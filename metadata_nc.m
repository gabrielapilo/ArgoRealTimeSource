% METADATA_NC  Create a new Argo metadata file
%
% INPUT: dbdat - master database record for this float
%        fpp   - struct array containing the profiles for this float
%                 (presently get a couple of times from this)
%
% Author:  Jeff Dunn CSIRO/BoM  Aug 2006
%
%  Devolved from matlabnetcdf scripts (Ann Thresher ?)
% 
% CALLS:  generic_fields_nc, netCDF toolbox functions, julian
%
% USAGE: metadata_nc(dbdat,fpp)

% Possible configuration variable names for our floats:
% CONFIG_ArgosTransmissionRepetitionPeriod_SECONDS
% CONFIG_AscentToSurfaceTimeOut_DecimalHour
% CONFIG_CycleTime_DecimalHour
% CONFIG_DescentToMaxPresTimeOut_DecimalHour
% CONFIG_DescentToParkTimeOut_DecimalHour
% CONFIG_Direction_STRING
% CONFIG_DownTime_HOURS
% CONFIG_ParkPressure_dBAR
% CONFIG_ParkTime_DecimalHour
% CONFIG_ProfilePressure_dBAR
% CONFIG_UpTime_HOURS
% CONFIG_AscentAdjustmentToBuoyancy_SECONDS
% CONFIG_AscentDuration_HOURS
% CONFIG_BitMaskMonthsIceDetectionActive_NUMBER
% CONFIG_ClockAscentEndTimeProfile1_HHMM
% CONFIG_ClockAscentEndTimeProfile2_HHMM
% CONFIG_ClockAscentEndTimeProfile3_HHMM
% CONFIG_ClockAscentStart_MINUTES
% CONFIG_ClockPresetStartCycle_FLAG
% CONFIG_ClockStartCycle_MINUTES
% CONFIG_CompensatorHyperRetraction_COUNT
% CONFIG_ConnectionTimeOut_SECONDS
% CONFIG_DeepestPressureAscendingProfile_dBAR
% CONFIG_DeepestPressureDescendingProfile_dBAR
% CONFIG_DepthTable_NUMBER
% CONFIG_DescentSpeed_MM/S
% CONFIG_FirstBuoyancyNudge_COUNT
% CONFIG_FloatReferenceDay_DD
% CONFIG_IceDetection_DegC
% CONFIG_MaxCycles_NUMBER
% CONFIG_MaxSizeEngineeringLogFile_KBYTE
% CONFIG_MeasureBattery_LOGICAL
% CONFIG_MissionPreludeTime_HOURS
% CONFIG_NitrateSampling_FLAG
% CONFIG_ParkSamplingPeriod_HOURS
% CONFIG_PistonFullExtension_COUNT
% CONFIG_PistonFullRetraction_COUNT
% CONFIG_PistonPark_COUNT
% CONFIG_PistonPositionBallast_COUNT
% CONFIG_PistonPositionPressureActivation_COUNT
% CONFIG_PistonProfile_COUNT
% CONFIG_PressureActivationCheckInterval_HOURS
% CONFIG_PressureBladderMax_dBAR
% CONFIG_PressureBladderTarget_dBAR
% CONFIG_PressureStartContinuousProfiling_dBAR
% CONFIG_PrimaryIridiumDialCommand_STRING
% CONFIG_ProfileWhereChangePistonPosition_NUMBER
% CONFIG_PumpActionIntervalDuringAscent_COUNT
% CONFIG_SecondaryIridiumDialCommand_STRING
% CONFIG_SeeksToParkPeriods_COUNT
% CONFIG_SeeksToParkPeriodsIntervals_SECONDS
% CONFIG_SlowAscentPistonAdjustment_COUNTS
% CONFIG_SurfaceTimeOut_DecimalHour
% CONFIG_TargetAscentSpeed_CM/S
% CONFIG_TelemetryRetryInterval_MINUTES
% CONFIG_TimeStartFirstDescentToStartFirstAscent_HOURS
% CONFIG_TripInterval_HOURS
% CONFIG_TriProfileOption_LOGICAL


function metadata_nc(dbdat,fpp)

global ARGO_SYS_PARAM
global THE_ARGO_CAL_DB  ARGO_CAL_WMO
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO


s=getadditionalinfo(dbdat.wmo_id);
mission=get_Argos_config_params(dbdat.wmo_id);
if dbdat.iridium
    try
        [mn,missionI]=getmission_number(dbdat.wmo_id,fpp(end).profile_number,1,dbdat);
    catch
        mn=[];
        missionI=[];
    end
end
if isempty(fpp)
    fpp=new_profile_struct(dbdat);
end
j=0;
if ~dbdat.iridium | (dbdat.iridium & isempty(missionI))
    for i=5:length(mission.data)-1
        if ~isempty(mission.config{i})
            if ~isempty(mission.data{i})
                j=j+1;
            end
        end
    end
    numconfigs=j;
%     numconfigs = sum(cellfun(@isempty,mission.data(6:end)) == 0); ??
%     probably not sophistocated enough - leave the wonderful loop for now
else
    
    numconfigs=length(missionI.names);
    
end
        
if str2num(mission.data{2})~=dbdat.wmo_id
   logerr(2,['METDATA_NC: wrong metadata record returned for WMO ' ...
	  num2str(dbdat.wmo_id)]);
end
    

% if isempty(THE_ARGO_CAL_DB)
   % Must be first call - so load the calibration details database
   getcaldbase;
% end
if isempty(THE_ARGO_O2_CAL_DB)
   % Must be first call - so load the calibration details database
   getO2caldbase;
%    o2db=THE_ARGO_O2_CAL_DB;
end
if isempty(THE_ARGO_BIO_CAL_DB)
   % Must be first call - so load the calibration details database
   getBiocaldbase;
end

ii = find(ARGO_CAL_WMO==dbdat.wmo_id);
if isempty(ii)
   logerr(2,['METDATA_NC: No Calibration DB record for WMO ' ...
	  num2str(dbdat.wmo_id)]);
  return
end
caldb = THE_ARGO_CAL_DB(ii);

if ~caldb.complete
   logerr(2,'METADATA_NC: Incomplete Cal spreadsheet - cannot create _meta.nc');
   return
end

% NOTE - remove the "V3" before this goes into production!

if ispc
fnm = [ARGO_SYS_PARAM.root_dir 'netcdf\' num2str(dbdat.wmo_id) '\' num2str(dbdat.wmo_id)  '_meta.nc'];
dirn = [ARGO_SYS_PARAM.root_dir 'netcdf\' num2str(dbdat.wmo_id) ];
else
fnm = [ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) '/' num2str(dbdat.wmo_id)  '_meta.nc'];
dirn = [ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) ];
end

if ~exist(dirn,'dir')
    system(['mkdir ' dirn]);
end

hist=[];
dc=[];
if exist(fnm,'file')
   try
       ncid=netcdf.open(fnm,'NOWRITE');
       
       hist=netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history');
       dcvarid=netcdf.inqVarID(ncid,'DATE_CREATION');
       dc=netcdf.getVar(ncid,dcvarid);
       
       netcdf.close(ncid)
       
%    hist=attnc(fnm,'global','history');
%    dc=getnc(fnm,'DATE_CREATION');
   end
else
   
end
    ncid=netcdf.create(fnm,'CLOBBER');
    
if isempty(dc) | all(double(dc)==0) | all(double(dc)==32)
    if ispc
       today_str=datestr(now,30); 
       today_str(9)=[];
    else
    [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
    end
%    [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
   dc=today_str(1:14);
end

netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'title','Argo float metadata file' );
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'institution',ARGO_SYS_PARAM.inst);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'source','Argo float');

if ispc
    dn=datestr(now,31);  % or use dn=datestr(datenum(now-(8/24),31)) (adjust for utc time difference)
else
    [st,dn]=system(['date -u +%Y-%m-%d-%H:%M:%S']);
end

dn(11:11)='T';
if isempty(hist)
    dn(20:29)='Z creation';
else
    hist(end+1)=';';
    dn(20:27)='Z update';
end
dnt=[hist dn];

netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history',dnt);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'references','http://www.argodatamgt.org/Documentation');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'comment','');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'user_manual_version','3.1');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'Conventions','Argo-3.1 CF-1.6');

STR2=netcdf.defDim(ncid,'STRING2',2);
STR4=netcdf.defDim(ncid,'STRING4',4);
STR8=netcdf.defDim(ncid,'STRING8',8);
STR16=netcdf.defDim(ncid,'STRING16',16);
STR32=netcdf.defDim(ncid,'STRING32',32);
STR64=netcdf.defDim(ncid,'STRING64',64);
STR128=netcdf.defDim(ncid,'STRING128',128);
STR256=netcdf.defDim(ncid,'STRING256',256);
STR1024=netcdf.defDim(ncid,'STRING1024',1024);
DaTi =netcdf.defDim(ncid,'DATE_TIME',14);

MISSID=netcdf.defDim(ncid,'N_MISSIONS',netcdf.getConstant('NC_UNLIMITED'));
NPOSID=netcdf.defDim(ncid,'N_POSITIONING_SYSTEM',1);
NTRANSID=netcdf.defDim(ncid,'N_TRANS_SYSTEM',1);

NCONFIGID=netcdf.defDim(ncid,'N_CONFIG_PARAM',numconfigs);
NLCONFIGID=netcdf.defDim(ncid,'N_LAUNCH_CONFIG_PARAM',numconfigs);

% will need to add flbb etc here!!!
jj=3;
n_param=3;

if dbdat.oxy
jj=jj+1;
    if ~isfield(fpp,'oxyT_raw')   %  dbdat.subtype==1007 | dbdat.subtype==38 | dbdat.subtype==1008 | ...
% dbdat.subtype==22 | dbdat.subtype==40 
        n_param = n_param+2;
    else
        n_param = n_param+3;
        if isfield(fpp,'t_oxygen_volts')
            n_param = n_param+1;
        end
    end
    if isfield(fpp,'Rphase_raw')
            n_param = n_param+1;
    end
end
if dbdat.flbb
    jj=jj+2;
    n_param=n_param+5;
    if isfield(fpp,'CDOM_raw')
        jj=jj+1;
        n_param=n_param+2;
    end
    if dbdat.subtype == 1026
        jj = jj+4;
    end
    if dbdat.subtype == 1029
        jj = jj+1;
    end
    if dbdat.flbb2
        jj=jj+1;
        n_param=n_param+2;
    end
    
        
