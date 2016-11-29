%=================================================================================
% RETURNS TECHNICAL / ENGINEERING PARAMETER NAMES AND VALUES INTO STRUCTURE ARRAY:
%      tech(j).pname  = 'voltage'
%             .pval   = [12.5, 12.6, .... ]
%             .plotIt = true or false
%             .showIt = true or false
%             .Yupper = 16.0;
%             .Ylower = 0.0;
% PROBLEMS:
%  Tech Parameter names are not the new ones, but old ones -> convert to new names
%=================================================================================
function tech = dbasequeryGetEngineeringParam(float)
%begin
    %inputs:
    tech = [];
    if (isempty(float)) return; end;
    try n=length(float); catch; return; end;
    
    %               dbase, tech , fieldname:            propername:                     sprintf showIt: plotIt  Ylower Yupper:
    %-----------------------------------------------------------------------------------------------------------------
    %general group:
    tech = getparam(float, tech, 'profile_number',      'Profile_Number',                '%3d',   true, false,    0, 500);
    tech = getdates(float, tech, 'datetime_vec',        'UplinkDate:',                   '%10s',  true, false,    0,   0);
    tech = getparam(float, tech, 'lat',                 'Latitude',                      '%8.3f', true, false,  -90,  90);
    tech = getparam(float, tech, 'lon',                 'Longitude',                     '%8.3f', true, false,    0, 360);
    
    %piston position group:
    tech = getparam(float, tech, 'pistonpos',           'Piston_Position_Surface_Counts', '%3d', true, true, 0, 260);
    tech = getparam(float, tech, 'p_end_pistonretract', 'Pressure_Endof_PistonRetract_Bar',     '%3d', true, true, 0, 160);
    tech = getparam(float, tech, 'profilepistonpos',    'Piston_Position_Profile_Counts', '%3d', true, true, 0, 160);
    tech = getparam(float, tech, 'parkpistonpos',       'Piston_Position_Park_Counts',    '%3d', true, true, 0, 160);

    %voltages group:
    tech = getparam(float, tech, 'SBEpumpvoltage',      'Voltage_SBEON_Volts',    '%4.1f',  true, true, 0, 16);
    tech = getparam(float, tech, 'parkbatteryvoltage',  'Voltage_Park_Volts',     '%4.1f',  true, true, 0, 16);
    tech = getparam(float, tech, 'voltage',             'Voltage_Profile_Volts',     '%4.1f',  true, true, 0, 16);
    tech = getparam(float, tech, 'airpumpvoltage',      'Voltage_Air_Pump_Volts', '%4.1f',  true, true, 0, 16);
    
    %current group:
    tech = getparam(float, tech, 'airpumpcurrent',      'Current_Air_Pump_mAmps',  '%4.0f', true, true, 0, 1000);
    tech = getparam(float, tech, 'SBEpumpcurrent',      'Current_SBE_Pump_mAmps',  '%4.0f', true, true, 0, 1000 );
    tech = getparam(float, tech, 'parkbatterycurrent',  'Current_Park_mAmps',      '%4.0f', true, true, 0, 1000 );
    tech = getparam(float, tech, 'batterycurrent',      'Current_Park_mAmps',      '%4.0f', true, true, 0, 1000 );
    
    %timing group+vacuum:
    tech = getparam(float, tech, 'pumpmotortime',       'Time_Pump_Motor_Seconds',   '%4.0f',  true, true, 0, 1000);
    tech = getparam(float, tech, 'airbladderpres',      'Pres_Air_Bladder_Counts',   '%3.0f',  true, true, 70, 160);
    tech = getparam(float, tech, 'p_internal',          'Pres_Internal_Vacuum_Hg',   '%5.2f',  true, true, -8,  -5);
    tech = getparam(float, tech, 'surfpres',            'Pres_Surface_Offset_dBars', '%6.1f',  true, true, -25, 25);

    %flags
    tech = getparam(float, tech, 'sfc_termination',     'Flag_Profile_Term.',      '%s',  true, false, 0, 0);
    tech = getparam(float, tech, 'grounded',            'Flag_Grounded_YN',        '%s',  true, false, 0, 0 );   
    tech = getparam(float, tech, 'SBE41status',         'Flag_SBE41_Status_16Bit', '%s',  true, false, 0, 0 );
    tech = getparam(float, tech, 'icedetection',        'Flag_Ice_Detection',      '%s',  true, false, 0, 0 );

    %ctd PRESSURE values at park:
    tech = getparam(float, tech, 'park_p',              'Pres_Park_dBars',           '%6.1f',   true, true, 0, 1200);
    tech = getparam(float, tech, 'p_park_av',           'Pres_Park_Average_dBars',   '%6.1f',   true, true, 0, 1200);
    tech = getparam(float, tech, 'p_park_std',          'Pres_Park_SDev_dBars',      '%5.2f',   true, true, 0,  200);
    tech = getparam(float, tech, 'p_at_min_t',          'Pres_atMin_Temp_dBars',     '%6.1f',   true, true, 0, 1200);
    tech = getparam(float, tech, 'p_at_max_t',          'Pres_atMax_Temp_dBars',     '%6.1f',   true, true, 0, 1200);
    tech = getparam(float, tech, 'p_min',               'Pres_Park_Min_dBars',       '%6.1f',   true, true, 0, 1200);
    tech = getparam(float, tech, 'p_max',               'Pres_Park_Max_dBars',       '%6.1f',   true, true, 0, 1200);
    
    %ctd TEMPERATURE values at park:
    tech = getparam(float, tech, 'park_t',              'Temp_Park_degC',          '%6.3f',  true, true,  -4, 6);
    tech = getparam(float, tech, 't_park_av',           'Temp_Park_Average_degC',  '%6.3f',  true, true,  -4, 6);
    tech = getparam(float, tech, 't_park_std',          'Temp_Park_SDev_degC',     '%6.3f',  true, true,  -4, 6);
    tech = getparam(float, tech, 't_min',               'Temp_Park_Min_degC',      '%6.3f',  true, true,  -4, 6);
    tech = getparam(float, tech, 't_max',               'Temp_Park_Max_degC',      '%6.3f',  true, true,  -4, 6);
    tech = getparam(float, tech, 'medianMixedLayerT',   'Temp_Median_MixedL_degC', '%6.3f',  true, true,  -4, 6);

    %general components:
    tech = getparam(float, tech, 'n_parkbuoyancy_adj',  'Number_Park_Buoyancy_Adj_Count', '%3d',  true,  true,  0, 100);
    tech = getparam(float, tech, 'nAirPumps',           'Number_AirPump_Adj_Count',       '%3d',  true,  true,  0, 100);
    tech = getparam(float, tech, 'iceEvasionBits',      'Ice_Evasion_Bits',               '%s',   false, false, 0,   0);
    tech = getparam(float, tech, 'nMixedLayerSamples',  'Number_Mixed_Layer_Samples',     '%3d',  true,  false, 0,   0);
   
    %optional:
    tech = getparam(float, tech, 'n_parkaverages',      'Number_Park_Averages_Count',      '%3d',   false, false, 0, 0);
    tech = getparam(float, tech, 'nparksamps',          'Number_Park_Samples_Count',       '%3d',   false, false, 0, 0);
    tech = getparam(float, tech, 'n_desc_p',            '',                                '%3d',   false, false, 0, 0);
    tech = getparam(float, tech, 'infimumMLTmedian',    'Temperature_Infinum_MixedL_degC', '%6.3f', false, false, 0, 0);
    tech = getparam(float, tech, 'VoltSecAirPump',      'Volt_Second_AirPumpOn',           '%5d',   false, false, 0, 0);
    tech = getparam(float, tech, 'park_s',              'Salinity_Park_PSU',               '%6.3f', false, false, 0, 0);

