% MARKERPLOT  x-y plot of symbols, whose colour is determined by z.
% INPUT:  xx    x coords
%         yy    y coords
%         zz    z coordinate which determines size
% Optional:       (can use empty [] if require some but not others) 
%         symb   string defining a normal "plot" symbol. Default '+'
%         vrng   Range for values; eg [0 366]. Default [min(zz) max(zz)]
%         mrng   Marker size range; eg [1 14]. Default [1 16]   
%         col    colour string (eg 'm' for magenta)
%
% # Values outside vrng are plotted as though equal to max or min vrng.
%
% Jeff Dunn  11/8/99
%
% USAGE: markerplot(xx,yy,zz,symb,vrng,mrng,col);

function markerplot(xx,yy,zz,symb,vrng,mrng,col)

if nargin==0
  disp('USAGE: markerplot(xx,yy,zz,symb,vrng,mrng,col);');
  return
end

hold on

rej = find(isnan(zz));
if ~isempty(rej)
  xx(rej) = [];
  yy(rej) = [];
  zz(rej) = [];
end

if min(size(xx)) > 1
  xx = xx(:);
  yy = yy(:);
  zz = zz(:);
end

if nargin < 4 | isempty(symb)
  symb = 'd';
end
if nargin < 5 | isempty(vrng)
  vrng = [min(zz) max(zz)];
end
rng = diff(vrng);
if nargin < 6 | isempty(mrng)
  mrng = [1 16];
end
if mrng(1)<1 
   mrng(1) = 1;
end
msz = mrng(1):mrng(2);
lmsz = length(msz);
if nargin > 6 & ~isempty(col)
   symb = [col symb];
end

% Plot in groups of like value, to reduce time and memory consumption.
  
idx = 1:length(zz);

for ii = 1:lmsz
   kk = find(lmsz*(zz(idx)-vrng(1))./rng < ii);
   plot(xx(idx(kk)),yy(idx(kk)),symb,'MarkerSize',msz(ii));
   idx(kk) = [];
end

% Plot those left (values above max vrng)
plot(xx(idx),yy(idx),symb,'MarkerSize',mrng(2));


% This is no good because markersize gets restricted by "legend" 
%if leg & lmsz>2   
%   for ii = 2:lmsz-1; lstr{ii}=''; end
%   lstr{1} = num2str(vrng(1));
%   lstr{lmsz} = num2str(vrng(2));
%   legend(lstr,0);
%end


% --------------- End of markerplot.m ----------------------
