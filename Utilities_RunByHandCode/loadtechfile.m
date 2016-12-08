% loadtechfile
% this script loads the tech file variables so they can be checked for
% anomalies
%
% note that you needto ahve alreadyloaded the atabase information dbdat

set_argo_sys_params
global ARGO_SYS_PARAM
if ispc
fnm = [ARGO_SYS_PARAM.root_dir 'netcdf\' num2str(dbdat.wmo_id) '\' num2str(dbdat.wmo_id) '_tech.nc'];
else
fnm = [ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) '/' num2str(dbdat.wmo_id) '_tech.nc'];
end
techn=getnc(fnm,'TECHNICAL_PARAMETER_NAME');
techv=getnc(fnm,'TECHNICAL_PARAMETER_VALUE');


cn=getnc(fnm,'CYCLE_NUMBER');
