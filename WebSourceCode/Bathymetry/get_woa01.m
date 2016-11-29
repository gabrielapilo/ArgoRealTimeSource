% GET_WOA01  Extract a chunk from World Ocean Atlas 2001
%
% INPUT
%  par  1-6, for T S O2 Si PO4 or NO3
%  var  1=analysed  2=difference  3=number_of_obs  4=std dev  5= std error  
%       6=means  7=interp error  8=grid point  [default 1]
%    Definitions from the data report, section 2.2:
%    "As with previous works, we have vertically interpolated ocean profile
%    data from "observed" depth levels to standard depth levels. The
%    statistics computed at each depth level include: 
%    (3) number of observations of each variable in each one-degree square
%    (6) arithmetic mean ("unanalyzed mean") of each variables in each 1deg
%        square
%    (4) standard deviation about the arithmetic mean
%    (5) standard error of the mean 
%    The above one-degree fields are referred to as "unanalyzed fields".
%    The fields of unanalyzed 1deg square means at each standard depth level 
%    were objectively analyzed to fill in 1deg squares that do not contain 
%    any data, through a process of interpolation and smoothing as outlined
%    in the World Ocean Atlas 2001: Volume 1 (Stephens et al. 2002). 
%    (1) The resulting fields are referred to as "analyzed fields". 
%    (2) Differences fields" are defined as the
%       difference between the monthly or seasonal analyzed field of a
%       variable and the corresponding analyzed annual mean field of the
%       variable. An analyzed annual mean field is defined as the average of
%       the twelve monthly (where available) or four seasonal analyzed mean
%       fields. 
%    (8) The number of 1deg square grid point values used to
%       compute the analyzed value at each grid point was also computed and
%       presented in the form of one-degree fields. This field is referred to
%       as a "grid point" field. 
%    (7) The difference between each "unanalyzed" field and the corresponding 
%       "analyzed", wherever data exists in the "unanalyzed" field, is
%       referred to as the "interpolation error".
%  typ  1=annual 2=monthly 3=seasonal
%  deps  Depths to extract, in metres   
%  rgn  [w e s n] region to extract
%
% OUTPUT
%  vv   data, dimensioned [ntm ndeps ny nx], where ntm=0,12,4 for typ 1,2,3 
%       respectively.
%  x,y  dimension [1 nx] and [1 ny] respectively
%
%                                          Jeff Dunn  CMAR  14/4/05
%
% USAGE: [vv,x,y] = get_woa01(par,var,typ,deps,rgn);

function [vv,x,y] = get_woa01(par,var,typ,deps,rgn)

[pth,slsh] = platform_path('nosferatu','murnau/data/levitus/');

parn = {'t','s','o','i','p','n'};
varn = {'an','ma','dd','sd','se','mn','oa','gp'};
typn = {'00','0112','1316'};
typd = {'annual','monthly','seasonal'};
ntim = [1 12 4];

if isempty(var)
   var = 1;
end
if ~ismember(par,1:6) | ~ismember(var,1:8) | ~ismember(typ,1:3)
   error('Wrong input arguments')
end

vnm = [parn{par} typn{typ} varn{var} '1'];
flnm = [pth typd{typ} slsh vnm];

x = .5:359.5;
y = -89.5:89.5;

if nargin>=5 & ~isempty(rgn)
   ix1 = min(find(x>=rgn(1)));  
   ix2 = max(find(x<=rgn(2)));
   iy1 = min(find(y>=rgn(3)));  
   iy2 = max(find(y<=rgn(4)));
   x = x(ix1:ix2);
   y = y(iy1:iy2);
   nx = 1+ix2-ix1;
   ny = 1+iy2-iy1;
else
   % Set nx ny to -1 so that getnc just extracts all
   ix1 = -1; ix2 = 360;
   nx = 360;
   iy1 = -11; iy2 = 180;
   ny = 180;
end


%depth = csl_dep(1:33,1);

if typ==1
   depth = getnc(flnm,'Depth');   
else
   depth = getnc(flnm,'depth');
end
   
if any(~ismember(deps,depth))
   error('GET_WOA01:  not one of the WOA (CSLv1) depths available for this parameter')
else
   idp = find(ismember(depth,deps));
end

ndp = length(idp);

if ntim(typ)==1
   if ndp>1 & any(diff(idp)>1)
      vv = zeros(ndp,ny,nx);      
      for ii = 1:ndp
	 vv(ii,:,:) = sq(getnc(flnm,vnm,[1 idp(ii) iy1 ix1],[1 idp(ii) iy2 ix2]));
      end
   else
      vv = sq(getnc(flnm,vnm,[1 idp(1) iy1 ix1],[1 idp(end) iy2 ix2]));
   end   
else
   if ndp>1 & any(diff(idp)>1)
      vv = zeros(ntims,ndp,ny,nx);
      for ii = 1:ndp
	 vv(:,ii,:,:) = getnc(flnm,vnm,[-1 idp(ii) iy1 ix1],[1 idp(ii) iy2 ix2]);
      end
   else
      vv = getnc(flnm,vnm,[-1 idp(1) iy1 ix1],[1 idp(end) iy2 ix2]);
   end   
end

%-------------------------------------------------------------------------------
