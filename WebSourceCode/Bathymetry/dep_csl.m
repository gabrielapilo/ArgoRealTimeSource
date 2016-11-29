% DEP_CSL - convert depth in metres to any of three sets of Standard Depth Levels
%
% INPUT  dep:  vector depth in metres (+ve below sea level)
%        vers: 1=NODC (WOD) levels   2=CARS2000 levels   3=CARS2005 levels
%              [Default: 2]
% OUTPUT stdep:  CSIRO Standard Levels corresponding to depths
%
% NOTES:
%  -  fractional levels are returned, so user can choose to use ceil or
%     floor of those values as required.
%  -  heights above sea level (-ve dep) are returned as 0.
%
% Jeff Dunn 16 Feb 99, 13/4/04, 16/6/04
%
% USAGE: stdep = dep_csl(dep,vers);

function [stdep] = dep_csl(dep,vers)

if nargin<2 | isempty(vers) | vers==0
   global CSL_Version
   if ~isempty(CSL_Version)
      vers = CSL_Version;
   else
      vers = 2;
   end
end

if vers==1
   sdp = [0; 10; 20; 30; 50; 75; 100; ...
	  125; 150; 200; 250; 300; 400; 500; ...
        600; 700; 800; 900; 1000; 1100; ...
        1200; 1300; 1400; 1500; 1750; 2000; 2500;  ...
        3000; 3500; 4000; 4500; 5000; 5500; ...
        6000; 6500; 7000; 7500; 8000; 8500; 9000];
elseif vers==2
   sdp = [ 0; 10; 20; 30; 40; 50; 60; 70; 75; 80; 90; 100; 110; ...
        125; 150; 175; 200; 225; 250; 275; 300; 350; 400; 450; 500; ...
        550; 600; 650; 700; 750; 800; 850; 900; 950; 1000; 1100; ...
        1200; 1300; 1400; 1500; 1600; 1750; 2000; 2250; 2500; 2750; ...
        3000; 3250; 3500; 3750; 4000; 4250; 4500; 4750; 5000; 5500; ...
        6000; 6500; 7000; 7500; 8000; 8500; 9000];
else
   % New levels are comprised of the levels we want, then 6 extra levels
   % added for backwards compatibility.
   sdp = [0 5 10:10:300  325:25:500  550:50:1000  1100:100:2000 ...
            2250:250:5000  5500:500:9000   75 125 175 225 275 1750]';
   sdp = sort(sdp);
end

indx = 1:prod(size(dep));

stdep = zeros(size(indx));

for ii=length(sdp)-1:-1:1
  jj = find(dep >= sdp(ii));
  if ~isempty(jj)
    stdep(indx(jj)) = ii + (dep(jj)-sdp(ii))/(sdp(ii+1)-sdp(ii));
    indx(jj) = [];
    dep(jj) = [];
  end
end