end
if dbdat.tmiss
    jj=jj+1;
    n_param = n_param+2;
end
if dbdat.eco
    jj=jj+1;
    n_param = n_param+6;
end
if dbdat.suna
    jj=jj+1;
    n_param=n_param+1;
end
if dbdat.irr
    if dbdat.irr2
       jj=jj+3;
       n_param=n_param+8;
    else
        jj=jj+8;
        n_param=n_param+16;       
    end
end
if dbdat.pH
    jj=jj+1;
    n_param=n_param+3;
end
 
if isfield(fpp,'Tilt')
    n_param=n_param+1;
end

NPARID=netcdf.defDim(ncid,'N_PARAM',n_param);
NSENSORID=netcdf.defDim(ncid,'N_SENSOR',jj);


% Define some fields common to several filetypes

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

NPTTID=netcdf.defVar(ncid,'PTT','NC_CHAR',STR256);
netcdf.putAtt(ncid,NPTTID,'long_name','Transmission identifier (ARGOS, ORBCOMM, etc.)');
netcdf.putAtt(ncid,NPTTID,'_FillValue',' ');

TRANSID=netcdf.defVar(ncid,'TRANS_SYSTEM','NC_CHAR',[STR16,NTRANSID]);
netcdf.putAtt(ncid,TRANSID,'long_name','Telecommunications system used');
netcdf.putAtt(ncid,TRANSID,'_FillValue',' ');

TRANSSYSTID=netcdf.defVar(ncid,'TRANS_SYSTEM_ID','NC_CHAR',[STR32,NTRANSID]);
netcdf.putAtt(ncid,TRANSSYSTID,'long_name','Program identifier used by the transmission system');
netcdf.putAtt(ncid,TRANSSYSTID,'_FillValue',' ');

TRANSFREQID=netcdf.defVar(ncid,'TRANS_FREQUENCY','NC_CHAR',[STR16,NTRANSID]);
netcdf.putAtt(ncid,TRANSFREQID,'long_name','Frequency of transmission from the float');
netcdf.putAtt(ncid,TRANSFREQID,'units','hertz');
netcdf.putAtt(ncid,TRANSFREQID,'_FillValue',' ');

NPOSSYSID=netcdf.defVar(ncid,'POSITIONING_SYSTEM','NC_CHAR',[STR8,NPOSID]);
netcdf.putAtt(ncid,NPOSSYSID,'long_name','Positioning system');
netcdf.putAtt(ncid,NPOSSYSID,'_FillValue',' ');

PLATFAMID=netcdf.defVar(ncid,'PLATFORM_FAMILY','NC_CHAR',STR256);
netcdf.putAtt(ncid,PLATFAMID,'long_name','Category of instrument');
netcdf.putAtt(ncid,PLATFAMID,'conventions','Argo reference table 22');
netcdf.putAtt(ncid,PLATFAMID,'_FillValue',' ');

PLATTYPID=netcdf.defVar(ncid,'PLATFORM_TYPE','NC_CHAR',STR32);
netcdf.putAtt(ncid,PLATTYPID,'long_name','Type of float');
netcdf.putAtt(ncid,PLATTYPID,'conventions','Argo reference table 23');
netcdf.putAtt(ncid,PLATTYPID,'_FillValue',' ');

PLATMAKERID=netcdf.defVar(ncid,'PLATFORM_MAKER','NC_CHAR',STR256);
netcdf.putAtt(ncid,PLATMAKERID,'long_name','Name of the manufacturer');
netcdf.putAtt(ncid,PLATMAKERID,'conventions','Argo reference table 24');
netcdf.putAtt(ncid,PLATMAKERID,'_FillValue',' ');

FIRMVERSID=netcdf.defVar(ncid,'FIRMWARE_VERSION','NC_CHAR',STR32);
netcdf.putAtt(ncid,FIRMVERSID,'long_name','Firmware version for the float');
netcdf.putAtt(ncid,FIRMVERSID,'_FillValue',' ');

MANVERSID=netcdf.defVar(ncid,'MANUAL_VERSION','NC_CHAR',STR16);
netcdf.putAtt(ncid,MANVERSID,'long_name','Manual version for the float');
netcdf.putAtt(ncid,MANVERSID,'_FillValue',' ');
FLOATSERID=netcdf.defVar(ncid,'FLOAT_SERIAL_NO','NC_CHAR',STR32);
netcdf.putAtt(ncid,FLOATSERID,'long_name','Serial number of the float');
netcdf.putAtt(ncid,FLOATSERID,'_FillValue',' ');

STDFMTID=netcdf.defVar(ncid,'STANDARD_FORMAT_ID','NC_CHAR',STR16);
netcdf.putAtt(ncid,STDFMTID,'long_name','Standard format number to describe the data format type for each float');
netcdf.putAtt(ncid,STDFMTID,'_FillValue',' ');

DACFMTID=netcdf.defVar(ncid,'DAC_FORMAT_ID','NC_CHAR',STR16);
netcdf.putAtt(ncid,DACFMTID,'long_name','Format number used by the DAC to describe the data format type for each float');
netcdf.putAtt(ncid,DACFMTID,'_FillValue',' ');

WMOINSTID=netcdf.defVar(ncid,'WMO_INST_TYPE','NC_CHAR',STR4);
netcdf.putAtt(ncid,WMOINSTID,'long_name','Coded instrument type');
netcdf.putAtt(ncid,WMOINSTID,'conventions','Argo reference table 8');
netcdf.putAtt(ncid,WMOINSTID,'_FillValue',' ');

NPRONAID=netcdf.defVar(ncid,'PROJECT_NAME','NC_CHAR',STR64);
netcdf.putAtt(ncid,NPRONAID,'long_name','Program under which the float was deployed');
netcdf.putAtt(ncid,NPRONAID,'_FillValue',' ');

NDACENID=netcdf.defVar(ncid,'DATA_CENTRE','NC_CHAR',STR2);
netcdf.putAtt(ncid,NDACENID,'long_name','Data centre in charge of float real-time processing');
netcdf.putAtt(ncid,NDACENID,'conventions','Argo reference table 4');
netcdf.putAtt(ncid,NDACENID,'_FillValue',' ');

NPINAID=netcdf.defVar(ncid,'PI_NAME','NC_CHAR',STR64);
netcdf.putAtt(ncid,NPINAID,'long_name','Name of the principal investigator');
netcdf.putAtt(ncid,NPINAID,'_FillValue',' ');

ANOMID=netcdf.defVar(ncid,'ANOMALY','NC_CHAR',STR256);
netcdf.putAtt(ncid,ANOMID,'long_name','Describe any anomalies or problems the float may have had');
netcdf.putAtt(ncid,ANOMID,'_FillValue',' ');

BATTYID=netcdf.defVar(ncid,'BATTERY_TYPE','NC_CHAR',STR64);
netcdf.putAtt(ncid,BATTYID,'long_name','Type of battery packs in the float');
netcdf.putAtt(ncid,BATTYID,'_FillValue',' ');
 
BATPKSID=netcdf.defVar(ncid,'BATTERY_PACKS','NC_CHAR',STR64);
netcdf.putAtt(ncid,BATPKSID,'long_name','Configuration of battery packs in the float');
netcdf.putAtt(ncid,BATPKSID,'_FillValue',' ');

CONTBDID=netcdf.defVar(ncid,'CONTROLLER_BOARD_TYPE_PRIMARY','NC_CHAR',STR32);
netcdf.putAtt(ncid,CONTBDID,'long_name','Type of primary controller board');
netcdf.putAtt(ncid,CONTBDID,'_FillValue',' ');

%  we only have one controller board on our floats:
SECCONTBDID=netcdf.defVar(ncid,'CONTROLLER_BOARD_TYPE_SECONDARY','NC_CHAR',STR32);
netcdf.putAtt(ncid,SECCONTBDID,'long_name','Type of secondary controller board');
netcdf.putAtt(ncid,SECCONTBDID,'_FillValue',' ');

CONTBDSERID=netcdf.defVar(ncid,'CONTROLLER_BOARD_SERIAL_NO_PRIMARY','NC_CHAR',STR32);
netcdf.putAtt(ncid,CONTBDSERID,'long_name','Serial number of the primary controller board');
netcdf.putAtt(ncid,CONTBDSERID,'_FillValue',' ');

%  we only have one controller board on our floats:
SECCONTBDSERID=netcdf.defVar(ncid,'CONTROLLER_BOARD_SERIAL_NO_SECONDARY','NC_CHAR',STR32);
netcdf.putAtt(ncid,SECCONTBDSERID,'long_name','Serial number of the secondary controller board');
netcdf.putAtt(ncid,SECCONTBDSERID,'_FillValue',' ');

SPECFEATID=netcdf.defVar(ncid,'SPECIAL_FEATURES','NC_CHAR',STR1024);
netcdf.putAtt(ncid,SPECFEATID,'long_name','Extra features of the float (algorithms, compressee etc.)');
netcdf.putAtt(ncid,SPECFEATID,'_FillValue',' ');

OWNERID=netcdf.defVar(ncid,'FLOAT_OWNER','NC_CHAR',STR64);
netcdf.putAtt(ncid,OWNERID,'long_name','Float owner');
netcdf.putAtt(ncid,OWNERID,'_FillValue',' ');

OPERATORID=netcdf.defVar(ncid,'OPERATING_INSTITUTION','NC_CHAR',STR64);
netcdf.putAtt(ncid,OPERATORID,'long_name','Operating institution of the float');
netcdf.putAtt(ncid,OPERATORID,'_FillValue',' ');

CUSTOMID=netcdf.defVar(ncid,'CUSTOMISATION','NC_CHAR',STR1024);
netcdf.putAtt(ncid,CUSTOMID,'long_name','Float customisation, i.e. (institution and modifications)');
netcdf.putAtt(ncid,CUSTOMID,'_FillValue',' ');

LAUNCHDATEID=netcdf.defVar(ncid,'LAUNCH_DATE','NC_CHAR',DaTi);
netcdf.putAtt(ncid,LAUNCHDATEID,'long_name','Date (UTC) of the deployment');
netcdf.putAtt(ncid,LAUNCHDATEID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,LAUNCHDATEID,'_FillValue',' ');