%end






%=================================================================
%SEARCHES RETURNS SINGLE PARAMETER VALUES IF FOUND; ADDED TO ARRAY
%=================================================================
function tech2 = getparam(float, tech1, fieldname, propername, format, showIt, plotIt, Ylower, Yupper)
%begin
    tech2 = tech1;
    try n = length(float); catch; return; end;
    if (n==0) return; end;
    if (isfield(float(1), fieldname)==0) return; end;
    
    %determine data type to allow in-between missing data fields to be padded appropriately:
    try u = getfield(float(1), fieldname); catch; return; end;
    if (isnumeric(u)) typeis='n'; end;
    if (ischar(u))    typeis='c'; end;
    
    try
        for j=1:n 
            u = getfield(float(j), fieldname);
            %handle missing single data fields:
            if (isempty(u) && (typeis=='n')) x(j)=nan;  continue; end;
            if (isempty(u) && (typeis=='c')) x(j)={''}; continue; end;
            %else save the value:
            if (typeis=='n') x(j) = u(1); end;
            if (typeis=='c') x(j) = {u};  end
        end;
        
        s.pname  = propername; %fieldname;
        s.pval   = x;
        s.showIt = showIt;
        s.plotIt = plotIt;
        s.Ylower = Ylower;
        s.Yupper = Yupper;
        s.format = format;
        m = length(tech2);
        if (m==0) tech2=s; else tech2(m+1)=s; end;       
    catch
        return;
    end
%end





%=================================================================
%SEARCHES RETURNS SINGLE PARAMETER VALUES IF FOUND; ADDED TO ARRAY
%=================================================================
function tech2 = getdates(float, tech1, fieldname, propername, format, showIt, plotIt, Ylower, Yupper)
%begin
    tech2 = tech1;
    try n = length(float); catch; return; end;
    if (n==0) return; end;
    if (isfield(float(1), fieldname)==0) return; end;

    %ADDITIONAL COMPONENTS: DATE/TIME:
    try
        for j=1:n 
            T = getfield(float(j), fieldname); 
            try str = sprintf('%02d/%02d/%04d', T(1,3), T(1,2), T(1,1)); catch;  str=' - ';  end;
            %try str = datestr(T(1,1:6)); catch; str=' - ';  end;
            %try str = str(1:11);         catch; str=' - ';  end;
            x(j) = {str};
        end;
        
        s.pname  = propername; %fieldname;
        s.pval   = x;
        s.showIt = showIt;
        s.plotIt = plotIt;
        s.Ylower = Ylower;
        s.Yupper = Yupper;
        s.format = format;
        m = length(tech2);
        if (m==0) tech2=s; else tech2(m+1)=s; end;       
    catch
        return;
    end    
    
    
%end




