% TRAJECTORY_NC  Create and load a netCDF Argo trajectory file
%
% INPUT: dbdat - master database record for this float
%        fpp   - struct array containing the profiles for this float
%        [traj]  - struct array containing trajectory info   
%        [traj_mc_order]  - vector of MC codes in the right order for this float type
%
% changed to read traj metadata file if traj and traj_mc_order are not
% specified.  These are now optional. 
%
% Author:  Jeff Dunn CSIRO/BoM  Aug 2006, Oct 2012
%
% MODS:  Complete rework for V3.0 format, 2013 JRD
%
% CALLS:  netCDF toolbox functions, julian
%
% USAGE: trajectory_nc(dbdat,fpp,traj,traj_mc_order)

function trajectory_nc(dbdat,fpp,traj,traj_mc_order)

global ARGO_SYS_PARAM

if nargin<3
    if ispc
        tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles\T' num2str(dbdat.wmo_id)];
    else
        tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(dbdat.wmo_id)];
    end
    load(tfnm,'traj','traj_mc_order');
end

np = min([length(fpp) length(traj)]);

% Count cycles for which we have data (ie ignore missing cycles)
gotcyc = zeros(1,np);
for ii = 1:np
   gotcyc(ii) = ~isempty(fpp(ii).jday) && isfield(traj(ii),'TST') && ...
       isfield(traj(ii).TST,'juld') && ~isempty(traj(ii).TST.juld);
end
gotcyc = find(gotcyc);
if isempty(gotcyc)
   logerr(2,['TRAJECTORY_NC:  No usable cycles, so no file made (WMO '...
	     num2str(dbdat.wmo_id) ')']);
   return
end

today_str = sprintf('%04d%02d%02d%02d%02d%02d',fix(clock));


% Only P, T, S and conductivity are stored in Core-Argo traj files - all
% other parameters are in the B-files. 
% Parameters defined in User Manual Ref table 3
pars = {'PRES','TEMP','PSAL'}; 
% if ~isfield(fpp,'p_park_av') && ~isfield(fpp,'park_p')    %palace floats
% without park averages - fill with empty data!
%    % What about surface measurements??
%    params = [];
% else
   params = [1 2];
   if isfield(fpp,'park_s') || isfield(fpp,'s_park_av') 
      params = [params 3];
   end
% end

% ## LOTS MORE TO FILL IN HERE :
%
% ## also THIS IS WHERE WE NEED TO SEPARATE B-Argo STUFF

lngnm{1} = 'Sea water pressure, equals 0 at sea-level';
lngnm{2} = 'Sea temperature in-situ ITS-90 scale';
lngnm{3} = 'Practical salinity';

stdnm{1} = 'sea_water_pressure';
stdnm{2} = 'sea_water_temperature';
stdnm{3} = 'sea_water_salinity';

units{1} = 'decibar';
units{2} = 'degree_Celsius';
units{3} = 'psu';

vmn = [0,   -2.5,  2.];
vmx = [12000, 40, 41.];
cmnt{1} = 'In situ measurement, sea surface = 0';
cmnt{2} = 'In situ measurement';
cmnt{3} = 'In situ measurement';

cfmt = {'%7.1f','%9.3f','%9.3f'};
ffmt = {'F7.1','F9.3','F9.3'};
resltn = [0,1, .001, .001];

parknm = {'park_p','park_t','park_s'};
pkavnm = {'p_park_av','t_park_av','s_park_av'};
surfnm = {'surf_Oxy_pressure','surf_t','surf_s'};

if ispc
fname = [ARGO_SYS_PARAM.root_dir 'netcdf\' num2str(dbdat.wmo_id) '\' num2str(dbdat.wmo_id) '_Rtraj.nc'];
dirn = [ARGO_SYS_PARAM.root_dir 'netcdf\' num2str(dbdat.wmo_id) ];
else
fname = [ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) '/' num2str(dbdat.wmo_id) '_Rtraj.nc'];
dirn = [ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) ];
end


if ~exist(dirn,'dir')
    system(['mkdir ' dirn]);
end

hist=[];
dc=[];
if exist(fname,'file')
   try
       ncid=netcdf.open(fnm,'NOWRITE');
       
       hist=netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history');
       dcvarid=netcdf.inqVarID(ncid,'DATE_CREATION');
       dc=netcdf.getVar(ncid,dcvarid);
       
       netcdf.close(ncid)
%     hist=attnc(fname,'global','history');
%     dc=getnc(fname,'DATE_CREATION');
   end
else
end
     ncid=netcdf.create(fname,'CLOBBER');

if isempty(dc)  | all(double(dc)==0) | all(double(dc)==32)
    if ispc
        today_str=datestr(now,30);
        today_str(9)=[];
    else
        [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
        today_str=today_str(1:14);
   end
    dc=today_str;
end

if ispc
    dn=datestr(now,31);  % or use dn=datestr(datenum(now-(8/24),31)) (adjust for utc time difference)
else
    [st,dn]=system(['date -u +%Y-%m-%d-%H:%M:%S']);
end

% dn=datestr(now,31);
dn(11:11)='T';
if isempty(hist)
    dn(20:29)='Z creation';
else
    hist(end+1)=';';
    dn(20:27)='Z update';
end
dnt=[hist dn];

netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'title','Argo float trajectory file' );
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'institution',ARGO_SYS_PARAM.inst);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'source','Argo float');


netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history',dnt);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'references','http://www.argodatamgt.org/Documentation');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'user_manual_version','3.1');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'Conventions','Argo-3.1 CF-1.6');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'featureType','trajectory');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'comment_on_resolution','PRES variable resolution depends on measurement codes');


% Number of collected float cycles
N_CYCLEID=netcdf.defDim(ncid,'N_CYCLE',length(gotcyc));

STR2=netcdf.defDim(ncid,'STRING2',2);
STR4=netcdf.defDim(ncid,'STRING4',4);
STR8=netcdf.defDim(ncid,'STRING8',8);
STR16=netcdf.defDim(ncid,'STRING16',16);
STR32=netcdf.defDim(ncid,'STRING32',32);
STR64=netcdf.defDim(ncid,'STRING64',64);
% STR256=netcdf.defDim(ncid,'STRING256',256);
DaTi =netcdf.defDim(ncid,'DATE_TIME',14);

% "When no parameter is measured along the trajectory, N_PARAM and any
% field with a N_PARAM dimension are removed from the file..."    2.3.4 
if ~isempty(params)
    N_PARID=netcdf.defDim(ncid,'N_PARAM',length(params));
end

N_HISID=netcdf.defDim(ncid,'N_HISTORY',1);

% Unlimited dimension...
N_MEASID=netcdf.defDim(ncid,'N_MEASUREMENT',netcdf.getConstant('NC_UNLIMITED'));

% Define the fields common to several filetypes
% generic_fields_nc(nc,dbdat,3,1);

NDACRID=netcdf.defVar(ncid,'DATE_CREATION','NC_CHAR',DaTi);
netcdf.putAtt(ncid,NDACRID,'long_name','Date of file creation');
netcdf.putAtt(ncid,NDACRID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NDACRID,'_FillValue',' ');

NDAUPID=netcdf.defVar(ncid,'DATE_UPDATE','NC_CHAR',DaTi);
netcdf.putAtt(ncid,NDAUPID,'long_name','Date of update of this file');
netcdf.putAtt(ncid,NDAUPID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NDAUPID,'_FillValue',' ');

NPLANUID=netcdf.defVar(ncid,'PLATFORM_NUMBER','NC_CHAR',STR8);
netcdf.putAtt(ncid,NPLANUID,'long_name','Float unique identifier');
netcdf.putAtt(ncid,NPLANUID,'conventions','WMO float identifier : A9IIIII');
netcdf.putAtt(ncid,NPLANUID,'_FillValue',' ');

NDACENID=netcdf.defVar(ncid,'DATA_CENTRE','NC_CHAR',STR2);
netcdf.putAtt(ncid,NDACENID,'long_name','Data centre in charge of float data processing');
netcdf.putAtt(ncid,NDACENID,'conventions','Argo reference table 4');
netcdf.putAtt(ncid,NDACENID,'_FillValue',' ');   

% The commmittee proved their worth that day! And if a letter of a long_name
% is not as decreed then the file is rejected - thus preventing global anarchy!

