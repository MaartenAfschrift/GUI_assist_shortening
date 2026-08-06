try
    disp('test')
    sfadsfa
catch ME
    warning('TwinCAT ADS unavailable, using MockAdsClient:','%s', ME.message);
end