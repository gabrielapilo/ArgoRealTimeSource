% Take salinity calibration off particular profiles and remake the netcdf
% files.
% inputs: wmo_id - or group of ids eg [5901963 5902653]
%         range of profile numbers eg [1:50]
function uncalibrate_sal(wmo_id,profrange)
global ARGO_SYS_PARAM
set_argo_sys_params


for i=1:length(wmo_id)
    [fpp,dbdat]=getargo(wmo_id(i));
    for j=profrange
        if fpp(j).c_ratio~=1
            [fpp,cal_rept]=calsal(fpp,j,0);
            argoprofile_nc(dbdat,fpp(j));
            web_profile_plot(fpp(j),dbdat)
        end
    end
    float=fpp;
    
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)]
    save(fnm,'float','-v6');
    web_float_summary(fpp,dbdat,1)
    webUpdatePages(dbdat.wmo_id)
end
