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
% Author:  Jeff Dunn CSIRO/BoM  Aug 2006
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
%  converted to separate out Bio data: AT Feb 2014
%
% note - only PRES can be found in these files. P T and S are in the R or D
% files only.


function argoprofile_Bfile_ncV3(dbdat,fp)

global ARGO_SYS_PARAM

% Developer note: We may like to use N_PROF as the unlimited dimension for
%  local all-profiles-for-one-float files? Would switch with HISTORY 
%  dimension, which could be fixed at some generous amount.

% if there's no data, we won't create these  files but all other files are
% fine...  and we detect no data by no pressures!

if(isfield(fp,'p_oxygen') && isempty(fp.p_raw) && isempty(fp.p_oxygen))
    return
elseif (~isfield(fp,'p_oxygen') && isempty(fp.p_raw))
    return
end

% DATA_MODE could be set by testing for non-empty s_calibrate, but for now
% fix to 'adjusted'.
% if(isempty(fp.s_calibrate))
    adjusted=0;
% else
%     adjusted = 1;
% end

%turn off calibration for the moment...: (turned back on 6/11/2007:AT)
%adjusted=0;

% AT: only R data can be found in the bio files

% if adjusted
%     datamode = 'A';
% else
    datamode = 'R';
% end

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

% if dbdat.subtype == 1006 | dbdat.subtype == 1017  | dbdat.subtype == 1008 ...
%         | dbdat.subtype==1020  %| dbdat.subtype==1005 

% this depends on the sub axis of p_oxygenm not hte subtype alone:
if isfield(fp,'p_oxygen')
    nin=2;
else  % this might change later:
    nin=1;
end
   pnum = fp.profile_number;
   pno=sprintf('%3.3i',pnum);
   if ispc
       fname = [ndir '\BR' int2str(dbdat.wmo_id) '_' pno '.nc'];
   else
       fname = [ndir '/BR' int2str(dbdat.wmo_id) '_' pno '.nc'];
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
%    hist=attnc(fname,'global','history');
%    dc=getnc(fname,'DATE_CREATION');
   end
   ncid=netcdf.create(fname,'CLOBBER');
else
   ncid=netcdf.create(fname,'NOCLOBBER');
end

if isfield(fp,'p_oxygen')
    nlevels2 = length(fp.p_oxygen);
end
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

n_param = 1;  % only PRES is carried in these files..
if dbdat.oxy  % & dbdat.subtype~=1006
    if ~isfield(fp,'oxyT_raw')   %  dbdat.subtype==1007 | dbdat.subtype==38 | dbdat.subtype==1008 | ...
% dbdat.subtype==22 | dbdat.subtype==40 
        n_param = n_param+2;
    else
        n_param = n_param+3;
        if isfield(fp,'t_oxygen_volts')
            n_param = n_param+1;
        end
    end
    if isfield(fp,'Rphase_raw')
            n_param = n_param+1;
    end
end

if dbdat.flbb
    n_param=n_param+5;
end

if isfield(fp,'CDOM_raw')
    n_param=n_param+2;
end

if dbdat.flbb2
    n_param=n_param+2;
end

if dbdat.tmiss
  n_param = n_param+2;
end

if dbdat.eco
    n_param = n_param+6;
end

if dbdat.suna
    n_param=n_param+1;
end

if dbdat.irr
    if dbdat.irr2       
        n_param=n_param+8;
    else
        n_param=n_param+16;
    end
end

if dbdat.pH
    n_param=n_param+3;
end

if isfield(fp,'Tilt')
    n_param=n_param+1;
end
   
N_PARID=netcdf.defDim(ncid,'N_PARAM',n_param);

% Argo netCDF files are required to have N_HISTORY as the unlimited dimension!
N_HISID=netcdf.defDim(ncid,'N_HISTORY',netcdf.getConstant('NC_UNLIMITED'));

NDATYID=netcdf.defVar(ncid,'DATA_TYPE','NC_CHAR',STR32); 
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

NSTAPARAID=netcdf.defVar(ncid,'STATION_PARAMETERS','NC_CHAR',[STR64,N_PARID,N_PROFID]); %STR16nc%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

NPARADAMOID=netcdf.defVar(ncid,'PARAMETER_DATA_MODE','NC_CHAR',[N_PARID,N_PROFID]);
netcdf.putAtt(ncid,NPARADAMOID,'long_name','Delayed mode or real time data');
netcdf.putAtt(ncid,NPARADAMOID,'conventions','R : real time; D : delayed mode; A : real time with adjustment');
netcdf.putAtt(ncid,NPARADAMOID,'_FillValue',' ');  

NFLSERNOID=netcdf.defVar(ncid,'FLOAT_SERIAL_NO','NC_CHAR',[STR32,N_PROFID]);
netcdf.putAtt(ncid,NFLSERNOID,'long_name','Serial number of the float');
netcdf.putAtt(ncid,NFLSERNOID,'_FillValue',' '); 

NFIRVERID=netcdf.defVar(ncid,'FIRMWARE_VERSION','NC_CHAR',[STR32,N_PROFID]);
netcdf.putAtt(ncid,NFIRVERID,'long_name','Instrument firmware version');
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

% NPROPRESQCID=netcdf.defVar(ncid,'PROFILE_PRES_QC','NC_CHAR',N_PROFID);
% netcdf.putAtt(ncid,NPROPRESQCID,'long_name','Global quality flag of PRES profile');
% netcdf.putAtt(ncid,NPROPRESQCID,'conventions','Argo reference table 2a');
% netcdf.putAtt(ncid,NPROPRESQCID,'_FillValue',' '); 

NVERSAMPSCID=netcdf.defVar(ncid,'VERTICAL_SAMPLING_SCHEME','NC_CHAR',[STR256,N_PROFID]);
netcdf.putAtt(ncid,NVERSAMPSCID,'long_name','Vertical sampling scheme');
netcdf.putAtt(ncid,NVERSAMPSCID,'conventions','Argo reference table 16');
netcdf.putAtt(ncid,NVERSAMPSCID,'_FillValue',' '); 

NCONFMISNUMID=netcdf.defVar(ncid,'CONFIG_MISSION_NUMBER','NC_INT',N_PROFID);
netcdf.putAtt(ncid,NCONFMISNUMID,'long_name','Unique number denoting the missions performed by the float');
netcdf.putAtt(ncid,NCONFMISNUMID,'conventions','1...N, 1 : first complete mission');
netcdf.putAtt(ncid,NCONFMISNUMID,'_FillValue',int32(fval)); 


