function handle = gebco_eez(contour, symbol, linewidth, limit_island);

% GEBCO_EEZ      Draws coastlines in lat/lon coordinates.
%
%	GEBCO_EEZ plots bathymetric contours in the longitude range 100 to
%	200 and the latitude range -46.6666 to 0 (sort of Australian EEZ)
%       using the GEBCO data.  Default is to draw over entire
%       latitude/longitude region.  Use AXIS to limit region.
%
%       GEBCO_EEZ(CONTOUR) uses the vector CONTOUR and plots the depth
%       contours closest to those given in the vector. Note that in some
%       regions some gebco contours do not exist and so there is no
%       guarantee that a desired contour will be plotted.
%
%       GEBCO_EEZ('SYMBOL') uses linetype 'SYMBOL'.  Any linetype supported 
%       by PLOT is allowed.  The default is 'm-' (i.e., magenta). SYMBOL may
%       be a cell array of different symbols for each contour.
%
%       GEBCO_EEZ(LINEWIDTH) or GEBCO_EEZ('SYMBOL',LINEWIDTH) specifies
%       thickness of lines.  Default is 1. LINEWIDTH may be a vector of
%       different linewidths for each contour.
%
%       GEBCO_EEZ(CONTOUR,'SYMBOL',LINEWIDTH, LIMIT_ISLAND) will only draw a
%       section of coastline if it contains more than LIMIT_ISLAND lon-lat
%       points. By setting LIMIT_ISLAND == 15 or so then small islands will
%       not be drawn and clutter up your plot. The default value is 0 in
%       which case all of the coastline will be drawn. This feature can
%       malfunction because not all of the coastlines are stored
%       contiguously; in particular, coastline sections could be omitted near
%       the boundaries of sheets. 
%
%       NOTE 1: If an empty array is passed as an argument then this will be
%       interpreted as the default, i.e., gebco_eez([], [], [], []) is
%       equivalent to gebco_eez(0, 'm-', 1, 0)
%       NOTE 2: This code will only work for matlab 5.0 and above.
% 
%       Optional output returns row vector of handle of coastline
%       segments.  This can be used to reset line properties such as
%       thickness or colour using the handle graphics command SET.
%       Note that there will be one handle for each contour level.
% 
%	Examples:  >> contour(lon,lat,z,v); h=gebco_eez(0, 'r-');
%       Plots coastlines over a contour plot created with contour and
%       returns the handle of the plotted coastline.
%                  >> set(h,'LineWidth',2)
%       This resets the thickness of all portions of coastline.
%                  >> set(h,'Color','c')
%       This changes the coastline colour to cyan. A vector RGB triple
%       may be used to specify the colour.
%                  >> set(h) 
%       shows properties that can be reset.
%
%       contour(lon,lat,z,v); gebco_eez([0 200 1000], {'b:', 'r', 'g--'})

%     Copyright J. V. Mansbridge, CSIRO, Tue Dec 13 14:32:01 EST 1994
%       $Id: gebco_eez.m,v 1.1 1999/10/22 03:37:51 mansbrid Exp $
%       Based on coast.m which was developed as below:
%	John Wilkin 3 February 93
%       Peter McIntosh 26/5/94 - faster algorithm using new data set
%       John Wilkin 27 April 94 - changed input handling and help.
%       Jim Mansbridge 3/8/95 - modified to use gebco data
%       Jim Mansbridge 3/8/95 - doesn't use unnecessary gebco sheets
%       Jim Mansbridge 10/4/96 - doesn't need the $TOOLBOX environment
%                                variable.
%       John Wilkin - some matlab5 syntax and the default action is always
%       to add to the current axes (not replace)

if nargin == 0
  contour = 0;
  symbol = 'm-';
  linewidth = 1;
  limit_island = 0;
elseif nargin == 1
  symbol = 'm-';
  linewidth = 1;
  limit_island = 0;
elseif nargin == 2
  if isstr(symbol) | iscell(symbol)
    linewidth = 1;
  else
    linewidth = symbol;
    symbol = 'm-';
  end
  limit_island = 0;
elseif nargin == 3
  limit_island = 0;
end

% Replace empty values with their defaults.

if isempty(contour)
  contour = 0;
end
if isempty(symbol)
  symbol = 'm-';
end
if isempty(linewidth)
  linewidth = 1;
end
if isempty(limit_island)
  limit_island = 0;
end

cont_levels = [ 0 50 100 200 300 400 500 1000 1500 2000 2500 3000 3500 ...
      4000 4500 4600 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 ...
      5800 5900 6000 6500 7000 7500 8000 8500 9000 9500 10000 ];
num_cont_levels = length(cont_levels);

% Find the directory which contains the required mat files.

temp = which('gebco_eez_1.mat');
dir = temp(1:((length(temp) - 15)));

nextpl_gcf = get(gcf, 'NextPlot');
ax = gca;
nextpl_gca = get(ax, 'NextPlot');
xlim = get(gca, 'XLim');
ylim = get(gca, 'YLim');
han = [];

set(gcf,'nextplot','add');
set(ax,'nextplot','add');

len_linewidth = length(linewidth);
len_contour = length(contour);
if iscell(symbol)
  len_symbol = length(symbol);
else
  len_symbol = 1;
end

% error checks

if len_contour ~= 1
  if (len_linewidth > 1) & (len_linewidth < len_contour)
    error('linewidth vector is the wrong length')
  end
  if (len_symbol > 1) & (len_symbol < len_contour)
    error('symbol vector is the wrong length')
  end
end

for ii = 1:len_contour

  % Find the nearest contour to the desired one.

  [mm, i_cont] = min(abs(cont_levels - contour(ii)));

  % Do the plot.
  
  name = ['gebco_eez_' num2str(i_cont)];
  load([dir name])
  
  % Get rid of the short line segments (for more details of the method see
  % gebco.m)
  
  if limit_island > 0
    ff = find(isnan(lon));
    dd = diff(ff);
    ff2 = find(dd <= limit_island);
    if ~isempty(ff2)
      low = ff(ff2)+1;
      up = ff(ff2+1)-1;
	
      len_low = length(low);
      mat_a = repmat(low, 1, limit_island - 1) + ...
	      repmat(0:limit_island - 2, len_low, 1);
      mat_b = repmat(up, 1, limit_island - 1);
      ff3 = find(mat_a > mat_b);
      if ~isempty(ff3)
	mat_a(ff3) = repmat(low(1), size(ff3));
      end
      ff4 = mat_a(:);
      lon(ff4) = repmat(NaN, size(ff4));
      lat(ff4) = repmat(NaN, size(ff4));
    end
  end
  if len_symbol > 1
    h = plot(lon, lat, symbol{ii});
  else
    h = plot(lon, lat, symbol);
  end
  if len_linewidth > 1
    set(h,'LineWidth',linewidth(ii));
  else
    set(h,'LineWidth',linewidth);
  end
  han = [han h];

end

set(gca, 'XLim', xlim);
set(gca, 'YLim', ylim);
set(gcf, 'NextPlot', nextpl_gcf);
set(ax, 'NextPlot', nextpl_gca);

if nargout>0,handle=han;end
