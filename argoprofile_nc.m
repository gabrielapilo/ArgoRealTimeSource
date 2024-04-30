% ARGOPROFILE_NC  Create or add to a netCDF Argo RAW profile file. May be used
%       for single or multi-profile files (but for now expect only the former)
%
% INPUT 
%  dbdat - master database record for this float
%  fp   - float struct array containing ONLY the profiles to be added.
%
% OUTPUT 
%   To a single netCDF file. If only one profile, the fileanme will include
%   its profilenumber, otherwise it will just have float WMO number. 
%
% Author:  Jeff Dunn CSIRO/BoM  Aug 2008
%
%  Devolved from matlabnetcdf scripts (Ann Thresher ?)
% 
% CALLS:  netCDF toolbox
%
% Example: If want to write profiles 3, 4, & 5 to a netCDF file, 
%         >> argoprofile_nc(dbdat,fp([3 4 5]))
%
% USAGE: argoprofile_nc(dbdat,fp)
%
% NOTE:  calibraton of salinity turned off on 3/9/2007 - to turn back on,
%        remove lines 42:43 below  :AT
% NOTE:  turned back on 6/11/2007
% NOTE: turned back off 09/12/2019 (GP)
%
% adding multiprofile features - June/July 2012 : AT
% note - this CANNOT be used to create true multiprofile files for a single
% float any more.
% Also note - this refers to more than one vertically resolved profile within a
% single station, not a colection of stations in one file. 
%
% Note : float types 1008, 1006 and 1017 have a secondary profile
%
%
% fp MUST be a single profile now so rename it fp for consistency.
%
%  converted to format 3.0 - AT 09/05/2013
%
% converted to separate out bio variables into a different file : AT Feb
% 2014 - format version 3.1
% this version creates the C file only. must be paired with
% argoprofile_Bfile_nc if float has bio data


function argoprofile_nc(dbdat,fp)

global ARGO_SYS_PARAM

% Developer note: We may like to use N_PROF as the unlimited dimension for
%  local all-profiles-for-one-float files? Would switch with HISTORY 
%  dimension, which could be fixed at some generous amount.

% if there's no data, we won't create these  files but all other files are
% fine...  and we detect no data by no pressures!

%  Trap for floats that have secondary profiles only (primary ctd profile 
%   is missing)
if(isfield(fp,'p_oxygen') && isempty(fp.p_raw) && isempty(fp.p_oxygen))
    return
elseif (~isfield(fp,'p_oxygen') && isempty(fp.p_raw))
    return
end

% DATA_MODE could be set by testing for non-empty s_calibrate, but for now
% fix to 'adjusted'.  Note - if the primary profile is empty, then this gets
% messy. We adjust all profiles so set to 'A' by default.
% if(isempty(fp.s_calibrate))
%     adjusted=0;
% else
    adjusted = 1;
% end

% (Calibration was turned on in 6/11/2007:AT)
adjusted = 1; % calibration turned off in 09/12/2019: GP (0 is off)

if adjusted
    datamode = 'A';
else
    datamode = 'R';
end

fval = 99999.;

% nin = length(fp);

if ispc
    ndir = [ARGO_SYS_PARAM.root_dir 'netcdf\' int2str(dbdat.wmo_id)];
else
    ndir = [ARGO_SYS_PARAM.root_dir 'netcdf/' int2str(dbdat.wmo_id)];
end
if ~exist(ndir,'dir')
    [st,ww] = system(['mkdir ' ndir]);
    if st~=0
        logerr(2,['Failed creating new directory ' ndir]);
        return
    end
end

% if nin==1 % - removed because we now generate multiprofile files for a
% single station/report

if isfield(fp,'p_oxygen')
    nin=2;
else
    nin=1;
end
pnum = fp.profile_number;
pno=sprintf('%3.3i',pnum);
if ispc
    if (dbdat.subtype==9999)  %EM floats with bidirectional sampling
        if rem(fp.profile_number,2)==1;
            fname = [ndir '\R' int2str(dbdat.wmo_id) '_' pno 'D.nc'];
        else
            fname = [ndir '\R' int2str(dbdat.wmo_id) '_' pno '.nc'];
        end
    else
        fname = [ndir '\R' int2str(dbdat.wmo_id) '_' pno '.nc'];
    end
else
    if (dbdat.subtype==9999)  %EM floats with bidirectional sampling
        if rem(fp.profile_number,2)==1;
            fname = [ndir '/R' int2str(dbdat.wmo_id) '_' pno 'D.nc'];
        else
            fname = [ndir '/R' int2str(dbdat.wmo_id) '_' pno '.nc'];
        end
    else
        fname = [ndir '/R' int2str(dbdat.wmo_id) '_' pno '.nc'];
    end
end

hist=[];
dc=[];
if exist(fname,'file')
    logerr(3,['ARGOPROFILE_NC: File ' fname ' exists - overwriting!']);
    try
       ncid=netcdf.open(fname,'NOWRITE');
       
       hist=netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history');
       dcvarid=netcdf.inqVarID(ncid,'DATE_CREATION');
       dc=netcdf.getVar(ncid,dcvarid);
       
       netcdf.close(ncid)
%         hist=attnc(fname,'global','history');
%         dc=getnc(fname,'DATE_CREATION');
    end
else
end

ncid=netcdf.create(fname,'CLOBBER');

nlevels = length(fp.p_raw);

maxlev = nlevels;
nlvls=0;
if isfield(fp,'p_oxygen')
    nlvls = length(fp.p_oxygen);
end
maxlev = max(nlvls,maxlev);


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

% // global attributes:
% 		:title = "Argo float vertical profile" ;
% 		:institution = "CSIRO" ;
% 		:source = "Argo float" ;
% 		:history = "2013-07-27T12:59:35Z creation;2014-08-15T15:22:01Z update;2014-10-06T03:01:40Z update;2014-10-20T00:27:00Z update" ;
% 		:references = "http://www.argodatamgt.org/Documentation" ;
% 		:user_manual_version = "3.1" ;
% 		:Conventions = "Argo-3.1 CF-1.6" ;
% 		:featureType = "trajectoryProfile" ;

netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'title','Argo float vertical profile' );
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'institution',ARGO_SYS_PARAM.inst);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'source','Argo float');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history',dnt);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'references','http://www.argodatamgt.org/Documentation');
% netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'comment','');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'user_manual_version','3.1');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'Conventions','Argo-3.1 CF-1.6');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'featureType','trajectoryProfile');

N_PROFID=netcdf.defDim(ncid,'N_PROF',nin);
N_LEVELSID=netcdf.defDim(ncid,'N_LEVELS',maxlev);
N_CALIBID=netcdf.defDim(ncid,'N_CALIB',1);

STR2=netcdf.defDim(ncid,'STRING2',2);
STR4=netcdf.defDim(ncid,'STRING4',4);
STR8=netcdf.defDim(ncid,'STRING8',8);
% STR10=netcdf.defDim(ncid,'STRING10',10);
STR16=netcdf.defDim(ncid,'STRING16',16);
STR32=netcdf.defDim(ncid,'STRING32',32);
STR64=netcdf.defDim(ncid,'STRING64',64);
STR256=netcdf.defDim(ncid,'STRING256',256);
DaTi =netcdf.defDim(ncid,'DATE_TIME',14);

% Standard dimensions
% nc('STRING2') = 2;
% nc('STRING4') = 4;
% nc('STRING8') = 8;
% % nc('STRING10') = 10;
% nc('STRING16') = 16;
% nc('STRING32') = 32;
% nc('STRING64') = 64;
% nc('STRING256') = 256;
% nc('DATE_TIME') = 14;

n_param = 3;  % only P T and S belong in the Core Argo file

