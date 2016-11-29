% GET_BATH15  Get Tas Uni bathymetry (-ve downwards) in region 109-156E 45-1S 
%
% INPUTS:  x,y    Locations at which depth is required
%          rpt:  [Optional]  1 => save data to make subsequent calls faster. 
%                (rpt=0 on last call will clear the data)
%          opt:  0= return NaN outside region covered by AusBath15
%                1= return NGDC "       "        "    "     "    [default]
%                2= return ETOPO5  "    "        "    "     "
%
% USAGE: [deps] = get_bath15(x,y,rpt,opt)

function [deps] = get_bath15(x,y,rpt,opt)

ncquiet;
   
if nargin<3
   rpt = 0;
elseif isempty(rpt)
   rpt = 0;
end
if nargin<4
   opt = 1;
elseif isempty(opt)
   opt = 1;
end


deps = repmat(nan,size(x));

ii = find(x<109 | x>156 | y<-45 | y>-1);
if ~isempty(ii)
  if opt==1
    deps(ii) = topongdc(y(ii),x(ii));
  elseif opt==2
    deps(ii) = topo(y(ii),x(ii));
  end
end


ii = find(x>=109 & x<=156 & y>=-45 & y<=-1);

if ~isempty(ii)
  global AusBath15
  fnm = platform_path('fips','eez_data/bath/ausbath15');
  if ~exist([fnm '.mat'],'file');
     fnm = platform_path('cascade','dunn/bath/ausbath15');
  end
  load(fnm)

  x = 1+((x(ii)-109)*15);
  y = 1+((-1-y(ii))*15);
  deps(ii) = interp2(AusBath15,x,y,'*linear');
end

if rpt~=1
  clear global AusBath15
end


% ------------------ end of get_bath15 -------------------
