function GUI(arg)
clc
guimode = 1;nargin;
%% to avoid creating hundreds of timers
listOfTimers = timerfindall;
if ~isempty(listOfTimers)
    delete(listOfTimers(:));
end

%% ADS
asm = NET.addAssembly('C:\TwinCAT\AdsApi\.NET\v4.0.30319\TwinCAT.Ads.dll');
import TwinCAT.Ads.*
%ads_netid_str = '127.0.0.1.1.1';
ads_netid_str = '172.18.234.64.1.1';
ads_port = 350;
tcClient = TwinCAT.Ads.TcAdsClient;
ams_id = TwinCAT.Ads.AmsNetId(ads_netid_str);
tcClient.Connect(ams_id, ads_port);

%% Read target
source_name = 'Exosoft_Controller.Output.gui_out';
try
    sourceBlock = tcClient.CreateVariableHandle(source_name);
catch e
    error('I cannot find my signals in the ADS server. Possibly TwinCAT3 is not in run-mode, or the required model is not running.');
end
fprintf('[%s] ADS connection successful.\n',datestr(now,'HH:MM:SS'))
length_target = 20*8; %20 vars, 8 bytes per double = 160 bytes
dataStream_target = TwinCAT.Ads.AdsStream(length_target);
binRead_target = TwinCAT.Ads.AdsBinaryReader(dataStream_target);
dataRead = zeros(length_target/8);
loggerstate = true;
%% Send targets
% Knee
ecmp = 'Exosoft_Controller.ModelParameters.' ;
ads.target(1).name = 'PosCtrlTrigger_Knee_Value';
ads.target(2).name = 'SlackCtrlTrigger_Knee_Value';
ads.target(3).name = 'TrqCtrlTrigger_Knee_Value';
ads.target(4).name = 'StopTrigger_Knee_Value';
ads.target(5).name = 'ErrAck_Knee_Value';
ads.target(6).name = 'HybridTrigger_Knee_Value';%'MotorAngleOffsetWrtJoint_Knee_V';
ads.target(7).name = 'ManualOffset_Knee_Value';
ads.target(8).name = 'TorqueRef_Knee_Value';
ads.target(9).name = '';%'AllowedInitialAngleError_deg_Kn'; %knee!
ads.target(10).name = 'AllowedTrackingError_deg_Knee_V';

%% Ankle
ads.target(11).name = 'PosCtrlTrigger_Ankle_Value';
ads.target(12).name = 'SlackCtrlTrigger_Ankle_Value';
ads.target(13).name = 'TrqCtrlTrigger_Ankle_Value';
ads.target(14).name = 'StopTrigger_Ankle_Value';
ads.target(15).name = 'ErrAck_Ankle_Value';
ads.target(16).name = 'HybridTrigger_Ankle_Value';%'MotorAngleOffsetWrtJoint_Ankle_';
ads.target(17).name = 'ManualOffset_Ankle_Value';
ads.target(18).name = 'TorqueRef_Ankle_Value';
ads.target(19).name = '';%'AllowedInitialAngleError_deg_An'; %ankle
ads.target(20).name = 'AllowedTrackingError_deg_Ankle_';
%% general
ads.target(21).name = 'TorqueLimit_Value';
ads.target(22).name = 'doLog_Value';
ads.target(23).name = 'CalibrateMotorOffset_Value';

%% check
for idx = 1:length(ads.target)
    if strcmp(ads.target(idx).name,'')
        continue;
    end
    ads.target(idx).name = [ecmp ads.target(idx).name]; %append
    ads.target(idx).size = 1;
    ads.target(idx).datasize = ads.target(idx).size*8;
    try
        ads.target(idx).handle = tcClient.CreateVariableHandle(ads.target(idx).name);
    catch e
        fprintf('Problematic handle: %s\n',ads.target(idx).name)
        error(e.message);
    end
end

%% GUI Window
hf = figure();
set(hf, 'MenuBar', 'none', 'ToolBar', 'none','CloseRequestFcn',@(obj,event) close_req_fcn(obj,event));
hf.Units = 'normalized';
set(hf,'outerposition',[0.1 0.1 0.4 0.8],'Name','Exosoft GUI','NumberTitle','off');
handles = initGUI();
handles.fighandle = hf;
pause(0.5)

