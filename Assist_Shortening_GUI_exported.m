classdef Assist_Shortening_GUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        clearButton                    matlab.ui.control.Button
        CopyDataButton                 matlab.ui.control.Button
        SetFolderDataLogButton         matlab.ui.control.Button
        PrintControlParametersButton   matlab.ui.control.Button
        TextArea                       matlab.ui.control.TextArea
        enabledatacollectionCheckBox   matlab.ui.control.CheckBox
        InitLowlevelcontrollerPanel    matlab.ui.container.Panel
        ignoreerrorlowlevelCheckBox    matlab.ui.control.CheckBox
        resetdriveRCheckBox            matlab.ui.control.CheckBox
        resetdriveLCheckBox            matlab.ui.control.CheckBox
        enablemotorvelRCheckBox        matlab.ui.control.CheckBox
        enabledriveRCheckBox           matlab.ui.control.CheckBox
        enablemotorvelLCheckBox        matlab.ui.control.CheckBox
        enabledriveLCheckBox           matlab.ui.control.CheckBox
        maxdorsiflexRButton            matlab.ui.control.Button
        maxplantarflexRButton          matlab.ui.control.Button
        zeroencoderRButton             matlab.ui.control.Button
        maxdorsiflexLButton            matlab.ui.control.Button
        maxplantarflexLButton          matlab.ui.control.Button
        zeroencoderLButton             matlab.ui.control.Button
        zeroloadcellRButton            matlab.ui.control.Button
        zeroLoadcellLButton            matlab.ui.control.Button
        HighlevelcontrollersettingsPanel  matlab.ui.container.Panel
        SelectControllerDropDown       matlab.ui.control.DropDown
        SelectControllerDropDownLabel  matlab.ui.control.Label
        cutoff_velEditField            matlab.ui.control.NumericEditField
        cutoff_velEditFieldLabel       matlab.ui.control.Label
        bexoEditField                  matlab.ui.control.NumericEditField
        bexoEditFieldLabel             matlab.ui.control.Label
        MinimalTorqueEditField         matlab.ui.control.NumericEditField
        MinimalTorqueEditFieldLabel    matlab.ui.control.Label
        PercentageAssistanceEditField  matlab.ui.control.NumericEditField
        PercentageAssistanceEditFieldLabel  matlab.ui.control.Label
        actdyn_typeDropDown            matlab.ui.control.DropDown
        actdyn_typeDropDownLabel       matlab.ui.control.Label
        applyassistanceCheckBox        matlab.ui.control.CheckBox
        UploadParamsButton             matlab.ui.control.Button
        SetParamsFileButton            matlab.ui.control.Button
        LowlevelcontrollersettingsPanel  matlab.ui.container.Panel
        durationzeroEditField          matlab.ui.control.NumericEditField
        durationzeroEditFieldLabel     matlab.ui.control.Label
        MaxTorqueEditField             matlab.ui.control.NumericEditField
        MaxTorqueEditFieldLabel        matlab.ui.control.Label
        PdcontrollerdesiredtorquetrackingLabel  matlab.ui.control.Label
        KdEditField                    matlab.ui.control.NumericEditField
        KdEditFieldLabel               matlab.ui.control.Label
        KpEditField                    matlab.ui.control.NumericEditField
        KpEditFieldLabel               matlab.ui.control.Label
        Muscle_Act_left                matlab.ui.control.UIAxes
        Muscle_Act_right               matlab.ui.control.UIAxes
        RightJointMoments              matlab.ui.control.UIAxes
        LeftJointMoments               matlab.ui.control.UIAxes
        RightMuscleMoments             matlab.ui.control.UIAxes
        LeftMuscleMoments              matlab.ui.control.UIAxes
    end


    properties (Access = private)

        % to do:
        % run timer on GUI and check if this is going to work at 10Hz.
        % we might want to buffer the data for the figures
        % (both combine in one output in simulink so that we only need one
        % ADS read + buffer data in a vector/matrix and only update the plot
        % using this buffer at a lower frequency (e.g. plot 10 datapoints every
        % second))

        % Required inputs, might need to change
        adsPort_highlevel = 351
        adsPort_lowlevel = 352
        amsNetId = "130.89.78.82.1.1"  % ToDo: replace % Description
        TwinCatAdsPath = 'C:\TwinCAT\AdsApi\.NET\v4.0.30319\TwinCAT.Ads.dll';
        sampling_frequency_gui = 10
        name_lowlevel_controller = 'MainLowLevelController' % to acces control params
        name_highlevel_controller = 'jlo_assist_short_explicit_clean_Lonit' % to acces control params
        JointWindowSec = 5 % number of seconds in figure
        dt_zero_sensors  = 2; % duration time window to get zero value sensors

        % specify number of doubles in gui_output (for visualisation)
        number_gui_outputs = 19
        gui_data_headers = {'LeftExoDesiredMoment',...      % 1
            'RightExoDesiredMoment',...                     % 2
            'LeftBioMoment',...                             % 3
            'RightBioMoment',...                            % 4
            'LeftAssistShortMoment',...                     % 5
            'RightAssistShortMoment',...                    % 6
            'LeftSolMoment', ...                            % 7
            'LeftGasMoment', ...                            % 8
            'LeftTibMoment', ...                            % 9
            'RightSolMoment', ...                           % 10
            'RightGasMoment', ...                           % 11
            'RightTibMoment', ...                           % 12
            'ControlMode',...                               % 13
            'Soleus_act_l',...                              % 14
            'Gastroc_act_l',...                             % 15
            'Tibialis_act_l',...                            % 16
            'Soleus_act_r',...                              % 17
            'Gastroc_act_r',...                             % 18
            'Tibialis_act_r'};                              % 19

        number_highlevel_param_outputs = 7;
        highlevel_params_headers = {
            'MinimalTorque',...                             % 1
            'ApplyAssistance',...                           % 2
            'perc_assistance',...                           % 3
            'b_exo',...                                     % 4
            'actdyn_selection',...                          % 5
            'cutoff_vel',...                                % 6
            'ControllerMode'};                              % 7

        number_lowlevel_param_outputs = 10;
        lowlevel_params_header = {'max_torque',...          % 1
            'enable_drives_left',...                        % 2
            'enable_drives_right',...                       % 3
            'enable_motor_velocity_left',...                % 4
            'enable_motor_velocity_right',...               % 5
            'enable_data_collection',...                    % 6
            'pd_kp_left',...                                % 7
            'pd_kp_right',...                               % 8
            'pd_kd_left',...                                % 9
            'pd_kd_right'};                                 % 10


        % variables specific for this program
        muscle_params_file = ''; % file with the calibrated muscle parameters
        headers_muscle_params = { ...
            'Gastroc_lTslack_r', 'Gastroc_Atendon_r', 'Gastroc_tau_act_r', 'Gastroc_tau_deact_r', 'Gastroc_scale_emg_r', ...
            'Soleus_lTslack_r', 'Soleus_Atendon_r', 'Soleus_tau_act_r', 'Soleus_tau_deact_r', 'Soleus_scale_emg_r', ...
            'Tibialis_lTslack_r', 'Tibialis_Atendon_r', 'Tibialis_tau_act_r', 'Tibialis_tau_deact_r', 'Tibialis_scale_emg_r' ...
            'Gastroc_lTslack_l', 'Gastroc_Atendon_l', 'Gastroc_tau_act_l', 'Gastroc_tau_deact_l', 'Gastroc_scale_emg_l', ...
            'Soleus_lTslack_l', 'Soleus_Atendon_l', 'Soleus_tau_act_l', 'Soleus_tau_deact_l', 'Soleus_scale_emg_l', ...
            'Tibialis_lTslack_l', 'Tibialis_Atendon_l', 'Tibialis_tau_act_l', 'Tibialis_tau_deact_l', 'Tibialis_scale_emg_l' ...
            }; % update muscle parameters will change these variables now

        % figure Left joint moment things
        leftJointPlot
        leftJointModelPlot
        leftAssistShortPlot
        leftJointStartTic        
        leftJointMaxPoints = 50 % default value

        % figure Right joint moment things
        rightJointPlot
        rightJointModelPlot
        rightAssistShortPlot
        rightJointStartTic
        rightJointMaxPoints = 50% default value

        % figure left moments generated by muscles
        leftTauSolPlot
        leftTauGasPlot
        leftTauTibPlot
        leftTauStartTic
        leftTauMaxPoints = 50

        % figure left moments generated by muscles
        rightTauSolPlot
        rightTauGasPlot
        rightTauTibPlot
        rightTauStartTic
        rightTauMaxPoints = 50

        % figure left muscle activations
        leftActSolPlot
        leftActGasPlot
        leftActTibPlot
        leftActStartTic
        leftActMaxPoints = 50

        % figure right muscle activations
        rightActSolPlot
        rightActGasPlot
        rightActTibPlot
        rightActStartTic
        rightActMaxPoints = 50

        

        % Vector-read path properties
        GuiOutputHandle
        GuiOutputdata_target
        GuiOutputbin_target
        length_GuiOuputStream
        gui_data

        % Vector-read highlevel control parameters
        HighLevelParamHandle
        HighLevelParamdata_target
        HighLevelParambin_target
        length_HighLevelParamStream
        HighLevelParam_data

        % various things handled automatically
        tcClient_lowlevel
        tcClient_highlevel
        scalarReadStream
        scalarReadBin        
        writeMap struct
        handleInitFailures struct
        loopTimer timer
        datalogfolder
    end

    methods (Access = private)

        function updateLoop(app)
            try
                % get all gui_output data
                app.tcClient_highlevel.Read(app.GuiOutputHandle, app.GuiOutputdata_target);
                for ind = 1:app.number_gui_outputs
                    app.gui_data(ind) = app.GuiOutputbin_target.ReadDouble;
                end
                app.GuiOutputdata_target.Position = 0;

                % unpack the gui_data
                LeftExoDesiredMoment = app.gui_data(strcmp(app.gui_data_headers,'LeftExoDesiredMoment'));
                LeftBioMoment = app.gui_data(strcmp(app.gui_data_headers,'LeftBioMoment'));
                LeftAssistShortMoment = app.gui_data(strcmp(app.gui_data_headers,'LeftAssistShortMoment'));

                RightExoDesiredMoment = app.gui_data(strcmp(app.gui_data_headers,'RightExoDesiredMoment'));
                RightBioMoment = app.gui_data(strcmp(app.gui_data_headers,'RightBioMoment'));
                RightAssistShortMoment = app.gui_data(strcmp(app.gui_data_headers,'RightAssistShortMoment'));
                
                LeftSolMoment = app.gui_data(strcmp(app.gui_data_headers,'LeftSolMoment'));
                LeftGasMoment = app.gui_data(strcmp(app.gui_data_headers,'LeftGasMoment'));
                LeftTibMoment = app.gui_data(strcmp(app.gui_data_headers,'LeftTibMoment'));
                
                RightSolMoment = app.gui_data(strcmp(app.gui_data_headers,'RightSolMoment'));
                RightGasMoment = app.gui_data(strcmp(app.gui_data_headers,'RightGasMoment'));
                RightTibMoment = app.gui_data(strcmp(app.gui_data_headers,'RightTibMoment'));

                LeftSoleusAct = app.gui_data(strcmp(app.gui_data_headers,'Soleus_act_l'));
                LeftGastrocAct = app.gui_data(strcmp(app.gui_data_headers,'Gastroc_act_l'));
                LeftTibialisAct = app.gui_data(strcmp(app.gui_data_headers,'Tibialis_act_l'));
                RightSoleusAct = app.gui_data(strcmp(app.gui_data_headers,'Soleus_act_r'));
                RightGastrocAct = app.gui_data(strcmp(app.gui_data_headers,'Gastroc_act_r'));
                RightTibialisAct = app.gui_data(strcmp(app.gui_data_headers,'Tibialis_act_r'));




                % update plots
                app.updateLeftJointPlot(LeftExoDesiredMoment, LeftBioMoment, LeftAssistShortMoment);
                app.updateRightJointPlot(RightExoDesiredMoment, RightBioMoment, RightAssistShortMoment);
                app.updateLeftMuscleTauPlot(LeftSolMoment, LeftGasMoment, LeftTibMoment);
                app.updateRightMuscleTauPlot(RightSolMoment, RightGasMoment, RightTibMoment);
                app.updateLeftMuscleActPlot(LeftSoleusAct, LeftGastrocAct, LeftTibialisAct);
                app.updateRightMuscleActPlot(RightSoleusAct, RightGastrocAct, RightTibialisAct);
                drawnow limitrate nocallbacks

            catch ME
                app.TextArea.Value = [app.TextArea.Value; {'TwinCAT update failed'}];
                warning('TwinCAT update failed');
                if ~isempty(app.loopTimer) && isvalid(app.loopTimer)
                    stop(app.loopTimer);
                end
                return;
            end
            

        end

        function value = readScalarSignal(app, handle, tcClient)
            tcClient.Read(handle, app.scalarReadStream);
            value = app.scalarReadBin.ReadDouble;
            app.scalarReadStream.Position = 0;
        end

        function writeDouble(app, handle, value, tcClient)
            if isempty(handle)
                warning('Write skipped: ADS handle is missing.');
                app.TextArea.Value = [app.TextArea.Value; {'Write skipped: required ADS handle missing'}];
                return;
            end
            tcClient.WriteAny(handle, typecast(double(value), 'uint8'));
        end
        
        function [handle, isOk] = createHandleChecked(app, key, symbol, group, tcClient)
            handle = [];
            isOk = false;

            try
                handle = tcClient.CreateVariableHandle(symbol);
                isOk = true;
            catch ME
                app.handleInitFailures(end+1) = struct( ...
                    'key', key, 'symbol', symbol, 'group', group, 'message', ME.message);
                app.TextArea.Value = [app.TextArea.Value; {sprintf('Handle failed [%s]: %s', key, symbol)}];
                warning('CreateVariableHandle failed for %s (%s): %s', key, symbol, ME.message);
            end
        end

        function pulse(app, handle, dt, tcClient)
            app.writeDouble(handle, 1, tcClient);
            pause(dt);
            app.writeDouble(handle, 0, tcClient);
        end

        function delete_ads_connection(app)
            if ~isempty(app.loopTimer) && isvalid(app.loopTimer), stop(app.loopTimer); delete(app.loopTimer); end
            if ~isempty(app.tcClient_highlevel), app.tcClient_highlevel.Close; end
            if ~isempty(app.tcClient_lowlevel), app.tcClient_lowlevel.Close; end
        end

        % methods for graph
        function initLeftJointPlot(app)
            cla(app.LeftJointMoments);
            grid(app.LeftJointMoments, 'on');
            hold(app.LeftJointMoments, 'on');
            app.leftJointPlot = animatedline(app.LeftJointMoments, ...
                'Color', [0 0.4470 0.7410], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.leftJointMaxPoints);
            app.leftJointModelPlot = animatedline(app.LeftJointMoments, ...
                'Color', [0.8500 0.3250 0.0980], ...
                'LineWidth', 1.25, ...
                'LineStyle', '--', ...
                'MaximumNumPoints', app.leftJointMaxPoints);
            app.leftAssistShortPlot = animatedline(app.LeftJointMoments, ...
                'Color', [0.0980 0.3250  0.8500], ...
                'LineWidth', 1.25, ...
                'LineStyle', '--', ...
                'MaximumNumPoints', app.leftJointMaxPoints);
            legend(app.LeftJointMoments, {'Applied','PercID','AssistShort'}, 'Location', 'best');
            app.leftJointStartTic = tic;
        end

        function updateLeftJointPlot(app, leftJointMoment, leftJointMomentModel,...
                leftAssistShort)
            t = toc(app.leftJointStartTic);
            addpoints(app.leftJointPlot, t, leftJointMoment);
            addpoints(app.leftJointModelPlot, t, leftJointMomentModel);
            addpoints(app.leftAssistShortPlot, t, leftAssistShort);
            if t > app.JointWindowSec
                xlim(app.LeftJointMoments, [t - app.JointWindowSec, t]);
            else
                xlim(app.LeftJointMoments, [0, app.JointWindowSec]);
            end
        end

        function initRightJointPlot(app)
            cla(app.RightJointMoments);
            grid(app.RightJointMoments, 'on');
            hold(app.RightJointMoments, 'on');
            app.rightJointPlot = animatedline(app.RightJointMoments, ...
                'Color', [0 0.4470 0.7410], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.rightJointMaxPoints);
            app.rightJointModelPlot = animatedline(app.RightJointMoments, ...
                'Color', [0.8500 0.3250 0.0980], ...
                'LineWidth', 1.25, ...
                'LineStyle', '--', ...
                'MaximumNumPoints', app.rightJointMaxPoints);
            app.rightAssistShortPlot = animatedline(app.RightJointMoments, ...
                'Color', [0.0980 0.3250  0.8500], ...
                'LineWidth', 1.25, ...
                'LineStyle', '--', ...
                'MaximumNumPoints', app.rightJointMaxPoints);
            legend(app.RightJointMoments, {'Applied','PercID','AssistShort'}, 'Location', 'best');
            app.rightJointStartTic = tic;
        end

        function updateRightJointPlot(app, rightJointMoment, rightJointMomentModel,...
                rightAssistShort)
            t = toc(app.rightJointStartTic);
            addpoints(app.rightJointPlot, t, rightJointMoment);
            addpoints(app.rightJointModelPlot, t, rightJointMomentModel);
            addpoints(app.rightAssistShortPlot, t, rightAssistShort);
            if t > app.JointWindowSec
                xlim(app.RightJointMoments, [t - app.JointWindowSec, t]);
            else
                xlim(app.RightJointMoments, [0, app.JointWindowSec]);
            end
        end

        % add functions for updating Left and Right Muscle Tau plot
        function initLeftMuscleTauPlot(app)
            cla(app.LeftMuscleMoments);
            grid(app.LeftMuscleMoments, 'on');
            hold(app.LeftMuscleMoments, 'on');
            app.leftTauSolPlot = animatedline(app.LeftMuscleMoments, ...
                'Color', [0 0.4470 0.7410], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.leftTauMaxPoints);
            app.leftTauGasPlot = animatedline(app.LeftMuscleMoments, ...
                'Color', [0.8500 0.3250 0.0980], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.leftTauMaxPoints);
            app.leftTauTibPlot = animatedline(app.LeftMuscleMoments, ...
                'Color', [0.4660 0.6740 0.1880], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.leftTauMaxPoints);
            legend(app.LeftMuscleMoments, {'Sol','Gas','Tib'}, 'Location', 'best');
            app.leftTauStartTic = tic;
        end

        function updateLeftMuscleTauPlot(app, leftTauSol, leftTauGas, leftTauTib)
            t = toc(app.leftTauStartTic);
            addpoints(app.leftTauSolPlot, t, leftTauSol);
            addpoints(app.leftTauGasPlot, t, leftTauGas);
            addpoints(app.leftTauTibPlot, t, leftTauTib);
            if t > app.JointWindowSec
                xlim(app.LeftMuscleMoments, [t - app.JointWindowSec, t]);
            else
                xlim(app.LeftMuscleMoments, [0, app.JointWindowSec]);
            end
        end

        function initRightMuscleTauPlot(app)
            cla(app.RightMuscleMoments);
            grid(app.RightMuscleMoments, 'on');
            hold(app.RightMuscleMoments, 'on');
            app.rightTauSolPlot = animatedline(app.RightMuscleMoments, ...
                'Color', [0 0.4470 0.7410], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.rightTauMaxPoints);
            app.rightTauGasPlot = animatedline(app.RightMuscleMoments, ...
                'Color', [0.8500 0.3250 0.0980], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.rightTauMaxPoints);
            app.rightTauTibPlot = animatedline(app.RightMuscleMoments, ...
                'Color', [0.4660 0.6740 0.1880], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.rightTauMaxPoints);
            legend(app.RightMuscleMoments, {'Sol','Gas','Tib'}, 'Location', 'best');
            app.rightTauStartTic = tic;
        end

        function updateRightMuscleTauPlot(app, rightTauSol, rightTauGas, rightTauTib)
            t = toc(app.rightTauStartTic);
            addpoints(app.rightTauSolPlot, t, rightTauSol);
            addpoints(app.rightTauGasPlot, t, rightTauGas);
            addpoints(app.rightTauTibPlot, t, rightTauTib);
            if t > app.JointWindowSec
                xlim(app.RightMuscleMoments, [t - app.JointWindowSec, t]);
            else
                xlim(app.RightMuscleMoments, [0, app.JointWindowSec]);
            end
        end

        function initLeftMuscleActPlot(app)
            cla(app.Muscle_Act_left);
            grid(app.Muscle_Act_left, 'on');
            hold(app.Muscle_Act_left, 'on');
            app.leftActSolPlot = animatedline(app.Muscle_Act_left, ...
                'Color', [0 0.4470 0.7410], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.leftActMaxPoints);
            app.leftActGasPlot = animatedline(app.Muscle_Act_left, ...
                'Color', [0.8500 0.3250 0.0980], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.leftActMaxPoints);
            app.leftActTibPlot = animatedline(app.Muscle_Act_left, ...
                'Color', [0.4660 0.6740 0.1880], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.leftActMaxPoints);
            legend(app.Muscle_Act_left, {'Sol','Gas','Tib'}, 'Location', 'best');
            ylim(app.Muscle_Act_left, [0, 1]);
            app.leftActStartTic = tic;
        end

        function updateLeftMuscleActPlot(app, leftActSol, leftActGas, leftActTib)
            t = toc(app.leftActStartTic);
            addpoints(app.leftActSolPlot, t, leftActSol);
            addpoints(app.leftActGasPlot, t, leftActGas);
            addpoints(app.leftActTibPlot, t, leftActTib);
            if t > app.JointWindowSec
                xlim(app.Muscle_Act_left, [t - app.JointWindowSec, t]);
            else
                xlim(app.Muscle_Act_left, [0, app.JointWindowSec]);
            end
        end

        function initRightMuscleActPlot(app)
            cla(app.Muscle_Act_right);
            grid(app.Muscle_Act_right, 'on');
            hold(app.Muscle_Act_right, 'on');
            app.rightActSolPlot = animatedline(app.Muscle_Act_right, ...
                'Color', [0 0.4470 0.7410], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.rightActMaxPoints);
            app.rightActGasPlot = animatedline(app.Muscle_Act_right, ...
                'Color', [0.8500 0.3250 0.0980], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.rightActMaxPoints);
            app.rightActTibPlot = animatedline(app.Muscle_Act_right, ...
                'Color', [0.4660 0.6740 0.1880], ...
                'LineWidth', 1.25, ...
                'MaximumNumPoints', app.rightActMaxPoints);
            legend(app.Muscle_Act_right, {'Sol','Gas','Tib'}, 'Location', 'best');
            ylim(app.Muscle_Act_right, [0, 1]);
            app.rightActStartTic = tic;
        end

        function updateRightMuscleActPlot(app, rightActSol, rightActGas, rightActTib)
            t = toc(app.rightActStartTic);
            addpoints(app.rightActSolPlot, t, rightActSol);
            addpoints(app.rightActGasPlot, t, rightActGas);
            addpoints(app.rightActTibPlot, t, rightActTib);
            if t > app.JointWindowSec
                xlim(app.Muscle_Act_right, [t - app.JointWindowSec, t]);
            else
                xlim(app.Muscle_Act_right, [0, app.JointWindowSec]);
            end
        end


    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)


            % this is the startup function of the GUI
            % ponytail: delete old timers from previous crashed runs; narrow to app-owned timer if needed later
            t = timerfindall;
            if ~isempty(t), delete(t); end            
            app.TextArea.Value = {'starting gui'};
            
            % add twincat Ads
            try
                app.number_gui_outputs = numel(app.gui_data_headers);
                NET.addAssembly(app.TwinCatAdsPath);
                % import ADS
                import TwinCAT.Ads.*
                % init TcClient
                app.tcClient_lowlevel = TcAdsClient;
                app.tcClient_lowlevel.Connect(AmsNetId(char(app.amsNetId)), app.adsPort_lowlevel);
                app.tcClient_highlevel = TcAdsClient;
                app.tcClient_highlevel.Connect(AmsNetId(char(app.amsNetId)), app.adsPort_highlevel);
                % init reader for double outputs
                app.scalarReadStream = AdsStream(8);
                app.scalarReadBin = AdsBinaryReader(app.scalarReadStream);
                % init reader for combined gui outputs
                app.length_GuiOuputStream = app.number_gui_outputs * 8; %8 bytes per double
                app.GuiOutputdata_target = AdsStream(app.length_GuiOuputStream);
                app.GuiOutputbin_target = AdsBinaryReader(app.GuiOutputdata_target);
                % init read for highevel control parameters
                app.length_HighLevelParamStream = app.number_highlevel_param_outputs * 8;
                app.HighLevelParamdata_target = AdsStream(app.length_HighLevelParamStream);
                app.HighLevelParambin_target = AdsBinaryReader(app.HighLevelParamdata_target);

                % update text
                app.TextArea.Value = [app.TextArea.Value; {'ADS connection done'}];
            catch ME
                % use MockAdsClient
                warning('TwinCAT ADS unavailable, using MockAdsClient: %s', ME.message);
                app.tcClient_highlevel = MockAdsClient;
                app.tcClient_lowlevel = MockAdsClient;
                app.tcClient_highlevel.Connect([], []);
                app.tcClient_lowlevel.Connect([], []);
                app.GuiOutputdata_target = System.IO.MemoryStream(app.number_gui_outputs * 8);
                app.GuiOutputbin_target = System.IO.BinaryReader(app.GuiOutputdata_target);
                app.HighLevelParamdata_target = System.IO.MemoryStream(app.number_highlevel_param_outputs * 8);
                app.HighLevelParambin_target = System.IO.BinaryReader(app.HighLevelParamdata_target);
                app.TextArea.Value = [app.TextArea.Value; {'ADS connection failed, debug ADS mode activated (dummy ADS)'}];
            end

            % some helpers to make handle creation easier
            base_name_high = [app.name_highlevel_controller '.'];
            base_name_output = [app.name_highlevel_controller '.Output.'];
            base_name_low = [app.name_lowlevel_controller '.ModelParameters.'];

            % list of all the handles we want to create
            handleSpecs = { ...
                'GuiOutputHandle', [base_name_output 'gui_output'], 'gui_output_plot',app.tcClient_highlevel; ...

                'Gastroc_lTslack_r', [base_name_high 'ModelParameters.Gastroc_lTslack_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_Atendon_r', [base_name_high 'ModelParameters.Gastroc_Atendon_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_tau_act_r', [base_name_high 'ModelParameters.Gastroc_tau_act_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_tau_deact_r', [base_name_high 'ModelParameters.Gastroc_tau_deact_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_scale_emg_r', [base_name_high 'ModelParameters.Gastroc_scale_emg_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_lTslack_r', [base_name_high 'ModelParameters.Soleus_lTslack_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_Atendon_r', [base_name_high 'ModelParameters.Soleus_Atendon_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_tau_act_r', [base_name_high 'ModelParameters.Soleus_tau_act_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_tau_deact_r', [base_name_high 'ModelParameters.Soleus_tau_deact_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_scale_emg_r', [base_name_high 'ModelParameters.Soleus_scale_emg_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_lTslack_r', [base_name_high 'ModelParameters.Tibialis_lTslack_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_Atendon_r', [base_name_high 'ModelParameters.Tibialis_Atendon_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_tau_act_r', [base_name_high 'ModelParameters.Tibialis_tau_act_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_tau_deact_r', [base_name_high 'ModelParameters.Tibialis_tau_deact_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_scale_emg_r', [base_name_high 'ModelParameters.Tibialis_scale_emg_r_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                
                'Gastroc_lTslack_l', [base_name_high 'ModelParameters.Gastroc_lTslack_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_Atendon_l', [base_name_high 'ModelParameters.Gastroc_Atendon_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_tau_act_l', [base_name_high 'ModelParameters.Gastroc_tau_act_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_tau_deact_l', [base_name_high 'ModelParameters.Gastroc_tau_deact_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Gastroc_scale_emg_l', [base_name_high 'ModelParameters.Gastroc_scale_emg_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_lTslack_l', [base_name_high 'ModelParameters.Soleus_lTslack_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_Atendon_l', [base_name_high 'ModelParameters.Soleus_Atendon_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_tau_act_l', [base_name_high 'ModelParameters.Soleus_tau_act_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_tau_deact_l', [base_name_high 'ModelParameters.Soleus_tau_deact_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Soleus_scale_emg_l', [base_name_high 'ModelParameters.Soleus_scale_emg_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_lTslack_l', [base_name_high 'ModelParameters.Tibialis_lTslack_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_Atendon_l', [base_name_high 'ModelParameters.Tibialis_Atendon_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_tau_act_l', [base_name_high 'ModelParameters.Tibialis_tau_act_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_tau_deact_l', [base_name_high 'ModelParameters.Tibialis_tau_deact_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...
                'Tibialis_scale_emg_l', [base_name_high 'ModelParameters.Tibialis_scale_emg_l_Value'], 'muscle_upload',app.tcClient_highlevel; ...

                'ControllerMode', [base_name_high 'ModelParameters.ControllerMode_Value'], 'controller_params',app.tcClient_highlevel; ...
                'MinimalTorque', [base_name_high 'ModelParameters.MinimalTorque_Value'], 'controller_params',app.tcClient_highlevel; ...
                'ApplyAssistance', [base_name_high 'ModelParameters.ApplyAssistance_Value'], 'controller_params',app.tcClient_highlevel; ...
                'perc_assistance', [base_name_high 'ModelParameters.PercentageAssistance_Value'], 'controller_params',app.tcClient_highlevel; ...
                'b_exo', [base_name_high 'ModelParameters.bexo_Value'], 'controller_params',app.tcClient_highlevel; ...
                'actdyn_selection', [base_name_high 'ModelParameters.ActDyn_mode_Value'], 'controller_params',app.tcClient_highlevel; ...
                'cutoff_vel', [base_name_high 'ModelParameters.cutoff_vel_Value'], 'controller_params',app.tcClient_highlevel; ...
                
                'zero_loadcell_left', [base_name_low 'Constant50_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'zero_loadcell_right', [base_name_low 'Constant64_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'zero_encoder_left', [base_name_low 'Constant30_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'zero_encoder_right', [base_name_low 'Constant65_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'max_plantarflex_left', [base_name_low 'Constant51_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'max_plantarflex_right', [base_name_low 'Constant34_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'max_dorsiflex_left', [base_name_low 'Constant35_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'max_dorsiflex_right', [base_name_low 'Constant36_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'max_torque', [base_name_low 'Constant40_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'enable_drives_left', [base_name_low 'Constant33_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'enable_drives_right', [base_name_low 'Constant54_Value_o'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'enable_motor_velocity_left', [base_name_low 'Constant25_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'enable_motor_velocity_right', [base_name_low 'Constant26_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'enable_data_collection', [base_name_low 'Constant4_Value_j'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'pd_kp_left', [base_name_low 'ManualKp1_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'pd_kp_right', [base_name_low 'ManualKp2_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'pd_kd_left', [base_name_low 'ManualKd_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'pd_kd_right', [base_name_low 'ManualKd1_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'reset_drive_left', [base_name_low 'Constant27_Value_m'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'reset_drive_right', [base_name_low 'Constant58_Value_l'], 'lowlevel_params',app.tcClient_lowlevel; ...
                'ignore_errors', [base_name_low 'ignore_errors_Value'], 'lowlevel_params',app.tcClient_lowlevel; ...


                'HighLevelParamHandle', [base_name_output 'highlevel_params'], 'highlevel_params',app.tcClient_highlevel; ...
                'lowlevel_params_output', [base_name_low 'lowlevel_params'], 'lowlevel_params',app.tcClient_lowlevel ...;
                };
            app.writeMap = struct;
            app.GuiOutputHandle = [];
            app.HighLevelParamHandle = [];

            app.gui_data = zeros(app.number_gui_outputs,1);
            app.handleInitFailures = struct('key', {}, 'symbol', {}, 'group', {}, 'message', {});
            app.HighLevelParam_data = zeros(app.number_highlevel_param_outputs,1);

            
            % loop to create all the handles with error check
            for ispec = 1:size(handleSpecs, 1)
                key = handleSpecs{ispec, 1};
                symbol = handleSpecs{ispec, 2};
                group = handleSpecs{ispec, 3};
                tcClient = handleSpecs{ispec, 4};
                [createdHandle, isOk] = app.createHandleChecked(key, symbol, group, tcClient);
                if strcmp(key, 'GuiOutputHandle')
                    if isOk, app.GuiOutputHandle = createdHandle; end
                elseif strcmp(key, 'HighLevelParamHandle')
                    if isOk, app.HighLevelParamHandle = createdHandle; end
                else
                    if isOk
                        app.writeMap.(key) = createdHandle;
                    else
                        app.writeMap.(key) = [];
                    end
                end
            end
            app.TextArea.Value = [app.TextArea.Value; ...
                {sprintf('Handles created: %d, failed: %d', ...
                size(handleSpecs, 1) - numel(app.handleInitFailures), numel(app.handleInitFailures))}];
            if any(cellfun(@(k) ~isfield(app.writeMap, k) || isempty(app.writeMap.(k)), app.headers_muscle_params))
                %app.UploadParamsButton.Enable = 'off';
                app.TextArea.Value = [app.TextArea.Value; {'Upload disabled: missing muscle parameter handles'}];
            end

            % adapt MaxPoints if needed
            app.leftJointMaxPoints = app.JointWindowSec * app.sampling_frequency_gui;
            app.rightJointMaxPoints = app.JointWindowSec * app.sampling_frequency_gui;
            app.leftTauMaxPoints = app.JointWindowSec * app.sampling_frequency_gui;
            app.rightTauMaxPoints = app.JointWindowSec * app.sampling_frequency_gui;
            app.leftActMaxPoints = app.JointWindowSec * app.sampling_frequency_gui;
            app.rightActMaxPoints = app.JointWindowSec * app.sampling_frequency_gui;


            % init the plot
            app.initLeftJointPlot();
            app.initRightJointPlot();
            app.initLeftMuscleTauPlot();
            app.initRightMuscleTauPlot();
            app.initLeftMuscleActPlot();
            app.initRightMuscleActPlot();


            % set sampling frequency of the GUI
            if isempty(app.GuiOutputHandle)
                warning('GUI output handle missing; plot update timer not started.');
                app.TextArea.Value = [app.TextArea.Value; {'Plot updates disabled: gui_output handle missing'}];
            else
                app.loopTimer = timer('ExecutionMode','fixedRate','Period',1/app.sampling_frequency_gui, ...
                    'TimerFcn', @(~,~)app.updateLoop());
                start(app.loopTimer);
            end

            % here we want to update the parameters in the GUI based on the
            % current values in the simulink model. I'm not sure how we can
            % do this properly. we could try to read them from the
            % .Modelproperties so that we do not have to export all of them
            % as an output

        end

        % Button pushed function: SetParamsFileButton
        function SetParamsFileButtonPushed(app, event)
            % this callback should open a window that enables the user
            % to select the matlab file you want to apply in the real-time
            % controller
            [file, path] = uigetfile('*.mat', 'Select a MATLAB file');
            if isequal(file, 0) || isequal(path, 0)
                app.muscle_params_file = '';
                disp('No file selected.');
                return;
            end
            app.muscle_params_file = fullfile(path, file);
            fprintf('Selected file: %s\n', app.muscle_params_file);
            % also print selected file in the window
            app.TextArea.Value = [app.TextArea.Value; {['file selected : ' app.muscle_params_file]}];
        end

        % Button pushed function: UploadParamsButton
        function UploadParamsButtonPushed(app, event)
            % this callback should upload the muscle parameters to twincat
            % steps:
            %   1) read them from .mat file
            %   2) assign them to twincat constants

            if exist(app.muscle_params_file,'file')
                % load the muscle params file
                muscle_params = load(app.muscle_params_file);
                app.TextArea.Value = [app.TextArea.Value; {[app.muscle_params_file ' muscle params file loaded correctly']}];
                % unpack muscle params in memory
                % ToDo: discuss how to do this with Lonit. This will
                % look something like this
                % unpack the model: this extracts all the params to the
                % workspace
                %unpack_model(muscle_params.model)
                % test upload one param file
                
                % loop over all params we want to change
                app.TextArea.Value = [app.TextArea.Value; {[app.muscle_params_file ' started updating muscle params']}];
                for iparam = 1:length(app.headers_muscle_params)
                    % name of the variable
                    var_name = app.headers_muscle_params{iparam};
                    % the muscle name and param name
                    parts = regexp(var_name, '^([^_]+)_(.*)$', 'tokens', 'once');
                    muscle_name = parts{1};
                    param_name = parts{2};
                    muscle_name_no_side = muscle_name(1:end-2);
                    iend = length(var_name); 
                    if strcmp(var_name(iend-1:iend), '_r')
                        % adapt muscle parameter value
                        value_sel = muscle_params.model_r.(muscle_name_no_side).(param_name);
                    elseif strcmp(var_name(iend-1:iend), '_l')
                        % adapt muscle parameter value
                        value_sel = muscle_params.model_l.(muscle_name_no_side).(param_name);
                    else
                        app.TextArea.Value = [app.TextArea.Value; {['unclear if ' var_name ' is left or right']}];
                    end
                    app.writeDouble(app.writeMap.(var_name),...
                        value_sel, ...
                        app.tcClient_highlevel);
                    % display set muscle parameter
                    app.TextArea.Value = [app.TextArea.Value;...
                        {[app.muscle_params_file [var_name ' set to ' num2str(value_sel)]]}];
                end
            else
                app.TextArea.Value = [app.TextArea.Value; {[app.muscle_params_file ' does not exist']}];
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete_ads_connection(app);
            delete(app);

        end

        % Value changed function: SelectControllerDropDown
        function SelectControllerDropDownValueChanged(app, event)
            value = app.SelectControllerDropDown.Value;
            % I guess that value is now a string with the name that is
            % selected. the options are
            % {'Minimal_Impedance', 'BiologicalMoment', 'AssistShortening'}
            controller_value = 0; % default is minimal impdance
            if strcmp(value,'Minimal_Impedance')
                controller_value = 0;
                app.TextArea.Value = [app.TextArea.Value; {'Minimal Impedance controller selected'}];
            elseif strcmp(value,'BiologicalMoment')
                controller_value = 1;
                app.TextArea.Value = [app.TextArea.Value; {'BioMoment controller selected'}];
            elseif strcmp(value,'AssistShortening')
                controller_value = 2;
                app.TextArea.Value = [app.TextArea.Value; {'AssistShortening controller selected'}];
            end
            app.writeDouble(app.writeMap.ControllerMode,controller_value, app.tcClient_highlevel);
        end

        % Value changed function: applyassistanceCheckBox
        function applyassistanceCheckBoxValueChanged(app, event)
            bool_assistance = app.applyassistanceCheckBox.Value;
            if bool_assistance
                app.writeDouble(app.writeMap.ApplyAssistance, 1, app.tcClient_highlevel);
                app.TextArea.Value = [app.TextArea.Value; {'assistance turned on'}];
            else
                app.writeDouble(app.writeMap.ApplyAssistance, 0,app.tcClient_highlevel);
                app.TextArea.Value = [app.TextArea.Value; {'assistance turned off'}];
            end
        end

        % Button pushed function: zeroLoadcellLButton
        function zeroLoadcellLButtonPushed(app, event)
            app.pulse(app.writeMap.zero_loadcell_left, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' zero left loadcell finished'}];
        end

        % Button pushed function: zeroloadcellRButton
        function zeroloadcellRButtonPushed(app, event)
            app.pulse(app.writeMap.zero_loadcell_right, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' zero right loadcell finished'}];
        end

        % Button pushed function: zeroencoderLButton
        function zeroencoderLButtonPushed(app, event)
            app.pulse(app.writeMap.zero_encoder_left, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' zero left encoder finished'}];
        end

        % Button pushed function: zeroencoderRButton
        function zeroencoderRButtonPushed(app, event)
            app.pulse(app.writeMap.zero_encoder_right, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' zero right encoder finished'}];
        end

        % Button pushed function: maxplantarflexLButton
        function maxplantarflexLButtonPushed(app, event)
            app.pulse(app.writeMap.max_plantarflex_left, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' max left plantarflexion set'}];
        end

        % Button pushed function: maxplantarflexRButton
        function maxplantarflexRButtonPushed(app, event)
            app.pulse(app.writeMap.max_plantarflex_right, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' max right plantarflexion set'}];
        end

        % Button pushed function: maxdorsiflexLButton
        function maxdorsiflexLButtonPushed(app, event)
            app.pulse(app.writeMap.max_dorsiflex_left, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' max left dorsiflexion set'}];
        end

        % Button pushed function: maxdorsiflexRButton
        function maxdorsiflexRButtonPushed(app, event)
            app.pulse(app.writeMap.max_dorsiflex_right, app.dt_zero_sensors, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {' max right dorsiflexion set'}];
        end

        % Value changed function: enabledriveLCheckBox
        function enabledriveLCheckBoxValueChanged(app, event)
            value = app.enabledriveLCheckBox.Value;
            app.writeDouble(app.writeMap.enable_drives_left, value, app.tcClient_lowlevel);
            if value == 1
                app.TextArea.Value = [app.TextArea.Value; {' left motor drive enabled'}];
            else
                app.TextArea.Value = [app.TextArea.Value; {' left motor drive disabled'}];
            end
        end

        % Value changed function: enabledriveRCheckBox
        function enabledriveRCheckBoxValueChanged(app, event)
            value = app.enabledriveRCheckBox.Value;
            app.writeDouble(app.writeMap.enable_drives_right, value, app.tcClient_lowlevel);
            if value == 1
                app.TextArea.Value = [app.TextArea.Value; {' right motor drive enabled'}];
            else
                app.TextArea.Value = [app.TextArea.Value; {' right motor drive disabled'}];
            end
        end

        % Value changed function: enablemotorvelLCheckBox
        function enablemotorvelLCheckBoxValueChanged(app, event)
            value = app.enablemotorvelLCheckBox.Value;
            app.writeDouble(app.writeMap.enable_motor_velocity_left, value, app.tcClient_lowlevel);
            if value == 1
                app.TextArea.Value = [app.TextArea.Value; {' left motor vel enabled'}];
            else
                app.TextArea.Value = [app.TextArea.Value; {' left motor vel disabled'}];
            end

        end

        % Value changed function: enablemotorvelRCheckBox
        function enablemotorvelRCheckBoxValueChanged(app, event)
            value = app.enablemotorvelRCheckBox.Value;
            app.writeDouble(app.writeMap.enable_motor_velocity_right, value, app.tcClient_lowlevel);
            if value == 1
                app.TextArea.Value = [app.TextArea.Value; {' right motor vel enabled'}];
            else
                app.TextArea.Value = [app.TextArea.Value; {' right motor vel disabled'}];
            end

        end

        % Value changed function: enabledatacollectionCheckBox
        function enabledatacollectionCheckBoxValueChanged(app, event)
            bool_data_collection = app.enabledatacollectionCheckBox.Value;
            if bool_data_collection
                app.writeDouble(app.writeMap.enable_data_collection, 1, app.tcClient_lowlevel);
            else
                app.writeDouble(app.writeMap.enable_data_collection, 0, app.tcClient_lowlevel);
            end
            if bool_data_collection
                app.TextArea.Value = [app.TextArea.Value; {' data collection started'}];
            else
                app.TextArea.Value = [app.TextArea.Value; {' data collection stopped'}];
            end

        end

        % Value changed function: KpEditField
        function KpEditFieldValueChanged(app, event)
            value = app.KpEditField.Value;
            app.writeDouble(app.writeMap.pd_kp_left, value, app.tcClient_lowlevel);
            app.writeDouble(app.writeMap.pd_kp_right, value, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {[' kp set to ' num2str(value)]}];

        end

        % Value changed function: KdEditField
        function KdEditFieldValueChanged(app, event)
            value = app.KdEditField.Value;
            %app.writeDouble(app.writeMap.pd_kd, value, app.tcClient_lowlevel);
            app.writeDouble(app.writeMap.pd_kd_left, value, app.tcClient_lowlevel);
            app.writeDouble(app.writeMap.pd_kd_right, value, app.tcClient_lowlevel);
            app.TextArea.Value = [app.TextArea.Value; {[' kd set to ' num2str(value)]}];

        end

        % Value changed function: bexoEditField
        function bexoEditFieldValueChanged(app, event)
            value = app.bexoEditField.Value;
            app.writeDouble(app.writeMap.b_exo,value, app.tcClient_highlevel)
            app.TextArea.Value = [app.TextArea.Value; {[' bexo set to ' num2str(value)]}];

        end

        % Value changed function: PercentageAssistanceEditField
        function PercentageAssistanceEditFieldValueChanged(app, event)
            value = app.PercentageAssistanceEditField.Value;
            app.writeDouble(app.writeMap.perc_assistance, value/100, app.tcClient_highlevel)
            app.TextArea.Value = [app.TextArea.Value; {[' percentage assistance set to ' num2str(value)]}];

        end

        % Value changed function: MinimalTorqueEditField
        function MinimalTorqueEditFieldValueChanged(app, event)
            value = app.MinimalTorqueEditField.Value;
            app.writeDouble(app.writeMap.MinimalTorque, value, app.tcClient_highlevel)
            app.TextArea.Value = [app.TextArea.Value; {[' minimal torque set to ' num2str(value)]}];

        end

        % Value changed function: actdyn_typeDropDown
        function actdyn_typeDropDownValueChanged(app, event)
            value = app.actdyn_typeDropDown.Value;
            % two options, default is the default option
            output = 1;
            if strcmp(value, 'Simple')
                % do something
                output = 1;
            elseif strcmp(value, 'DeGroote2016')
                % do something else
                output = 2;
            end
            app.writeDouble(app.writeMap.actdyn_selection, output, app.tcClient_highlevel)
        end

        % Value changed function: cutoff_velEditField
        function cutoff_velEditFieldValueChanged(app, event)
            value = app.cutoff_velEditField.Value;
            app.writeDouble(app.writeMap.cutoff_vel, value, app.tcClient_highlevel)
        end

        % Value changed function: MaxTorqueEditField
        function MaxTorqueEditFieldValueChanged(app, event)
            value = app.MaxTorqueEditField.Value;
            app.writeDouble(app.writeMap.max_torque,value, app.tcClient_lowlevel);   
            app.TextArea.Value = [app.TextArea.Value; {[' max torque set to ' num2str(value)]}];

        end

        % Value changed function: durationzeroEditField
        function durationzeroEditFieldValueChanged(app, event)
            value = app.durationzeroEditField.Value;
            app.dt_zero_sensors = value;
        end

        % Button pushed function: PrintControlParametersButton
        function PrintControlParametersButtonPushed(app, event)
            % here we want to first fetch all the control params through
            % the ads stream and subsequently print all of the in the
            % command window
            % get all gui_output data

            %  read the highlevel param data
            if isempty(app.HighLevelParamHandle)
                warning('High-level params output handle missing; cannot print high-level parameters.');
                app.TextArea.Value = [app.TextArea.Value; {'Print skipped: highlevel_params_output handle missing'}];
                return;
            end

            %  read the highlevel param data
            app.tcClient_highlevel.Read(app.HighLevelParamHandle, app. HighLevelParamdata_target);
            for ind = 1:app.number_highlevel_param_outputs
                app.HighLevelParam_data(ind) = app.HighLevelParambin_target.ReadDouble;
            end
            app.HighLevelParamdata_target.Position = 0;

            % print all the highlevel param data
            app.TextArea.Value = [app.TextArea.Value; { '  '}];
            app.TextArea.Value = [app.TextArea.Value; { 'printing current highlevel controller parameters'}];
            for idata = 1:length(app.highlevel_params_headers)
                app.TextArea.Value = [app.TextArea.Value; {[ ' ' app.highlevel_params_headers{idata}, ' ',...
                    num2str(app.HighLevelParam_data(idata))]}];
            end

            % read the lowlevel param data

        end

        % Value changed function: resetdriveLCheckBox
        function resetdriveLCheckBoxValueChanged(app, event)
            value = app.resetdriveLCheckBox.Value;
            app.writeDouble(app.writeMap.reset_drive_left, value, app.tcClient_lowlevel)
            if value == 1
                app.TextArea.Value = [app.TextArea.Value; {' reset left drive set to 1'}];
            else
                app.TextArea.Value = [app.TextArea.Value; {' reset left drive set to 0'}];
            end
        end

        % Value changed function: resetdriveRCheckBox
        function resetdriveRCheckBoxValueChanged(app, event)
            value = app.resetdriveRCheckBox.Value;
            app.writeDouble(app.writeMap.reset_drive_right, value, app.tcClient_lowlevel)
            if value == 1
                app.TextArea.Value = [app.TextArea.Value; {' reset right drive set to 1'}];
            else
                app.TextArea.Value = [app.TextArea.Value; {' reset right drive set to 0'}];
            end
        end

        % Button pushed function: SetFolderDataLogButton
        function SetFolderDataLogButtonPushed(app, event)
            % set folder data logging
            datafolder = uigetdir();
            if isequal(datafolder, 0)
                app.datalogfolder = '';
                app.TextArea.Value = [app.TextArea.Value; {' no datafolder selected'}];
                return;
            end
            app.datalogfolder = datafolder;
            % also print selected file in the window
            app.TextArea.Value = [app.TextArea.Value; {['data log folder : ' app.datalogfolder]}];
        end

        % Button pushed function: CopyDataButton
        function CopyDataButtonPushed(app, event)

            if isempty(app.datalogfolder)
                app.TextArea.Value = [app.TextArea.Value; {' no datafolder selected'}];
                return;
            else
                % this copies all the *.mat files to the output folder
                mat_files = dir(fullfile('D:\LonitPeeters\data','*.mat'));
                for ifile = 1:length(mat_files)
                    file = mat_files(ifile);
                    copyfile(fullfile(file.folder,file.name),fullfile(app.datalogfolder,file.name));
                end
                % delete the original files after this ?
                for ifile = 1:length(mat_files)
                    file = mat_files(ifile);
                    delete(fullfile(file.folder,file.name));
                end

            end
        end

        % Button pushed function: clearButton
        function clearButtonPushed(app, event)
            app.TextArea.Value = {' .....'};
        end

        % Value changed function: ignoreerrorlowlevelCheckBox
        function ignoreerrorlowlevelCheckBoxValueChanged(app, event)
            value = app.ignoreerrorlowlevelCheckBox.Value;
            app.writeDouble(app.writeMap.ignore_errors, value, app.tcClient_lowlevel)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1536 728];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Theme = 'light';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create LeftMuscleMoments
            app.LeftMuscleMoments = uiaxes(app.UIFigure);
            title(app.LeftMuscleMoments, 'Left')
            ylabel(app.LeftMuscleMoments, 'Muscle Moment')
            zlabel(app.LeftMuscleMoments, 'Z')
            app.LeftMuscleMoments.Toolbar.Visible = 'off';
            app.LeftMuscleMoments.Position = [351 389 300 185];

            % Create RightMuscleMoments
            app.RightMuscleMoments = uiaxes(app.UIFigure);
            title(app.RightMuscleMoments, 'Right')
            ylabel(app.RightMuscleMoments, 'Muscle Moment')
            zlabel(app.RightMuscleMoments, 'Z')
            app.RightMuscleMoments.Toolbar.Visible = 'off';
            app.RightMuscleMoments.Position = [679 389 300 185];

            % Create LeftJointMoments
            app.LeftJointMoments = uiaxes(app.UIFigure);
            ylabel(app.LeftJointMoments, 'Ankle Moment')
            zlabel(app.LeftJointMoments, 'Z')
            app.LeftJointMoments.Toolbar.Visible = 'off';
            app.LeftJointMoments.Position = [351 201 300 185];

            % Create RightJointMoments
            app.RightJointMoments = uiaxes(app.UIFigure);
            ylabel(app.RightJointMoments, 'Ankle Moment')
            zlabel(app.RightJointMoments, 'Z')
            app.RightJointMoments.Toolbar.Visible = 'off';
            app.RightJointMoments.Position = [679 201 300 185];

            % Create Muscle_Act_right
            app.Muscle_Act_right = uiaxes(app.UIFigure);
            xlabel(app.Muscle_Act_right, 'Time [s]')
            ylabel(app.Muscle_Act_right, 'muscle activation')
            zlabel(app.Muscle_Act_right, 'Z')
            app.Muscle_Act_right.Position = [679 17 300 185];

            % Create Muscle_Act_left
            app.Muscle_Act_left = uiaxes(app.UIFigure);
            xlabel(app.Muscle_Act_left, 'Time [s]')
            ylabel(app.Muscle_Act_left, 'Muscle activation')
            zlabel(app.Muscle_Act_left, 'Z')
            app.Muscle_Act_left.Position = [351 17 300 185];

            % Create LowlevelcontrollersettingsPanel
            app.LowlevelcontrollersettingsPanel = uipanel(app.UIFigure);
            app.LowlevelcontrollersettingsPanel.Title = 'Low level controller settings';
            app.LowlevelcontrollersettingsPanel.BackgroundColor = [1 1 1];
            app.LowlevelcontrollersettingsPanel.Position = [11 402 328 190];

            % Create KpEditFieldLabel
            app.KpEditFieldLabel = uilabel(app.LowlevelcontrollersettingsPanel);
            app.KpEditFieldLabel.HorizontalAlignment = 'right';
            app.KpEditFieldLabel.Position = [39 41 25 22];
            app.KpEditFieldLabel.Text = 'Kp';

            % Create KpEditField
            app.KpEditField = uieditfield(app.LowlevelcontrollersettingsPanel, 'numeric');
            app.KpEditField.Limits = [0 200];
            app.KpEditField.ValueChangedFcn = createCallbackFcn(app, @KpEditFieldValueChanged, true);
            app.KpEditField.Position = [79 41 100 22];
            app.KpEditField.Value = 10;

            % Create KdEditFieldLabel
            app.KdEditFieldLabel = uilabel(app.LowlevelcontrollersettingsPanel);
            app.KdEditFieldLabel.HorizontalAlignment = 'right';
            app.KdEditFieldLabel.Position = [41 10 25 22];
            app.KdEditFieldLabel.Text = 'Kd';

            % Create KdEditField
            app.KdEditField = uieditfield(app.LowlevelcontrollersettingsPanel, 'numeric');
            app.KdEditField.ValueChangedFcn = createCallbackFcn(app, @KdEditFieldValueChanged, true);
            app.KdEditField.Position = [81 10 100 22];
            app.KdEditField.Value = 0.5;

            % Create PdcontrollerdesiredtorquetrackingLabel
            app.PdcontrollerdesiredtorquetrackingLabel = uilabel(app.LowlevelcontrollersettingsPanel);
            app.PdcontrollerdesiredtorquetrackingLabel.Position = [38 62 199 22];
            app.PdcontrollerdesiredtorquetrackingLabel.Text = 'Pd controller desired torque tracking';

            % Create MaxTorqueEditFieldLabel
            app.MaxTorqueEditFieldLabel = uilabel(app.LowlevelcontrollersettingsPanel);
            app.MaxTorqueEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxTorqueEditFieldLabel.Position = [7 102 64 22];
            app.MaxTorqueEditFieldLabel.Text = 'MaxTorque';

            % Create MaxTorqueEditField
            app.MaxTorqueEditField = uieditfield(app.LowlevelcontrollersettingsPanel, 'numeric');
            app.MaxTorqueEditField.ValueChangedFcn = createCallbackFcn(app, @MaxTorqueEditFieldValueChanged, true);
            app.MaxTorqueEditField.Position = [86 102 100 22];

            % Create durationzeroEditFieldLabel
            app.durationzeroEditFieldLabel = uilabel(app.LowlevelcontrollersettingsPanel);
            app.durationzeroEditFieldLabel.HorizontalAlignment = 'right';
            app.durationzeroEditFieldLabel.Position = [212 135 75 22];
            app.durationzeroEditFieldLabel.Text = 'duration zero';

            % Create durationzeroEditField
            app.durationzeroEditField = uieditfield(app.LowlevelcontrollersettingsPanel, 'numeric');
            app.durationzeroEditField.ValueChangedFcn = createCallbackFcn(app, @durationzeroEditFieldValueChanged, true);
            app.durationzeroEditField.Position = [212 113 100 22];
            app.durationzeroEditField.Value = 3;

            % Create HighlevelcontrollersettingsPanel
            app.HighlevelcontrollersettingsPanel = uipanel(app.UIFigure);
            app.HighlevelcontrollersettingsPanel.Title = 'High level controller settings';
            app.HighlevelcontrollersettingsPanel.BackgroundColor = [1 1 1];
            app.HighlevelcontrollersettingsPanel.Position = [11 -2 327 377];

            % Create SetParamsFileButton
            app.SetParamsFileButton = uibutton(app.HighlevelcontrollersettingsPanel, 'push');
            app.SetParamsFileButton.ButtonPushedFcn = createCallbackFcn(app, @SetParamsFileButtonPushed, true);
            app.SetParamsFileButton.Position = [26 312 102 29];
            app.SetParamsFileButton.Text = 'Set Params File';

            % Create UploadParamsButton
            app.UploadParamsButton = uibutton(app.HighlevelcontrollersettingsPanel, 'push');
            app.UploadParamsButton.ButtonPushedFcn = createCallbackFcn(app, @UploadParamsButtonPushed, true);
            app.UploadParamsButton.Position = [162 312 92 29];
            app.UploadParamsButton.Text = 'Upload Params';

            % Create applyassistanceCheckBox
            app.applyassistanceCheckBox = uicheckbox(app.HighlevelcontrollersettingsPanel);
            app.applyassistanceCheckBox.ValueChangedFcn = createCallbackFcn(app, @applyassistanceCheckBoxValueChanged, true);
            app.applyassistanceCheckBox.Text = 'apply assistance';
            app.applyassistanceCheckBox.Position = [38 27 111 22];

            % Create actdyn_typeDropDownLabel
            app.actdyn_typeDropDownLabel = uilabel(app.HighlevelcontrollersettingsPanel);
            app.actdyn_typeDropDownLabel.HorizontalAlignment = 'right';
            app.actdyn_typeDropDownLabel.Position = [26 227 70 22];
            app.actdyn_typeDropDownLabel.Text = 'actdyn_type';

            % Create actdyn_typeDropDown
            app.actdyn_typeDropDown = uidropdown(app.HighlevelcontrollersettingsPanel);
            app.actdyn_typeDropDown.Items = {'Simple', 'DeGroote2016'};
            app.actdyn_typeDropDown.ValueChangedFcn = createCallbackFcn(app, @actdyn_typeDropDownValueChanged, true);
            app.actdyn_typeDropDown.Position = [112 227 100 22];
            app.actdyn_typeDropDown.Value = 'Simple';

            % Create PercentageAssistanceEditFieldLabel
            app.PercentageAssistanceEditFieldLabel = uilabel(app.HighlevelcontrollersettingsPanel);
            app.PercentageAssistanceEditFieldLabel.HorizontalAlignment = 'right';
            app.PercentageAssistanceEditFieldLabel.Position = [22 135 127 22];
            app.PercentageAssistanceEditFieldLabel.Text = 'Percentage Assistance';

            % Create PercentageAssistanceEditField
            app.PercentageAssistanceEditField = uieditfield(app.HighlevelcontrollersettingsPanel, 'numeric');
            app.PercentageAssistanceEditField.ValueChangedFcn = createCallbackFcn(app, @PercentageAssistanceEditFieldValueChanged, true);
            app.PercentageAssistanceEditField.Position = [164 135 100 22];

            % Create MinimalTorqueEditFieldLabel
            app.MinimalTorqueEditFieldLabel = uilabel(app.HighlevelcontrollersettingsPanel);
            app.MinimalTorqueEditFieldLabel.HorizontalAlignment = 'right';
            app.MinimalTorqueEditFieldLabel.Position = [64 98 86 22];
            app.MinimalTorqueEditFieldLabel.Text = 'Minimal Torque';

            % Create MinimalTorqueEditField
            app.MinimalTorqueEditField = uieditfield(app.HighlevelcontrollersettingsPanel, 'numeric');
            app.MinimalTorqueEditField.ValueChangedFcn = createCallbackFcn(app, @MinimalTorqueEditFieldValueChanged, true);
            app.MinimalTorqueEditField.Position = [165 98 100 22];

            % Create bexoEditFieldLabel
            app.bexoEditFieldLabel = uilabel(app.HighlevelcontrollersettingsPanel);
            app.bexoEditFieldLabel.HorizontalAlignment = 'right';
            app.bexoEditFieldLabel.Position = [119 66 31 22];
            app.bexoEditFieldLabel.Text = 'bexo';

            % Create bexoEditField
            app.bexoEditField = uieditfield(app.HighlevelcontrollersettingsPanel, 'numeric');
            app.bexoEditField.ValueChangedFcn = createCallbackFcn(app, @bexoEditFieldValueChanged, true);
            app.bexoEditField.Position = [165 66 100 22];

            % Create cutoff_velEditFieldLabel
            app.cutoff_velEditFieldLabel = uilabel(app.HighlevelcontrollersettingsPanel);
            app.cutoff_velEditFieldLabel.HorizontalAlignment = 'right';
            app.cutoff_velEditFieldLabel.Position = [93 177 56 22];
            app.cutoff_velEditFieldLabel.Text = 'cutoff_vel';

            % Create cutoff_velEditField
            app.cutoff_velEditField = uieditfield(app.HighlevelcontrollersettingsPanel, 'numeric');
            app.cutoff_velEditField.ValueChangedFcn = createCallbackFcn(app, @cutoff_velEditFieldValueChanged, true);
            app.cutoff_velEditField.Position = [164 177 100 22];

            % Create SelectControllerDropDownLabel
            app.SelectControllerDropDownLabel = uilabel(app.HighlevelcontrollersettingsPanel);
            app.SelectControllerDropDownLabel.HorizontalAlignment = 'right';
            app.SelectControllerDropDownLabel.Position = [8 265 94 22];
            app.SelectControllerDropDownLabel.Text = 'Select Controller';

            % Create SelectControllerDropDown
            app.SelectControllerDropDown = uidropdown(app.HighlevelcontrollersettingsPanel);
            app.SelectControllerDropDown.Items = {'Minimal_Impedance', 'BiologicalMoment', 'AssistShortening'};
            app.SelectControllerDropDown.ValueChangedFcn = createCallbackFcn(app, @SelectControllerDropDownValueChanged, true);
            app.SelectControllerDropDown.Position = [113 265 129 22];
            app.SelectControllerDropDown.Value = 'Minimal_Impedance';

            % Create InitLowlevelcontrollerPanel
            app.InitLowlevelcontrollerPanel = uipanel(app.UIFigure);
            app.InitLowlevelcontrollerPanel.Title = 'Init Lowlevel controller';
            app.InitLowlevelcontrollerPanel.BackgroundColor = [1 1 1];
            app.InitLowlevelcontrollerPanel.Position = [11 596 963 126];

            % Create zeroLoadcellLButton
            app.zeroLoadcellLButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.zeroLoadcellLButton.ButtonPushedFcn = createCallbackFcn(app, @zeroLoadcellLButtonPushed, true);
            app.zeroLoadcellLButton.Position = [25 73 100 22];
            app.zeroLoadcellLButton.Text = 'zero Loadcell  L';

            % Create zeroloadcellRButton
            app.zeroloadcellRButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.zeroloadcellRButton.ButtonPushedFcn = createCallbackFcn(app, @zeroloadcellRButtonPushed, true);
            app.zeroloadcellRButton.Position = [25 27 100 22];
            app.zeroloadcellRButton.Text = 'zero loadcell  R';

            % Create zeroencoderLButton
            app.zeroencoderLButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.zeroencoderLButton.ButtonPushedFcn = createCallbackFcn(app, @zeroencoderLButtonPushed, true);
            app.zeroencoderLButton.Position = [164 74 100 22];
            app.zeroencoderLButton.Text = 'zero encoder L';

            % Create maxplantarflexLButton
            app.maxplantarflexLButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.maxplantarflexLButton.ButtonPushedFcn = createCallbackFcn(app, @maxplantarflexLButtonPushed, true);
            app.maxplantarflexLButton.Position = [305 74 106 22];
            app.maxplantarflexLButton.Text = 'max plantarflex L';

            % Create maxdorsiflexLButton
            app.maxdorsiflexLButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.maxdorsiflexLButton.ButtonPushedFcn = createCallbackFcn(app, @maxdorsiflexLButtonPushed, true);
            app.maxdorsiflexLButton.Position = [448 74 100 22];
            app.maxdorsiflexLButton.Text = 'max dorsiflex L';

            % Create zeroencoderRButton
            app.zeroencoderRButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.zeroencoderRButton.ButtonPushedFcn = createCallbackFcn(app, @zeroencoderRButtonPushed, true);
            app.zeroencoderRButton.Position = [164 28 100 22];
            app.zeroencoderRButton.Text = 'zero encoder R';

            % Create maxplantarflexRButton
            app.maxplantarflexRButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.maxplantarflexRButton.ButtonPushedFcn = createCallbackFcn(app, @maxplantarflexRButtonPushed, true);
            app.maxplantarflexRButton.Position = [304 28 108 22];
            app.maxplantarflexRButton.Text = 'max plantarflex R';

            % Create maxdorsiflexRButton
            app.maxdorsiflexRButton = uibutton(app.InitLowlevelcontrollerPanel, 'push');
            app.maxdorsiflexRButton.ButtonPushedFcn = createCallbackFcn(app, @maxdorsiflexRButtonPushed, true);
            app.maxdorsiflexRButton.Position = [448 28 100 22];
            app.maxdorsiflexRButton.Text = 'max dorsiflex R';

            % Create enabledriveLCheckBox
            app.enabledriveLCheckBox = uicheckbox(app.InitLowlevelcontrollerPanel);
            app.enabledriveLCheckBox.ValueChangedFcn = createCallbackFcn(app, @enabledriveLCheckBoxValueChanged, true);
            app.enabledriveLCheckBox.Text = 'enable drive L';
            app.enabledriveLCheckBox.Position = [598 74 97 22];

            % Create enablemotorvelLCheckBox
            app.enablemotorvelLCheckBox = uicheckbox(app.InitLowlevelcontrollerPanel);
            app.enablemotorvelLCheckBox.ValueChangedFcn = createCallbackFcn(app, @enablemotorvelLCheckBoxValueChanged, true);
            app.enablemotorvelLCheckBox.Text = 'enable motor vel L';
            app.enablemotorvelLCheckBox.Position = [839 75 120 22];

            % Create enabledriveRCheckBox
            app.enabledriveRCheckBox = uicheckbox(app.InitLowlevelcontrollerPanel);
            app.enabledriveRCheckBox.ValueChangedFcn = createCallbackFcn(app, @enabledriveRCheckBoxValueChanged, true);
            app.enabledriveRCheckBox.Text = 'enable drive R';
            app.enabledriveRCheckBox.Position = [598 29 99 22];

            % Create enablemotorvelRCheckBox
            app.enablemotorvelRCheckBox = uicheckbox(app.InitLowlevelcontrollerPanel);
            app.enablemotorvelRCheckBox.ValueChangedFcn = createCallbackFcn(app, @enablemotorvelRCheckBoxValueChanged, true);
            app.enablemotorvelRCheckBox.Text = 'enable motor vel R';
            app.enablemotorvelRCheckBox.Position = [837 30 122 22];

            % Create resetdriveLCheckBox
            app.resetdriveLCheckBox = uicheckbox(app.InitLowlevelcontrollerPanel);
            app.resetdriveLCheckBox.ValueChangedFcn = createCallbackFcn(app, @resetdriveLCheckBoxValueChanged, true);
            app.resetdriveLCheckBox.Text = 'reset drive L';
            app.resetdriveLCheckBox.Position = [718 76 87 22];

            % Create resetdriveRCheckBox
            app.resetdriveRCheckBox = uicheckbox(app.InitLowlevelcontrollerPanel);
            app.resetdriveRCheckBox.ValueChangedFcn = createCallbackFcn(app, @resetdriveRCheckBoxValueChanged, true);
            app.resetdriveRCheckBox.Text = 'reset drive R';
            app.resetdriveRCheckBox.Position = [718 31 89 22];

            % Create ignoreerrorlowlevelCheckBox
            app.ignoreerrorlowlevelCheckBox = uicheckbox(app.InitLowlevelcontrollerPanel);
            app.ignoreerrorlowlevelCheckBox.ValueChangedFcn = createCallbackFcn(app, @ignoreerrorlowlevelCheckBoxValueChanged, true);
            app.ignoreerrorlowlevelCheckBox.Text = 'ignore error lowlevel';
            app.ignoreerrorlowlevelCheckBox.Position = [598 1 129 22];

            % Create enabledatacollectionCheckBox
            app.enabledatacollectionCheckBox = uicheckbox(app.UIFigure);
            app.enabledatacollectionCheckBox.ValueChangedFcn = createCallbackFcn(app, @enabledatacollectionCheckBoxValueChanged, true);
            app.enabledatacollectionCheckBox.Text = 'enable data collection';
            app.enabledatacollectionCheckBox.Position = [40 536 137 22];

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Position = [988 17 543 655];

            % Create PrintControlParametersButton
            app.PrintControlParametersButton = uibutton(app.UIFigure, 'push');
            app.PrintControlParametersButton.ButtonPushedFcn = createCallbackFcn(app, @PrintControlParametersButtonPushed, true);
            app.PrintControlParametersButton.Position = [1018 692 146 22];
            app.PrintControlParametersButton.Text = 'Print Control Parameters';

            % Create SetFolderDataLogButton
            app.SetFolderDataLogButton = uibutton(app.UIFigure, 'push');
            app.SetFolderDataLogButton.ButtonPushedFcn = createCallbackFcn(app, @SetFolderDataLogButtonPushed, true);
            app.SetFolderDataLogButton.Position = [1186 692 130 22];
            app.SetFolderDataLogButton.Text = 'SetFolderDataLog';

            % Create CopyDataButton
            app.CopyDataButton = uibutton(app.UIFigure, 'push');
            app.CopyDataButton.ButtonPushedFcn = createCallbackFcn(app, @CopyDataButtonPushed, true);
            app.CopyDataButton.Position = [1340 692 100 22];
            app.CopyDataButton.Text = 'CopyData';

            % Create clearButton
            app.clearButton = uibutton(app.UIFigure, 'push');
            app.clearButton.ButtonPushedFcn = createCallbackFcn(app, @clearButtonPushed, true);
            app.clearButton.Position = [1467 672 64 22];
            app.clearButton.Text = 'clear';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Assist_Shortening_GUI_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end