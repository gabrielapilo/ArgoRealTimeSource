% CSL_DEP Given a vector of rational Standard Levels indices, return depths (m)
%
% INPUTS: levels  - levels (possibly non-integer) [arbitrary shape]
%         version - 1=NODC (WOD) levels   2=CARS2000 levels    3=CARS2005 levels
%                  [Default: 2]
%
% OUTPUTS:  deps - corresponding depths (metres) (same size as "levels" input)
%
% USAGE: deps = csl_dep(levels,version);

function deps = csl_dep(levels,vers);

% Mods: 13/4/04 Add vers so can specify vers 1 or 3 instead.
%       18/6/04 Revise v3 levels for backwards compatibility

if nargin<2 | isempty(vers) | vers==0
   global CSL_Version
   if ~isempty(CSL_Version)
      vers = CSL_Version;
   else
      vers = 2;
   end
end

if vers==1
   sdeps = [0; 10; 20; 30; 50; 75; 100; ...
	    125; 150; 200; 250; 300; 400; 500; ...
        600; 700; 800; 900; 1000; 1100; ...
        1200; 1300; 1400; 1500; 1750; 2000; 2500;  ...
        3000; 3500; 4000; 4500; 5000; 5500; ...
        6000; 6500; 7000; 7500; 8000; 8500; 9000];
elseif vers==2
   sdeps = [ 0; 10; 20; 30; 40; 50; 60; 70; 75; 80; 90; 100; 110; ...
        125; 150; 175; 200; 225; 250; 275; 300; 350; 400; 450; 500; ...
        550; 600; 650; 700; 750; 800; 850; 900; 950; 1000; 1100; ...
        1200; 1300; 1400; 1500; 1600; 1750; 2000; 2250; 2500; 2750; ...
        3000; 3250; 3500; 3750; 4000; 4250; 4500; 4750; 5000; 5500; ...
        6000; 6500; 7000; 7500; 8000; 8500; 9000];
else
   % New levels are comprised of the levels we want, then 6 extra levels
   % added for backwards compatibility. 
   sdeps = [0 5 10:10:300  325:25:500  550:50:1000  1100:100:2000 ...
	    2250:250:5000  5500:500:9000   75 125 175 225 275 1750]';
   sdeps = sort(sdeps);
end

lcsl = length(sdeps);

deps = NaN*ones(size(levels));

ii = find(levels<1);
if ~isempty(ii)
   ii = find(levels<0);
   deps(ii) = levels(ii)*10;    % Hypothetical 10m levels above s.l., with
                              % 0=0m, -1=10m asl, but 1-0 undefined (=NaN)
  jj = find(levels>=1);
  if ~isempty(jj)
    deps(jj) = interp1(1:lcsl,sdeps,levels(jj));
  end
else
  ii = find(~isnan(levels));
  deps(ii) = interp1(1:lcsl,sdeps,levels(ii));
end
