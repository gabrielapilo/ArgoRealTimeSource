function [data,lon,lat,date_used] = pfsst(limits,date_requested,varopt,...
	deci,data_dir)

% Retrieves a map of 10-day averaged estimates of NOAA/NASA Pathfinder SST
% closest to the date requested, within the lat/lon LIMITS requested.
%
% [data,lon,lat,date_used] = pfsst(limits,date_requested,varopt,deci,data_dir)
%---------------------------------------------------------------------
% LIMITS is a 4-element vector [lonmin lonmax latmin latmax]
%		as used by AXIS
%
% DATE_REQUESTED is a 6-element vector [year month day hr min sec]
%
% VAROPT can be:
%         'sst' to get the SST estimate (default)
%         'err' to get the expected error
%         'raw' to get the unprocessed Pathfinder best-SST
%
% DECI is equivalent to stride in a call to getnc : the factor by
%	which you want to dcimate the high resolution data (default = 1)
%
% DATA_DIR directory in which netcdf files reside (default exists)
%
% Outputs are matrices of DATA, LON, LAT, and the actual DATE_USED
% for the output data.
%
% This version reads the 10-day averaged data stored in netcdf files.
% The spatial resolution ~=0.114 degrees with lat/lon boundaries [90 200 -70 0]
% Optimally averaged Pathfinder data presently spans the time-period 
% [1987 2 14 0 0 0] to [1994 6 27 0 0 0]
%
% Produced : Alison Walker  & John Wilkin Sep-97
% 
%
% Oceans-EEZ project matlab tools are installed in:
% /home/eez_data/software/matlab 
%
% If this function fails when trying to execute function getnc, make sure
% the version 5 netcdf utilities are in your path.   They can be added
% interactively with the commands ...
% addpath /home/toolbox/local/netcdf_matlab5 -begin
% addpath /home/toolbox/local/netcdf_matlab5/nctype -begin
% addpath /home/toolbox/local/netcdf_matlab5/ncutility -begin
%
% The directory where the Pathfinder netcdf files are kept
%	driftwood:/rwx2/eez_data/sst/pathfinder_aus/

% CHECK INPUTS

if nargin < 5
   data_dir = platform_path('fips','eez_data/sst/pathfinder_aus/');
   if nargin < 4
  	deci=1;
   end
end
if nargin >= 3
  if ~(strcmp(varopt,'sst') | strcmp(varopt,'err') | strcmp(varopt,'raw'))
    error(['varopt must be sst, error or raw.  It was: ' varopt])
  end
else
  varopt = 'sst'; % default is to get the sst estimate
end

%if strcmp(varopt,'raw');
  reading_raw_data = strcmp(varopt,'raw');
  %error('raw data is not available with this function anymore')
%end

if strcmp(varopt,'err')
  varopt = 'error'; % so we can read this variable name fomr the netcdf file
end

lonmn = limits(1);
lonmx = limits(2);
latmn = limits(3);
latmx = limits(4);

% delta_angle of data grid interval is 360/4096;
vlimits = [90+[0 1251*360/4096] [-796 -1]*360/4096];

if lonmn<vlimits(1) | lonmx>vlimits(2) | latmn<vlimits(3) | latmx>vlimits(4)
  bell;
  disp(['Requested lon/lat limits exceed valid range ' mat2str(vlimits)])
  disp('The output will not cover the full area requested')
end

% CHOOSE APPROPRIATE NETCDF FILE
date_requested = gregorian(julian(date_requested));
year_req = date_requested(1)-1900;
if reading_raw_data 
   file=([data_dir 'pfsstr' num2str(year_req)]);
else
   file=([data_dir 'pfsste' num2str(year_req)]);
end

% FIND LAT, LON AND TIME INDICES

lon = getnc(file,'lon');
lat = getnc(file,'lat');
time = getnc(file,'time');

index = find(lon>lonmn & lon<lonmx);
xW = max([index(1)-1 1]);
xE = min([index(end)+1 length(lon)]);
index = find(lat>latmn & lat<latmx);
yN = max([index(1)-1 1]);
yS = min([index(end)+1 length(lat)]);

if reading_raw_data 
   time_lag = julian(date_requested)-(time+julian([1985 1 1 0 0 0]));
   index = find(abs(time_lag)==min(abs(time_lag)));
   t = index(1); 
   date_used = time(t)+julian([1985 1 1 0 0 0]);
   varopt  ='sst';
else
   time_lag = julian(date_requested)-(time+julian([1985 1 1 0 0 0]));
   index = find(abs(time_lag)==min(abs(time_lag)));
   t = index(1); % in case the date was exactly between two analysis dates
   date_used = time(t)+julian([1985 1 1 0 0 0]);

   if abs(time_lag(t)) >= 5.0001
  	if time_lag(t)>0
     	   year_req = year_req+1;
     	   file=([data_dir 'pfsste' num2str(year_req)]);
     	   time = getnc(file,'time');
     	   time_lag = julian(date_requested)-(time+julian([1985 1 1 0 0 0]));
     	   index = find(abs(time_lag)==min(abs(time_lag)));
     	   t = index(1); % in case the date was exactly between two analysis dates
     	   date_used = time(t)+julian([1985 1 1 0 0 0]);
     	   time_lag(t)
  	end
   	if time_lag(t)<0
     	   year_req = year_req-1;
     	   file=([data_dir 'pfsste' num2str(year_req)]);
     	   time = getnc(file,'time');
     	   time_lag = julian(date_requested)-(time+julian([1985 1 1 0 0 0]));
     	   index = find(abs(time_lag)==min(abs(time_lag)));
     	   t = index(1); % in case the date was exactly between two analysis dates
           date_used = time(t)+julian([1985 1 1 0 0 0]);
     	   time_lag(t)
  	end
   end
end

% RETRIEVE REQUESTED DATA FROM NETCDF FILES

% retrieve lat/lon data from netcdf file
lat = lat(yN:deci:yS);
lon = lon(xW:deci:xE);

% retrieve sst or error data from netcdf files
data = getnc(file,varopt,[t yN xW],[t yS xE],[1 deci deci],-1,-1);

if reading_raw_data
   %data = data + 254;
   data(find(data<0)) = data(find(data<0))+254;
   data = .15*data - 3.0;
   data=change(data,'==',-3.,nan);
end

% flip so that lat index is increasing from south to north
lat = flipud(lat);
data = flipud(data);
