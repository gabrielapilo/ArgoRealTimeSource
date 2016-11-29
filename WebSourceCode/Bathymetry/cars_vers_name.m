% Get the "cars_version" global attribute from a netCDF file
%
% INPUT  
%    fnm   full path name [if non-CARS netCDF file]
%    cnm   CARS name part [if CARS netCDF file]
%    pth   path [if CARS file and non-standard path]
%
% eg  cver = cars_vers_name('myfile.nc');
% eg  cver = cars_vers_name([],'cars2005a');
%
% NOTE: cver=[] if global attribute 'cars_version' is missing from the file
%
% USAGE: cver = cars_vers_name(fnm,cnm,pth);

function cver = cars_vers_name(fnm,cnm,pth)

if nargin<3
   pth = [];
end

if isempty(fnm)
   % Assume there will always be a T version of CARS files
   fnm = clname('t',pth,cnm);
   fnm = [fnm '.nc'];
else
   nn = length(fnm);
   if ~strcmp(fnm((nn-2):nn),'.nc')
      fnm = [fnm '.nc'];
   end
end

[attval,attname] = attnc(fnm);

ii = strmatch('cars_version',attname,'exact');
if isempty(ii)
   cver = [];
else
   cver = attval{ii};
end

%---------------------------------------------------------------------------