LAUNCHLATID=netcdf.defVar(ncid,'LAUNCH_LATITUDE','NC_DOUBLE',[]);
netcdf.putAtt(ncid,LAUNCHLATID,'long_name','Latitude of the float when deployed');
netcdf.putAtt(ncid,LAUNCHLATID,'units','degree_north');
netcdf.putAtt(ncid,LAUNCHLATID,'_FillValue',double(99999.));
netcdf.putAtt(ncid,LAUNCHLATID,'valid_min',double(-90.));
netcdf.putAtt(ncid,LAUNCHLATID,'valid_max',double(90.));

LAUNCHLONID=netcdf.defVar(ncid,'LAUNCH_LONGITUDE','NC_DOUBLE',[]);
netcdf.putAtt(ncid,LAUNCHLONID,'long_name','Longitude of the float when deployed');
netcdf.putAtt(ncid,LAUNCHLONID,'units','degree_east');
netcdf.putAtt(ncid,LAUNCHLONID,'_FillValue',double(99999.));
netcdf.putAtt(ncid,LAUNCHLONID,'valid_min',double(-180.));
netcdf.putAtt(ncid,LAUNCHLONID,'valid_max',double(180.));

LAUNCHQCID=netcdf.defVar(ncid,'LAUNCH_QC','NC_CHAR',[]);
netcdf.putAtt(ncid,LAUNCHQCID,'long_name','Quality on launch date, time and location');
netcdf.putAtt(ncid,LAUNCHQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,LAUNCHQCID,'_FillValue',' ');

STARTDATEID=netcdf.defVar(ncid,'START_DATE','NC_CHAR',DaTi);
netcdf.putAtt(ncid,STARTDATEID,'long_name','Date (UTC) of the first descent of the float');
netcdf.putAtt(ncid,STARTDATEID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,STARTDATEID,'_FillValue',' ');

STARTDATEQCID=netcdf.defVar(ncid,'START_DATE_QC','NC_CHAR',[]);
netcdf.putAtt(ncid,STARTDATEQCID,'long_name','Quality on start date');
netcdf.putAtt(ncid,STARTDATEQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,STARTDATEQCID,'_FillValue',' ');

% nc{'START_DATE_QC'}=ncchar;
% nc{'START_DATE_QC'}.long_name='Quality on start date';
% nc{'START_DATE_QC'}.conventions='Argo reference table 2';
% nc{'START_DATE_QC'}.FillValue_=' ';

STARTUPDATEID=netcdf.defVar(ncid,'STARTUP_DATE','NC_CHAR',DaTi);
netcdf.putAtt(ncid,STARTUPDATEID,'long_name','Date (UTC) of the activation of the float');
netcdf.putAtt(ncid,STARTUPDATEID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,STARTUPDATEID,'_FillValue',' ');

STARTUPDATEQCID=netcdf.defVar(ncid,'STARTUP_DATE_QC','NC_CHAR',[]);
netcdf.putAtt(ncid,STARTUPDATEQCID,'long_name','Quality on startup date');
netcdf.putAtt(ncid,STARTUPDATEQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,STARTUPDATEQCID,'_FillValue',' ');

DEPPLATID=netcdf.defVar(ncid,'DEPLOYMENT_PLATFORM','NC_CHAR',STR32);
netcdf.putAtt(ncid,DEPPLATID,'long_name','Identifier of the deployment platform');
netcdf.putAtt(ncid,DEPPLATID,'_FillValue',' ');

DEPCRUISEID=netcdf.defVar(ncid,'DEPLOYMENT_CRUISE_ID','NC_CHAR',STR32);
netcdf.putAtt(ncid,DEPCRUISEID,'long_name','Identification number or reference number of the cruise used to deploy the float');
netcdf.putAtt(ncid,DEPCRUISEID,'_FillValue',' ');

DEPREFSTNID=netcdf.defVar(ncid,'DEPLOYMENT_REFERENCE_STATION_ID','NC_CHAR',STR256);
netcdf.putAtt(ncid,DEPREFSTNID,'long_name','Identifier or reference number of co-located stations used to verify the first profile');
netcdf.putAtt(ncid,DEPREFSTNID,'_FillValue',' ');

ENDMISSDATEID=netcdf.defVar(ncid,'END_MISSION_DATE','NC_CHAR',DaTi);
netcdf.putAtt(ncid,ENDMISSDATEID,'long_name','Date (UTC) of the end of mission of the float');
netcdf.putAtt(ncid,ENDMISSDATEID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,ENDMISSDATEID,'_FillValue',' ');

ENDMISSSTATID=netcdf.defVar(ncid,'END_MISSION_STATUS','NC_CHAR',[]);
netcdf.putAtt(ncid,ENDMISSSTATID,'long_name','Status of the end of mission of the float');
netcdf.putAtt(ncid,ENDMISSSTATID,'conventions','T:No more transmission received, R:Retrieved');
netcdf.putAtt(ncid,ENDMISSSTATID,'_FillValue',' ');

% now add the new mission configuration fields!

LAUNCONFIGNID=netcdf.defVar(ncid,'LAUNCH_CONFIG_PARAMETER_NAME','NC_CHAR',[STR128,NLCONFIGID]);
netcdf.putAtt(ncid,LAUNCONFIGNID,'long_name','Name of configuration parameter at launch');
netcdf.putAtt(ncid,LAUNCONFIGNID,'_FillValue',' ');

LAUNCONFIGVID=netcdf.defVar(ncid,'LAUNCH_CONFIG_PARAMETER_VALUE','NC_DOUBLE',NLCONFIGID);
netcdf.putAtt(ncid,LAUNCONFIGVID,'long_name','Value of configuration parameter at launch');
netcdf.putAtt(ncid,LAUNCONFIGVID,'_FillValue',double(99999.));

CONFIGNID=netcdf.defVar(ncid,'CONFIG_PARAMETER_NAME','NC_CHAR',[STR128,NCONFIGID]);
netcdf.putAtt(ncid,CONFIGNID,'long_name','Name of configuration parameter');
netcdf.putAtt(ncid,CONFIGNID,'_FillValue',' ');

CONFIGVID=netcdf.defVar(ncid,'CONFIG_PARAMETER_VALUE','NC_DOUBLE',[NCONFIGID,MISSID]);
netcdf.putAtt(ncid,CONFIGVID,'long_name','Value of configuration parameter');
netcdf.putAtt(ncid,CONFIGVID,'_FillValue',double(99999.));

CONFIGMISSID=netcdf.defVar(ncid,'CONFIG_MISSION_NUMBER','NC_INT',MISSID);
netcdf.putAtt(ncid,CONFIGMISSID,'long_name','Unique number denoting the missions performed by the float');
netcdf.putAtt(ncid,CONFIGMISSID,'conventions','1...N, 1 : first complete mission');
netcdf.putAtt(ncid,CONFIGMISSID,'_FillValue',int32(99999));

CONFIGMISSCCID=netcdf.defVar(ncid,'CONFIG_MISSION_COMMENT','NC_CHAR',[STR256,MISSID]);
netcdf.putAtt(ncid,CONFIGMISSCCID,'long_name','Comment on configuration');
netcdf.putAtt(ncid,CONFIGMISSCCID,'_FillValue',' ');

% sensor information section

SENSORID=netcdf.defVar(ncid,'SENSOR','NC_CHAR',[STR32,NSENSORID]);
netcdf.putAtt(ncid,SENSORID,'long_name','Name of the sensor mounted on the float');
netcdf.putAtt(ncid,SENSORID,'conventions','Argo reference table 25');
netcdf.putAtt(ncid,SENSORID,'_FillValue',' ');

SENSORMAKERID=netcdf.defVar(ncid,'SENSOR_MAKER','NC_CHAR',[STR256,NSENSORID]);
netcdf.putAtt(ncid,SENSORMAKERID,'long_name','Name of the sensor manufacturer');
netcdf.putAtt(ncid,SENSORMAKERID,'conventions','Argo reference table 26');
netcdf.putAtt(ncid,SENSORMAKERID,'_FillValue',' ');


SENSORMODELID=netcdf.defVar(ncid,'SENSOR_MODEL','NC_CHAR',[STR256,NSENSORID]);
netcdf.putAtt(ncid,SENSORMODELID,'long_name','Type of sensor');
netcdf.putAtt(ncid,SENSORMODELID,'conventions','Argo reference table 27');
netcdf.putAtt(ncid,SENSORMODELID,'_FillValue',' ');

SENSORSERNOID=netcdf.defVar(ncid,'SENSOR_SERIAL_NO','NC_CHAR',[STR16,NSENSORID]);
netcdf.putAtt(ncid,SENSORSERNOID,'long_name','Serial number of the sensor');
netcdf.putAtt(ncid,SENSORSERNOID,'_FillValue',' ');

NPARAID=netcdf.defVar(ncid,'PARAMETER','NC_CHAR',[STR64,NPARID]);
netcdf.putAtt(ncid,NPARAID,'long_name','Name of parameter computed from float measurements');
netcdf.putAtt(ncid,NPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NPARAID,'_FillValue',' ');

NPARSENSID=netcdf.defVar(ncid,'PARAMETER_SENSOR','NC_CHAR',[STR128,NPARID]);
netcdf.putAtt(ncid,NPARSENSID,'long_name','Name of the sensor that measures this parameter');
netcdf.putAtt(ncid,NPARSENSID,'conventions','Argo reference table 25');
netcdf.putAtt(ncid,NPARSENSID,'_FillValue',' ');

NPARUNITID=netcdf.defVar(ncid,'PARAMETER_UNITS','NC_CHAR',[STR32,NPARID]);
netcdf.putAtt(ncid,NPARUNITID,'long_name','Units of accuracy and resolution of the parameter');
netcdf.putAtt(ncid,NPARUNITID,'_FillValue',' ');

NPARACCID=netcdf.defVar(ncid,'PARAMETER_ACCURACY','NC_CHAR',[STR32,NPARID]);
netcdf.putAtt(ncid,NPARACCID,'long_name','Accuracy of the parameter');
netcdf.putAtt(ncid,NPARACCID,'_FillValue',' ');

