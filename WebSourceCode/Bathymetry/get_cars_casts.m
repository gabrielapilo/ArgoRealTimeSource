% GET_CARS_CASTS: Return extracts from CARS, at a set of locations and
%      depths, and optionally day-of-years.   Can also return just the 
%      CARS seasonal anomaly (see 'doy' below).
%
%  ** Differs from GET_CLIM_CASTS only in being restricted to CSL levels, 
%     rather than allowing arbitrary depths. This reduces memory 
%     requirements enormously (but can actually be a lot slower?!)
%
% INPUT
%  prop    property ('t','s','o','si','n', OR 'p')
%  lon,lat   vectors of NN locations
%  deps    vector of depths (in m) - must match CSL levels but need not be
%          contiguous levels.
%    OPTIONAL:
%  doy     vector of NN day-of-year corresponding to locations. Note
%          that a seasonal cycle are not provided below a certain depth 
%          (1000m for CARS2000).
%          NOTE: use -doy if want just seasonal component; ie mean=0.
%  fname   eg 'cars2005a' 
%  dummy   unused argument
%  fll     1=values at all depths outside of land areas (with selected 
%          files only) [default 0]
%
% OUTPUT
%  vv      psuedo-casts extracted from CARS, dimensioned [DD,NN]
%  out     index to casts outside region of specified maps
%
% AUTHOR: Jeff Dunn  CSIRO CMAR  June 06
%
% Devolved from get_clim_casts.m,v 1.6 2001/06/07 00:00:59 dun216
%
% CALLS:  clname  inpolygon  coord2grd  getchunk
% RELATED:  'get_clim' - is slower but can get data from multiple climatologies
%           in one go (eg use low res only where no high res), and also can
%           return variables other than the mean or seasonal property fields.
%           'get_clim'casts'
%
% USAGE: [vv,out] = get_cars_casts(prop,lon,lat,deps,doy,fname,dum,fll);

function [vv,out] = get_cars_casts(prop,lon,lat,deps,doy,fname,dum,fll);

ncquiet;

if nargin<5; doy = []; end
if nargin<6; fname = []; end
if nargin<8 | isempty(fll); fll = 0; end

lon = lon(:)';
lat = lat(:)';
nout = length(lat);

tcor = -i*2*pi/366;
cpath = [];

[tmp,ncf] = clname(prop,cpath,fname);
gor = ncf{'gr_origin'}(:);
gsp = ncf{'grid_space'}(:);
rot = ncf{'rotation'}(:);
cnrs = ncf{'corners'}(:);
clo = ncf{'lon'}(:);
cla = ncf{'lat'}(:);
cdep = ncf{'depth'}(:);
close(ncf);

[ldep,levs] = intersect(cdep,deps);
ndep = length(levs);
if ndep<length(deps)
   disp('GET_CARS_CASTS expects all depths to match levels in CARS')
end

if isempty(rot) | rot==0
   if min(size(cla)>1)
      cla = cla(:,1)';
      clo = clo(1,:);
   end
   ic = find(lon>=min(clo) & lon<=max(clo) & lat>=min(cla) & lat<=max(cla));
else
  ic = inpolygon(lon,lat,cnrs(2,:),cnrs(1,:));
  ic = find(ic>0);
end
ic = ic(:)';  

if length(ic)<length(lat(:))
  out = 1:length(lat(:));
  out(ic) = [];
  lon = lon(ic);
  lat = lat(ic);
else
  out = [];
end

nomean = 0;
if ~isempty(doy)
   if length(doy)==1 & length(ic)>1
   %   doy = repmat(doy,size(ic));
   else
      doy = doy(ic);
      doy = doy(:)';
   end
   if sum(doy<0) > sum(doy>=0)
      nomean = 1;
      doy = -doy;
   end
end

if nomean 
   vv = zeros(ndep,nout);
else
   vv = repmat(nan,ndep,nout);
end

