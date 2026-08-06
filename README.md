# Build your own TwinCAT MATLAB GUI (App Designer, local-first)

This guide shows how to build a MATLAB App Designer GUI for a TwinCAT-controlled project, based on the behavior in `GUI_ArvidKeemink.m` but without the custom script-style UI.

## 1. What you will build

- App Designer GUI with:
  - status readout (state/error/angles/torque),
  - buttons for trigger commands (pulse 1 -> 0),
  - sliders for continuous values.
- ADS connection to TwinCAT via `TwinCAT.Ads.dll`.
- Timer loop (~10 Hz) to read output data and refresh labels.

## 2. Prerequisites (local-first)

1. MATLAB with **App Designer**.
2. TwinCAT runtime in RUN mode with your model running.
3. ADS .NET DLL available at  
   `C:\TwinCAT\AdsApi\.NET\v4.0.30319\TwinCAT.Ads.dll`
4. Your target AMS Net ID and ADS port (example in existing script uses `350`).

## 3. Define your signal contract first

Do this before UI work.

### 3.1 Read block (from existing GUI)

- Source block name: `Exosoft_Controller.Output.gui_out`
- Existing code assumes `20` doubles (`20*8` bytes).

Create your own table for your project:

| Read index (double) | Meaning | Unit |
|---|---|---|
| 1 | Motor angle knee (example) | deg/rad |
| 2 | Motor torque knee (example) | Nm |
| ... | ... | ... |

### 3.2 Write targets (from existing GUI pattern)

Prefix in existing GUI:

`Exosoft_Controller.ModelParameters.`

Trigger-type writes (pulse 1->0):
- `PosCtrlTrigger_Knee_Value`
- `SlackCtrlTrigger_Knee_Value`
- `TrqCtrlTrigger_Knee_Value`
- `StopTrigger_Knee_Value`
- `ErrAck_Knee_Value`
- `HybridTrigger_Knee_Value`
- same set for ankle
- `CalibrateMotorOffset_Value`

Continuous-value writes:
- `TorqueRef_Knee_Value`
- `ManualOffset_Knee_Value`
- `TorqueRef_Ankle_Value`
- `ManualOffset_Ankle_Value`
- `TorqueLimit_Value`
- `doLog_Value` (0/1 as value, not pulse)

For your own project, replace names and keep the same semantics (pulse vs value).

### 3.3 Using `.tmc` as source of truth (recommended)

For generated TwinCAT modules, build ADS paths from:

`<ModuleName>.<DataArea>.<SymbolName>`

For `jlo_assist_short_explicit_clean_Lon.tmc`:
- Module: `jlo_assist_short_explicit_clean_Lonit`
- DataAreas include: `Output`, `ModelParameters`, `BlockIO`

Stable default policy:
- **Read** from `Output`
- **Write** tunables in `ModelParameters`
- Avoid `BlockIO` in baseline GUI (internal names can change more across rebuilds)

Example from your model:
- `exo_torque_desired_highlevel_r` is in `Output`  
  -> `jlo_assist_short_explicit_clean_Lonit.Output.exo_torque_desired_highlevel_r`
- `exo_torque_desired_r` is in `BlockIO`  
  -> `jlo_assist_short_explicit_clean_Lonit.BlockIO.exo_torque_desired_r`

If you need to visualize `exo_torque_desired_r` with the stable policy, expose it to `Output` in Simulink/codegen and then read it from `Output`.

## 4. Build the App Designer UI

Create a new app and add:

1. A panel per subsystem (e.g. Knee, Ankle).
2. In each panel:
   - buttons: Disable, Pos Hold, Torque, Slack, Error Ack, Hybrid
   - sliders: torque reference and offset
   - labels for state/error/angles/torque
3. One General panel:
   - Disable all, All slack, Recalibrate, Logger toggle

Keep it minimal first: build one panel (Knee) and duplicate for others.

## 5. Paste minimal App Designer backend skeleton

Add these to your app code (adapt component names to your app):