NPARRESID=netcdf.defVar(ncid,'PARAMETER_RESOLUTION','NC_CHAR',[STR32,NPARID]);
netcdf.putAtt(ncid,NPARRESID','long_name','Resolution of the parameter');
netcdf.putAtt(ncid,NPARRESID,'_FillValue',' ');

PREDEPCALEQNID=netcdf.defVar(ncid,'PREDEPLOYMENT_CALIB_EQUATION','NC_CHAR',[STR1024,NPARID]);
netcdf.putAtt(ncid,PREDEPCALEQNID,'long_name','Calibration equation for this parameter');
netcdf.putAtt(ncid,PREDEPCALEQNID,'_FillValue',' ');

PREDEPCALCOEFFID=netcdf.defVar(ncid,'PREDEPLOYMENT_CALIB_COEFFICIENT','NC_CHAR',[STR1024,NPARID]);
netcdf.putAtt(ncid,PREDEPCALCOEFFID,'long_name','Calibration coefficients for this equation');
netcdf.putAtt(ncid,PREDEPCALCOEFFID,'_FillValue',' ');

PREDEPCALCOMMID=netcdf.defVar(ncid,'PREDEPLOYMENT_CALIB_COMMENT','NC_CHAR',[STR1024,NPARID]);
netcdf.putAtt(ncid,PREDEPCALCOMMID,'long_name','Comment applying to this parameter calibration');
netcdf.putAtt(ncid,PREDEPCALCOMMID,'_FillValue',' ');

% Done with defining everything - Now write the data! --------------------------

% Fill the fields common to several filetypes - eliminated in conversion to
% version R2013
% note - this is no longer a function:

netcdf.endDef(ncid);

typ=2;
stage=2;
   
aa = num2str(dbdat.wmo_id);

netcdf.putVar(ncid,NPLANUID,0,length(aa),aa);
netcdf.putVar(ncid,NDACENID,0,length(ARGO_SYS_PARAM.datacentre),ARGO_SYS_PARAM.datacentre);

if ispc
    today_str=datestr(now,31);  % or use dn=datestr(datenum(now-(8/24),31)) (adjust for utc time difference)
else
    [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
end

today_str=today_str(1:14);

%     today_str = sprintf('%04d%02d%02d%02d%02d%02d',fix(clock));

netcdf.putVar(ncid,NDAUPID,0,14,today_str(1:14));

if ~isempty(strfind(dbdat.owner,'COOE'))
    netcdf.putVar(ncid,NPRONAID,0,length('Cooperative Ocean Observing Exp'),'Cooperative Ocean Observing Exp');
else
    aa=ARGO_SYS_PARAM.Proj;
    netcdf.putVar(ncid,NPRONAID,0,length(aa),aa);  %'Argo AUSTRALIA';
end

if isfield(fpp,'PI')
    netcdf.putVar(ncid,NPINAID,0,length(fpp(1).PI),fpp(1).PI);
else
    netcdf.putVar(ncid,NPINAID,0,length(dbdat.PI),dbdat.PI) ;  
end

netcdf.putVar(ncid,WMOINSTID,0,length(dbdat.wmo_inst_type),dbdat.wmo_inst_type );

netcdf.putVar(ncid,NDATYID,0,length('Argo meta-data'),'Argo meta-data');
netcdf.putVar(ncid,NFMVRID,0,length('3.1'),'3.1');
netcdf.putVar(ncid,NHDVRID,0,length(' 1.2'),' 1.2');
netcdf.putVar(ncid,NDACRID,0,length(dc),dc);

b = num2str(dbdat.argos_id);

netcdf.putVar(ncid,NPTTID,0,length(b),b);

if(dbdat.iridium) 
    netcdf.putVar(ncid,TRANSID,[0,0],[7,1],'IRIDIUM');
    netcdf.putVar(ncid,TRANSFREQID,[0,0],[3,1],'n/a');
else
    netcdf.putVar(ncid,TRANSID,[0,0],[5,1],'ARGOS');
    netcdf.putVar(ncid,TRANSFREQID,[0,0],[13,1],'401.65 x 10^6');
end

if ~dbdat.iridium
    aa=ARGO_SYS_PARAM.our_id;
    netcdf.putVar(ncid,TRANSSYSTID,[0,0],[length(aa),1],aa);   
else
    netcdf.putVar(ncid,TRANSSYSTID,[0,0],[3,1],'n/a');
end
if dbdat.iridium
    netcdf.putVar(ncid,NPOSSYSID,[0,0],[3,1],'GPS');   
else
    netcdf.putVar(ncid,NPOSSYSID,[0,0],[5,1],'ARGOS');   
end

netcdf.putVar(ncid,PLATFAMID,0,5,'FLOAT');

if dbdat.maker==1
    netcdf.putVar(ncid,PLATMAKERID,0,3,'WRC');
    if dbdat.subtype==0
        netcdf.putVar(ncid,PLATTYPID,0,6,'PALACE');
    else
        netcdf.putVar(ncid,PLATTYPID,0,4,'APEX');
    end
   
% ======== Modified by uday to accomodate PROVOR and ARVOR type floats =========
elseif dbdat.maker==2
   if dbdat.subtype==3 | dbdat.subtype==1
       netcdf.putVar(ncid,PLATMAKERID,0,8,'METOCEAN');
       netcdf.putVar(ncid,PLATTYPID,0,9,'PROVOR_MT');
   else
       if dbdat.subtype==4 | dbdat.subtype==5
           netcdf.putVar(ncid,PLATMAKERID,0,3,'NKE');
           if dbdat.wmo_inst_type=='844'
               netcdf.putVar(ncid,PLATTYPID,0,9,'PROVOR_II');
           else
               netcdf.putVar(ncid,PLATTYPID,0,5,'ARVOR');
           end
       end
   end
 % ======== end of uday modification ==============
 
elseif dbdat.maker==3
    netcdf.putVar(ncid,PLATMAKERID,0,4,'WHOI');
    netcdf.putVar(ncid,PLATTYPID,0,6,'SOLO_W');

elseif dbdat.maker==4
    netcdf.putVar(ncid,PLATMAKERID,0,3,'SBE');
    netcdf.putVar(ncid,PLATTYPID,0,7,'NAVIS_A');

elseif dbdat.maker==5
    netcdf.putVar(ncid,PLATMAKERID,0,3,'MRV');
    netcdf.putVar(ncid,PLATTYPID,0,3,'S2A');

end

aa=mission.data{29};
if isempty(aa)
    aa='n/a';
end
if length(aa)>32
    aa=aa(1:32);
end

if ~isempty(aa)
     netcdf.putVar(ncid,FIRMVERSID,0,length(aa),aa);
end
aa=num2str(s.mfg_id);
     netcdf.putVar(ncid,FLOATSERID,0,length(aa),aa);

aa=mission.data{33};
     netcdf.putVar(ncid,STDFMTID,0,length(aa),aa);

aa=mission.data{28};
if isempty(aa)
    aa='n/a';
end
if ~isempty(aa)
     netcdf.putVar(ncid,MANVERSID,0,length(aa),aa);
end

aa=num2str(dbdat.subtype);

netcdf.putVar(ncid,DACFMTID,0,length(aa),aa);

%DEV Need a comments database for this sort of thing...
if dbdat.wmo_id==53548
    aa='This float has a severe pressure and/or salinity drift - the data cannot be reliably calibrated at this time';
     netcdf.putVar(ncid,ANOMID,0,length(aa),aa);
end

aa=s.Battery_Configuration;
netcdf.putVar(ncid,BATPKSID,0,length(aa),aa);
li=strfind(aa,'Li');
alk=strfind(aa,'Alk');
if ~isempty(li) & ~isempty(alk)
    aa='Alkaline and Lithium';
    netcdf.putVar(ncid,BATTYID,0,length(aa),aa);
elseif ~isempty(li) & isempty(alk)
    aa='Lithium';
    netcdf.putVar(ncid,BATTYID,0,length(aa),aa);
elseif isempty(li) & ~isempty(alk)
    aa='Alkaline';
    netcdf.putVar(ncid,BATTYID,0,length(aa),aa);
else
    aa='Alkaline';
    netcdf.putVar(ncid,BATTYID,0,length(aa),aa);
end


if ~isempty(dbdat.boardtype)
    if dbdat.boardtype==8
        aa='APF8';
    elseif dbdat.boardtype==9
        aa='APF9';
    elseif dbdat.boardtype==11
        aa='APF11';
    else
        aa='n/a';
    end
else
        aa='n/a';
end
netcdf.putVar(ncid,CONTBDID,0,length(aa),aa);

aa=[];
if dbdat.ice
    aa=[aa 'Ice Sensing Algorithm '];
end

if ~isempty(aa)
    netcdf.putVar(ncid,SPECFEATID,0,length(aa),aa);
end

aa=dbdat.controlboardnumstring;
if length(aa)==0;aa='n/a';end
netcdf.putVar(ncid,CONTBDSERID,0,length(aa),aa);
    
aa=upper(dbdat.owner);
if ~isempty(aa)
    netcdf.putVar(ncid,OWNERID,0,length(aa),aa);
end

aa=ARGO_SYS_PARAM.inst;
netcdf.putVar(ncid,OPERATORID,0,length(aa),aa);
netcdf.putVar(ncid,LAUNCHDATEID,0,14,dbdat.launchdate);
netcdf.putVar(ncid,LAUNCHLATID,dbdat.launch_lat);

if(dbdat.launch_lon>180.)
    dblon=dbdat.launch_lon-360;
else
    dblon=dbdat.launch_lon;

end
netcdf.putVar(ncid,LAUNCHLONID,dblon);
netcdf.putVar(ncid,LAUNCHQCID,'1');

%DEV ***this is probably not right... should be in a database anyway,
% especially as I don't want profile(1) being a dummy containing launch info.
if ~isempty(fpp)
    if ~isempty(fpp(1).datetime_vec)
       aa = sprintf('%04d%02d%02d%02d%02d%02d',fpp(1).datetime_vec(1,:));
    else
        aa=dbdat.launchdate;
    end
else
        aa=dbdat.launchdate;
end
netcdf.putVar(ncid,STARTDATEID,0,length(aa),aa);
netcdf.putVar(ncid,STARTDATEQCID,'1');

if ~isempty(dbdat.launch_platform);
    aa=dbdat.launch_platform;
    netcdf.putVar(ncid,DEPPLATID,0,length(aa),aa);
end

netcdf.putVar(ncid,SENSORID,[0,0],[8,1],'CTD_TEMP');
netcdf.putVar(ncid,SENSORID,[0,1],[8,1],'CTD_CNDC');
netcdf.putVar(ncid,SENSORID,[0,2],[8,1],'CTD_PRES');

if dbdat.RBR
    netcdf.putVar(ncid,SENSORMAKERID,[0,0],[3,1],'RBR');
    netcdf.putVar(ncid,SENSORMAKERID,[0,1],[3,1],'RBR');
    netcdf.putVar(ncid,SENSORMAKERID,[0,2],[3,1],'RBR');
else
    netcdf.putVar(ncid,SENSORMAKERID,[0,0],[3,1],'SBE');
    netcdf.putVar(ncid,SENSORMAKERID,[0,1],[3,1],'SBE');
    netcdf.putVar(ncid,SENSORMAKERID,[0,2],[length(dbdat.pressure_sensor),1],dbdat.pressure_sensor);
end
nn = length(s.CTDtype);
netcdf.putVar(ncid,SENSORMODELID,[0,0],[nn,1],s.CTDtype);
netcdf.putVar(ncid,SENSORMODELID,[0,1],[nn,1],s.CTDtype);
netcdf.putVar(ncid,SENSORMODELID,[0,2],[length(dbdat.pressure_sensor),1],dbdat.pressure_sensor);

sbeSN = num2str(dbdat.sbe_snum);
netcdf.putVar(ncid,SENSORSERNOID,[0,0],[length(sbeSN),1],sbeSN);
netcdf.putVar(ncid,SENSORSERNOID,[0,1],[length(sbeSN),1],sbeSN);
   
aa = num2str(dbdat.psens_snum);
netcdf.putVar(ncid,SENSORSERNOID,[0,2],[length(aa),1],aa);

jj=3;
if dbdat.oxy
    jj=jj+1;
    if(strfind(s.Oxygen.mfg,'eabird'))
    netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[3,1],'SBE');
        if strfind(s.Oxygen.ModelNo,'IDO');
            osensor='IDO_DOXY';
        else
            osensor='OPTODE_DOXY';
        end
    else
     netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[8,1],'AANDERAA');
        osensor='OPTODE_DOXY';
    end

     netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(osensor),1],osensor);
    aa=s.Oxygen.ModelNo;
    netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
    aa=s.Oxygen.SerialNo;
    netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
