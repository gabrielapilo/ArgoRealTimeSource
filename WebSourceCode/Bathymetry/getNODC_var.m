function [lat,lon,time,var1,var2,var3,var4,var5] ...
    = getNODC_var(file_sufs,scrlev,latrng,lonrng,a5,a6,a7,a8,a9,a10,a11,a12,a13)

% getNODC_var:  Extract lat-lons, times and cast data from netcdf files.
% INPUT: 
%   file_sufs   column of one or more of these file suffix strings:
%               '_bot' '_bot2' '_xbt' '_xbt2' '_mbt' '_mbt2' '_ctd' '_ctd2'
%               '_isd'  [If more than one string, use str2mat to create.]
%   scrlev  -1: as for 0, and also reject where all of selected cast isnan
%                in variable 1.
%            0: reject on basis of NODC and local csiro screening
%            1: reject only on basis local csiro screening
%            2: reject nothing
%   latrng EITHER [lat1 lat2] latitude range (southern-most first)
%          OR  [lat1 ... latN] latitudes of vertices of a polygon.
%   lonrng EITHER [lon1 lon2] longitude range (western-most first)
%          OR  [lon1 ... lonN] corresponding longitudes of a polygon.
%   OPTIONAL: data var strings, with matching depth ranges if appropriate:
%     vars -  strings:     'cr'=cruise_no  'co'=country_code  'dp'='num_depths'
%        'cp'=csiro_profile_no   'cf'=csiro_flag
%        'o'=o2   'n'=no3   'p'=po4   'i'=si  't'=temp  's'=sal 'g'=neut_dens
%        'os'=o2-screened (values set to NaN if data flags!=0) ... and so on
%        'fo'=o2_flag  ... and so on for n,p,i,t,s,g
%         NOTE; at this stage, don't use vars which imply different file
%               prefices. EG t,ft,s,cp are ok together, but not t,o
%     deps - standard depth level pairs where required, eg [1 33] or [1 1]
%            Not required where it doesn't apply, such as with profile_no.
% 
% Eg: ('_bot',-1,[-10 10],[135 142],'t',[1 33],'ft',[1 33], 'cp', 'ss',[1 10])
%
% OUTPUT: lat - vector(m) of signed latitudes (-ve South) for the
%              m data points.
%         lon - vector(m) of signed longitudes (-180 to +360)
%         time - decimal days since 1900-01-01 00:00:00
%         var1 - the first specified group of cast data
%         var2 -    ... etc
%         var3 -    ... etc
%
% USAGE:   [lat,lon,time,var1,var2,var3,var4,var5] =
%        getNODC_var( file_sufs, scrlev, latrng, lonrng, {var,deps}, {var})

% FUNCTIONS called (non-library):  getNODC_arg  getNODC_onev  cast_locj
%
% Copyright (C) J R Dunn, CSIRO, 
% $Revision: 1.7 $    Last revision $Date: 1997/11/21 02:52:53 $
%
% NOTE: A non-standard path to files can be specified by setting global
%       variable DATA_DIR


% Globals:
%  varpr - prefix of netcdf_files (deduced from arguments by getNODC_arg)
%  varnm - names of variables in netcdf file
%  deps -  array of [d1 d2] specifying (upper and lower) range of standard 
%          depths to get
%  getd -  tracks whether or not next argument should specify depth range of
%          previous argument
%  scr  -  should this variable be screened
%  nvar -  number of variables to be extracted.

global getN_varpr; global getN_varnm; global getN_deps; global getN_getd;
global getN_scr; global getN_nvar;
global DATA_DIR;

if nargin==0
  disp('[lat,lon,time,var1,var2,var3,var4,var5] = ...');
  disp('   getNODC_var( file_sufs, scrlev, latrng, lonrng, {var,deps}, {var})');
  return
end

if length(DATA_DIR)==0
  DATA_DIR = '/home/eez_data/woa94/';
  % disp(['Global DATA_DIR is empty. Using: ' DATA_DIR]);
end

var1 = []; var2 = []; var3 = []; var4 = []; var5 = [];

% Set the level of csiro_flag screening
if scrlev<1
  cfmax = 0;
elseif scrlev==1
  cfmax = 9;
else
  cfmax = 1000;
end

if length(latrng)==2
  simplebox = 1;
else
  simplebox = 0;
end

% Construct a grid covering whole area of interest, one point at the centre
% of every wmo square. Initially move edges inwards so that do not get 
% neighbouring squares when edge of specified region is on a wmo boundary.
% This algorithm may be very inefficient where a quadrilateral is specified,
% but I can live with that.

wmosq = [];

