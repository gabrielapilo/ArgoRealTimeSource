% DEP_STD -    REDUNDANT - use  csl_dep.m  instead.
%
% - convert from depth in metres to Standard Depths
%
% INPUT  dep:  vector depth in metres (+ve below sea level)
%
% OUTPUT stdep:  standard depth level [1-40] corresponding to depths
%
% NOTES:
%  -  fractional levels are returned, so user can choose to use ceil or
%     floor of those values as required.
%  -  heights above sea level (-ve dep) are returned as 0.
%
% Jeff Dunn 6 Nov 96

function [stdep] = dep_std(dep)

global Warn_Once_Dep_Std

if isempty(Warn_Once_Dep_Std)
   disp('WARNING: "dep_csl" should now be used instead of "dep_std"');
   Warn_Once_Dep_Std = 1;
end

sdp = [0;10;20;30;50;75;100;125;150;200;250;300;400;500;600;700;...
    800;900;1000;1100;1200;1300;1400;1500;1750;2000;2500;3000;3500;...
    4000;4500;5000;5500;6000;6500;7000;7500;8000;8500;9000;9500];

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
  