end

if dbdat.flbb
    if dbdat.subtype < 1021
        jj=jj+1;
        aa=s.FLBB.mfg;
        netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
        aa='BACKSCATTERINGMETER_BBP700';
        netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
        aa=s.FLBB.ModelNo;
        netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
        aa=s.FLBB.SerialNo;
        netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
        jj=jj+1;
        aa=s.FLBB.mfg;
        netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
        aa='FLUOROMETER_CHLA';
        netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
        aa=s.FLBB.ModelNo;
        netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
        aa=s.FLBB.SerialNo;
        netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
    end
    
    if isfield(fpp,'CDOM_raw')     % dbdat.subtype==1006  %cdom sensor
        jj=jj+1;
        aa=s.FLBB.mfg;
        netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
        aa='FLUOROMETER_CDOM';
        netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
        aa=s.FLBB.ModelNo;
        netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
        aa=s.FLBB.SerialNo;
        netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
    end
    
    if dbdat.subtype > 1025 & dbdat.subtype < 1030  | dbdat.subtype == 1031%MCOMS wetlabs types NHM floats
        if dbdat.subtype == 1026 %BB3 eco model (not in spreadsheet) with MCOMS FLBBCD (in spreadsheet)
            jj=jj+1;
            aa=s.FLBB.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='BACKSCATTERINGMETER_BBP700';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa='ECO_BB3';
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.Eco.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
            jj=jj+1;
            aa=s.Eco.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='BACKSCATTERINGMETER_BBP532';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa='ECO_BB3';
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.Eco.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
            jj=jj+1;
            aa=s.Eco.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='BACKSCATTERINGMETER_BBP470';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa='ECO_BB3';
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.Eco.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
            jj=jj+1;
            aa=s.Eco.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='FLUOROMETER_CHLA';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
            jj=jj+1;
            aa=s.FLBB.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='FLUOROMETER_CDOM';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
            jj=jj+1;
            aa=s.FLBB.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='BACKSCATTERINGMETER_BBP700';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
        end
        if dbdat.subtype > 1026 & dbdat.subtype < 1030 | dbdat.subtype == 1031 %MCOMS flbb2
            jj=jj+1;
            aa=s.FLBB.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='FLUOROMETER_CHLA';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
            jj=jj+1;
            aa=s.FLBB.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='BACKSCATTERINGMETER_BBP700';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
            jj=jj+1;
            aa=s.FLBB.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa='BACKSCATTERINGMETER_BBP532';
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.FLBB.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
        end
    end
end

if dbdat.tmiss
    jj=jj+1;
    aa=s.Transmissometer.mfg;
    netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
    aa='TRANSMISSOMETER_CP';
    netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
    aa=s.Transmissometer.ModelNo;
    netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
    aa=s.Transmissometer.SerialNo;
    netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
end

if dbdat.eco
    jj=jj+1;
    aa=s.Eco.mfg;
    netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP700';
    netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
    aa=s.Eco.ModelNo;
    netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
    aa=s.Eco.SerialNo;
    netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
end

if dbdat.suna
    jj=jj+1;
    aa=s.SUNA.mfg;
    netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
    aa='SPECTROPHOTOMETER_NITRATE';
    netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
    aa=s.SUNA.ModelNo;
    netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
    aa=s.SUNA.SerialNo;
    netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
end

if dbdat.irr
    %OCR540_ICSW, down irradiance at selcted wavelengths
    pars = {'RADIOMETER_DOWN_IRR412','RADIOMETER_DOWN_IRR490'};
    for mm = 1:length(pars)
        jj=jj+1;
        aa=s.Irr.mfg;
        netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
        aa=pars{mm};
        netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
        aa=s.Irr.ModelNo;
        netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
        aa=s.Irr.SerialNo;
        netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
    end
    
    if dbdat.irr2
    %OCR540_ICSW, down irradiance at selcted wavelengths, and down par        
        pars = {'RADIOMETER_DOWN_IRR380','RADIOMETER_PAR'};
        for mm = 1:length(pars)
            jj=jj+1;
            aa=s.Irr.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa= pars{mm};
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.Irr.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.Irr.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
        end
    end
    if ~dbdat.irr2
        %also has OCR540_R10W, up radiance at selcted wavelengths
        pars = {'RADIOMETER_DOWN_IRR443','RADIOMETER_DOWN_IRR555'};
        for mm = 1:length(pars)
            jj=jj+1;
            aa=s.Irr.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa=pars{mm};
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.Irr.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.Irr.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
        end
        pars = {'RADIOMETER_UP_RAD412','RADIOMETER_UP_RAD443', ...
            'RADIOMETER_UP_RAD490','RADIOMETER_UP_RAD555'};
        for mm = 1:length(pars)
            jj=jj+1;
            aa=s.Rad.mfg;
            netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
            aa=pars{mm};
            netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
            aa=s.Rad.ModelNo;
            netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
            aa=s.Rad.SerialNo;
            netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
        end
    end
end

if dbdat.pH
    jj=jj+1;
    aa=s.pH.mfg;
    netcdf.putVar(ncid,SENSORMAKERID,[0,jj-1],[length(aa),1],aa);
    aa='TRANSISTOR_PH';
    netcdf.putVar(ncid,SENSORID,[0,jj-1],[length(aa),1],aa);
    aa=s.pH.ModelNo;
    netcdf.putVar(ncid,SENSORMODELID,[0,jj-1],[length(aa),1],aa);
    aa=s.pH.SerialNo;
    netcdf.putVar(ncid,SENSORSERNOID,[0,jj-1],[length(aa),1],aa);
end


netcdf.putVar(ncid,NPARAID,[0,0],[4,1],'TEMP');
netcdf.putVar(ncid,NPARAID,[0,1],[4,1],'PSAL');
netcdf.putVar(ncid,NPARAID,[0,2],[4,1],'PRES');

netcdf.putVar(ncid,NPARSENSID,[0,0],[8,1],'CTD_TEMP');
netcdf.putVar(ncid,NPARSENSID,[0,1],[8,1],'CTD_CNDC');
netcdf.putVar(ncid,NPARSENSID,[0,2],[8,1],'CTD_PRES');

netcdf.putVar(ncid,NPARUNITID,[0,0],[5,1],'deg C');

aa= num2str(caldb.temp_acc);
netcdf.putVar(ncid,NPARACCID,[0,0],[length(aa),1],aa);
aa= num2str(caldb.temp_res);
netcdf.putVar(ncid,NPARRESID,[0,0],[length(aa),1],aa);

netcdf.putVar(ncid,NPARUNITID,[0,1],[3,1],'psu');
aa=num2str(caldb.cond_acc);
netcdf.putVar(ncid,NPARACCID,[0,1],[length(aa),1],aa);
aa= num2str(caldb.cond_res);
netcdf.putVar(ncid,NPARRESID,[0,1],[length(aa),1],aa);

netcdf.putVar(ncid,NPARUNITID,[0,2],[8,1],'decibars');
aa=num2str(caldb.pres_acc);
netcdf.putVar(ncid,NPARACCID,[0,2],[length(aa),1],aa);
aa= num2str(caldb.pres_res);
netcdf.putVar(ncid,NPARRESID,[0,2],[length(aa),1],aa);


