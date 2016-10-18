function [xcs,allX,allY] = xcontour(z,v,arg3,arg4,arg5,arg6,arg7);

% Xcontour - DEFUNCT  use contour in matlab4.x
error('Xcontour - DEFUNCT  use contour in matlab4.x')

%
%--------------------------------------------------------------------------
% XCONTOUR  1.5   94/04/18
%
% FUNCTION [xcs,allX,allY] = xcontour(z,v,badflag)
%                                   -OR-
%                            xcontour(z,v,x,y,badflag)
%                                   -OR-
%                            xcontour(z,v,x,y,badflag,ndash)
%                                   -OR-
%                            xcontour(z,v,x,y,badflag,ndash,limits)
%
% Enhanced version of CONTOUR to handle arrays with missing data. See also
% the help entry for CONTOUR.
% 
% Input:  z       - matrix of values to be contoured.
%         v       - vector of contour levels.
%         badflag - value for missing data (e.g. Nan, -9999).
%         x       - vector specifying X-axes to be used on plot.
%         y       - vector specifying Y-axes to be used on plot.
%                   (N.B. As in CONTOUR, z(1,1) is in top left corner,
%                    but y(1) is coordinate of bottom of Y-axis)!
%         ndash   - if non-zero, draw negative contours dashed.
%         limits  - specifies axis limits (1x4 array as used by AXIS).
%
% Output: All optional. xcs is the two row matrix of contour lines with
%         only valid pieces of contours listed (as used by CLABEL).
%         allX/allY are the x,y points for the valid pieces, arranged in
%         the columns of allX/Y, and padded with Nan's.
%
%--------------------------------------------------------------------------

% @(#)xcontour.m   1.5   94/04/18
% AUTHORS:  Peter McIntosh and Phil Morgan
%--------------------------------------------------------------------------

[m,n] = size(z);

if nargin < 3
  error('Insufficient input arguments!');
elseif nargin == 3
  x=[1:n];
  y=[1:m];
  badflag=arg3;
  ndash=0;
elseif nargin == 5
  x=arg3;
  y=arg4;
  badflag=arg5;
  ndash=0;
elseif nargin == 6
  x=arg3;
  y=arg4;
  badflag=arg5;
  ndash=arg6;
elseif nargin == 7
  x=arg3;
  y=arg4;
  badflag=arg5;
  ndash=arg6;
  limits=arg7;
else
  error('Wrong number of input arguments!');
end

if length(x)~=n
  error('xcontour: x has wrong dimensions!');
end
if length(y)~=m
  error('xcontour: rowscale has wrong dimensions!');
end

%...If badflag is NaN or Inf, convert to finite number so we can use contour...

if isnan(badflag)
  newbadflag  = -99999;
  bad         = find(isnan(z));
  z(bad)      = newbadflag*ones(bad);
%elseif ~finite(badflag)
elseif ~isfinite(badflag)
  newbadflag  = -99999;
  %bad         = find(~finite(z));
  bad         = find(~isfinite(z));
  z(bad)      = newbadflag*ones(bad);
else
  newbadflag  = badflag;
end

plot('off');
cs0=contour(z,v,x,y);

%...Contours on unit grid for testing good values on line segments...

cs1=contour(z,v);

termtype=getenv('TERM');
if strcmp(termtype,'vt100')
  vt240tek;
else
  plot('x');
end

%...Find indices of contour data & level/number info...

count=1;
index=[];
info=[];
lcs0=length(cs0);
while count<=lcs0;
  info=[info count];
  num=cs0(2,count);
  index=[index count+1:count+num];
  count=count+num+1;
end

%...Initialize value arrays (using 1 if newbadflag=0, otherwise 0)...

if newbadflag==0
  value1=ones(1,lcs0);
  value2=ones(1,lcs0);
else
  value1=zeros(1,lcs0);
  value2=zeros(1,lcs0);
end

%...Test if valid contour & set cs0 to NaN if bad data at that point...

ix = cs1(1,index);
iy = m+1-cs1(2,index);

value1(index) = z(floor(iy) + (floor(ix)-1)*m);
value2(index) = z(ceil (iy) + (ceil (ix)-1)*m);

replace = find(value1==newbadflag | value2==newbadflag);

lr = length(replace);
if lr > 0
  cs0(:,replace) = NaN*ones(2,lr);
end

%...Stack contiguous segments into columns of allX/Y...

array=cs0;
array(:,info)=nan*ones(2,length(info));
[p,q]  = size(array);
nancol = find(isnan(array(1,:)));

if length(nancol)<q
  nancol   = [0 nancol q+1];
  ngood    = diff(nancol)-1;
  maxpiece = max(ngood);
  npieces  = length(find(ngood>1));
  allX     = nan*ones(maxpiece,npieces);
  allY     = allX;
  pnum     = 0;

  for i = 1:length(nancol)-1
    ig1  = nancol(i)+1;
    ig2  = nancol(i+1)-1;
    inum = ig2-ig1+1;
    if inum > 1
      pnum              = pnum+1;
      allX(1:inum,pnum) = array(1,ig1:ig2)';
      allY(1:inum,pnum) = array(2,ig1:ig2)';
      ptot(pnum)        = inum;
      cinfo=max(find(info<ig1));
      cvalue(pnum)=cs0(1,info(cinfo));
    end
  end

else
  disp('No meaningful contours!');
  return;
end

if nargin < 7,
  axmin  = min(x);
  axmax  = max(x);
  aymin  = min(y);
  aymax  = max(y);
  limits = [axmin axmax aymin aymax];
end

axis(limits);

if ndash ==0,
  plot(allX,allY,'-w');
else
  indexge=find(cvalue>=0);
  indexlt=find(cvalue<0);
  if length(indexge)==0,
    plot(allX(:,indexlt),allY(:,indexlt),'--w');
  elseif length(indexlt)==0,
    plot(allX(:,indexge),allY(:,indexge),'-w');
  else
    plot(allX(:,indexlt),allY(:,indexlt),'--w',...
         allX(:,indexge),allY(:,indexge),'-w');
  end
end

axis;

%...If xcs array is requested, calculate it...

if nargout>0
  xcs     = [];
  [ma,na] = size(allX);
  for j = 1:na
    nn  = ptot(j);
    xcs = [xcs [cvalue(j); nn] [allX(1:nn,j)'; allY(1:nn,j)']];
  end
end
%-----------------------------------------------------------------------------
