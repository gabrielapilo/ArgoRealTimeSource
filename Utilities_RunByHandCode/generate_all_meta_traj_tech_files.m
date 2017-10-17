%used to regenerate technical, trajectory or metadata files:
%comment out what you don't need to produce...

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
kk = [5905199];
% kk = [1901329
%     1901338
%     1901339
%     5903629
%     5903630
%     5903649
%     5903660
%     5903678
%     5903679
%     5903955
%     5904218
%     5904882
%     1901347
%     1901348
%     5904923
%     5904924
%     5905022

%     5905165
%     5905167];
getdbase(0);
for ii = 1:length(kk)%1:length(THE_ARGO_FLOAT_DB)
    [fpp,dbdat] = getargo(kk(ii));
%     [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if ~isempty(fpp)
%         trajectory_nc(dbdat,fpp);
%         techinfo_nc(dbdat,fpp);
        metadata_nc(dbdat,fpp);
    end
end
