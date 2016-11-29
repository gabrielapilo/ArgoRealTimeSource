function [data, date_serial, site_name] = read_ntf(file, data_limits, ...
						  time_limits)
% read_ntf reads a National Tidal Facility data file
% [data, date_serial, site_name] = read_ntf(file, data_limits, time_limits)
%
%    INPUT
% file: name of the NTF file
% data_limits: a 2 element vector used to specify outliers. All data values
%              < data_limits(1) or > data_limits(2) will be returned as
%              NaNs. If no vector or an empty vector is passed it will be
%              treated as if it was [-Inf Inf], i.e., there are no outliers.
% time_limits: a 2 element vector used to set a time window. The only values
%              returned in data, date_serial will be those where date_serial
%              >= time_limits(1) and <= time_limits(2). If no vector or an
%              empty vector is passed it will be treated as if it was [-Inf
%              Inf], i.e., all data points will be returned. The elements
%              refer to serial days as produced by datenum.
%
%    OUTPUT
%
% data: a vector of tide data
% date_serial: a vector of serial dates as produced by datenum.
% site_name: a string giving the site name.
%
%    EXAMPLES
%
% 1)
%
% file = '/home/eez_data/sealevel/seaframe/proc/sb.dat';
% [data, date_serial, site_name] = read_ntf(file, [0 2], ...
%	                           [datenum('4-Jul-1999') Inf]);
%
% 2)
%
% [data, date_serial, site_name] = read_ntf(file, [], ...
%	[datenum('4-Jul-1999') datenum('15-Sep-1999 15:45:17')]);

% $Id: read_ntf.m,v 1.4 2001/08/22 07:50:53 man133 Exp $
% Copyright J. V. Mansbridge, CSIRO, Wed Aug 22 14:58:28 EST 2001

% Check inputs and set defaults.

if nargin == 1
  data_limits = [-Inf Inf];
  time_limits = [-Inf Inf];
elseif nargin == 2
  if isempty(data_limits)
    data_limits = [-Inf Inf];
  elseif prod(size(data_limits)) ~= 2
    error('data_limits must be a vector of length 2')
  end
  time_limits = [-Inf Inf];
elseif nargin == 3
  if isempty(data_limits)
    data_limits = [-Inf Inf];
  elseif prod(size(data_limits)) ~= 2
    error('data_limits must be a vector of length 2')
  end
  if isempty(time_limits)
    time_limits = [-Inf Inf];
  elseif prod(size(data_limits)) ~= 2
    error('time_limits must be a vector of length 2')
  end
else
  error('There must be 1, 2 or 3 input arguments')
end
  
% Create a temporary file with '******' replaced by ' 9.999' and '/' and ':'
% replaced by ','. Then read this file into matlab before deleting it. This
% is necessary because the file format is a bit complicated for matlab and
% textread does NOT work as documented - specifically, when reading with the
% %c option some white spaces are thrown away.

tempfile = tempname;
str = ['cat ' file ' | sed ''s/\//,/g'' | sed ''s/:/,/''' ...
       ' | sed ''s/\*\*\*\*\*\*/ 9.999/'' > ' tempfile];
unix(str);
site = textread(tempfile, '%s', 1);
site_name = site{1};
[day, month, year, hour, minute, data] = textread(tempfile, ...
		'%d %d %d %d %d %f', 'delimiter', ',', 'headerlines', 2);
delete(tempfile)
date_serial = datenum(year, month, day, hour, minute, 0);
len_data = length(data);

% Replace outliers with NaNs.

if ~isnan(sum(data_limits)) % Inf - Inf == NaN
  ff = find((data < data_limits(1)) | (data > data_limits(2)));
  if ~isempty(ff)
    data(ff) = NaN;
  end
end

% Subset the data in time.

if ~isnan(sum(time_limits)) % Inf - Inf == NaN
  ff = find((date_serial >= time_limits(1)) & (date_serial <= time_limits(2)));
  if isempty(ff)
    data = [];
    date_serial = [];
  else
    data = data(ff);
    date_serial = date_serial(ff);
  end
end
