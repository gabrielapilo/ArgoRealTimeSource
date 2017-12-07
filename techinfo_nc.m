% TECHINFO_NC  Create or build onto a techinfo netCDF file
%
% INPUT: dbdat - master database record for this float
%        fpp   - the float struct array
%        pnum  - [optional] index of the profiles to update (ie *index*
%                which may be different to 'profile_number')
%                It omitted, any new profiles are just added to end.
%
% Author:  Jeff Dunn CSIRO/BoM  Aug 2006
%
%  Devolved from matlabnetcdf/argostechinfoV3.m (Ann Thresher ?)
% 
% CALLS:  netCDF toolbox,  (loadfield - in this file)
%
% USAGE: techinfo_nc(dbdat,fpp,pnum)
%
%  edited May 2008 for new techinfo file formats and parameter name
%  standardization: AT
%  coded for V3.0 - AT, Sept 2013
%  use pnum == -1 if you want to recreate the file from scratch...

function techinfo_nc(dbdat,fpp,pnum)

global ARGO_SYS_PARAM

i=0;

np = length(fpp);

if nargin<3; pnum = []; end
   
fname = [ARGO_SYS_PARAM.root_dir 'netcdf/'  num2str(dbdat.wmo_id) '/' num2str(dbdat.wmo_id) '_tech.nc'] ;

%  now pattern this after the trajectory file handling - recreate if reprocessing old profile...
hist=[];
dc=[];

% if pnum==-1;new=1;end

% force this to re-create it each time:

if exist(fname,'file')    % & ~isempty(pnum)
    % --- We have an existing file, so get the critical information out
    % before you crunch it:
    try
       ncid=netcdf.open(fname,'NOWRITE');
       
       hist=netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history');
       dcvarid=netcdf.inqVarID(ncid,'DATE_CREATION');
       dc=netcdf.getVar(ncid,dcvarid);
       
       netcdf.close(ncid)
%         hist=attnc(fname,'global','history');
%         dc=getnc(fname,'DATE_CREATION');
    end
    if isempty(dc) | all(double(dc)==0)
        if ispc
            today_str=datestr(now,30);
            today_str(9)=[];
        else
            [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
        end
        %    [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
        dc=today_str(1:14);
    end

    new=1;
    varid=[];
    nold=0;
    pnum=[];

    %  note - we now create this anew each time it runs.
end


% --- No existing file - build from scratch!
ndir = [ARGO_SYS_PARAM.root_dir 'netcdf/' int2str(dbdat.wmo_id)];
if ~exist(ndir,'dir')
    [st,ww] = system(['mkdir ' ndir]);
    if st~=0
        logerr(2,['Failed creating new directory ' ndir]);
        return
    end
end

if isempty(pnum) | pnum==-1
    pnum = 1:np;
elseif length(pnum)~=np
    logerr(3,['TECHINFO_NC: WMO ' num2str(dbdat.wmo_id) ', new techinfo' ...
        ' file, but asked to add less profiles than are available']);
end

ncid=netcdf.create(fname,'CLOBBER');

netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'title','Argo float technical data file' );
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'institution',ARGO_SYS_PARAM.inst);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'source','Argo float');


% Standard dimensions
STR2=netcdf.defDim(ncid,'STRING2',2);
STR4=netcdf.defDim(ncid,'STRING4',4);
STR8=netcdf.defDim(ncid,'STRING8',8);
STR32=netcdf.defDim(ncid,'STRING32',32);
STR128=netcdf.defDim(ncid,'STRING128',128);
DaTi =netcdf.defDim(ncid,'DATE_TIME',14);

% Unlimited dimension...

NTECHPAR=netcdf.defDim(ncid,'N_TECH_PARAM',netcdf.getConstant('NC_UNLIMITED'));

% Define the fields common to several filetypes
% note - this is no longer a function:
%     typ=4;
%     stage=1;
%     generic_fields_nc(nc,dbdat,4,1);

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