```matlab
properties (Access = private)
    tcClient
    sourceHandle
    readStream
    readBin
    readLength = 20 * 8;   % bytes, adjust to your read block
    adsPort = 350
    amsNetId = "172.18.234.64.1.1"  % replace
    writeMap struct
    loopTimer timer
end

methods (Access = private)
    function startupFcn(app)
        % ponytail: delete old timers from previous crashed runs; narrow to app-owned timer if needed later
        t = timerfindall;
        if ~isempty(t), delete(t); end

        NET.addAssembly('C:\TwinCAT\AdsApi\.NET\v4.0.30319\TwinCAT.Ads.dll');
        import TwinCAT.Ads.*

        app.tcClient = TcAdsClient;
        app.tcClient.Connect(AmsNetId(char(app.amsNetId)), app.adsPort);

        app.sourceHandle = app.tcClient.CreateVariableHandle('Exosoft_Controller.Output.gui_out'); % replace
        app.readStream = AdsStream(app.readLength);
        app.readBin = AdsBinaryReader(app.readStream);

        app.writeMap = struct( ...
            'PosCtrlKnee', app.tcClient.CreateVariableHandle('Exosoft_Controller.ModelParameters.PosCtrlTrigger_Knee_Value'), ...
            'TrqRefKnee',  app.tcClient.CreateVariableHandle('Exosoft_Controller.ModelParameters.TorqueRef_Knee_Value') ...
        ); % add all required variables

        app.loopTimer = timer('ExecutionMode','fixedRate','Period',0.1, ...
            'TimerFcn', @(~,~)app.updateLoop());
        start(app.loopTimer);
    end

    function updateLoop(app)
        app.tcClient.Read(app.sourceHandle, app.readStream);
        data = zeros(app.readLength/8,1);
        for i = 1:numel(data), data(i) = app.readBin.ReadDouble; end
        app.readStream.Position = 0;

        % map read indexes to labels (replace with your contract)
        app.KneeStateLabel.Text = sprintf('State: %g', data(7));
        app.KneeErrorLabel.Text = sprintf('Error: %g', data(6));
    end

    function writeDouble(app, handle, value)
        app.tcClient.WriteAny(handle, typecast(double(value), 'uint8'));
    end

    function pulse(app, handle)
        app.writeDouble(handle, 1);
        pause(0.1);
        app.writeDouble(handle, 0);
    end

    function delete(app)
        if ~isempty(app.loopTimer) && isvalid(app.loopTimer), stop(app.loopTimer); delete(app.loopTimer); end
        if ~isempty(app.tcClient), app.tcClient.Close; end
    end
end
```

## 6. Wire callbacks in App Designer

- Button callback (trigger signal): call `pulse(app, app.writeMap.<SignalName>)`
- Slider callback (continuous signal): call `writeDouble(app, app.writeMap.<SignalName>, app.<Slider>.Value)`
- Logger toggle: write 0/1 value with `writeDouble`

## 7. First-run checklist

1. Confirm AMS Net ID and ADS port.
2. Confirm all variable names exactly match TwinCAT symbols.
3. Start TwinCAT runtime/model first, then start MATLAB app.
4. Verify one read label changes and one button pulse is received before adding more controls.

## 8. Troubleshooting

- **`CreateVariableHandle` fails**: wrong symbol name/path or target not running.
- **Connection fails**: AMS Net ID/port mismatch or ADS route missing.
- **GUI freezes/stops updating**: timer error; wrap `updateLoop` call path with actionable logging and stop timer on hard ADS error.
- **Multiple timers running**: old timer objects not cleaned; ensure `delete(app)` stops/deletes timer.

## 9. Migration notes from `GUI_ArvidKeemink.m`

| Old script pattern | App Designer equivalent |
|---|---|
| `figure/uicontrol/uipanel` | drag-and-drop components in `.mlapp` |
| nested callbacks in one file | component callbacks + private methods |
| `eval`-based text updates | direct label property updates |
| global-ish shared variables in function scope | app private properties |
| manual close request | app `delete` cleanup |

## 10. Optional appendix: remote/deployment setup

Use this only after local flow works:

1. Configure ADS route between engineering PC and remote target.
2. Replace `amsNetId` with target net ID.
3. Open required ADS/TwinCAT network access.
4. Add reconnect behavior (retry/backoff) if long-running field use is needed.
