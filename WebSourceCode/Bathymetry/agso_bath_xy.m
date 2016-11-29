% AGSO_BATH_XY:  Return AGSO 30sec bathymetry interp to given locations.
%
%  WARNING:  Bathy file is big enough to kill matlab, so total region
%            spanned by locations should be kept small!
% INPUT:
%  x,y     locations
% OUTPUT:
%  dd      depth in m, +ve downwards (ie +ve depths)
%
% Jeff Dunn CSIRO   CMR 15/4/02
%
% USAGE: dd = agso_bath_xy(x,y);

function dd = agso_bath_xy(x,y)

dd = [];

fnm = platform_path('reg','netcdf-data/bath_agso_98');
lo = getnc(fnm,'lon');
la = getnc(fnm,'lat');

ix = find(lo>=min(x(:)) & lo<=max(x(:)));
iy = find(la>=min(y(:)) & la<=max(y(:)));

if isempty(iy) | isempty(ix)
   disp('AGSO_BATH: no data at given locations');
else
   dg = -getnc(fnm,'height',[iy(1) ix(1)],[iy(end) ix(end)]);
   [lo,la] = meshgrid(lo(ix),la(iy));
   dd = interp2(lo,la,dg,x,y);   
end

return

%---------------------------------------------------------------------------
