function handle = coast(symbol,linewidth);

% COAST      Draws coastlines in lat/lon coordinates.
%
%	COAST plots coastlines in the longitude range 0 to 360 using the 
%       Reid coastlines data.  Default is to draw entire world.  Use
%       AXIS to limit region.  Use HOLD to plot over data.
%
%       COAST('SYMBOL') uses linetype 'SYMBOL'.  Any linetype supported 
%       by PLOT is allowed.  The default is 'm-' (i.e., magenta). 
%
%       COAST(LINEWIDTH) or COAST('SYMBOL',LINEWIDTH) specifies thickness 
%       of lines.  Default is 1.
%
%       Optional output returns handle of coastline segments.  This can
%       be used to reset line properties such as thickness or colour using
%       the handle graphics command SET.  
% 
%	Examples:  >> contour(long,lat,z,v); hold on; h=coast('r-');
%       Plots coastlines over a contour plot created with contour and
%       returns the handle of the plotted coastline.
%                  >> set(h,'LineWidth',2)
%       This resets the thickness of all portions of coastline.
%                  >> set(h,'Color','c')
%       This changes the coastline colour to cyan. A vector RGB triple
%       may be used to specify the colour.
%                  >> set(h) 
%       shows properties that can be reset.

%	Files: Requires the toolbox file /local/csirolib/coastdata.mat
%	which contains the Reid coastlines data in a modified format.

%	John Wilkin 3 February 93
%       Peter McIntosh 26/5/94 - faster algorithm using new data set
%       John Wilkin 27 April 94 - changed input handling and help.
%       Jim Mansbridge hacked so that the coastdat.mat file is found
%         without using the TOOLBOX environment variable (this is not
%         useful on inverse).  It is now assumed that coastdat.mat is in
%         the same directory as coast.m.

if nargin < 1,
  symbol = 'm-';
  linewidth = 1;
end

if nargin == 1,
  if isstr(symbol)
    linewidth = 1;
  else
    linewidth = symbol;
    symbol = 'm-';
  end
end

%dir = [getenv('TOOLBOX') '/local/csirolib'];
temp = which('coast');
dir = temp(1:((length(temp) - 8)));
eval(['load ' dir '/coastdat']);

h = plot(coastdata_x,coastdata_y,symbol);

set(h,'LineWidth',linewidth);

if nargout>0,handle=h;end
