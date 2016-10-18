function handle = gebco(symbol, linewidth, limit_island)

% GEBCO      Draws coastlines in lat/lon coordinates.
%
%	GEBCO plots coastlines in the longitude range -180 to 540 using
%       the GEBCO coastlines data.  Default is to draw over entire
%       latitude/longitude region.  Use AXIS to limit region.  Use
%       HOLD to plot over data.
%
%       GEBCO('SYMBOL') uses linetype 'SYMBOL'.  Any linetype supported 
%       by PLOT is allowed.  The default is 'm-' (i.e., magenta). 
%
%       GEBCO(LINEWIDTH) or GEBCO('SYMBOL',LINEWIDTH) specifies thickness 
%       of lines.  Default is 1.
%
%       Optional output returns row vector of handle of coastline
%       segments.  This can be used to reset line properties such as
%       thickness or colour using the handle graphics command SET.
%       Note that there will be one handle for each gebco sheet.
%
%       GEBCO('SYMBOL',LINEWIDTH, LIMIT_ISLAND) will only draw a section of
%       coastline if it contains more than LIMIT_ISLAND lon-lat points. By
%       setting LIMIT_ISLAND == 15 or so then small islands will not be drawn
%       and clutter up your plot. The default value is 0 in which case all of
%       the coastline will be drawn. This feature can malfunction because not
%       all of the coastlines are stored contiguously; in particular, since
%       there are actually 31 sheets to cover the globe then coastline
%       sections could be omitted near the boundaries of sheets.
%
%       NOTE 1: If an empty array is passed as an argument then this will be
%       interpreted as the default, i.e., gebco([], [], []) is equivalent to
%       gebco('m-', 1, 0)
%       NOTE 2: This code will only work for matlab 5.0 and above.
% 
%	Examples:  >> contour(long,lat,z,v); hold on; h=gebco('r-');
%       Plots coastlines over a contour plot created with contour and
%       returns the handle of the plotted coastline.
%                  >> set(h,'LineWidth',2)
%       This resets the thickness of all portions of coastline.
%                  >> set(h,'Color','c')
%       This changes the coastline colour to cyan. A vector RGB triple
%       may be used to specify the colour.
%                  >> set(h) 
%       shows properties that can be reset.

%     Copyright J. V. Mansbridge, CSIRO, Tue Dec 13 14:32:01 EST 1994
%       $Id:
%       Based on coast.m which was developed as below:
%	John Wilkin 3 February 93
%       Peter McIntosh 26/5/94 - faster algorithm using new data set
%       John Wilkin 27 April 94 - changed input handling and help.
%       Jim Mansbridge 3/8/95 - modified to use gebco data
%       Jim Mansbridge 3/8/95 - doesn't use unnecessary gebco sheets
%       Jim Mansbridge 10/4/96 - doesn't need the $TOOLBOX environment
%                                variable.

if nargin == 0
  symbol = 'm-';
  linewidth = 1;
  limit_island = 0;
elseif nargin == 1
  if isstr(symbol)
    linewidth = 1;
  else
    linewidth = symbol;
    symbol = 'm-';
  end
  limit_island = 0;
elseif nargin == 2
  limit_island = 0;
end

% Replace empty values with their defaults.

if isempty(symbol)
  symbol = 'm-';
end
if isempty(linewidth)
  linewidth = 1;
end
if isempty(limit_island)
  limit_island = 0;
end

% Find the directory which contains gebco_limits.mat. Method 1 used the
% environment variable $TOOLBOX but setting this appropriately is messy (it
% is done in the matlab script). Method 2  assumed that it is in the
% same directory as gebco.m. Method 3 uses the matlab5 extension to 'which'
% to directly find gebco_limits.mat.

temp = which('gebco_limits.mat');
dir = temp(1:((length(temp) - 16)));

nextpl = get(gcf, 'NextPlot');
xlim = get(gca, 'XLim');
ylim = get(gca, 'YLim');
han = [];

% Get the matrix detailing the lon and lat limits of the gebco sheets.

eval(['load ' dir 'gebco_limits']);

% Work through each sheet and only plot those which will appear in the
% region defined by the current axis.

for i = 501:531
  ii = i - 500;
  if( (gebco_limits(ii, 3) < xlim(2)) & ...
	(gebco_limits(ii, 4) > xlim(1)) & ...
	(gebco_limits(ii, 1) < ylim(2)) & ...
	(gebco_limits(ii, 2) > ylim(1)) )
    name = ['gebco' num2str(i)];
    eval(['load ' dir name]);
    eval(['matrix = ' name ';']);
    
    % Get rid of the short line segments
  
    if limit_island > 0
      ff = find(isnan(matrix(:, 1)));
      dd = diff(ff);
      ff2 = find(dd <= limit_island);
      if ~isempty(ff2)
	low = ff(ff2)+1;
	up = ff(ff2+1)-1;
	
	% Messy code. This does the same as the following, less complicated,
        % code that I have commented out but should be quicker when there are
        % a lot of islands to be NaNed out.
	
	len_low = length(low);
	mat_a = repmat(low, 1, limit_island - 1) + ...
		repmat(0:limit_island - 2, len_low, 1);
	mat_b = repmat(up, 1, limit_island - 1);
	ff3 = find(mat_a > mat_b);
	if ~isempty(ff3)
	  mat_a(ff3) = repmat(low(1), size(ff3));
	end
	ff4 = mat_a(:);
	matrix(ff4, 1) = repmat(NaN, size(ff4));
	matrix(ff4, 2) = repmat(NaN, size(ff4));
	
	% dd_ff2 = dd(ff2)-1;
	% for jj = 1:length(low)
	  % matrix(low(jj):up(jj), 1) = repmat(NaN, dd_ff2(jj), 1);
	  % matrix(low(jj):up(jj), 2) = repmat(NaN, dd_ff2(jj), 1);
	% end
      end
    end
    
    % Do the plot
    
    h = plot(matrix(:, 2), matrix(:, 1), symbol);
    set(h,'LineWidth',linewidth);
    han = [han h];
    hold on
  end
end
set(gca, 'XLim', xlim);
set(gca, 'YLim', ylim);
set(gcf, 'NextPlot', nextpl);

if nargout>0,handle=han;end
