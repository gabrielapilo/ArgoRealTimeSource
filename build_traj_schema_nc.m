%function schema = build_traj_schema_nc(fname,gotcyc,params)
% Build the schema used by matlab's netcdf tools to make the trajectory NC 
% files for iridium floats.
%
% INPUTS
%
% OUTPUTS
%   schema: structure with the required dimensions, variables and Attributes    
%
% Bec Cowley, CSIRO, 11 September, 2015
%
% CALLS:  
%
% CALLED BY: trajectory_iridium_nc.m
%
% LIMITATIONS: based on v3.1 schema.
%
% USAGE: schema = build_traj_schema_nc;
% 
function schema = build_traj_schema_nc(fname,gotcyc,params)
%build the structure with all the fields and correct dimensions.
%then return the schema for population in trajectory_iridium_nc

schema.Filename = fname;
schema.Name = '/';
%____________________________________________________________________
%Dimensions:
dimfld_name = {'N_CYCLE'
    'STRING2'
    'STRING4'
    'STRING8'
    'STRING16'
    'STRING32'
    'STRING64'
    'DATE_TIME'
    'N_PARAM'
    'N_HISTORY'
    'N_MEASUREMENT'};
dimfld_val = [length(gotcyc)
    2
    4
    8
    16
    32
    64
    14
    length(params)
    1
    0];
dimfld_unlimited = [0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    1];
for a = 1:length(dimfld_name)
    schema.Dimensions(a).Name = dimfld_name{a};
    schema.Dimensions(a).Length = dimfld_val(a);
    schema.Dimensions(a).Unlimited = logical(dimfld_unlimited(a));
end
%____________________________________________________________________
%Variables
varflds_name = {'DATE_CREATION'
    'DATE_UPDATE'
    'PLATFORM_NUMBER'
    'DATA_CENTRE'
    'WMO_INST_TYPE'
    'PROJECT_NAME'
    'PI_NAME'
    'DATA_TYPE'
    'FORMAT_VERSION'
    'HANDBOOK_VERSION'
    'REFERENCE_DATE_TIME'
    'POSITIONING_SYSTEM'
    'TRAJECTORY_PARAMETERS'
    'DATA_STATE_INDICATOR'
    'PLATFORM_TYPE'
    'FLOAT_SERIAL_NO'
    'FIRMWARE_VERSION'
    'JULD'
    'JULD_STATUS'
    'JULD_QC'
    'JULD_ADJUSTED'
    'JULD_ADJUSTED_STATUS'
    'JULD_ADJUSTED_QC'
    'LATITUDE'
    'LONGITUDE'
    'POSITION_ACCURACY'
    'POSITION_QC'
    'CYCLE_NUMBER'
    'CYCLE_NUMBER_ADJUSTED'
    'MEASUREMENT_CODE'
    'PRES'
    'PRES_QC'
    'PRES_ADJUSTED'
    'PRES_ADJUSTED_QC'
    'PRES_ADJUSTED_ERROR'
    'TEMP'
    'TEMP_QC'
    'TEMP_ADJUSTED'
    'TEMP_ADJUSTED_QC'
    'TEMP_ADJUSTED_ERROR'
    'PSAL'
    'PSAL_QC'
    'PSAL_ADJUSTED'
    'PSAL_ADJUSTED_QC'
    'PSAL_ADJUSTED_ERROR'
    'AXES_ERROR_ELLIPSE_MAJOR'
    'AXES_ERROR_ELLIPSE_MINOR'
    'AXES_ERROR_ELLIPSE_ANGLE'
    'SATELLITE_NAME'
    'JULD_ASCENT_START'
    'JULD_ASCENT_START_STATUS'
    'JULD_ASCENT_END'
    'JULD_ASCENT_END_STATUS'
    'JULD_DESCENT_START'
    'JULD_DESCENT_START_STATUS'
    'JULD_DESCENT_END'
    'JULD_DESCENT_END_STATUS'
    'JULD_TRANSMISSION_START'
    'JULD_TRANSMISSION_START_STATUS'
    'JULD_FIRST_STABILIZATION'
    'JULD_FIRST_STABILIZATION_STATUS'
    'JULD_PARK_START'
    'JULD_PARK_START_STATUS'
    'JULD_PARK_END'
    'JULD_PARK_END_STATUS'
    'JULD_DEEP_PARK_START'
    'JULD_DEEP_PARK_START_STATUS'
    'JULD_DEEP_DESCENT_END'
    'JULD_DEEP_DESCENT_END_STATUS'
    'JULD_DEEP_ASCENT_START'
    'JULD_DEEP_ASCENT_START_STATUS'
    'JULD_TRANSMISSION_END'
    'JULD_TRANSMISSION_END_STATUS'
    'JULD_FIRST_MESSAGE'
    'JULD_FIRST_MESSAGE_STATUS'
    'JULD_FIRST_LOCATION'
    'JULD_FIRST_LOCATION_STATUS'
    'JULD_LAST_MESSAGE'
    'JULD_LAST_MESSAGE_STATUS'
    'JULD_LAST_LOCATION'
    'JULD_LAST_LOCATION_STATUS'
    'CLOCK_OFFSET'
    'GROUNDED'
    'REPRESENTATIVE_PARK_PRESSURE'
    'REPRESENTATIVE_PARK_PRESSURE_STATUS'
    'CONFIG_MISSION_NUMBER'
    'CYCLE_NUMBER_INDEX'
    'CYCLE_NUMBER_INDEX_ADJUSTED'
    'DATA_MODE'
    'HISTORY_INSTITUTION'
    'HISTORY_STEP'
    'HISTORY_SOFTWARE'
    'HISTORY_SOFTWARE_RELEASE'
    'HISTORY_REFERENCE'
    'HISTORY_DATE'
    'HISTORY_ACTION'
    'HISTORY_PARAMETER'
    'HISTORY_PREVIOUS_VALUE'
    'HISTORY_INDEX_DIMENSION'
    'HISTORY_START_INDEX'
    'HISTORY_STOP_INDEX'
    'HISTORY_QCTEST'};
