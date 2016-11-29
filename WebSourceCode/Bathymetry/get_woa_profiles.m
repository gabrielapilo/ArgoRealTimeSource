% GET_WOA_PROFILES:  Extract WOA94 profiles at given place and day-of-year
%     (Similar function to lev_mapdat, but is faster.)
%     
% Note: Does NOT do temporal interpolation - just takes nearest month value.
%
% INPUT: prop:  't' 's' 'o' 'os' 'si' 'a' 'p' OR 'n'
%    lons,lats:  vectors of locations
%    deps:       Vector (montonic but not nec. contiguous) of depth levels
%    doy:        OPTIONAL: vector of day-of-year. If absent, get annual mean.
%
% OUTPUT: out:  [ndep,nlocs] psuedo-casts from WOA94
%
% $Id: get_woa_profiles.m,v 1.1 1998/06/11 03:17:03 dunn Exp dunn $   
% Jeff Dunn CSIRO DMR May 1998
%
% USAGE: out = get_woa_profiles(prop,lons,lats,deps,doy);

function out = get_woa_profiles(prop,lons,lats,deps,doy)

% About the algorithms:  
% Only have monthly maps to level 19, so if these are required we must access
% them and then add on any deeper layers from the annual-mean maps.
% Also, we extract WOA in a 3D block of contiguous depths. Since we allow a
% non-contiguous set of depths to be specified, we must then index from the
% 3D block into our output matrix. We do this via the Z coordinate of the
% 3D interpolation.

lons = lons(:)'; lats = lats(:)'; deps = deps(:)';

out = repmat(nan,length(deps),length(lons));

maxtd = 19;

prop = lower(prop);
if length(prop)==1; prop = [prop ' ']; end
mnly = 0;
if strncmp(prop,'t',1)
  var='TEMP';
  mnly = 1;
elseif strncmp(prop,'si',2)
  var='SIO3';
elseif strncmp(prop,'s',1)
  var='SALT';
  mnly = 1;
elseif strncmp(prop,'os',2)
  var='OSAT';
elseif strncmp(prop,'o',1)
  var='O2';
elseif strncmp(prop,'a',1)
  var='AOU';
elseif strncmp(prop,'p',1)
  var='PO4';
elseif strncmp(prop,'n',1)
  var='NO3';
else
  disp('The properties available are: t, s, si, os, o, a, p, n');
  disp('that is: temp, salt, SIO3, Osat, O2, AOU, PO4, NO3.');
  error(' Try again.');
end

monthly = 0;
if nargin>4 & deps(1)<=maxtd
  if ~mnly
    warning('Monthly maps are available to level 19 only for T and S');
  else
    monthly = 1;
  end
end

d0 = 0;     % Marks start level in output. Is shifted to the bottom of any 
            % levels extracted from monthly maps, so that deep annual-mean
	    % data will be put in the right place.

if monthly

  if strncmp(prop,'t',1)
    filename = '/home/netcdf-data/levitus_monthly_temp_98';
  elseif strncmp(prop,'s',1)
    filename = '/home/netcdf-data/levitus_monthly_salinity_98';
  end
  lon = getnc(filename,'lon');
  lat = getnc(filename,'lat');
    
  ndep = length(find(deps<=maxtd));
  dzidx = deps(1:ndep)+1-deps(1);

  mon = ceil(doy/30.5);
  ii = find(mon<1); if ~isempty(ii); mon(ii) = ones(size(ii)); end
  ii = find(mon>12); if ~isempty(ii); mon(ii) = repmat(12,size(ii)); end

  for month=1:12
    kk = find(mon==month);
    if ~isempty(kk)
      [loidx,laidx,longr,latgr] = gridx(lon,lat,lons(kk),lats(kk));
      corner = [month deps(1) laidx(1) loidx(1)];
      end_point = [month deps(ndep) laidx(2) loidx(2)];
      dat = getnc(filename,var,corner,end_point,-1,-2,2,0);
      LO = 1+lons(kk)-longr(1);
      LA = 1+lats(kk)-latgr(1);
      out(1,kk) = interp2(dat(:,:,1),LA,LO,'*linear');
      if ndims(dat)>2
	LO = repmat(LO,ndep-1,1);
	LA = repmat(LA,ndep-1,1);
	Z = repmat(dzidx(2:ndep)'-.001,1,length(kk));
	out(2:ndep,kk) = interp3(dat,LA,LO,Z,'*linear');
      end
    end
  end

  d0 = ndep;
  deps = deps(find(deps>maxtd));
end


if ~isempty(deps)
  
  filename = '/home/netcdf-data/levitus_annual_98';
  lon = getnc(filename,'lon');
  lat = getnc(filename,'lat');

  ndep = length(deps);
  dzidx = deps(1:ndep)+1-deps(1);

  [loidx,laidx,longr,latgr] = gridx(lon,lat,lons,lats);
  corner    = [deps(1) laidx(1) loidx(1)];
  end_point = [deps(ndep) laidx(2) loidx(2)];
  dat = getnc(filename,var,corner,end_point,-1,-2,2,0);
  
  LO = 1+lons-longr(1);
  LA = 1+lats-latgr(1);
  out(d0+1,:) = interp2(dat(:,:,1),LA,LO,'*linear');
  if ndims(dat)>2
    LO = repmat(LO,ndep-1,1);
    LA = repmat(LA,ndep-1,1);
    Z = repmat(dzidx(2:ndep)'-.001,1,length(lats));
    out((d0+2):(d0+ndep),:) = interp3(dat,LA,LO,Z,'*linear');
  end

end

% ------------
% GRIDX: Find indices into WOA97 files which span the given locations
%
% To simplify matters, assume that we will not require data near 0E
%
function [loidx,laidx,longr,latgr] = gridx(lon,lat,lons,lats)

loidx = find(lon>=(min(lons)-1) & lon<=(max(lons)+1));
loidx = [min(loidx) max(loidx)];
laidx = find(lat>=(min(lats)-1) & lat<=(max(lats)+1));
laidx = [min(laidx) max(laidx)];

longr = lon(loidx);
latgr = lat(laidx);


% ------------ End of get_woa_profiles.m --------------------