jj=3;
if dbdat.oxy
    jj=jj+1;
    aa='DOXY';
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
    aa='micromole/kg';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    aa='5';
    netcdf.putVar(ncid,NPARACCID,[0,jj-1],[length(aa),1],aa);
    aa='0.4';
    netcdf.putVar(ncid,NPARRESID,[0,jj-1],[length(aa),1],aa);
    
    % add extra fields here depending on whether they are required:
    if isfield(fpp,'oxyT_raw')
        jj=jj+1;
        aa='TEMP_DOXY';
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
        aa='degree_Celsius';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);      
    end
    
    if isfield(fpp,'oxy_umolar')  %(dbdat.subtype==32 || dbdat.subtype==35 || dbdat.subtype==31 || dbdat.subtype==40)
        jj=jj+1;
        aa='MOLAR_DOXY';
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
        aa='micromole/litre';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
    
    if  isfield(fpp,'SBEOxyfreq_raw')  %(dbdat.subtype==38 || dbdat.subtype==22 || dbdat.subtype==1007 || dbdat.subtype==1008)
        jj=jj+1;
        aa='FREQUENCY_DOXY';
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
        aa='hertz';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
    
    if isfield(fpp,'Bphase_raw')   %dbdat.subtype==1002 || dbdat.subtype==1012  || dbdat.subtype==1006 || dbdat.subtype==1020
        jj=jj+1;
        
        aa='BPHASE_DOXY';
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
        aa='degree';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
    
    if isfield(fpp,'O2phase_raw')   %dbdat.subtype==1017
        jj=jj+1;
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
        aa='PHASE_DELAY_DOXY';
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='microsecond';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        if isfield(fpp,'t_oxygen_volts')
            jj=jj+1;
            netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
            aa='TEMP_VOLTAGE_DOXY';
            netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
            aa='volts';
            netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        end
     end

    if isfield(fpp,'Tphase_raw')  %dbdat.subtype==1022 % added by uday for APEX-BioArgo floats
        jj=jj+1;
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
        aa='TPHASE_DOXY';
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='degree';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
    
    if isfield(fpp,'Rphase_raw')  %dbdat.subtype==1022 % added by uday for APEX-BioArgo floats
        jj=jj+1;
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(osensor),1],osensor);
        aa='RPHASE_DOXY';
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='degree';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
    
end

% note -  added flbb and transmissometer data:
if dbdat.flbb
    jj=jj+1;
    aa='CHLA'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='FLUOROMETER_CHLA';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='mg/m3';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='FLUORESCENCE_CHLA';   %raw
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='FLUOROMETER_CHLA';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='count';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='BBP700'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP700';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='m-1';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='BETA_BACKSCATTERING700';  %raw
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP700';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='count';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='TEMP_CPU_CHLA';  %raw
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP700';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='count';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    if dbdat.flbb2
        jj=jj+1;
        aa='BBP532'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='BACKSCATTERINGMETER_BBP532';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='m-1';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='BETA_BACKSCATTERING532';  %raw
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='BACKSCATTERINGMETER_BBP532';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
    
    if isfield(fpp,'CDOM_raw')  %dbdat.subtype==1006
        jj=jj+1;
        aa='FLUORESCENCE_CDOM';  %raw
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='FLUOROMETER_CDOM';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        jj=jj+1;
        aa='CDOM'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='FLUOROMETER_CDOM';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='ppb';
            netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
end

if dbdat.tmiss
    jj=jj+1;
    aa='TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660';  %raw
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='TRANSMISSOMETER_CP';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='count';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    jj=jj+1;
    aa='CP660'; %derived - orig:PARTICLE_BEAM_ATTENUATION
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='TRANSMISSOMETER_CP';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='m-1';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
end

if dbdat.eco
    if dbdat.flbb
        sensor='BACKSCATTERINGMETER_BBP700_2';
        parameter700='BBP700_2';
        praw='BETA_BACKSCATTERING700_2';
    else
        sensor='BACKSCATTERINGMETER_BBP700';
        parameter700='BBP700';
        praw='BETA_BACKSCATTERING700';
    end
    jj=jj+1;
    aa=parameter700; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa=sensor;
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='m-1';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa=praw;  %raw
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa=sensor;
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='count';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='BBP532'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP532';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='m-1';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='BETA_BACKSCATTERING532';  %raw
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP532';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='count';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='BBP470'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP470';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='m-1';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    
    jj=jj+1;
    aa='BETA_BACKSCATTERING470';  %raw
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='BACKSCATTERINGMETER_BBP470';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='count';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
end

if dbdat.suna
    jj=jj+1;
    aa='NITRATE'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='SPECTROPHOTOMETER_NITRATE';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='micromole/kg';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
end

if dbdat.irr   
    if dbdat.irr2        
        jj=jj+1;
        aa='DOWN_IRRADIANCE380'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR380';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_IRRADIANCE380'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR380';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='DOWN_IRRADIANCE412'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR412';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_IRRADIANCE412'; %raw
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR412';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='DOWN_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR490';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR490';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='DOWNWELLING_PAR'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_PAR';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_PAR'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_PAR';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
    else
        
        jj=jj+1;
        aa='DOWN_IRRADIANCE412'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR412';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_IRRADIANCE412'; %raw
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR412';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='DOWN_IRRADIANCE443'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR443';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_IRRADIANCE443'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR443';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='DOWN_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR490';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR490';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='DOWN_IRRADIANCE555'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR555';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_DOWNWELLING_IRRADIANCE555'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_DOWN_IRR555';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        % now for the up radiance:
        jj=jj+1;
        aa='UP_RADIANCE412'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_UPWELLING_RADIANCE412'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD412';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='UP_RADIANCE443'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD443';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_UPWELLING_RADIANCE443'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD443';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='UP_RADIANCE490'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD490';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_UPWELLING_RADIANCE490'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD490';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='UP_RADIANCE555'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD555';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='W/m^2/nm';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
        
        jj=jj+1;
        aa='RAW_UPWELLING_RADIANCE555'; %derived
        netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
        aa='RADIOMETER_UP_RAD555';
        netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
        aa='count';
        netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    end
end

if dbdat.pH
    jj=jj+1;
    aa='PH_IN_SITU_TOTAL'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='TRANSISTOR_PH';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='dimensionlessm';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    jj=jj+1;
    aa='VRS_PH'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='TRANSISTOR_PH';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='volt';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
    jj=jj+1;
    aa='TEMP_PH'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='TRANSISTOR_PH';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='degree_Celsius';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
end
if isfield(fpp,'Tilt')
    jj=jj+1;
    aa='TILT'; %derived
    netcdf.putVar(ncid,NPARAID,[0,jj-1],[length(aa),1],aa);
    aa='TILT';
    netcdf.putVar(ncid,NPARSENSID,[0,jj-1],[length(aa),1],aa);
    aa='degrees';
    netcdf.putVar(ncid,NPARUNITID,[0,jj-1],[length(aa),1],aa);
end 

for h=1:jj
    
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,h-1],[3,1],'n/a');
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,h-1],[3,1],'n/a');
   
end

if dbdat.deploy_num<=8
   a1='n = instrument output - (ptca1 * t + ptca2 * t^2);  pressure (psia) = pa0 + pa1 * n + pa2 * n^2 ';
else
   a1='y=thermistor output; t=PTHA0+PTHA1*y+PTHA2*y^2; x=pressure output-PTCA0+PTCA1*t+PTCA2*t^2; n=x*PTCB0/(PTCB0+PTCB1*t+PTCB2*t^2); pressure (psia)=PA0+PA1*n+PA2*n^2';
end
a2='Temperature ITS-90 = 1/ { a0 + a1[lambda nu (n)] + a2 [lambda nu^2 (n)] + a3 [lambda nu^3 (n)]} - 273.15 (deg C) ';
a3=' f = inst freq * sqrt(1.0 + WBOTC * t) / 1000.0; t = temperature [deg C]; p = pressure [decibars]; delta = CTcor; epsilon = CPcor; Conductivity = (g + hf^2 + if^3 + jf^4)/(1+ delta t + epsilon p) Siemens/meter ';

netcdf.putVar(ncid,PREDEPCALEQNID,[0,0],[length(a1),1],a1);
netcdf.putVar(ncid,PREDEPCALEQNID,[0,1],[length(a2),1],a2);
netcdf.putVar(ncid,PREDEPCALEQNID,[0,2],[length(a3),1],a3);

plist = {'PA0','PA1','PA2','PTCA0','PTCA1','PTCA2','PTCB0','PTCB1','PTCB2',...
	 'PTHA0','PTHA1','PTHA2'};
a1 = sprintf('ser# = %s pressure coeffs:',sbeSN);
for ii = 1:length(plist)
   ss = eval(['caldb.' plist{ii}]);
   if ~isempty(ss)
      a1 = [a1 ' ' plist{ii} ' = ' num2str(ss)];
   end
end
a2 = sprintf(['ser# = %s temperature coeffs: A0 = %8.4f A1 = %8.4f ' ...
	      'A2 = %8.4f A3 = %8.4f '],...
	     sbeSN, caldb.TA0, caldb.TA1, caldb.TA2, caldb.TA3);
a3 = sprintf(['ser# = %s conductivity coeffs: G = %8.4f H = %8.4f I = %8.4f' ...
	      ' J = %8.4f CPCOR = %8.4f CTCOR = %8.4f WBOTC = %8.4f '],...
	     sbeSN, caldb.G, caldb.H, caldb.I, ...
	     caldb.J, caldb.CPCOR, caldb.CTCOR, caldb.WBOTC);

    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,0],[length(a1),1],a1);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,1],[length(a2),1],a2);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,2],[length(a3),1],a3);

