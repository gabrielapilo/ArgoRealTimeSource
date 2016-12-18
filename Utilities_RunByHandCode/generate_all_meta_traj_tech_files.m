%used to regenerate technical, trajectory or metadata files:
%comment out what you don't need to produce...

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

kk = 5903260;
getdbase(0);
for ii = kk%1:length(THE_ARGO_FLOAT_DB)
    [fpp,dbdat] = getargo(ii);
%     [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if ~isempty(fpp)
%         trajectory_nc(dbdat,fpp);
%         techinfo_nc(dbdat,fpp);
        metadata_nc(dbdat,fpp);
    end
end