if dbdat.oxy
    NPRODOXYQCID=netcdf.defVar(ncid,'PROFILE_DOXY_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOXYQCID,'long_name','Global quality flag of DOXY profile');
    netcdf.putAtt(ncid,NPRODOXYQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOXYQCID,'_FillValue',' ');

    
    if isfield(fp,'oxyT_raw')   %(dbdat.subtype~=38 && dbdat.subtype~=1007 && dbdat.subtype~=1008 && ...
        %             dbdat.subtype~=22 && dbdat.subtype~=40)

        NPROTEMPDOXYQCID=netcdf.defVar(ncid,'PROFILE_TEMP_DOXY_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROTEMPDOXYQCID,'long_name','Global quality flag of TEMP_DOXY profile');
        netcdf.putAtt(ncid,NPROTEMPDOXYQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROTEMPDOXYQCID,'_FillValue',' ');
        
    end
    
    if isfield(fp,'oxy_umolar')   %(dbdat.subtype==32 || dbdat.subtype==35 || dbdat.subtype==31 || dbdat.subtype==40)

        NPROMOLARDOXYQCID=netcdf.defVar(ncid,'PROFILE_MOLAR_DOXY_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROMOLARDOXYQCID,'long_name','Global quality flag of MOLAR_DOXY profile');
        netcdf.putAtt(ncid,NPROMOLARDOXYQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROMOLARDOXYQCID,'_FillValue',' ');
        
    elseif isfield(fp,'SBEOxyfreq_raw')   %(dbdat.subtype==38 || dbdat.subtype==22 || dbdat.subtype==1007 || dbdat.subtype==1008)

        NPROFREQDOXYQCID=netcdf.defVar(ncid,'PROFILE_FREQUENCY_DOXY_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROFREQDOXYQCID,'long_name','Global quality flag of FREQUENCY_DOXY profile');
        netcdf.putAtt(ncid,NPROFREQDOXYQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROFREQDOXYQCID,'_FillValue',' ');        
        
    elseif isfield(fp,'Bphase_raw')    %dbdat.subtype==1002 || dbdat.subtype==1012  || dbdat.subtype==1006 || dbdat.subtype==1020

        NPROBPHASEDOXYQCID=netcdf.defVar(ncid,'PROFILE_BPHASE_DOXY_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROBPHASEDOXYQCID,'long_name','Global quality flag of BPHASE_DOXY profile');
        netcdf.putAtt(ncid,NPROBPHASEDOXYQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROBPHASEDOXYQCID,'_FillValue',' ');        
        
    elseif isfield(fp,'O2phase_raw')    %dbdat.subtype==1017

        NPROPHASEDOXYQCID=netcdf.defVar(ncid,'PROFILE_PHASE_DELAY_DOXY_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROPHASEDOXYQCID,'long_name','Global quality flag of PHASE_DELAY_DOXY profile');
        netcdf.putAtt(ncid,NPROPHASEDOXYQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROPHASEDOXYQCID,'_FillValue',' ');        

        if isfield(fp,'t_oxygen_volts')
        NPROTEMPVOLDOXYQCID=netcdf.defVar(ncid,'PROFILE_TEMP_VOLTAGE_DOXY_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROTEMPVOLDOXYQCID,'long_name','Global quality flag of TEMP_VOLTAGE_DOXY profile');
        netcdf.putAtt(ncid,NPROTEMPVOLDOXYQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROTEMPVOLDOXYQCID,'_FillValue',' ');            

        end
        
    elseif isfield(fp,'Tphase_raw')    %dbdat.subtype==1030
 
        NPROTPHASEDOXYQCID=netcdf.defVar(ncid,'PROFILE_TPHASE_DOXY_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROTPHASEDOXYQCID,'long_name','Global quality flag of TPHASE_DOXY profile');
        netcdf.putAtt(ncid,NPROTPHASEDOXYQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROTPHASEDOXYQCID,'_FillValue',' ');        

        if isfield(fp,'Rphase_raw')    %dbdat.subtype==1030

            NPRORPHASEDOXYQCID=netcdf.defVar(ncid,'PROFILE_RPHASE_DOXY_QC','NC_CHAR',N_PROFID);
            netcdf.putAtt(ncid,NPRORPHASEDOXYQCID,'long_name','Global quality flag of RPHASE_DOXY profile');
            netcdf.putAtt(ncid,NPRORPHASEDOXYQCID,'conventions','Argo reference table 2a');
            netcdf.putAtt(ncid,NPRORPHASEDOXYQCID,'_FillValue',' ');

        end
    end
end

if dbdat.flbb
        NPROCHLAQCID=netcdf.defVar(ncid,'PROFILE_CHLA_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROCHLAQCID,'long_name','Global quality flag of CHLA profile');
        netcdf.putAtt(ncid,NPROCHLAQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROCHLAQCID,'_FillValue',' ');    

        NPROFLUOCHLAQCID=netcdf.defVar(ncid,'PROFILE_FLUORESCENCE_CHLA_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROFLUOCHLAQCID,'long_name','Global quality flag of FLUORESCENCE_CHLA profile');
        netcdf.putAtt(ncid,NPROFLUOCHLAQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROFLUOCHLAQCID,'_FillValue',' ');    

        NPROBBP700QCID=netcdf.defVar(ncid,'PROFILE_BBP700_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROBBP700QCID,'long_name','Global quality flag of BBP700 profile');
        netcdf.putAtt(ncid,NPROBBP700QCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROBBP700QCID,'_FillValue',' ');       

        NPROBETABACK700QCID=netcdf.defVar(ncid,'PROFILE_BETA_BACKSCATTERING700_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROBETABACK700QCID,'long_name','Global quality flag of BETA_BACKSCATTERING700 profile');
        netcdf.putAtt(ncid,NPROBETABACK700QCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROBETABACK700QCID,'_FillValue',' ');       

        NPROTEMPCPUCHLAQCID=netcdf.defVar(ncid,'PROFILE_TEMP_CPU_CHLA_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROTEMPCPUCHLAQCID,'long_name','Global quality flag of TEMP_CPU_CHLA profile');
        netcdf.putAtt(ncid,NPROTEMPCPUCHLAQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROTEMPCPUCHLAQCID,'_FillValue',' ');       

        if dbdat.flbb2
            NPROBBP532QCID=netcdf.defVar(ncid,'PROFILE_BBP532_QC','NC_CHAR',N_PROFID);
            netcdf.putAtt(ncid,NPROBBP532QCID,'long_name','Global quality flag of BBP532 profile');
            netcdf.putAtt(ncid,NPROBBP532QCID,'conventions','Argo reference table 2a');
            netcdf.putAtt(ncid,NPROBBP532QCID,'_FillValue',' ');
            
            NPROBETABACK532QCID=netcdf.defVar(ncid,'PROFILE_BETA_BACKSCATTERING532_QC','NC_CHAR',N_PROFID);
            netcdf.putAtt(ncid,NPROBETABACK532QCID,'long_name','Global quality flag of BETA_BACKSCATTERING532 profile');
            netcdf.putAtt(ncid,NPROBETABACK532QCID,'conventions','Argo reference table 2a');
            netcdf.putAtt(ncid,NPROBETABACK532QCID,'_FillValue',' ');
        end
    
    if isfield(fp,'CDOM_raw')
        
        NPROFLUOCDOMQCID=netcdf.defVar(ncid,'PROFILE_FLUORESCENCE_CDOM_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROFLUOCDOMQCID,'long_name','Global quality flag of FLUORESCENCE_CDOM profile');
        netcdf.putAtt(ncid,NPROFLUOCDOMQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROFLUOCDOMQCID,'_FillValue',' ');           

        NPROCDOMQCID=netcdf.defVar(ncid,'PROFILE_CDOM_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROCDOMQCID,'long_name','Global quality flag of CDOM profile');
        netcdf.putAtt(ncid,NPROCDOMQCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROCDOMQCID,'_FillValue',' ');          

    end
end
    
if dbdat.tmiss
    
    NPROTRANSPARBEANATT660QCID=netcdf.defVar(ncid,'PROFILE_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROTRANSPARBEANATT660QCID,'long_name','Global quality flag of TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660 profile');
    netcdf.putAtt(ncid,NPROTRANSPARBEANATT660QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROTRANSPARBEANATT660QCID,'_FillValue',' ');

    NPROCP660QCID=netcdf.defVar(ncid,'PROFILE_CP660_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROCP660QCID,'long_name','Global quality flag of CP660 profile');
    netcdf.putAtt(ncid,NPROCP660QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROCP660QCID,'_FillValue',' ');
    
end

if dbdat.eco

    if dbdat.flbb
        NPROBBP7002QCID=netcdf.defVar(ncid,'PROFILE_BBP700_2_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROBBP7002QCID,'long_name','Global quality flag of BBP700_2 profile');
        netcdf.putAtt(ncid,NPROBBP7002QCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROBBP7002QCID,'_FillValue',' ');           

        NPROBETABACK7002QCID=netcdf.defVar(ncid,'PROFILE_BETA_BACKSCATTERING700_2_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROBETABACK7002QCID,'long_name','Global quality flag of BETA_BACKSCATTERING700_2 profile');
        netcdf.putAtt(ncid,NPROBETABACK7002QCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROBETABACK7002QCID,'_FillValue',' ');           

    else
        NPROBBP700QCID=netcdf.defVar(ncid,'PROFILE_BBP700_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROBBP700QCID,'long_name','Global quality flag of BBP700 profile');
        netcdf.putAtt(ncid,NPROBBP700QCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROBBP700QCID,'_FillValue',' ');     

        NPROBETABACK700QCID=netcdf.defVar(ncid,'PROFILE_BETA_BACKSCATTERING700_QC','NC_CHAR',N_PROFID);
        netcdf.putAtt(ncid,NPROBETABACK700QCID,'long_name','Global quality flag of BETA_BACKSCATTERING700 profile');
        netcdf.putAtt(ncid,NPROBETABACK700QCID,'conventions','Argo reference table 2a');
        netcdf.putAtt(ncid,NPROBETABACK700QCID,'_FillValue',' ');                     
    end
    
    NPROBBP532QCID=netcdf.defVar(ncid,'PROFILE_BBP532_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROBBP532QCID,'long_name','Global quality flag of BBP532 profile');
    netcdf.putAtt(ncid,NPROBBP532QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROBBP532QCID,'_FillValue',' ');

    NPROBETABACK532QCID=netcdf.defVar(ncid,'PROFILE_BETA_BACKSCATTERING532_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROBETABACK532QCID,'long_name','Global quality flag of BETA_BACKSCATTERING532 profile');
    netcdf.putAtt(ncid,NPROBETABACK532QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROBETABACK532QCID,'_FillValue',' ');

    NPROBBP470QCID=netcdf.defVar(ncid,'PROFILE_BBP470_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROBBP470QCID,'long_name','Global quality flag of BBP470 profile');
    netcdf.putAtt(ncid,NPROBBP470QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROBBP470QCID,'_FillValue',' '); 

    NPROBETABACK470QCID=netcdf.defVar(ncid,'PROFILE_BETA_BACKSCATTERING470_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROBETABACK470QCID,'long_name','Global quality flag of BETA_BACKSCATTERING470 profile');
    netcdf.putAtt(ncid,NPROBETABACK470QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROBETABACK470QCID,'_FillValue',' ');        
        
end

if dbdat.suna
    
    NPRONITRATEQCID=netcdf.defVar(ncid,'PROFILE_NITRATE_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRONITRATEQCID,'long_name','Global quality flag of NITRATE profile');
    netcdf.putAtt(ncid,NPRONITRATEQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRONITRATEQCID,'_FillValue',' '); 
    
end

if dbdat.irr & ~dbdat.irr2
    
    NPRODOWNIRRA412QCID=netcdf.defVar(ncid,'PROFILE_DOWN_IRRADIANCE412_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNIRRA412QCID,'long_name','Global quality flag of DOWN_IRRADIANCE412 profile');
    netcdf.putAtt(ncid,NPRODOWNIRRA412QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNIRRA412QCID,'_FillValue',' ');       

    NPRORAWDOWNIRRA412QCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_IRRADIANCE412_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA412QCID,'long_name','Global quality flag of RAW_DOWNWELLING_IRRADIANCE412 profile');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA412QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA412QCID,'_FillValue',' ');       

    NPRODOWNIRRA443QCID=netcdf.defVar(ncid,'PROFILE_DOWN_IRRADIANCE443_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNIRRA443QCID,'long_name','Global quality flag of DOWN_IRRADIANCE443 profile');
    netcdf.putAtt(ncid,NPRODOWNIRRA443QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNIRRA443QCID,'_FillValue',' ');     

    NPRORAWDOWNIRRA443QCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_IRRADIANCE443_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA443QCID,'long_name','Global quality flag of RAW_DOWNWELLING_IRRADIANCE443 profile');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA443QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA443QCID,'_FillValue',' ');            

    NPRODOWNIRRA490QCID=netcdf.defVar(ncid,'PROFILE_DOWN_IRRADIANCE490_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNIRRA490QCID,'long_name','Global quality flag of DOWN_IRRADIANCE490 profile');
    netcdf.putAtt(ncid,NPRODOWNIRRA490QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNIRRA490QCID,'_FillValue',' ');     
    
    NPRORAWDOWNIRRA490QCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_IRRADIANCE490_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA490QCID,'long_name','Global quality flag of RAW_DOWNWELLING_IRRADIANCE490 profile');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA490QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA490QCID,'_FillValue',' ');           

    NPRODOWNIRRA555QCID=netcdf.defVar(ncid,'PROFILE_DOWN_IRRADIANCE555_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNIRRA555QCID,'long_name','Global quality flag of DOWN_IRRADIANCE555 profile');
    netcdf.putAtt(ncid,NPRODOWNIRRA555QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNIRRA555QCID,'_FillValue',' ');        

    NPRORAWDOWNIRRA555QCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_IRRADIANCE555_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA555QCID,'long_name','Global quality flag of RAW_DOWNWELLING_IRRADIANCE555 profile');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA555QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA555QCID,'_FillValue',' ');             

    NPROUPRAD412QCID=netcdf.defVar(ncid,'PROFILE_UP_RADIANCE412_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROUPRAD412QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE412 profile');
    netcdf.putAtt(ncid,NPROUPRAD412QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROUPRAD412QCID,'_FillValue',' ');       

    NPRORAWUPRAD412QCID=netcdf.defVar(ncid,'PROFILE_RAW_UPWELLING_RADIANCE412','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWUPRAD412QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE412 profile');
    netcdf.putAtt(ncid,NPRORAWUPRAD412QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWUPRAD412QCID,'_FillValue',' ');        

    NPROUPRAD443QCID=netcdf.defVar(ncid,'PROFILE_UP_RADIANCE443_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROUPRAD443QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE443 profile');
    netcdf.putAtt(ncid,NPROUPRAD443QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROUPRAD443QCID,'_FillValue',' ');       

    NPRORAWUPRAD443QCID=netcdf.defVar(ncid,'PROFILE_RAW_UPWELLING_RADIANCE443','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWUPRAD443QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE443 profile');
    netcdf.putAtt(ncid,NPRORAWUPRAD443QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWUPRAD443QCID,'_FillValue',' ');       

    NPROUPRAD490QCID=netcdf.defVar(ncid,'PROFILE_UP_RADIANCE490_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROUPRAD490QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE490 profile');
    netcdf.putAtt(ncid,NPROUPRAD490QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROUPRAD490QCID,'_FillValue',' ');       

    NPRORAWUPRAD490QCID=netcdf.defVar(ncid,'PROFILE_RAW_UPWELLING_RADIANCE490','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWUPRAD490QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE490 profile');
    netcdf.putAtt(ncid,NPRORAWUPRAD490QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWUPRAD490QCID,'_FillValue',' ');       

    NPROUPRAD555QCID=netcdf.defVar(ncid,'PROFILE_UP_RADIANCE555_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROUPRAD555QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE555 profile');
    netcdf.putAtt(ncid,NPROUPRAD555QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROUPRAD555QCID,'_FillValue',' ');       

    NPRORAWUPRAD555QCID=netcdf.defVar(ncid,'PROFILE_RAW_UPWELLING_RADIANCE555','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWUPRAD555QCID,'long_name','Global quality flag of PROFILE_UP_RADIANCE555 profile');
    netcdf.putAtt(ncid,NPRORAWUPRAD555QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWUPRAD555QCID,'_FillValue',' ');       

end

if dbdat.irr2
    
    NPRODOWNIRRA380QCID=netcdf.defVar(ncid,'PROFILE_DOWN_IRRADIANCE380_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNIRRA380QCID,'long_name','Global quality flag of DOWN_IRRADIANCE380 profile');
    netcdf.putAtt(ncid,NPRODOWNIRRA380QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNIRRA380QCID,'_FillValue',' ');        

    NPRORAWDOWNIRRA380QCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_IRRADIANCE380_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA380QCID,'long_name','Global quality flag of RAW_DOWNWELLING_IRRADIANCE380 profile');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA380QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA380QCID,'_FillValue',' ');        

    NPRODOWNIRRA412QCID=netcdf.defVar(ncid,'PROFILE_DOWN_IRRADIANCE412_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNIRRA412QCID,'long_name','Global quality flag of DOWN_IRRADIANCE412 profile');
    netcdf.putAtt(ncid,NPRODOWNIRRA412QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNIRRA412QCID,'_FillValue',' ');        

    NPRORAWDOWNIRRA412QCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_IRRADIANCE412_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA412QCID,'long_name','Global quality flag of RAW_DOWNWELLING_IRRADIANCE412 profile');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA412QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA412QCID,'_FillValue',' ');    

    NPRODOWNIRRA490QCID=netcdf.defVar(ncid,'PROFILE_DOWN_IRRADIANCE490_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNIRRA490QCID,'long_name','Global quality flag of DOWN_IRRADIANCE490 profile');
    netcdf.putAtt(ncid,NPRODOWNIRRA490QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNIRRA490QCID,'_FillValue',' ');        

    NPRORAWDOWNIRRA490QCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_IRRADIANCE490_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA490QCID,'long_name','Global quality flag of RAW_DOWNWELLING_IRRADIANCE490 profile');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA490QCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNIRRA490QCID,'_FillValue',' ');        

    NPRODOWNPARQCID=netcdf.defVar(ncid,'PROFILE_DOWNWELLING_PAR_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRODOWNPARQCID,'long_name','Global quality flag of DOWNWELLING_PAR profile');
    netcdf.putAtt(ncid,NPRODOWNPARQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRODOWNPARQCID,'_FillValue',' ');        

    NPRORAWDOWNPARQCID=netcdf.defVar(ncid,'PROFILE_RAW_DOWNWELLING_PAR_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPRORAWDOWNPARQCID,'long_name','Global quality flag of RAW_DOWNWELLING_PAR profile');
    netcdf.putAtt(ncid,NPRORAWDOWNPARQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPRORAWDOWNPARQCID,'_FillValue',' ');        

end

if dbdat.pH
    
    NPROVRSPHQCID=netcdf.defVar(ncid,'PROFILE_VRS_PH_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROVRSPHQCID,'long_name','Global quality flag of VRS_PH profile');
    netcdf.putAtt(ncid,NPROVRSPHQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROVRSPHQCID,'_FillValue',' ');

    NPROPHINSITOLQCID=netcdf.defVar(ncid,'PROFILE_PH_IN_SITU_TOTAL_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROPHINSITOLQCID,'long_name','Global quality flag of PH_IN_SITU_TOTAL profile');
    netcdf.putAtt(ncid,NPROPHINSITOLQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROPHINSITOLQCID,'_FillValue',' ');    

    NPROTEMPPHQCID=netcdf.defVar(ncid,'PROFILE_TEMP_PH_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROTEMPPHQCID,'long_name','Global quality flag of TEMP_PH profile');
    netcdf.putAtt(ncid,NPROTEMPPHQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROTEMPPHQCID,'_FillValue',' ');    

end

if isfield(fp,'Tilt')
    
    NPROTILTQCID=netcdf.defVar(ncid,'PROFILE_TILT_QC','NC_CHAR',N_PROFID);
    netcdf.putAtt(ncid,NPROTILTQCID,'long_name','Global quality flag of TILT profile');
    netcdf.putAtt(ncid,NPROTILTQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NPROTILTQCID,'_FillValue',' ');

end

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

if dbdat.oxy %  & dbdat.subtype~=1006
    NDOXYID=netcdf.defVar(ncid,'DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOXYID,'long_name','Dissolved oxygen');
    netcdf.putAtt(ncid,NDOXYID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOXYID,'units','micromole/kg');
    netcdf.putAtt(ncid,NDOXYID,'axis','Z');
    netcdf.putAtt(ncid,NDOXYID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOXYID,'valid_min',single(-5.));
    netcdf.putAtt(ncid,NDOXYID,'valid_max',single(600.));
    netcdf.putAtt(ncid,NDOXYID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOXYID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOXYID,'resolution',single(0.001));

    NDOXYADID=netcdf.defVar(ncid,'DOXY_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOXYADID,'long_name','Dissolved oxygen');
    netcdf.putAtt(ncid,NDOXYADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOXYADID,'units','micromole/kg');
    netcdf.putAtt(ncid,NDOXYADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOXYADID,'valid_min',single(-5.));
    netcdf.putAtt(ncid,NDOXYADID,'valid_max',single(600.));
    netcdf.putAtt(ncid,NDOXYADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOXYADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOXYADID,'resolution',single(0.001));

    NDOXYQCID=netcdf.defVar(ncid,'DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOXYQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOXYQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOXYQCID,'_FillValue',' ');

    NDOXYADQCID=netcdf.defVar(ncid,'DOXY_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOXYADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOXYADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOXYADQCID,'_FillValue',' ');
         
   if isfield(fp,'oxyT_raw')
        NTEMPDOXYID=netcdf.defVar(ncid,'TEMP_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NTEMPDOXYID,'long_name','Sea temperature from oxygen sensor ITS-90 scale');
        netcdf.putAtt(ncid,NTEMPDOXYID,'standard_name','temperature_of_sensor_for_oxygen_in_sea_water');
        netcdf.putAtt(ncid,NTEMPDOXYID,'units','degree_Celsius');
        netcdf.putAtt(ncid,NTEMPDOXYID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NTEMPDOXYID,'valid_min',single(-2.));
        netcdf.putAtt(ncid,NTEMPDOXYID,'valid_max',single(40.));
        netcdf.putAtt(ncid,NTEMPDOXYID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NTEMPDOXYID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NTEMPDOXYID,'resolution',single(0.001));       

        NTEMPDOXYQCID=netcdf.defVar(ncid,'TEMP_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NTEMPDOXYQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NTEMPDOXYQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NTEMPDOXYQCID,'_FillValue',' ');

   end
   
    % added Feb 2012 - AT
    %floats that report DO concentration from either a Seabird IDO or Anderaa Optode sensor:
    % NOTE - Only the derived fields have adjusted or error variables so none of
    % these qualify:
    
    if isfield(fp,'oxy_umolar')   %(dbdat.subtype==32 || dbdat.subtype==35 || dbdat.subtype==31 || dbdat.subtype==40)

        NMOLARDOXYID=netcdf.defVar(ncid,'MOLAR_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NMOLARDOXYID,'long_name','Uncompensated (pressure and salinity) oxygen concentration reported by the oxygen sensor');
        netcdf.putAtt(ncid,NMOLARDOXYID,'standard_name','mole_concentration_of_dissolved_molecular_oxygen_in_sea_water');
        netcdf.putAtt(ncid,NMOLARDOXYID,'units','micromole/l');
        netcdf.putAtt(ncid,NMOLARDOXYID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NMOLARDOXYID,'valid_min',single(0.));
        netcdf.putAtt(ncid,NMOLARDOXYID,'valid_max',single(650.));
        netcdf.putAtt(ncid,NMOLARDOXYID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NMOLARDOXYID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NMOLARDOXYID,'resolution',single(0.001)); 
       
        NMOLARDOXYQCID=netcdf.defVar(ncid,'MOLAR_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NMOLARDOXYQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NMOLARDOXYQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NMOLARDOXYQCID,'_FillValue',' ');        

    end
    
    % floats that report O2 frequency from a Seabird IDO sensor:
    
    if isfield(fp,'SBEOxyfreq_raw')  %(dbdat.subtype==38 || dbdat.subtype==22 || dbdat.subtype==1007 || dbdat.subtype==1008)

        NFREQDOXYID=netcdf.defVar(ncid,'FREQUENCY_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NFREQDOXYID,'long_name','Frequency reported by oxygen sensor');
        netcdf.putAtt(ncid,NFREQDOXYID,'standard_name','-');
        netcdf.putAtt(ncid,NFREQDOXYID,'units','hertz');
        netcdf.putAtt(ncid,NFREQDOXYID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NFREQDOXYID,'valid_min',single(0.));
        netcdf.putAtt(ncid,NFREQDOXYID,'valid_max',single(25000.));
        netcdf.putAtt(ncid,NFREQDOXYID,'C_format','%5.2f');
        netcdf.putAtt(ncid,NFREQDOXYID,'FORTRAN_format','F5.2');
        netcdf.putAtt(ncid,NFREQDOXYID,'resolution',single(0.001)); 

        NFREQDOXYQCID=netcdf.defVar(ncid,'FREQUENCY_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NFREQDOXYQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NFREQDOXYQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NFREQDOXYQCID,'_FillValue',' ');    
        
    end

% floats that report Bphase from an Anderaa Optode sensor:

    if isfield(fp,'Bphase_raw')  %( dbdat.subtype==1002 || dbdat.subtype==1012 || dbdat.subtype==1006 || dbdat.subtype==1020 )

        NBPHASEDOXYID=netcdf.defVar(ncid,'BPHASE_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBPHASEDOXYID,'long_name','Uncalibrated phase shift reported by oxygen sensor');
        netcdf.putAtt(ncid,NBPHASEDOXYID,'standard_name','-');
        netcdf.putAtt(ncid,NBPHASEDOXYID,'units','degree');
        netcdf.putAtt(ncid,NBPHASEDOXYID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NBPHASEDOXYID,'valid_min',single(10.));
        netcdf.putAtt(ncid,NBPHASEDOXYID,'valid_max',single(70.));
        netcdf.putAtt(ncid,NBPHASEDOXYID,'C_format','%8.2f');
        netcdf.putAtt(ncid,NBPHASEDOXYID,'FORTRAN_format','F8.2');
        netcdf.putAtt(ncid,NBPHASEDOXYID,'resolution',single(0.01)); 
        
        NBPHASEDOXYQCID=netcdf.defVar(ncid,'BPHASE_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBPHASEDOXYQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBPHASEDOXYQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBPHASEDOXYQCID,'_FillValue',' ');     
        
    end
    
    % floats that report Tphase and R phase from Anderaa 4330 sensor:
    
    if isfield(fp,'Tphase_raw')  %( dbdat.subtype==1002 || dbdat.subtype==1012 || dbdat.subtype==1006 || dbdat.subtype==1020 )
       
        NTPHASEDOXYID=netcdf.defVar(ncid,'TPHASE_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NTPHASEDOXYID,'long_name','Uncalibrated phase shift reported by oxygen sensor');
        netcdf.putAtt(ncid,NTPHASEDOXYID,'standard_name','-');
        netcdf.putAtt(ncid,NTPHASEDOXYID,'units','degree');
        netcdf.putAtt(ncid,NTPHASEDOXYID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NTPHASEDOXYID,'valid_min',single(10.));
        netcdf.putAtt(ncid,NTPHASEDOXYID,'valid_max',single(70.));
        netcdf.putAtt(ncid,NTPHASEDOXYID,'C_format','%8.2f');
        netcdf.putAtt(ncid,NTPHASEDOXYID,'FORTRAN_format','F8.2');
        netcdf.putAtt(ncid,NTPHASEDOXYID,'resolution',single(0.01)); 
        
        NTPHASEDOXYQCID=netcdf.defVar(ncid,'TPHASE_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NTPHASEDOXYQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NTPHASEDOXYQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NTPHASEDOXYQCID,'_FillValue',' ');  
        

        if isfield(fp,'Rphase_raw')  %( dbdat.subtype==1002 || dbdat.subtype==1012 || dbdat.subtype==1006 || dbdat.subtype==1020 )

            NRPHASEDOXYID=netcdf.defVar(ncid,'RPHASE_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
            netcdf.putAtt(ncid,NRPHASEDOXYID,'long_name','Uncalibrated phase shift reported by oxygen sensor');
            netcdf.putAtt(ncid,NRPHASEDOXYID,'standard_name','-');
            netcdf.putAtt(ncid,NRPHASEDOXYID,'units','degree');
            netcdf.putAtt(ncid,NRPHASEDOXYID,'_FillValue',single(fval));
            netcdf.putAtt(ncid,NRPHASEDOXYID,'valid_min',single(10.));
            netcdf.putAtt(ncid,NRPHASEDOXYID,'valid_max',single(70.));
            netcdf.putAtt(ncid,NRPHASEDOXYID,'C_format','%8.2f');
            netcdf.putAtt(ncid,NRPHASEDOXYID,'FORTRAN_format','F8.2');
            netcdf.putAtt(ncid,NRPHASEDOXYID,'resolution',single(0.01)); 

            NRPHASEDOXYQCID=netcdf.defVar(ncid,'RPHASE_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
            netcdf.putAtt(ncid,NRPHASEDOXYQCID,'long_name','quality flag');
            netcdf.putAtt(ncid,NRPHASEDOXYQCID,'conventions','Argo reference table 2');
            netcdf.putAtt(ncid,NRPHASEDOXYQCID,'_FillValue',' ');     

        end
    end
    
% floats that report Phase from an Seabird Optode sensor:

    if isfield(fp,'O2phase_raw')   %(dbdat.subtype==1017 )

        NPHASEDOXYID=netcdf.defVar(ncid,'PHASE_DELAY_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NPHASEDOXYID,'long_name','Phase delay reported by oxygen sensor');
        netcdf.putAtt(ncid,NPHASEDOXYID,'standard_name','-');
        netcdf.putAtt(ncid,NPHASEDOXYID,'units','microsecond');
        netcdf.putAtt(ncid,NPHASEDOXYID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NPHASEDOXYID,'valid_min',single(0.));
        netcdf.putAtt(ncid,NPHASEDOXYID,'valid_max',single(99999.));
        netcdf.putAtt(ncid,NPHASEDOXYID,'C_format','%8.4f');
        netcdf.putAtt(ncid,NPHASEDOXYID,'FORTRAN_format','F8.4');
        netcdf.putAtt(ncid,NPHASEDOXYID,'resolution',single(0.01)); 
        
        NPHASEDOXYQCID=netcdf.defVar(ncid,'PHASE_DELAY_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NPHASEDOXYQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NPHASEDOXYQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NPHASEDOXYQCID,'_FillValue',' ');            
        
        
        if isfield(fp,'t_oxygen_volts')  
            
            NTEMPVOLDOXYID=netcdf.defVar(ncid,'TEMP_VOLTAGE_DOXY','NC_FLOAT',[N_LEVELSID,N_PROFID]);
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'long_name','Thermistor voltage reported by oxygen sensor');
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'standard_name','-');
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'units','volt');
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'_FillValue',single(fval));
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'valid_min',single(0.));
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'valid_max',single(100.));
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'C_format','%9.6f');
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'FORTRAN_format','F9.6');
            netcdf.putAtt(ncid,NTEMPVOLDOXYID,'resolution',single(0.01));
            
            NTEMPVOLDOXYQCID=netcdf.defVar(ncid,'TEMP_VOLTAGE_DOXY_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
            netcdf.putAtt(ncid,NTEMPVOLDOXYQCID,'long_name','quality flag');
            netcdf.putAtt(ncid,NTEMPVOLDOXYQCID,'conventions','Argo reference table 2');
            netcdf.putAtt(ncid,NTEMPVOLDOXYQCID,'_FillValue',' ');
            
        end            
    end
end


if dbdat.oxy %& dbdat.subtype~=1006 & dbdat.subtype~=1017
    
        NDOXYADERRID=netcdf.defVar(ncid,'DOXY_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NDOXYADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
        netcdf.putAtt(ncid,NDOXYADERRID,'units','micromole/kg');
        netcdf.putAtt(ncid,NDOXYADERRID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NDOXYADERRID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NDOXYADERRID,'resolution',single(0.001)); 
        netcdf.putAtt(ncid,NDOXYADERRID,'_FillValue',single(fval));        
   
    if isfield(fp,'oxyT_raw')   %(dbdat.subtype~=38 && dbdat.subtype~=1007 && dbdat.subtype~=1008 && ...
%             dbdat.subtype~=22 && dbdat.subtype~=40)
        
%         nc{'TEMP_DOXY_ADJUSTED_ERROR'}=ncfloat('N_PROF','N_LEVELS');
%         nc{'TEMP_DOXY_ADJUSTED_ERROR'}.long_name='Contains the error on the adjusted values as determined by the delayed mode QC process';
%         nc{'TEMP_DOXY_ADJUSTED_ERROR'}.units='degree_Celsius';
%         nc{'TEMP_DOXY_ADJUSTED_ERROR'}.C_format='%9.3f';
%         nc{'TEMP_DOXY_ADJUSTED_ERROR'}.FORTRAN_format='F9.3';
%         nc{'TEMP_DOXY_ADJUSTED_ERROR'}.resolution=ncfloat(0.001);
%         nc{'TEMP_DOXY_ADJUSTED_ERROR'}.FillValue_=ncfloat(fval);
%         
    end
end


if dbdat.flbb
    NCHLAID=netcdf.defVar(ncid,'CHLA','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCHLAID,'long_name','Chlorophyll-A');
    netcdf.putAtt(ncid,NCHLAID,'standard_name','mass_concentration_of_chlorophyll_a_in_sea_water');
    netcdf.putAtt(ncid,NCHLAID,'units','mg/m3');
    netcdf.putAtt(ncid,NCHLAID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NCHLAID,'C_format','%9.5f');
    netcdf.putAtt(ncid,NCHLAID,'FORTRAN_format','F9.5');
    netcdf.putAtt(ncid,NCHLAID,'resolution',' ');
    
    NCHLAADID=netcdf.defVar(ncid,'CHLA_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCHLAADID,'long_name','Chlorophyll-A');
    netcdf.putAtt(ncid,NCHLAADID,'standard_name','mass_concentration_of_chlorophyll_a_in_sea_water');
    netcdf.putAtt(ncid,NCHLAADID,'units','mg/m3');
    netcdf.putAtt(ncid,NCHLAADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NCHLAADID,'C_format','%9.5f');
    netcdf.putAtt(ncid,NCHLAADID,'FORTRAN_format','F9.5');
    netcdf.putAtt(ncid,NCHLAADID,'resolution',' ');
    
    NCHLAQCID=netcdf.defVar(ncid,'CHLA_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCHLAQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NCHLAQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NCHLAQCID,'_FillValue',' ');
    
    NCHLAADQCID=netcdf.defVar(ncid,'CHLA_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCHLAADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NCHLAADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NCHLAADQCID,'_FillValue',' ');
    
    NCHLAADERRID=netcdf.defVar(ncid,'CHLA_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCHLAADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NCHLAADERRID,'units','mg/m3');
    netcdf.putAtt(ncid,NCHLAADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NCHLAADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NCHLAADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NCHLAADERRID,'_FillValue',single(fval));
    
    NFLUOCHLAID=netcdf.defVar(ncid,'FLUORESCENCE_CHLA','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NFLUOCHLAID,'long_name','Chlorophyll-A signal from fluorescence sensor');
    %         netcdf.putAtt(ncid,NFLUOCHLAID,'standard_name','mass_concentration_of_chlorophyll_a_in_sea_water');
    netcdf.putAtt(ncid,NFLUOCHLAID,'units','count');
    netcdf.putAtt(ncid,NFLUOCHLAID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NFLUOCHLAID,'valid_min',single(0.));
    netcdf.putAtt(ncid,NFLUOCHLAID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NFLUOCHLAID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NFLUOCHLAID,'resolution',single(1.));
    NFLUOCHLAQCID=netcdf.defVar(ncid,'FLUORESCENCE_CHLA_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NFLUOCHLAQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NFLUOCHLAQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NFLUOCHLAQCID,'_FillValue',' ');
    
    NBBP700ID=netcdf.defVar(ncid,'BBP700','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP700ID,'long_name','Particle backscattering at 700 nanometers');
    %         netcdf.putAtt(ncid,NBBP700ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBBP700ID,'units','m-1');
    netcdf.putAtt(ncid,NBBP700ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NBBP700ID,'valid_min','');
    %         netcdf.putAtt(ncid,NBBP700ID,'valid_max','');
    netcdf.putAtt(ncid,NBBP700ID,'C_format','%10.8f');
    netcdf.putAtt(ncid,NBBP700ID,'FORTRAN_format','F10.8');
    netcdf.putAtt(ncid,NBBP700ID,'resolution',' ');
    
    NBBP700ADID=netcdf.defVar(ncid,'BBP700_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP700ADID,'long_name','Particle backscattering at 700 nanometers');
    %         netcdf.putAtt(ncid,NBBP700ADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBBP700ADID,'units','m-1');
    netcdf.putAtt(ncid,NBBP700ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NBBP700ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NBBP700ADID,'valid_max','');
    netcdf.putAtt(ncid,NBBP700ADID,'C_format','%10.8f');
    netcdf.putAtt(ncid,NBBP700ADID,'FORTRAN_format','F10.8');
    netcdf.putAtt(ncid,NBBP700ADID,'resolution',' ');
    
    NBBP700QCID=netcdf.defVar(ncid,'BBP700_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP700QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBBP700QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBBP700QCID,'_FillValue',' ');
    
    NBBP700ADQCID=netcdf.defVar(ncid,'BBP700_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP700ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBBP700ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBBP700ADQCID,'_FillValue',' ');
    
    NBBP700ADERRID=netcdf.defVar(ncid,'BBP700_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP700ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NBBP700ADERRID,'units','m-1');
    netcdf.putAtt(ncid,NBBP700ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NBBP700ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NBBP700ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NBBP700ADERRID,'_FillValue',single(fval));
    
    NBETABACK700ID=netcdf.defVar(ncid,'BETA_BACKSCATTERING700','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBETABACK700ID,'long_name','Total angle specific volume from backscattering sensor at 700 nanometers');
    %         netcdf.putAtt(ncid,NBETABACK700ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBETABACK700ID,'units','count');
    netcdf.putAtt(ncid,NBETABACK700ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NBETABACK700ID,'valid_min',single(0.));
    %         netcdf.putAtt(ncid,NBETABACK700ID,'valid_max',single(99999.));
    netcdf.putAtt(ncid,NBETABACK700ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NBETABACK700ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NBETABACK700ID,'resolution',single(1.));
    
    NBETABACK700QCID=netcdf.defVar(ncid,'BETA_BACKSCATTERING700_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBETABACK700QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBETABACK700QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBETABACK700QCID,'_FillValue',' ');
    
    NTEMPCPUCHLAID=netcdf.defVar(ncid,'TEMP_CPU_CHLA','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTEMPCPUCHLAID,'long_name','Thermistor signal from backscattering sensor');
    %         netcdf.putAtt(ncid,NTEMPCPUCHLAID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NTEMPCPUCHLAID,'units','count');
    netcdf.putAtt(ncid,NTEMPCPUCHLAID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NTEMPCPUCHLAID,'valid_min',' ');
    %         netcdf.putAtt(ncid,NTEMPCPUCHLAID,'valid_max',' ');
    netcdf.putAtt(ncid,NTEMPCPUCHLAID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NTEMPCPUCHLAID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NTEMPCPUCHLAID,'resolution',single(1.));
    
    NTEMPCPUCHLAQCID=netcdf.defVar(ncid,'TEMP_CPU_CHLA_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTEMPCPUCHLAQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NTEMPCPUCHLAQCID,'conventions','Argo reference table 2a');
    netcdf.putAtt(ncid,NTEMPCPUCHLAQCID,'_FillValue',' ');
    
    if dbdat.flbb2
        
        NBBP532ID=netcdf.defVar(ncid,'BBP532','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP532ID,'long_name','Particle backscattering at 532 nanometers');
        %         netcdf.putAtt(ncid,NBBP532ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBBP532ID,'units','m-1');
        netcdf.putAtt(ncid,NBBP532ID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NBBP532ID,'valid_min','');
        %         netcdf.putAtt(ncid,NBBP532ID,'valid_max','');
        netcdf.putAtt(ncid,NBBP532ID,'C_format','%10.8f');
        netcdf.putAtt(ncid,NBBP532ID,'FORTRAN_format','F10.8');
        netcdf.putAtt(ncid,NBBP532ID,'resolution',' ');
        
        NBBP532ADID=netcdf.defVar(ncid,'BBP532_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP532ADID,'long_name','Particle backscattering at 532 nanometers');
        %         netcdf.putAtt(ncid,NBBP532ADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBBP532ADID,'units','m-1');
        netcdf.putAtt(ncid,NBBP532ADID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NBBP532ADID,'valid_min','');
        %         netcdf.putAtt(ncid,NBBP532ADID,'valid_max','');
        netcdf.putAtt(ncid,NBBP532ADID,'C_format','%10.8f');
        netcdf.putAtt(ncid,NBBP532ADID,'FORTRAN_format','F10.8');
        netcdf.putAtt(ncid,NBBP532ADID,'resolution',' ');
        
        NBBP532QCID=netcdf.defVar(ncid,'BBP532_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP532QCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBBP532QCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBBP532QCID,'_FillValue',' ');
        
        NBBP532ADQCID=netcdf.defVar(ncid,'BBP532_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP532ADQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBBP532ADQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBBP532ADQCID,'_FillValue',' ');
        
        NBBP532ADERRID=netcdf.defVar(ncid,'BBP532_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP532ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
        netcdf.putAtt(ncid,NBBP532ADERRID,'units','m-1');
        netcdf.putAtt(ncid,NBBP532ADERRID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NBBP532ADERRID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NBBP532ADERRID,'resolution',' ');
        netcdf.putAtt(ncid,NBBP532ADERRID,'_FillValue',single(fval));
        
        NBETABACK532ID=netcdf.defVar(ncid,'BETA_BACKSCATTERING532','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBETABACK532ID,'long_name','Total angle specific volume from backscattering sensor at 532 nanometers');
        %         netcdf.putAtt(ncid,NBETABACK532ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBETABACK532ID,'units','count');
        netcdf.putAtt(ncid,NBETABACK532ID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NBETABACK532ID,'valid_min',single(0.));
        %         netcdf.putAtt(ncid,NBETABACK532ID,'valid_max',single(99999.));
        netcdf.putAtt(ncid,NBETABACK532ID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NBETABACK532ID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NBETABACK532ID,'resolution',single(1.));
        
        NBETABACK532QCID=netcdf.defVar(ncid,'BETA_BACKSCATTERING532_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBETABACK532QCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBETABACK532QCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBETABACK532QCID,'_FillValue',' ');
        
    end
    
    if isfield(fp,'CDOM_raw')
        
        NCDOMID=netcdf.defVar(ncid,'CDOM','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NCDOMID,'long_name','Concentration of coloured dissolved organic matter in sea water');
        %         netcdf.putAtt(ncid,NCDOMID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NCDOMID,'units','ppb');
        netcdf.putAtt(ncid,NCDOMID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NCDOMID,'valid_min','');
        %         netcdf.putAtt(ncid,NCDOMID,'valid_max','');
        netcdf.putAtt(ncid,NCDOMID,'C_format','%9.5f');
        netcdf.putAtt(ncid,NCDOMID,'FORTRAN_format','F9.5');
        netcdf.putAtt(ncid,NCDOMID,'resolution',' ');
        
        NCDOMADID=netcdf.defVar(ncid,'CDOM_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NCDOMADID,'long_name','Concentration of coloured dissolved organic matter in sea water');
        %         netcdf.putAtt(ncid,NCDOMADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NCDOMADID,'units','ppb');
        netcdf.putAtt(ncid,NCDOMADID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NCDOMADID,'valid_min','');
        %         netcdf.putAtt(ncid,NCDOMADID,'valid_max','');
        netcdf.putAtt(ncid,NCDOMADID,'C_format','%9.5f');
        netcdf.putAtt(ncid,NCDOMADID,'FORTRAN_format','F9.5');
        netcdf.putAtt(ncid,NCDOMADID,'resolution',' ');
        
        NCDOMQCID=netcdf.defVar(ncid,'CDOM_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NCDOMQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NCDOMQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NCDOMQCID,'_FillValue',' ');
        
        NCDOMADQCID=netcdf.defVar(ncid,'CDOM_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NCDOMADQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NCDOMADQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NCDOMADQCID,'_FillValue',' ');
        
        NCDOMADERRID=netcdf.defVar(ncid,'CDOM_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NCDOMADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
        netcdf.putAtt(ncid,NCDOMADERRID,'units','ppb');
        netcdf.putAtt(ncid,NCDOMADERRID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NCDOMADERRID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NCDOMADERRID,'resolution',' ');
        netcdf.putAtt(ncid,NCDOMADERRID,'_FillValue',single(fval));
        
        NFLUOCDOMID=netcdf.defVar(ncid,'FLUORESCENCE_CDOM','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NFLUOCDOMID,'long_name','Raw fluorescence from coloured dissolved organic matter sensor');
        %         netcdf.putAtt(ncid,NFLUOCDOMID,'standard_name','mass_concentration_of_chlorophyll_a_in_sea_water');
        netcdf.putAtt(ncid,NFLUOCDOMID,'units','count');
        netcdf.putAtt(ncid,NFLUOCDOMID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NFLUOCDOMID,'valid_min',single(0.));
        %         netcdf.putAtt(ncid,NFLUOCDOMID,'valid_max',single(99999.));
        netcdf.putAtt(ncid,NFLUOCDOMID,'C_format','%9.5f');
        netcdf.putAtt(ncid,NFLUOCDOMID,'FORTRAN_format','F9.5'); %%%%%%%%%%%%%%%%%%²»Í¬%%%%%%%%%%%
        netcdf.putAtt(ncid,NFLUOCDOMID,'resolution',single(1.));
        NFLUOCDOMQCID=netcdf.defVar(ncid,'FLUORESCENCE_CDOM_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NFLUOCDOMQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NFLUOCDOMQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NFLUOCDOMQCID,'_FillValue',' ');
        
    end
end

if dbdat.tmiss
    
    NCP660ID=netcdf.defVar(ncid,'CP660','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCP660ID,'long_name','Particle beam attenuation at 660 nanometers');
    %         netcdf.putAtt(ncid,NCP660ID,'standard_name','');
    netcdf.putAtt(ncid,NCP660ID,'units','m-1');
    netcdf.putAtt(ncid,NCP660ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NCP660ID,'valid_min','');
    %         netcdf.putAtt(ncid,NCP660ID,'valid_max','');
    netcdf.putAtt(ncid,NCP660ID,'C_format','%9.6f');
    netcdf.putAtt(ncid,NCP660ID,'FORTRAN_format','F9.6');
    netcdf.putAtt(ncid,NCP660ID,'resolution',' ');
    
    NCP660ADID=netcdf.defVar(ncid,'CP660_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCP660ADID,'long_name','Particle beam attenuation at 660 nanometers');
    %         netcdf.putAtt(ncid,NCP660ADID,'standard_name','Particle beam attenuation at x nanometers');
    netcdf.putAtt(ncid,NCP660ADID,'units','m-1');
    netcdf.putAtt(ncid,NCP660ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NCP660ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NCP660ADID,'valid_max','');
    netcdf.putAtt(ncid,NCP660ADID,'C_format','%9.6f');
    netcdf.putAtt(ncid,NCP660ADID,'FORTRAN_format','F9.6');
    netcdf.putAtt(ncid,NCP660ADID,'resolution',' ');
    
    NCP660QCID=netcdf.defVar(ncid,'CP660_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCP660QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NCP660QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NCP660QCID,'_FillValue',' ');
    
    NCP660ADQCID=netcdf.defVar(ncid,'CP660_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCP660ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NCP660ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NCP660ADQCID,'_FillValue',' ');
    
    NCP660ADERRID=netcdf.defVar(ncid,'CP660_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NCP660ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NCP660ADERRID,'units','ppb');
    netcdf.putAtt(ncid,NCP660ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NCP660ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NCP660ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NCP660ADERRID,'_FillValue',single(fval));
    
    NTRANSPARBEATT660ID=netcdf.defVar(ncid,'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTRANSPARBEATT660ID,'long_name','Beam attenuation from transmissometer sensor at 660 nanometers');
    netcdf.putAtt(ncid,NTRANSPARBEATT660ID,'units','dimensionless');
    netcdf.putAtt(ncid,NTRANSPARBEATT660ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NTRANSPARBEATT660ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NTRANSPARBEATT660ID,'resolution',single(1.));
    netcdf.putAtt(ncid,NTRANSPARBEATT660ID,'_FillValue',single(fval));
    
    NTRANSPARBEATT660QCID=netcdf.defVar(ncid,'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTRANSPARBEATT660QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NTRANSPARBEATT660QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NTRANSPARBEATT660QCID,'_FillValue',' ');

end

if dbdat.eco
    
    if dbdat.flbb
        
        NBBP7002ID=netcdf.defVar(ncid,'BBP700_2','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP7002ID,'long_name','Particle backscattering at 700 nanometers');
        %         netcdf.putAtt(ncid,NBBP7002ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBBP7002ID,'units','m-1');
        netcdf.putAtt(ncid,NBBP7002ID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NBBP7002ID,'valid_min','');
        %         netcdf.putAtt(ncid,NBBP7002ID,'valid_max','');
        netcdf.putAtt(ncid,NBBP7002ID,'C_format','%10.8f');
        netcdf.putAtt(ncid,NBBP7002ID,'FORTRAN_format','F10.8');
        netcdf.putAtt(ncid,NBBP7002ID,'resolution',' ');
        
        NBBP7002ADID=netcdf.defVar(ncid,'BBP700_2_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP7002ADID,'long_name','Particle backscattering at 700 nanometers');
        %         netcdf.putAtt(ncid,NBBP7002ADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBBP7002ADID,'units','m-1');
        netcdf.putAtt(ncid,NBBP7002ADID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NBBP7002ADID,'valid_min','');
        %         netcdf.putAtt(ncid,NBBP7002ADID,'valid_max','');
        netcdf.putAtt(ncid,NBBP7002ADID,'C_format','%10.8f');
        netcdf.putAtt(ncid,NBBP7002ADID,'FORTRAN_format','F10.8');
        netcdf.putAtt(ncid,NBBP7002ADID,'resolution',' ');       
        
        NBBP7002QCID=netcdf.defVar(ncid,'BBP700_2_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP7002QCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBBP7002QCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBBP7002QCID,'_FillValue',' ');    
        
        NBBP7002ADQCID=netcdf.defVar(ncid,'BBP700_2_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP7002ADQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBBP7002ADQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBBP7002ADQCID,'_FillValue',' ');   
        
        NBBP7002ADERRID=netcdf.defVar(ncid,'BBP700_2_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP7002ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
        netcdf.putAtt(ncid,NBBP7002ADERRID,'units','m-1');
        netcdf.putAtt(ncid,NBBP7002ADERRID,'C_format','%10.8f');
        netcdf.putAtt(ncid,NBBP7002ADERRID,'FORTRAN_format','F10.8');
        netcdf.putAtt(ncid,NBBP7002ADERRID,'resolution',' '); 
        netcdf.putAtt(ncid,NBBP7002ADERRID,'_FillValue',single(fval));  
        
        NBETABACK7002ID=netcdf.defVar(ncid,'BETA_BACKSCATTERING700_2','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBETABACK7002ID,'long_name','Total angle specific volume from backscattering sensor at 700 nanometers');
%         netcdf.putAtt(ncid,NBETABACK7002ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBETABACK7002ID,'units','count');
        netcdf.putAtt(ncid,NBETABACK7002ID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NBETABACK7002ID,'valid_min',single(0.));
%         netcdf.putAtt(ncid,NBETABACK7002ID,'valid_max',single(99999.));
        netcdf.putAtt(ncid,NBETABACK7002ID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NBETABACK7002ID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NBETABACK7002ID,'resolution',single(1.));   
        
        NBETABACK7002QCID=netcdf.defVar(ncid,'BETA_BACKSCATTERING700_2_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBETABACK7002QCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBETABACK7002QCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBETABACK7002QCID,'_FillValue',' ');        
        
    else
        
        NBBP700ID=netcdf.defVar(ncid,'BBP700','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP700ID,'long_name','Particle backscattering at 700 nanometers');
        %         netcdf.putAtt(ncid,NBBP700ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBBP700ID,'units','m-1');
        netcdf.putAtt(ncid,NBBP700ID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NBBP700ID,'valid_min','');
        %         netcdf.putAtt(ncid,NBBP700ID,'valid_max','');
        netcdf.putAtt(ncid,NBBP700ID,'C_format','%10.8f');
        netcdf.putAtt(ncid,NBBP700ID,'FORTRAN_format','F10.8');
        netcdf.putAtt(ncid,NBBP700ID,'resolution',' ');
        
        NBBP700ADID=netcdf.defVar(ncid,'BBP700_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP700ADID,'long_name','Particle backscattering at 700 nanometers');
        %         netcdf.putAtt(ncid,NBBP700ADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBBP700ADID,'units','m-1');
        netcdf.putAtt(ncid,NBBP700ADID,'_FillValue',single(fval));
        %         netcdf.putAtt(ncid,NBBP700ADID,'valid_min','');
        %         netcdf.putAtt(ncid,NBBP700ADID,'valid_max','');
        netcdf.putAtt(ncid,NBBP700ADID,'C_format','%10.8f');
        netcdf.putAtt(ncid,NBBP700ADID,'FORTRAN_format','F10.8');
        netcdf.putAtt(ncid,NBBP700ADID,'resolution',' ');
        
        NBBP700QCID=netcdf.defVar(ncid,'BBP700_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP700QCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBBP700QCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBBP700QCID,'_FillValue',' ');    
        
        NBBP700ADQCID=netcdf.defVar(ncid,'BBP700_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP700ADQCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBBP700ADQCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBBP700ADQCID,'_FillValue',' ');   
        
        NBBP700ADERRID=netcdf.defVar(ncid,'BBP700_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBBP700ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
        netcdf.putAtt(ncid,NBBP700ADERRID,'units','m-1');
        netcdf.putAtt(ncid,NBBP700ADERRID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NBBP700ADERRID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NBBP700ADERRID,'resolution',' '); 
        netcdf.putAtt(ncid,NBBP700ADERRID,'_FillValue',single(fval));  
        
        NBETABACK700ID=netcdf.defVar(ncid,'BETA_BACKSCATTERING700','NC_FLOAT',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBETABACK700ID,'long_name','Total angle specific volume from backscattering sensor at 700 nanometers');
%         netcdf.putAtt(ncid,NBETABACK700ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
        netcdf.putAtt(ncid,NBETABACK700ID,'units','count');
        netcdf.putAtt(ncid,NBETABACK700ID,'_FillValue',single(fval));
        netcdf.putAtt(ncid,NBETABACK700ID,'valid_min',single(0.));
%         netcdf.putAtt(ncid,NBETABACK700ID,'valid_max',single(99999.));
        netcdf.putAtt(ncid,NBETABACK700ID,'C_format','%9.3f');
        netcdf.putAtt(ncid,NBETABACK700ID,'FORTRAN_format','F9.3');
        netcdf.putAtt(ncid,NBETABACK700ID,'resolution',single(1.));         
        
        NBETABACK700QCID=netcdf.defVar(ncid,'BETA_BACKSCATTERING700_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
        netcdf.putAtt(ncid,NBETABACK700QCID,'long_name','quality flag');
        netcdf.putAtt(ncid,NBETABACK700QCID,'conventions','Argo reference table 2');
        netcdf.putAtt(ncid,NBETABACK700QCID,'_FillValue',' ');   

    end 
    
    NBBP532ID=netcdf.defVar(ncid,'BBP532','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP532ID,'long_name','Particle backscattering at 532 nanometers');
    %         netcdf.putAtt(ncid,NBBP532ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBBP532ID,'units','m-1');
    netcdf.putAtt(ncid,NBBP532ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NBBP532ID,'valid_min','');
    %         netcdf.putAtt(ncid,NBBP532ID,'valid_max','');
    netcdf.putAtt(ncid,NBBP532ID,'C_format','%10.8f');
    netcdf.putAtt(ncid,NBBP532ID,'FORTRAN_format','F10.8');
    netcdf.putAtt(ncid,NBBP532ID,'resolution',' ');
    
    NBBP532ADID=netcdf.defVar(ncid,'BBP532_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP532ADID,'long_name','Particle backscattering at 532 nanometers');
    %         netcdf.putAtt(ncid,NBBP532ADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBBP532ADID,'units','m-1');
    netcdf.putAtt(ncid,NBBP532ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NBBP532ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NBBP532ADID,'valid_max','');
    netcdf.putAtt(ncid,NBBP532ADID,'C_format','%10.8f');
    netcdf.putAtt(ncid,NBBP532ADID,'FORTRAN_format','F10.8');
    netcdf.putAtt(ncid,NBBP532ADID,'resolution',' ');
    
    NBBP532QCID=netcdf.defVar(ncid,'BBP532_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP532QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBBP532QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBBP532QCID,'_FillValue',' ');
    
    NBBP532ADQCID=netcdf.defVar(ncid,'BBP532_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP532ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBBP532ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBBP532ADQCID,'_FillValue',' ');
    
    NBBP532ADERRID=netcdf.defVar(ncid,'BBP532_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP532ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NBBP532ADERRID,'units','m-1');
    netcdf.putAtt(ncid,NBBP532ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NBBP532ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NBBP532ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NBBP532ADERRID,'_FillValue',single(fval));
    
    NBETABACK532ID=netcdf.defVar(ncid,'BETA_BACKSCATTERING532','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBETABACK532ID,'long_name','Total angle specific volume from backscattering sensor at 532 nanometers');
    %         netcdf.putAtt(ncid,NBETABACK532ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBETABACK532ID,'units','count');
    netcdf.putAtt(ncid,NBETABACK532ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NBETABACK532ID,'valid_min',single(0.));
    %         netcdf.putAtt(ncid,NBETABACK532ID,'valid_max',single(99999.));
    netcdf.putAtt(ncid,NBETABACK532ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NBETABACK532ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NBETABACK532ID,'resolution',single(1.));
    
    NBETABACK532QCID=netcdf.defVar(ncid,'BETA_BACKSCATTERING532_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBETABACK532QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBETABACK532QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBETABACK532QCID,'_FillValue',' ');
    
    
    NBBP470ID=netcdf.defVar(ncid,'BBP470','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP470ID,'long_name','Particle backscattering at 470 nanometers');
    %         netcdf.putAtt(ncid,NBBP470ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBBP470ID,'units','m-1');
    netcdf.putAtt(ncid,NBBP470ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NBBP470ID,'valid_min','');
    %         netcdf.putAtt(ncid,NBBP470ID,'valid_max','');
    netcdf.putAtt(ncid,NBBP470ID,'C_format','%10.8f');
    netcdf.putAtt(ncid,NBBP470ID,'FORTRAN_format','F10.8');
    netcdf.putAtt(ncid,NBBP470ID,'resolution',' ');
    
    NBBP470ADID=netcdf.defVar(ncid,'BBP470_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP470ADID,'long_name','Particle backscattering at 470 nanometers');
    %         netcdf.putAtt(ncid,NBBP470ADID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBBP470ADID,'units','m-1');
    netcdf.putAtt(ncid,NBBP470ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NBBP470ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NBBP470ADID,'valid_max','');
    netcdf.putAtt(ncid,NBBP470ADID,'C_format','%10.8f');
    netcdf.putAtt(ncid,NBBP470ADID,'FORTRAN_format','F10.8');
    netcdf.putAtt(ncid,NBBP470ADID,'resolution',' ');
    
    NBBP470QCID=netcdf.defVar(ncid,'BBP470_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP470QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBBP470QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBBP470QCID,'_FillValue',' ');
    
    NBBP470ADQCID=netcdf.defVar(ncid,'BBP470_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP470ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBBP470ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBBP470ADQCID,'_FillValue',' ');
    
    NBBP470ADERRID=netcdf.defVar(ncid,'BBP470_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBBP470ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NBBP470ADERRID,'units','m-1');
    netcdf.putAtt(ncid,NBBP470ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NBBP470ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NBBP470ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NBBP470ADERRID,'_FillValue',single(fval));
    
    NBETABACK470ID=netcdf.defVar(ncid,'BETA_BACKSCATTERING470','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBETABACK470ID,'long_name','Total angle specific volume from backscattering sensor at 470 nanometers');
    %         netcdf.putAtt(ncid,NBETABACK470ID,'standard_name','moles_of_oxygen_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NBETABACK470ID,'units','count');
    netcdf.putAtt(ncid,NBETABACK470ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NBETABACK470ID,'valid_min',single(0.));
    %         netcdf.putAtt(ncid,NBETABACK470ID,'valid_max',single(99999.));
    netcdf.putAtt(ncid,NBETABACK470ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NBETABACK470ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NBETABACK470ID,'resolution',single(1.));
    
    NBETABACK470QCID=netcdf.defVar(ncid,'BETA_BACKSCATTERING470_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NBETABACK470QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NBETABACK470QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NBETABACK470QCID,'_FillValue',' ');

end

if dbdat.suna
    
    NNITRATEID=netcdf.defVar(ncid,'NITRATE','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NNITRATEID,'long_name','Nitrate');
    netcdf.putAtt(ncid,NNITRATEID,'standard_name','moles_of_nitrate_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NNITRATEID,'units','micromole/kg');
    netcdf.putAtt(ncid,NNITRATEID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NNITRATEID,'valid_min','');
    %         netcdf.putAtt(ncid,NNITRATEID,'valid_max','');
    netcdf.putAtt(ncid,NNITRATEID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NNITRATEID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NNITRATEID,'resolution',' ');
    
    NNITRATEADID=netcdf.defVar(ncid,'NITRATE_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NNITRATEADID,'long_name','Nitrate');
    netcdf.putAtt(ncid,NNITRATEADID,'standard_name','moles_of_nitrate_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NNITRATEADID,'units','ppb');
    netcdf.putAtt(ncid,NNITRATEADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NNITRATEADID,'valid_min','');
    %         netcdf.putAtt(ncid,NNITRATEADID,'valid_max','');
    netcdf.putAtt(ncid,NNITRATEADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NNITRATEADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NNITRATEADID,'resolution',' ');
    
    NNITRATEQCID=netcdf.defVar(ncid,'NITRATE_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NNITRATEQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NNITRATEQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NNITRATEQCID,'_FillValue',' ');
    
    NNITRATEADQCID=netcdf.defVar(ncid,'NITRATE_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NNITRATEADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NNITRATEADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NNITRATEADQCID,'_FillValue',' ');
    
    NNITRATEADERRID=netcdf.defVar(ncid,'NITRATE_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NNITRATEADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NNITRATEADERRID,'units','micromole/kg');
    netcdf.putAtt(ncid,NNITRATEADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NNITRATEADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NNITRATEADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NNITRATEADERRID,'_FillValue',single(fval));
    
end

if dbdat.irr & ~dbdat.irr2
    
    NDOWNIRRA412ID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'long_name','Downwelling irradiance at 412 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA412ID,'standard_name','moles_of_DOWNIRRA412_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA412ID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA412ID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'resolution',' ');
    
    NDOWNIRRA412ADID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'long_name','Downwelling irradiance at 412 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA412ADID,'standard_name','moles_of_DOWNIRRA412_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA412ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA412ADID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'resolution',' ');
    
    NDOWNIRRA412QCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA412QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA412QCID,'_FillValue',' ');
    
    NDOWNIRRA412ADQCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA412ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA412ADQCID,'_FillValue',' ');
    
    NDOWNIRRA412ADERRID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'_FillValue',single(fval));
    
    NRAWDOWNIRRA412ID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE412','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'long_name','Raw downwelling irradiance at 412 nanometers');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'standard_name','moles_of_RAWDOWNIRRA412_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'resolution',' ');
    
    NRAWDOWNIRRA412QCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE412_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA412QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412QCID,'_FillValue',' ');
    
    NDOWNIRRA443ID=netcdf.defVar(ncid,'DOWN_IRRADIANCE443','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA443ID,'long_name','Downwelling irradiance at 443 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA443ID,'standard_name','moles_of_DOWNIRRA443_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA443ID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA443ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA443ID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA443ID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA443ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA443ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA443ID,'resolution',' ');
    
    NDOWNIRRA443ADID=netcdf.defVar(ncid,'DOWN_IRRADIANCE443_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA443ADID,'long_name','Downwelling irradiance at 443 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA443ADID,'standard_name','moles_of_DOWNIRRA443_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA443ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA443ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA443ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA443ADID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA443ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA443ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA443ADID,'resolution',' ');
    
    NDOWNIRRA443QCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE443_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA443QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA443QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA443QCID,'_FillValue',' ');
    
    NDOWNIRRA443ADQCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE443_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA443ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA443ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA443ADQCID,'_FillValue',' ');
    
    NDOWNIRRA443ADERRID=netcdf.defVar(ncid,'DOWN_IRRADIANCE443_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA443ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNIRRA443ADERRID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA443ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA443ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA443ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNIRRA443ADERRID,'_FillValue',single(fval));
    
    NRAWDOWNIRRA443ID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE443','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'long_name','Raw downwelling irradiance at 443 nanometers');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'standard_name','moles_of_RAWDOWNIRRA443_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWNIRRA443ID,'resolution',' ');
    
    NRAWDOWNIRRA443QCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE443_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA443QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNIRRA443QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNIRRA443QCID,'_FillValue',' ');
    
    NDOWNIRRA490ID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'long_name','Downwelling irradiance at 490 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA490ID,'standard_name','moles_of_DOWNIRRA490_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA490ID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA490ID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'resolution',' ');
    
    NDOWNIRRA490ADID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'long_name','Downwelling irradiance at 490 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA490ADID,'standard_name','moles_of_DOWNIRRA490_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA490ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA490ADID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'resolution',' ');
    
    NDOWNIRRA490QCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA490QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA490QCID,'_FillValue',' ');
    
    NDOWNIRRA490ADQCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA490ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA490ADQCID,'_FillValue',' ');
    
    NDOWNIRRA490ADERRID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'_FillValue',single(fval));
    
    NRAWDOWNIRRA490ID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE490','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'long_name','Raw downwelling irradiance at 490 nanometers');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'standard_name','moles_of_RAWDOWNIRRA490_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'resolution',' ');
    
    NRAWDOWNIRRA490QCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE490_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA490QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490QCID,'_FillValue',' ');
    
    NDOWNIRRA555ID=netcdf.defVar(ncid,'DOWN_IRRADIANCE555','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA555ID,'long_name','Downwelling irradiance at 555 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA555ID,'standard_name','moles_of_DOWNIRRA555_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA555ID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA555ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA555ID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA555ID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA555ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA555ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA555ID,'resolution',' ');
    
    NDOWNIRRA555ADID=netcdf.defVar(ncid,'DOWN_IRRADIANCE555_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA555ADID,'long_name','Downwelling irradiance at 555 nanometers');
    %         netcdf.putAtt(ncid,NDOWNIRRA555ADID,'standard_name','moles_of_DOWNIRRA555_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NDOWNIRRA555ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA555ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NDOWNIRRA555ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NDOWNIRRA555ADID,'valid_max','');
    netcdf.putAtt(ncid,NDOWNIRRA555ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA555ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA555ADID,'resolution',' ');
    
    NDOWNIRRA555QCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE555_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA555QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA555QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA555QCID,'_FillValue',' ');
    
    NDOWNIRRA555ADQCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE555_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA555ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA555ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA555ADQCID,'_FillValue',' ');
    
    NDOWNIRRA555ADERRID=netcdf.defVar(ncid,'DOWN_IRRADIANCE555_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA555ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNIRRA555ADERRID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA555ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA555ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA555ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNIRRA555ADERRID,'_FillValue',single(fval));
    
    NRAWDOWNIRRA555ID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE555','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'long_name','Raw downwelling irradiance at 555 nanometers');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'standard_name','moles_of_RAWDOWNIRRA555_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWNIRRA555ID,'resolution',' ');
    
    NRAWDOWNIRRA555QCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE555_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA555QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNIRRA555QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNIRRA555QCID,'_FillValue',' ');
        
    NUPRAD412ID=netcdf.defVar(ncid,'UP_RADIANCE412','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD412ID,'long_name','Upwelling radiance at 412 nanometers');
    netcdf.putAtt(ncid,NUPRAD412ID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD412ID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD412ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD412ID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD412ID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD412ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD412ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD412ID,'resolution',' ');
    
    NUPRAD412ADID=netcdf.defVar(ncid,'UP_RADIANCE412_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD412ADID,'long_name','Upwelling radiance at 412 nanometers');
    netcdf.putAtt(ncid,NUPRAD412ADID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD412ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NUPRAD412ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD412ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD412ADID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD412ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD412ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD412ADID,'resolution',' ');
    
    NUPRAD412QCID=netcdf.defVar(ncid,'UP_RADIANCE412_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD412QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD412QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD412QCID,'_FillValue',' ');
    
    NUPRAD412ADQCID=netcdf.defVar(ncid,'UP_RADIANCE412_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD412ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD412ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD412ADQCID,'_FillValue',' ');
    
    NUPRAD412ADERRID=netcdf.defVar(ncid,'UP_RADIANCE412_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD412ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NUPRAD412ADERRID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD412ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD412ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD412ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NUPRAD412ADERRID,'_FillValue',single(fval));
    
    NRAWUPRAD412ID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE412','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD412ID,'long_name','Raw Upwelling radiance at 412 nanometers');
    %         netcdf.putAtt(ncid,NRAWUPRAD412ID,'standard_name','moles_of_RAWUPRAD412_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWUPRAD412ID,'units','count');
    netcdf.putAtt(ncid,NRAWUPRAD412ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWUPRAD412ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWUPRAD412ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWUPRAD412ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWUPRAD412ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWUPRAD412ID,'resolution',' ');
    
    NRAWUPRAD412QCID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE412_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD412QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWUPRAD412QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWUPRAD412QCID,'_FillValue',' ');
        
    NUPRAD443ID=netcdf.defVar(ncid,'UP_RADIANCE443','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD443ID,'long_name','Upwelling radiance at 443 nanometers');
    netcdf.putAtt(ncid,NUPRAD443ID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD443ID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD443ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD443ID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD443ID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD443ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD443ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD443ID,'resolution',' ');
    
    NUPRAD443ADID=netcdf.defVar(ncid,'UP_RADIANCE443_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD443ADID,'long_name','Upwelling radiance at 443 nanometers');
    netcdf.putAtt(ncid,NUPRAD443ADID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD443ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NUPRAD443ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD443ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD443ADID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD443ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD443ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD443ADID,'resolution',' ');
    
    NUPRAD443QCID=netcdf.defVar(ncid,'UP_RADIANCE443_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD443QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD443QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD443QCID,'_FillValue',' ');
    
    NUPRAD443ADQCID=netcdf.defVar(ncid,'UP_RADIANCE443_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD443ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD443ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD443ADQCID,'_FillValue',' ');
    
    NUPRAD443ADERRID=netcdf.defVar(ncid,'UP_RADIANCE443_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD443ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NUPRAD443ADERRID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD443ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD443ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD443ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NUPRAD443ADERRID,'_FillValue',single(fval));
    
    NRAWUPRAD443ID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE443','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD443ID,'long_name','Raw Upwelling radiance at 443 nanometers');
    %         netcdf.putAtt(ncid,NRAWUPRAD443ID,'standard_name','moles_of_RAWUPRAD443_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWUPRAD443ID,'units','count');
    netcdf.putAtt(ncid,NRAWUPRAD443ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWUPRAD443ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWUPRAD443ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWUPRAD443ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWUPRAD443ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWUPRAD443ID,'resolution',' ');
    
    NRAWUPRAD443QCID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE443_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD443QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWUPRAD443QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWUPRAD443QCID,'_FillValue',' ');    
    
    NUPRAD490ID=netcdf.defVar(ncid,'UP_RADIANCE490','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD490ID,'long_name','Upwelling radiance at 490 nanometers');
    netcdf.putAtt(ncid,NUPRAD490ID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD490ID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD490ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD490ID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD490ID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD490ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD490ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD490ID,'resolution',' ');
    
    NUPRAD490ADID=netcdf.defVar(ncid,'UP_RADIANCE490_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD490ADID,'long_name','Upwelling radiance at 490 nanometers');
    netcdf.putAtt(ncid,NUPRAD490ADID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD490ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NUPRAD490ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD490ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD490ADID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD490ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD490ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD490ADID,'resolution',' ');
    
    NUPRAD490QCID=netcdf.defVar(ncid,'UP_RADIANCE490_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD490QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD490QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD490QCID,'_FillValue',' ');
    
    NUPRAD490ADQCID=netcdf.defVar(ncid,'UP_RADIANCE490_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD490ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD490ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD490ADQCID,'_FillValue',' ');
    
    NUPRAD490ADERRID=netcdf.defVar(ncid,'UP_RADIANCE490_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD490ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NUPRAD490ADERRID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD490ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD490ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD490ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NUPRAD490ADERRID,'_FillValue',single(fval));
    
    NRAWUPRAD490ID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE490','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD490ID,'long_name','Raw Upwelling radiance at 490 nanometers');
    %         netcdf.putAtt(ncid,NRAWUPRAD490ID,'standard_name','moles_of_RAWUPRAD490_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWUPRAD490ID,'units','count');
    netcdf.putAtt(ncid,NRAWUPRAD490ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWUPRAD490ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWUPRAD490ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWUPRAD490ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWUPRAD490ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWUPRAD490ID,'resolution',' ');
    
    NRAWUPRAD490QCID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE490_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD490QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWUPRAD490QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWUPRAD490QCID,'_FillValue',' ');
        
    NUPRAD555ID=netcdf.defVar(ncid,'UP_RADIANCE555','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD555ID,'long_name','Upwelling radiance at 555 nanometers');
    netcdf.putAtt(ncid,NUPRAD555ID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD555ID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD555ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD555ID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD555ID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD555ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD555ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD555ID,'resolution',' ');
    
    NUPRAD555ADID=netcdf.defVar(ncid,'UP_RADIANCE555_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD555ADID,'long_name','Upwelling radiance at 555 nanometers');
    netcdf.putAtt(ncid,NUPRAD555ADID,'standard_name','upwelling_radiance_in_sea_water');
    netcdf.putAtt(ncid,NUPRAD555ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NUPRAD555ADID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NUPRAD555ADID,'valid_min','');
    %         netcdf.putAtt(ncid,NUPRAD555ADID,'valid_max','');
    netcdf.putAtt(ncid,NUPRAD555ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD555ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD555ADID,'resolution',' ');
    
    NUPRAD555QCID=netcdf.defVar(ncid,'UP_RADIANCE555_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD555QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD555QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD555QCID,'_FillValue',' ');
    
    NUPRAD555ADQCID=netcdf.defVar(ncid,'UP_RADIANCE555_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD555ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NUPRAD555ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NUPRAD555ADQCID,'_FillValue',' ');
    
    NUPRAD555ADERRID=netcdf.defVar(ncid,'UP_RADIANCE555_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NUPRAD555ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NUPRAD555ADERRID,'units','W/m^2/nm/sr');
    netcdf.putAtt(ncid,NUPRAD555ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NUPRAD555ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NUPRAD555ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NUPRAD555ADERRID,'_FillValue',single(fval));
    
    NRAWUPRAD555ID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE555','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD555ID,'long_name','Raw Upwelling radiance at 555 nanometers');
    %         netcdf.putAtt(ncid,NRAWUPRAD555ID,'standard_name','moles_of_RAWUPRAD555_per_unit_mass_in_sea_water');
    netcdf.putAtt(ncid,NRAWUPRAD555ID,'units','count');
    netcdf.putAtt(ncid,NRAWUPRAD555ID,'_FillValue',single(fval));
    %         netcdf.putAtt(ncid,NRAWUPRAD555ID,'valid_min','');
    %         netcdf.putAtt(ncid,NRAWUPRAD555ID,'valid_max','');
    netcdf.putAtt(ncid,NRAWUPRAD555ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWUPRAD555ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWUPRAD555ID,'resolution',' ');
    
    NRAWUPRAD555QCID=netcdf.defVar(ncid,'RAW_UPWELLING_RADIANCE555_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWUPRAD555QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWUPRAD555QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWUPRAD555QCID,'_FillValue',' ');
        
end

if dbdat.irr2
    
    NDOWNIRRA380ID=netcdf.defVar(ncid,'DOWN_IRRADIANCE380','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA380ID,'long_name','Downwelling irradiance at 380 nanometers');
    netcdf.putAtt(ncid,NDOWNIRRA380ID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA380ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWNIRRA380ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA380ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA380ID,'resolution',' ');
    
    NDOWNIRRA380ADID=netcdf.defVar(ncid,'DOWN_IRRADIANCE380_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA380ADID,'long_name','Downwelling irradiance at 380 nanometers');
    netcdf.putAtt(ncid,NDOWNIRRA380ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA380ADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWNIRRA380ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA380ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA380ADID,'resolution',' ');
    
    NDOWNIRRA380QCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE380_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA380QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA380QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA380QCID,'_FillValue',' ');
    
    NDOWNIRRA380ADQCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE380_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA380ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA380ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA380ADQCID,'_FillValue',' ');
    
    NDOWNIRRA380ADERRID=netcdf.defVar(ncid,'DOWN_IRRADIANCE380_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA380ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNIRRA380ADERRID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA380ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA380ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA380ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNIRRA380ADERRID,'_FillValue',single(fval));
    
    NRAWDOWNIRRA380ID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE380','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA380ID,'long_name','Raw downwelling irradiance at 380 nanometers');
    netcdf.putAtt(ncid,NRAWDOWNIRRA380ID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWNIRRA380ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NRAWDOWNIRRA380ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWNIRRA380ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWNIRRA380ID,'resolution',' ');
    
    NRAWDOWNIRRA380QCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE380_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA380QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNIRRA380QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNIRRA380QCID,'_FillValue',' ');
        
    NDOWNIRRA412ID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'long_name','Downwelling irradiance at 412 nanometers');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA412ID,'resolution',' ');
    
    NDOWNIRRA412ADID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'long_name','Downwelling irradiance at 412 nanometers');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA412ADID,'resolution',' ');
    
    NDOWNIRRA412QCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA412QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA412QCID,'_FillValue',' ');
    
    NDOWNIRRA412ADQCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA412ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA412ADQCID,'_FillValue',' ');
    
    NDOWNIRRA412ADERRID=netcdf.defVar(ncid,'DOWN_IRRADIANCE412_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNIRRA412ADERRID,'_FillValue',single(fval));
    
    NRAWDOWNIRRA412ID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE412','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'long_name','Raw downwelling irradiance at 412 nanometers');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412ID,'resolution',' ');
    
    NRAWDOWNIRRA412QCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE412_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA412QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNIRRA412QCID,'_FillValue',' ');
        
    NDOWNIRRA490ID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'long_name','Downwelling irradiance at 490 nanometers');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA490ID,'resolution',' ');
    
    NDOWNIRRA490ADID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'long_name','Downwelling irradiance at 490 nanometers');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA490ADID,'resolution',' ');
    
    NDOWNIRRA490QCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA490QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA490QCID,'_FillValue',' ');
    
    NDOWNIRRA490ADQCID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNIRRA490ADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNIRRA490ADQCID,'_FillValue',' ');
    
    NDOWNIRRA490ADERRID=netcdf.defVar(ncid,'DOWN_IRRADIANCE490_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'units','W/m^2/nm');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNIRRA490ADERRID,'_FillValue',single(fval));
    
    NRAWDOWNIRRA490ID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE490','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'long_name','Raw downwelling irradiance at 490 nanometers');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490ID,'resolution',' ');
    
    NRAWDOWNIRRA490QCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_IRRADIANCE490_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNIRRA490QCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490QCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNIRRA490QCID,'_FillValue',' ');
    
    NDOWN_PARID=netcdf.defVar(ncid,'DOWNWELLING_PAR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWN_PARID,'long_name','Downwelling photosynthetic available radiation');
    netcdf.putAtt(ncid,NDOWN_PARID,'standard_name','downwelling_photosynthetic_photon_flux_in_sea_water');
    netcdf.putAtt(ncid,NDOWN_PARID,'units','microMoleQuanta/m^2/sec');
    netcdf.putAtt(ncid,NDOWN_PARID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWN_PARID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWN_PARID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWN_PARID,'resolution',' ');
    
    NDOWNPARADID=netcdf.defVar(ncid,'DOWNWELLING_PAR_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNPARADID,'long_name','Downwelling irradiance at 490 nanometers');
    netcdf.putAtt(ncid,NDOWN_PARID,'standard_name','downwelling_photosynthetic_photon_flux_in_sea_water');
    netcdf.putAtt(ncid,NDOWNPARADID,'units','microMoleQuanta/m^2/sec');
    netcdf.putAtt(ncid,NDOWNPARADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NDOWNPARADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNPARADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNPARADID,'resolution',' ');
    
    NDOWNPARQCID=netcdf.defVar(ncid,'DOWNWELLING_PAR_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNPARQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNPARQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNPARQCID,'_FillValue',' ');
    
    NDOWNPARADQCID=netcdf.defVar(ncid,'DOWNWELLING_PAR_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNPARADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NDOWNPARADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NDOWNPARADQCID,'_FillValue',' ');
    
    NDOWNPARADERRID=netcdf.defVar(ncid,'DOWNWELLING_PAR_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NDOWNPARADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NDOWNPARADERRID,'units','microMoleQuanta/m^2/sec');
    netcdf.putAtt(ncid,NDOWNPARADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NDOWNPARADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NDOWNPARADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NDOWNPARADERRID,'_FillValue',single(fval));
    
    NRAWDOWN_PARID=netcdf.defVar(ncid,'RAW_DOWNWELLING_PAR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWN_PARID,'long_name','Raw downwelling photosynthetic available radiation');
    netcdf.putAtt(ncid,NRAWDOWN_PARID,'units','count');
    netcdf.putAtt(ncid,NRAWDOWN_PARID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NRAWDOWN_PARID,'C_format','%9.1f');
    netcdf.putAtt(ncid,NRAWDOWN_PARID,'FORTRAN_format','F9.1');
    netcdf.putAtt(ncid,NRAWDOWN_PARID,'resolution',' ');
    
    NRAWDOWNPARQCID=netcdf.defVar(ncid,'RAW_DOWNWELLING_PAR_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NRAWDOWNPARQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NRAWDOWNPARQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NRAWDOWNPARQCID,'_FillValue',' ');
        
end


if dbdat.pH
    
    NPHINSITOLID=netcdf.defVar(ncid,'PH_IN_SITU_TOTAL','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NPHINSITOLID,'long_name','PH');
    netcdf.putAtt(ncid,NPHINSITOLID,'standard_name','sea_water_ph_reported_on_total_scale');
    netcdf.putAtt(ncid,NPHINSITOLID,'units','dimensionless');
    netcdf.putAtt(ncid,NPHINSITOLID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NPHINSITOLID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NPHINSITOLID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NPHINSITOLID,'resolution',' ');
    
    NPHINSITOLADID=netcdf.defVar(ncid,'PH_IN_SITU_TOTAL_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NPHINSITOLADID,'long_name','PH');
    netcdf.putAtt(ncid,NPHINSITOLID,'standard_name','sea_water_ph_reported_on_total_scale');
    netcdf.putAtt(ncid,NPHINSITOLADID,'units','dimensionless');
    netcdf.putAtt(ncid,NPHINSITOLADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NPHINSITOLADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NPHINSITOLADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NPHINSITOLADID,'resolution',' ');
    
    NPHINSITOLQCID=netcdf.defVar(ncid,'PH_IN_SITU_TOTAL_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NPHINSITOLQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NPHINSITOLQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NPHINSITOLQCID,'_FillValue',' ');
    
    NPHINSITOLADQCID=netcdf.defVar(ncid,'PH_IN_SITU_TOTAL_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NPHINSITOLADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NPHINSITOLADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NPHINSITOLADQCID,'_FillValue',' ');
    
    NPHINSITOLADERRID=netcdf.defVar(ncid,'PH_IN_SITU_TOTAL_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NPHINSITOLADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NPHINSITOLADERRID,'units','dimensionless');
    netcdf.putAtt(ncid,NPHINSITOLADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NPHINSITOLADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NPHINSITOLADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NPHINSITOLADERRID,'_FillValue',single(fval));
    
    NVRSPHID=netcdf.defVar(ncid,'VRS_PH','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NVRSPHID,'long_name','Voltage difference between reference and source from pH sensor');
    netcdf.putAtt(ncid,NVRSPHID,'units','volt');
    netcdf.putAtt(ncid,NVRSPHID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NVRSPHID,'C_format','%9.7f');
    netcdf.putAtt(ncid,NVRSPHID,'FORTRAN_format','F9.7');%%%%%F9.1%%%%%%%%%%%%%%
    netcdf.putAtt(ncid,NVRSPHID,'resolution',' ');
    
    NVRSPHQCID=netcdf.defVar(ncid,'VRS_PH_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NVRSPHQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NVRSPHQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NVRSPHQCID,'_FillValue',' ');
    
    NTEMPPHID=netcdf.defVar(ncid,'TEMP_PH','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTEMPPHID,'long_name','Sea temperature from pH sensor');
    netcdf.putAtt(ncid,NTEMPPHID,'units','volt');
    netcdf.putAtt(ncid,NTEMPPHID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NTEMPPHID,'C_format','%9.4f');
    netcdf.putAtt(ncid,NTEMPPHID,'FORTRAN_format','F9.4');%%%%%F9.1%%%%%%%%%%%%%%
    netcdf.putAtt(ncid,NTEMPPHID,'resolution',' ');
    
    NTEMPPHQCID=netcdf.defVar(ncid,'TEMP_PH_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTEMPPHQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NTEMPPHQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NTEMPPHQCID,'_FillValue',' ');
        
end

if isfield(fp,'Tilt')
    
    NTILTID=netcdf.defVar(ncid,'TILT','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTILTID,'long_name','Inclination of the float axis in respect to the local vertical');
    netcdf.putAtt(ncid,NTILTID,'units','degree');
    netcdf.putAtt(ncid,NTILTID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NTILTID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NTILTID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NTILTID,'resolution',' ');
    
    NTILTADID=netcdf.defVar(ncid,'TILT_ADJUSTED','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTILTADID,'long_name','Inclination of the float axis in respect to the local vertical');
    netcdf.putAtt(ncid,NTILTADID,'units','degree');
    netcdf.putAtt(ncid,NTILTADID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NTILTADID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NTILTADID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NTILTADID,'resolution',' ');
    
    NTILTQCID=netcdf.defVar(ncid,'TILT_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTILTQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NTILTQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NTILTQCID,'_FillValue',' ');
    
    NTILTADQCID=netcdf.defVar(ncid,'TILT_ADJUSTED_QC','NC_CHAR',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTILTADQCID,'long_name','quality flag');
    netcdf.putAtt(ncid,NTILTADQCID,'conventions','Argo reference table 2');
    netcdf.putAtt(ncid,NTILTADQCID,'_FillValue',' ');
    
    NTILTADERRID=netcdf.defVar(ncid,'TILT_ADJUSTED_ERROR','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTILTADERRID,'long_name','Contains the error on the adjusted values as determined by the delayed mode QC process');
    netcdf.putAtt(ncid,NTILTADERRID,'units','degree');
    netcdf.putAtt(ncid,NTILTADERRID,'C_format','%9.3f');
    netcdf.putAtt(ncid,NTILTADERRID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NTILTADERRID,'resolution',' ');
    netcdf.putAtt(ncid,NTILTADERRID,'_FillValue',single(fval));
    
    NTILTSTDID=netcdf.defVar(ncid,'TILT_STD','NC_FLOAT',[N_LEVELSID,N_PROFID]);
    netcdf.putAtt(ncid,NTILTSTDID,'long_name','Standard deviation of inclination of the float axis in respect to the local vertical');
    netcdf.putAtt(ncid,NTILTSTDID,'units','degree');
    netcdf.putAtt(ncid,NTILTSTDID,'_FillValue',single(fval));
    netcdf.putAtt(ncid,NTILTSTDID,'C_format','%9.7f');
    netcdf.putAtt(ncid,NTILTSTDID,'FORTRAN_format','F9.3');
    netcdf.putAtt(ncid,NTILTSTDID,'resolution',' ');
    
end

NPARAID=netcdf.defVar(ncid,'PARAMETER','NC_CHAR',[STR64,N_PARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NPARAID,'long_name','List of parameters with calibration information');
netcdf.putAtt(ncid,NPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NPARAID,'_FillValue',' ');

NSCICALEQUID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_EQUATION','NC_CHAR',[STR256,N_PARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALEQUID,'long_name','Calibration equation for this parameter');
netcdf.putAtt(ncid,NSCICALEQUID,'_FillValue',' ');

NSCICALCOEFID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_COEFFICIENT','NC_CHAR',[STR256,N_PARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALCOEFID,'long_name','Calibration coefficients for this equation');
netcdf.putAtt(ncid,NSCICALCOEFID,'_FillValue',' ');

NSCICALCOMID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_COMMENT','NC_CHAR',[STR256,N_PARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALCOMID,'long_name','Comment applying to this parameter calibration');
netcdf.putAtt(ncid,NSCICALCOMID,'_FillValue',' ');

NSCICALDAID=netcdf.defVar(ncid,'SCIENTIFIC_CALIB_DATE','NC_CHAR',[DaTi,N_PARID,N_CALIBID,N_PROFID]);
netcdf.putAtt(ncid,NSCICALDAID,'long_name','Date of calibration');
netcdf.putAtt(ncid,NSCICALDAID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NSCICALDAID,'_FillValue',' ');

%----History fields

NHISINSTID=netcdf.defVar(ncid,'HISTORY_INSTITUTION','NC_CHAR',[STR4,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISINSTID,'long_name','Institution which performed action');
netcdf.putAtt(ncid,NHISINSTID,'conventions','Argo reference table 4');
netcdf.putAtt(ncid,NHISINSTID,'_FillValue',' ');

NHISSTEPID=netcdf.defVar(ncid,'HISTORY_STEP','NC_CHAR',[STR4,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISSTEPID,'long_name','Step in data processing');
netcdf.putAtt(ncid,NHISSTEPID,'conventions','Argo reference table 12');
netcdf.putAtt(ncid,NHISSTEPID,'_FillValue',' ');

NHISSOFTID=netcdf.defVar(ncid,'HISTORY_SOFTWARE','NC_CHAR',[STR4,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISSOFTID,'long_name','Name of software which performed action');
netcdf.putAtt(ncid,NHISSOFTID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISSOFTID,'_FillValue',' ');

NHISSOFTREID=netcdf.defVar(ncid,'HISTORY_SOFTWARE_RELEASE','NC_CHAR',[STR4,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISSOFTREID,'long_name','Version/release of software which performed action');
netcdf.putAtt(ncid,NHISSOFTREID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISSOFTREID,'_FillValue',' ');

NHISREFID=netcdf.defVar(ncid,'HISTORY_REFERENCE','NC_CHAR',[STR64,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISREFID,'long_name','Reference of database');
netcdf.putAtt(ncid,NHISREFID,'conventions','Institution dependent');
netcdf.putAtt(ncid,NHISREFID,'_FillValue',' ');
%netcdf.putAtt(ncid,'HISTORY_REFERENCE'}(1,1,1:2)='CS');

NHISDAID=netcdf.defVar(ncid,'HISTORY_DATE','NC_CHAR',[DaTi,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISDAID,'long_name','Date the history record was created');
netcdf.putAtt(ncid,NHISDAID,'conventions','YYYYMMDDHHMISS');
netcdf.putAtt(ncid,NHISDAID,'_FillValue',' ');

NHISACTID=netcdf.defVar(ncid,'HISTORY_ACTION','NC_CHAR',[STR4,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISACTID,'long_name','Action performed on data');
netcdf.putAtt(ncid,NHISACTID,'conventions','Argo reference table 7');
netcdf.putAtt(ncid,NHISACTID,'_FillValue',' ');

NHISPARAID=netcdf.defVar(ncid,'HISTORY_PARAMETER','NC_CHAR',[STR16,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISPARAID,'long_name','Station parameter action is performed on');
netcdf.putAtt(ncid,NHISPARAID,'conventions','Argo reference table 3');
netcdf.putAtt(ncid,NHISPARAID,'_FillValue',' ');

NHISSTAPRESID=netcdf.defVar(ncid,'HISTORY_START_PRES','NC_FLOAT',[N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISSTAPRESID,'long_name','Start pressure action applied on');
% netcdf.putAtt(ncid,'HISTORY_START_PRES'}.conventions='Argo reference table 4');
netcdf.putAtt(ncid,NHISSTAPRESID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NHISSTAPRESID,'units','decibar');

NHISSTOPPRESID=netcdf.defVar(ncid,'HISTORY_STOP_PRES','NC_FLOAT',[N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISSTOPPRESID,'long_name','Stop pressure action applied on');
% netcdf.putAtt(ncid,'HISTORY_STOP_PRES'}.conventions='Argo reference table 4');
netcdf.putAtt(ncid,NHISSTOPPRESID,'_FillValue',single(fval));
netcdf.putAtt(ncid,NHISSTOPPRESID,'units','decibar');

NHISPREVALID=netcdf.defVar(ncid,'HISTORY_PREVIOUS_VALUE','NC_FLOAT',[N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISPREVALID,'long_name','Parameter/Flag previous value before action');
% netcdf.putAtt(ncid,'HISTORY_PREVIOUS_VALUE'}.conventions='Argo reference table 4');
netcdf.putAtt(ncid,NHISPREVALID,'_FillValue',single(fval));

NHISQCTID=netcdf.defVar(ncid,'HISTORY_QCTEST','NC_CHAR',[STR16,N_PROFID,N_HISID]);
netcdf.putAtt(ncid,NHISQCTID,'long_name','Documentation of tests performed, tests failed (in hex form)');
netcdf.putAtt(ncid,NHISQCTID,'conventions','Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
netcdf.putAtt(ncid,NHISQCTID,'_FillValue',' ');

%--- Finished defining variables, now write values! -----------------------

netcdf.endDef(ncid);

netcdf.putVar(ncid,NDATYID,0,length('B-Argo profile'),'B-Argo profile');
netcdf.putVar(ncid,NFMVRID,0,length('3.1'),'3.1');
netcdf.putVar(ncid,NHDVRID,0,length(' 1.2'),' 1.2');
netcdf.putVar(ncid,NREDTID,0,length('19500101000000'),'19500101000000');

% Fill fields for each profile

nlv = nlevels;
if isfield(fp,'p_oxygen')  %dbdat.subtype == 1006 || dbdat.subtype==1017 || dbdat.subtype==1008 || dbdat.subtype==1020
    nlv2 = fp.n_Oxysamples;
else
    nlv2=[];
end

oqc(1:nlv2)=0;
pdm(1:nin,1:n_param)=' ';
% pdm(1:nin,1:n_param)='R';

% if nlevels==0
%     nc{'DATA_MODE'}(1)=' ';
% else

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
        aa=ARGO_SYS_PARAM.PI_Name;
        netcdf.putVar(ncid,NPINAID,[0,ii-1],[length(ARGO_SYS_PARAM.PI_Name),1],ARGO_SYS_PARAM.PI_Name) ;  %'Susan Wijffels';
    end
    
    netcdf.putVar(ncid,NSTAPARAID,[0,0,ii-1],[length('PRES'),1,1],'PRES');
    netcdf.putVar(ncid,NPARAID,[0,0,0,ii-1],[length('PRES'),1,1,1],'PRES');
    aa='Adjusted values are provided in the core profile file';
    netcdf.putVar(ncid,NSCICALCOMID,[0,0,0,ii-1],[length(aa),1,1,1],aa);
    ij=1;
    pdm(ii,ij)='R';
    
    if dbdat.oxy
        if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1    % oxygen on primary axis
            ij=ij+1;
            pdm(ii,ij)='R';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('DOXY'),1,1],'DOXY');
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('DOXY'),1,1,1],'DOXY');
        elseif isfield(fp,'p_oxygen')  & ii==2
            if isfield(fp,'Rphase_raw') | ~isfield(fp,'no3_raw')   % oxygen on secondary axis (can have both)
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('DOXY'),1,1],'DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('DOXY'),1,1,1],'DOXY');
            end
        end
        
        if isfield(fp,'oxyT_raw')
            if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('TEMP_DOXY'),1,1],'TEMP_DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('TEMP_DOXY'),1,1,1],'TEMP_DOXY');
            elseif isfield(fp,'p_oxygen')  && ii==2
                if isfield(fp,'Rphase_raw')  | ~isfield(fp,'no3_raw')     % (dbdat.subtype==1006 | dbdat.subtype==1017 | dbdat.subtype==1020)
                    ij=ij+1;
                    pdm(ii,ij)='R';
                    netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('TEMP_DOXY'),1,1],'TEMP_DOXY');
                    netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('TEMP_DOXY'),1,1,1],'TEMP_DOXY');
                end
            end
        end
        
        if isfield(fp,'oxy_umolar')  %dbdat.subtype==31 || dbdat.subtype==32 || dbdat.subtype==35
            if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('MOLAR_DOXY'),1,1],'MOLAR_DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('MOLAR_DOXY'),1,1,1],'MOLAR_DOXY');
            elseif isfield(fp,'p_oxygen') && ii==2
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('MOLAR_DOXY'),1,1],'MOLAR_DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('MOLAR_DOXY'),1,1,1],'MOLAR_DOXY');
            end
        elseif isfield(fp,'SBEOxyfreq_raw')   %dbdat.subtype==1007 || dbdat.subtype==22 || dbdat.subtype==38
            if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('FREQUENCY_DOXY'),1,1],'FREQUENCY_DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('FREQUENCY_DOXY'),1,1,1],'FREQUENCY_DOXY');
            elseif isfield(fp,'p_oxygen') && ii==2
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('FREQUENCY_DOXY'),1,1],'FREQUENCY_DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('FREQUENCY_DOXY'),1,1,1],'FREQUENCY_DOXY');
            end
        elseif isfield(fp,'Bphase_raw')    %dbdat.subtype == 1002 || dbdat.subtype==1012
            if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('BPHASE_DOXY'),1,1],'BPHASE_DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('BPHASE_DOXY'),1,1,1],'BPHASE_DOXY');
            elseif isfield(fp,'p_oxygen') && ii==2
                ij=ij+1;
                pdm(ii,ij)='R';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length('BPHASE_DOXY'),1,1],'BPHASE_DOXY');
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length('BPHASE_DOXY'),1,1,1],'BPHASE_DOXY');
            end
        elseif isfield(fp,'Tphase_raw')
            if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='TPHASE_DOXY';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            elseif isfield(fp,'p_oxygen') && ii==2
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='TPHASE_DOXY';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            end
            if isfield(fp,'Rphase_raw')
                if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1
                    ij=ij+1;
                    pdm(ii,ij)='R';
                    aa='RPHASE_DOXY';
                    netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                    netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                elseif isfield(fp,'p_oxygen') && ii==2
                    ij=ij+1;
                    pdm(ii,ij)='R';
                    aa='RPHASE_DOXY';
                    netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                    netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                end
            end
            
        elseif isfield(fp,'O2phase_raw')   %dbdat.subtype==1017 && ii==2
            if (length(fp.p_raw)==length(fp.oxy_raw)) && ii==1
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='PHASE_DELAY_DOXY';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                if isfield(fp,'t_oxygen_volts')
                    ij=ij+1;
                    pdm(ii,ij)='R';
                    aa='TEMP_VOLTAGE_DOXY';
                    netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                    netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                end
            elseif isfield(fp,'p_oxygen') && ~isfield(fp,'no3_raw') && ii==2
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='PHASE_DELAY_DOXY';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                if isfield(fp,'t_oxygen_volts')
                    ij=ij+1;
                    pdm(ii,ij)='R';
                    aa='TEMP_VOLTAGE_DOXY';
                    netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                    netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
               end
            end
        end
    end
    
    
    if dbdat.flbb
        if length(fp.BBP700_raw)==length(fp.p_raw) & ii==1
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='CHLA';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='FLUORESCENCE_CHLA';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BBP700';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BETA_BACKSCATTERING700';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='TEMP_CPU_CHLA';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            if dbdat.flbb2
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='BBP532';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='BETA_BACKSCATTERING532';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            end
            
            if isfield(fp,'CDOM_raw')
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='FLUORESCENCE_CDOM';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='CDOM';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            end
            
        elseif length(fp.BBP700_raw)~=length(fp.p_raw) & ii==2
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='CHLA';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='FLUORESCENCE_CHLA';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BBP700';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BETA_BACKSCATTERING700';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='TEMP_CPU_CHLA';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            if dbdat.flbb2
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='BBP532';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='BETA_BACKSCATTERING532';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            end
            
            if isfield(fp,'CDOM_raw')
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='FLUORESCENCE_CDOM';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
                ij=ij+1;
                pdm(ii,ij)='R';
                aa='CDOM';
                netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
                netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
           end
        end
        
    end
    
    if dbdat.tmiss & ii==1
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660';
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='CP660';
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
    end
    
    if dbdat.eco & ii==1
        
        if dbdat.flbb
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BBP700_2';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BETA_BACKSCATTERING700_2';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        else
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BBP700';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
            ij=ij+1;
            pdm(ii,ij)='R';
            aa='BETA_BACKSCATTERING700';
            netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
            netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        end
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='BBP532';
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='BETA_BACKSCATTERING532';
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);        
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='BBP470';
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='BETA_BACKSCATTERING470';
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
    end
    
    
    if dbdat.suna & ii==2
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='NITRATE'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
    end
    
    if dbdat.irr & ~dbdat.irr2 & ii==1
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWN_IRRADIANCE412'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_IRRADIANCE412'; %raw
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWN_IRRADIANCE443'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_IRRADIANCE443'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWN_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWN_IRRADIANCE555'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_IRRADIANCE555'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='UP_RADIANCE412'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_UPWELLING_RADIANCE412'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
         
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='UP_RADIANCE443'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_UPWELLING_RADIANCE443'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='UP_RADIANCE490'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_UPWELLING_RADIANCE490'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='UP_RADIANCE555'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_UPWELLING_RADIANCE555'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
         
    end
    
    if dbdat.irr2 & ii==1
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWN_IRRADIANCE380'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_IRRADIANCE380'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWN_IRRADIANCE412'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
         
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_IRRADIANCE412'; %raw
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWN_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_IRRADIANCE490'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='DOWNWELLING_PAR'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='RAW_DOWNWELLING_PAR'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
    end   
    
    if dbdat.pH & ii==1
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='VRS_PH'; %intermediate
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='PH_IN_SITU_TOTAL'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
         
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='TEMP_PH'; %intermediate
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
    end
    
    if isfield(fp,'Tilt') & ii==1
        
        ij=ij+1;
        pdm(ii,ij)='R';
        aa='TILT'; %derived
        netcdf.putVar(ncid,NSTAPARAID,[0,ij-1,ii-1],[length(aa),1,1],aa);
        netcdf.putVar(ncid,NPARAID,[0,ij-1,0,ii-1],[length(aa),1,1,1],aa);
        
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
    
    clear today_str
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
    if ispc
        aa = [num2str(dbdat.wmo_id) '\' num2str(fp.profile_number)];
    else
        aa = [num2str(dbdat.wmo_id) '/' num2str(fp.profile_number)];
    end
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
        %         if dbdat.subtype == 1005
        %             aa='Near-surface sampling: discrete, pumped []';
        %         else
        aa='Secondary sampling: discrete []';
        [a2,mission]=getmission_number(dbdat.wmo_id,fp.profile_number,0,dbdat);
    end
    
    netcdf.putVar(ncid,NVERSAMPSCID,[0,ii-1],[length(aa),1],aa);
    netcdf.putVar(ncid,NCONFMISNUMID,ii-1,length(a2),a2);

    %     if(adjusted)
    %         nc{'DATA_MODE'}(ii)='A';
    %     else
    %         nc{'DATA_MODE'}(ii)='R';
    %     end
    
    
    switch dbdat.wmo_inst_type
        case '831'
            aa = ['PALACE '];
        case '846'
            aa = ['APEX '];
        case '841'
            aa = ['PROVOR'];
        case '839'
            aa = ['PROVOR_II']
        case '844'
            aa = ['ARVOR '];
        case '851'
            aa = ['SOLO_W '];
        case '863'
            aa = ['NAVIS_A '];
        case '853'
            aa = ['S2A '];
    end
    
    for i=length(aa)+1:32
        aa=[aa ' '];
    end
    netcdf.putVar(ncid,NPLATYID,[0,ii-1],[length(aa),1],aa);
   
    
    ll = length(dbdat.wmo_inst_type);
    netcdf.putVar(ncid,NWMOINTYID,[0,ii-1],[length([dbdat.wmo_inst_type ' ']),1],[dbdat.wmo_inst_type ' '] );
    
    s=getadditionalinfo(dbdat.wmo_id);
    aa=s.Firmware_Revision;
    netcdf.putVar(ncid,NFIRVERID,[0,ii-1],[length(aa),1],aa);
    
    if isfield(fp,'jday_location') & ~isempty(fp.jday_location)
        jday_ref_1950 = fp.jday_location(1) - julian([1950 1 1 0 0 0]);
    else
        jday_ref_1950 = fp.jday(1) - julian([1950 1 1 0 0 0]);
    end
    
    %     jday_asc_end_1950 = fp.jday_ascent_end - julian([1950 1 1 0 0 0]);
    if isempty(fp.jday_ascent_end)
        jday_asc_end_1950 = jday_ref_1950;
    else
        jday_asc_end_1950 = fp.jday_ascent_end - julian([1950 1 1 0 0 0]);
    end
    
    netcdf.putVar(ncid,NJULDID,ii-1,length(jday_asc_end_1950),jday_asc_end_1950);
    netcdf.putVar(ncid,NJULDQCID,ii-1,1,'1');
    netcdf.putVar(ncid,NJULDLOCID,ii-1,length(jday_ref_1950),jday_ref_1950);
    if ~isnan(fp.lat(1))
        netcdf.putVar(ncid,NLATID,ii-1,length(fp.lat(1)),fp.lat(1));
        lonl = fp.lon(1);
        if lonl > 180
            lonl = lonl - 360;
        end
        netcdf.putVar(ncid,NLONGID,ii-1,length(lonl),lonl);
        if isfield(fp,'pos_qc')
            if fp.pos_qc~=0;
                if fp.pos_qc==7
                    netcdf.putVar(ncid,NPOSID,ii-1,1,'2');
                else
                    netcdf.putVar(ncid,NPOSID,ii-1,length(num2str(fp.pos_qc)),num2str(fp.pos_qc));
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
            %             nc{'PRES_QC'}(ii,1:nlv) = num2str(fp.p_qc(irev),'%1d');
            %
            %             qcflag = overall_qcflag(fp.p_qc);
            %             nc{'PROFILE_PRES_QC'}(ii) = qcflag;
        end
        
        if dbdat.oxy
            if ~isempty(fp.oxy_raw) & (length(fp.oxy_raw)==length(fp.p_raw))  %primary oxygen axis
                %         if dbdat.subtype==1008 & ~isempty(fp.oxy_raw) | (dbdat.oxy && ~isempty(fp.oxy_raw) & ~isfield(fp,'p_oxygen')); %&&  dbdat.subtype~=1006 && dbdat.subtype~=1017 && dbdat.subtype~=1020
                netcdf.putVar(ncid,NDOXYID,[0,ii-1],[length(nan2fv(fp.oxy_raw(irev),fval)),1],nan2fv(fp.oxy_raw(irev),fval));
                oqc2=get_derived_oqc(fp.oxy_qc(irev),fp.oxy_raw(irev));
                netcdf.putVar(ncid,NDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                if isfield(fp,'oxyT_raw') & (length(fp.oxyT_raw)==length(fp.p_raw))
                    if ~isempty(fp.oxyT_raw)
                        netcdf.putVar(ncid,NTEMPDOXYID,[0,ii-1],[length(nan2fv(fp.oxyT_raw(irev),fval)),1],nan2fv(fp.oxyT_raw(irev),fval));
                        oqc2=get_derived_oqc(fp.oxyT_qc(irev),fp.oxyT_raw(irev));
                        netcdf.putVar(ncid,NTEMPDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                        qcflag = overall_qcflag(fp.oxyT_qc);
                        if(qcflag=='F')
                            %                             qcflag=' ';
                        end
                        netcdf.putVar(ncid,NPROTEMPDOXYQCID,ii-1,length(qcflag),qcflag);
                    end
                end
                if adjusted
                    if ~isempty(fp.oxy_calibrate)
                        oc=qc_apply4(fp.oxy_calibrate(irev),fp.oxy_qc(irev));
                        netcdf.putVar(ncid,NDOXYADID,[0,ii-1],[length(nan2fv(oc,fval)),1],nan2fv(oc,fval));
                    else
                        oc=qc_apply4(fp.oxy_raw(irev),fp.oxy_qc(irev));
                        netcdf.putVar(ncid,NDOXYADID,[0,ii-1],[length(nan2fv(oc,fval)),1],nan2fv(oc,fval));
                    end
                    oqc2=get_derived_oqc(fp.oxy_qc(irev),fp.oxy_raw(irev));
                    netcdf.putVar(ncid,NDOXYADQCID,[0,ii-1],[length(num2str(fp.oxy_qc(irev),'%1d')),1],num2str(fp.oxy_qc(irev),'%1d'));
                end
                
                qcflag = overall_qcflag(fp.oxy_qc);
                if(qcflag=='F')
                    %                     qcflag=' ';
                end
                netcdf.putVar(ncid,NPRODOXYQCID,ii-1,length(qcflag),qcflag);
                
                % now do the raw fields:
                %   floats that report DO concentration from either a Seabird IDO or Aandera Optode sensor:
                
                if isfield(fp,'oxy_umolar') & (length(fp.oxy_umolar)==length(fp.p_raw))    %(dbdat.subtype==32 || dbdat.subtype==35 || dbdat.subtype==31 || dbdat.subtype==40)
                    oqc=fp.oxy_qc(irev);
                    %                     mdc=qc_apply4(fp.oxy_umolar(irev),fp.oxy_qc(irev));
                    netcdf.putVar(ncid,NMOLARDOXYID,[0,ii-1],[length(nan2fv(fp.oxy_umolar(irev),fval)),1],nan2fv(fp.oxy_umolar(irev),fval));
                    oqc2=get_intermediate_oqc(oqc,fp.oxy_umolar(irev));
                    netcdf.putVar(ncid,NMOLARDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(fp.oxy_qc);
                    if(qcflag=='F')
                        % %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROMOLARDOXYQCID,ii-1,length(qcflag),qcflag);
                    
                    %       floats that report O2 frequency from a Seabird IDO sensor:
                    
                elseif isfield(fp,'SBEOxyfreq_raw') & (length(fp.SBEOxyfreq_raw)==length(fp.p_raw))  %intermediate
                    oqc=fp.oxy_qc(irev);
                    %                     fdc=qc_apply4(fp.SBEOxyfreq_raw(irev),oqc);
                    oqc2=get_intermediate_oqc(oqc,fp.SBEOxyfreq_raw(irev));
                    netcdf.putVar(ncid,NFREQDOXYID,[0,ii-1],[length(nan2fv(fp.SBEOxyfreq_raw(irev),fval)),1],nan2fv(fp.SBEOxyfreq_raw(irev),fval));
                    netcdf.putVar(ncid,NFREQDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    if(qcflag=='F')
                        %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROFREQDOXYQCID,ii-1,length(qcflag),qcflag);
                    
                    %       floats that report Bphase  from an Anderaa Optode sensor:
                    
                elseif isfield(fp,'Bphase_raw') & (length(fp.Bphase_raw)==length(fp.p_raw))   %((dbdat.subtype~=1006 && dbdat.subtype~=1017 && dbdat.subtype~=1008 && dbdat.subtype~=1020) || dbdat.subtype==1002 || dbdat.subtype==1012)
                    
                    %                     bdc=qc_apply4(fp.Bphase_raw(irev),fp.oxy_qc(irev));
                    netcdf.putVar(ncid,NBPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.Bphase_raw(irev),fval)),1],nan2fv(fp.Bphase_raw(irev),fval));
                    oqc2=get_intermediate_oqc(fp.oxy_qc(irev),fp.Bphase_raw(irev));
                    netcdf.putVar(ncid,NBPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(fp.oxy_qc);
                    if(qcflag=='F')
                        %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROBPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                    
                elseif isfield(fp,'Tphase_raw') & (length(fp.Tphase_raw)==length(fp.p_raw))   %((dbdat.subtype~=1006 && dbdat.subtype~=1017 && dbdat.subtype~=1008 && dbdat.subtype~=1020) || dbdat.subtype==1002 || dbdat.subtype==1012)
                    
                    %                     bdc=qc_apply4(fp.Bphase_raw(irev),fp.oxy_qc(irev));
                    netcdf.putVar(ncid,NTPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.Tphase_raw(irev),fval)),1],nan2fv(fp.Tphase_raw(irev),fval));
                     oqc2=get_intermediate_oqc(fp.oxy_qc(irev),fp.Tphase_raw(irev));
                    netcdf.putVar(ncid,NTPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(fp.oxy_qc);
                    if(qcflag=='F')
                        %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROTPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                    
                    if isfield(fp,'Rphase_raw') & (length(fp.Rphase_raw)==length(fp.p_raw))   %((dbdat.subtype~=1006 && dbdat.subtype~=1017 && dbdat.subtype~=1008 && dbdat.subtype~=1020) || dbdat.subtype==1002 || dbdat.subtype==1012)
                        
                        %                     bdc=qc_apply4(fp.Bphase_raw(irev),fp.oxy_qc(irev));
                        netcdf.putVar(ncid,NRPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.Rphase_raw(irev),fval)),1],nan2fv(fp.Rphase_raw(irev),fval));
                        oqc2=get_intermediate_oqc(fp.oxy_qc(irev),fp.Rphase_raw(irev));
                        netcdf.putVar(ncid,NRPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                        qcflag = overall_qcflag(fp.oxy_qc);
                        if(qcflag=='F')
                            %                         qcflag=' ';
                        end
                        netcdf.putVar(ncid,NPRORPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                     end
                    
                elseif isfield(fp,'O2phase_raw') & (length(fp.O2phase_raw)==length(fp.p_raw))   %((dbdat.subtype~=1006 && dbdat.subtype~=1017 && dbdat.subtype~=1008 && dbdat.subtype~=1020) || dbdat.subtype==1002 || dbdat.subtype==1012)
                    oqc=fp.oxy_qc(irev);
                    %                     bdc=qc_apply4(fp.O2phase_raw(irev),fp.oxy_qc(irev));
                    netcdf.putVar(ncid,NPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.O2phase_raw(irev),fval)),1],nan2fv(fp.O2phase_raw(irev),fval));
                    oqc2=get_intermediate_oqc(oqc,fp.O2phase_raw(irev));
                    netcdf.putVar(ncid,NPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(fp.oxy_qc);
                    if(qcflag=='F')
                        %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                    if isfield(fp,'t_oxygen_volts')
                        %                     otdc=qc_apply4(fp.t_oxygen_volts(irev),fp.oxy_qc(irev));
                        netcdf.putVar(ncid,NTEMPVOLDOXYID,[0,ii-1],[length(nan2fv(fp.t_oxygen_volts(irev),fval)),1],nan2fv(fp.t_oxygen_volts(irev),fval));
                        oqc2=get_intermediate_oqc(fp.oxy_qc(irev),fp.t_oxygen_volts(irev));
                        netcdf.putVar(ncid,NTEMPVOLDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    end
                    qcflag=='0';
                    netcdf.putVar(ncid,NPROTEMPVOLDOXYQCID,ii-1,length(qcflag),qcflag);
                end
            end
        end
        
        if dbdat.flbb & length(fp.CHLa_raw)==length(fp.p_raw)
            
            oqc=fp.CHLa_qc(irev);
            
            %             bdc=qc_apply4(fp.CHLa_raw(irev),fp.oxy_qc(irev));
            if ~isempty(fp.CHLa_raw) & any(~isnan(fp.CHLa_raw))
                oqc2=get_derived_oqc(oqc,fp.CHLa_raw(irev));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NCHLAID,[0,ii-1],[length(nan2fv(fp.CHLa_raw(irev),fval)),1],nan2fv(fp.CHLa_raw(irev),fval));
                netcdf.putVar(ncid,NCHLAQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                netcdf.putVar(ncid,NPROCHLAQCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~isempty(fp.Fsig) & any(~isnan(fp.Fsig))
                oqc2=get_intermediate_oqc(oqc,fp.Fsig(irev));
                qcflag = overall_qcflag(oqc2);
                 netcdf.putVar(ncid,NFLUOCHLAID,[0,ii-1],[length(nan2fv(fp.Fsig(irev),fval)),1],nan2fv(fp.Fsig(irev),fval));
                netcdf.putVar(ncid,NFLUOCHLAQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                netcdf.putVar(ncid,NPROFLUOCHLAQCID,ii-1,length(qcflag),qcflag)
            end
            
            if ~isempty(fp.BBP700_raw) & any(~isnan(fp.BBP700_raw))
                oqc(1:nlv)=fp.BBP700_qc(irev);
                oqc2=get_derived_oqc(oqc,fp.BBP700_raw(irev));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NBBP700ID,[0,ii-1],[length(nan2fv(fp.BBP700_raw(irev),fval)),1],nan2fv(fp.BBP700_raw(irev),fval));
                netcdf.putVar(ncid,NBBP700QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                netcdf.putVar(ncid,NPROBBP700QCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~isempty(fp.Bbsig) & any(~isnan(fp.Bbsig))
                oqc2=get_intermediate_oqc(oqc,fp.Bbsig(irev));
                netcdf.putVar(ncid,NBETABACK700ID,[0,ii-1],[length(nan2fv(fp.Bbsig(irev),fval)),1],nan2fv(fp.Bbsig(irev),fval));
                netcdf.putVar(ncid,NBETABACK700QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                if(qcflag=='F')
                    %                     qcflag=' ';
                end
                netcdf.putVar(ncid,NPROBETABACK700QCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~isempty(fp.Tsig) & any(~isnan(fp.Tsig))
                oqc2=get_derived_oqc(oqc,fp.Tsig(irev));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NTEMPCPUCHLAID,[0,ii-1],[length(nan2fv(fp.Tsig(irev),fval)),1],nan2fv(fp.Tsig(irev),fval));
                netcdf.putVar(ncid,NTEMPCPUCHLAQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                netcdf.putVar(ncid,NPROTEMPCPUCHLAQCID,ii-1,length(qcflag),qcflag);
            end
            
            if isfield(fp,'CDOM_raw') & any(~isnan(fp.CDOM_raw))
                if ~isempty(fp.CDOM_raw)
                    oqc(1:nlv)=fp.CDOM_qc(irev);
                    oqc2=get_derived_oqc(oqc,fp.CDOM_raw(irev));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NCDOMID,[0,ii-1],[length(nan2fv(fp.CDOM_raw(irev),fval)),1],nan2fv(fp.CDOM_raw(irev),fval));
                    netcdf.putVar(ncid,NCDOMQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    if(qcflag=='F')
                        %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROCDOMQCID,ii-1,length(qcflag),qcflag);
                end
                
                if ~isempty(fp.Cdsig) & any(~isnan(fp.Cdsig))
                    oqc2=get_intermediate_oqc(oqc,fp.Cdsig(irev));
                    netcdf.putVar(ncid,NFLUOCDOMID,[0,ii-1],[length(nan2fv(fp.Cdsig(irev),fval)),1],nan2fv(fp.Cdsig(irev),fval));
                    netcdf.putVar(ncid,NFLUOCDOMQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    if(qcflag=='F')
                        %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROFLUOCDOMQCID,ii-1,length(qcflag),qcflag);
                end
            end
        end
        
        if dbdat.flbb2 & length(fp.BBP532_raw)==length(fp.p_raw)
            oqc(1:nlv)=0;
            oqc2=get_derived_oqc(oqc,fp.BBP532_raw(irev));
            netcdf.putVar(ncid,NBBP532ID,[0,ii-1],[length(nan2fv(fp.BBP532_raw(irev),fval)),1],nan2fv(fp.BBP532_raw(irev),fval));
            netcdf.putVar(ncid,NBBP532QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
            qcflag = overall_qcflag(oqc);
            netcdf.putVar(ncid,NPROBBP532QCID,ii-1,length(qcflag),qcflag);
            if ~isempty(fp.Bbsig532) & any(~isnan(fp.Bbsig532))
                oqc2=get_intermediate_oqc(oqc,fp.Bbsig532(irev));
                netcdf.putVar(ncid,NBETABACK532ID,[0,ii-1],[length(nan2fv(fp.Bbsig532(irev),fval)),1],nan2fv(fp.Bbsig532(irev),fval));
                netcdf.putVar(ncid,NBETABACK532QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPROBETABACK532QCID,ii-1,length(qcflag),qcflag);
            end
        end
        
        if dbdat.tmiss  % ours have tmiss data on primary axis only
            % note - no QC on raw tmiss data
            oqc=fp.CP_qc(irev);
            oqc2=get_intermediate_oqc(oqc,fp.tm_counts(irev));
            netcdf.putVar(ncid,NTRANSPARBEATT660ID,[0,ii-1],[length(nan2fv(fp.tm_counts(irev),fval)),1],nan2fv(fp.tm_counts(irev),fval));
            netcdf.putVar(ncid,NTRANSPARBEATT660QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
            
            oqc2=get_derived_oqc(oqc,fp.CP_raw(irev));
            netcdf.putVar(ncid,NCP660ID,[0,ii-1],[length(nan2fv(fp.CP_raw(irev),fval)),1],nan2fv(fp.CP_raw(irev),fval));
            netcdf.putVar(ncid,NCP660QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
            
        end
        
        if dbdat.eco
            if dbdat.flbb
                if ~isempty(fp.ecoBBP700_raw) & any(~isnan(fp.ecoBBP700_raw))
                    oqc(1:nlv)=0;
                    oqc2=get_derived_oqc(oqc,fp.ecoBBP700_raw(irev));
                    netcdf.putVar(ncid,NBBP7002ID,[0,ii-1],[length(nan2fv(fp.ecoBBP700_raw(irev),fval)),1],nan2fv(fp.BBP700_raw(irev),fval));
                    netcdf.putVar(ncid,NBBP7002QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    if(qcflag=='F')
                        %                     qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPROBBP7002QCID,ii-1,length(qcflag),qcflag);
                end
                
                if ~isempty(fp.ecoBbsig700) & any(~isnan(fp.ecoBbsig700))
                    oqc2=get_intermediate_oqc(oqc,fp.ecoBbsig700(irev));
                    netcdf.putVar(ncid,NBETABACK7002ID,[0,ii-1],[length(nan2fv(fp.ecoBbsig700(irev),fval)),1],nan2fv(fp.ecoBbsig700(irev),fval));
                    netcdf.putVar(ncid,NBETABACK7002QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPROBETABACK7002QCID,ii-1,length(qcflag),qcflag);
                end
            else
                if ~isempty(fp.ecoBBP700_raw) & any(~isnan(fp.ecoBBP700_raw))
                    oqc(1:nlv)=0;
                    oqc2=get_derived_oqc(oqc,fp.ecoBBP700_raw(irev));
                    netcdf.putVar(ncid,NBBP700ID,[0,ii-1],[length(nan2fv(fp.ecoBBP700_raw(irev),fval)),1],nan2fv(fp.ecoBBP700_raw(irev),fval));
                    netcdf.putVar(ncid,NBBP700QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPROBBP700QCID,ii-1,length(qcflag),qcflag);
                end
                
                if ~isempty(fp.ecoBbsig700) & any(~isnan(fp.ecoBbsig700))
                    oqc2=get_intermediate_oqc(oqc,fp.ecoBbsig700(irev));
                    netcdf.putVar(ncid,NBETABACK700ID,[0,ii-1],[length(nan2fv(fp.ecoBbsig700(irev),fval)),1],nan2fv(fp.ecoBbsig700(irev),fval));
                    netcdf.putVar(ncid,NBETABACK700QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPROBETABACK700QCID,ii-1,length(qcflag),qcflag);
                end
            end
            
            if ~isempty(fp.ecoBBP532_raw) & any(~isnan(fp.ecoBBP532_raw))
                oqc(1:nlv)=0;
                oqc2=get_derived_oqc(oqc,fp.ecoBBP532_raw(irev));
                netcdf.putVar(ncid,NBBP532ID,[0,ii-1],[length(nan2fv(fp.ecoBBP532_raw(irev),fval)),1],nan2fv(fp.ecoBBP532_raw(irev),fval));
                netcdf.putVar(ncid,NBBP532QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROBBP532QCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~isempty(fp.ecoBbsig532) & any(~isnan(fp.ecoBbsig532))
                oqc2=get_intermediate_oqc(oqc,fp.ecoBbsig532(irev));
                netcdf.putVar(ncid,NBETABACK532ID,[0,ii-1],[length(nan2fv(fp.ecoBbsig532(irev),fval)),1],nan2fv(fp.ecoBbsig532(irev),fval));
                netcdf.putVar(ncid,NBETABACK532QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPROBETABACK532QCID,ii-1,length(qcflag),qcflag);
            end
            if ~isempty(fp.ecoBBP470_raw) & any(~isnan(fp.ecoBBP470_raw))
                oqc2=get_intermediate_oqc(oqc,fp.ecoBbsig470(irev));
                
                netcdf.putVar(ncid,NBBP470ID,[0,ii-1],[length(nan2fv(fp.ecoBBP470_raw(irev),fval)),1],nan2fv(fp.ecoBBP470_raw(irev),fval));
                netcdf.putVar(ncid,NBBP470QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROBBP470QCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~isempty(fp.ecoBbsig470) & any(~isnan(fp.ecoBbsig470))
                oqc2=get_intermediate_oqc(oqc,fp.ecoBbsig470(irev));
                netcdf.putVar(ncid,NBETABACK470ID,[0,ii-1],[length(nan2fv(fp.ecoBbsig470(irev),fval)),1],nan2fv(fp.ecoBbsig470(irev),fval));
                netcdf.putVar(ncid,NBETABACK470QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPROBETABACK470QCID,ii-1,length(qcflag),qcflag);
                
            end
            
        end
        
        
        if dbdat.irr
            
            oqc(1:nlv)=0;
            
            if dbdat.irr2
                if ~isempty(fp.dn_irr380_raw)  & any(~isnan(fp.dn_irr380_raw))
                     oqc2=get_derived_oqc(oqc,fp.dn_irr380_raw(irev));
                    netcdf.putVar(ncid,NDOWNIRRA380ID,[0,ii-1],[length(nan2fv(fp.dn_irr380_raw(irev),fval)),1],nan2fv(fp.dn_irr380_raw(irev),fval));
                    netcdf.putVar(ncid,NDOWNIRRA380QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    if(qcflag=='F')
                        %                     qcflag=' ';
                    end
                     netcdf.putVar(ncid,NPRODOWNIRRA380QCID,ii-1,length(qcflag),qcflag);
                end
                if ~isempty(fp.irr380) & any(~isnan(fp.irr380))
                     oqc2=get_intermediate_oqc(oqc,fp.irr380(irev));
                    netcdf.putVar(ncid,NRAWDOWNIRRA380ID,[0,ii-1],[length(nan2fv(fp.irr380(irev),fval)),1], nan2fv(fp.irr380(irev),fval));
                    netcdf.putVar(ncid,NRAWDOWNIRRA380QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    if(qcflag=='F')
                        %                         qcflag=' ';
                    end
                    netcdf.putVar(ncid,NPRORAWDOWNIRRA380QCID,ii-1,length(qcflag),qcflag);
                end
            end
            
            if ~isempty(fp.dn_irr412_raw) & any(~isnan(fp.dn_irr412_raw))
                oqc2=get_derived_oqc(oqc,fp.dn_irr412_raw(irev));
                netcdf.putVar(ncid,NDOWNIRRA412ID,[0,ii-1],[length(nan2fv(fp.dn_irr412_raw(irev),fval)),1],nan2fv(fp.dn_irr412_raw(irev),fval));
                netcdf.putVar(ncid,NDOWNIRRA412QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPRODOWNIRRA412QCID,ii-1,length(qcflag),qcflag);
            end
            
            
            if ~isempty(fp.irr412) & any(~isnan(fp.irr412))
                oqc2=get_intermediate_oqc(oqc,fp.irr412(irev));
                netcdf.putVar(ncid,NRAWDOWNIRRA412ID,[0,ii-1],[length(nan2fv(fp.irr412(irev),fval)),1], nan2fv(fp.irr412(irev),fval));
                netcdf.putVar(ncid,NRAWDOWNIRRA412QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                
                qcflag = overall_qcflag(oqc2);
                if(qcflag=='F')
                    %                         qcflag=' ';
                end
                netcdf.putVar(ncid,NPRORAWDOWNIRRA412QCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~dbdat.irr2
                if ~isempty(fp.dn_irr443_raw) & any(~isnan(fp.dn_irr443_raw))
                     oqc2=get_derived_oqc(oqc,fp.dn_irr443_raw(irev));
                    
                    netcdf.putVar(ncid,NDOWNIRRA443ID,[0,ii-1],[length(nan2fv(fp.dn_irr443_raw(irev),fval)),1],nan2fv(fp.dn_irr443_raw(irev),fval));
                    netcdf.putVar(ncid,NDOWNIRRA443QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPRODOWNIRRA443QCID,ii-1,length(qcflag),qcflag);
                end
                
                
                if ~isempty(fp.irr443) & any(~isnan(fp.irr443))
                    oqc2=get_intermediate_oqc(oqc,fp.irr443(irev));
                    netcdf.putVar(ncid,NRAWDOWNIRRA443ID,[0,ii-1],[length(nan2fv(fp.irr443(irev),fval)),1], nan2fv(fp.irr443(irev),fval));
                    netcdf.putVar(ncid,NRAWDOWNIRRA443QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPRORAWDOWNIRRA443QCID,ii-1,length(qcflag),qcflag);
                end
            end
            
            if ~isempty(fp.dn_irr490_raw) & any(~isnan(fp.dn_irr490_raw))
                oqc2=get_derived_oqc(oqc,fp.dn_irr490_raw(irev));
                
                netcdf.putVar(ncid,NDOWNIRRA490ID,[0,ii-1],[length(nan2fv(fp.dn_irr490_raw(irev),fval)),1],nan2fv(fp.dn_irr490_raw(irev),fval));
                netcdf.putVar(ncid,NDOWNIRRA490QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPRODOWNIRRA490QCID,ii-1,length(qcflag),qcflag);
            end
            
            
            if ~isempty(fp.irr490) & any(~isnan(fp.irr490))
                oqc2=get_intermediate_oqc(oqc,fp.irr490(irev));
                
                netcdf.putVar(ncid,NRAWDOWNIRRA490ID,[0,ii-1],[length(nan2fv(fp.irr490(irev),fval)),1], nan2fv(fp.irr490(irev),fval));
                netcdf.putVar(ncid,NRAWDOWNIRRA490QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPRORAWDOWNIRRA490QCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~dbdat.irr2
                if ~isempty(fp.dn_irr555_raw) & any(~isnan(fp.dn_irr555_raw))
                    oqc2=get_derived_oqc(oqc,fp.dn_irr555_raw(irev));
                     netcdf.putVar(ncid,NDOWNIRRA555ID,[0,ii-1],[length(nan2fv(fp.dn_irr555_raw(irev),fval)),1],nan2fv(fp.dn_irr555_raw(irev),fval));
                    netcdf.putVar(ncid,NDOWNIRRA555QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPRODOWNIRRA555QCID,ii-1,length(qcflag),qcflag);
                end
                
                
                if ~isempty(fp.irr555) & any(~isnan(fp.irr555))
                    oqc2=get_intermediate_oqc(oqc,fp.irr555(irev));
                    netcdf.putVar(ncid,NRAWDOWNIRRA555ID,[0,ii-1],[length(nan2fv(fp.irr555(irev),fval)),1], nan2fv(fp.irr555(irev),fval));
                    netcdf.putVar(ncid,NRAWDOWNIRRA555QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPRORAWDOWNIRRA555QCID,ii-1,length(qcflag),qcflag);
                end
            end
            
            if dbdat.irr2
                if ~isempty(fp.dn_irrPAR_raw) &  any(~isnan(fp.dn_irrPAR_raw))
                    oqc2=get_derived_oqc(oqc,fp.dn_irrPAR_raw(irev));
                    netcdf.putVar(ncid,NDOWN_PARID,[0,ii-1],[length(nan2fv(fp.dn_irrPAR_raw(irev),fval)),1],nan2fv(fp.dn_irrPAR_raw(irev),fval));
                    netcdf.putVar(ncid,NDOWNPARQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPRODOWNPARQCID,ii-1,length(qcflag),qcflag);
                end
                
                
                if ~isempty(fp.irrPAR)  % & ~isnan(fp.irrPAR)
                    oqc2=get_intermediate_oqc(oqc,fp.irrPAR(irev));
                    netcdf.putVar(ncid,NRAWDOWN_PARID,[0,ii-1],[length(nan2fv(fp.irrPAR(irev),fval)),1],nan2fv(fp.irrPAR(irev),fval));
                    netcdf.putVar(ncid,NRAWDOWNPARQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPRORAWDOWNPARQCID,ii-1,length(qcflag),qcflag);
                end
            end
            
            % now upward values:
            
            if ~dbdat.irr2
                oqc(1:nlv)=0;
                if ~isempty(fp.up_rad412_raw) & any(~isnan(fp.up_rad412_raw))
                    oqc2=get_derived_oqc(oqc,fp.up_rad412_raw(irev));
                    netcdf.putVar(ncid,NUPRAD412ID,[0,ii-1],[length(nan2fv(fp.up_rad412_raw(irev),fval)),1],nan2fv(fp.up_rad412_raw(irev),fval));
                    netcdf.putVar(ncid,NUPRAD412QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc2);
                    netcdf.putVar(ncid,NPROUPRAD412QCID,ii-1,length(qcflag),qcflag);
                    
                end
                
                
                if ~isempty(fp.rad412) & any(~isnan(fp.rad412))
                    oqc2=get_intermediate_oqc(oqc,fp.rad412(irev));
                    netcdf.putVar(ncid,NRAWUPRAD412ID,[0,ii-1],[length(nan2fv(fp.rad412(irev),fval)),1], nan2fv(fp.rad412(irev),fval));
                    netcdf.putVar(ncid,NRAWUPRAD412QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPRORAWUPRAD412QCID,ii-1,length(qcflag),qcflag);
                end
                
                
                if ~isempty(fp.up_rad443_raw) & any(~isnan(fp.up_rad443_raw))
                    oqc2=get_derived_oqc(oqc,fp.up_rad443_raw(irev));
                    netcdf.putVar(ncid,NUPRAD443ID,[0,ii-1],[length(nan2fv(fp.up_rad443_raw(irev),fval)),1],nan2fv(fp.up_rad443_raw(irev),fval));
                    netcdf.putVar(ncid,NUPRAD443QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPROUPRAD443QCID,ii-1,length(qcflag),qcflag);
                end
                
                
                if ~isempty(fp.rad443) & any(~isnan(fp.rad443))
                    oqc2=get_intermediate_oqc(oqc,fp.rad443(irev));
                    netcdf.putVar(ncid,NRAWUPRAD443ID,[0,ii-1],[length(nan2fv(fp.rad443(irev),fval)),1], nan2fv(fp.rad443(irev),fval));
                    netcdf.putVar(ncid,NRAWUPRAD443QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPRORAWUPRAD443QCID,ii-1,length(qcflag),qcflag);
                    
                end
                
                
                if ~isempty(fp.up_rad490_raw)  & any(~isnan(fp.up_rad490_raw))
                    oqc2=get_derived_oqc(oqc,fp.up_rad490_raw(irev));
                    netcdf.putVar(ncid,NUPRAD490ID,[0,ii-1],[length(nan2fv(fp.up_rad490_raw(irev),fval)),1],nan2fv(fp.up_rad490_raw(irev),fval));
                    netcdf.putVar(ncid,NUPRAD490QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPROUPRAD490QCID,ii-1,length(qcflag),qcflag);
                    
                end
                
                
                if ~isempty(fp.rad490) & any(~isnan(fp.rad490))
                    oqc2=get_intermediate_oqc(oqc,fp.rad490(irev));
                    netcdf.putVar(ncid,NRAWUPRAD490ID,[0,ii-1],[length(nan2fv(fp.rad490(irev),fval)),1], nan2fv(fp.rad490(irev),fval));
                    netcdf.putVar(ncid,NRAWUPRAD490QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPRORAWUPRAD490QCID,ii-1,length(qcflag),qcflag);
                end
                
                if ~isempty(fp.up_rad555_raw) & any(~isnan(fp.up_rad555_raw))
                    oqc2=get_derived_oqc(oqc,fp.up_rad555_raw(irev));
                    netcdf.putVar(ncid,NUPRAD555ID,[0,ii-1],[length(nan2fv(fp.up_rad555_raw(irev),fval)),1],nan2fv(fp.up_rad555_raw(irev),fval));
                    netcdf.putVar(ncid,NUPRAD555QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPROUPRAD555QCID,ii-1,length(qcflag),qcflag);
                end
                 
                if ~isempty(fp.rad555) & any(~isnan(fp.rad555))
                    oqc2=get_intermediate_oqc(oqc,fp.rad555(irev));
                    netcdf.putVar(ncid,NRAWUPRAD555ID,[0,ii-1],[length(nan2fv(fp.rad555(irev),fval)),1], nan2fv(fp.rad555(irev),fval));
                    netcdf.putVar(ncid,NRAWUPRAD555QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                   netcdf.putVar(ncid,NPRORAWUPRAD555QCID,ii-1,length(qcflag),qcflag);
                end
                
            end
        end
        
        if dbdat.pH
            oqc(1:nlv)=0;
            if ~isempty(fp.pH_raw) & any(~isnan(fp.pH_raw))
                oqc2=get_derived_oqc(oqc,fp.pH_raw(irev));
                netcdf.putVar(ncid,NPHINSITOLQCIDID,[0,ii-1],[length(nan2fv(fp.pH_raw(irev),fval)),1],nan2fv(fp.pH_raw(irev),fval));
                netcdf.putVar(ncid,NPHINSITOLQCIDQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROPHINSITOLQCIDQCID,ii-1,length(qcflag),qcflag);
            end
            
            
            if ~isempty(fp.pHvolts) & any(~isnan(fp.pHvolts))
                oqc2=get_intermediate_oqc(oqc,fp.pHvolts(irev));
                netcdf.putVar(ncid,NVRSPHID,[0,ii-1],[length(nan2fv(fp.pHvolts(irev),fval)),1],nan2fv(fp.pHvolts(irev),fval));
                netcdf.putVar(ncid,NVRSPHQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROVRSPHQCID,ii-1,length(qcflag),qcflag);
            end
 
            
            if ~isempty(fp.pHT) & any(~isnan(fp.pHT))
                oqc2=get_derived_oqc(oqc,fp.pHT(irev));
                netcdf.putVar(ncid,NTEMPPHID,[0,ii-1],[length(nan2fv(fp.pHT(irev),fval)),1],nan2fv(fp.pHT(irev),fval));
                netcdf.putVar(ncid,NTEMPPHQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROTEMPPHQCID,ii-1,length(qcflag),qcflag);
                
            end
            
            
        end
        
        if isfield(fp,'Tilt')
            oqc(1:nlv)=0;
            if ~isempty(fp.Tilt) & any(~isnan(fp.Tilt))
                oqc2=get_derived_oqc(oqc,fp.Tilt(irev));
                netcdf.putVar(ncid,NTILTID,[0,ii-1],[length(nan2fv(fp.Tilt(irev),fval)),1],nan2fv(fp.Tilt(irev),fval));
                netcdf.putVar(ncid,NTILTQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROTILTQCID,ii-1,length(qcflag),qcflag);
            end
            if ~isempty(fp.Tilt_sd) & any(~isnan(fp.Tilt_sd))
                netcdf.putVar(ncid,NTILTSTDID,[0,ii-1],[length(nan2fv(fp.Tilt_sd(irev),fval)),1],nan2fv(fp.Tilt_sd(irev),fval));
            end
            
        end
                
    elseif ii==2
        
        if isfield(fp,'p_oxygen')   % dbdat.subtype==1006 || dbdat.subtype==1017 || dbdat.subtype==1008 || dbdat.subtype==1020
            p_c = fp.p_oxygen - fp.surfpres_used;  %calibrate fields
            p2=fp.p_oxygen;
            s2=fp.s_oxygen;
            t2=fp.t_oxygen;
        end
        QC.p=fp.p_oxygen_qc;
        QC.s=fp.s_oxygen_qc;
        QC.t=fp.t_oxygen_qc;
        %
        % need to take into account the primary QC values before assign
        % secondary QC:  AT Dec 2013
        
        priqcP=find(fp.p_qc>=3 & fp.p_qc<=4);
        %         priqcT=find(fp.t_qc>=3 & fp.t_qc<=4);
        %         priqcS=find(fp.s_qc>=3 & fp.s_qc<=4);
        
        if ~isempty(priqcP)
            ppbad=range(fp.p_calibrate(priqcP));
            ppreject=find(p2 > ppbad(1) & p2 < ppbad(2));
            QC.p(ppreject)=3;
            QC.s(ppreject)=3;
            QC.t(ppreject)=3;
            
        end
        
        if nlv2>0
            netcdf.putVar(ncid,NPRESID,[0,ii-1],[length(nan2fv(p2(irev2),fval)),1],nan2fv(p2(irev2),fval));
            %             pc=qc_apply4(p_c(irev2),QC.p(irev2));
            
            %             nc{'PRES_ADJUSTED'}(ii,1:nlv2) = nan2fv(pc,fval);
            %             nc{'PRES_ADJUSTED_QC'}(ii,1:nlv2) = num2str(QC.p(irev2),'%1d');
            %
            %             qcflag = overall_qcflag(QC.p);
            %             nc{'PROFILE_PRES_QC'}(ii) = qcflag;
        end
        
        if dbdat.oxy
            if  ~isempty(fp.oxy_raw) && ~isfield(fp,'FLBBoxy_raw') && length(fp.oxy_raw)~=length(fp.p_raw) %dbdat.subtype~=1008
                oqc=fp.oxy_qc(irev2);
                netcdf.putVar(ncid,NDOXYID,[0,ii-1],[length(nan2fv(fp.oxy_raw(irev2),fval)),1],nan2fv(fp.oxy_raw(irev2),fval));
                oqc2=get_derived_oqc(oqc,fp.oxy_raw(irev2));
                netcdf.putVar(ncid,NDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                
                if isfield(fp,'oxyT_raw');
                    netcdf.putVar(ncid,NTEMPDOXYID,[0,ii-1],[length(nan2fv(fp.oxyT_raw(irev2),fval)),1],nan2fv(fp.oxyT_raw(irev2),fval));
                    oqc2=get_derived_oqc(oqc,fp.oxyT_raw(irev2));
                    netcdf.putVar(ncid,NTEMPDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                end
                
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPRODOXYQCID,ii-1,length(qcflag),qcflag);
                if adjusted
                    if ~isempty(fp.oxy_calibrate)
                        oc=qc_apply4(fp.oxy_calibrate(irev2),fp.oxy_qc(irev2));
                        netcdf.putVar(ncid,NDOXYADID,[0,ii-1],[length(nan2fv(oc,fval)),1],nan2fv(oc,fval));
                    else
                        oc=qc_apply4(fp.oxy_raw(irev2),fp.oxy_qc(irev2));
                        netcdf.putVar(ncid,NDOXYADID,[0,ii-1],[length(nan2fv(oc,fval)),1],nan2fv(oc,fval));
                    end
                    oqc2=get_derived_oqc(oqc,fp.oxy_calibrate(irev2));
                    netcdf.putVar(ncid,NDOXYADQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    %                     if isfield(fp,'oxyT_raw');
                    %                         if ~isempty(fp.oxyT_calibrate)
                    %                             tdc=qc_apply4(fp.oxyT_calibrate(irev2),fp.oxyT_qc(irev2));
                    %                             nc{'TEMP_DOXY_ADJUSTED'}(ii,1:nlv2) = nan2fv(tdc,fval);
                    %                         else
                    %                             tdc=qc_apply4(fp.oxyT_raw(irev2),fp.oxyT_qc(irev2));
                    %                             nc{'TEMP_DOXY_ADJUSTED'}(ii,1:nlv2) = nan2fv(tdc,fval);
                    %                         end
                    %                         nc{'TEMP_DOXY_ADJUSTED_QC'}(ii,1:nlv2) = num2str(fp.oxyT_qc(irev2),'%1d');
                    %                     end
                end
            end
            if  isfield(fp,'FLBBoxy_raw')  % dbdat.subtype==1008 - note that 1008 has
                %both primary and secondary oxygen measurements
                if ~isempty(fp.FLBBoxy_raw)
                    netcdf.putVar(ncid,NDOXYID,[0,ii-1],[length(nan2fv(fp.FLBBoxy_raw(irev2),fval)),1],nan2fv(fp.FLBBoxy_raw(irev2),fval));
                    oqc=fp.FLBBoxy_qc(irev2);
                    oqc2=get_derived_oqc(oqc,fp.FLBBoxy_raw(irev2));
                    netcdf.putVar(ncid,NDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(fp.FLBBoxy_qc);
                    netcdf.putVar(ncid,NPRODOXYQCID,ii-1,length(qcflag),qcflag);
                    %                     if adjusted   % we neither adjust nor quality control oxygen data in real-time
                    %                         %                 if ~isempty(fp.oxy_calibrate)
                    %                         %                     oc=qc_apply4(fp.oxy_calibrate(irev2),fp.oxy_qc(irev2));
                    %                     nc{'DOXY_ADJUSTED'}(ii,1:nlv2) = nan2fv(oc,fval);
                    %                 else
                    %                         oc=qc_apply4(fp.FLBBoxy_raw(irev2),oqc);
                    %                         nc{'DOXY_ADJUSTED'}(ii,1:nlv2) = nan2fv(oc,fval);
                    %                         %                 end
                    %
                    %                         nc{'DOXY_ADJUSTED_QC'}(ii,1:nlv2) = num2str(oqc2,'%1d');
                    %                     end
                    if isfield(fp,'SBEOxyfreq')     %(dbdat.subtype==1008) % intermediate
                        if ~isempty(fp.SBEOxyfreq)
                            oqc=fp.FLBBoxy_qc(irev2);
                            oqc2=get_intermediate_oqc(oqc,fp.SBEOxyfreq(irev2));
                            netcdf.putVar(ncid,NFREQDOXYID,[0,ii-1],[length(nan2fv(fp.SBEOxyfreq(irev2),fval)),1],nan2fv(fp.SBEOxyfreq(irev2),fval));
                            netcdf.putVar(ncid,NFREQDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                            qcflag = overall_qcflag(oqc2);
                            netcdf.putVar(ncid,NPROFREQDOXYQCID,ii-1,length(qcflag),qcflag);
                        end
                    end
                end
            end
            
            
            if length(fp.oxy_raw)~=length(fp.p_raw)
                qcflag = overall_qcflag(fp.oxy_qc);
                netcdf.putVar(ncid,NPRODOXYQCID,ii-1,length(qcflag),qcflag);                    
                if isfield(fp,'oxyT_raw')
                    if ~isempty(fp.oxyT_raw)
                        qcflag = overall_qcflag(fp.oxyT_qc);
                        netcdf.putVar(ncid,NPROTEMPDOXYQCID,ii-1,length(qcflag),qcflag);                             
                    end
                end
            end
            
            % now do the raw fields:
            %   floats that report DO concentration from either a Seabird IDO or Aandera Optode sensor:

            if length(fp.oxy_raw)~=length(fp.p_raw)  % these go on the primary axis...
                
                if isfield(fp,'Bphase_raw')   %(dbdat.subtype==1006 | dbdat.subtype==1020)
                    if ~isempty(fp.Bphase_raw)
                        oqc=fp.oxy_qc(irev2);
                        %                         bdc=qc_apply4(fp.Bphase_raw(irev2),fp.oxy_qc(irev2));
                        netcdf.putVar(ncid,NBPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.Bphase_raw(irev2),fval)),1],nan2fv(fp.Bphase_raw(irev2),fval));
                        oqc2=get_intermediate_oqc(oqc,fp.Bphase_raw(irev2));
                        netcdf.putVar(ncid,NBPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                        qcflag = overall_qcflag(fp.oxy_qc);
                        netcdf.putVar(ncid,NPROBPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                    end
                end
                if isfield(fp,'Tphase_raw')   %(dbdat.subtype==1006 | dbdat.subtype==1020)
                    if ~isempty(fp.Tphase_raw)
                        oqc=fp.oxy_qc(irev2);
                        %                         bdc=qc_apply4(fp.Bphase_raw(irev2),fp.oxy_qc(irev2));
                        netcdf.putVar(ncid,NTPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.Tphase_raw(irev2),fval)),1],nan2fv(fp.Tphase_raw(irev2),fval));
                        oqc2=get_intermediate_oqc(oqc,fp.Tphase_raw(irev2));
                        netcdf.putVar(ncid,NTPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                        qcflag = overall_qcflag(fp.oxy_qc);
                        netcdf.putVar(ncid,NPROTPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                    end
                    if isfield(fp,'Rphase_raw')   %(dbdat.subtype==1006 | dbdat.subtype==1020)
                        if ~isempty(fp.Rphase_raw)
                            oqc=fp.oxy_qc(irev2);
                            %                         bdc=qc_apply4(fp.Bphase_raw(irev2),fp.oxy_qc(irev2));
                            netcdf.putVar(ncid,NRPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.Rphase_raw(irev2),fval)),1],nan2fv(fp.Rphase_raw(irev2),fval));
                            oqc2=get_intermediate_oqc(oqc,fp.Rphase_raw(irev2));
                            netcdf.putVar(ncid,NRPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                            qcflag = overall_qcflag(fp.oxy_qc);
                            netcdf.putVar(ncid,NPRORPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                        end
                    end
                end
                
                
                if isfield(fp,'O2phase_raw')    %(dbdat.subtype==1017)
                    if ~isempty(fp.O2phase_raw)
                        %                         bdc=qc_apply4(fp.O2phase_raw(irev2),fp.oxy_qc(irev2));
                        netcdf.putVar(ncid,NPHASEDOXYID,[0,ii-1],[length(nan2fv(fp.O2phase_raw(irev2),fval)),1],nan2fv(fp.O2phase_raw(irev2),fval));
                        oqc2=get_intermediate_oqc(oqc,fp.O2phase_raw(irev2));
                        netcdf.putVar(ncid,NPHASEDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                        qcflag = overall_qcflag(fp.oxy_qc);
                        netcdf.putVar(ncid,NPROPHASEDOXYQCID,ii-1,length(qcflag),qcflag);
                        
                    end
                end
              
                if isfield(fp,'SBEOxyfreq')     %(dbdat.subtype==1008)
                    if ~isempty(fp.SBEOxyfreq)
                        oqc=fp.oxy_qc(irev2);
                        oqc2=get_intermediate_oqc(oqc,fp.SBEOxyfreq(irev2));
                        netcdf.putVar(ncid,NFREQDOXYID,[0,ii-1],[length(nan2fv(fp.SBEOxyfreq(irev2),fval)),1],nan2fv(fp.SBEOxyfreq(irev2),fval));
                        netcdf.putVar(ncid,NFREQDOXYQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                        qcflag = overall_qcflag(oqc2);
                        netcdf.putVar(ncid,NPROFREQDOXYQCID,ii-1,length(qcflag),qcflag);
                        
                    end
                end
            end
        end
        
        if dbdat.flbb & length(fp.CHLa_raw)~=length(fp.p_raw)
            
            oqc(1:nlv2)=fp.CHLa_qc(irev2);
            
            %             bdc=qc_apply4(fp.CHLa_raw(irev2),fp.oxy_qc(irev2));
            if ~isempty(fp.CHLa_raw) & any(~isnan(fp.CHLa_raw))
                oqc2=get_derived_oqc(oqc,fp.CHLa_raw(irev2));
                netcdf.putVar(ncid,NCHLAID,[0,ii-1],[length(nan2fv(fp.CHLa_raw(irev2),fval)),1],nan2fv(fp.CHLa_raw(irev2),fval));
                netcdf.putVar(ncid,NCHLAQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPROCHLAQCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~isempty(fp.Fsig) & any(~isnan(fp.Fsig))
                oqc2=get_intermediate_oqc(oqc,fp.Fsig(irev2));
                netcdf.putVar(ncid,NFLUOCHLAID,[0,ii-1],[length(nan2fv(fp.Fsig(irev2),fval)),1],nan2fv(fp.Fsig(irev2),fval));
                netcdf.putVar(ncid,NFLUOCHLAQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPROFLUOCHLAQCID,ii-1,length(qcflag),qcflag)
            end
            
            if ~isempty(fp.BBP700_raw) & any(~isnan(fp.BBP700_raw))
                oqc(1:nlv2)=fp.BBP700_qc(irev2);
                oqc2=get_derived_oqc(oqc,fp.BBP700_raw(irev2));
                netcdf.putVar(ncid,NBBP700ID,[0,ii-1],[length(nan2fv(fp.BBP700_raw(irev2),fval)),1],nan2fv(fp.BBP700_raw(irev2),fval));
                netcdf.putVar(ncid,NBBP700QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc2);
                netcdf.putVar(ncid,NPROBBP700QCID,ii-1,length(qcflag),qcflag);
            end
            
            if ~isempty(fp.Bbsig) & any(~isnan(fp.Bbsig))
                oqc2=get_intermediate_oqc(oqc,fp.Bbsig(irev2));
                netcdf.putVar(ncid,NBETABACK700ID,[0,ii-1],[length(nan2fv(fp.Bbsig(irev2),fval)),1],nan2fv(fp.Bbsig(irev2),fval));
                netcdf.putVar(ncid,NBETABACK700QCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));               
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROBETABACK700QCID,ii-1,length(qcflag),qcflag);               
            end
            
            if ~isempty(fp.Tsig) & any(~isnan(fp.Tsig))
                oqc2=get_intermediate_oqc(oqc,fp.Tsig(irev2));
                netcdf.putVar(ncid,NTEMPCPUCHLAID,[0,ii-1],[length(nan2fv(fp.Tsig(irev2),fval)),1],nan2fv(fp.Tsig(irev2),fval));
                netcdf.putVar(ncid,NTEMPCPUCHLAQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPROTEMPCPUCHLAQCID,ii-1,length(qcflag),qcflag);               
            end
            
            if isfield(fp,'CDOM_raw') & any(~isnan(fp.CDOM_raw))
                if ~isempty(fp.CDOM_raw)
                    oqc(1:nlv2)=fp.CDOM_qc(irev2);
                    oqc2=get_derived_oqc(oqc,fp.CDOM_raw(irev2));
                    netcdf.putVar(ncid,NCDOMID,[0,ii-1],[length(nan2fv(fp.CDOM_raw(irev2),fval)),1],nan2fv(fp.CDOM_raw(irev2),fval));
                    netcdf.putVar(ncid,NCDOMQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                     qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPROCDOMQCID,ii-1,length(qcflag),qcflag);                   
                end
                
                if ~isempty(fp.Cdsig) & any(~isnan(fp.Cdsig))
                    oqc2=get_intermediate_oqc(oqc,fp.Cdsig(irev2));
                    netcdf.putVar(ncid,NFLUOCDOMID,[0,ii-1],[length(nan2fv(fp.Cdsig(irev2),fval)),1],nan2fv(fp.Cdsig(irev2),fval));
                    netcdf.putVar(ncid,NFLUOCDOMQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                    qcflag = overall_qcflag(oqc);
                    netcdf.putVar(ncid,NPROFLUOCDOMQCID,ii-1,length(qcflag),qcflag);                     
                end
            end
        end
        
        if dbdat.suna
            oqc=[];
            if isfield(fp,'no3_raw')
                oqc(1:nlv2)=0;
                oqc2=get_derived_oqc(oqc,fp.no3_raw(irev2));
                netcdf.putVar(ncid,NNITRATEID,[0,ii-1],[length(nan2fv(fp.no3_raw(irev2),fval)),1],nan2fv(fp.no3_raw(irev2),fval));
                netcdf.putVar(ncid,NNITRATEQCID,[0,ii-1],[length(num2str(oqc2,'%1d')),1],num2str(oqc2,'%1d'));
                qcflag = overall_qcflag(oqc);
                netcdf.putVar(ncid,NPRONITRATEQCID,ii-1,length(qcflag),qcflag);
            end
        end         
            
    end

    
    % The ADJUSTED_ERROR fields can be left as initialised at FillValue

        
    for jj = 1:6
        qcdc=[ARGO_SYS_PARAM.datacentre 'QC'];
        netcdf.putVar(ncid,NHISINSTID,[0,ii-1,jj-1],[length(ARGO_SYS_PARAM.datacentre),1,1],ARGO_SYS_PARAM.datacentre);
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
    pars = []; % 2];
    if dbdat.oxy 
        if length(fp.p_raw)==length(fp.oxy_raw) & ii==1
            pars = [pars 1];
        elseif isfield(fp,'p_oxygen') & length(fp.p_raw)~=length(fp.oxy_raw) & ii==2
            pars = [pars 1];
        end        
    end
    if isfield(fp,'oxyT_raw')
        if length(fp.p_raw)==length(fp.oxy_raw) & ii==1
            pars = [pars 2];
        elseif isfield(fp,'p_oxygen')  & length(fp.p_raw)~=length(fp.oxy_raw) & ii==2
            pars = [pars 2];
        end
   end
    if dbdat.tmiss & ii==1
        pars = [pars 3];
    end
        
    if dbdat.flbb 
        if length(fp.Bbsig)==length(fp.p_raw) & ii==1
            pars = [pars 4 5];
            if isfield (fp,'CDOM_raw')
                pars=[pars 6];
            end
            
        elseif length(fp.Bbsig)~=length(fp.p_raw) & ii==2
            pars = [pars 4 5];
            if isfield (fp,'CDOM_raw')
                pars=[pars 6];
            end
        end
    end
    if dbdat.flbb2 & ii==1
        pars = [pars 7];
    end
    if dbdat.tmiss & ii==1
        pars = [pars 8];
    end
    if dbdat.eco & ii==1
        if dbdat.flbb
        pars = [pars 9 7 10];
        else
            pars = [pars 4 7 10];
        end
    end
    if dbdat.suna & ii==2
        pars = [pars 11];
    end
    if dbdat.irr & ii==1
        pars = [pars 12 13 14 15 16 17 18 19];
    end
        
    for par = pars
        vqc=[];
        switch par
            case 1
                if ii==1
                    vqc = fp.oxy_qc;
                else 
                    vqc = [];
                end
                pnam = 'DOXY';
            case 2
                vqc = fp.oxyT_qc;
                pnam = 'TEMP_DOXY';
            case 3
                vqc = fp.tm_qc;
                pnam = 'CP660';
            case 4
                vqc = [];
                pnam = 'CHLA';
            case 5
                vqc = [];
                pnam = 'BBP700';
            case 6
                vqc = [];
                pnam = 'CDOM';
            case 7
                vqc = [];
                pnam = 'BBP532';
            case 8
                vqc = [];
                pnam = 'CP660';
             case 9
                vqc = [];
                pnam = 'BBP700_2';
            case 10
                vqc = [];
                pnam = 'BBP470';
            case 11
                vqc = [];
                pnam = 'NITRATE';
            case 12
                vqc = [];
                pnam = 'DOWN_IRRADIANCE412';
            case 13
                vqc = [];
                pnam = 'DOWN_IRRADIANCE443';
            case 14
                vqc = [];
                pnam = 'DOWN_IRRADIANCE490';
            case 15
                vqc = [];
                pnam = 'DOWN_IRRADIANCE555';
            case 16
                vqc = [];
                pnam = 'UP_RADIANCE412';
            case 17
                vqc = [];
                pnam = 'UP_RADIANCE443';
            case 18
                vqc = [];
                pnam = 'UP_RADIANCE490';
            case 19
                vqc = [];
                pnam = 'UP_RADIANCE555';
        end
 

        % Find start and end of each patch of flagged data
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
[m,n]=size(pdm);
netcdf.putVar(ncid,NPARADAMOID,[0,0],[n,m],pdm');

netcdf.close(ncid)

% if exist('isingdac')==2
%     if isingdac(fname)~=2
        %         % change this back to export!!!
        [status,ww] = system(['cp -f ' fname ' ' ARGO_SYS_PARAM.root_dir 'export_hold']);
        if ispc
            [status,ww] = system(['copy /Y ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
        else
%             [status,ww] = system(['cp -f ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
        end
        if status~=0
            logerr(3,['Copy of ' fname ' to export/ failed:' ww]);
        end
%     end
% end


%----------------------------------------------------------------------------
function vo = nan2fv(vin,fval)

vo = vin;
jk = find(isnan(vin));
if ~isempty(jk) 
   vo(jk) = fval;
end

return
%----------------------------------------------------------------------------

function oqc = get_derived_oqc(qc,var_raw)  % change missing values to quality 9

oqc=qc;
kk=find(qc==0 & isnan(var_raw));
if ~isempty(kk)
    oqc(kk)=9;
end

return
%----------------------------------------------------------------------------

function oqc = get_intermediate_oqc(qc,var_raw)  % change quality for '0' values to 4

oqc=qc;

kk=find(oqc==9 & var_raw==0);
if ~isempty(kk)
    oqc(kk)=4;
end
kk=find(oqc==9 & ~isnan(var_raw));
if ~isempty(kk)
    oqc(kk)=4;
end


return
%----------------------------------------------------------------------------