NPARID=netcdf.defDim(ncid,'N_PARAM',n_param);

% Argo netCDF files are required to have N_HISTORY as the unlimited dimension!
NHISID=netcdf.defDim(ncid,'N_HISTORY',netcdf.getConstant('NC_UNLIMITED'));

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

NDACRID=netcdf.defVar(ncid,'DATE_CREATION','NC_CHAR',DaTi);
netcdf.putAtt(ncid,NDACRID,'long_name','Date of file creation');
netcdf.putAtt(ncid,NDACRID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NDACRID,'_FillValue',' ');

NDAUPID=netcdf.defVar(ncid,'DATE_UPDATE','NC_CHAR',DaTi);
netcdf.putAtt(ncid,NDAUPID,'long_name','Date of update of this file');
netcdf.putAtt(ncid,NDAUPID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NDAUPID,'_FillValue',' ');

NPLANUID=netcdf.defVar(ncid,'PLATFORM_NUMBER','NC_CHAR',[STR8,N_PROFID]);
netcdf.putAtt(ncid,NPLANUID,'long_name','Float unique identifier');
netcdf.putAtt(ncid,NPLANUID,'conventions','WMO float identifier : A9IIIII');
netcdf.putAtt(ncid,NPLANUID,'_FillValue',' ');

NPRONAID=netcdf.defVar(ncid,'PROJECT_NAME','NC_CHAR',[STR64,N_PROFID]);
netcdf.putAtt(ncid,NPRONAID,'long_name','Name of the project');
netcdf.putAtt(ncid,NPRONAID,'_FillValue',' ');

NPINAID=netcdf.defVar(ncid,'PI_NAME','NC_CHAR',[STR64,N_PROFID]);
netcdf.putAtt(ncid,NPINAID,'long_name','Name of the principal investigator');
netcdf.putAtt(ncid,NPINAID,'_FillValue',' ');

NSTAPARAID=netcdf.defVar(ncid,'STATION_PARAMETERS','NC_CHAR',[STR16,NPARID,N_PROFID]);
netcdf.putAtt(ncid,NSTAPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NSTAPARAID,'long_name','List of available parameters for the station');
netcdf.putAtt(ncid,NSTAPARAID,'_FillValue',' ');

NCYCNUMID=netcdf.defVar(ncid,'CYCLE_NUMBER','NC_INT',N_PROFID);
netcdf.putAtt(ncid,NCYCNUMID,'long_name','Float cycle number');
netcdf.putAtt(ncid,NCYCNUMID,'_FillValue',int32(fval));
netcdf.putAtt(ncid,NCYCNUMID,'conventions','0...N, 0 : launch cycle (if exists), 1 : first complete cycle');

NDIRID=netcdf.defVar(ncid,'DIRECTION','NC_CHAR',N_PROFID);
netcdf.putAtt(ncid,NDIRID,'long_name','Direction of the station profiles');
netcdf.putAtt(ncid,NDIRID,'conventions','A: ascending profiles, D: descending profiles');
netcdf.putAtt(ncid,NDIRID,'_FillValue',' ');

NDACENID=netcdf.defVar(ncid,'DATA_CENTRE','NC_CHAR',[STR2,N_PROFID]);
netcdf.putAtt(ncid,NDACENID,'long_name','Data centre in charge of float data processing');
netcdf.putAtt(ncid,NDACENID,'conventions','Argo reference table 4');
netcdf.putAtt(ncid,NDACENID,'_FillValue',' ');

NDCREFID=netcdf.defVar(ncid,'DC_REFERENCE','NC_CHAR',[STR32,N_PROFID]);
netcdf.putAtt(ncid,NDCREFID,'long_name','Station unique identifier in data centre');
netcdf.putAtt(ncid,NDCREFID,'conventions','Data centre convention');
%netcdf.putAtt(ncid,'DC_REFERENCE'}.construction='Argos float number/profilenumber');
netcdf.putAtt(ncid,NDCREFID,'_FillValue',' ');

NDASTAINDID=netcdf.defVar(ncid,'DATA_STATE_INDICATOR','NC_CHAR',[STR4,N_PROFID]);
netcdf.putAtt(ncid,NDASTAINDID,'long_name','Degree of processing the data have passed through');
netcdf.putAtt(ncid,NDASTAINDID,'conventions','Argo reference table 6');
netcdf.putAtt(ncid,NDASTAINDID,'_FillValue',' ');

NDAMOID=netcdf.defVar(ncid,'DATA_MODE','NC_CHAR',N_PROFID);
netcdf.putAtt(ncid,NDAMOID,'long_name','Delayed mode or real time data');
netcdf.putAtt(ncid,NDAMOID,'conventions','R : real time; D : delayed mode; A : real time with adjustment');
netcdf.putAtt(ncid,NDAMOID,'_FillValue',' ');

NPLATYID=netcdf.defVar(ncid,'PLATFORM_TYPE','NC_CHAR',[STR32,N_PROFID]);
netcdf.putAtt(ncid,NPLATYID,'long_name','Type of float');
netcdf.putAtt(ncid,NPLATYID,'conventions','Argo reference table 23');
netcdf.putAtt(ncid,NPLATYID,'_FillValue',' ');

NFLSERNOID=netcdf.defVar(ncid,'FLOAT_SERIAL_NO','NC_CHAR',[STR32,N_PROFID]);
netcdf.putAtt(ncid,NFLSERNOID,'long_name','Serial number of the float');
netcdf.putAtt(ncid,NFLSERNOID,'_FillValue',' ');

NFIRVERID=netcdf.defVar(ncid,'FIRMWARE_VERSION','NC_CHAR',[STR32,N_PROFID]);
netcdf.putAtt(ncid,NFIRVERID,'long_name','Instrument firmware version');
% netcdf.putAtt(ncid,'FIRMWARE_VERSION'}.conventions=' ';
netcdf.putAtt(ncid,NFIRVERID,'_FillValue',' ');

NWMOINTYID=netcdf.defVar(ncid,'WMO_INST_TYPE','NC_CHAR',[STR4,N_PROFID]);
netcdf.putAtt(ncid,NWMOINTYID,'long_name','Coded instrument type');
netcdf.putAtt(ncid,NWMOINTYID,'conventions','Argo reference table 8');
netcdf.putAtt(ncid,NWMOINTYID,'_FillValue',' ');

NJULDID=netcdf.defVar(ncid,'JULD','NC_DOUBLE',N_PROFID);
netcdf.putAtt(ncid,NJULDID,'standard_name','time');
netcdf.putAtt(ncid,NJULDID,'long_name','Julian day (UTC) of the station relative to REFERENCE_DATE_TIME');
netcdf.putAtt(ncid,NJULDID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDID,'resolution',double(0.00001));  % 1 second resolution
netcdf.putAtt(ncid,NJULDID,'_FillValue',double(999999));
netcdf.putAtt(ncid,NJULDID,'axis','T');

NJULDQCID=netcdf.defVar(ncid,'JULD_QC','NC_CHAR',N_PROFID);
netcdf.putAtt(ncid,NJULDQCID,'long_name','Quality on date and time');
netcdf.putAtt(ncid,NJULDQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NJULDQCID,'_FillValue',' ');