TECHNID=netcdf.defVar(ncid,'TECHNICAL_PARAMETER_NAME','NC_CHAR',[STR128,NTECHPAR]);
netcdf.putAtt(ncid,TECHNID,'long_name','Name of technical parameter');
netcdf.putAtt(ncid,TECHNID,'_FillValue',' ');

TECHVID=netcdf.defVar(ncid,'TECHNICAL_PARAMETER_VALUE','NC_CHAR',[STR128,NTECHPAR]);
netcdf.putAtt(ncid,TECHVID,'long_name','Value of technical parameter');
netcdf.putAtt(ncid,TECHVID,'_FillValue',' ');

CYCNOID=netcdf.defVar(ncid,'CYCLE_NUMBER','NC_INT',NTECHPAR);
netcdf.putAtt(ncid,CYCNOID,'long_name','Float cycle number');
netcdf.putAtt(ncid,CYCNOID,'conventions','0...N, 0 : launch cycle (if exists), 1 : first complete cycle');
netcdf.putAtt(ncid,CYCNOID,'_FillValue',int32(99999));

% Now enter data mode and load variables

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

netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'history',dnt);
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'references','http://www.argodatamgt.org/Documentation');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'comment','');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'user_manual_version','3.1');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'Conventions','Argo-3.1 CF-1.6');
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'featureType','trajectoryProfile');

%%%%%%%%%%%%%%%%%%%%%%%%

netcdf.endDef(ncid);

aa = num2str(dbdat.wmo_id);
netcdf.putVar(ncid,NPLANUID,0,length(aa),aa);

% Now enter data mode and load variables

% Fill the fields common to several filetypes
    
netcdf.putVar(ncid,NDATYID,0,length('Argo technical data'),'Argo technical data');
netcdf.putVar(ncid,NFMVRID,0,length('3.1'),'3.1');
netcdf.putVar(ncid,NHDVRID,0,length(' 1.2'),' 1.2');   
    
i=0;

if ispc
    today_str=datestr(now,30);
    today_str(9)=[];