varflds_type = {'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'double'
    'char'
    'char'
    'double'
    'char'
    'char'
    'double'
    'double'
    'char'
    'char'
    'int32'
    'int32'
    'int32'
    'single'
    'char'
    'single'
    'char'
    'single'
    'single'
    'char'
    'single'
    'char'
    'single'
    'single'
    'char'
    'single'
    'char'
    'single'
    'single'
    'single'
    'single'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'double'
    'char'
    'single'
    'char'
    'int32'
    'int32'
    'int32'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'char'
    'single'
    'char'
    'int32'
    'int32'
    'char'};
varflds_dimnames = {{'DATE_TIME'}
    {'DATE_TIME'}
    {'STRING8'}
    {'STRING2'}
    {'STRING4'}
    {'STRING64'}
    {'STRING64'}
    {'STRING16'}
    {'STRING4'}
    {'STRING4'}
    {'DATE_TIME'}
    {'STRING8'}
    {'STRING16','N_PARAM'}
    {'STRING4'}
    {'STRING32'}
    {'STRING32'}
    {'STRING32'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_MEASUREMENT'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'N_CYCLE'}
    {'STRING4','N_HISTORY'}
    {'STRING4','N_HISTORY'}
    {'STRING4','N_HISTORY'}
    {'STRING4','N_HISTORY'}
    {'STRING64','N_HISTORY'}
    {'DATE_TIME','N_HISTORY'}
    {'STRING4','N_HISTORY'}
    {'STRING16','N_HISTORY'}
    {'N_HISTORY'}
    {'N_HISTORY'}
    {'N_HISTORY'}
    {'N_HISTORY'}
    {'STRING16','N_HISTORY'}};

varflds_atts_name = {{'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'_FillValue','long_name'}
    {'long_name','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','standard_name','conventions','units','resolution','_FillValue','axis'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','standard_name','conventions','units','resolution','_FillValue','axis'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','axis'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','axis'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','C_format','FORTRAN_format','axis','resolution'}
    {'long_name','conventions','_FillValue'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','comment','C_format','FORTRAN_format','resolution'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue','units','C_format','FORTRAN_format','resolution'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','C_format','FORTRAN_format','resolution'}
    {'long_name','conventions','_FillValue'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','comment','C_format','FORTRAN_format','resolution'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue','units','C_format','FORTRAN_format','resolution'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','C_format','FORTRAN_format','resolution'}
    {'long_name','conventions','_FillValue'}
    {'long_name','standard_name','_FillValue','units','valid_min','valid_max','comment','C_format','FORTRAN_format','resolution'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue','units','C_format','FORTRAN_format','resolution'}
    {'long_name','_FillValue','units'}
    {'long_name','_FillValue','units'}
    {'long_name','units','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','standard_name','units','conventions','resolution','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','units','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','units','_FillValue'}
    {'conventions','long_name','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','conventions','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','_FillValue'}
    {'long_name','conventions','_FillValue'}};

varflds_atts_value = {{'Date of file creation','YYYYMMDDHHMISS',' '}
    {'Date of update of this file','YYYYMMDDHHMISS',' '}
    {'Float unique identifier','WMO float identifier : A9IIIII',' '}
    {'Data centre in charge of float data processing','Argo reference table 4',' '}
    {'Coded instrument type','Argo reference table 8',' '}
    {' ','Name of the project'}
    {'Name of the principal investigator',' '}
    {'Data type','Argo reference table 1',' '}
    {'File format version',' '}
    {'Data handbook version',' '}
    {'Date of reference for Julian days','YYYYMMDDHHMISS',' '}
    {'Positioning system',' '}
    {'Argo reference table 3','List of available parameters for the station',' '}
    {'Degree of processing the data have passed through','Argo reference table 6',' '}
    {'Type of float','Argo reference table 23',' '}
    {'Serial number of the float',' '}
    {'Instrument firmware version',' '}
    {'Julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME','time','Relative julian days with decimal part (as parts of day)','days since 1950-01-01 00:00:00 UTC',0.01,999999,'T'}
    {'Status of the date and time','Argo reference table 19',' '}
    {'Quality on date and time','Argo reference table 2',' '}
    {'Adjusted julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME','time','Relative julian days with decimal part (as parts of day)','days since 1950-01-01 00:00:00 UTC',0.01,999999,'T'}
    {'Status of the JULD_ADJUSTED date','Argo reference table 19',' '}
    {'Quality on adjusted date and time','Argo reference table 2',' '}
    {'Latitude of each location','latitude',99999,'degree_north',-90,90,'Y'}
    {'Longitude of each location','longitude',99999,'degree_east',-180,180,'X'}
    {'Estimated accuracy in latitude and longitude','Argo reference table 5',' '}
    {'Quality on position','Argo reference table 2',' '}
    {'Float cycle number of the measurement','0...N, 0 : launch cycle, 1 : first complete cycle',99999}
    {'Adjusted float cycle number of the measurement','0...N, 0 : launch cycle, 1 : first complete cycle',99999}
    {'Flag referring to a measurement event in the cycle','Argo reference table 15',99999}
    {'Sea water pressure, equals 0 at sea-level','sea_water_pressure',99999,'decibar',0,12000,'%7.1f','F7.1','Z',0}
    {'quality flag','Argo reference table 2',' '}
    {'Sea water pressure, equals 0 at sea-level','sea_water_pressure',99999,'decibar',0,12000,'In situ measurement, sea surface = 0','%7.1f','F7.1',0}
    {'quality flag','Argo reference table 2',' '}
    {'Contains the error on the adjusted values as determined by the delayed mode QC process',99999,'decibar','%7.1f','F7.1',0}
    {'Sea temperature in-situ ITS-90 scale','sea_water_temperature',99999,'degree_Celsius',-2.5,40,'%9.3f','F9.3',1}
    {'quality flag','Argo reference table 2',' '}
    {'Sea temperature in-situ ITS-90 scale','sea_water_temperature',99999,'degree_Celsius',-2.5,40,'In situ measurement','%9.3f','F9.3',1}
    {'quality flag','Argo reference table 2',' '}
    {'Contains the error on the adjusted values as determined by the delayed mode QC process',99999,'degree_Celsius','%9.3f','F9.3',1}
    {'Practical salinity','sea_water_salinity',99999,'psu',2,41,'%9.3f','F9.3',0.001}
    {'quality flag','Argo reference table 2',' '}
    {'Practical salinity','sea_water_salinity',99999,'psu',2,41,'In situ measurement','%9.3f','F9.3',0.001}
    {'quality flag','Argo reference table 2',' '}
    {'Contains the error on the adjusted values as determined by the delayed mode QC process',99999,'psu','%9.3f','F9.3',0.001}
    {'Major axis of error ellipse from positioning system',99999,'meters'}
    {'Minor axis of error ellipse from positioning system',99999,'meters'}
    {'Angle of error ellipse from positioning system','Degrees (from North when heading East)',99999}
    {'Satellite name from positioning system',' '}
    {'Start date of the ascent to the surface','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of start date of the ascent to the surface',' '}
    {'End date of ascent to the surface','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of end date of ascent to the surface',' '}
    {'Descent start date of the cycle','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of descent start date of the cycle',' '}
    {'Descent end date of the cycle','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of descent end date of the cycle',' '}
    {'Start date of transmission','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of start date of transmission',' '}
    {'Time when a float first becomes water-neutral','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of time when a float first becomes water-neutral',' '}
    {'Drift start date of the cycle','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of drift start date of the cycle',' '}
    {'Drift end date of the cycle','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of drift end date of the cycle',' '}
    {'Deep park start date of the cycle','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of deep park start date of the cycle',' '}
    {'Deep descent end date of the cycle','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of deep descent end date of the cycle',' '}
    {'Deep ascent start date of the cycle','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of deep ascent start date of the cycle',' '}
    {'Transmission end date','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of transmission end date',' '}
    {'Date of earliest float message received','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of date of earliest float message received',' '}
    {'Date of earliest location','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of date of earliest location',' '}
    {'Date of latest float message received','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of date of latest float message received',' '}
    {'Date of latest location','time','days since 1950-01-01 00:00:00 UTC','Relative julian days with decimal part (as parts of day)',0.01,999999}
    {'Argo reference table 19','Status of date of latest location',' '}
    {'Time of float clock drift','days','Days with decimal part (as parts of day)',999999}
    {'Did the profiler touch the ground for that cycle?','Argo reference table 20',' '}
    {'Best pressure value during park phase','decibar',99999}
    {'Argo reference table 21','Status of best pressure value during park phase',' '}
    {'Unique number denoting the missions performed by the float','1...N, 1 : first complete mission',99999}
    {'Cycle number that corresponds to the current index','0...N, 0 : launch cycle, 1 : first complete cycle',99999}
    {'Adjusted cycle number that corresponds to the current index','0...N, 0 : launch cycle, 1 : first complete cycle',99999}
    {'Delayed mode or real time data','R : real time; D : delayed mode; A : real time with adjustment',' '}
    {'Institution which performed action','Argo reference table 4',' '}
    {'Step in data processing','Argo reference table 12',' '}
    {'Name of software which performed action','Institution dependent',' '}
    {'Version/release of software which performed action','Institution dependent',' '}
    {'Reference of database','Institution dependent',' '}
    {'Date the history record was created','YYYYMMDDHHMISS',' '}
    {'Action performed on data','Argo reference table 7',' '}
    {'Station parameter action is performed on','Argo reference table 3',' '}
    {'Parameter/Flag previous value before action',99999}
    {'Name of dimension to which HISTORY_START_INDEX and HISTORY_STOP_INDEX correspond','C: N_CYCLE, M: N_MEASUREMENT',' '}
    {'Start index action applied on',99999}
    {'Stop index action applied on',99999}
    {'Documentation of tests performed, tests failed (in hex form)','Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$',' '}};

%% Now build the schema
for a = 1:length(varflds_name)
    %Name
    schema.Variables(a).Name = varflds_name{a};
    %Dimensions nested structure
    for b = 1:size(varflds_dimnames{a},2)
        ii = strmatch(varflds_dimnames{a}{b},dimfld_name);
        if isempty(ii)
            disp('Problems in build_traj_schema')
%             keyboard
        end
        schema.Variables(a).Dimensions(b).Name = varflds_dimnames{a}{b};
        schema.Variables(a).Dimensions(b).Length = dimfld_val(ii);
        schema.Variables(a).Dimensions(b).Unlimited = dimfld_unlimited(ii);
    end
    %Size
    schema.Variables(a).Size = dimfld_val(ii);
    %datatype
    schema.Variables(a).Datatype = varflds_type{a};
    %attributes nested structure:
    for b = 1:size(varflds_atts_name{a},2)
        schema.Variables(a).Attributes(b).Name = varflds_atts_name{a}{b};
        val = varflds_atts_value{a}{b};
        %check for 'double' in the fill value when it should be a different
        %type.
        if ~isempty(strmatch(varflds_atts_name{a}{b},'_FillValue'))
            s = whos('val');
            if isempty(strmatch(varflds_type{a},s.class,'exact'))
                %need to change the datatype:
                eval(['val = ' varflds_type{a} '(val);'])
            end
        end
        schema.Variables(a).Attributes(b).Value = val;
    end
    %Other bits:
    schema.Variables(a).ChunkSize = [];
    schema.Variables(a).FillValue = [];
    schema.Variables(a).DeflateLevel = [];
    schema.Variables(a).Shuffle = false;
end

%Adjust the schema for the number of parameters:
pars = {'PRES','TEMP','PSAL'}; 
parsn = [1,2,3];
if isempty(params)
    %get rid of all the parameter variables and dims:
    ii = strmatch('N_PARAM',dimfld_name);
    schema.Dimensions(ii) = [];
    for a = 1:length(pars)
        ii = strmatch(pars{a},varflds_name); %will match all 5 parameter related vars
        schema.Variables(ii) = [];
        varflds_name(ii) = [];
    end
    %get rid of trajectory_parameters variable
    ii = strmatch('TRAJECTORY_PARAMETERS',varflds_name);
    schema.Variables(ii) = [];
%only one or two parameters:
elseif length(params) < 3
    imissing = ismember(parsn,params);
    for a = 1:length(imissing)
        if imissing(a) == 1
            continue
        end
        ii = strmatch(pars{parsn(a)},varflds_name);
        schema.Variables(ii) = [];
        varflds_name(ii) = [];
    end   
end
%% add the global atts and finish
%____________________________________________________________________
% GLOBAL ATTRIBUTES
attflds = {'title'
    'institution'
    'source'
    'history'
    'references'
    'user_manual_version'
    'Conventions'
    'featureType'
    'comment_on_resolution'};
attflds_value = {'Argo float trajectory file'
    'CSIRO'
    'Argo float'
    ' '
    'http://www.argodatamgt.org/Documentation'
    '3.1'
    'Argo-3.1 CF-1.6'
    'trajectory'
    'PRES variable resolution depends on measurement codes'};

for a = 1:length(attflds)
    schema.Attributes(a).Name = attflds{a};
    schema.Attributes(a).Value = attflds_value{a};
end


%____________________________________________________________________
%Groups
schema.Groups = [];
%Format
schema.Format = 'classic';