WMOINSTID=netcdf.defVar(ncid,'WMO_INST_TYPE','NC_CHAR',STR4);
netcdf.putAtt(ncid,WMOINSTID,'long_name','Coded instrument type');
netcdf.putAtt(ncid,WMOINSTID,'conventions','Argo reference table 8');
netcdf.putAtt(ncid,WMOINSTID,'_FillValue',' ');

NPRONAID=netcdf.defVar(ncid,'PROJECT_NAME','NC_CHAR',STR64);
% netcdf.putAtt(ncid,NPRONAID,'long_name','Program under which the float was deployed');
netcdf.putAtt(ncid,NPRONAID,'long_name','Name of the project');
netcdf.putAtt(ncid,NPRONAID,'_FillValue',' ');
       
NPINAID=netcdf.defVar(ncid,'PI_NAME','NC_CHAR',STR64);
netcdf.putAtt(ncid,NPINAID,'long_name','Name of the principal investigator');
netcdf.putAtt(ncid,NPINAID,'_FillValue',' ');
     
NDATYID=netcdf.defVar(ncid,'DATA_TYPE','NC_CHAR',STR16);
netcdf.putAtt(ncid,NDATYID,'long_name','Data type');
netcdf.putAtt(ncid,NDATYID,'conventions','Argo reference table 1');
netcdf.putAtt(ncid,NDATYID,'_FillValue',' ');

NFMVRID=netcdf.defVar(ncid,'FORMAT_VERSION','NC_CHAR',STR4);
netcdf.putAtt(ncid,NFMVRID,'long_name','File format version');
netcdf.putAtt(ncid,NFMVRID,'_FillValue',' ');

NHDVRID=netcdf.defVar(ncid,'HANDBOOK_VERSION','NC_CHAR',STR4);
netcdf.putAtt(ncid,NHDVRID,'long_name','Data handbook version');
netcdf.putAtt(ncid,NHDVRID,'_FillValue',' ');

NREDTID=netcdf.defVar(ncid,'REFERENCE_DATE_TIME','NC_CHAR',DaTi);
netcdf.putAtt(ncid,NREDTID,'long_name','Date of reference for Julian days');
netcdf.putAtt(ncid,NREDTID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NREDTID,'_FillValue',' ');

NPOSSYSID=netcdf.defVar(ncid,'POSITIONING_SYSTEM','NC_CHAR',STR8);
netcdf.putAtt(ncid,NPOSSYSID,'long_name','Positioning system');
netcdf.putAtt(ncid,NPOSSYSID,'_FillValue',' ');

if ~isempty(params)
NTRAJPARAID=netcdf.defVar(ncid,'TRAJECTORY_PARAMETERS','NC_CHAR',[STR16,N_PARID]);
netcdf.putAtt(ncid,NTRAJPARAID,'long_name','List of available parameters for the station');
netcdf.putAtt(ncid,NTRAJPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NTRAJPARAID,'_FillValue',' ');   
end

NDASTAINDID=netcdf.defVar(ncid,'DATA_STATE_INDICATOR','NC_CHAR',STR4);
netcdf.putAtt(ncid,NDASTAINDID,'long_name','Degree of processing the data have passed through');
netcdf.putAtt(ncid,NDASTAINDID,'conventions','Argo reference table 6');
netcdf.putAtt(ncid,NDASTAINDID,'_FillValue',' ');

NPLATYID=netcdf.defVar(ncid,'PLATFORM_TYPE','NC_CHAR',STR32);
netcdf.putAtt(ncid,NPLATYID,'long_name','Type of float');
netcdf.putAtt(ncid,NPLATYID,'conventions','Argo reference table 23');
netcdf.putAtt(ncid,NPLATYID,'_FillValue',' ');

NFLSERNOID=netcdf.defVar(ncid,'FLOAT_SERIAL_NO','NC_CHAR',STR32);
netcdf.putAtt(ncid,NFLSERNOID,'long_name','Serial number of the float');
netcdf.putAtt(ncid,NFLSERNOID,'_FillValue',' ');

NFIRVERID=netcdf.defVar(ncid,'FIRMWARE_VERSION','NC_CHAR',STR32);
netcdf.putAtt(ncid,NFIRVERID,'long_name','Instrument firmware version');
netcdf.putAtt(ncid,NFIRVERID,'_FillValue',' ');