else
    [st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
end

today_str=today_str(1:14);
if isempty(dc) | all(double(dc)==0) | all(double(dc)==32)
    dc=today_str(1:14);
end

netcdf.putVar(ncid,NDACRID,0,length(dc),dc);
netcdf.putVar(ncid,NDAUPID,0,length(today_str(1:14)),today_str(1:14));
netcdf.putVar(ncid,NDACENID,0,length(ARGO_SYS_PARAM.datacentre),ARGO_SYS_PARAM.datacentre);

% try 
%     if ~new
%         varid=netcdf.inqVarID(ncid,'TECHNIDAL_PARAMETER_VARIABLE')
%         tv=netcdf.getVar(ncid,varid);
%         varid=netcdf.inqVarID(ncid,'TECHNIDAL_PARAMETER_NAME')
%         tn=netcdf.getVar(ncid,varid2);
%         [m,n]=size(tv);
%         n_tech_F=m-1;
%     else

tn(1,1:128)=' ';
tv(1,1:128)=' ';
n_tech_F = 0;

%     end
% catch
%     n_tech_F = 0;
% end

for jj = pnum(:)'
    
    if dbdat.subtype~=3 & dbdat.subtype~=5
       i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryInitialAtProfileDepth_volts',fpp(jj).voltage);
        
        try
            i=i+1;
            [tn,tv]=loadfield(nc,n_tech_F+i,'PRESSURE_InternalVacuum_inHg',fpp(jj).p_internal(end));
        catch
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRESSURE_InternalVacuum_inHg',fpp(jj).p_internal);
        end
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'FLAG_ProfileTermination_hex',fpp(jj).sfc_termination);
        
        if dbdat.subtype==0
            surfp=fpp(jj).surfpres+5.;
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRES_SurfaceOffsetTruncatedPlus5dbar_dbar',surfp);
        end
    
    end
        
    if (dbdat.maker==1 | dbdat.maker==4) && dbdat.subtype>0
        
        if dbdat.subtype>1000
            if dbdat.subtype==1023
                surfp=fpp(jj).surfpres_used;
            else
                surfp=fpp(jj).surfpres;
            end
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRES_SurfaceOffsetNotTruncated_dbar',surfp);
        else
            surfp=fpp(jj).surfpres+5.;
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRES_SurfaceOffsetTruncatedPlus5dbar_dbar',surfp);
        end

        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'POSITION_PistonSurface_COUNT',fpp(jj).pistonpos);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'TIME_PumpMotor_seconds',fpp(jj).pumpmotortime);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CURRENT_BatteryInitialAtProfileDepth_mA',fpp(jj).batterycurrent);
        
        if dbdat.subtype<=2 | dbdat.subtype==10
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CURRENT_BatteryAirPumpOn_mA',fpp(jj).airpumpcurrent);
            %	 [tn,tv]=loadfield(nc,km(11),'POSITION_PistonSurface_COUNT',...
            %		   fpp(jj).surfacepistonpos);
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'POSITION_PistonProfile_COUNT',...
                fpp(jj).bottompistonpos);
            i=i+1;
            try
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatterySurfaceNoLoad_volts',...
                fpp(jj).surfacebatteryvolt);
            i=i+1;
            end
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryProfileNoLoad_volts',...
                fpp(jj).bottombatteryvolt);
        else
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'POSITION_PistonProfile_COUNT',...
                fpp(jj).profilepistonpos);
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'POSITION_PistonPark_COUNT',...
                fpp(jj).parkpistonpos);
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryParkNoLoad_volts',...
                fpp(jj).parkbatteryvoltage);
            if dbdat.subtype~=4
                i=i+1;
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CURRENT_BatteryPark_mA',...
                    fpp(jj).parkbatterycurrent);
                i=i+1;
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatterySBEAscent_volts',...
                    fpp(jj).SBEpumpvoltage);
            else
                i=i+1;
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'POSITION_PistonSurface_COUNT',...
                    fpp(jj).surfacepistonpos);
                i=i+1;
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatterySurfaceNoLoad_volts',...
                    fpp(jj).surfacebatteryvolt);
            end
        end
        
        i=i+1;
        try
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRESSURE_AirBladder_COUNT',...
                fpp(jj).airbladderpres(end));
        catch
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRESSURE_AirBladder_COUNT',...
                fpp(jj).airbladderpres);
        end
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CURRENT_BatterySBEPump_mA',fpp(jj).SBEpumpcurrent);
        
        if dbdat.ice
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'FLAG_IceDetected_COUNT',fpp(jj).icedetection);
        end
        
        if dbdat.iridium  %iridium floats
            
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'FLAG_CTDStatus_NUMBER',fpp(jj).SBE41status);
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatterySurfaceAirPumpOn_volts',fpp(jj).airpumpvoltage);
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_RepositionsDuringPark_COUNT',fpp(jj).n_parkbuoyancy_adj);
            i=i+1;
            [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_ParkSamples_COUNT',fpp(jj).n_parkaverages);
            i=i+1;
            try
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'TIME_IridiumGPSFix_seconds',fpp(jj).GPSfixtime);
            catch
                i=i-1;
            end
            i=i+1;
            try
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_GPSSatellites_COUNT',fpp(jj).GPSsatellites);
            catch
                i=i-1;
            end
            try
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CURRENT_BatteryPistonPumpOn_mA',fpp(jj).buoyancypumpcurrent);
                i=i+1;
            catch
                i=i-1;
            end
            try
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryPistonPumpOn_volts',fpp(jj).buoyancypumpvoltage);
            catch
                i=i-1;
            end
            i=i+1;
            try
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'POSITION_PistonMax_COUNT',fpp(jj).maxpistonpos);
            catch
                i=i-1;
            end
            i=i+1;
            try
                [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_RealTimeDrift_seconds',fpp(jj).RTCskew);
            catch
                i=i-1;
            end
            
        end
        
    elseif dbdat.maker==2
        %Provor floats
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_StartDescentToPark_hours',fpp(jj).desc_sttime);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_ValveActionsAtSurfaceDuringDescent_COUNT',...
            fpp(jj).n_valve_acts_surf);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_InitialStabilizationDuringDescentToPark_hours',...
            fpp(jj).first_stab_time);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_ValveActionsDuringDescentToPark_COUNT',...
            fpp(jj).n_valve_acts_desc);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_PumpActionsDuringDescentToPark_COUNT',...
            fpp(jj).n_pump_acts_desc);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_EndDescentToPark_hours',fpp(jj).desc_endtime);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_RepositionsDuringPark_COUNT',fpp(jj).n_repositions);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_PumpActionsDuringAscentToSurface_COUNT',...
            fpp(jj).n_pump_acts_asc);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_EndAscentToSurface_hours',...
            fpp(jj).resurf_endtime);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_PumpActionsAtSurface_COUNT',...
            fpp(jj).n_pump_acts_surf);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_FloatTime_hours',fpp(jj).float_time_hour);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_FloatTime_minutes',fpp(jj).float_time_min);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_FloatTime_seconds',fpp(jj).float_time_sec);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRES_SurfaceOffsetNotTruncated_dbar',fpp(jj).pres_offset);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRESSURE_InternalVacuum_inHg',fpp(jj).internal_vacuum);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_AscentArgosMessages_COUNT',...
            fpp(jj).n_asc_blks);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_AscentSamples_COUNT',...
            fpp(jj).n_asc_samps);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_ParkArgosMessages_COUNT',...
            fpp(jj).n_drift_blks);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_ParkSamples_COUNT',...
            fpp(jj).n_drift_samps);
        
    if isfield(fpp,'date_1st_driftsamp')
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_DateFirstParkSample_YYYYMMDDHHMMSS',...
            fpp(jj).date_1st_driftsamp);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'CLOCK_TimeFirstParkSample_hours',...
            fpp(jj).time_1st_driftsamp);
    end
    if isfield(fpp,'sevenV_batvolt')
    i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_Battery7V_volts',...
            fpp(jj).sevenV_batvolt);
    end
    if isfield(fpp,'fourteenV_batvolt')
       i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_Battery14V_volts',...
            fpp(jj).fourteenV_batvolt);
    end
        %SAME AS CYCLE NUMBER...
        %      [tn,tv]=loadfield(nc,jj,30,'ASCENT_PROFILE_NUMBER',fpp(jj).asc_prof_num);
        
    elseif dbdat.maker==3 | dbdat.subtype==5
        %Solo floats
        surfp=fpp(jj).surfpres;
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRES_SurfaceOffsetBeforeReset_1cBarResolution_dbar',surfp);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'FLAG_SystemAtDepth_hex',fpp(jj).syst_flags_depth);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'FLAG_SystemAtSurface_hex',fpp(jj).syst_flags_surface);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRESSURE_InternalVacuumDuringPark_PercentAtm',fpp(jj).p_internal);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRESSURE_InternalVacuumAtSurface_PercentAtm',fpp(jj).p_internal_surface);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryCPUSurface_volts',fpp(jj).CPUpumpSURFACEvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryCPUDepth_volts',fpp(jj).CPUpumpvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryPumpAscentEnd_volts',fpp(jj).SBEpumpSURFACEvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryPumpStartProfile_volts',fpp(jj).SBEpumpvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_PumpActionsDuringPark_COUNT',fpp(jj).driftpump_adj);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryPumpOn_volts',fpp(jj).SBEpumpvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'TIME_PumpActionsInOutAtSurface_COUNT',fpp(jj).pumpin_outatsurface);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'TIME_PumpActionsInOutAtDepth_COUNT',fpp(jj).pumpin_outatdepth);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_GPSResets_COUNT',fpp(jj).GPScounter);
        
    elseif dbdat.maker==5
        %Solo II (S2A) floats
        surfp=fpp(jj).surfpres;
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRES_SurfaceOffsetBeforeReset_1cBarResolution_dbar',surfp);
        
