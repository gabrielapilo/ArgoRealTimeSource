% GETARGO  Get a float array, or just one profile, from mat-files
%
% INPUT:  wmo  - WMO ID 
%         pn   - Argo profile_number. If a number>last pn in file, returns
%                last profile.  [default - return whole float].
%
% OUTPUT  fp    - a float structure array, or a single profile structure
%         dbdat - [optional] the database record, if 2 return args
%
% JRD Nov 06
%
% CALLED BY:  for interactive use, but could be called by other functions
%
% USAGE: [fp,dbdat] = getargo(wmo,pn);

function [fp,dbdat] = getargo(wmo,pn)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if nargout==2
   dbdat = getdbase(wmo);
end

fp = [];
if ispc
fnm = [ARGO_SYS_PARAM.root_dir 'matfiles\float' num2str(wmo)];
else
fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo)];    
end

if ~exist([fnm '.mat'],'file')
   disp([fnm ' does not exist!'])
   return
end

load(fnm,'float');

if isempty(float)
   disp([fnm ' is empty!'])
   return
end

nn = length(float);
pnums = [float.profile_number];

if nargin<2 || isempty(pn)
   fp = float(1:nn);
elseif pn>max(pnums)
   fp = float(nn);
   disp(['Returning pn ' num2str(fp.profile_number) ' as requested ' ...
	 num2str(pn) ' not found in file']);
elseif any(pnums==pn)
   ii = find(pnums==pn);
   fp = float(ii);
else
   disp(['Profile_number ' num2str(pn) ' not found in file']);
end


%-------------------------------------------------------------------
