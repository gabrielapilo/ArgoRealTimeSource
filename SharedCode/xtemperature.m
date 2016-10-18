function c = xtemperature(m)
%XTEMPERATURE a color spectrum from blue-magenta-red-yellow       
%	XTEMPERATURE(M) returns an M-by-3 matrix containing a
%	temperature-scale colormap (but without white hot).
%	XTEMPERATURE, by itself, is the same length as the current colormap.
%
%	For example, to reset the colormap of the current figure:
%
%	          colormap(xtemperature)
%
%	See also HSV, HOT, COOL, BONE, COPPER, PINK, FLAG, 
%	COLORMAP, RGBPLOT.

%     Copyright J. V. Mansbridge, CSIRO, Tue Aug  2 11:15:23 EST 1994


% case (5) a 32 color spectrum from blue-magenta-red-yellow-white        

x = [
    0,   0,  95,     0,   0, 135,     0,   0, 175,     0,   0, 215,
    0,   0, 255,    28,   0, 255,    56,   0, 255,    85,   0, 255,
  113,   0, 255,   141,   0, 255,   170,   0, 255,   198,   0, 255,
  226,   0, 255,   255,   0, 255,   255,   0, 204,   255,   0, 153,
  255,   0, 102,   255,   0,  51,   255,   0,   0,   255,  28,   0,
  255,  56,   0,   255,  85,   0,   255, 113,   0,   255, 141,   0,
  255, 170,   0,   255, 198,   0,   255, 226,   0,   255, 255,   0,
  255, 255,  64,   255, 255, 128,   255, 255, 192,   255, 255, 255
];

% case (5) a 30 color spectrum from blue-magenta-red-yellow

x = [
    0,   0,  95,     0,   0, 135,     0,   0, 175,     0,   0, 215, ...
    0,   0, 255,    28,   0, 255,    56,   0, 255,    85,   0, 255, ...
  113,   0, 255,   141,   0, 255,   170,   0, 255,   198,   0, 255, ...
  226,   0, 255,   255,   0, 255,   255,   0, 204,   255,   0, 153, ...
  255,   0, 102,   255,   0,  51,   255,   0,   0,   255,  28,   0, ...
  255,  56,   0,   255,  85,   0,   255, 113,   0,   255, 141,   0, ...
  255, 170,   0,   255, 198,   0,   255, 226,   0,   255, 255,   0, ...
  255, 255,  64,   255, 255, 128
];

% case (5) a 29 color spectrum from blue-magenta-red-yellow

x = [
    0,   0, 135,     0,   0, 175,     0,   0, 215, ...
    0,   0, 255,    28,   0, 255,    56,   0, 255,    85,   0, 255, ...
  113,   0, 255,   141,   0, 255,   170,   0, 255,   198,   0, 255, ...
  226,   0, 255,   255,   0, 255,   255,   0, 204,   255,   0, 153, ...
  255,   0, 102,   255,   0,  51,   255,   0,   0,   255,  28,   0, ...
  255,  56,   0,   255,  85,   0,   255, 113,   0,   255, 141,   0, ...
  255, 170,   0,   255, 198,   0,   255, 226,   0,   255, 255,   0, ...
  255, 255,  64,   255, 255, 128
];

len_x = length(x);
len_x_m1 = len_x - 1;
len_x_m2 = len_x - 2;
x_top = len_x/3 - 1;

x = x/255;
%x = reshape(x'/255, len_x, 1);
if nargin < 1, m = size(get(gcf,'colormap'),1); end
mm = m - 1;
x_orig = (0:x_top)/x_top;
x_m = (0:mm)/mm;
r = interp1(x_orig, x(1:3:len_x_m2), x_m);
g = interp1(x_orig, x(2:3:len_x_m1), x_m);
b = interp1(x_orig, x(3:3:len_x), x_m);
c = [ r' g' b' ];