%         i=i+1;
%         loadfield(nc,n_tech_F+i,'FLAG_SystemAtDepth_hex',fpp(jj).syst_flags_depth);
%         
%         i=i+1;
%         loadfield(nc,n_tech_F+i,'FLAG_SystemAtSurface_hex',fpp(jj).syst_flags_surface);
%         
%         i=i+1;
%         loadfield(nc,n_tech_F+i,'PRESSURE_InternalVacuumDuringPark_PercentAtm',fpp(jj).p_internal);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'PRESSURE_InternalVacuumAtSurface_PercentAtm',fpp(jj).p_internal_surface);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryCPUSurface_volts',fpp(jj).CPUpumpSURFACEvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryCPUDepth_volts',fpp(jj).CPUpumpvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryPumpOnSurface_volts',fpp(jj).SBEpumpSURFACEvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryPumpStartProfile_volts',fpp(jj).SBEpumpvoltage);
        
%         i=i+1;
%         loadfield(nc,n_tech_F+i,'NUMBER_PumpActionsDuringPark_COUNT',fpp(jj).driftpump_adj);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_BatteryPumpOn_volts',fpp(jj).SBEpumpvoltage);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'TIME_PumpActionsInOutAtSurface_COUNT',fpp(jj).pumpin_outatsurface);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'TIME_PumpActionsInOutAtDepth_COUNT',fpp(jj).pumpin_outatdepth);
        
        i=i+1;
        [tn,tv]=loadfield(tn,tv,n_tech_F+i,'NUMBER_GPSResets_COUNT',fpp(jj).GPScounter);
        
    end
    if isfield(fpp,'fourteenV_batvolt')
     i=i+1;
     [tn,tv]=loadfield(tn,tv,n_tech_F+i,'VOLTAGE_Battery14V_volts',...
		fpp(jj).fourteenV_batvolt);
    end
    
    %   km=km(end)+(1:N_TECH_P);
    if(~isempty(fpp(jj).profile_number))
        pn=[];
        pn(1:i)=fpp(jj).profile_number;
