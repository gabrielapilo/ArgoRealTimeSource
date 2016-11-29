% getNODC2:  Extract lat-lons, times and cast data from netcdf files.
% INPUT: 
%   file_sufs - column of one or more of these file suffix strings:
%               '_bot' '_bot2' '_xbt' '_xbt2' '_mbt' '_mbt2' '_ctd' '_ctd2'
%               '_isd'  [If more than one string, use str2mat to create.]
%   scrlev - -1: as for 0, and also reject where all of selected cast isnan
%                in variable 1.
%            0: reject on basis of NODC and local csiro screening
%            1: reject only on basis local csiro screening
%            2: reject nothing
%   range    either [w e s n]
%            or     [x1 y1; x2 y2; x3 y3; ... xn yn]
%   OPTIONAL: data var strings, with matching depth ranges if appropriate:
%     vars -  strings:     'cr'=cruise_no  'co'=country_code  'dp'='num_depths'
%        'cp'=csiro_profile_no   'cf'=csiro_flag
%        'o'=o2   'n'=no3   'p'=po4   'i'=si  't'=temp  's'=sal 'g'=neut_dens
%        'os'=o2-screened (values set to NaN if data flags!=0) ... and so on
%        'fo'=o2_flag  ... and so on for n,p,i,t,s,g
%         NOTE: at this stage, don't use vars which imply different file
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
%
% USAGE:   [lat,lon,time,var1,var2,var3,var4,var5] =
%        getNODC( file_sufs, scrlev, range, {var,deps}, {var})
 
function [lat,lon,time,var1,var2,var3,var4,var5] ...
    = getNODC2(file_sufs,scrlev,range,a5,a6,a7,a8,a9,a10,a11,a12,a13)

% FUNCTIONS called (non-library):  getNODC_arg
%     Subfunctions in this file:  getNODCone  get_and_scr
%
% Copyright (C) J R Dunn, CSIRO, 
% $Revision: 1.1 $    Last revision $Date: 1997/11/23 22:04:36 $
%
%   {Derived from getNODC_var v1.7, but much faster because uses direct 
%   ncvarget rather than via getcdf or getnc.}
%
% Matlab 5 ONLY - because of subfunction use.
% FUTURE WORK:  use Maltab5 variable argument-list system?
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

ncmex('setopts',0);

if nargin==0
  disp('[lat,lon,time,var1,var2,var3,var4,var5] = ...');
  disp('   getNODC( file_sufs, scrlev, range, {var,deps}, {var})');
  return
end

vers = version;
if strcmp(vers(1),'4')
  error('Sorry, getNODC needs Matlab 5. Use getNODC_var with Matlab 4.')
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

% If range specified as [w e n s] limits, expand to a polygon specification
% so only have to handle that type of spec when selecting casts.
wmosq = getwmo(range);

if size(range) == [1 4]
   range = [range([1 2 2 1])' range([3 3 4 4])'];
end 

% Decode input arguments - if there is a better way to do, please tell me!

getN_varpr = []; getN_varnm = []; getN_deps = []; getN_getd = 0; 
getN_scr = zeros(size(1:9)); getN_nvar = 0;

