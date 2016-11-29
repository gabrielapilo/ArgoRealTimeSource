% CTD_EXTRACT  Read DPG CTD data from netCDF files   *** Matlab 5 ***
% 
%   Jeff Dunn  15/1/98  CSIRO Division of Marine Research
%
% FILE INPUT:  ASCII file called 'ctdnames.lis' with one CTD filename per line
%              as produced by "ctd_select".
%
% WARNING: For efficiency this script uses 'varget' rather than 'getnc', and
%          so assumes that no offsets, scale factors, or unusual fill or 
%          missing values have been applied in the DPG files.
%
% USAGE:
% 1. Obtain an ASCII file of CTD file names (use "ctd_select")
%
% 2. This script is INCOMPLETE - you need to make the following changes:
%
%   IF wanting to accumulate all casts before working with data, note that 
%   these are 2dB average casts, and matrices of size 
%   [ncasts X max_num_data_per_cast] could become huge. Also, if a moderate
%   number of casts, you will want to preallocate the arrays.
%
%   IF using data within Matlab, modify the line below to: "decode_data = 1"
%   IF writing out ASCII,        modify the line below to: "decode_data = 0"
%
%   Put your code to actually DO something with the data in the appropriate 
%   place near the bottom of this script.
%
%   Modify or remove to suit the lines which extract different variables. 
%   
% 3. Invoke this script:
%        >> ctd_extract


decode_data = ?????????????;



% Get list of names of CTD netCDF files as produced by ctd_select. These
% comprise the cruise subdirectory path and filename, but not the full path
% nor the '.cdf' extension.
% Grungy scheme from old Matlab: read as one big vector of numbers,
% then find the "CR"s (decimal 10) to split it up into individual names.
% Convert the numbers to ASCII.

filename = uigetfile('ctdnames*.lis', 'File with names of CTD files');
fid = fopen(filename, 'r');
name_bin = fread(fid)';
fclose(fid);
crtns = find(name_bin==10);
names = setstr(name_bin);
numsta = length(crtns);
clear name_bin

% Preallocate arrays here if required and possible

% EG
%lon = zeros(numsta, 1);
%lat = zeros(numsta, 1);
%year = zeros(numsta, 1);
%month = zeros(numsta, 1);
%time_of_day = zeros(numsta, 1);
%bottom_depth = zeros(numsta, 1);


%  Suppress tedious netCDF warnings
ncmex('setopts',0);


start = 1;

for ii=1:numsta

  fname = deblank(names(start:crtns(ii)-1));
  
  cdfid = ncmex('ncopen',['/home/dpg/export/ctd_arc/' fname '.cdf'],'nowrite');
  
  % Because of loose use of ASCII fields in the global attributes, it is safer
  % to get cruise details from file names than from those attributes. 

  n1 = 8;

  sves = fname(1:2);
  scr_id = fname(3:6);

  lst = length(fname);
  sstn = fname(lst-2:lst);

  sdep = ncmex('ncattget', cdfid, 'global', 'Bottom_depth');

  % Get start time if available. I would prefer bottom time, but the date is
  % apparently for the start time, and I'm too lazy to do the testing and
  % correcting of the date to match the bottom time.

  stime = ncmex('ncattget', cdfid, 'global', 'Start_time');
  if isempty(deblank(stime))
    stime = ncmex('ncattget', cdfid, 'global', 'Bottom_time');
    if isempty(deblank(stime))
      stime = ncmex('ncattget', cdfid, 'global', 'End_time');
      if isempty(deblank(stime))
	stime = '    ';
      end
    end
  end
  
  sdate = ncmex('ncattget', cdfid, 'global', 'Date');

  % Get a lat lon, preferably from bottom position
  
  pos = ncmex('ncattget', cdfid, 'global', 'Bottom_position');
  if pos(9:9)~='N' & pos(9:9)~='S'
    pos = ncmex('ncattget', cdfid, 'global', 'Start_position');
    if pos(9:9)~='N' & pos(9:9)~='S'
      pos = ncmex('ncattget', cdfid, 'global', 'End_position');
    end
  end
  
  
  [dimnam,nrecs] = ncmex('ncdiminq',cdfid,'number_of_data_records');
  
  % ******* Modify or remove lines below so extract only the data required:
  %   
  % EXAMPLE 1: get all of variable "pressure":
  %
  %   pp = ncmex('varget',cdfid,'pressure',0,nrecs);
  %
  % EXAMPLE 2: get a particular depth range of "temperature" (having previously
  %            extracted pressure). Note that conversion to depth is optional
  %            and does require decoded latitude. Also note that records are
  %            indexed from 0 to (number_of_records)-1
  %  
  %   ddep = sw_dpth(pp,lat);     % For precision, convert pressure to depth
  %   recs = find(ddep>depth1 & ddep<depth2);
  %   count = length(recs);
  %   if nrecs > 0
  %      t = ncmex('varget',cdfid,'temperature',[recs(1)-1],count]);
  %   end
  %
  % OTHER VARIABLE NAMES:
  %   'salinity'  
  %   'std(temp)'
  %   'std(cond)' 
  %   'digitiser_channels'  - This has dimensions [digitiser_channels, nrecs]
  %
  % EXAMPLE 3:  to access digitiser channels (say the "Light" channel)
  %   digl = ncmex('ncattget', cdfid, 'global', 'Dig_labels');
  %   diglw = word_chop(digl);
  %   for ii = 1:length(diglw)
  %      if strcmpi(diglw{ii},'Light')
  %         idig = ii;
  %      end
  %   end
  %   if nrecs > 0
  %      light = ncmex('varget',cdfid,'digitiser_channels',[ii-1 0],[1 nrecs]);
  %   end
  %
  % *******
  
  
  if decode_data
    
    if sves=='fr'
      ves_id = 1;
    elseif sves=='ss'
      ves_id = 2;
    elseif sves=='aa'
      ves_id = 3;
    elseif sves=='g9'
      ves_id = 4;
    elseif sves=='as'
      ves_id = 5;
    else
      ves_id = -1;
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
    time = jday + yday + tim;

    latd = str2num(pos(1:2));
    latm = str2num(pos(4:8));
    if strcmp(pos(9:9),'S')
      lat = -(latd + latm/60);
    else
      lat = latd + latm/60;
    end

    lond = str2num(pos(11:13));
    lonm = str2num(pos(15:19));
    ew   = strcmp(pos(20:20),'W');
    lon  = lond + lonm/60. + ew*180;

    % After decoding bottom depth, check for failed conversion
    bdepth = sscanf(sdep,'%d');
    if isempty(bdepth)
      bdepth = sscanf(sdep,'%*s %d');
      if isempty(bdepth) 
	bdepth = NaN;
      end
    end

    % might be useful:
    %  month(ii) = str2num(datestr(datenum(sdate(1:11)), 5));
    
    % ****** Put your code to use numeric data here *******
  
    
    % *****************************************************
    
  else
    
    % ASCII data is in the following variables
    % sves   - ship
    % scr_id - cruise
    % sstn   - station number
    % sdep   - bottom depth
    % stime  - time (start time if available, otherwise bottom or end time)
    % sdate  - date (of start time)
    % pos    - position (bottom if available, otherwise start or end position)
    % 
    % ****** Put your code to write ASCII data here *******
  
    
    % *****************************************************
        
  end
    
  ncmex('ncclose',cdfid);
  
  start = crtns(ii)+1;
end
  

% --------------- End of ctd_extract -----------------
