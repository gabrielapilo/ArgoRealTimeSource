% S_FROM_DIRECT_TS05  Given T casts, return matching S casts from 2005 version
%                 direct TS climatology.
% INPUTS
%   lo
%   la
%   doy  day-of-year of each cast (ie 1-366), OR doy=[] to disable seasonal calc
%   t    observed temperature casts [ndep,ncast]
%   fnm  [optional] full-path name of ts climatology file (leave off '.nc') 
% OUTPUTS
%   s    [ndep,NC2]  NC2 is number of casts within region of climatology 
%   outofreg    index to out-of-region casts
%
% Author: Jeff Dunn 4 Nov 2005
%
% USAGE: [s,outofreg] =  s_from_direct_ts05(lo,la,doy,t,fnm);


% WARNING:  This algorithm looks tacky and unnecessary. It is also about 150x
%  faster than the obvious interp3 approach, so stick with it!


function [ss,outofreg] =  s_from_direct_ts05(lo,la,doy,tt,fnm)


lo = lo(:)';
la = la(:)';
if ~isempty(doy)
   doy = doy(:)';
   ann = 1;
else
   ann = 0;
end
 
if size(tt,2)~=length(lo)
   if size(tt,1)==length(lo)
      tt = tt';
   else
      error('S_FROM_DIRECT_TS: wrong dimensions for "t"')
   end
end
ndep = size(tt,1);
  
if nargin<5 | isempty(fnm)
   fnm = platform_path('fips','eez_data/ts_clim/ts_clim');
end

if ~exist([fnm '.nc'],'file')
   error(['S_FROM_DIRECT_TS05: Cannot find file ' fnm]);
end


X = getnc(fnm,'lon');
Y = getnc(fnm,'lat');
outofreg = find(lo<X(1) | lo>=X(end) | la<Y(1) | la>=Y(end));
if ~isempty(outofreg)
   disp([7 num2str(length(outofreg)) ' points outside region covered by t/s'])
   lo(outofreg) = [];
   la(outofreg) = [];
   tt(:,outofreg) = [];
   if ~isempty(doy)
      doy(outofreg) = [];
   end
end
ncast = length(lo);
ss = repmat(nan,size(tt));
if ncast==0
   return
end

% Begin to convert cast locations to indices into t-s climatology...
ix = interp1(X,1:length(X),lo);
iy = interp1(Y,1:length(Y),la);
ix0 = floor(min(ix));
ixe = floor(max(ix))+1;
iy0 = floor(min(iy));
iye = floor(max(iy))+1;
ix = 1+ix-ix0;
iy = 1+iy-iy0;
X = X(ix0:ixe);
Y = Y(iy0:iye);

ny = length(Y);

% Indices of neighbouring grid points (index = (nrows*(col-1)) + col)
i1 = round((ny*(floor(ix)-1))+floor(iy));
i2 = i1+1;
i3 = round((ny*floor(ix))+floor(iy));
i4 = i3+1;

% Calc horizontal and "vertical" interpolation weights
xr = ix-floor(ix);
yr = iy-floor(iy);
w = [(1-xr).*(1-yr); (1-xr).*yr; xr.*(1-yr); xr.*yr];

tlvs = getnc(fnm,'T_level');

tmp = find(tlvs<nanmin(tt(:)));
if isempty(tmp)
   itl(1) = 1;
else
   itl(1) = tmp(end);
end
tmp = find(tlvs>nanmax(tt(:)));
if isempty(tmp)
   itl(2) = length(tlvs);
else
   itl(2) = tmp(1);
end
tlvs = tlvs(itl(1):itl(2));

timc = exp(doy*(-i*2*pi/366));

MN = shiftdim(getnc(fnm,'mean',[itl(1) iy0 ix0],[itl(2) iye ixe]),1);  
if ann
   anc = shiftdim(getnc(fnm,'an_cos',[itl(1) iy0 ix0],[itl(2) iye ixe]),1);  
   AN = anc + ...
	i.*shiftdim(getnc(fnm,'an_sin',[itl(1) iy0 ix0],[itl(2) iye ixe]),1);
   clear anc
end

rr = find(isnan(MN));
MN(rr) = 0;
mn0 = squeeze(MN(:,:,1));
if ann
   AN(rr) = 0;
   an0 = squeeze(AN(:,:,1));
end   

for jj = 1:(length(tlvs)-1)
   mn = squeeze(MN(:,:,jj+1));   
   if ann
      an = squeeze(AN(:,:,jj+1));
   end
   ll = find(tt>=tlvs(jj) & tt<tlvs(jj+1));
   wz = (tt(ll)-tlvs(jj))./(tlvs(jj+1)-tlvs(jj));
   
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
   
      % Require t/s values above and below each t, and that the data is not just 
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

      if ann
	 indx = [i1(cic); i2(cic); i3(cic); i4(cic)];
	 dd0 = an0(indx).*aa0;
	 tmp = (sum(dd0.*w(:,cic))./sumw0);
	 s1 = s1 + real(tmp.*timc(cic));
	 an0 = an;
      end

      aa = aa(:,ic);
      dd = dd(:,ic).*aa;
      sumw = sumw(ic);
      s2 = sum(dd.*w(:,cic))./sumw;

      if ann
	 dd = an(indx).*aa;
	 tmp = (sum(dd.*w(:,cic))./sumw);
	 s2 = s2 + real(tmp.*timc(cic));
      end

%      if size(s1,2)~=size(ic,2)
	 ss(ll(ic)) = s1'.*(1-wz(ic)) + s2'.*wz(ic);
%      else
%	 ss(ll(ic)) = s1.*(1-wz(ic)) + s2.*wz(ic);
%      end
   end
   
   mn0 = mn;
   if ann
      an0 = an;
   end
end
      
%--------------------------------------------------------------------------------