%% GUI Timer
gui_dt = 0.1; %10 Hz update
looptimer = timer('StartDelay', 0, 'Period', gui_dt,'ExecutionMode','fixedRate');
looptimer.StartFcn = @timer_start_fcn;
looptimer.StopFcn = @timer_stop_fcn;
looptimer.TimerFcn = {@timer_update_fcn,handles};

%% Start
start(looptimer)

%%
    function close_req_fcn(obj,event)
       try
           stop(looptimer);
       catch
       end
       pause(0.001);
       delete(get(0,'CurrentFigure'))
    end

    function timer_start_fcn(obj, event)
        fprintf('[%s] GUI Started.\n',datestr(now,'HH:MM:SS'))
    end

    function timer_stop_fcn(obj, event)
        try
            tcClient.Close;
        catch e
            disp(e.message);
        end
        fprintf('[%s] ADS connection closed.\n',datestr(now,'HH:MM:SS'))
    end

    function timer_update_fcn(obj, event, h)
        if guimode ~= 0
        try
            tcClient.Read(sourceBlock,dataStream_target);
        catch e
            %disp(e) %debug
            disp(e.message);
            stop(looptimer);
            return;
        end
        dataRead = zeros(length_target/8,1);
        for ind = 1:length_target/8
            dataRead(ind) = binRead_target.ReadDouble;
        end
        dataStream_target.Position = 0;
        end
        %update display
%         dataRead
%         disp('UpdateGui')
        updateGUI();
    end

    function updateGUI()
        str = {'Disabled','Pos. Hold','Torque','Slack Homing','Slack','HSlack Homing','HSlack','HTorque'};
        
        % 0 = none
        % 1 = Vel too high
        % 2 = Trq too high
        % 3 = Vel+Trq
        % 4 = Track err too high
        % 5 = Vel + Track
        % 6 = Trq + Track
        % 7 = Trck + Vel + Trq
        
        errstr = {'None','Vel.','Torq.','Vel.+Torq.','Track. err.','Vel.+Track','Torq.+Track','Track+Vel.+Torq.','a','b'};
%         handles.gui_elements(1).txt_State.string = num2str(str{dataRead(7)+1});
        updateTxt(1,'txt_State','State:',str{dataRead(7)+1});%num2str(str{dataRead(7)+1}));
        updateTxt(1,'txt_Error','Error:',errstr{dataRead(6)+1});%,num2str(dataRead(6)));
        updateTxt(1,'txt_ErrorL','Err. Latch:',errstr{dataRead(5)+1});%num2str(dataRead(5)));
        updateTxt(1,'txt_JointAngle','Jnt. ang.:',num2str(dataRead(3)));
        updateTxt(1,'txt_MotorAngle','Mot. ang.:',num2str(dataRead(1)));
        updateTxt(1,'txt_MeasMotTrq','Mot. Trq. m:',num2str(dataRead(2)));
        updateTxt(1,'txt_MotRefSlack','Mot. posref.:',num2str(dataRead(8)));
        
        updateTxt(2,'txt_State','State:',str{dataRead(16)+1});%num2str(str{dataRead(16)+1}));
        updateTxt(2,'txt_Error','Error:',errstr{dataRead(15)+1});%,num2str(dataRead(15)));
        updateTxt(2,'txt_ErrorL','Err. Latch:',errstr{dataRead(14)+1});%,num2str(dataRead(14)));
        updateTxt(2,'txt_JointAngle','Jnt. ang.:',num2str(dataRead(12)));
        updateTxt(2,'txt_MotorAngle','Mot. ang.:',num2str(dataRead(10)));
        updateTxt(2,'txt_MeasMotTrq','Mot. trq.:',num2str(dataRead(11)));
        updateTxt(2,'txt_MotRefSlack','Mot. posref.:',num2str(dataRead(17)));
    end

    function updateTxt(panel,label,prefix,str)
        str=sprintf('handles.gui_elements(%i).%s.String = ''%s %s'';',panel,char(label),char(prefix),char(str));
