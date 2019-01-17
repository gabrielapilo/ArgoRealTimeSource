%used to regenerate technical, trajectory or metadata files:
%comment out what you don't need to produce...

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
kk = [    5904922
    5904925
    5905389
    5905390
    5905393
    5905394
    5905410
    5905411
    5905412
    5905413
    5905419
    5905420
    5905421
    ];
getdbase(0);
for ii = 1:length(kk)%1:length(THE_ARGO_FLOAT_DB)%%
    [fpp,dbdat] = getargo(kk(ii));
%     [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if ~isempty(fpp)
%         trajectory_nc(dbdat,fpp);
%         techinfo_nc(dbdat,fpp);
%         metadata_nc(dbdat,fpp);
    plot_tech(fpp,dbdat)
% make_tech_webpage(dbdat.wmo_id);
    end
end