ylim = [min(latrng)+.001  max(latrng)-.001];
xlim = [min(lonrng)+.001  max(lonrng)-.001];
ylim = (ceil(ylim/10)*10)-5;
xlim = (ceil(xlim/10)*10)-5;
latgrd = ylim(1):10:ylim(2);
longrd = xlim(1):10:xlim(2);
for ii = latgrd
  for jj = longrd
    wmosq =  [wmosq wmo(jj,ii)];
  end
end


% Decode input arguments - if there is a better way to do, please tell me!

getN_varpr = []; getN_varnm = []; getN_deps = []; getN_getd = 0; 
getN_scr = zeros(size(1:9)); getN_nvar = 0;

if nargin>=5;  getNODC_arg(a5);  end
if nargin>=6;  getNODC_arg(a6);  end
if nargin>=7;  getNODC_arg(a7);  end
if nargin>=8;  getNODC_arg(a8);  end
if nargin>=9;  getNODC_arg(a9);  end
if nargin>=10; getNODC_arg(a10);  end
if nargin>=11; getNODC_arg(a11); end
if nargin>=12; getNODC_arg(a12); end
if nargin==13; getNODC_arg(a13); end


if isempty(getN_varpr); getN_varpr = 'ts'; end      % A default value
% Trim leading blank string from getN_varnm matrix.
if getN_nvar>0
  getN_varnm = getN_varnm(2:getN_nvar+1,:);
end

file_prefix = [DATA_DIR getN_varpr '_ocl_'];

% Build matrix of filenames

files = [];
[nfilesufs tmp] = size(file_sufs);
for j=1:nfilesufs
  file_suffix = deblank(file_sufs(j,:));
  for i=1:length(wmosq)
    tmpstr = [file_prefix num2str(wmosq(i)) file_suffix];
    % check that the file exists
    if exist([tmpstr '.nc'])
      files = str2mat(files,tmpstr);
    end
  end
end

% the first row is always blank because of the way str2mat works
% so this has to be trimmed from file list
[nfiles m] = size(files);
files = files(2:nfiles,:);
[nfiles m] = size(files);


lat = [];
lon = [];
time = [];
var = [];


for i=1:nfiles
  nfile = deblank(files(i,:));
  tmp_str = strrep(nfile,DATA_DIR,'');
  
  Lat = getcdf(nfile,'lat');
  nc = length(Lat);
  Lon = getcdf(nfile,'lon');
  
  % Make sure lon is reported as 0->360
  west_of_zero = find(Lon<0);
  Lon(west_of_zero) = Lon(west_of_zero) + 360;

  Time = getcdf(nfile,'time');
  Csiro_flag = getcdf(nfile,'csiro_flag');
  
  rej1 = find(Csiro_flag>cfmax);
  if simplebox
    rej2 = find(Lat<latrng(1) | Lat>latrng(2) | Lon<lonrng(1) | Lon>lonrng(2));
  else
    rej2 = isinpoly(Lon,Lat,lonrng,latrng);
    rej2 = find(~rej2);
  end
  reject = [rej1; rej2];
  if ~isempty(reject)
    Lat(reject) = [];
    Lon(reject) = [];
    Time(reject) = [];
  end

  lat = [lat; Lat];
  lon = [lon; Lon];
  time = [time; Time];
  
  Depth = getcdf(nfile,'depth');
  nd = length(Depth);
  if getN_nvar>=1; 
    [var1] = getNODC_onev(nfile,1,var1,reject,nd,nc);
  end
  if getN_nvar>=2; 
    [var2] = getNODC_onev(nfile,2,var2,reject,nd,nc);
  end
  if getN_nvar>=3; 
    [var3] = getNODC_onev(nfile,3,var3,reject,nd,nc);
  end
  if getN_nvar>=4; 
    [var4] = getNODC_onev(nfile,4,var4,reject,nd,nc);
  end
  if getN_nvar==5; 
    [var5] = getNODC_onev(nfile,5,var5,reject,nd,nc);
  end

  if scrlev<0 & ~isempty(var1)
    [m,n] = size(var1);
    if n==1
      rej3 = find(isnan(var1));
    else
      rej3 = find(all(isnan(var1')));
    end
    if ~isempty(rej3)
      lat(rej3) = [];
      lon(rej3) = [];
      time(rej3) = [];
      var1(rej3,:) = [];
      if getN_nvar>=2; var2(rej3,:) = []; end
      if getN_nvar>=3; var3(rej3,:) = []; end
      if getN_nvar>=4; var4(rej3,:) = []; end
      if getN_nvar>=5; var5(rej3,:) = []; end
    end
  end
end  

% ___ End of getNODC_var __________________