%         disp(str);
        eval(str);
    end

    function handles_ = initGUI()
        handles_.gui_panel(1) = uipanel('Position',[0.05 0.45 0.9 0.4],'Title','Knee'); %x,y, w, h (from bottom)
        handles_.gui_panel(2) = uipanel('Position',[0.05 0.025 0.9 0.4],'Title','Ankle'); %x,y, w, h (from bottom)
        handles_.gui_panel(3) = uipanel('Position',[0.05 0.875 0.9 0.1],'Title','General'); %x,y, w, h (from bottom)
        handles_.btn_DisableAll = uicontrol(handles_.gui_panel(3),'style','pushbutton','callback',{@cb_fun_btn_DisableAll},'units','normalized','position',[0.04,0.1,0.2,0.8],'string','Disable ALL','FontSize',10,'FontWeight','bold');
        handles_.btn_SlackAll = uicontrol(handles_.gui_panel(3),'style','pushbutton','callback',{@cb_fun_btn_AllSlack},'units','normalized','position',[0.28,0.1,0.2,0.8],'string','ALL Slack','FontSize',10,'FontWeight','bold');
        handles_.btn_DoLog = uicontrol(handles_.gui_panel(3),'style','pushbutton','callback',{@cb_fun_btn_ToggleLogger},'units','normalized','position',[0.76,0.1,0.2,0.8],'string','Logger...','FontSize',10,'FontWeight','bold');
        handles_.btn_CalibSlack = uicontrol(handles_.gui_panel(3),'style','pushbutton','callback',{@cb_fun_btn_CalibSlack},'units','normalized','position',[0.52,0.1,0.2,0.8],'string','(Re)Calib Slack','FontSize',10,'FontWeight','bold');
       
        %knee
        handles_.gui_elements(1).btn_PosCtrl =  uicontrol(handles_.gui_panel(1),'style','pushbutton','callback',{@cb_fun_btn_PosCtrl_Knee},'units','normalized','position',[0.025,0.025,0.3,0.15],'string','Pos. Hold Mode');
        handles_.gui_elements(1).btn_TrqCtrl =  uicontrol(handles_.gui_panel(1),'style','pushbutton','callback',{@cb_fun_btn_TrqCtrl_Knee},'units','normalized','position',[0.025,0.225,0.3,0.15],'string','Torque Mode');
        handles_.gui_elements(1).btn_SlackCtrl =  uicontrol(handles_.gui_panel(1),'style','pushbutton','callback',{@cb_fun_btn_SlackCtrl_Knee},'units','normalized','position',[0.025,0.425,0.3,0.15],'string','Slack Mode');
        handles_.gui_elements(1).btn_ErrAck =  uicontrol(handles_.gui_panel(1),'style','pushbutton','callback',{@cb_fun_btn_ErrAck_Knee},'units','normalized','position',[0.025,0.625,0.3,0.15],'string','Error Acknowledged');
        handles_.gui_elements(1).btn_Disable =  uicontrol(handles_.gui_panel(1),'style','pushbutton','callback',{@cb_fun_btn_Stop_Knee},'units','normalized','position',[0.025,0.825,0.3,0.15],'string','Disable');
        handles_.gui_elements(1).txt_State = uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.35,0.85,0.4,0.1],'string','State: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(1).txt_Error = uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.35,0.75,0.4,0.1],'string','Error: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(1).txt_ErrorL = uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.35,0.65,0.4,0.1],'string','Err. Latch: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(1).txt_JointAngle = uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.35,0.55,0.4,0.1],'string','Jnt. ang.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(1).txt_MotorAngle = uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.35,0.45,0.4,0.1],'string','Mot. ang.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(1).txt_MeasMotTrq = uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.35,0.35,0.4,0.1],'string','Mot. trq.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(1).txt_MotRefSlack = uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.35,0.25,0.4,0.1],'string','M. sl. ref.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);

        handles_.gui_elements(1).btn_HybCtrl =  uicontrol(handles_.gui_panel(1),'style','pushbutton','callback',{@cb_fun_btn_Hybrid_Knee},'units','normalized','position',[0.35,0.025,0.3,0.15],'string','Hybrid Mode');
        
        uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.7,0.87,0.4,0.1],'string','Constant Torque Offset (Nm)','HorizontalAlignment','left','FontSize',10);
        handles_.gui_elements(1).sld_ConstantTorque = uicontrol(handles_.gui_panel(1),'style','slider','callback',{@cb_fun_TrqSldr_Knee},'units','normalized','position',[0.70,0.8,0.275,0.075],'min',-1,'max',1,'value',0,'enable','on','SliderStep',[0.05 0.10]);
        uicontrol(handles_.gui_panel(1),'style','text','units','normalized','position',[0.7,0.67,0.4,0.1],'string','Constant Slider Offset (deg)','HorizontalAlignment','left','FontSize',10);
        handles_.gui_elements(1).sld_OffsetSliderPos = uicontrol(handles_.gui_panel(1),'style','slider','callback',{@cb_fun_PosSldr_Knee},'units','normalized','position',[0.70,0.6,0.275,0.075],'min',-50,'max',50,'value',0,'enable','on','SliderStep',[0.01 0.01]);
    %'min',-42,'max',23
        %ankle
        handles_.gui_elements(2).btn_PosCtrl =  uicontrol(handles_.gui_panel(2),'style','pushbutton','callback',{@cb_fun_btn_PosCtrl_Ankle},'units','normalized','position',[0.025,0.025,0.3,0.15],'string','Pos. Hold Mode');
        handles_.gui_elements(2).btn_TrqCtrl =  uicontrol(handles_.gui_panel(2),'style','pushbutton','callback',{@cb_fun_btn_TrqCtrl_Ankle},'units','normalized','position',[0.025,0.225,0.3,0.15],'string','Torque Mode');
        handles_.gui_elements(2).btn_SlackCtrl =  uicontrol(handles_.gui_panel(2),'style','pushbutton','callback',{@cb_fun_btn_SlackCtrl_Ankle},'units','normalized','position',[0.025,0.425,0.3,0.15],'string','Slack Mode');
        handles_.gui_elements(2).btn_ErrAck =  uicontrol(handles_.gui_panel(2),'style','pushbutton','callback',{@cb_fun_btn_ErrAck_Ankle},'units','normalized','position',[0.025,0.625,0.3,0.15],'string','Error Acknowledged');
        handles_.gui_elements(2).btn_Disable =  uicontrol(handles_.gui_panel(2),'style','pushbutton','callback',{@cb_fun_btn_Stop_Ankle},'units','normalized','position',[0.025,0.825,0.3,0.15],'string','Disable');
        handles_.gui_elements(2).txt_State = uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.35,0.85,0.4,0.1],'string','State: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(2).txt_Error = uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.35,0.75,0.4,0.1],'string','Error: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(2).txt_ErrorL = uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.35,0.65,0.4,0.1],'string','Err. Latch: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(2).txt_JointAngle = uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.35,0.55,0.4,0.1],'string','Jnt. ang.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(2).txt_MotorAngle = uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.35,0.45,0.4,0.1],'string','Mot. ang.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(2).txt_MeasMotTrq = uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.35,0.35,0.4,0.1],'string','Mot. trq.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
        handles_.gui_elements(2).txt_MotRefSlack = uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.35,0.25,0.4,0.1],'string','M. sl. ref.: ???','FontWeight','bold','HorizontalAlignment','left','FontSize',12);
       
        handles_.gui_elements(2).btn_HybCtrl =  uicontrol(handles_.gui_panel(2),'style','pushbutton','callback',{@cb_fun_btn_Hybrid_Ankle},'units','normalized','position',[0.35,0.025,0.3,0.15],'string','Hybrid Mode');
         
        uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.7,0.87,0.4,0.1],'string','Constant Torque Offset (Nm)','HorizontalAlignment','left','FontSize',10);
        handles_.gui_elements(2).sld_ConstantTorque = uicontrol(handles_.gui_panel(2),'style','slider','callback',{@cb_fun_TrqSldr_Ankle},'units','normalized','position',[0.70,0.8,0.275,0.075],'min',-1,'max',1,'value',0,'enable','on','SliderStep',[0.05 0.10]);
        uicontrol(handles_.gui_panel(2),'style','text','units','normalized','position',[0.7,0.67,0.4,0.1],'string','Constant Slider Offset (deg)','HorizontalAlignment','left','FontSize',10);
        handles_.gui_elements(2).sld_OffsetSliderPos = uicontrol(handles_.gui_panel(2),'style','slider','callback',{@cb_fun_PosSldr_Ankle},'units','normalized','position',[0.70,0.6,0.275,0.075],'min',-60,'max',60,'value',0,'enable','on','SliderStep',[0.02 0.02]);
  

        drawnow
    end

    function sendADSMessage(target,value)
        %send only 1 double
        data_bytes = typecast(double(value(1)), 'uint8');
        try
            tcClient.WriteAny(target.handle,data_bytes);
        catch e
            error(e.message);
        end
    end


    function toggleInput(n)
       sendADSMessage(ads.target(n),1);
       pause(0.1);
       sendADSMessage(ads.target(n),0);
    end

    function cb_fun_btn_Hybrid_Knee(obj,event)
       toggleInput(6); 
    end
    function cb_fun_btn_Hybrid_Ankle(obj,event)
       toggleInput(16); 
    end
    function cb_fun_btn_PosCtrl_Knee(obj,event)
        toggleInput(1);
    end
    function cb_fun_btn_SlackCtrl_Knee(obj,event)
        toggleInput(2);
    end
    function cb_fun_btn_TrqCtrl_Knee(obj,event)
        handles.gui_elements(1).sld_ConstantTorque.Value = 0;
        toggleInput(3);
    end
    function cb_fun_btn_Stop_Knee(obj,event)
        toggleInput(4);
    end
    function cb_fun_btn_ErrAck_Knee(obj,event)
        toggleInput(5);
    end

    function cb_fun_btn_PosCtrl_Ankle(obj,event)
        toggleInput(11);
    end
    function cb_fun_btn_SlackCtrl_Ankle(obj,event)
        toggleInput(12);       
    end
    function cb_fun_btn_TrqCtrl_Ankle(obj,event)
        handles.gui_elements(2).sld_ConstantTorque.Value = 0;
        toggleInput(13);        
    end
    function cb_fun_btn_Stop_Ankle(obj,event)
        toggleInput(14);        
    end
    function cb_fun_btn_ErrAck_Ankle(obj,event)
        toggleInput(15);
    end

    function cb_fun_btn_DisableAll(obj,event)
        sendADSMessage(ads.target(4),1);
        sendADSMessage(ads.target(14),1);
        pause(0.1)
        sendADSMessage(ads.target(4),0);
        sendADSMessage(ads.target(14),0);
    end
    function cb_fun_btn_AllSlack(obj,event)
        toggleInput(2);
        toggleInput(12); 
    end
    function cb_fun_btn_CalibSlack(obj,event)
        toggleInput(23);

    end
    function cb_fun_btn_ToggleLogger(obj,event)
        loggerstate = ~loggerstate;
        if (loggerstate)
            handles.btn_DoLog.String = 'Log now ON';
        else
            handles.btn_DoLog.String = 'Log now OFF';
        end
        sendADSMessage(ads.target(22),double(loggerstate));
    end

    function cb_fun_TrqSldr_Knee(obj,event)
        val = handles.gui_elements(1).sld_ConstantTorque.Value;
        sendADSMessage(ads.target(8),val);
    end
    function cb_fun_TrqSldr_Ankle(obj,event)
        val = handles.gui_elements(2).sld_ConstantTorque.Value;
        sendADSMessage(ads.target(18),val);
    end
    function cb_fun_PosSldr_Knee(obj,event)
        val = handles.gui_elements(1).sld_OffsetSliderPos.Value;
        sendADSMessage(ads.target(7),val);
    end
    function cb_fun_PosSldr_Ankle(obj,event)
        val = handles.gui_elements(2).sld_OffsetSliderPos.Value;
        sendADSMessage(ads.target(17),val);
    end
end