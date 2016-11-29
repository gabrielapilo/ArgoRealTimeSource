% CLNAME: Get name of climatology file
% INPUT: 
%    property - property name (eg 'salinity' or just 's')
%    pth    - path to netCDF map file
%    fname   - input file name component, if non-CARS. Full name is built as
%              follows:    filename = [fullproperty '_' fname '.nc']
%            eg: property='s', fname='maps'  then filename='salinity_maps.nc'
%
% OUTPUT: 
%    clnam   Constructed climatology name (not including '.nc')
%    ncf     Optional: open the file; returns the netcdf toolbox object
%
% USAGE: [clnam,ncf] = clname(property,pth,fname)

function [clnam,ncf] = clname(property,pth,fname)

if length(property)==1
  property = [property ' '];
end

if strcmp(property(1),'t')
  property = 'temperature';
elseif strcmp(property(1),'o')
  property = 'oxygen';
elseif strcmp(property(1),'n')
  property = 'nitrate';
elseif strcmp(property(1),'p')
  property = 'phosphate';
elseif strcmp(property(1:2),'si')
  property = 'silicate';
elseif strcmp(property(1),'s')
  property = 'salinity';
end
  
if nargin<2 | isempty(pth)
  pth = platform_path('fips','eez_data/atlas/');
end

if nargin<3 | isempty(fname)
   global CLNAME_def_warn
   if isempty(CLNAME_def_warn)
      CLNAME_def_warn = 1;
      disp('CLNAME - CARS2000 by default. This may change in late 2006.')
      disp('[  This warning once per session only  ]')
   end
  fname='cars2000';
end

clnam = [pth property '_' fname];

if nargout==1
  if ~exist([clnam '.nc'],'file')
    disp([7 'Cannot find file ' clnam '.nc']);
  end
else
  ncf = netcdf([clnam '.nc'],'nowrite');
  if isempty(ncf)
    disp([7 'CLNAME: Cannot open file ' clnam]);
  end
end

% -------------------------------------------------------
