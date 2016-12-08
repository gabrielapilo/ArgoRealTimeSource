%  function runprofiles_automated(wmo_id,pn)
%
% When given a wmo id and list of profiles, this program derives the file
% names using find_argos_downloads, then runs strip over the entire list.
%
% usage:
%     runprofiles_automated(wmo_id,pn)
%
%   where:  wmo_id is the identifier of the float and 
%           pn is the list of profile numbers to be re-run

function runprofiles_automated(wmo_id)
global ARGO_SYS_PARAM
global   ARGO_ID_CROSSREF THE_ARGO_FLOAT_DB
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
if isempty(ARGO_ID_CROSSREF)
    getdbase(0);
end
warning off all


opts.redo=1;
% first, get the file names:

[fpp,dbdat]=getargo(wmo_id);
load ([ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) '.old.mat']);

for i=1:length(float)
        file=find_argos_download(wmo_id,i);

% now re-run the specified profiles:

% [m,n]=size(file);

% for i=1:m
%     try
if ~isempty(file)
        strip_argos_msg_noweb(file,wmo_id,opts)
end
end