jj=3;
if dbdat.oxy
    typ=dbdat.subtype;
    jj=jj+1;
    kk=find(ARGO_O2_CAL_WMO==dbdat.wmo_id);
    cal=THE_ARGO_O2_CAL_DB(kk);
    %     switch typ
    if isfield(fpp,'SBEOxyfreq_raw')  %        case {22, 38}  case{1007, 1008} % convertFREQoxygen    
        if dbdat.subtype==22 | dbdat.subtype==38
            
            a4 = sprintf(['ser# = %s oxygen coeffs: a0 = %8.4f a1 = %8.4f ' ...
                'a2 = %8.4f a3 = %8.4f '],...
                num2str(cal.O2_snum), cal.a0, cal.a1, cal.a2, cal.a3);
            netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
            
            a4 = ['o2Sol_mlperL=O2sol(s,t)*(sw_dens0(s,t)+1000)/44659.6; pO2 = (a0 * '...
                '(freqO2+a1)) * exp(a2 * t) * o2Sol_mlperL * exp(=a3 * pp);O2 = ' ...
                'pO2*44659.6/(sw_pden(s,t,pp,0))'];
            netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
            
        else                                                                % convertSBEOxyfreq
            
            a4 = sprintf(['ser# = %s oxygen coeffs: a0 = %8.4f a1 = %8.4f ' ...
                'a2 = %8.4f a3 = %8.4f B0 = -6.24523e-3 '...
                'B1 = -7.37614e-3 B2 = -1.03410e-2 B3 = -8.17083e-3 C0 = -4.88682e-7 '...
                'A0 = 2.00907 A1 = 3.22014 A2 = 4.05010 A3 = 4.94457 A4 = -2.56847e-01 A5 = 3.88767'],...
                num2str(cal.O2_snum), cal.a0, cal.a1, cal.a2, cal.a3);
            netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
            
            a4 = ['o2Sol_mlperL = exp(A0+A1*ts+A2*ts.^2+A3*ts.^3+A4*ts.^4+A5*ts.^5 + s.*' ...
                '(B0+B1*ts+B2*ts.^2+B3*ts.^3)+C0*s.^2);%ml/l; pO2 = cal.a0*(Freq+cal.a1).*' ...
                '(1+cal.a2*t+cal.a3*t.^2+cal.a4*t.^3).*o2Sol_mlperL.*exp(cal.a5*pp./(t+273.15)); '...
                'O2 = pO2*44659.6/(sw_pden(s,t,pp,0)); ts = log((298.15-t)/(273.15+t))'];
            netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
            
        end
    end
    if isfield(fpp,'Bphase_raw')  %    case {1002, 1012, 1006, 1020}  % convertBphase
           if isempty(cal.a7) | cal.a7==0
               a4 = sprintf(['ser# = %s oxygen coeffs: a0 = %8.4f a1 = %8.4f ' ...
                   'a2 = %8.4f a3 = %8.4f a4 = %8.4f a5 = %8.4f a6 = %8.4f '], ...
                   num2str(cal.O2_snum), cal.a0, cal.a1, cal.a2, cal.a3, cal.a4, cal.a5, cal.a6);
               netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
               a4 = ['DO2 = (((a3 + a4*t)./(a5 + a6*bp)) - 1)./(a0 + a1*t + a2*t.^2); ' ...
                   'ts = log((298.15-t)/(273.15+t)) ; ' ...
                   'O2a=DO2.*exp(s.*(e0+e1*ts+e2*ts.^2+e3*ts.^3)+f0*s.^2); O2a=O2a*(1+(0.032*depth/1000)); ' ...
                   'O2= O2a./(0.001*sw_dens0(s,t))'];
               netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
           else
               a4 = sprintf(['ser# = %s oxygen coeffs: a0 = %8.4f a1 = %8.4f ' ...
                   'a2 = %8.4f a3 = %8.4f a4 = %8.4f a5 = %8.4f ' ...
                   'a6 = %8.4f a7 = %8.4f a8 = %8.4f a9 = %8.4f ' ...
                   'a10 = %8.4f a11 = %8.4f a12 = %8.4f a13 = %8.4f '],...
                   num2str(cal.O2_snum), cal.a0, cal.a1, cal.a2, cal.a3, cal.a4, cal.a5, cal.a6, ...
                   cal.a7, cal.a8, cal.a9, cal.a10, cal.a11, cal.a12, cal.a13);
               netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
                a4 = ['pO2 = a0 + a1*t + a2*bp + a3*t.^2 + a4*t.*bp + a5*bp.^2 + ' ...
                    'a6*t.^3 + bp.*t.^2*a7 + t.*bp.^2*a8 + a9*bp.^3 + '  ...
                    'bp.*t.^3*a10 + t.^2.*bp.^2*a11 + t.*bp.^3*a12 + a13*bp.^4; ' ...
                    'ts = log((298.15-t)/(273.15+t)) ; ' ...
                    'DO2 = (pO2.*O2sol(s1,t).*0.001.*sw_dens0(s1,t))/(0.20946*1013.25*(1-vpress(s1,t))); ' ...
                    'O2a=DO2.*exp(s.*(e0+e1*ts+e2*ts.^2+e3*ts.^3)+f0*s.^2); O2a=O2a*(1+(0.032*depth/1000)); ' ...
                    'O2= O2a./(0.001*sw_dens0(s,t))'];
            netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
            end
    end
	if isfield(fpp,'Tphase_raw')  %case {1022}  % convertTphase Modified by uday ===============
        if isempty(cal.a7) | cal.a7==0
            a4 = sprintf(['ser# = %s oxygen coeffs: a0 = %8.4f a1 = %8.4f ' ...
                'a2 = %8.4f a3 = %8.4f a4 = %8.4f a5 = %8.4f a6 = %8.4f '], ...
                num2str(cal.O2_snum), cal.a0, cal.a1, cal.a2, cal.a3, cal.a4, cal.a5, cal.a6);
            netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
            a4 = ['DO2 = (((a3 + a4*t)./(a5 + a6*bp)) - 1)./(a0 + a1*t + a2*t.^2); ' ...
                'ts = log((298.15-t)/(273.15+t)) ; ' ...
                'O2a=DO2.*exp(s.*(e0+e1*ts+e2*ts.^2+e3*ts.^3)+f0*s.^2); O2a=O2a*(1+(0.032*depth/1000)); ' ...
                'O2= O2a./(0.001*sw_dens0(s,t))'];
             netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
        else
            a4 = sprintf(['ser# = %s oxygen coeffs: a0 = %8.4f a1 = %8.4f ' ...
                'a2 = %8.4f a3 = %8.4f a04 = %8.4f a5 = %8.4f ' ...
                'a6 = %8.4f a7 = %8.4f a8 = %8.4f a9 = %8.4f ' ...
                'a10 = %8.4f a11 = %8.4f a12 = %8.4f a13 = %8.4f ',...
                'a14 = %8.4f a15 = %8.4f a16 = %8.4f a17 = %8.4f ',...
                'a18 = %8.4f a19 = %8.4f a20 = %8.4f a21 = %8.4f ',...
                'a22 = %8.4f a23 = %8.4f a24 = %8.4f a25 = %8.4f ',...
                'a26 = %8.4f a27 = %8.4f a28 = %8.4f a29 = %8.4f ',...
                'a30 = %8.4f '],...
                num2str(cal.O2_snum), cal.a0, cal.a1, cal.a2, cal.a3, cal.a4, cal.a5, cal.a6, ...
                cal.a7, cal.a8, cal.a9, cal.a10, cal.a11, cal.a12, cal.a13, cal.a14, cal.a15, ...
                cal.a16, cal.a16, cal.a17, cal.a18, cal.a19, cal.a20, cal.a21, cal.a22, cal.a23, ...
                cal.a24, cal.a25, cal.a26, cal.a27, cal.a28, cal.a29);
            netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
            a4 = ['temp = a0 + a1*t + a2*t.^2 + a3*t.^3; ' ...
                'calphase= a4 + a5*tphase + a6*tphase.^2 + a7*tphase.^3; ' ...
                'delP = a8*temp.^1*calphase.^4 + a9*temp.^0*calphase.^5 + a10*temp.^0*calphase.^4 + ' ...
                'a11*temp.^0*calphase.^3 + a12*temp.^1*calphase.^3 + a13*temp.^2*calphase.^3 + ' ...
                'a14*temp.^0*calphase.^2 + a15*temp.^1*calphase.^2 + a16*temp.^2*calphase.^2 + ' ...
                'a17*temp.^3*calphase.^2 + a18*temp.^1*calphase.^1 + a19*temp.^2*calphase.^1 + ' ...
                'a20*temp.^3*calphase.^1 + a21*temp.^4*calphase.^1 + a22*temp.^0*calphase.^0 + ' ...
                'a23*temp.^1*calphase.^0 + a24*temp.^2*calphase.^0 + a25*temp.^3*calphase.^0 + ' ...
                'a26*temp.^4*calphase.^0 + a27*temp.^5*calphase.^0; ' ...
                'nomairpress=1013.25; nomairmix=0.20946; ' ...
                'pvapour=exp(52.57 - 6690.9./(temp+273.15) - 4.681*log(temp + 273.15)); ' ...
                'airsat=deltaP*100./((nomairpress-pvapour)*nomairmix); ' ...
                'Ts=log((298.15-temp)./(273.15+temp)); ' ...
                'cstar = exp(f0 + f1*Ts + f2*Ts^2 + f3*Ts^3 + f4*Ts^4 + f5*Ts^5; ' ...
                'molar_doxy=cstar*44.614.*airsat/100']
             netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
            % =========== end of uday modification =================
        end
    end
    if isfield(fpp,'oxy_umolar')  %    case{31, 32, 35, 40}    %convert_uMolar
        s=getadditionalinfo(dbdat.wmo_id);
        a4 = sprintf(['ser# = %s O2a = raw molar doxy'],...
            num2str(s.Oxygen.SerialNo));
        netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
        a4 = ['O2a=O2a.*(1+(0.032*depth/1000)); O2= O2a./(0.001*sw_dens0(s,t))'];
        netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
    end
    if isfield(fpp,'O2phase_raw')   % case 1017    % convertSBE63Oxy
        a4 = sprintf(['ser# = %s  oxygen coeffs: s1 = 0 a0 = %8.4f a1 = %8.4f ' ...
            'a2 = %8.4f b0 = %8.4f b1 = %8.4f c0 = %8.4f  c1 = %8.4f c2 = %8.4f e = %8.4f'],...
            num2str(cal.O2_snum), cal.a0, cal.a1, cal.a2, cal.a3, cal.a4, cal.a5, cal.a6, cal.a7, cal.a8);
        netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
        a4 = ['k = t + 273.15; V = Phase/39.457071; o2_mlperL=(((a0 + a1*t + a2 * ' ...
            'V.^2)./(b0 + b1*V) - 1.0)./(c0 + c1*t + c2*t.^2)) .* exp(e * pp./k); ' ...
            'O2 = o2_mlperL*44659.6./(sw_dens0(s,t))'];
        netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
        if isfield(fpp,'t_oxygen_volts')    % convertSBE63Tv
            jj=jj+1;
            a4 = sprintf(['ser# = %s  oxygen coeffs: T0 = %8.4f T1 = %8.4f T2 = %8.4f ' ...
                'T3 = %8.4f' ],...
                num2str(cal.O2_snum), cal.T0, cal.T1, cal.T2, cal.T3);
            netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
            a4 = ['R = 100000 * Tv ./ (3.300000 - Tv); L1 = log(R); L2 = L1 .* L1; L3 = L2 .* L1; ' ...
                'O2T = (1 ./ (T0 + T1.*L1 + T2.*L2 + T3.*L3))-273.15; '];
            netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
        end               
    end  
        
