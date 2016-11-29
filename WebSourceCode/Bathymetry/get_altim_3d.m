function [lon,lat,time,height_diff] = get_altim_3d(file,date_anal,p1,p2);
% Extract altimeter data from netcdf file created by program
% /home/eez_data/software/????/altim
%
% [lon,lat,time,height_diff] = get_altim_3d(file,date,xyrng,num_cycles);
%
% Required inputs:
% 
% FILE is the netcdf file of alongtrack data (no file extension)
% e.g. /home/eez_data/altim/WA_FRDC/top_west_9294(.nc)
%
% DATE is the analysis date in Gregorian format [year month day h m s]
%
% Optional inputs: (either or both may be given, in any order)
%
% XYRNG is a 4-element vector of [minlon maxlon minlat maxlat] limits
% (default is the whole lat/lon range in FILE)
% NUM_CYCLES is the even number of altimeter orbit cycles to extract, 
% bracketing the DATE (default num_cycles = 6)
% 
% Outputs:
%
% LON,LAT,TIME are alongtrack coordinates
% HEIGHT_DIFF is the altimeter height anomaly
%
% John Wilkin 6 May 97
% modified 29 Jul 97 for new getnc
%
% $Id: get_altim_3d.m,v 1.3 1998/01/26 23:21:53 wilkin Exp wilkin $
%
% Oceans-EEZ project matlab tools are installed in:
% /home/eez_data/software/matlab 

xyrng = []; 
num_cycles = [];
switch nargin
  case {0,1}
    error('At least 2 inputs, FILE and DATE, are required')
  case 2
  case 3
    if length(p1)==1
      num_cycles = p1;
    else
      xyrng = p1;
    end
  case 4
    if length(p2)==1
      num_cycles = p2;
      xyrng = p1;
    else
      xyrng = p2;
      num_cycles = p1;
    end
end
if isempty(num_cycles)
  num_cycles = 4;
end
if rem(num_cycles,2)~=0
  error('num_cycles must be an even number')
end

% get all three coordinates

% latitude
lat = getnc(file,'lat');
if ~isempty(xyrng)
  lat0 = min(find(lat>=xyrng(3) & lat<=xyrng(4)));
  lat1 = max(find(lat>=xyrng(3) & lat<=xyrng(4)));
  lat = lat(lat0:lat1);
else
  lat0 = 1;
  lat1 = length(lat);
end

% longitude
lon = getnc(file,'lon',[1 lat0],[-1 lat1],[1 1],[2 1],2,NaN,0);
if ~isempty(xyrng)
  trks_reqd = find(max(lon)>=xyrng(1) & min(lon)<=xyrng(2));
else
  trks_reqd = 1:size(lon,2);
end

% time
midlat = floor(size(lat,1)/2);
cycle_times = getnc(file,'time',[1 1 midlat],[-1 -1 midlat],...
    [1 1 1],[3 2 1],2,NaN,1);

% figure out times of each altimeter pass
day_begin = julian(1985,1,1)+min(cycle_times(:))/86400;

repeat_interval = nanmean(diff(cycle_times(:,1)))/86400;
%repeat_interval = diff(cycle_times(1:2,1))/86400;
days_of_cycles = day_begin+(0:size(cycle_times,1)-1)*repeat_interval;
day_end = max(days_of_cycles);

% target analysis time
day_anal  = julian(date_anal);
if day_anal < day_begin | day_anal > day_end
  error(['Data file does not include analysis date ' ...
      mat2str(date_anal(1:3))])
end

% get index of first and last cycle to extract from the data file
cycle_before = max(find((days_of_cycles-day_anal>0)==0));
cyc0 = cycle_before - ((num_cycles/2)-1);
cyc1 = cyc0 + num_cycles-1;

% check we don't exceed the cycles available in the file
if cyc0<0 | cyc1>size(cycle_times,1)
  disp(['Warning: there are not ' int2str(num_cycles) ...
      ' cycles bracketing the analysis date'])
  cyc0 = max(0,cyc0);
  cyc1 = min(cyc1,size(time,2));
end

% get the height anomaly data and times
height_diff = getnc(file,'height_diff',...
    [1 cyc0 lat0],[-1 cyc1 lat1],[1 1 1],[3 2 1],2,NaN,0);
time = getnc(file,'time',[1 cyc0 lat0],[-1 cyc1 lat1],[1 1 1],[3 2 1],2,NaN,0);

% clip the track dimension to get only those tracks in the required
% longitude range
height_diff = height_diff(:,:,trks_reqd); 
lon = lon(:,trks_reqd);
time = time(:,:,trks_reqd); 

% expand lat to 2 dimensions
lat = lat(:,ones([1 size(lon,2)]));

% permute indicies so that the order is lat,lon,time
time = permute(time,[1 3 2]);
height_diff = permute(height_diff,[1 3 2]);
