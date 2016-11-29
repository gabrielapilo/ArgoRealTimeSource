function y = wmo(x1, x2)
% wmo(longitude, latitude) returns the wmo 10-degree square no.
% wmo(wmo_square) returns [longitude, latitude] at the middle of the
% named wmo_square.
% Note that wmo is not vectorised and so x1 and x2 must be scalars.

% Copyright J. V. Mansbridge, CSIRO, Thu Feb 15 13:32:52 EST 1996
% $Id: wmo.m,v 1.1 1996/02/15 03:42:29 mansbrid Exp $

% Generate a matrix containing the 10-degree wmo square values.

w = ones(9, 1)*(0:8);
w = w + 100*w';
fw = flipud(w);
wmo_sq = [fw+3000  fw+3009  fliplr(fw)+5009  fliplr(fw)+5000;
    w+1000  w+1009  fliplr(w)+7009  fliplr(w)+7000];
flipud(wmo_sq);

% Generate vectors containing the longitudes and latitudes of the
% centres of the wmo 10-degree squares.

lon = 5:10:355;
lat = -85:10:85;

if nargin == 1
  if max(size(x1)) ~= 1
    error('wmo must be passed a scalar')
  end
  [ii, jj] = find(wmo_sq == x1);
  if isempty(ii)
    error([num2str(x1) ' is not a proper wmo square'])
  end
  y = [lon(jj) lat(ii)];
elseif nargin == 2
  if (max(size(x1)) ~= 1) | (max(size(x2)) ~= 1)
    error('wmo must be passed scalars')
  end
  % Put longitude in the range 0 to 360
  jj = ceil(x1/10);
  jj = rem(jj-1, 36) + 1;
  if jj <= 0
    jj = jj + 36;
  end
  ii = ceil((x2+90)/10);
  if (x2 < -90 | x2 > 90)
    error(['latitude = ' num2str(x2) ' is unacceptable'])
  elseif ii == 0
    ii = 1;
  elseif ii == 19
    ii = 18;
  end
  y = wmo_sq(ii, jj);
else
  disp('wmo(longitude, latitude) returns the wmo 10-degree square no.')
  disp('wmo(wmo_square) returns [longitude, latitude] at the middle of')
  disp('the named wmo_square.')
end
