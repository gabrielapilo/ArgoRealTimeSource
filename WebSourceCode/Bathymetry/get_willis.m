% GET_WILLIS  The Willis QC-ed T dataset is split into regional files so
%   you do not have to load the whole thing if you just want a small region.
%   This function just concatonates data from the required regional files.
%
% INPUT  src - can be empty (all data), or [w e s n], or polygon definition,
%              or one of subset regions 1 to 5  [default: all]
%        deps - depth levels (in metres) to extract  [default: all depths]
% OUTPUT *** arguments have changed, with addition of cpn (11/4/05) ***
%
% USAGE: [lo,la,tim,tz,botdep,ptyp,pindx,styp,sindx,cpn] = get_willis(src,deps)

function [lo,la,tim,tz,botdep,ptyp,pindx,styp,sindx,cpn] = get_willis(src,deps)

if nargin==0
   src = [];
end

wdep = 0:10:750;
if nargin<2 | isempty(deps)
   ideps = 1:length(wdep);
else
   ideps = find(ismember(wdep,deps));
   if length(ideps)<length(deps)
      error('Willis has only depths 0:10:750')   
   end
end

lo = []; la = []; tim = []; tz = []; botdep = []; cpn = [];
ptyp = []; pindx = []; styp = []; sindx = [];

pth = platform_path('fips','eez_data/willis/');
fnm = {'north_2004','sth_atl_2004','west_2004','central_2004','east_2004'};	

jset = [];
if isempty(src)
   jset = 1:5;
elseif max(size(src))==1
   if ~ismember(src,1:5)
      error(['GET_WILLIS: src unknown: ' num2str(src)])
   else
      jset = src;
   end
elseif min(size(src))==1
   if src(4)>30; jset = 1; end
   if src(3)<30
      if src(1)<20 | src(2)>290; jset = [jset 2]; end
      if src(1)<140 & src(2)>20; jset = [jset 3]; end
      if src(1)<210 & src(2)>140; jset = [jset 4]; end
      if src(1)<290 & src(2)>210; jset = [jset 5]; end
   end
else
   if any(src(:,2)>30); jset = 1; end
   if any(src(:,2)<30)
      % This is highly imperfect, but it is tricky!
      if any(src(:,1)<20 | src(:,1)>290); jset = [jset 2]; end
      if any(src(:,1)<140 & src(:,1)>20); jset = [jset 3]; end
      if any(src(:,1)<210 & src(:,1)>140); jset = [jset 4]; end
      if any(src(:,1)<290 & src(:,1)>210); jset = [jset 5]; end
   end
end

for ii = jset
   load([pth fnm{ii}]);
   lo = [lo; lon];
   la = [la; lat];
   tim = [tim; time];
   tz = [tz; t(:,ideps)];
   botdep = [botdep; bdep];
   ptyp = ptypes;
   pindx = [pindx; ptindx];
   styp = source;
   sindx = [sindx; src_indx];
   cpn = [cpn; stnno];
end

if isempty(src) | max(size(src))==1
   % return everything
else
   if min(size(src))==1
      ii = find(lo>=src(1) & lo<=src(2) & la>=src(3) & la<=src(4));
   else
      ii = find(inpolygon(lo,la,src(:,1),src(:,2))); 
   end
   lo = lo(ii);
   la = la(ii);
   tim = tim(ii);
   tz = tz(ii,:);
   botdep = botdep(ii);
   pindx = pindx(ii);
   sindx = sindx(ii);
   cpn = cpn(ii);   
end

%--------------------------------------------------------------------------
