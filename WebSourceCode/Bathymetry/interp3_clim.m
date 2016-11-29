% INTERP3_CLIM  Extract climatology variables and interpolate to a set of
%      locations (and optionally evaluate at day-of-year's)
%
% INPUTS
%   fpth,fnam  Source file path and name part, as for GETMAP
%   fll    fill option [for selected files only], as for GETMAP
%   prop   unambiguous mapped property name string, as for GETMAP
%   var    single variable number, as for GETMAP. If supplying doy, use var==1.
%   dps    Depths (in m)
%   xi,yi  Locations at which values required
% Optional:
%   doy    Day-of-year to evaluate each interpolated point
%   vin    input result matrix - nans indicate which values need to be filled
%   fns    0,1,2 max level of seasonal harmonics to use
%
% OUTPUT
%   vout   Interpolated variable or evaluated fields
%
% Jeff Dunn  CSIRO Marine Research  Dec 2000
%     Called direct or by GET_CLIM
%
% USAGE: vout = interp3_clim(fpth,fnam,fll,prop,var,dps,xi,yi,doy,vin,fns);

function vout = interp3_clim(fpth,fnam,fll,prop,var,dps,xi,yi,doy,vin,fns)

% $Id: interp3_clim.m,v 1.1 2001/06/20 04:09:07 dun216 Exp dun216 $
% NOTE: Really just does 2D interps at each depth level.
%
% MODS:  
% - work from minimum sized chunks of maps to improve efficiency. 20/6/01


[tmp,nc] = clname(prop,fpth,fnam);
if isempty(nc)
   return
end

if isempty(dps)
   %dps = csl_dep(1:56,2);
   dps = nc{'depth'}(:);
end
x = nc{'lon'}(:);
y = nc{'lat'}(:);
close(nc);

if nargin<9
   doy = [];
end
if nargin<11
   fns = 2;
end


% Create output matrix of the right dimensions

[nyo nxo] = size(xi);
nzo = length(dps);
if nargin<10 | isempty(vin)
   vin = repmat(nan,[nyo nxo nzo]);
else   
   % An input matrix provided - check that it has dimenions corresponding to
   % or at least compatible with other inputs. We want vout to be 3D, even if
   % some dims degenerate, so that do not need to cope with different
   % dimension cases in later assignments.
   
   if dims(vin)<3
      if prod(size(vin)) ~= nyo*nxo*nzo
	 error('Size of xi & depths do not match dimensions of supplied vin');
      else
	 vin = reshape(vin,[nyo nxo nzo]);
      end      
   else
      [nyi nxi nzi] = size(vin);

      if nyi~=nyo | nxi~=nxo
	 if nyi==nxo & nxi==nyo
	    disp([7 'Rotating xi,yi to match vin dimensions']);
	    xi = xi';
	    yi = yi';
	    doy = doy';
	 else
	    error('Dimensions of xi & yi do not match supplied vin');
	 end
      end
      if nzi~=length(dps)
	 error('Number of depths does not match 3rd dimension of supplied vin');
      end
   end
end

vout = vin;

xi = xi(:)';
yi = yi(:)';
doy = doy(:)';

if var==1 & ~isempty(doy) & fns>0
   temporal = fns;
else
   temporal = 0;
end

% x0 = west edge of grid, nx = number of x
% Set up (fractional) indices to target points in climatology grid, then
% reduce climatology grid to minimum required to extract, and correct target
% indices to that reduced grid.

if min(size(x))==1
   [x,y] = meshgrid(x,y);
end 
x0 = x(1); y0 = y(1);
[ny,nx] = size(x);
inc = abs(y(2,1)-y(1,1));

ix = 1+(xi-x0)/inc;
iy = 1+(yi-y0)/inc;


jin = find(ix>=1 & ix<=nx & iy>=1 & iy<=ny);
if isempty(jin)
   return
end
ix = ix(jin);
iy = iy(jin);
if ~isempty(doy)
   doy = doy(jin);
end
mnx = floor(min(ix));
mxx = ceil(max(ix));
mny = floor(min(iy));
mxy = ceil(max(iy));
ix = 1+ix-mnx;
iy = 1+iy-mny;
nx = 1+mxx-mnx;
ny = 1+mxy-mny;

regn = [x(1,mnx) x(1,mxx) y(mny,1) y(mxy,1)];

% Indices to grid points surrounding target point: i1=SW i2=NW i3=SE i4=NE

i1 = round((ny*floor(ix-1))+floor(iy));
i2 = i1+1;
i3 = round((ny*floor(ix))+floor(iy));
i4 = i3+1;

% For points on nx or ny boundaries, fold indices back to prevent accessing
% non-existant nx+1 or ny+1 elements

j2 = find(ix==nx);
i3(j2) = i1(j2);
i4(j2) = i2(j2);

j2 = find(iy==ny);
i2(j2) = i1(j2);
i4(j2) = i3(j2);

% Calc interpolation weights. xr, yr are fractional distances from West and
% South grid lines. Weigths are 1 minus those, so if target point very near
% east grid point, then xr~1 and w~0 for west grid points.

xr = ix-floor(ix);
yr = iy-floor(iy);

w = [(1-xr).*(1-yr); (1-xr).*yr; xr.*(1-yr); xr.*yr];

timc = -i*2*pi/366;

% Do 2D interp for each depth level

for idp = 1:length(dps)
   % We may be below temporal harmonics depth, in which case an & sa will
   % just be empty
   if temporal==2
      [dd,an,sa] = getmap(prop,dps(idp),fpth,fnam,fll,[1 2 3],regn);
   elseif temporal==1
      [dd,an] = getmap(prop,dps(idp),fpth,fnam,fll,[1 2],regn);
   else
      dd = getmap(prop,dps(idp),fpth,fnam,fll,var,regn);
   end

   if ~isempty(dd)
      dd = dd([i1; i2; i3; i4]);
      aa = ~isnan(dd);
      sumw = sum(aa.*w);

      % Require that data is not only at points almost the full grid interval
      % away (ie that the good data interpolation weight is non-trivial)
   
      if ~isempty(vin)
	 tmp = squeeze(vin(:,:,idp));
	 if any(size(tmp(jin))~=size(sumw))
	    tmp = tmp';
	 end
	 % Only get values where we don't currently have them.
	 ic = find(isnan(tmp(jin)) & sumw>.05);
      else
	 tmp = repmat(nan,[nyo nxo]);
	 ic = find(sumw>.05);
      end
   else
      ic = [];  
   end
   
   if ~isempty(ic)
      dd = dd(:,ic);
      % Set nans to 0 as alternative to using nansum below
      bad = find(isnan(dd));
      dd(bad) = zeros(size(bad));

      tmp(jin(ic)) = sum(dd.*w(:,ic))./sumw(ic);

      if temporal>0 & ~isempty(an)
	 dd = an([i1(ic); i2(ic); i3(ic); i4(ic)]);
	 % Could possibly be missing harmonics where do have a mean value 
	 bad = find(isnan(dd));
	 dd(bad) = zeros(size(bad));
	 tmp2 = sum(dd.*w(:,ic))./sumw(ic);
	 tmp(jin(ic)) = tmp(jin(ic)) + real(tmp2.*exp(timc*doy(ic)));
	 if temporal==2 & ~isempty(sa)
	    dd = sa([i1(ic); i2(ic); i3(ic); i4(ic)]);
	    dd(bad) = zeros(size(bad));
	    tmp2 = sum(dd.*w(:,ic))./sumw(ic);
	    tmp(jin(ic)) = tmp(jin(ic)) + real(tmp2.*exp(2*timc*doy(ic)));
	 end
      end
   
      vout(:,:,idp) = tmp;
   end
end

vout = squeeze(vout);

%---------------------------------------------------------------------------
