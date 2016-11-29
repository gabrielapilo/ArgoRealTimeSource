% COLOURPLOT  x-y plot of symbols, whose colour is determined by z.
% INPUT:  xx    x coords
%         yy    y coords
%         zz    z coordinate which determines colour
% Optional:       (can use empty [] if require some but not others) 
%         symb   string defining a normal "plot" symbol
%         cpmin  Min value for colour map
%         cprng  Range of colour map (so caxis will be [cpmin cpmin+cprng])
% *NEW* -->      Use the -ve of required range to plot data in descending order. 
%         msz    Marker size for symbols
%         blur   If 1, add small random error to locations to see coincident
%                points [if >1 then error range = max(range)/blur]
%
% Note: Line marker symbols are catered for, but may consume much more time
%       and memory.
%
% WARNINGS: Apply required colour map FIRST (cannot change it after plotting)
%           Data is plotted in order of zz, NOT as ordered in input arrays.
%
% Jeff Dunn  8/11/96  15/1/98  19/6/98  31/7/00  2/10/00
%
% USAGE: colourplot(xx,yy,zz,symb,cpmin,cprng,msz,blur)

function colourplot(xx,yy,zz,symb,cpmin,cprng,msz,blur)

if nargin==0
  disp('colourplot(xx,yy,zz,{symb,cpmin,cprng,msz})');
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
  symb = '+';
end
if nargin < 5 | isempty(cpmin)
  cpmin = min(zz);
end
if nargin < 6 | isempty(cprng)
  cprng = max(zz) - cpmin;
end
if nargin < 7
  msz = [];
end

cm = colormap;
lcm = size(cm,1);

if nargin < 8 | isempty(blur)  
   blur = 0;
end
if blur
   if blur==1; blur=30; end
   rng = max([(max(xx)-min(xx)) (max(yy)-min(yy))])/blur;
   xx = xx+rng*(rand(size(xx))-.5);
   yy = yy+rng*(rand(size(yy))-.5);
end


if strcmp(symb(1),'-') | strcmp(symb,':')
  
  % Plot data in original order, esp. for drawing continuous lines

  cprng = abs(cprng);
  
  limit = find(zz<cpmin);
  if ~isempty(limit)
    zz(limit) = cpmin*ones(size(limit));
    disp([num2str(length(limit)) ' data increased to CPMIN'])
  end

  limit = find(zz>(cpmin+cprng));
  if ~isempty(limit)
    zz(limit) = (cpmin+cprng)*ones(size(limit));
    disp([num2str(length(limit)) ' data decreased to CPMIN+CPRNG'])
  end

  cc = cm(1+ floor((lcm-1)*(zz-cpmin)./cprng),:);

  for ii=2:length(xx)
    plot(xx([ii-1 ii]),yy([ii-1 ii]),symb,'Color',cc(ii,:));
  end

else
  
  % Plot in groups of like value, to reduce time and memory consumption.
  
  % Crappy way (but only way?) to get default markersize
  if isempty(msz)
     hh = plot(xx(1),yy(1),'o');
     msz = get(hh,'MarkerSize');
     delete(hh);
  end
  
  idx = 1:length(zz);

  if cprng>0
     % Plot colours in ascending order
     for ii=1:lcm-1
	kk = find(lcm*(zz(idx)-cpmin)./cprng < ii);
	plot(xx(idx(kk)),yy(idx(kk)),symb,'Color',cm(ii,:),'MarkerSize',msz);
	idx(kk) = [];
     end
     plot(xx(idx),yy(idx),symb,'Color',cm(lcm,:),'MarkerSize',msz);
  else
     % Plot colours in descending order (lowest values last)
     cprng = -cprng;
     for ii=lcm:-1:2
	kk = find(lcm*(zz(idx)-cpmin)./cprng > ii);
	plot(xx(idx(kk)),yy(idx(kk)),symb,'Color',cm(ii,:),'MarkerSize',msz);
	idx(kk) = [];
     end
     plot(xx(idx),yy(idx),symb,'Color',cm(1,:),'MarkerSize',msz);
  end
end

% And now, a terrible slight-of-hand to get colorbar to work properly -
% the last child of the axis must be a patch...
    
caxis([cpmin cpmin+cprng])
aa = axis;
h = patch(aa(1),aa(3),[1 1 1]);
set(h,'EdgeColor','none');

% --------------- End of colourplot.m ----------------------
