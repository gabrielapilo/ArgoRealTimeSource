% ATDAYPOS  Given lats,lons and times, return values according to grid and 
%           temporal functions.
% INPUT:  
%   lats, lons, doy:  vectors of required positions and day-of-year
%   xgrid,ygrid, mn:  [ny,nx] long, lat and mean map
%   an,sa          :  [ny,nx] optional annual and semi-annual harmonics
%
% Assumes: Uniformly spaced grid, with element 1,1 being in the SW corner. 
%
% JRD 23/4/96
% USAGE: vals = atdaypos(lats,lons,doy,xgrid,ygrid,mn,an,sa)

function [vals]=atdaypos(lats,lons,doy,xgrid,ygrid,mn,an,sa)

t1 = 0;
if nargin > 6 
  t1 = length(find(isnan(an)));
end
t2 = 0;
if nargin > 7
  t2 = length(find(isnan(sa)));
end

if min(size(xgrid))==1 & min(size(mn)) > 1
   [xgrid,ygrid] = meshgrid(xgrid,ygrid);
end
   
% If there are no NaNs in the harmonics we can get away with the much simpler
% and more accurate method below:
    
if t1==0 & t2==0

  vals = interp2(xgrid,ygrid,mn,lons,lats,'*bilinear');

  if nargin > 6
    ann = interp2(xgrid,ygrid,an,lons,lats,'*bilinear');
    vals = vals + real(ann.*exp(-i*doy*2*pi/366));
  end
  if nargin > 7
    saa = interp2(xgrid,ygrid,sa,lons,lats,'*bilinear');
    vals = vals + real(saa.*exp(-i*doy*4*pi/366));
  end

else
   if max(size(doy))==1 & max(size(lats))>1
      doy = repmat(doy,size(lats));
   end
   
  ii = find(isnan(an));
  an(ii) = zeros(size(ii));
  if t2 ~= 0
    ii = find(isnan(sa));
    sa(ii) = zeros(size(ii));
  end
  
  [mg,ng] = size(xgrid);
  vals = NaN*ones(length(lats),1);

  vbase = interp2(xgrid,ygrid,mn,lons,lats,'*bilinear');

  gsp = abs(xgrid(1,1)-xgrid(1,2));
  orgn = [xgrid(1,1)-gsp/2 ygrid(1,1)-gsp/2];

  if nargin==6
    vals = vbase;
  elseif nargin==7
    for ii = 1:length(lats)
      elr = 1+floor((lons(ii)-orgn(1))/gsp);
      elc = 1+floor((lats(ii)-orgn(2))/gsp);
      if( elr>=1 & elr<=ng & elc>=1 & elc<=mg)
	vals(ii) = vbase(ii) + real(an(elc,elr)*exp(-i*doy(ii)*2*pi/366));
      end
    end
  elseif nargin==8
    for ii = 1:length(lats)
      elr = 1+floor((lons(ii)-orgn(1))/gsp);
      elc = 1+floor((lats(ii)-orgn(2))/gsp);
      if( elr>=1 & elr<=ng & elc>=1 & elc<=mg)
	vals(ii) = vbase(ii) ...
	    + real(an(elc,elr)*exp(-i*2*pi/366*doy(ii))) ...
	    + real(sa(elc,elr)*exp(-i*4*pi/366*doy(ii)));
      end
    end
  end
  
end

% -------------- End of atdaypos ----------------------

