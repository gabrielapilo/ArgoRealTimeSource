% getCSIROxbt: get Thermal Archive XBT data
%
% INPUT:
%  range   either [w e s n]     OR     [x1 y1; x2 y2; x3 y3; ... xn yn]
%  hvar    vector of one or more cast header info codes:
%          1)CPN   2)time   3)castflag   4)bot_depth   5)country   6)cruise   
%          7)pos_stat   8)OCL   9) Filetype
%  var     vector of property codes: only var=1 is available. 
%  deps    Vector of indices of CSL depth levels to extract 
%          [use round(dep_csl(depths)) to convert from +ve metres to indices]
%
% OUTPUTS:
%  lat,lon  position of casts
%  vars     1 cell for each hvar and var specified (vars being [ncast ndep])
%
%   NOTE: casts with no good values in the depth range are removed.
%         depths below deepest available data are removed.
%  Jeff Dunn 15/4/2002   CSIRO
%
% USAGE: [lat,lon,vout] = getCSIROxbt(range,hvar,var,deps);

function [lat,lon,vout] = getCSIROxbt(range,hvar,var,deps)

fnm = platform_path('fips','eez_data/csiro_therm_archive/csiro_xbt');
ncst = 70949;

nvars = length(var);
nhv = length(hvar);
vout{nhv+nvars} = [];

if nargin<4 | isempty(deps)
   deps = 1:35;
else
   deps = deps(find(deps<=35));
end
ndp = length(deps);

idxv = find(var<=13);
notv = find(var>13);


load(fnm);

if length(lat)~=ncst
   error('Thermal Archive file has changed, so dynamic CPNs will have too.');
end


if size(range) == [1 4]
   isin = find(lon>=range(1) & lon<=range(2) & lat>=range(3) & lat<=range(4));
else
   isin = find(feval('isinpoly',lon,lat,range(:,1),range(:,2)));
end

% Get rid of any cast with no good data
if ndp~=35
   allbad = find(all(isnan(tz(isin,deps)')));
   if ~isempty(allbad)
      isin(allbad) = [];
   end
end

lon = lon(isin);
lat = lat(isin);

for hh = 1:nhv
   switch hvar(hh)
     case 1
       vout{hh} = 81000000 + indx(isin);
     case 2
       vout{hh} = time(isin);
     case 3
       vout{hh} = zeros(size(isin));
     case 4
       vout{hh} = bdep(isin);
     case 9
       vout{hh} = repmat(8,size(isin));
     otherwise
       vout{hh} = repmat(nan,size(isin));
   end
end

% Cut off casts at deepest good data
tz = tz(isin,deps);
lastgood = max(find(any(~isnan(tz))));
if lastgood<ndp
   tz(:,(lastgood+1):ndp) = [];
   ndp = size(tz,2);
end

for hh = 1:nvars
   switch var(hh)
     case 1
       vout{nhv+hh} = tz;
     otherwise
       vout{nhv+hh} = repmat(nan,size(tz));
   end
end

% -----------------------------------------------------------------------