end
if dbdat.flbb
    typ=dbdat.subtype;
    kk=find(ARGO_BIO_CAL_WMO==dbdat.wmo_id);
    cal=THE_ARGO_BIO_CAL_DB(kk);
    jj=jj+1; % CHLA
    a4 = sprintf(['ser# = %s FLBB CHLA coeffs: Scale = %8.4f  Dark Counts = %8.4f' ],...
        num2str(cal.FLBB700sn), cal.FLBBCHLscale, cal.FLBBCHLdc);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
    a4 = ['CHLA = FLBBCHLscale*(Fsig - FLBBCHLdc)'];
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
    jj=jj+1; % BBP
    a4 = sprintf(['ser# = %s FLBB 700 BBP coeffs: Scale = %8.4f  Dark Counts = %8.4f'  ...
        ' FLBBangle = %8.4f  FLBBChi = %8.4f'],...
        num2str(cal.FLBB700sn), cal.FLBB700scale, cal.FLBB700dc, cal.BBP700angle, cal.BBP700Chi);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
    a4 = ['totalBBP = FLBB700scale*(Bbsig - FLBB700dc); ' ...
        ' [betasw,beta90sw,bsw] = betasw_ZHH2009(700,t_oxygen,FLBB700angle,s_oxygen) cf betasw_ZHH2009; '...
        ' BBP700 = 2*pi*FLBBChi*(totalBBP-betasw)'];
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
    
    if isfield(fpp,'CDOM_raw')  %dbdat.subtype==1006
        jj=jj+1; % CDOM
        
        a4 = sprintf(['ser# = %s FLBB CDOM coeffs: Scale = %8.4f  Dark Counts = %8.4f' ],...
            num2str(cal.FLBB700sn), cal.CDOMscale, cal.CDOMdc);
        netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
        a4 = ['CDOM = CDOMLscale*(Cdsig - CDOMdc)'];
        netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
    end       
end
if dbdat.flbb2
    typ=dbdat.subtype;
    kk=find(ARGO_BIO_CAL_WMO==dbdat.wmo_id);
    cal=THE_ARGO_BIO_CAL_DB(kk);
    jj=jj+1; % BBP 532, MCOMS FLBB2
    a4 = sprintf(['ser# = %s FLBB 532 BBP coeffs: Scale = %8.4f  Dark Counts = %8.4f'  ...
        ' FLBBangle = %8.4f  FLBBChi = %8.4f'],...
        num2str(cal.FLBB700sn), cal.FLBB532scale, cal.FLBB532dc, cal.BBP532angle, cal.BBP532Chi);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
    a4 = ['totalBBP532 = FLBB532scale*(Bbsig - FLBB532dc); ' ...
        ' [betasw,beta90sw,bsw] = betasw_ZHH2009(532,t_oxygen,FLBB532angle,s_oxygen) cf betasw_ZHH2009; '...
        ' BBP532 = 2*pi*FLBBChi*(totalBBP-betasw)'];
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
end

if dbdat.eco
    typ=dbdat.subtype;
    kk=find(ARGO_BIO_CAL_WMO==dbdat.wmo_id);
    cal=THE_ARGO_BIO_CAL_DB(kk);
    jj=jj+1; % BBP 700 - Eco
    a4 = sprintf(['ser# = %s ECO 700 BBP coeffs: Scale = %8.4f Eco 700 Dark Counts = %8.4f'  ...
        ' ECO 700angle = %8.4f ECO 700 Chi = %8.4f'],...
        num2str(cal.EcoFLBB700sn), cal.EcoFLBB700scale, cal.EcoFLBB700dc, cal.EcoFLBB700angle, cal.EcoFLBB700Chi);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
    a4 = ['totalBBP700 = EcoFLBB700scale*(Bbsig - EcoFLBB700dc); ' ...
        ' [betasw,beta90sw,bsw] = betasw_ZHH2009(700,t_oxygen,EcoFLBB700angle,s_oxygen) cf betasw_ZHH2009; '...
        ' BBP700 = 2*pi*EcoFLBB700Chi*(totalBBP700-betasw)'];
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
    jj=jj+1; % BBP532 - Eco
    a4 = sprintf(['ser# = %s FLBB 532 BBP coeffs: Scale = %8.4f Eco 532 Dark Counts = %8.4f'  ...
        ' Eco 532 angle = %8.4f  Eco 532 Chi = %8.4f'],...
        num2str(cal.EcoFLBB700sn), cal.EcoFLBB532scale, cal.EcoFLBB532dc, cal.EcoFLBB532angle, cal.EcoFLBB532Chi);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
    a4 = ['totalBBP532 = FLBB532scale*(Bbsig - FLBB532dc); ' ...
        ' [betasw,beta90sw,bsw] = betasw_ZHH2009(532,t_oxygen,EcoFLBB532angle,s_oxygen) cf betasw_ZHH2009; '...
        ' BBP532 = 2*pi*EcoFLBB532Chi*(totalBBP532-betasw)'];
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
    jj=jj+1; % % BBP532 - Eco
    a4 = sprintf(['ser# = %s FLBB 470 BBP coeffs: Scale = %8.4f  Dark Counts = %8.4f'  ...
        ' FLBB470angle = %8.4f  FLBB470Chi = %8.4f'],...
        num2str(cal.EcoFLBB700sn), cal.EcoFLBB470scale, cal.EcoFLBB470dc, cal.EcoFLBB470angle, cal.EcoFLBB470Chi);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
    a4 = ['totalBBP470 = FLBB470scale*(Bbsig - FLBB470dc); ' ...
        ' [betasw,beta90sw,bsw] = betasw_ZHH2009(470,t_oxygen,EcoFLBB470angle,s_oxygen) cf betasw_ZHH2009; '...
        ' BBP470 = 2*pi*EcoFLBB470Chi*(totalBBP470-betasw)'];
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);
end    
    

if dbdat.tmiss
    kk=find(ARGO_BIO_CAL_WMO==dbdat.wmo_id);
    cal=THE_ARGO_BIO_CAL_DB(kk);
    jj=jj+1; % CP = particle beam transmittence
    a4 = sprintf(['ser# = %s Transmissometer CP coeffs: Reference = %8.4f  Dark Counts = %8.4f  Path Length = 25' ],...
        num2str(cal.TM_snum), cal.TMref, cal.TMdark);
    netcdf.putVar(ncid,PREDEPCALCOEFFID,[0,jj-1],[length(a4),1],a4);
    a4 = ['transmittence = (TMcounts - Dark Counts)*(Reference - Dark Counts); CP = -1/Path Length*ln(transmittence);' ];
    netcdf.putVar(ncid,PREDEPCALEQNID,[0,jj-1],[length(a4),1],a4);      
end

% May need to update mission end date/status

%DEV If last profile has no times then we cannot know how long it has been 
% missing. The way around this is when we decide a float HAS died, make sure 
% the last profile record DOES have a jday! 


if(length(fpp)==0)  % died on deployment
    aa=dbdat.launchdate;
    netcdf.putVar(ncid,ENDMISSDATEID,0,length(aa),aa);
    netcdf.putVar(ncid,ENDMISSSTATID,'T');
else
    np = length(fpp);
    if ~isempty(fpp(np).jday)
        if abs(julian(clock)-fpp(np).jday(1)) > 340
            aa = sprintf('%04d%02d%02d%02d%02d%02d',fpp(np).datetime_vec(1,:));
            netcdf.putVar(ncid,ENDMISSDATEID,0,length(aa),aa);
            netcdf.putVar(ncid,ENDMISSSTATID,'T');
            if isempty(strfind(dbdat.status,'dead'))
                logerr(3,['METADATA_NC: WMO ' num2str(dbdat.wmo_id) ' has status "' ...
                    dbdat.status '" but last date is ' ...
                    num2str(fpp(np).datetime_vec(1,:))]);
          end
       end
    end
end

% now configuration parameters:
%Argos non-changing missions first:

jk=0;

if ~dbdat.iridium | (dbdat.iridium & isempty(missionI))  %launch info first: 
    %  names for the parameters from the spreadsheet for argos floats only.
    %  iridium names come from the floataux.mat files. Also note that
    %  argos floats only have one set of configuraton parameters!

    for l=5:length(mission.data)-1
        if ~isempty(mission.config{l}) && ~isempty(mission.data{l})
            jk=jk+1 ;
            aa=mission.config{l};
            netcdf.putVar(ncid,LAUNCONFIGNID,[0,jk-1],[length(aa),1],aa);
            netcdf.putVar(ncid,CONFIGNID,[0,jk-1],[length(aa),1],aa);
            
            aan=str2num(mission.data{l});
            netcdf.putVar(ncid,LAUNCONFIGVID,jk-1,1,aan);
             netcdf.putVar(ncid,CONFIGVID,[jk-1,0],[1,1],aan);
            
        end
        
    end
    
    netcdf.putVar(ncid,CONFIGMISSID,0,1,1);
    
else   %iridium configuration parameters come from elsewhere:
    %     and have already been loaded with mission number
     
    for l=1:length(missionI.names)
        aa=missionI.names{l};
        netcdf.putVar(ncid,LAUNCONFIGNID,[0,l-1],[length(aa),1],aa);
        netcdf.putVar(ncid,CONFIGNID,[0,l-1],[length(aa),1],aa);
        aan=missionI.values(l,1);
        netcdf.putVar(ncid,LAUNCONFIGVID,l-1,length(aan),aan);
    end
    
    for jj=1:length(missionI.names)
        for l=1:length(missionI.missionno)
            aan=missionI.values(jj,l);
            netcdf.putVar(ncid,CONFIGVID,[jj-1,l-1],[1,1],aan);
            netcdf.putVar(ncid,CONFIGMISSID,l-1,1,missionI.missionno(l));
        end        
    end

end

netcdf.close(ncid);

if ~strcmp('hold',dbdat.status) & ~strcmp('evil',dbdat.status)
    [status,ww] = system(['cp -f ' fnm ' ' ARGO_SYS_PARAM.root_dir 'export']);
    if status~=0
        logerr(3,['Copy of ' fnm ' to export/ failed:' ww]);
    end
    
end
%-------------------------------------------------------------------------------