NJULDLOCID=netcdf.defVar(ncid,'JULD_LOCATION','NC_DOUBLE',N_PROFID);
netcdf.putAtt(ncid,NJULDLOCID,'long_name','Julian day (UTC) of the location relative to REFERENCE_DATE_TIME');
netcdf.putAtt(ncid,NJULDLOCID,'units','days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(ncid,NJULDLOCID,'conventions','Relative julian days with decimal part (as parts of day)');
netcdf.putAtt(ncid,NJULDLOCID,'resolution',double(0.00001));  % 1 second resolution
netcdf.putAtt(ncid,NJULDLOCID,'_FillValue',double(999999));
netcdf.putAtt(ncid,NJULDLOCID,'axis','T');

NLATID=netcdf.defVar(ncid,'LATITUDE','NC_DOUBLE',N_PROFID);
netcdf.putAtt(ncid,NLATID,'long_name','Latitude of the station, best estimate');
netcdf.putAtt(ncid,NLATID,'standard_name','latitude');
netcdf.putAtt(ncid,NLATID,'units','degree_north');
netcdf.putAtt(ncid,NLATID,'valid_min',double(-90.));
netcdf.putAtt(ncid,NLATID,'valid_max',double(90.));
netcdf.putAtt(ncid,NLATID,'axis','Y');
netcdf.putAtt(ncid,NLATID,'_FillValue',double(fval));

NLONGID=netcdf.defVar(ncid,'LONGITUDE','NC_DOUBLE',N_PROFID);
netcdf.putAtt(ncid,NLONGID,'long_name','Longitude of the station, best estimate');
netcdf.putAtt(ncid,NLONGID,'standard_name','longitude');
netcdf.putAtt(ncid,NLONGID,'units','degree_east');
netcdf.putAtt(ncid,NLONGID,'valid_min',double(-180.));
netcdf.putAtt(ncid,NLONGID,'valid_max',double(180.));
netcdf.putAtt(ncid,NLONGID,'axis','X');
netcdf.putAtt(ncid,NLONGID,'_FillValue',double(fval));

NPOSID=netcdf.defVar(ncid,'POSITION_QC','NC_CHAR',N_PROFID);
netcdf.putAtt(ncid,NPOSID,'long_name','Quality on position (latitude and longitude)');
netcdf.putAtt(ncid,NPOSID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NPOSID,'_FillValue',' ');

NPOSSYSID=netcdf.defVar(ncid,'POSITIONING_SYSTEM','NC_CHAR',[STR8,N_PROFID]);
netcdf.putAtt(ncid,NPOSSYSID,'long_name','Positioning system');
netcdf.putAtt(ncid,NPOSSYSID,'_FillValue',' ');

NPROPRESQCID=netcdf.defVar(ncid,'PROFILE_PRES_QC','NC_CHAR',N_PROFID);
netcdf.putAtt(ncid,NPROPRESQCID,'long_name','Global quality flag of PRES profile');
netcdf.putAtt(ncid,NPROPRESQCID,'conventions','Argo reference table 2a');
netcdf.putAtt(ncid,NPROPRESQCID,'_FillValue',' ');

NPROTEMPQCID=netcdf.defVar(ncid,'PROFILE_TEMP_QC','NC_CHAR',N_PROFID);
netcdf.putAtt(ncid,NPROTEMPQCID,'long_name','Global quality flag of TEMP profile');
netcdf.putAtt(ncid,NPROTEMPQCID,'conventions','Argo reference table 2a');
netcdf.putAtt(ncid,NPROTEMPQCID,'_FillValue',' ');

NPROPSALQCID=netcdf.defVar(ncid,'PROFILE_PSAL_QC','NC_CHAR',N_PROFID);
netcdf.putAtt(ncid,NPROPSALQCID,'long_name','Global quality flag of PSAL profile');
netcdf.putAtt(ncid,NPROPSALQCID,'conventions','Argo reference table 2a');
netcdf.putAtt(ncid,NPROPSALQCID,'_FillValue',' ');

NVERSAMPSCID=netcdf.defVar(ncid,'VERTICAL_SAMPLING_SCHEME','NC_CHAR',[STR256,N_PROFID]);
netcdf.putAtt(ncid,NVERSAMPSCID,'long_name','Vertical sampling scheme');
netcdf.putAtt(ncid,NVERSAMPSCID,'conventions','Argo reference table 16');
netcdf.putAtt(ncid,NVERSAMPSCID,'_FillValue',' ');

NCONFMISNUMID=netcdf.defVar(ncid,'CONFIG_MISSION_NUMBER','NC_INT',N_PROFID);
netcdf.putAtt(ncid,NCONFMISNUMID,'long_name','Unique number denoting the missions performed by the float');
netcdf.putAtt(ncid,NCONFMISNUMID,'conventions','1...N, 1 : first complete mission');
netcdf.putAtt(ncid,NCONFMISNUMID,'_FillValue',int32(fval));

NPRESID=netcdf.defVar(ncid,'PRES','NC_FLOAT',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPRESID,'long_name','Sea water pressure, equals 0 at sea-level');
netcdf.putAtt(ncid,NPRESID,'standard_name','sea_water_pressure');
netcdf.putAtt(ncid,NPRESID,'units','decibar');
netcdf.putAtt(ncid,NPRESID,'axis','Z');
netcdf.putAtt(ncid,NPRESID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NPRESID,'valid_min',single(0.));
netcdf.putAtt(ncid,NPRESID,'valid_max',single(12000.));
netcdf.putAtt(ncid,NPRESID,'C_format','%7.1f');
netcdf.putAtt(ncid,NPRESID,'FORTRAN_format','F7.1');
netcdf.putAtt(ncid,NPRESID,'resolution',single(0.1));   %DEV Use dbdat.pres_res?

NPRESQCID=netcdf.defVar(ncid,'PRES_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPRESQCID,'long_name','quality flag');
netcdf.putAtt(ncid,NPRESQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NPRESQCID,'_FillValue',' ');

NPRESADID=netcdf.defVar(ncid,'PRES_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPRESADID,'long_name','Sea water pressure, equals 0 at sea-level');
netcdf.putAtt(ncid,NPRESADID,'standard_name','sea_water_pressure');
netcdf.putAtt(ncid,NPRESADID,'units','decibar');
% netcdf.putAtt(ncid,NPRESADID,'comment','In situ measurement, sea surface ', 0');
netcdf.putAtt(ncid,NPRESADID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NPRESADID,'valid_min',single(0.));
netcdf.putAtt(ncid,NPRESADID,'valid_max',single(12000.));
netcdf.putAtt(ncid,NPRESADID,'C_format','%7.1f');
netcdf.putAtt(ncid,NPRESADID,'FORTRAN_format','F7.1');
netcdf.putAtt(ncid,NPRESADID,'resolution',single(0.1));

NPRESADQCID=netcdf.defVar(ncid,'PRES_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPRESADQCID,'long_name','quality flag');
netcdf.putAtt(ncid,NPRESADQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NPRESADQCID,'_FillValue',' ');

NTEMPID=netcdf.defVar(ncid,'TEMP','NC_FLOAT',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NTEMPID,'long_name','Sea temperature in-situ ITS-90 scale');
netcdf.putAtt(ncid,NTEMPID,'standard_name','sea_water_temperature');
netcdf.putAtt(ncid,NTEMPID,'units','degree_Celsius');
netcdf.putAtt(ncid,NTEMPID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NTEMPID,'valid_min',single(-2.5));
netcdf.putAtt(ncid,NTEMPID,'valid_max',single(40.));
% netcdf.putAtt(ncid,NTEMPID,'comment','In situ measurement');
netcdf.putAtt(ncid,NTEMPID,'C_format','%9.3f');
netcdf.putAtt(ncid,NTEMPID,'FORTRAN_format','F9.3');
netcdf.putAtt(ncid,NTEMPID,'resolution',single(0.001));

NTEMPQCID=netcdf.defVar(ncid,'TEMP_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NTEMPQCID,'long_name','quality flag');
netcdf.putAtt(ncid,NTEMPQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NTEMPQCID,'_FillValue',' ');

NTEMPADID=netcdf.defVar(ncid,'TEMP_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NTEMPADID,'long_name','Sea temperature in-situ ITS-90 scale');
netcdf.putAtt(ncid,NTEMPADID,'standard_name','sea_water_temperature');
netcdf.putAtt(ncid,NTEMPADID,'units','degree_Celsius');
netcdf.putAtt(ncid,NTEMPADID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NTEMPADID,'valid_min',single(-2.5));
netcdf.putAtt(ncid,NTEMPADID,'valid_max',single(40.));
% netcdf.putAtt(ncid,NTEMPADID,'comment','In situ measurement');
netcdf.putAtt(ncid,NTEMPADID,'C_format','%9.3f');
netcdf.putAtt(ncid,NTEMPADID,'FORTRAN_format','F9.3');
netcdf.putAtt(ncid,NTEMPADID,'resolution',single(0.001));

NTEMPADQCID=netcdf.defVar(ncid,'TEMP_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NTEMPADQCID,'long_name','quality flag');
netcdf.putAtt(ncid,NTEMPADQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NTEMPADQCID,'_FillValue',' ');

NPSALID=netcdf.defVar(ncid,'PSAL','NC_FLOAT',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPSALID,'long_name','Practical salinity');
netcdf.putAtt(ncid,NPSALID,'standard_name','sea_water_salinity');
netcdf.putAtt(ncid,NPSALID,'units','psu');
netcdf.putAtt(ncid,NPSALID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NPSALID,'valid_min',single(2.));
netcdf.putAtt(ncid,NPSALID,'valid_max',single(41.));
% netcdf.putAtt(ncid,NPSALID,'comment','In situ measurement');
netcdf.putAtt(ncid,NPSALID,'C_format','%9.3f');
netcdf.putAtt(ncid,NPSALID,'FORTRAN_format','F9.3');
netcdf.putAtt(ncid,NPSALID,'resolution',single(0.001));

NPSALQCID=netcdf.defVar(ncid,'PSAL_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPSALQCID,'long_name','quality flag');
netcdf.putAtt(ncid,NPSALQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NPSALQCID,'_FillValue',' ');

NPSALADID=netcdf.defVar(ncid,'PSAL_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPSALADID,'long_name','Practical salinity');
netcdf.putAtt(ncid,NPSALADID,'standard_name','sea_water_salinity');
netcdf.putAtt(ncid,NPSALADID,'units','psu');
netcdf.putAtt(ncid,NPSALADID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NPSALADID,'valid_min',single(2.));
netcdf.putAtt(ncid,NPSALADID,'valid_max',single(41.));
% netcdf.putAtt(ncid,NPSALADID,'comment','In situ measurement');
netcdf.putAtt(ncid,NPSALADID,'C_format','%9.3f');
netcdf.putAtt(ncid,NPSALADID,'FORTRAN_format','F9.3');
netcdf.putAtt(ncid,NPSALADID,'resolution',single(0.001));

NPSALADQCID=netcdf.defVar(ncid,'PSAL_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
netcdf.putAtt(ncid,NPSALADQCID,'long_name','quality flag');
netcdf.putAtt(ncid,NPSALADQCID,'conventions','Argo reference table 2');
netcdf.putAtt(ncid,NPSALADQCID,'_FillValue',' ');

NPRESADERRID=netcdf.defVar(ncid,'PRES_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
% netcdf.putAtt(ncid,'PRES_ADJUSTED_ERROR','long_name','error on sea pressure');
netcdf.putAtt(ncid,NPRESADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
netcdf.putAtt(ncid,NPRESADERRID,'C_format','%7.1f');
netcdf.putAtt(ncid,NPRESADERRID,'FORTRAN_format','F7.1');
netcdf.putAtt(ncid,NPRESADERRID,'resolution',single(0.1));
netcdf.putAtt(ncid,NPRESADERRID,'units','decibar');
netcdf.putAtt(ncid,NPRESADERRID,'_FillValue',single(fval));

NTEMPADERRID=netcdf.defVar(ncid,'TEMP_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
% netcdf.putAtt(ncid,'TEMP_ADJUSTED_ERROR','long_name','error on sea temperature in-situ ITS-90 scale');
netcdf.putAtt(ncid,NTEMPADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
netcdf.putAtt(ncid,NTEMPADERRID,'units','degree_Celsius');
netcdf.putAtt(ncid,NTEMPADERRID,'C_format','%9.3f');
netcdf.putAtt(ncid,NTEMPADERRID,'FORTRAN_format','F9.3');
netcdf.putAtt(ncid,NTEMPADERRID,'resolution',single(0.001));
netcdf.putAtt(ncid,NTEMPADERRID,'_FillValue',single(fval));

NPSALADERRID=netcdf.defVar(ncid,'PSAL_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
% netcdf.putAtt(ncid,'PSAL_ADJUSTED_ERROR','long_name','error on practical salinity');
netcdf.putAtt(ncid,NPSALADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
netcdf.putAtt(ncid,NPSALADERRID,'units','psu');
netcdf.putAtt(ncid,NPSALADERRID,'C_format','%9.3f');
netcdf.putAtt(ncid,NPSALADERRID,'FORTRAN_format','F9.3');
netcdf.putAtt(ncid,NPSALADERRID,'resolution',single(0.001));
netcdf.putAtt(ncid,NPSALADERRID,'_FillValue',single(fval));

NPARAID=netcdf.defVar(ncid,'PARAMETER','NC_CHAR',[STR16,NPARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NPARAID,'long_name','List of parameters with calibration information');
netcdf.putAtt(ncid,NPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NPARAID,'_FillValue',' ');

NSCICALEQUID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_EQUATION','NC_CHAR',[STR256,NPARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALEQUID,'long_name','Calibration equation for this parameter');
netcdf.putAtt(ncid,NSCICALEQUID,'_FillValue',' ');

NSCICALCOEFID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_COEFFICIENT','NC_CHAR',[STR256,NPARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALCOEFID,'long_name','Calibration coefficients for this equation');
netcdf.putAtt(ncid,NSCICALCOEFID,'_FillValue',' ');

NSCICALCOMID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_COMMENT','NC_CHAR',[STR256,NPARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALCOMID,'long_name','Comment applying to this parameter calibration');
netcdf.putAtt(ncid,NSCICALCOMID,'_FillValue',' ');

NSCICALDAID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_DATE','NC_CHAR',[DaTi,NPARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALDAID,'long_name','Date of calibration');
netcdf.putAtt(ncid,NSCICALDAID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NSCICALDAID,'_FillValue',' ');


%----History fields

NHISINSTID=netcdf.defVar(ncid,'HISTORY_INSTITUTION','NC_CHAR',[STR4,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISINSTID,'long_name','Institution which performed action');
netcdf.putAtt(ncid,NHISINSTID,'conventions','Argo reference table 4');
netcdf.putAtt(ncid,NHISINSTID,'_FillValue',' ');

NHISSTEPID=netcdf.defVar(ncid,'HISTORY_STEP','NC_CHAR',[STR4,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISSTEPID,'long_name','Step in data processing');
netcdf.putAtt(ncid,NHISSTEPID,'conventions','Argo reference table 12');
netcdf.putAtt(ncid,NHISSTEPID,'_FillValue',' ');

NHISSOFTID=netcdf.defVar(ncid,'HISTORY_SOFTWARE','NC_CHAR',[STR4,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISSOFTID,'long_name','Name of software which performed action');
netcdf.putAtt(ncid,NHISSOFTID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISSOFTID,'_FillValue',' ');

NHISSOFTREID=netcdf.defVar(ncid,'HISTORY_SOFTWARE_RELEASE','NC_CHAR',[STR4,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISSOFTREID,'long_name','Version/release of software which performed action');
netcdf.putAtt(ncid,NHISSOFTREID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISSOFTREID,'_FillValue',' ');

NHISREFID=netcdf.defVar(ncid,'HISTORY_REFERENCE','NC_CHAR',[STR64,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISREFID,'long_name','Reference of database');
netcdf.putAtt(ncid,NHISREFID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISREFID,'_FillValue',' ');

NHISDAID=netcdf.defVar(ncid,'HISTORY_DATE','NC_CHAR',[DaTi,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISDAID,'long_name','Date the history record was created');
netcdf.putAtt(ncid,NHISDAID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NHISDAID,'_FillValue',' ');

NHISACTID=netcdf.defVar(ncid,'HISTORY_ACTION','NC_CHAR',[STR4,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISACTID,'long_name','Action performed on data');
netcdf.putAtt(ncid,NHISACTID,'conventions','Argo reference table 7');
netcdf.putAtt(ncid,NHISACTID,'_FillValue',' ');

NHISPARAID=netcdf.defVar(ncid,'HISTORY_PARAMETER','NC_CHAR',[STR16,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISPARAID,'long_name','Station parameter action is performed on');
netcdf.putAtt(ncid,NHISPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NHISPARAID,'_FillValue',' ');

NHISSTAPRESID=netcdf.defVar(ncid,'HISTORY_START_PRES','NC_FLOAT',[N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISSTAPRESID,'long_name','Start pressure action applied on');
% netcdf.putAtt(ncid,'HISTORY_START_PRES'}.conventions='Argo reference table 4');
netcdf.putAtt(ncid,NHISSTAPRESID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NHISSTAPRESID,'units','decibar');

NHISSTOPPRESID=netcdf.defVar(ncid,'HISTORY_STOP_PRES','NC_FLOAT',[N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISSTOPPRESID,'long_name','Stop pressure action applied on');
% netcdf.putAtt(ncid,'HISTORY_STOP_PRES'}.conventions='Argo reference table 4');
netcdf.putAtt(ncid,NHISSTOPPRESID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NHISSTOPPRESID,'units','decibar');

NHISPREVALID=netcdf.defVar(ncid,'HISTORY_PREVIOUS_VALUE','NC_FLOAT',[N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISPREVALID,'long_name','Parameter/Flag previous value before action');
% netcdf.putAtt(ncid,'HISTORY_PREVIOUS_VALUE'}.conventions='Argo reference table 4');
netcdf.putAtt(ncid,NHISPREVALID,'_FillValue',single(fval));

NHISQCTID=netcdf.defVar(ncid,'HISTORY_QCTEST','NC_CHAR',[STR16,N_PROFID,NHISID]);
netcdf.putAtt(ncid,NHISQCTID,'long_name','Documentation of tests performed, tests failed (in hex form)');
netcdf.putAtt(ncid,NHISQCTID,'conventions','Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
netcdf.putAtt(ncid,NHISQCTID,'_FillValue',' ');

%--- Finished defining variables, now write values! -----------------------

netcdf.endDef(ncid);

netcdf.putVar(ncid,NDATYID,0,length('Argo profile'),'Argo profile');
netcdf.putVar(ncid,NFMVRID,0,length('3.1'),'3.1');
netcdf.putVar(ncid,NHDVRID,0,length(' 1.2'),' 1.2');
netcdf.putVar(ncid,NREDTID,0,length('19500101000000'),'19500101000000');

% Fill fields for each profile

nlv = nlevels;
if isfield(fp,'p_oxygen')   %dbdat.subtype == 1006 || dbdat.subtype==1017 || dbdat.subtype==1008 || dbdat.subtype==1020
    nlv2 = fp.n_Oxysamples;
elseif dbdat.subtype == 1005
    nlv2=length(fp.nearsurfT);
else
    nlv2=[];
end
oqc(1:nlv2)=0;

% if nlevels==0
%     nc{'DATA_MODE'}(1)=' ';
% elseif(adjusted)
% if nlvls==0
%     nc{'DATA_MODE'}(2)=' ';
% elseif(adjusted)
%     nc{'DATA_MODE'}(2)='A';
% else
%     nc{'DATA_MODE'}(2)='R';
% end    

for ii = 1:nin
    if(adjusted)
        netcdf.putVar(ncid,NDAMOID,ii-1,1,'A');
    else
        netcdf.putVar(ncid,NDAMOID,ii-1,1,'R');
    end
    
    aa=int2str(dbdat.maker_id);
    netcdf.putVar(ncid,NFLSERNOID,[0,ii-1],[length(aa),1],aa); %OK
    aa = num2str(dbdat.wmo_id);
    netcdf.putVar(ncid,NPLANUID,[0,ii-1],[length(aa),1],aa);
    if ~isempty(strfind(dbdat.owner,'COOE'))
        netcdf.putVar(ncid,NDATYID,[0,ii-1],[length('Cooperative Ocean Observing Exp'),1],'Cooperative Ocean Observing Exp');
    else
        aa=ARGO_SYS_PARAM.Proj;
        netcdf.putVar(ncid,NPRONAID,[0,ii-1],[length(aa),1],aa);  %'Argo AUSTRALIA';
    end
    if isfield(fp,'PI')
        netcdf.putVar(ncid,NPINAID,[0,ii-1],[length(fp.PI),1],fp.PI);
    else
        netcdf.putVar(ncid,NPINAID,[0,ii-1],[length(dbdat.PI),1],dbdat.PI) ; 
    end
    
    netcdf.putVar(ncid,NSTAPARAID,[0,0,ii-1],[length('PRES'),1,1],'PRES');
    netcdf.putVar(ncid,NSTAPARAID,[0,1,ii-1],[length('TEMP'),1,1],'TEMP');
    if ii==1 | (ii==2 & dbdat.subtype~=1005)
        netcdf.putVar(ncid,NSTAPARAID,[0,2,ii-1],[length('PSAL'),1,1],'PSAL');
    end
    
    netcdf.putVar(ncid,NCYCNUMID,ii-1,1,fp.profile_number);
    
    if (dbdat.subtype==9999)  %EM floats with bidirectional sampling
        if rem(fp.profile_number,2)==1;
            up=0;
            netcdf.putVar(ncid,NDIRID,ii-1,1,'D');
        else
            up=1;
            netcdf.putVar(ncid,NDIRID,ii-1,1,'A');
        end
    else
        up=1;
        netcdf.putVar(ncid,NDIRID,ii-1,1,'A');
    end
    
    %    if dbdat.maker==2 & dbdat.subtype==4
    %        irev = 1:nlv;
    %    else
    irev = nlv:-1:1;
    %    end
    if ~isempty(nlv2)
        irev2=nlv2:-1:1;
    end
    if ispc
        today_str=datestr(now,30);
        today_str(9)=[];
    else
        [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
    end
    
    today_str=today_str(1:14);
    
    cd=gregorian(fp.jday(end));
    creation_date=sprintf('%04d%02d%02d%02d%02d%02d',cd);
    
    netcdf.putVar(ncid,NDACRID,0,length(creation_date),creation_date);
    netcdf.putVar(ncid,NDAUPID,0,length(today_str(1:14)),today_str(1:14));
    
    netcdf.putVar(ncid,NDACENID,[0,ii-1],[length(ARGO_SYS_PARAM.datacentre),1],ARGO_SYS_PARAM.datacentre);
    
    aa = [num2str(dbdat.wmo_id) '/' num2str(fp.profile_number)];
    
    netcdf.putVar(ncid,NDCREFID,[0,ii-1],[length(aa),1],aa);
    
    netcdf.putVar(ncid,NDASTAINDID,[0,ii-1],[length('2B  '),1],'2B  ');
    
    a2=99999;
    if ii==1
        if dbdat.iridium
            aa='Primary sampling: averaged []';
            [a2,mission]=getmission_number(dbdat.wmo_id,fp.profile_number,0,dbdat);
            %             a2=99999;
        else
            aa='Primary sampling: discrete []';
            a2=1;
        end
    elseif ii==2
        if dbdat.subtype == 1005
            aa='Near-surface sampling: discrete, pumped []';
            a2=1;
        else
            aa='Secondary sampling: discrete []';
            a2=getmission_number(dbdat.wmo_id,fp.profile_number,0,dbdat);
            %         a2=99999;
        end
    end
    
    netcdf.putVar(ncid,NVERSAMPSCID,[0,ii-1],[length(aa),1],aa);
    netcdf.putVar(ncid,NCONFMISNUMID,ii-1,length(a2),a2);
    
    switch dbdat.wmo_inst_type
        case '831'
            aa = ['PALACE '];
        case '846'
            aa = ['APEX '];
        case '841'
            aa = ['PROVOR'];
        case '839'
            aa = ['PROVOR_II'];
        case '844'
            aa = ['ARVOR '];
        case '851'
            aa = ['SOLO_W '];
        case '863'
            aa = ['NAVIS_A '];
        case '869'
            aa = ['NAVIS_EBR '];
        case '854'
            aa = ['S2A '];
    end
    
    for i=length(aa)+1:32
        aa=[aa ' '];
    end
    netcdf.putVar(ncid,NPLATYID,[0,ii-1],[length(aa),1],aa);
    
    
    ll = length(dbdat.wmo_inst_type);
    
    netcdf.putVar(ncid,NWMOINTYID,[0,ii-1],[length(dbdat.wmo_inst_type),1],dbdat.wmo_inst_type );
    
    s=getadditionalinfo(dbdat.wmo_id);
    aa=s.Firmware_Revision;
    if length(aa)>32;
        aa=aa(1:32);
    end
    netcdf.putVar(ncid,NFIRVERID,[0,ii-1],[length(aa),1],aa);
    
    %position information
    %find the first occurrence of a good position
    order = [1,2,0,5,8,9,3,4,7]; % 7 is "unused", but kept here
    [~,ia,~] = intersect(fp.pos_qc,order,'stable'); 
    
    if isfield(fp,'jday_location') & ~isempty(fp.jday_location)
        jday_ref_1950 = fp.jday_location(ia(1)) - julian([1950 1 1 0 0 0]);
    else
        jday_ref_1950 = fp.jday(1) - julian([1950 1 1 0 0 0]);
    end
    
    %     jday_asc_end_1950 = fp.jday_ascent_end - julian([1950 1 1 0 0 0]);
    if isempty(fp.jday_ascent_end) | abs((fp.jday_ascent_end-fp.jday(1)))>.9
        jday_asc_end_1950 = jday_ref_1950;
    else
        jday_asc_end_1950 = fp.jday_ascent_end - julian([1950 1 1 0 0 0]);
    end
    
    netcdf.putVar(ncid,NJULDID,ii-1,length(jday_asc_end_1950),jday_asc_end_1950);
    netcdf.putVar(ncid,NJULDQCID,ii-1,1,'1');
    netcdf.putVar(ncid,NJULDLOCID,ii-1,length(jday_ref_1950),jday_ref_1950);
    if ~isnan(fp.lat(ia(1)))
        netcdf.putVar(ncid,NLATID,ii-1,length(fp.lat(ia(1))),fp.lat(ia(1)));
        lonl = fp.lon(ia(1));
        if lonl > 180
            lonl = lonl - 360;
        end
        netcdf.putVar(ncid,NLONGID,ii-1,length(lonl),lonl);
        if isfield(fp,'pos_qc')           
            if fp.pos_qc(ia(1))~=0;
                if fp.pos_qc(ia(1))==7
                    netcdf.putVar(ncid,NPOSID,ii-1,1,'2');
                else
                    netcdf.putVar(ncid,NPOSID,ii-1,length(num2str(fp.pos_qc(ia(1)))),num2str(fp.pos_qc(ia(1))));
                end
            else
                netcdf.putVar(ncid,NPOSID,ii-1,1,'1');
            end
        else
            netcdf.putVar(ncid,NPOSID,ii-1,1,'1');
        end
        
    else
        netcdf.putVar(ncid,NPOSID,ii-1,1,'9');
    end
    if dbdat.iridium
        if fp.position_accuracy == 'I'
            netcdf.putVar(ncid,NPOSSYSID,[0,ii-1],[length('IRIDIUM'),1],'IRIDIUM');
        else
            netcdf.putVar(ncid,NPOSSYSID,[0,ii-1],[length('GPS'),1],'GPS');
        end
    else
        netcdf.putVar(ncid,NPOSSYSID,[0,ii-1],[length('ARGOS'),1],'ARGOS');
    end
    
    % Load profiles into netCDF files in REVERSE order (except for Provor CTS3 profiles).. We guard against
    % trying to write missing parameters, although this should happen rarely.
    
    if ii==1  % handle multiprofile files here with if/else
        
        if nlv>0
            netcdf.putVar(ncid,NPRESID,[0,ii-1],[length(nan2fv(fp.p_raw(irev),fval)),1],nan2fv(fp.p_raw(irev),fval));
            netcdf.putVar(ncid,NPRESQCID,[0,ii-1],[length(num2str(fp.p_qc(irev),'%1d')),1],nan2fv(num2str(fp.p_qc(irev),'%1d')));
            
            if isempty(fp.p_calibrate)
                if ispc
                    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles\float' num2str(dbdat.wmo_id)];
                else
                    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
                end
                [float,dbdat]=getargo(fp.wmo_id);
                for j=1:length(float)
                    if float(j).profile_number==fp.profile_number
                        np=j;
                        break
                    end
                end
                
                float = calibrate_p(float,np);
%                 [float,cal_rep] = calsal(float,np);
                [float,cal_rep] = calsal_DMoffset(float,np);
                float = qc_tests(dbdat,float,np);
                
                save(fnm,'float','-v6');
                
                fp=float(np);
            end
            
            pc=qc_apply4(fp.p_calibrate(irev),fp.p_qc(irev));
            
            netcdf.putVar(ncid,NPRESADID,[0,ii-1],[length(nan2fv(pc,fval)),1],nan2fv(pc,fval));
            netcdf.putVar(ncid,NPRESADQCID,[0,ii-1],[length(num2str(fp.p_qc(irev),'%1d')),1],num2str(fp.p_qc(irev),'%1d'));
            
            qcflag = overall_qcflag(fp.p_qc);
            netcdf.putVar(ncid,NPROPRESQCID,ii-1,length(qcflag),qcflag);
            
        end
        
        if ~isempty(fp.t_raw)
            netcdf.putVar(ncid,NTEMPID,[0,ii-1],[length(nan2fv(fp.t_raw(irev),fval)),1],nan2fv(fp.t_raw(irev),fval));
            netcdf.putVar(ncid,NTEMPQCID,[0,ii-1],[length(num2str(fp.t_qc(irev),'%1d')),1],num2str(fp.t_qc(irev),'%1d'));
            
            if adjusted
                if ~isempty(fp.t_calibrate)
                    tc=qc_apply4(fp.t_calibrate(irev),fp.t_qc(irev));
                    netcdf.putVar(ncid,NTEMPADID,[0,ii-1],[length(nan2fv(tc,fval)),1],nan2fv(tc,fval));
                    
                else
                    tc=qc_apply4(fp.t_raw(irev),fp.t_qc(irev));
                    netcdf.putVar(ncid,NTEMPADID,[0,ii-1],[length(nan2fv(tc,fval)),1],nan2fv(tc,fval));
                    
                end
                netcdf.putVar(ncid,NTEMPADQCID,[0,ii-1],[length(num2str(fp.t_qc(irev),'%1d')),1],num2str(fp.t_qc(irev),'%1d'));
                
            end
            qcflag = overall_qcflag(fp.t_qc);
            netcdf.putVar(ncid,NPROTEMPQCID,ii-1,length(qcflag),qcflag);
            
        end
        
        if ~isempty(fp.s_raw)
            netcdf.putVar(ncid,NPSALID,[0,ii-1],[length(nan2fv(fp.s_raw(irev),fval)),1],nan2fv(fp.s_raw(irev),fval));
            netcdf.putVar(ncid,NPSALQCID,[0,ii-1],[length(num2str(fp.s_qc(irev),'%1d')),1],num2str(fp.s_qc(irev),'%1d'));
            
            if adjusted
                if ~isempty(fp.s_calibrate)
                    sc=qc_apply4(fp.s_calibrate(irev),fp.s_qc(irev));
                else
                    sc = fp.s_raw(irev);
                end
                netcdf.putVar(ncid,NPSALADID,[0,ii-1],[length(nan2fv(sc,fval)),1], nan2fv(sc,fval));
                netcdf.putVar(ncid,NPSALADQCID,[0,ii-1],[length(num2str(fp.s_qc(irev),'%1d')),1],num2str(fp.s_qc(irev),'%1d'));
                
            end
            qcflag = overall_qcflag(fp.s_qc);
            netcdf.putVar(ncid,NPROPSALQCID,ii-1,length(qcflag),qcflag);
        end
        
        
    elseif ii==2
        if isfield(fp,'p_oxygen')    %dbdat.subtype==1006 || dbdat.subtype==1017 || dbdat.subtype==1008 || dbdat.subtype==1020
            p_c = fp.p_oxygen - fp.surfpres_used;  %calibrate fields
            p2=fp.p_oxygen;
            s2=fp.s_oxygen;
            t2=fp.t_oxygen;
        elseif dbdat.subtype==1005
            p_c = fp.nearsurfP - fp.surfpres_used;  %calibrate fields
            p2=fp.nearsurfP;
            s2(1:length(p2))=NaN;
            t2=fp.nearsurfT;
        end
        QC = qc_tests_Profile2(dbdat,p2,s2,t2,fp.p_oxygen_qc,fp.s_oxygen_qc,fp.t_oxygen_qc);
        %         QC.p=fp.p_oxygen_qc;
        %         QC.s=fp.s_oxygen_qc;
        %         QC.t=fp.t_oxygen_qc;
        
        if fp.c_ratio ~=1
            s_c = calsal_Profile2(p2,s2,t2,p_c,fp.c_ratio);
        else
            s_c = s2;
        end
        
        % need to take into account the primary QC values before assign
        % secondary QC:  AT Dec 2013
        
        priqcP=find(fp.p_qc>=3 & fp.p_qc<=4);
        priqcT=find(fp.t_qc>=3 & fp.t_qc<=4);
        priqcS=find(fp.s_qc>=3 & fp.s_qc<=4);
        
        if ~isempty(priqcP)
            ppbad=range(fp.p_calibrate(priqcP));
            ppreject=find(p2 > ppbad(1) & p2 < ppbad(2));
            QC.p(ppreject)=3;
            QC.s(ppreject)=3;
            QC.t(ppreject)=3;
            
        end
        
        if ~isempty(priqcT)
            if max(diff(priqcT)<=1)
                ppbad=range(fp.p_calibrate(priqcT));
                ppreject=find(p2 > ppbad(1) & p2 < ppbad(2));
                QC.t(ppreject)=3;
            end
        end
        
        if ~isempty(priqcS)
            if max(diff(priqcS)<=1)
                ppbad=range(fp.p_calibrate(priqcS));
                ppreject=find(p2 > ppbad(1) & p2 < ppbad(2));
                QC.s(ppreject)=3;
            end
        end
        
        
        if nlv2>0
            
            netcdf.putVar(ncid,NPRESID,[0,ii-1],[length(nan2fv(p2(irev2),fval)),1],nan2fv(p2(irev2),fval));
            netcdf.putVar(ncid,NPRESQCID,[0,ii-1],[length(num2str(QC.p(irev2),'%1d')),1],num2str(QC.p(irev2),'%1d'));
            pc=qc_apply4(p_c(irev2),QC.p(irev2));
            
            netcdf.putVar(ncid,NPRESADID,[0,ii-1],[length(nan2fv(pc,fval)),1],nan2fv(pc,fval));
            netcdf.putVar(ncid,NPRESADQCID,[0,ii-1],[length(num2str(QC.p(irev2),'%1d')),1],num2str(QC.p(irev2),'%1d'));
            qcflag = overall_qcflag(QC.p);
            netcdf.putVar(ncid,NPROPRESQCID,ii-1,length(qcflag),qcflag);
        end
        
        if ~isempty(t2)
            
            netcdf.putVar(ncid,NTEMPID,[0,ii-1],[length( nan2fv(t2(irev2),fval)),1], nan2fv(t2(irev2),fval));
            netcdf.putVar(ncid,NTEMPQCID,[0,ii-1],[length(num2str(QC.t(irev2),'%1d')),1],num2str(QC.t(irev2),'%1d'));
            if adjusted
                tc=qc_apply4(t2(irev2),QC.t(irev2));
                netcdf.putVar(ncid,NTEMPADID,[0,ii-1],[length(nan2fv(tc,fval)),1],nan2fv(tc,fval));
                netcdf.putVar(ncid,NTEMPADQCID,[0,ii-1],[length(num2str(QC.t(irev2),'%1d')),1],num2str(QC.t(irev2),'%1d'));
            end
            qcflag = overall_qcflag(QC.t);
            netcdf.putVar(ncid,NPROTEMPQCID,ii-1,length(qcflag),qcflag);
        end
        
        if dbdat.subtype ~=1005 & ~isempty(s2)
            
            netcdf.putVar(ncid,NPSALID,[0,ii-1],[length(nan2fv(s2(irev2),fval)),1],nan2fv(s2(irev2),fval));
            netcdf.putVar(ncid,NPSALQCID,[0,ii-1],[length(num2str(QC.s(irev2),'%1d')),1],num2str(QC.s(irev2),'%1d'));
            if adjusted
                sc=qc_apply4(s_c(irev2),QC.s(irev2));
                
                netcdf.putVar(ncid,NPSALADID,[0,ii-1],[length(nan2fv(sc,fval)),1], nan2fv(sc,fval));
                netcdf.putVar(ncid,NPSALADQCID,[0,ii-1],[length(num2str(QC.s(irev2),'%1d')),1],num2str(QC.s(irev2),'%1d'));
            end
            qcflag = overall_qcflag(QC.s);
            netcdf.putVar(ncid,NPROPSALQCID,ii-1,length(qcflag),qcflag);
        end
        
    end
    %
    % The ADJUSTED_ERROR fields can be left as initialised at FillValue
    
    netcdf.putVar(ncid,NPARAID,[0,0,0,ii-1],[length('PRES'),1,1,1],'PRES');
    netcdf.putVar(ncid,NPARAID,[0,1,0,ii-1],[length('TEMP'),1,1,1],'TEMP');
    if ii==1 | (ii==2 & dbdat.subtype~=1005)
        netcdf.putVar(ncid,NPARAID,[0,2,0,ii-1],[length('PSAL'),1,1,1],'PSAL');
        
        netcdf.putVar(ncid,NSCICALEQUID,[0,0,0,ii-1],[length('Pcorrected = Praw - surface offset'),1,1,1],'Pcorrected = Praw - surface offset');
        
        if ii==1 | (ii==2 & dbdat.subtype~=1005)
            netcdf.putVar(ncid,NSCICALEQUID,[0,2,0,ii-1],[length('Scorrected = S(Ccorrected,Traw,Pcorrected)'),1,1,1],'Scorrected = S(Ccorrected,Traw,Pcorrected)');
            
        end
        netcdf.putVar(ncid,NSCICALCOMID,[0,0,0,ii-1],[length('This sensor is subject to hysteresis'),1,1,1],'This sensor is subject to hysteresis');
        
        if(fp.TL_cal_done)
            netcdf.putVar(ncid,NSCICALCOMID,[0,2,0,ii-1],[length('Thermal Lag correction according to Morison et al, 1994, JAOT was performed'),1,1,1],'Thermal Lag correction according to Morison et al, 1994, JAOT was performed');
        end
        
        netcdf.putVar(ncid,NSCICALDAID,[0,0,0,ii-1],[length(today_str),1,1,1],today_str);
        netcdf.putVar(ncid,NSCICALDAID,[0,2,0,ii-1],[length(today_str),1,1,1],today_str);
        
        for jj = 1:6
            netcdf.putVar(ncid,NHISINSTID,[0,ii-1,jj-1],[length(ARGO_SYS_PARAM.datacentre),1,1],ARGO_SYS_PARAM.datacentre);
            qcdc=[ARGO_SYS_PARAM.datacentre 'QC'];
            netcdf.putVar(ncid,NHISSOFTID,[0,ii-1,jj-1],[length(qcdc),1,1],qcdc);
            netcdf.putVar(ncid,NHISSOFTREID,[0,ii-1,jj-1],[length('V4.0'),1,1],'V4.0');
            netcdf.putVar(ncid,NHISDAID,[0,ii-1,jj-1],[length(today_str),1,1],today_str);
        end
        
        netcdf.putVar(ncid,NHISSTEPID,[0,ii-1,0],[length('ARFM'),1,1],'ARFM');
        netcdf.putVar(ncid,NHISSTEPID,[0,ii-1,1],[length('ARGQ'),1,1],'ARGQ');
        netcdf.putVar(ncid,NHISSTEPID,[0,ii-1,2],[length('ARCA'),1,1],'ARCA');
        netcdf.putVar(ncid,NHISSTEPID,[0,ii-1,3],[length('ARUP'),1,1],'ARUP');
        
        for jj = 5:6
            netcdf.putVar(ncid,NHISSTEPID,[0,ii-1,jj-1],[length('ARGQ'),1,1],'ARGQ');
        end
        
        for jj = 1:4
            netcdf.putVar(ncid,NHISACTID,[0,ii-1,jj-1],[length('  IP'),1,1],'  IP');
        end
        netcdf.putVar(ncid,NHISACTID,[0,ii-1,4],[length('QCP$'),1,1],'QCP$');
        netcdf.putVar(ncid,NHISACTID,[0,ii-1,5],[length('QCF$'),1,1],'QCF$');
        
        % We store vectors of tests performed or failed. This is packed into
        % one number. eg  if failed = 1 7 13, then ans = 2^1 + 2^7 + 2^13
        
        jj = find(fp.testsperformed);
        qp = dec2hex(sum(power(2,jj)));
        netcdf.putVar(ncid,NHISQCTID,[0,ii-1,4],[length(qp),1,1],qp);
        jj = find(fp.testsfailed);
        qf = dec2hex(sum(power(2,jj)));
        netcdf.putVar(ncid,NHISQCTID,[0,ii-1,5],[length(qf),1,1],qf);
        
        % Now record each block of values that failed QC tests
        pars = [1 2];
        if dbdat.subtype==1005 & ii==2
            pars = [1];
        end
        for par = pars
            vqc=[];
            switch par
                case 1
                    if ii==1
                        vqc = fp.t_qc;
                    else
                        try
                            vqc = QC.t;
                        catch
                            vqc=[];
                        end
                    end
                    pnam = 'TEMP';
                case 2
                    if ii==1
                        vqc = fp.s_qc;
                    else
                        try
                            vqc = QC.s;
                        catch
                            vqc=[];
                        end
                    end
                    pnam = 'PSAL';
            end
            
            %         % Find start and end of each patch of flagged data
            bad = diff([0 (vqc>1 & vqc<9) 0]);
            kst = find(bad==1);
            kend = find(bad==-1)-1;
            nh=length(ARGO_SYS_PARAM.datacentre);
            
            for kk = 1:length(kst)
                jj = nh + kk;
                netcdf.putVar(ncid,NHISINSTID,[0,ii-1,jj-1],[length(ARGO_SYS_PARAM.datacentre),1,1],ARGO_SYS_PARAM.datacentre);
                qcdc=[ARGO_SYS_PARAM.datacentre 'QC'];
                netcdf.putVar(ncid,NHISSOFTID,[0,ii-1,jj-1],[length(qcdc),1,1],qcdc);
                netcdf.putVar(ncid,NHISSTEPID,[0,ii-1,jj-1],[length('ARGQ'),1,1],'ARGQ');
                netcdf.putVar(ncid,NHISSOFTREID,[0,ii-1,jj-1],[length('V4.0'),1,1],'V4.0');
                netcdf.putVar(ncid,NHISDAID,[0,ii-1,jj-1],[length( today_str),1,1], today_str);
                netcdf.putVar(ncid,NHISACTID,[0,ii-1,jj-1],[length('CF'),1,1],'CF');
                netcdf.putVar(ncid,NHISPARAID,[0,ii-1,jj-1],[length(pnam),1,1],pnam);
                
                if ii==1
                    if ~isnan(fp.p_calibrate(kend(kk)))
                        netcdf.putVar(ncid,NHISSTAPRESID,[ii-1,jj-1],[length(fp.p_calibrate(kend(kk))),1],fp.p_calibrate(kend(kk)));
                    end
                else
                    if ~isnan(p_c(kend(kk)))
                        netcdf.putVar(ncid,NHISSTAPRESID,[ii-1,jj-1],[length(p_c(kend(kk))),1],p_c(kend(kk)));
                        
                    end
                end
                if ii==1
                    if ~isnan(fp.p_calibrate(kst(kk)))
                        netcdf.putVar(ncid,NHISSTOPPRESID,[ii-1,jj-1],[length(fp.p_calibrate(kst(kk))),1],fp.p_calibrate(kst(kk)));
                    end
                else
                    if ~isnan(p_c(kst(kk)))
                        netcdf.putVar(ncid,NHISSTOPPRESID,[ii-1,jj-1],[length(p_c(kst(kk))),1],p_c(kst(kk)));
                    end
                end
                netcdf.putVar(ncid,NHISPREVALID,[ii-1,jj-1],[length(1),1],1);
            end
        end
        
    end
end
    
    netcdf.close(ncid)
    
    if exist('isingdac')==2
        if isingdac(fname)~=2 & ~strcmp('evil',dbdat.status) %& ~strcmp('hold',dbdat.status) %DON'T DELIVER these!!!!!
            if ispc
                [status,ww] = system(['copy /Y ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
            else
                [status,ww] = system(['cp -f ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
            end
            if status~=0
                logerr(3,['Copy of ' fname ' to export/ failed:' ww]);
            end
        end
    end
    if dbdat.oxy
        argoprofile_Bfile_nc(dbdat,fp);
    end
    if isfield(fp,'p_desc_raw')
        argoprofile_desc_ncWindows(dbdat,fp);
    end


%----------------------------------------------------------------------------
function vo = nan2fv(vin,fval)

vo = vin;
jk = find(isnan(vin));
if ~isempty(jk) 
   vo(jk) = fval;
end

return
%----------------------------------------------------------------------------
