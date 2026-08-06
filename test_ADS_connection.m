%% Minimal example test ADS connection
%--------------------------------------

% user inputs
Simulink_source_name = 'Exosoft_Controller';
test_modelparam = 'Constant25_Value'; % this is sample time in the controller
test_output = 'exo_torque_desired_highlevel_l';

% ADS
asm = NET.addAssembly('C:\TwinCAT\AdsApi\.NET\v4.0.30319\TwinCAT.Ads.dll');
import TwinCAT.Ads.*
ads_netid_str = '172.18.234.64.1.1';
ads_port = 350;
tcClient = TwinCAT.Ads.TcAdsClient;
ams_id = TwinCAT.Ads.AmsNetId(ads_netid_str);
tcClient.Connect(ams_id, ads_port);


% Read target
ads_target_name = [Simulink_source_name '.Output.' test_output];
try
    sourceBlock = tcClient.CreateVariableHandle(ads_target_name);
    disp('create output variable handle done');
catch e
    warning(['I cannot find my signals in the ADS server.',...
        'Possibly TwinCAT3 is not in run-mode, or the required model is not running.']);
end

% check create
ads_target_name  = [Simulink_source_name '.ModelParameters.' test_modelparam];
try
    ads_target_handle = tcClient.CreateVariableHandle(ads_target_name);
    disp('create model variable handle done');
catch e
    disp('problem with model variable')
    warning(e.message);
end

%% check read block

dataStream_target = TwinCAT.Ads.AdsStream(8);
binRead_target = TwinCAT.Ads.AdsBinaryReader(dataStream_target);
dataStream_target.Position = 0;
try
    tcClient.Read(sourceBlock,dataStream_target);
    my_double = binRead_target.ReadDouble;
    disp(['Successfully read output: ', num2str(my_double)]);
catch e
    disp('problem with data stream read');
    warning(e.message);
end


%% check the send block

try
    % try to send value 1
    data_bytes = typecast(double(10), 'uint8');
    tcClient.WriteAny(ads_target_handle,data_bytes);
    disp('Successfully wrote parameter');
catch e
    disp('problem with sending block')
    warning(e.message);
end





