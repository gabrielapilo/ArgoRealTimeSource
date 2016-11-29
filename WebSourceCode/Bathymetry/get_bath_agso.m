% GET_BATH_AGSO:  Return AGSO 2002 .01 degree (or AGSO 98 30sec) bathymetry
%             (and coords) in given range.
%
%  WARNING:  Bathy file is big enough to kill matlab, so specifed range
%            should be kept small!
%
% INPUT:
%  range   either [w e s n]     OR     [x1 y1; x2 y2; x3 y3; ... xn yn]
%  vers    [Optional] 1=AGSO_98  2=AGSO_2002   [default=2]
% OUTPUT:
%  dd      depth in m, +ve downwards (ie +ve depths)
%  x,y     locations - if range is [w e s n], then x,y are NOT plaid.
%
% REPLACES  agso_bath.m
%
% Jeff Dunn CSIRO   CMR 15/4/02   7/1/03
%
% SEE ALSO   get_bath.m
%
% USAGE: [dd,x,y] = get_bath_agso(range[,vers]);

function [dd,x,y] = get_bath_agso(range,vers)

dd = []; x = []; y = [];

if nargin<2 | isempty(vers)
   vers = 2;
end
switch vers
  case 1
    fnm = platform_path('reg','netcdf-data/bath_agso_98');
  case 2
    fnm = platform_path('reg','netcdf-data/bath_agso_2002');
  otherwise
    disp('Do not understand that "vers". Defaulting to AGSO 2002')
    fnm = platform_path('reg','netcdf-data/bath_agso_2002');
end

lo = getnc(fnm,'lon');
la = getnc(fnm,'lat');

if size(range) == [1 4]
   ix = find(lo>=range(1) & lo<=range(2));
   iy = find(la>=range(3) & la<=range(4));
   if isempty(iy) | isempty(ix)
      disp(['GET_BATH_AGSO: no data in range ' num2str(range)]); 
   else
      dd = -getnc(fnm,'height',[iy(1) ix(1)],[iy(end) ix(end)]);
      x = lo(ix);
      y = la(iy);
   end
elseif size(range,2)==2 & size(range,1)>=3
   ix = find(lo>=min(range(:,1)) & lo<=max(range(:,1)));
   iy = find(la>=min(range(:,2)) & la<=max(range(:,2)));   
   [lo,la] = meshgrid(lo(ix),la(iy));
   ii = find(isinpoly(lo,la,range(:,1),range(:,2)));
   if isempty(ii)
      disp('GET_BATH_AGSO: no data in specified range');
   else
      dd = -getnc(fnm,'height',[iy(1) ix(1)],[iy(end) ix(end)]);
      dd = dd(ii);
      x = lo(ii);
      y = la(ii);
   end
end

return

%---------------------------------------------------------------------------
