% TOPO: Matlab-callable fortran routines to access the ETOPO5 bathymetry.
%   (or, where Mex is not available, m-script to do the same)
%
% INPUT:
%     lats - vector of latitudes
%     lons - vector of longitudes
%     fnm  - optional - name of terrainbase file
%
% NOTE: Mex form is vastly more efficient if input is sorted by latitude
%
% OUTPUT: 
%     heights:  -ve is below sea level
%
% May 1996, May 1998   J Dunn CSIRO
% June 1998 Switch to "terrainbase" - the new ETOPO5
% Aug 2003  Allow fnm to be specified, so can use a PC pathname
%
% USAGE: deps = topo(lats,lons,fnm)

function deps = topo(lats,lons,fnm)

if nargin<3 | isempty(fnm)
   fnm = platform_path('fips','eez_data/bath/terrainbase');
end

ncquiet;

deps = repmat(nan,size(lats));

% Add .041667 to cause values to correspond to range -2.5' to +2.5'.
% Wrap around 4321, so that 355 58' comes back to element 1.

yrec = 2161 - floor((90.041667-lats(:)).*12);
xrec = floor((lons(:)+.041667).*12) + 1;
ii = find(xrec==4321);
if ~isempty(ii)
  xrec(ii) = ones(size(ii));
end

jj = find(yrec>=1 & yrec<=2161 & xrec>=1 & xrec<=4320);

if length(jj)~=sum(~isnan(lats(:)))
  warning('TOPO: Bad position indices! Have you mixed up lats and lons?');
end

if ~isempty(jj)
   load(fnm);
   for ii=jj(:)'
      deps(ii) = height(yrec(ii),xrec(ii));
   end      
end

% ----------------------- End ----------------------

