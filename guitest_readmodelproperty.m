%% Minimal example test ADS connection
%--------------------------------------

% info high level controller
Simulink_source_name = 'jlo_assist_short_explicit_clean_Lonit'; % name simulink model
test_modelparam = 'MinimalTorque_Value'; % this is sample time in the controller

% ADS
asm = NET.addAssembly('C:\TwinCAT\AdsApi\.NET\v4.0.30319\TwinCAT.Ads.dll');
import TwinCAT.Ads.*
ads_netid_str = '130.89.78.82.1.1';
ads_port = 351;
tcClient = TwinCAT.Ads.TcAdsClient;
ams_id = TwinCAT.Ads.AmsNetId(ads_netid_str);
tcClient.Connect(ams_id, ads_port);


% check create
ads_target_name  = [Simulink_source_name '.ModelParameters.' test_modelparam];
try
    ads_target_handle = tcClient.CreateVariableHandle(ads_target_name);
    disp('create model variable handle done');
catch e
    disp('problem with model variable')
    warning(e.message);
end

% try to read from ModelParameters handle
dataStream_target = TwinCAT.Ads.AdsStream(8);
binRead_target = TwinCAT.Ads.AdsBinaryReader(dataStream_target);
dataStream_target.Position = 0;
tcClient.Read(ads_target_handle,dataStream_target);
my_double = binRead_target.ReadDouble;
disp([test_modelparam ' is ' num2str(my_double)]);


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
    data_bytes = typecast(double(1.0), 'uint8');
    tcClient.WriteAny(ads_target_handle,data_bytes);
    disp('Successfully wrote parameter');
catch e
    disp('problem with sending block')
    warning(e.message);
end

%% test push button connection

% % push button implementation
% tcClient.WriteAny(ads_target_handle,typecast(double(1), 'uint8'));
% pause(10);
% data_bytes = typecast(double(0), 'uint8');
% tcClient.WriteAny(ads_target_handle,typecast(double(0), 'uint8'));