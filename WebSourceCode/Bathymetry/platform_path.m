% PLATFORM_PATH
% Construct paths appropriately for the type of machine being used.
%
% INPUT: mach  - home of the disc, so can construct PC-style path
%        upth  - unix style path, without the '/home/' 
%
% OUTPUT  pth  - complete path
%        slsh  - slash symbol, if want to construct extra paths
%        plat  - 1=PC, 0=Unix, -1=MAC
%
% EG:  pth = platform_path('reg','reg2/SST_mw/netcdf/');
%
% USAGE: [pth,slsh,plat] = platform_path(mach,upth);

function [pth,slsh,plat] = platform_path(mach,upth)

cname = computer;
if strncmp(cname,'PC',2)
   plat = 1;
   pth = ['\\' mach '-hf\'];
   ii = findstr(upth,'/');
   slsh = '\';
   upth(ii) = slsh;
   pth = [pth upth];
elseif strncmp(cname,'MAC',3)
   plat = -1;
   disp([7 'Sorry - do not how to find datafiles from a Mac'])
   pth = '';
   slsh = '?';
else
   % Assuming not a VAX, must be Unix
   plat = 0;
   pth = ['/home/' upth];
   slsh = '/';
end


return

%-----------------------------------------------------------------------------
