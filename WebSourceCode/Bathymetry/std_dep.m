% STD_DEP -    REDUNDANT - use  csl_dep.m  instead.
%
% Given a vector of real standard depth levels, return depths (m)

function [deps] = std_dep(levels);

global Warn_Once_Std_Dep

if isempty(Warn_Once_Std_Dep)
   disp('WARNING: "csl_dep" should now be used instead of "std_dep"');
   Warn_Once_Std_Dep = 1;
end

std_deps = [0;10;20;30;50;75;100;125;150;200;250;300;400;500;600;700;...
    800;900;1000;1100;1200;1300;1400;1500;1750;2000;2500;3000;3500;...
    4000;4500;5000;5500;6000;6500;7000;7500;8000;8500;9000];

deps = NaN*ones(size(levels));

ii = find(levels<1);
if ~isempty(ii)
  deps(ii) = 1-levels(ii)*10;       % Hypothetical 10m levels above s.l.
  
  jj = find(levels>=1);
  if ~isempty(jj)
    deps(jj) = interp1(1:40,std_deps,levels(jj));
  end
else
  ii = find(~isnan(levels));
  deps(ii) = interp1(1:40,std_deps,levels(ii));
end
