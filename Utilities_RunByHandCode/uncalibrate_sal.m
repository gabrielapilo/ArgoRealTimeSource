global ARGO_SYS_PARAM
set_argo_sys_params

wmo_id=[5900845 5901145 5901630]

for i=1:length(wmo_id)
    [fpp,dbdat]=getargo(wmo_id(i));
    for j=1:length(fpp)
        if fpp(j).c_ratio~=1
            [fpp,cal_rept]=calsal(fpp,j);
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