if ~isempty(lon)    
   % Auto-set an efficient range, but guard against degenerate ones which 
   % would not provide enough grid points for interpolation.

  ix1 = max(find(clo<min(lon))); 
  ix2 = min(find(clo>max(lon)));
  if isempty(ix1) | isempty(ix2) | ix1==ix2
     ix = max([1 ix1-1]):min([ix2+1 length(clo)]);
  else
     ix = ix1:ix2;
  end
  iy1 = max(find(cla<min(lat))); 
  iy2 = min(find(cla>max(lat)));
  if isempty(iy1) | isempty(iy2) | iy1==iy2
     iy = max([1 iy1-1]):min([iy2+1 length(cla)]);
  else
     iy = iy1:iy2;
  end

  rgn = [clo(ix(1)) clo(ix(end)) cla(iy(1)) cla(iy(end))];

  [X,Y] = coord2grd(lon,lat,rgn(1),rgn(3),gsp(2),gsp(1),rot);

  %[clo,cla] = meshgrid(clo(ix),cla(iy));

  if ~isempty(doy)
     doy = -i*2*pi/366*doy;
     edoy = exp(doy);
     e2doy = exp(2*doy);
  else
     an = []; sa = [];
  end
  
  for idp = 1:ndep
     ll = deps(idp);
     if isempty(doy)
	mn = getmap(prop,ll,[],fname,fll,[],rgn);
     else
	[mn,an,sa] = getmap(prop,ll,[],fname,fll,[],rgn);
     end
     if nomean
	vv(idp,ic) = 0;
     else
	%vv(idp,ic) = interp2(clo,cla,mn,lon,lat,'*linear');
	vv(idp,ic) = interp2(mn,X,Y,'*linear');
     end
     if ~isempty(an)
	%tmp = interp2(clo,cla,an,lon,lat,'*linear');
	tmp = interp2(an,X,Y,'*linear');
	vv(idp,ic) = vv(idp,ic) + real(tmp.*edoy);
     end
     if ~isempty(sa)
	%tmp = interp2(clo,cla,sa,lon,lat,'*linear');
	tmp = interp2(sa,X,Y,'*linear');
	vv(idp,ic) = vv(idp,ic) + real(tmp.*e2doy);
     end	
  end
end


%------------- End of get_clim_casts -------------------------
%  [clo,cla] = meshgrid(clo(ix),cla(iy));
%  
%  if ~nomean
%     for idp = 1:ndep
%	ll = levs(idp);
%	tmp = scaleget(ncf,'mean',ll,iy,ix);
%	vv(idp,ic) = interp2(clo,cla,squeeze(tmp),lon,lat,'*linear');
%     end
%  end
%
%  if ~isempty(doy)
%     doy = -i*2*pi/366*doy;
%     edoy = exp(doy);
%     e2doy = exp(2*doy);
%     
%     vnames = ncnames(var(ncf));
%    d1max = length(ncf('depth_ann'));
%     if d1max==0
%	% Old 2nd depth coord
%	d1max = length(ncf('depth_timefit'));
%	if d1max > 0
%	   if strmatch('sa_cos',vnames,'exact')
%	      d2max = d1max;
%	   else
%	      d2max = 0;
%	   end
%	end
%     else
%	d2max = length(ncf('depth_semiann'));
%     end
%     
%     for idp = 1:ndep
%	ll = levs(idp);
%	if ll<=d1max
%	   tmp2 = scaleget(ncf,'an_sin',ll,iy,ix);
%	   tmp = scaleget(ncf,'an_cos',ll,iy,ix) + i*tmp2;
%	   if any(isnan(tmp))
%	      kk = find(isnan(tmp));
%	      tmp(kk) = 0;
%	   end
%	   tmp2 = interp2(clo,cla,squeeze(tmp),lon,lat,'*linear');
%	   vv(idp,ic) = vv(idp,ic) + real(tmp2.*edoy);
%	end
%
%	if ll<=d2max
%	   tmp2 = scaleget(ncf,'sa_sin',ll,iy,ix);
%	   tmp = scaleget(ncf,'sa_cos',ll,iy,ix) + i*tmp2;
%	   if any(isnan(tmp))
%	      kk = find(isnan(tmp));
%	      tmp(kk) = 0;
%	   end
%	   tmp2 = interp2(clo,cla,squeeze(tmp),lon,lat,'*linear');
%	   vv(idp,ic) = vv(idp,ic) + real(tmp2.*e2doy);
%	end
%     end
