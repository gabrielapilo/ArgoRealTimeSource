% S_FROM_DIRECT_TS  Given T casts, return matching S casts from direct TS
%                 climatology.
% INPUTS
%   lo
%   la
%   doy  day-of-year of each cast (ie 1-366), OR doy=[] to disable seasonal calc
%   tx   observed temperature casts [ndep,ncast]
%   vers  2=CARS2000  3=CARS2005  [default 2 **at present**]
% OUTPUTS
%   ss   [ndep,NC2]  NC2 is number of casts within region of climatology 
%   outofreg    index to out-of-region casts
%
% Author: Jeff Dunn 26 Nov 2000
%  Complete revision, which is much faster and recovers data otherwise lost
%  because with interp3, one or more neighbouring nans make the result nan.
%
% $Id: s_from_direct_ts.m,v 1.5 2002/02/25 01:17:49 dun216 Exp dun216 $
%
% USAGE: [ss,outofreg] =  s_from_direct_ts(lo,la,doy,tx,vers);

function [ss,outofreg] =  s_from_direct_ts(lo,la,doy,tx,vers)

if nargin>4 & ~isempty(vers) & vers==3
   [ss,outofreg] =  s_from_direct_ts05(lo,la,doy,tx);
   return
end

lo = lo(:)';
la = la(:)';
if ~isempty(doy)
   doy = doy(:)';
end
ncast = length(lo);
if size(tx,2)~=ncast
   if size(tx,1)==ncast
      tx = tx';
   else
      error('S_FROM_DIRECT_TS: wrong dimensions for "tx"')
   end
end
   
% Temperature groups in t-s climatology. Filenames include tcn, which is t*100.
tinc = .5;
tcn = [-250:50:3100];
tc = tcn/100;

% Define dimensions of t-s climatology
x0 = 30;
y0 = -80;
inc = 1;
nx = length(30:220);
ny = length(-80:30);

outofreg = find(lo<30 | lo>=220 | la<-80 | la>=30);
if ~isempty(outofreg)
   disp([7 num2str(length(outofreg)) ' points outside region covered by t/s'])
   lo(outofreg) = [];
   la(outofreg) = [];
   tx(:,outofreg) = [];
   if ~isempty(doy)
      doy(outofreg) = [];
   end
end

ss = repmat(NaN,size(tx));
ndep = size(tx,1);

% Begin to convert cast locations to indices into t-s climatology...
ix = 1+(lo(:)'-x0)/inc;
iy = 1+(la(:)'-y0)/inc;

% Indices of neighbouring grid points (index = (nrows*(col-1)) + col)
i1 = round((ny*(floor(ix)-1))+floor(iy));
i2 = i1+1;
i3 = round((ny*floor(ix))+floor(iy));
i4 = i3+1;

% Calc horizontal and "vertical" interpolation weights
xr = ix-floor(ix);
yr = iy-floor(iy);

w = [(1-xr).*(1-yr); (1-xr).*yr; xr.*(1-yr); xr.*yr];
wz = mod(tx,tinc)./tinc; 
wz = [(1-wz(:)) wz(:)];


timc = -i*2*pi/366;

fnm = platform_path('fips','eez_data/ts_clim/ts_');
load([fnm num2str(tcn(1)) '_90'],'mn','an');  
mn0 = mn; 
an0 = an;
rr = find(isnan(mn0));
mn0(rr) = zeros(size(rr));
an0(rr) = zeros(size(rr));

for jj = 1:(length(tc)-1)
   load([fnm num2str(tcn(jj+1)) '_90'],'mn','an');
   rr = find(isnan(mn));
   mn(rr) = zeros(size(rr));
   an(rr) = zeros(size(rr));
   
   ll = find(tx>=tc(jj) & tx<tc(jj+1));
   cst = ceil(ll/ndep);
   cst = cst(:)';
   
   if isempty(ll)
      ic = [];
   else
      % We cannot have a salinity of zero, so can use zero as the non-data flag.
      % If we left it as nan we would have to use the slower nansum below.
      indx = [i1(cst); i2(cst); i3(cst); i4(cst)];
      dd0 = mn0(indx);
      aa0 = ~~dd0;
      sumw0 = sum(aa0.*w(:,cst));   
   
      dd = mn(indx);
      aa = ~~dd;
      sumw = sum(aa.*w(:,cst));   
   
      % Require t/s values above and below each tx, and that the data is not just 
      % at points almost the full grid interval away (ie that the good data 
      % interpolation weight is non-trivial)
      ic = find(sumw0>.05 & sumw>.05);
   end
   
   if ~isempty(ic)
      cic = cst(ic);
      
      aa0 = aa0(:,ic);
      dd0 = dd0(:,ic).*aa0;
      sumw0 = sumw0(ic);
      s1 = sum(dd0.*w(:,cic))./sumw0;

      if ~isempty(doy)
	 indx = [i1(cic); i2(cic); i3(cic); i4(cic)];
	 dd0 = an0(indx).*aa0;
	 tmp = (sum(dd0.*w(:,cic))./sumw0);
	 s1 = s1 + real(tmp.*exp(timc*doy(cic)));
      end

      aa = aa(:,ic);
      dd = dd(:,ic).*aa;
      sumw = sumw(ic);
      s2 = sum(dd.*w(:,cic))./sumw;

      if ~isempty(doy)
	 dd = an(indx).*aa;
	 tmp = (sum(dd.*w(:,cic))./sumw);
	 s2 = s2 + real(tmp.*exp(timc*doy(cic)));
      end
      
      ss(ll(ic)) = s1'.*wz(ll(ic),1) + s2'.*wz(ll(ic),2);
   end
   
   mn0 = mn;
   an0 = an;
end
      
%--------------------------------------------------------------------------------