NJULDID=netcdf.defVar(ncid,'JULD','NC_DOUBLE',N_MEASID);
netcdf.putAtt(ncid,NJULDID,'standard_name','time');
netcdf.putAtt(ncid,NJULDID,'long_name','Julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
netcdf.putAtt(ncid,NJULDID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDID,'resolution',double(0.01));  % 1 second resolution
netcdf.putAtt(ncid,NJULDID,'_FillValue',double(999999));
netcdf.putAtt(ncid,NJULDID,'axis','T');

NJULDSTID=netcdf.defVar(ncid,'JULD_STATUS','NC_CHAR',N_MEASID);
netcdf.putAtt(ncid,NJULDSTID,'long_name','Status of the date and time');
netcdf.putAtt(ncid,NJULDSTID,'conventions','Argo reference table 19');
netcdf.putAtt(ncid,NJULDSTID,'_FillValue',' ');

NJULDQCID=netcdf.defVar(ncid,'JULD_QC','NC_CHAR',N_MEASID);
netcdf.putAtt(ncid,NJULDQCID,'long_name','Quality on date and time');
netcdf.putAtt(ncid,NJULDQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NJULDQCID,'_FillValue',' ');

NJULDADID=netcdf.defVar(ncid,'JULD_ADJUSTED','NC_DOUBLE',N_MEASID);
netcdf.putAtt(ncid,NJULDADID,'long_name','Adjusted julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
netcdf.putAtt(ncid,NJULDADID,'standard_name','time');
netcdf.putAtt(ncid,NJULDADID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDADID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDADID,'resolution',double(0.01));  % 1 second resolution
netcdf.putAtt(ncid,NJULDADID,'_FillValue',double(999999));
netcdf.putAtt(ncid,NJULDADID,'axis','T');

NJULDADSTID=netcdf.defVar(ncid,'JULD_ADJUSTED_STATUS','NC_CHAR',N_MEASID);
netcdf.putAtt(ncid,NJULDADSTID,'long_name','Status of the JULD_ADJUSTED date');
netcdf.putAtt(ncid,NJULDADSTID,'conventions','Argo reference table 19');
netcdf.putAtt(ncid,NJULDADSTID,'_FillValue',' ');

NJULDADQCID=netcdf.defVar(ncid,'JULD_ADJUSTED_QC','NC_CHAR',N_MEASID);
netcdf.putAtt(ncid,NJULDADQCID,'long_name','Quality on adjusted date and time');
netcdf.putAtt(ncid,NJULDADQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NJULDADQCID,'_FillValue',' ');

NLATID=netcdf.defVar(ncid,'LATITUDE','NC_DOUBLE',N_MEASID);
netcdf.putAtt(ncid,NLATID,'long_name','Latitude of each location');
netcdf.putAtt(ncid,NLATID,'standard_name','latitude');
netcdf.putAtt(ncid,NLATID,'units','degree_north');
netcdf.putAtt(ncid,NLATID,'valid_min',double(-90.));
netcdf.putAtt(ncid,NLATID,'valid_max',double(90.));
netcdf.putAtt(ncid,NLATID,'axis','Y');
netcdf.putAtt(ncid,NLATID,'_FillValue',double(99999.));

NLONGID=netcdf.defVar(ncid,'LONGITUDE','NC_DOUBLE',N_MEASID);
netcdf.putAtt(ncid,NLONGID,'long_name','Longitude of each location');
netcdf.putAtt(ncid,NLONGID,'standard_name','longitude');
netcdf.putAtt(ncid,NLONGID,'units','degree_east');
netcdf.putAtt(ncid,NLONGID,'valid_min',double(-180.));
netcdf.putAtt(ncid,NLONGID,'valid_max',double(180.));
netcdf.putAtt(ncid,NLONGID,'axis','X');
netcdf.putAtt(ncid,NLONGID,'_FillValue',double(99999.));

NPOSACCID=netcdf.defVar(ncid,'POSITION_ACCURACY','NC_CHAR',N_MEASID);
netcdf.putAtt(ncid,NPOSACCID,'long_name','Estimated accuracy in latitude and longitude');
netcdf.putAtt(ncid,NPOSACCID,'conventions','Argo reference table 5');
netcdf.putAtt(ncid,NPOSACCID,'_FillValue',' ');

NPOSQCID=netcdf.defVar(ncid,'POSITION_QC','NC_CHAR',N_MEASID);
netcdf.putAtt(ncid,NPOSQCID,'long_name','Quality on position');
netcdf.putAtt(ncid,NPOSQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NPOSQCID,'_FillValue',' ');

NCYCNUMID=netcdf.defVar(ncid,'CYCLE_NUMBER','NC_INT',N_MEASID);
netcdf.putAtt(ncid,NCYCNUMID,'long_name','Float cycle number of the measurement');
netcdf.putAtt(ncid,NCYCNUMID,'_FillValue',int32(99999));
netcdf.putAtt(ncid,NCYCNUMID,'conventions','0...N, 0 : launch cycle, 1 : first complete cycle'); 

NCYCNUMADID=netcdf.defVar(ncid,'CYCLE_NUMBER_ADJUSTED','NC_INT',N_MEASID);
netcdf.putAtt(ncid,NCYCNUMADID,'long_name','Adjusted float cycle number of the measurement');
netcdf.putAtt(ncid,NCYCNUMADID,'_FillValue',int32(99999));
netcdf.putAtt(ncid,NCYCNUMADID,'conventions','0...N, 0 : launch cycle, 1 : first complete cycle'); 

NMEASCOID=netcdf.defVar(ncid,'MEASUREMENT_CODE','NC_INT',N_MEASID);
netcdf.putAtt(ncid,NMEASCOID,'long_name','Flag referring to a measurement event in the cycle');
netcdf.putAtt(ncid,NMEASCOID,'_FillValue',int32(99999));
netcdf.putAtt(ncid,NMEASCOID,'conventions','Argo reference table 15'); 

for ipar = params
    parnm = pars{ipar};
    cmmd=['N' parnm 'ID= netcdf.defVar(ncid,''' parnm ''',''NC_FLOAT'',N_MEASID);'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''long_name'',lngnm{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''standard_name'',stdnm{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''_FillValue'',single(99999.));'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''units'',units{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''valid_min'',single(vmn(ipar)));'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''valid_max'',single(vmx(ipar)));'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''C_format'',cfmt{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''FORTRAN_format'',ffmt{ipar});'];
    eval(cmmd);
    
    if ipar==1
        cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''axis'',''Z'');'];
        eval(cmmd);
    end
    
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ID,''resolution'',single(resltn(ipar)));'];
    eval(cmmd);
    cmmd=['N' parnm 'QCID = netcdf.defVar(ncid,''' parnm '_QC'',''NC_CHAR'',N_MEASID);'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'QCID,''long_name'',''quality flag'');'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'QCID,''conventions'',''Argo reference table 2'');'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'QCID,''_FillValue'','' '');'];
    eval(cmmd);
    
    cmmd=['N' parnm 'ADID = netcdf.defVar(ncid,''' parnm '_ADJUSTED'',''NC_FLOAT'',N_MEASID);'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''long_name'',lngnm{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''standard_name'',stdnm{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''_FillValue'',single(99999.));'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''units'',units{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''valid_min'',single(vmn(ipar)));'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''valid_max'',single(vmx(ipar)));'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''comment'',cmnt{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''C_format'',cfmt{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''FORTRAN_format'',ffmt{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''resolution'',single(resltn(ipar)));'];
    eval(cmmd);
    
    cmmd=['N' parnm 'ADQCID = netcdf.defVar(ncid,''' parnm '_ADJUSTED_QC'',''NC_CHAR'',N_MEASID);'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADQCID,''long_name'',''quality flag'');'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADQCID,''conventions'',''Argo reference table 2'');'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADQCID,''_FillValue'','' '');'];
    eval(cmmd);
    
    cmmd=['N' parnm 'ADERRID = netcdf.defVar(ncid,''' parnm '_ADJUSTED_ERROR'',''NC_FLOAT'',N_MEASID);'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADERRID,''long_name'',[''Contains the error on the adjusted values as determined by the delayed mode QC process'']);'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADERRID,''_FillValue'',single(99999.));'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADERRID,''units'',units{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADERRID,''C_format'',cfmt{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADERRID,''FORTRAN_format'',ffmt{ipar});'];
    eval(cmmd);
    cmmd=['netcdf.putAtt(ncid,N' parnm 'ADERRID,''resolution'',single(resltn(ipar)));'];
    eval(cmmd);
end

NAXESERRELLMAJID=netcdf.defVar(ncid,'AXES_ERROR_ELLIPSE_MAJOR','NC_FLOAT',N_MEASID);
netcdf.putAtt(ncid,NAXESERRELLMAJID,'long_name','Major axis of error ellipse from positioning system');
netcdf.putAtt(ncid,NAXESERRELLMAJID,'_FillValue',single(99999.));
netcdf.putAtt(ncid,NAXESERRELLMAJID,'units','meters');

NAXESERRELLMINID=netcdf.defVar(ncid,'AXES_ERROR_ELLIPSE_MINOR','NC_FLOAT',N_MEASID);
netcdf.putAtt(ncid,NAXESERRELLMINID,'long_name','Minor axis of error ellipse from positioning system');
netcdf.putAtt(ncid,NAXESERRELLMINID,'_FillValue',single(99999.));
netcdf.putAtt(ncid,NAXESERRELLMINID,'units','meters');

NAXESERRELLANGID=netcdf.defVar(ncid,'AXES_ERROR_ELLIPSE_ANGLE','NC_FLOAT',N_MEASID);
netcdf.putAtt(ncid,NAXESERRELLANGID,'long_name','Angle of error ellipse from positioning system');
netcdf.putAtt(ncid,NAXESERRELLANGID,'_FillValue',single(99999.));
netcdf.putAtt(ncid,NAXESERRELLANGID,'units','Degrees (from North when heading East)');

NSATENAID=netcdf.defVar(ncid,'SATELLITE_NAME','NC_CHAR',N_MEASID);
netcdf.putAtt(ncid,NSATENAID,'long_name','Satellite name from positioning system');
netcdf.putAtt(ncid,NSATENAID,'_FillValue',' ');

% -------- N_CYCLE vars

NJULDASSTAID=netcdf.defVar(ncid,'JULD_ASCENT_START','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDASSTAID,'long_name','Start date of the ascent to the surface');
netcdf.putAtt(ncid,NJULDASSTAID,'standard_name','time');
netcdf.putAtt(ncid,NJULDASSTAID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDASSTAID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDASSTAID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDASSTAID,'_FillValue',double(999999.));

NJULDASSTASTID=netcdf.defVar(ncid,'JULD_ASCENT_START_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDASSTASTID,'long_name','Status of start date of the ascent to the surface');
netcdf.putAtt(ncid,NJULDASSTASTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDASSTASTID,'conventions','Argo reference table 19');
% 

% % GDAC says we need a long_name but present manuals do not specifiy it 

NJULDASENDID=netcdf.defVar(ncid,'JULD_ASCENT_END','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDASENDID,'long_name','End date of ascent to the surface');
netcdf.putAtt(ncid,NJULDASENDID,'standard_name','time');
netcdf.putAtt(ncid,NJULDASENDID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDASENDID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDASENDID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDASENDID,'_FillValue',double(999999.));

NJULDASENDSTID=netcdf.defVar(ncid,'JULD_ASCENT_END_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDASENDSTID,'long_name','Status of end date of ascent to the surface');
netcdf.putAtt(ncid,NJULDASENDSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDASENDSTID,'conventions','Argo reference table 19');

NJULDDESTAID=netcdf.defVar(ncid,'JULD_DESCENT_START','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDESTAID,'long_name','Descent start date of the cycle');
netcdf.putAtt(ncid,NJULDDESTAID,'standard_name','time');
netcdf.putAtt(ncid,NJULDDESTAID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDDESTAID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDDESTAID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDDESTAID,'_FillValue',double(999999.));

NJULDDESTASTID=netcdf.defVar(ncid,'JULD_DESCENT_START_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDESTASTID,'long_name','Status of descent start date of the cycle');
netcdf.putAtt(ncid,NJULDDESTASTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDDESTASTID,'conventions','Argo reference table 19');

NJULDDEENDID=netcdf.defVar(ncid,'JULD_DESCENT_END','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEENDID,'long_name','Descent end date of the cycle');
netcdf.putAtt(ncid,NJULDDEENDID,'standard_name','time');
netcdf.putAtt(ncid,NJULDDEENDID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDDEENDID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDDEENDID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDDEENDID,'_FillValue',double(999999.));

NJULDDEENDSTID=netcdf.defVar(ncid,'JULD_DESCENT_END_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEENDSTID,'long_name','Status of descent end date of the cycle');
netcdf.putAtt(ncid,NJULDDEENDSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDDEENDSTID,'conventions','Argo reference table 19');

NJULDTRANSSTAID=netcdf.defVar(ncid,'JULD_TRANSMISSION_START','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDTRANSSTAID,'long_name','Start date of transmission');
netcdf.putAtt(ncid,NJULDTRANSSTAID,'standard_name','time');
netcdf.putAtt(ncid,NJULDTRANSSTAID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDTRANSSTAID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDTRANSSTAID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDTRANSSTAID,'_FillValue',double(999999.));

NJULDTRANSSTASTID=netcdf.defVar(ncid,'JULD_TRANSMISSION_START_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDTRANSSTASTID,'long_name','Status of start date of transmission');
netcdf.putAtt(ncid,NJULDTRANSSTASTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDTRANSSTASTID,'conventions','Argo reference table 19');

NJULDFIRSTABID=netcdf.defVar(ncid,'JULD_FIRST_STABILIZATION','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDFIRSTABID,'long_name','Time when a float first becomes water-neutral');
netcdf.putAtt(ncid,NJULDFIRSTABID,'standard_name','time');
netcdf.putAtt(ncid,NJULDFIRSTABID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDFIRSTABID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDFIRSTABID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDFIRSTABID,'_FillValue',double(999999.));

NJULDFIRSTABSTID=netcdf.defVar(ncid,'JULD_FIRST_STABILIZATION_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDFIRSTABSTID,'long_name','Status of time when a float first becomes water-neutral');
netcdf.putAtt(ncid,NJULDFIRSTABSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDFIRSTABSTID,'conventions','Argo reference table 19');

NJULDPARKSTAID=netcdf.defVar(ncid,'JULD_PARK_START','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDPARKSTAID,'long_name','Drift start date of the cycle');
netcdf.putAtt(ncid,NJULDPARKSTAID,'standard_name','time');
netcdf.putAtt(ncid,NJULDPARKSTAID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDPARKSTAID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDPARKSTAID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDPARKSTAID,'_FillValue',double(999999.));

NJULDPARKSTASTID=netcdf.defVar(ncid,'JULD_PARK_START_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDPARKSTASTID,'long_name','Status of drift start date of the cycle');
netcdf.putAtt(ncid,NJULDPARKSTASTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDPARKSTASTID,'conventions','Argo reference table 19');

NJULDPARKENDID=netcdf.defVar(ncid,'JULD_PARK_END','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDPARKENDID,'long_name','Drift end date of the cycle');
netcdf.putAtt(ncid,NJULDPARKENDID,'standard_name','time');
netcdf.putAtt(ncid,NJULDPARKENDID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDPARKENDID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDPARKENDID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDPARKENDID,'_FillValue',double(999999.));

NJULDPARKENDSTID=netcdf.defVar(ncid,'JULD_PARK_END_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDPARKENDSTID,'long_name','Status of drift end date of the cycle');
netcdf.putAtt(ncid,NJULDPARKENDSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDPARKENDSTID,'conventions','Argo reference table 19');

NJULDDEEPPARKSTAID=netcdf.defVar(ncid,'JULD_DEEP_PARK_START','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEEPPARKSTAID,'long_name','Deep park start date of the cycle');
netcdf.putAtt(ncid,NJULDDEEPPARKSTAID,'standard_name','time');
netcdf.putAtt(ncid,NJULDDEEPPARKSTAID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDDEEPPARKSTAID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDDEEPPARKSTAID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDDEEPPARKSTAID,'_FillValue',double(999999.));

NJULDDEEPPARKSTASTID=netcdf.defVar(ncid,'JULD_DEEP_PARK_START_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEEPPARKSTASTID,'long_name','Status of deep park start date of the cycle');
netcdf.putAtt(ncid,NJULDDEEPPARKSTASTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDDEEPPARKSTASTID,'conventions','Argo reference table 19');

NJULDDEEPDEENDID=netcdf.defVar(ncid,'JULD_DEEP_DESCENT_END','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEEPDEENDID,'long_name','Deep descent end date of the cycle');
netcdf.putAtt(ncid,NJULDDEEPDEENDID,'standard_name','time');
netcdf.putAtt(ncid,NJULDDEEPDEENDID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDDEEPDEENDID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDDEEPDEENDID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDDEEPDEENDID,'_FillValue',double(999999.));

NJULDDEEPDEENDSTID=netcdf.defVar(ncid,'JULD_DEEP_DESCENT_END_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEEPDEENDSTID,'long_name','Status of deep descent end date of the cycle');
netcdf.putAtt(ncid,NJULDDEEPDEENDSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDDEEPDEENDSTID,'conventions','Argo reference table 19');

NJULDDEEPASSTAID=netcdf.defVar(ncid,'JULD_DEEP_ASCENT_START','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEEPASSTAID,'long_name','Deep ascent start date of the cycle');
netcdf.putAtt(ncid,NJULDDEEPASSTAID,'standard_name','time');
netcdf.putAtt(ncid,NJULDDEEPASSTAID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDDEEPASSTAID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDDEEPASSTAID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDDEEPASSTAID,'_FillValue',double(999999.));

NJULDDEEPASSTASTID=netcdf.defVar(ncid,'JULD_DEEP_ASCENT_START_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDDEEPASSTASTID,'long_name','Status of deep ascent start date of the cycle');
netcdf.putAtt(ncid,NJULDDEEPASSTASTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDDEEPASSTASTID,'conventions','Argo reference table 19');

NJULDTRANSENDID=netcdf.defVar(ncid,'JULD_TRANSMISSION_END','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDTRANSENDID,'long_name','Transmission end date');
netcdf.putAtt(ncid,NJULDTRANSENDID,'standard_name','time');
netcdf.putAtt(ncid,NJULDTRANSENDID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDTRANSENDID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDTRANSENDID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDTRANSENDID,'_FillValue',double(999999.));

NJULDTRANSENDSTID=netcdf.defVar(ncid,'JULD_TRANSMISSION_END_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDTRANSENDSTID,'long_name','Status of transmission end date');
netcdf.putAtt(ncid,NJULDTRANSENDSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDTRANSENDSTID,'conventions','Argo reference table 19');

NJULDFIRSMESSID=netcdf.defVar(ncid,'JULD_FIRST_MESSAGE','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDFIRSMESSID,'long_name','Date of earliest float message received');
netcdf.putAtt(ncid,NJULDFIRSMESSID,'standard_name','time');
netcdf.putAtt(ncid,NJULDFIRSMESSID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDFIRSMESSID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDFIRSMESSID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDFIRSMESSID,'_FillValue',double(999999.));

NJULDFIRSMESSSTID=netcdf.defVar(ncid,'JULD_FIRST_MESSAGE_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDFIRSMESSSTID,'long_name','Status of date of earliest float message received');
netcdf.putAtt(ncid,NJULDFIRSMESSSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDFIRSMESSSTID,'conventions','Argo reference table 19');

NJULDFIRSLOCID=netcdf.defVar(ncid,'JULD_FIRST_LOCATION','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDFIRSLOCID,'long_name','Date of earliest location');
netcdf.putAtt(ncid,NJULDFIRSLOCID,'standard_name','time');
netcdf.putAtt(ncid,NJULDFIRSLOCID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDFIRSLOCID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDFIRSLOCID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDFIRSLOCID,'_FillValue',double(999999.));

NJULDFIRSLOCSTID=netcdf.defVar(ncid,'JULD_FIRST_LOCATION_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDFIRSLOCSTID,'long_name','Status of date of earliest location');
netcdf.putAtt(ncid,NJULDFIRSLOCSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDFIRSLOCSTID,'conventions','Argo reference table 19');

NJULDLASTMESSID=netcdf.defVar(ncid,'JULD_LAST_MESSAGE','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDLASTMESSID,'long_name','Date of latest float message received');
netcdf.putAtt(ncid,NJULDLASTMESSID,'standard_name','time');
netcdf.putAtt(ncid,NJULDLASTMESSID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDLASTMESSID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDLASTMESSID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDLASTMESSID,'_FillValue',double(999999.));

NJULDLASTMESSSTID=netcdf.defVar(ncid,'JULD_LAST_MESSAGE_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDLASTMESSSTID,'long_name','Status of date of latest float message received');
netcdf.putAtt(ncid,NJULDLASTMESSSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDLASTMESSSTID,'conventions','Argo reference table 19');

NJULDLASTLOCID=netcdf.defVar(ncid,'JULD_LAST_LOCATION','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NJULDLASTLOCID,'long_name','Date of latest location');
netcdf.putAtt(ncid,NJULDLASTLOCID,'standard_name','time');
netcdf.putAtt(ncid,NJULDLASTLOCID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDLASTLOCID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDLASTLOCID,'resolution',double(0.01)); % Made this up. Not defined. JRD May14
netcdf.putAtt(ncid,NJULDLASTLOCID,'_FillValue',double(999999.));

NJULDLASTLOCSTID=netcdf.defVar(ncid,'JULD_LAST_LOCATION_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NJULDLASTLOCSTID,'long_name','Status of date of latest location');
netcdf.putAtt(ncid,NJULDLASTLOCSTID,'_FillValue',' ');
netcdf.putAtt(ncid,NJULDLASTLOCSTID,'conventions','Argo reference table 19');

NCLOOFFSID=netcdf.defVar(ncid,'CLOCK_OFFSET','NC_DOUBLE',N_CYCLEID);
netcdf.putAtt(ncid,NCLOOFFSID,'long_name','Time of float clock drift');
netcdf.putAtt(ncid,NCLOOFFSID,'units','days');
netcdf.putAtt(ncid,NCLOOFFSID,'conventions','Days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NCLOOFFSID,'_FillValue',double(999999.));

NGROUDID=netcdf.defVar(ncid,'GROUNDED','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NGROUDID,'long_name','Did the profiler touch the ground for that cycle?');
netcdf.putAtt(ncid,NGROUDID,'conventions','Argo reference table 20');
netcdf.putAtt(ncid,NGROUDID,'_FillValue',' ');

NREPREPARKPRESID=netcdf.defVar(ncid,'REPRESENTATIVE_PARK_PRESSURE','NC_FLOAT',N_CYCLEID);
netcdf.putAtt(ncid,NREPREPARKPRESID,'long_name','Best pressure value during park phase');
netcdf.putAtt(ncid,NREPREPARKPRESID,'units','decibar');
netcdf.putAtt(ncid,NREPREPARKPRESID,'_FillValue',single(99999.));

NREPREPARKPRESSTID=netcdf.defVar(ncid,'REPRESENTATIVE_PARK_PRESSURE_STATUS','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NREPREPARKPRESSTID,'long_name','Status of best pressure value during park phase');
netcdf.putAtt(ncid,NREPREPARKPRESSTID,'conventions','Argo reference table 21');
netcdf.putAtt(ncid,NREPREPARKPRESSTID,'_FillValue',' ');

NCONFMISNUMID=netcdf.defVar(ncid,'CONFIG_MISSION_NUMBER','NC_INT',N_CYCLEID);
netcdf.putAtt(ncid,NCONFMISNUMID,'long_name','Unique number denoting the missions performed by the float');
netcdf.putAtt(ncid,NCONFMISNUMID,'conventions','1...N, 1 : first complete mission');
netcdf.putAtt(ncid,NCONFMISNUMID,'_FillValue',int32(99999));

NCYCNUMINDID=netcdf.defVar(ncid,'CYCLE_NUMBER_INDEX','NC_INT',N_CYCLEID);
netcdf.putAtt(ncid,NCYCNUMINDID,'long_name','Cycle number that corresponds to the current index');
netcdf.putAtt(ncid,NCYCNUMINDID,'conventions','0...N, 0 : launch cycle, 1 : first complete cycle');
netcdf.putAtt(ncid,NCYCNUMINDID,'_FillValue',int32(99999));

NCYCNUMINDADID=netcdf.defVar(ncid,'CYCLE_NUMBER_INDEX_ADJUSTED','NC_INT',N_CYCLEID);
netcdf.putAtt(ncid,NCYCNUMINDADID,'long_name','Adjusted cycle number that corresponds to the current index');
netcdf.putAtt(ncid,NCYCNUMINDADID,'conventions','0...N, 0 : launch cycle, 1 : first complete cycle');
netcdf.putAtt(ncid,NCYCNUMINDADID,'_FillValue',int32(99999));

NDAMOID=netcdf.defVar(ncid,'DATA_MODE','NC_CHAR',N_CYCLEID);
netcdf.putAtt(ncid,NDAMOID,'long_name','Delayed mode or real time data');
netcdf.putAtt(ncid,NDAMOID,'conventions','R : real time; D : delayed mode; A : real time with adjustment');
netcdf.putAtt(ncid,NDAMOID,'_FillValue',' ');

% History defs

NHISINSID=netcdf.defVar(ncid,'HISTORY_INSTITUTION','NC_CHAR',[STR4,N_HISID]);
netcdf.putAtt(ncid,NHISINSID,'long_name','Institution which performed action');
netcdf.putAtt(ncid,NHISINSID,'conventions','Argo reference table 4');
netcdf.putAtt(ncid,NHISINSID,'_FillValue',' ');

NHISSTEPID=netcdf.defVar(ncid,'HISTORY_STEP','NC_CHAR',[STR4,N_HISID]);
netcdf.putAtt(ncid,NHISSTEPID,'long_name','Step in data processing');
netcdf.putAtt(ncid,NHISSTEPID,'conventions','Argo reference table 12');
netcdf.putAtt(ncid,NHISSTEPID,'_FillValue',' ');

NHISSOFTID=netcdf.defVar(ncid,'HISTORY_SOFTWARE','NC_CHAR',[STR4,N_HISID]);
netcdf.putAtt(ncid,NHISSOFTID,'long_name','Name of software which performed action');
netcdf.putAtt(ncid,NHISSOFTID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISSOFTID,'_FillValue',' ');

NHISSOFTRELEID=netcdf.defVar(ncid,'HISTORY_SOFTWARE_RELEASE','NC_CHAR',[STR4,N_HISID]);
netcdf.putAtt(ncid,NHISSOFTRELEID,'long_name','Version/release of software which performed action');
netcdf.putAtt(ncid,NHISSOFTRELEID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISSOFTRELEID,'_FillValue',' ');

NHISREFERID=netcdf.defVar(ncid,'HISTORY_REFERENCE','NC_CHAR',[STR64,N_HISID]);
netcdf.putAtt(ncid,NHISREFERID,'long_name','Reference of database');
netcdf.putAtt(ncid,NHISREFERID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISREFERID,'_FillValue',' ');

NHISDAID=netcdf.defVar(ncid,'HISTORY_DATE','NC_CHAR',[DaTi,N_HISID]);
netcdf.putAtt(ncid,NHISDAID,'long_name','Date the history record was created');
netcdf.putAtt(ncid,NHISDAID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NHISDAID,'_FillValue',' ');

NHISACTID=netcdf.defVar(ncid,'HISTORY_ACTION','NC_CHAR',[STR4,N_HISID]);
netcdf.putAtt(ncid,NHISACTID,'long_name','Action performed on data');
netcdf.putAtt(ncid,NHISACTID,'conventions','Argo reference table 7');
netcdf.putAtt(ncid,NHISACTID,'_FillValue',' ');

NHISPARAID=netcdf.defVar(ncid,'HISTORY_PARAMETER','NC_CHAR',[STR16,N_HISID]);
netcdf.putAtt(ncid,NHISPARAID,'long_name','Station parameter action is performed on');
netcdf.putAtt(ncid,NHISPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NHISPARAID,'_FillValue',' ');

NHISPREVALID=netcdf.defVar(ncid,'HISTORY_PREVIOUS_VALUE','NC_FLOAT',N_HISID);
netcdf.putAtt(ncid,NHISPREVALID,'long_name','Parameter/Flag previous value before action');
netcdf.putAtt(ncid,NHISPREVALID,'_FillValue',single(99999.));

NHISINDDIMID=netcdf.defVar(ncid,'HISTORY_INDEX_DIMENSION','NC_CHAR',N_HISID);
netcdf.putAtt(ncid,NHISINDDIMID,'long_name','Name of dimension to which HISTORY_START_INDEX and HISTORY_STOP_INDEX correspond');
netcdf.putAtt(ncid,NHISINDDIMID,'conventions','C: N_CYCLE, M: N_MEASUREMENT');
netcdf.putAtt(ncid,NHISINDDIMID,'_FillValue',' ');

NHISSTAINDID=netcdf.defVar(ncid,'HISTORY_START_INDEX','NC_INT',N_HISID);
netcdf.putAtt(ncid,NHISSTAINDID,'long_name','Start index action applied on');
netcdf.putAtt(ncid,NHISSTAINDID,'_FillValue',int32(99999));

NHISSTOINDID=netcdf.defVar(ncid,'HISTORY_STOP_INDEX','NC_INT',N_HISID);
netcdf.putAtt(ncid,NHISSTOINDID,'long_name','Stop index action applied on');
netcdf.putAtt(ncid,NHISSTOINDID,'_FillValue',int32(99999));

NHISQCTID=netcdf.defVar(ncid,'HISTORY_QCTEST','NC_CHAR',[STR16,N_HISID]);
netcdf.putAtt(ncid,NHISQCTID,'long_name','Documentation of tests performed, tests failed (in hex form)');
netcdf.putAtt(ncid,NHISQCTID,'conventions','Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
netcdf.putAtt(ncid,NHISQCTID,'_FillValue',' ');


% --------- Finished definitions, now add data

sensdb = getadditionalinfo(dbdat.wmo_id);
mission=get_Argos_config_params(dbdat.wmo_id);

% Fill the fields common to several filetypes
% generic_fields_nc(nc,dbdat,3,2);

netcdf.endDef(ncid);

aa = num2str(dbdat.wmo_id);

netcdf.putVar(ncid,NPLANUID,0,length(aa),aa);
netcdf.putVar(ncid,NDACENID,0,length(ARGO_SYS_PARAM.datacentre),ARGO_SYS_PARAM.datacentre);

netcdf.putVar(ncid,NDAUPID,0,14,today_str(1:14));

if ~isempty(strfind(dbdat.owner,'COOE'))
    netcdf.putVar(ncid,NPRONAID,0,31,'Cooperative Ocean Observing Exp');
else
    aa=ARGO_SYS_PARAM.Proj;
    netcdf.putVar(ncid,NPRONAID,0,length(aa),aa);  %'Argo AUSTRALIA';
end
if isfield(fpp,'PI')
    netcdf.putVar(ncid,NPINAID,0,length(fpp(1).PI),fpp(1).PI);
else
    netcdf.putVar(ncid,NPINAID,0,length(ARGO_SYS_PARAM.PI_Name),ARGO_SYS_PARAM.PI_Name) ;  %'Susan Wijffels';
end

ll = length(dbdat.wmo_inst_type);
netcdf.putVar(ncid,WMOINSTID,0,ll,dbdat.wmo_inst_type);
if dbdat.iridium
    netcdf.putVar(ncid,NPOSSYSID, 0,3,'GPS');
else
    netcdf.putVar(ncid,NPOSSYSID, 0,5 ,'ARGOS');
end

netcdf.putVar(ncid,NDATYID,0,length('Argo trajectory'),'Argo trajectory');
netcdf.putVar(ncid,NFMVRID,0,length('3.1'),'3.1');
netcdf.putVar(ncid,NHDVRID,0,length(' 1.2'),' 1.2');
netcdf.putVar(ncid,NREDTID,0,length('19500101000000'),'19500101000000');
netcdf.putVar(ncid,NDACRID,0,length(dc),dc);

for ii = 1:length(params)
   str = pars{params(ii)};
   netcdf.putVar(ncid,NTRAJPARAID,[0,params(ii)-1],[length(str),1],str);
end

netcdf.putVar(ncid,NDASTAINDID,0,length('2B  '),'2B  ');

% This might do for now?
switch dbdat.maker
    case 1
        if dbdat.subtype==0
            netcdf.putVar(ncid,NPLATYID,0,length('PALACE'),'PALACE');
        else
            netcdf.putVar(ncid,NPLATYID,0,length('APEX'),'APEX');
        end
    case 2
        netcdf.putVar(ncid,NPLATYID,0,length('PROVOR-MT'),'PROVOR-MT');
    case 3
        netcdf.putVar(ncid,NPLATYID,0,length('SOLO-W'),'SOLO-W');
    case 4
        netcdf.putVar(ncid,NPLATYID,0,length('NAVIS_A'),'NAVIS_A');
    case 5
        netcdf.putVar(ncid,NPLATYID,0,length('S2A'),'S2A');
end

aa =   sensdb.mfg_id;   
if ~ischar(aa)
    aa = num2str(aa);
end
netcdf.putVar(ncid,NFLSERNOID,0,length(aa),aa);

aa = mission.data{29};
if isempty(aa)
    aa='n/a';
end

if ~isempty(aa)
    netcdf.putVar(ncid,NFIRVERID,0,length(aa),aa);
end

j1950 = julian([1950 1 1 0 0 0]);
% Launch position and date in N_MEASUREMENT (but I think not in N_CYCLE)
iNM = 1;
tmp = sscanf(dbdat.launchdate,'%4d%2d%2d%2d%2d%2d');
netcdf.putVar(ncid,NJULDID,iNM-1,length(julian(tmp(:)')),julian(tmp(:)')-j1950);
netcdf.putVar(ncid,NLATID,iNM-1,length(dbdat.launch_lat),dbdat.launch_lat);
netcdf.putVar(ncid,NLONGID,iNM-1,length(dbdat.launch_lon),dbdat.launch_lon);
netcdf.putVar(ncid,NJULDQCID,iNM-1,length('1'),'1');
netcdf.putVar(ncid,NPOSQCID,iNM-1,length('1'),'1');

%  Set to 1 if/when position is checked,  otherwise 0. I assume they have
%  been checked 

% num2str(-1)
netcdf.putVar(ncid,NCYCNUMID,iNM-1,length(-1),-1);
netcdf.putVar(ncid,NMEASCOID,iNM-1,length(0),0);

% UTC time
netcdf.putVar(ncid,NDAUPID,0,length(today_str),today_str);



% For mandatory cycle timing fields, must use fillvalue in N_CYCLE and
% N_MEASUREMENT fields if times cannot even be estimated.

% User Manual pp25
% "If the float experiences an event but the time is not able to be
% determined, then most variables are set to fill value and a *_STATUS = '9'
% is used in both the N_MEASUREMENT and N_CYCLE arrays. This indicates that
% it might be possible to estimate in the future and acts as a placeholder.
%
% If a float does not experience an event, then the fill values are used for
% all N_CYCLE variables. These non-events do not get a placeholder in the 
% N_MEASUREMENT arrays."


% ----------------- N_CYCLE dimension fields
ii = 0;
for nn = gotcyc
   % We don't include missing cycles, so should end up with ii=length(gotcyc)
   ii = ii+1;
   
   % If float cycle number starts from zero then this will may need
   % correction, although normally cycle zero would be in in fpp(1), so
   % it will work out ok.
   netcdf.putVar(ncid,NCYCNUMINDID,ii-1,length(fpp(nn).profile_number),fpp(nn).profile_number);
   
   if isempty(traj(nn).clockoffset)
      jcor = j1950;
      netcdf.putVar(ncid,NDAMOID,ii-1,length('R'),'R');
   else
      % Clock correction to applying to times which are not already
      % intrinsically corrected.
      jcor = j1950 + traj(nn).clockoffset;
      netcdf.putVar(ncid,NCLOOFFSID,ii-1,length(traj(nn).clockoffset),traj(nn).clockoffset);
      netcdf.putVar(ncid,NDAMOID,ii-1,length('A'),'A');
   end      
   
   % Q: Are all variables below to be used for all floats of all types?
   %
   % Q: When do we leave _STATUS as fillvalue, and when do we use '9'?
   %	 
   %  Assuming STATUS here the same as JULD_STATUS in N_M arrays.

   %    nvnm = {'DESCENT_START','FIRST_STABILIZATION','DESCENT_END','PARK_START',...
   % 	   'PARK_END','DEEP_DESCENT_END','DEEP_PARK_START','DEEP_ASCENT_START',...
   % 	   'ASCENT_START','ASCENT_END','TRANSMISSION_START','FIRST_MESSAGE',...
   % 	   'FIRST_LOCATION','LAST_LOCATION','LAST_MESSAGE','TRANSMISSION_END'};
   nvnm = {'DESTA','FIRSTAB','DEEND','PARKSTA',...
       'PARKEND','DEEPDEEND','DEEPPARKSTA','DEEPASSTA',...
       'ASSTA','ASEND','TRANSSTA','FIRSMESS',...
       'FIRSLOC','LASTLOC','LASTMESS','TRANSEND'};
   tvnm = {'DST','FST','DET','PST',...
       'PET','DDET','DPST','DAST',...
       'AST','AET','TST','FMT',...
       'FLT','LLT','LMT','TET'};
   %    j1950 = julian([1950 1 1 0 0 0]); %%%%%%%%%%%%%%%%%%%%%%%%%20160725Add
   for jj = 1:length(nvnm)
      nnm = nvnm{jj};
      tnm = tvnm{jj};
      if isfield(traj,tnm) && ~isempty(traj(nn).(tnm).juld)
	 if ~isnan(traj(nn).(tnm).juld)
         if traj(nn).(tnm).adj
             %            cmmd=['netcdf.putAtt(ncid,N' parnm 'ADID,''C_format'',cfmt{ipar});'];
             cmmd=['netcdf.putVar(ncid,NJULD' nnm 'ID,ii-1,length(traj(nn).(tnm).juld-j1950),traj(nn).(tnm).juld-j1950);'];
             eval(cmmd);
             %            netcdf.putVar(ncid,['NJULD_' nnm 'ID'],ii-1,length(traj(nn).(tnm).juld-j1950),traj(nn).(tnm).juld-j1950);
         else
             cmmd=['netcdf.putVar(ncid,NJULD' nnm 'ID,ii-1,length(traj(nn).(tnm).juld-jcor),traj(nn).(tnm).juld-j1950);'];
             eval(cmmd);
             %            netcdf.putVar(ncid,['NJULD_' nnm 'ID'],ii-1,length(traj(nn).(tnm).juld-jcor),traj(nn).(tnm).juld-jcor);
         end
     end
     cmmd=['netcdf.putVar(ncid,NJULD' nnm 'STID,ii-1,length(char(traj(nn).(tnm).stat)),char(traj(nn).(tnm).stat));'];
     eval(cmmd);
     %      netcdf.putVar(ncid,['NJULD_' nnm '_STATUSID'],ii-1,length(traj(nn).(tnm).stat),traj(nn).(tnm).stat);
      end
   end
   
   netcdf.putVar(ncid,NGROUDID,ii-1,length(fpp(nn).grounded),fpp(nn).grounded);
   
   % REPRESENTATIVE_PARK_PRESSURE is only used where values are averaged to
   % provide one value for whole park period (corresponds to MC=301)   

   % This probably only if adjustment determined in Delayed Mode?
end


% Copied from metadata_ncV3.m, May 2014
if dbdat.iridium
    % iridium configuration parameters come from elsewhere:
    %     and have already been loaded with mission number
    [~,missionI] = getmission_number(dbdat.wmo_id,fpp(end).profile_number,1,dbdat);
    for jk = 1:length(missionI.missionno)
        netcdf.putVar(ncid,NCONFMISNUMID,jk-1,length(missionI.missionno(jk)),missionI.missionno(jk));
    end
else
    % Simple for non-Iridiun floats
    for jk=1:length(gotcyc)
        jk
        netcdf.putVar(ncid,NCONFMISNUMID,jk-1,1,1);
    end
end



% ------------- N_MEASUREMENT dimension fields

% Manual references for M-CODEs:
% 290  3.4.1.1.2
% 296  3.4.1.1.2.3
% 297,298  3.4.2.6
% 299  - not yet used? "any single measurement" so could apply to a single
%    park measurement, but we expect a series of park measurements, hence use 290?
% 300  3.2.2.1.5.1
% 301  3.4.3

% M-CODE to variable name cross-ref
vnms([100,150,200,250,300,400,450,500,550,600,700,702,704,800]) = ...
    [{'DST'} {'FST'} {'DET'} {'PST'} {'PET'} {'DDET'} {'DPST'} {'AST'} {'DAST'} ...
     {'AET'} {'TST'} {'FMT'} {'LMT'} {'TET'}];

jfillval = 999999;   

numnn=0;
% Loop on profiles to be written to this file
for nn = gotcyc
numnn=numnn+1;    

   % Add variables which have been recently introduced but maybe not yet
   % loaded for all cycles.    JRD July 2014
   %if ~isfield(fpp(nn),'jday_qc')
   %   fpp(nn).jday_qc = ones(size(fpp(nn).jday));
   %end
   %if ~isfield(fpp(nn),'position_qc')
   %   fpp(nn).position_qc = ones(size(fpp(nn).jday));
   %end
   
   for mc = traj_mc_order
      madd = [];
      switch mc
	 
	case {100,150,200,250,300,400,450,500,550,600,700,702,704,800}
	  vnm = vnms{mc};
	  if isfield(traj,vnm)
	     fv = traj(nn).(vnm);
	     if ~isempty(fv) && ~isempty(fv.juld)
		% Assume cannot have multi-valued parameters
		% Beware: some tricky interacting requirements here. Thoroughly
		% read Cookbook section 3.2.2 before changing anything.
		if isnan(fv.juld)
		   jday = jfillval;
		   status = '9';
		else
		   jday = fv.juld-j1950;
		   status = fv.stat;
		end
		adj = fv.adj;
		madd = iNM+1;
		if ~adj
           netcdf.putVar(ncid,NJULDID,madd(1)-1,length(jday),jday);
           netcdf.putVar(ncid,NJULDSTID,madd(1)-1,length(status),status);           
		   if isfield(fv,'qc') && ~isempty(fv.qc)
              netcdf.putVar(ncid,NJULDQCID,madd(1)-1,length(fv.qc),fv.qc);               
           else
              netcdf.putVar(ncid,NJULDQCID,madd(1)-1,length('0'),'0');                
		   end
		   if ~isempty(traj(nn).clockoffset)
		      adj = 1;
		      jday = jday - traj(nn).clockoffset;
		   end
		end
		if adj
		   if fv.adj
              netcdf.putVar(ncid,NJULDSTID,madd(1)-1,length( '9'), '9');
           end
           netcdf.putVar(ncid,NJULDADID,madd(1)-1,length(jday),jday);
           netcdf.putVar(ncid,NJULDADSTID,madd(1)-1,length(status),status);
		   if isfield(fv,'qc') && ~isempty(fv.qc)
              netcdf.putVar(ncid,NJULDADQCID,madd(1)-1,length(fv.qc),fv.qc);               
           else
              netcdf.putVar(ncid,NJULDADQCID,madd(1)-1,length('0'),'0');                
		   end
		end
	    end
	  end	     
	  
	  
	case {99,290,296}
	  % Due to coding in decode_webb, there is presently no floattype-independant 
	  % relationship between n_parkaverages & p_park_av, and n_parksamps &
	  % park_p. n_parksamps probably refers to the number of samples
          % going into the averages? Anyway we ignore those counters and just
          % store whatever data we find.  
	  %
	  % Previous coding here implied may be multi-valued AND size of
	  % _jday may not match park_p.  That would be rather messy, eh? I
	  % am going to ignore that possibility

	  if mc==99
	     % Surface: single measurements made prior to start of descent	  
	     % Use MC=96 for average surface measurements 	  
	     % Rethink if we can get surf measurements without surf_Oxy_pressure??
	     % Oxy measurements should be in B-file anyway! 
	     ok = isfield(fpp,'surf_Oxy_pressure') && ~isempty(fpp(nn).surf_Oxy_pressure) ...
		  && ~isnan(fpp(nn).surf_Oxy_pressure);
	     tmpnm = surfnm;
	     if ok
		%jday = fpp(nn).surf_jday(1);      % surf_jday ?? ******		
		jday = traj(nn).DST.juld;
		stus = traj(nn).DST.stat;
	     end	  
	  elseif mc==290
	     % Park         
	     ok = isfield(fpp,'park_p') && ~isempty(fpp(nn).park_p);
	     tmpnm = parknm;
	     %jday = fpp(nn).park_jday(1);     % ??
	     % Here need to find out sample timing scheme and compute juld
	     % Temporary alternative below:
	     if ok && isfield(traj,'PET')
		jday = traj(nn).PET.juld;
		stus = traj(nn).PET.stat;
	     else
		ok = 0;
	     end
	  elseif mc==296            
	     % "aves towards PET"       3.4.1.1.2
	     % If we have individual samples instead of averages then should
             % use MC=290. If we have or we create a single average for the Park period
	     % then should use MC=301 (3.4.3), in which case we should also
             % provide a value for REPRESENTATIVE_PARK_PRESSURE
	     ok = isfield(fpp,'p_park_av') && ~isempty(fpp(nn).p_park_av);
	     tmpnm = pkavnm;
	     %jday = fpp(nn).park_av_jday(1);   % ??
	     if ok && isfield(traj,'PET')
		jday = traj(nn).PET.juld;
		stus = traj(nn).PET.stat;
	     else
		ok = 0;
	     end
	  end
	  
	  if ok
	     % There can be multiple values (eg for park_av). ASSUME there
             % will always be P values if T or S, so determine number of 
	     % values from number of P (ipar=1) values.
	     if isfield(fpp(nn),tmpnm{1})
		nval = length(fpp(nn).(tmpnm{1}));
	     else
		nval = 0;
	     end
	     
	     for ij = 1:nval
             netcdf.putVar(ncid,NJULDID,iNM+ij-1,length(jday-j1950),jday-j1950);
             netcdf.putVar(ncid,NJULDSTID,iNM+ij-1,length(stus),stus);
             netcdf.putVar(ncid,NJULDQCID,iNM+ij-1,length('1'),'1');
	     end
	     % Use clockoffset to decide whether to use JULD_ADJUSTED ??
	     
	     for ipar = params
		if isfield(fpp(nn),tmpnm{ipar})
		   tmp = fpp(nn).(tmpnm{ipar});
		   for ij = 1:min(nval,length(tmp))
		      if ~isnan(tmp(ij))
            cmmd=['netcdf.putVar(ncid,N' pars{ipar} 'ID,iNM+ij-1,length(tmp(ij)),tmp(ij));'];
            eval(cmmd);
            cmmd=['netcdf.putVar(ncid,N' pars{ipar} 'QCID,iNM+ij-1,length(''0''),''0'');'];
            eval(cmmd);            
			 if ~isempty(fpp(nn).surfpres_used)
			    % Don't know if this can/should apply for surface values 
			    if ipar==1
			       tmp(ij) = tmp(ij) - fpp(nn).surfpres_used;
                   netcdf.putVar(ncid,NDAMOID,numnn-1,length('A'),'A');
                end
                cmmd=['netcdf.putVar(ncid,N' pars{ipar} 'ADID,iNM+ij-1,length(tmp(ij)),tmp(ij));'];
                eval(cmmd);
                cmmd=['netcdf.putVar(ncid,N' pars{ipar} 'ADQCID,iNM+ij-1,length(''0''),''0'');'];
                eval(cmmd);
			 elseif ipar==1
                netcdf.putVar(ncid,NDAMOID,numnn-1,length('R'),'R');
			 end
		      end
		   end
		end
	     end
	     
	     madd = iNM+(1:nval);	     
	  end
	
	
	case 703 
	  % The actual Argos fixes
	  %
	  % ### Actually need to get this from traj, not float
	  %
	  %

	  %if ~isempty(fpp(nn).jday)
	  %   % Do we load all, even if NaN, or just good ones? Assume latter.
	  %   ij = find(~isnan(fpp(nn).jday(:)+fpp(nn).lat(:)+fpp(nn).lon(:)));
	  %else
	  %   ij = [];
	  %end
	  %if ~isempty(ij)	     
	  %   madd = iNM + (1:length(ij));
	  %   nc{'JULD'}(madd) = fpp(nn).jday(ij)-j1950;
          %   % nc{'JULD_QC'}(madd) = char(fpp(nn).jday_qc(ij));
	  %   nc{'JULD_QC'}(madd) = repmat('1',(size(fpp(nn).jday_qc(ij))));
	  %   nc{'JULD_STATUS'}(madd) = '4';  
	  %   nc{'LATITUDE'}(madd) = fpp(nn).lat(ij);
	  %   nc{'LONGITUDE'}(madd) = fpp(nn).lon(ij);
	  %   %nc{'POSITION_QC'}(madd) = char(fpp(nn).position_qc(ij));
	  %   nc{'POSITION_QC'}(madd) = repmat('1',size(fpp(nn).lon(ij)));
	  %   nc{'POSITION_ACCURACY'}(madd) = fpp(nn).position_accuracy(ij);
	  %   if isfield(fpp,'satnam') && ~isempty(fpp(nn).satnam)
	  %	nc{'SATELLITE_NAME'}(madd) = fpp(nn).satnam(ij);
	  %   end
	  %end
	  
      if ~isempty(traj(nn).heads) && isfield(traj(nn).heads,'juld')
          madd = iNM + (1:length(traj(nn).heads.juld));
          netcdf.putVar(ncid,NJULDID,madd(1)-1,length(traj(nn).heads.juld-j1950),traj(nn).heads.juld-j1950);
          if isfield(traj(nn).heads,'juld_qc') && ~isempty(traj(nn).heads.juld_qc)
              netcdf.putVar(ncid,NJULDQCID,madd(1)-1,length(char(traj(nn).heads.juld_qc(:))),char(traj(nn).heads.juld_qc(:)));
          else
              netcdf.putVar(ncid,NJULDQCID,madd(1)-1,length('0'),'0');
          end
          netcdf.putVar(ncid,NJULDSTID,madd(1)-1,length('4'),'4');
          netcdf.putVar(ncid,NLATID,madd(1)-1,length(traj(nn).heads.lat),traj(nn).heads.lat);
          %make sure longitude is +/-180, not 0-360 as stored in mat files:
          lon = traj(nn).heads.lon;
          if any(lon > 180)
              ii = lon>180;
              lon(ii) = -1*(360-lon(ii));
          end
          netcdf.putVar(ncid,NLONGID,madd(1)-1,length(lon),lon);
          if isfield(traj(nn).heads,'qcflags') && ~isempty(traj(nn).heads.qcflags)
              netcdf.putVar(ncid,NPOSQCID,madd(1)-1,length(num2str(traj(nn).heads.qcflags)),num2str(traj(nn).heads.qcflags));
          else
              netcdf.putVar(ncid,NPOSQCID,madd(1)-1,length('1'),'1');
          end
          if isfield(traj(nn).heads,'aclass')
              netcdf.putVar(ncid,NPOSACCID,madd(1)-1,length(traj(nn).heads.aclass),traj(nn).heads.aclass);
          end
          if isfield(traj(nn).heads,'satnam') && ~isempty(traj(nn).heads.satnam)
              netcdf.putVar(ncid,NSATENAID,madd(1)-1,length(traj(nn).heads.satnam),traj(nn).heads.satnam);
          end
	  end
	  
	  
      case 903
          % Megan S agrees that this is the way to store SPO
          if ~isempty(fpp(nn).surfpres_used) && ~isnan(fpp(nn).surfpres_used)
              madd = iNM+1;
              netcdf.putVar(ncid,NPRESID,madd(1)-1,length(fpp(nn).surfpres_used),fpp(nn).surfpres_used);
          end
      end
      
      if ~isempty(madd)
          for jh=1:length(madd)
              netcdf.putVar(ncid,NCYCNUMID,madd(jh)-1,length(fpp(nn).profile_number),fpp(nn).profile_number);
              netcdf.putVar(ncid,NMEASCOID,madd(jh)-1,length(mc),mc);
          end
          iNM = madd(end);
      end
   end          % End of switch mc
   
end       % Loop on every cycle


% History section:
% No history records added at this stage


netcdf.close(ncid);

%### THIS NEEDS TO BE CHANGED WHEN GDAC IS READY TO RECEIVE Rtraj FILES
%### Also then need to change export_argo.m to look for Rtraj rather than traj files.
%   disp('** Not ready to export Rtraj files - so disabled in trajectory_nc.m')
%   logerr(3,['NOT Copying ' fname ' to export/ until GDAC ready for them!']);
%#####
% started data delivery 30/9/2014: AT

  [status,ww] = system(['cp -f ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
  if status~=0
    logerr(3,['Copy of ' fname ' to export/ failed:' ww]);
  end
%###

%-------------------------------------------------------------------------------
