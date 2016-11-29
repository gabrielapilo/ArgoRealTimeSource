% getCSIROcsl:  Get CSIRO CTD&Hydro CSL standard level data (from csiro_csl.nc) 
%        Does not remove casts lacking data in requested range and properties.
%
% ***   WARNING  -  Some of this data may be subject to embargo  ***
%
% INPUTS 
%  lim     [w e s n] define geographic extent (eg: [100 130 -40 -10])
%         OR  [x1 y1;x2 y2;x3 y3; ... ] vertices of polygon of required data
%  hvar   vector of one or more cast header info codes:
%         1)CPN   2)time   3)castflag  4)bot_depth  9) Filetype
%  vars    vector of variable codes:  1)t  2)s  3)o2  4)si  5)po4  6)no3   
%          7)gamma   14)no4   15)nh3
%  deps    Vector of indices of CSL levels to extract (eg [1 10 11 40 56])
%          [use round(dep_csl(depths)) if need to convert from +ve depths in m]
%  scrn    0: do NOT reject cast if cast_flag set     [default=1]
%  fname   [Optional - if want to define the CTD-only file, say]
%
% OUTPUTS 
%  la      Latitude of extracted casts
%  lo      Longitude "    "       "
%  vout    [ncast] header vars and [ncast X ndeps] property vars in cells in
%          order as requested
%
% NOTE  Time = days since 1900
%       cpn  = Profile ID comprised of: vCCCCsss v=vessel CCCC=cruise sss=station
%
% USAGE: [la,lo,vout] = getCSIROcsl(lim,hvar,vars,deps,scrn,fname);

function [la,lo,vout] = getCSIROcsl(lim,hvar,vars,deps,scrn,fname)

%  Jeff Dunn  March 2000
% $Id: getCSIROcsl.m,v 1.2 2006/10/05 00:04:33 dun216 Exp dun216 $
   
if nargin<6 | isempty(fname)
   fname = platform_path('fips','eez_data/hydro/csiro_csl');
end
if nargin<5 | isempty(scrn)
   scrn = 1;
end

deps = deps(find(deps<=56));
d1 = min(deps);
d2 = max(deps);

nhv = length(hvar);
ihv = find(hvar<=4);
noth = find(hvar>4);

nv = length(vars);
iv = find((vars>0 & vars<=7) | vars==14 | vars==15);
notv = 1:nv;
notv(iv) = [];

vout{nhv+nv} = [];

la = getnc(fname,'lat');
lo = getnc(fname,'lon');
if scrn
   csflg = getnc(fname,'cast_flag');
else
   csflg = zeros(size(la));
end

hnam = {'profilid','time','cast_flag','botdepth'};
pnam = {'t','s','o2','si','po4','no3','neut_density','','','','','','','no4','nh3'};


for ii = ihv
   vout{ii} = getnc(fname,hnam{hvar(ii)});
end

for ii = iv
   vout{nhv+ii} = getnc(fname,pnam{vars(ii)},[-1 d1],[1 d2]);
   % If required depths are not contiguous, extract just the required depths
   if length(d1:d2) > length(deps)
      vout{nhv+ii} = vout{nhv+ii}(:,deps+1-d1);
   end
end

% If required get supplementary nitrate data.

if any(vars==6)
   fno3 = platform_path('fips','eez_data/hydro/csiro_no3');
   tmp = getnc(fno3,'lat');
   la = [la(:); tmp(:)];
   nnew = length(tmp);
   tmp = getnc(fno3,'lon');
   lo = [lo(:); tmp(:)];
   tmp = getnc(fno3,'cast_flag');
   csflg = [csflg; tmp(:)];
   for ii = ihv
      tmp = getnc(fno3,hnam{hvar(ii)});
      vout{ii} = [vout{ii}(:); tmp(:)];
   end
   tmp = getnc(fno3,'no3',[-1 d1],[1 d2]);
   if size(tmp,1)~=nnew
      tmp = tmp';
   end
   if length(d1:d2) > length(deps)
      tmp = tmp(:,deps+1-d1);
   end
   jj = find(vars==6);
   vout{nhv+jj} = [vout{nhv+jj}; tmp];
end


% Remove flagged casts (if screening) and those outside requested region.

if min(size(lim))==1
   rej = find(lo<lim(1) | lo>lim(2) | la<lim(3) | la>lim(4) | isnan(lo) ...
	      | isnan(la) | csflg>0);
else
   rej = find(~isinpoly(lo,la,lim(:,1),lim(:,2)) | isnan(lo) | isnan(la) | csflg>0);
end

if ~isempty(rej)
  la(rej) = [];
  lo(rej) = [];
  for ii = ihv
    vout{ii}(rej) = [];
  end
  for ii = iv
    vout{nhv+ii}(rej,:) = [];
  end
end


% Pad out requested vars which are not available in this dataset.
% (hvar==9 is "FileType", which is 7 for CSIRO data).

ncast = length(la);
if ncast>0
   ndep = length(deps);
   for ii = noth
      if hvar(ii)==9
	 vout{ii} = repmat(7,[ncast 1]);
      else
	 vout{ii} = repmat(nan,[ncast 1]);
      end
   end
   for ii = notv
      vout{nhv+ii} = repmat(nan,[ncast ndep]);
   end
end
      
%----------------- End of getCSIROcsl.m -------------------------------

