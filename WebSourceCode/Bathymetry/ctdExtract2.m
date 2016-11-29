function [p,lon,lat,time,bdepth,varargout] = ctdExtract2(fname,varargin)

% ctdExtract2  Read DPG CTD data from netCDF files
%
%   [p,lon,lat,time,bdepth] = ctdExtract(filename);
% Given a list of CTD station files, 'filename', return
%  p   pressure for the full range of pressures covered by the station files
%  lon   the longitude
%  lat   the latitude
%  time   decimal days since 1900 (use time2greg to get [yr mon day hr min sec]).
%  bdepth  bottom depth
%
%   [p,lon,lat,time,bdepth,v1,v2, ...] = ctdExtract2(filename,p1,p2, ...);
% As above, but also return data v1, v2, ..., for CTD data types 'p1', 'p2',etc.
% 'p1', 'p2', etc. are strings with the following values (case SENSITIVE):
%   't'  - temperature
%   's'  - salinity
%   'o'  - dissolved oxygen
%   'Tr' - digitizer channel (transmissometer)
%   'Fl' - digitizer channel (fluorometer)
%
% WARNING: Data variables ncast X ndepths may be very large.
%
%   Derived from ctd_extract as written by:
%   Jeff Dunn  15/1/98  CSIRO Division of Marine Research
%   Modified for use as a function by Lindsay Pender 21/5/98 and again 5/11/99
%   Modified Jeff Dunn 16/8/00
   
if ~nargin | isempty(fname)
  fname = 'ctdnames.lis';
end

miss = zeros(1,nargin-1);

fid = fopen(fname,'r');
name_bin = fread(fid)';
fclose(fid);
crtns = find(name_bin==10);
names = setstr(name_bin);
numsta = length(crtns);
clear name_bin

%  Suppress tedious netCDF warnings
ncmex('setopts',0);

if ~numsta
  return;
end

start = 1;
maxrecs = 0;

for ii=1:numsta
  fname = deblank(names(start:crtns(ii)-1));
  
  nc = netcdf(['/home/dpg/export/ctd_arc/' fname '.cdf'],'nowrite');
  if isempty(nc)
     error(['Cannot open ' fname])
  end
  nrecs = length(nc('number_of_data_records'));
  if nrecs > maxrecs
    maxrecs = nrecs;
    p = nc{'pressure'}(:);
  end
  close(nc);
  
  start = crtns(ii)+1;
end

lat = repmat(nan,numsta,1);
lon = repmat(nan,numsta,1);
time = repmat(nan,numsta,1);
bdepth = repmat(nan,numsta,1);
for ii = 1:(nargin-1)
   varargout{ii} = repmat(nan,numsta,maxrecs);
end

start = 1;

for ii=1:numsta
  fname = deblank(names(start:crtns(ii)-1));
  
  nc = netcdf(['/home/dpg/export/ctd_arc/' fname '.cdf'],'nowrite');
  
  % Because of loose use of ASCII fields in the global attributes, it is safer
  % to get cruise details from file names than from those attributes. 

  n1 = 8;

  sves = fname(1:1);
  scr_id = fname(3:6);

  lst = length(fname);
  sstn = fname(lst-2:lst);

  sdep = nc.Bottom_depth(:);

  % Get start time if available. I would prefer bottom time, but the date is
  % apparently for the start time, and I'm too lazy to do the testing and
  % correcting of the date to match the bottom time.

  stime = nc.Start_time(:);
  if isempty(deblank(stime))
    stime = nc.Bottom_time(:);
    if isempty(deblank(stime))
      stime = nc.End_time(:);
      if isempty(deblank(stime))
	stime = '    ';
      end
    end
  end
  
  sdate = nc.Date(:);

  % Get a lat lon, preferably from bottom position
  
  pos = nc.Bottom_position(:);
  if pos(9:9)~='N' & pos(9:9)~='S'
    pos = nc.Start_position(:);
    if pos(9:9)~='N' & pos(9:9)~='S'
      pos = nc.End_position(:);
    end
  end
  
  cr_id = str2num(scr_id);
  stn = str2num(sstn);

  tim = str2num(stime(1:4));
  if tim ~= 0
    hr = floor(tim/100);
    minu = rem(tim,100);
    tim = ((hr*60)+minu)/1440;
  end
 
  % Convert date to days_since_1900, which involves the magic number below

  yday = str2num(sdate(13:15));
  yr   = str2num(sdate(8:11));
  jday = julian(yr-1,12,31) - 2415020.5;
  time(ii) = jday + yday + tim;

  latd = str2num(pos(1:2));
  latm = str2num(pos(4:8));
  if strcmp(pos(9:9),'S')
    lat(ii) = -(latd + latm/60);
  else
    lat(ii) = latd + latm/60;
  end

  lond = str2num(pos(11:13));
  lonm = str2num(pos(15:19));
  ew   = strcmp(pos(20:20),'W');
  lon(ii)  = lond + lonm/60. + ew*180;

  % After decoding bottom depth, check for failed conversion
  bdepth(ii) = sscanf(sdep,'%d');
  if isempty(bdepth(ii))
    bdepth(ii) = sscanf(sdep,'%*s %d');
    if isempty(bdepth(ii)) 
      bdepth(ii) = NaN;
    end
  end

  nrecs = length(nc('number_of_data_records'));
  
  ndig = nc.no_dig_chan(:);
  if ndig>0
     digl = nc.Dig_labels(:);
     diglw = word_chop(digl);
  end
  
  for jj = 1:(nargin-1)
     switch varargin{jj}
      case 't'
       x = nc{'temperature'}(:);
       fil = nc{'temperature'}.Fillvalue(:);
	
      case 's'
       x = nc{'salinity'}(:);
       fil = nc{'salinity'}.Fillvalue(:);
	
      case 'o'
       x = nc{'dissolved'}(:);
       fil = nc{'dissolved'}.Fillvalue(:);
	
      otherwise
       x = [];
       if ndig>0
	  nn = strmatch(varargin{jj},diglw);
	  if ~isempty(nn)
	     x = nc{'digitiser_channels'}(nn,:);
	     fil = nc{'digitiser_channels'}.Fillvalue(:);
	  end
       end
     end
     
     if isempty(x)
	miss(jj) = miss(jj)+1;
     else
	x(x==fil) = NaN;
	varargout{jj}(ii,1:nrecs) = x;
     end
  end

  close(nc);
  
  start = crtns(ii)+1;
end

for jj = 1:(nargin-1)
   if miss(jj)   
	disp([num2str(miss(jj)) ' files had no data of type ' varargin{jj}])
   end
end

% --------------- End of ctd_extract ----------------