%         nc{'CYCLE_NUMBER'}(n_tech_F+1:n_tech_F+i)= fpp(jj).profile_number;
        netcdf.putVar(ncid,CYCNOID,n_tech_F,i,pn); %???????????????????????n_tech_F+1:n_tech_F+i
        
    end
    n_tech_F=n_tech_F+i;
    i=0;
    
end

netcdf.putVar(ncid,TECHVID,[0,0],[128,n_tech_F],tv')
netcdf.putVar(ncid,TECHNID,[0,0],[128,n_tech_F],tn')

netcdf.close(ncid)

if ~strcmp('hold',dbdat.status) & ~strcmp('evil',dbdat.status)
    if ispc
        [status,ww] = system(['copy /Y ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
    else
        [status,ww] = system(['cp -f ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
    end
end

return

%----------------------------------------------------------------------------

function [tn,tv]=loadfield(tn,tv,kk,afnam,val)

if(length(afnam)>128)
    ll=128;
else
    ll=length(afnam);
end
blankstr(1:128)=' ';
blankstr(1:ll)=afnam(1:ll);
tn(kk,1:128)=blankstr;

aa = num2str(val);
if isempty(aa)
    clear blankstr
    blankstr(1:128)=' ';
    tv(kk,1:128)=blankstr;
elseif length(aa) > 128
    %cut down on the blanks
    aa = num2str(val,'%6.4f ');
    clear blankstr
    blankstr(1:128)=' ';
    if length(aa) > 128
        aa = aa(1:126); %truncate the last part-number
    end
    blankstr(1:length(aa))=aa;
    tv(kk,1:128)=blankstr;    
else
    clear blankstr
    blankstr(1:128)=' ';
    blankstr(1:length(aa))=aa;
    tv(kk,1:128)=blankstr;
end

return

