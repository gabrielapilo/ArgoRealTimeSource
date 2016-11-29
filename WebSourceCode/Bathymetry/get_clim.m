% GET_CLIM: Return extracts from CARS, at a set of locations and depths, and
%      optionally day-of-years
%      SUPERCEDES 'getsection' and can be used instead of 'get_clim_casts'
%      or 'getchunk' (both routines are FASTER but less general).
%      Note that 'get_clim_casts' cannot return other CARS variables.
%
% INPUT
%  prop    property ('t','s','o','si','n', OR 'p')
%  lon,lat  vector or array of NN locations
%  deps    vector of DD depths (in m). Need not be contiguous.
%  OPTIONAL:
%  doy     matrix day-of-year corresponding to locations
%  var     1 = return CARS property (mean or seasonal depending on 'fns' and
%          whether or not 'doy' is non-empty.)   If not = 1, then return
%          other climatology variables, (see GETMAP 'vars')
%  fnms    name or cell array of names of climatology files to
%          access (in the order specified). 
%      OR  'best' to get CARS2000 best possible resolution
%      OR  'best07' to get CARS2006 best possible resolution
%          Default:  'cars2000' [will REMAIN for backwards compatibility!]
%  woa     1=use WOA98 (Levitus) outside of CARS EEZ region
%  fll     1=values at all depths outside of land areas (only with selected 
%          files) [def 0]
%  fpth    to get map files from a non-standard disc location
%  fns     0=mean only, 1=+annual, 2=+semi-ann [default: semi-ann if available]
%
% OUTPUT
%  vv      psuedo-casts extracted from CARS, dimensioned [size(lon) DD]
%
% NOTE:  if fll~=1 then the interpolation used here will still provide some
%     crude inshore values from adjacent data points. These may result in 
%     temperature inversions etc which are not actually present in CARS. If
%     this is a problem, use fll=1 or use GET_CLIM_CASTS.
%
% AUTHOR: Jeff Dunn  CSIRO DMR  May 1998
% $Id: get_clim.m,v 1.1 2001/06/20 04:08:17 dun216 Exp dun216 $
% MODS:  see below
% CALLS:  intp3jd (getmap (clname))  csl_dep
%
% USAGE: vv = get_clim(prop,lon,lat,deps,doy,var,fnms,woa,fll,fpth,fns);

function vv = get_clim(prop,lon,lat,deps,doy,var,fnms,woa,fll,fpth,fns);

% MODS:
%  1/5/2001  Fixed range so that use WOA outside [30 200 -70 10] instead of
%            [100 200 -70 0]. Also, bug in WOA stuff if 2D x&y, and olny 1 depth.
%  20/6/01   Mod interp3_clim to extract the minimum required amount of CARS, to
%            decrease time and memory requirements.

ncquiet;

if nargin<5; doy = []; end
if length(doy)==1 & prod(size(lon))>1
   doy = repmat(doy,size(lon));
end
if nargin<6 | isempty(var)
   var = 1;
end
cars05 = 1;
if nargin<7 | isempty(fnms)
   cars05 = 0;
   fnms = {'cars2000'};
   global GET_CLIM_def_warn
   if isempty(GET_CLIM_def_warn)
      GET_CLIM_def_warn = 1;
      disp('GET_CLIM - CARS2000 by default. THIS WILL NOT BE CHANGED.')
      disp('[  This warning once per session only  ]')
   end
elseif strcmp(fnms,'best07')   
   if strcmp(prop,'t') || strcmp(prop,'s')
      fnms = {'coast8_06','cars2006a'};
   else
      fnms = {'coast8_06','cars2006'};
   end
elseif strcmp(fnms,'best')
   fnms = {'coast8','cars2000'};
   cars05 = 0;
elseif strcmp(fnms,'cars2000')
   cars05 = 0;
end
   
if ~iscell(fnms)
   fnms = {fnms};
end

if nargin<4 | isempty(deps)
   [tmp,nc] = clname(prop,fpth,fnms{1});
   deps = nc{'depth'}(:); 
   close(nc);
end

if nargin<8 | isempty(woa); woa = 0; end
if nargin<9 | isempty(fll); fll = 0; end
if nargin<10; fpth = []; end
if nargin<11 | isempty(fns); fns = 2; end


vv = interp3_clim(fpth,fnms{1},fll,prop,var,deps,lon,lat,doy,[],fns);
for ii = 2:length(fnms)
   if any(isnan(vv(:)))
      vin = vv;
      vv = interp3_clim(fpth,fnms{ii},fll,prop,var,deps,lon,lat,doy,vin,fns);
   end
end


if woa & any(isnan(vv(:))) & ~cars05
   % Only look for WOA values outside the CARS 2000 region   
   kk = find(lat>10 | lon>200 | lon<30);
   if ~isempty(kk)
      wdep = dep_csl(deps,1);
      iw = find(wdep==round(wdep));
      if length(iw)~=length(deps)
	 nwdep = deps;
	 nwdep(iw) = [];
	 disp('The following depths are not available in WOA98 (is it mapped on');
	 disp(['a smaller set on depth levels: ' num2str(nwdep)]);
      end
      if ~isempty(iw)
	 disp([num2str(length(kk)) ' profiles used WOA98']);
	 if isempty(doy)	    
	    tmp = get_woa_profiles(prop,lon(kk),lat(kk),wdep(iw));
	 else
	    tmp = get_woa_profiles(prop,lon(kk),lat(kk),wdep(iw),doy(kk));
	 end
	 if dims(lon)==1
	    vv(kk,iw) = tmp';
	 else
	    for jj = 1:length(iw)
	       tmp2 = vv(:,:,iw(jj));
	       tmp2(kk) = tmp(jj,:);
	       vv(:,:,iw(jj)) = tmp2;
	    end
	 end
      end
   end
elseif woa & any(isnan(vv(:))) & cars05
   disp('GET_CLIM: You have set WOA=1 and CARS has not been able to')
   disp('provide all requested data. However, we are not providing')
   disp('fallback to WOA when using CARS2005. Sorry.');
end

%------------- End of get_clim -------------------------