if nargin>=4;  getNODC_arg(a5);  end
if nargin>=5;  getNODC_arg(a6);  end
if nargin>=6;  getNODC_arg(a7);  end
if nargin>=7;  getNODC_arg(a8);  end
if nargin>=8;  getNODC_arg(a9);  end
if nargin>=9; getNODC_arg(a10);  end
if nargin>=10; getNODC_arg(a11); end
if nargin>=11; getNODC_arg(a12); end
if nargin==12; getNODC_arg(a13); end


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
    files = str2mat(files,tmpstr);
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
  
  [cdfid,rcode] = mexcdf('ncopen',[nfile '.nc'],'nowrite');
  if cdfid<0 | rcode<0
    % Files doesn't exist or can't be opened
  else
    [tmp,nc] = mexcdf('ncdiminq',cdfid,'cast_number');
    [tmp,nd] = mexcdf('ncdiminq',cdfid,'depth');

    Lat = mexcdf('ncvarget',cdfid,'lat',0,nc);
    Lon = mexcdf('ncvarget',cdfid,'lon',0,nc);
    
    % Make sure lon is reported as 0->360
    west_of_zero = find(Lon<0);
    Lon(west_of_zero) = Lon(west_of_zero) + 360;
    
    Time = mexcdf('ncvarget',cdfid,'time',0,nc);
    Csiro_flag = mexcdf('ncvarget',cdfid,'csiro_flag',0,nc);
  
    rej1 = find(Csiro_flag>cfmax);
    rej2 = isinpoly(Lon,Lat,range(:,1),range(:,2));
    rej2 = find(~rej2);

    reject = [rej1; rej2];
    if ~isempty(reject)
      Lat(reject) = [];
      Lon(reject) = [];
      Time(reject) = [];
    end

    lat = [lat; Lat];
    lon = [lon; Lon];
    time = [time; Time];
  
    Depth = get_and_scr(cdfid,'depth',0,nd);
    if getN_nvar>=1; 
      [var1] = getNODCone(cdfid,1,var1,reject,nd,nc);
    end
    if getN_nvar>=2; 
      [var2] = getNODCone(cdfid,2,var2,reject,nd,nc);
    end
    if getN_nvar>=3; 
      [var3] = getNODCone(cdfid,3,var3,reject,nd,nc);
    end
    if getN_nvar>=4; 
      [var4] = getNODCone(cdfid,4,var4,reject,nd,nc);
    end
    if getN_nvar==5; 
      [var5] = getNODCone(cdfid,5,var5,reject,nd,nc);
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

  end      % Of a file that could be opened
  
  mexcdf('ncclose',cdfid);
end  


%---- subfunction get_and_scr ---------------------------

function var = get_and_scr(cdfid,var,start,counts)

var = mexcdf('ncvarget',cdfid,var,start,counts);
inval = find( var < -9 );
if ~isempty(inval)
  var(inval) = NaN*ones(size(inval));
end



% --- subfunction -----------------------------------------------

function var = getNODCone(cdfid,nv,var,reject,nd,nc);

%  Used by getNODC to read one variable, and append it to the data 
%  collected so far.
%
% INPUTS:
%  cdfid - id of input file
%  nv   - index of this one variable (in the global arrays). 
%  var  - data already accumulated
%  reject - list of indices of casts to be rejected
%  nd   - number of depths in this file
%  nc   -   "    "  casts  "       "
%
%  Copyright (C) J R Dunn, CSIRO, 

% Globals:
%  varnm - names of variables in netcdf file
%  deps -  [d1 d2] specifying (upper and lower) range of depths to get
%  scr  -  if 1, screening by dataflag is required.

global getN_varnm; global getN_deps; global getN_scr;


vntmp = deblank(getN_varnm(nv,:));

if getN_deps(nv,:)==[0 0]
  % This should only be used to extract 1-D variables
  VAR = get_and_scr(cdfid,vntmp,0,nc);
elseif getN_deps(nv,1) <= nd
  % varget crashes if ask for more depths than are in the file - so work out
  % max depth to ask for:
  maxdep = min([nd getN_deps(nv,2)]);
  ndeps = 1+maxdep-getN_deps(nv,1);
  VAR = get_and_scr(cdfid,vntmp,[0 getN_deps(nv,1)-1],[nc ndeps]);

  % We want each row to correspond to a cast, so transpose. However, if only
  % extract one depth, it already comes out as a column-cast vector, so
  % don't change.
  if (maxdep>getN_deps(nv,1));  VAR = VAR'; end

  % If required, screen using individual data flags.
  if getN_scr(nv)
    vntmp = [vntmp '_flag'];
    flags = get_and_scr(cdfid,vntmp,[0 getN_deps(nv,1)-1],[nc ndeps]);
    if ndeps > 1 ;  flags = flags'; end
    
    rejs = find(rem(flags,10)~=0);
    VAR(rejs) = NaN*ones(size(rejs));
  end
else
  % Case where the specified depth levels are not present in the file,
  % so make up a dummy VAR.
  VAR = NaN*ones(nc,1);
end


VAR(reject,:) = [];


% If necessary, pack the data to the required number of depths.

[m n] = size(VAR);
ndeps = 1+getN_deps(nv,2)-getN_deps(nv,1);
if n < ndeps
  VAR = [VAR NaN*ones(m,ndeps-n)];
end

var = [var; VAR];


% ___ End of getNODC __________________
