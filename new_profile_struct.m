% NEW_PROFILE_STRUCT   Create a blank standard raw Argo profile structure
%
%          THIS is also the DEFINITION of the structure
%
%   An exact match should be maintained between the USE of the variables
%   and their DESCRIPTIONS below.
%
% INPUT   dbdat - Argo database record for one float
%
% OUTPUT  fp    - single profile struct (formatted according to the make of
%                 float, and with WMO ID set, most vars empty or set to 
%                 an initial state.
%
% Called by:   message decoding routines, prior to decoding a profile message
%
%  Jeff Dunn  CSIRO/BoM  Aug-Oct 2006
%
% USAGE: fp = new_profile_struct(dbdat);
% From dbdat we obtain:
% np0 - correction to float number due to "profiles" counted after
%       deployment but while still in the cardboard box
% subtype - Webb format number
% oxy     - does it have oxygen?
% ice     - does it have ice detection?
% tmiss   - does it have transmissiometer?

% subtypes are presently: 
%  pre-Apex   = 0
%  Apex1      = 1
%  Apex early Korea = 2
%  Apex Indian = 4
%  Apex Korea = 10
%  Apex2      = 11
%  Apex2ice Korea = 20
%  Apex2 SBE DO Korea = 22
%  Apex2ice   = 28   
%  Apex2oxyice= 31   
%  Apex2oxy   = 32   
%  Apex2oxyTmiss = 35
%  Apex2SBEoxy Indian = 38
%  ApexOptode Korea = 40
%  Apex2var Park T,P = 43
%  Apex2var Park T,P + ice detection = 44
%  ApexAPF9a   = 1001
%  ApexAPF9aOptode = 1002
%  ApexAPF9aIce = 1003
%  ApexIridium = 1004 - with and without ice (decode_iridium)
%  ApexSurfaceT Indian = 1005
%  ApexIridiumO2 = 1006  (decode_iridium) with and without flbb sensor
%  ApexIridiumSBEOxy = 1007  (decode_iridium)
%  ApexIridiumSBEOxy = 1008 - with flbb
%  ApexAPF9Indian = 1010
%  ApexAPF9 with an extra point = 1011
%  ApexAPF9 format (oxygen, 1002) with extra point = 1012
%  ApexAPF9 with engineering data at end of data = 1014
%  Solo Polynya floats = 1015
%  Seabird Navis Vanilla float = 1016
%  Seabird Navis Optical Oxygen = 1017
%  MRV Solo II Vanilla = 1018
%  Webb APF11 = 1019
%  ApexAPF9OxyFLBB (no CDOM, Anderaa optode) = 1020
%  Webb APF9G Indian float = 1021 
%  Webb APF9i Indian float = 1022 With Optode 4330 & FLBB sensors 
%  Webb ApexAPF11 latest firmware = 1023
%  Seabird Navis BGCI floats (Nick H-M) = 1026 with C-Rover TMISS, flbb2 and
%  eco-puck 3 bb sensors and O2T reported in volts
%  Seabird Navis BGCI floats (Nick H-M) = 1027 with flbb2 and suna sensors and O2T reported in volts
%  Seabird Navis BGCI floats (Nick H-M) = 1028 with flbb2 and O2T reported in volts
%  Seabird Navis Optical Oxygen  with flbb2, irradiance with PAR, pH and O2T reported in volts = 1029
%  Apex Suna (early model) Oxygen with Nitrates only - Peter Thompson float = 1030
%  
%

function fp = new_profile_struct(dbdat)


% Processing system fields
fp.proc_stage = 0;
fp.TL_cal_done = 0;
fp.proc_status = [0 0];
fp.fbm_report = zeros(1,8,'uint8');       % See find_best_msg.m
fp.stage_ecnt = zeros(2,5,'uint8');      % See process_profile.m
fp.stage_jday = [0; 0];              % Local dates of 1st & 2nd stage processing
fp.ftp_download_jday = [0; 0];       % UTC julian time of ftp download (stage 1&2)
fp.stg1_desc = '';                   % stage 1 description
fp.stg2_desc = '';                   % stage 2 description
fp.cal_report = zeros(1,6);          % See calsal.m
fp.rework = 0;                       % Can be set if want already processed
% profile to be reworked next run.

% Generic float data fields
fp.wmo_id = dbdat.wmo_id;
fp.maker = dbdat.maker;
fp.subtype = dbdat.subtype;     % Data format number (for Webb floats)
                                % NOTE:  APF9 floats don't have a formal
                                % subtype - have assigned 1001 to the first
                                % of these - vanilla.  Increment as required...
                                % 1002 is APF9a-optode

fp.jday_ascent_end = [];    % Predicted time of surfacing, this profile 
fp.grounded = 'U';

%DEV Resolve whether lon is 0-360 or -180 to 180!

% Transmission fix info - one matrix row per fix. If not received in 
% chronological order then order is corrected in PROCESS_PROFILE.
%
% A profile will NOT be saved to file if jday is empty - no point in having
% a record if it has no information and we don't even know which profile it
% is meant to be. [Scanned all old files and never found a case with empty
% jday but useful profile data!]
fp.jday = [];               % julian day of all transmitted messages.
fp.datetime_vec = [];       % [yr mon day hr min sec]  ^     ^      ^
fp.lat = [];                % lat of all transmitted messages 
fp.lon = [];                % lon    ^       ^        ^
fp.position_accuracy = [];  % Argos accuracy code   ^     ^   (char)


fp.SN = [];
fp.profile_number = [];
fp.npoints = [];           % Number of obs in this profile

fp.voltage = [];
fp.p_internal = [];
fp.sfc_termination = [];

fp.surfpres = [];            % Formerly psfc (but now includes any decoding 
                             % corrections, eg Webb +5 correction)
fp.surfpres_used = [];       % Value actually used to calibrate P (may differ
                             % from .surfpres if that judged to be bad.)
fp.surfpres_qc = [];         % QC code, 0=good, see calibrate_p.m
			     
			     
fp.testsperformed = zeros(1,19,'uint8');     % QC info
fp.testsfailed = zeros(1,19,'uint8');        % QC info

% --- Profile data - size [npoints 1] (except _qc which are [1 npoints])

%DEV Undecided whether to use these variables, which are largely redundant
% because of the '_raw' and '_calibrate' variables. Most likely use is
% to have QC'ed variables to use instead of using qc_apply, but is that
% worth the storage and the possibility for mix-ups (such as if modified
% s_qc variable without rebuilding s.) Also must be clear whether this is
% a qc'ed version of _raw or _calibrate - the latter may be more useful and
% could arguably be called s_best or s_adjusted instead.

% fp.s = [];              % QC-ed  S
% fp.t = [];              % QC-ed  T
% fp.p = [];              % QC-ed  P
% fp.cndc = [];           % QC-ed  conductivity

fp.s_raw = [];              % Exactly as decoded from transmission - no QC
fp.t_raw = [];              % Exactly as decoded from transmission - no QC
fp.p_raw = [];              % Exactly as decoded from transmission - no QC
fp.cndc_raw = [];           % as computed from s_raw, t_raw and p_raw

% Note: qc variables end up as strings of characters '0' to '9'. We keep them
%   as numbers for now (for ease of testing), but use row vectors so that
%   num2str produces a horizontal string.
% Note: at this stage, QC only done once, so not required to have separate QC
%   variables for '_raw' and '_calibrate' data. 

fp.s_qc = uint16([]);           % Decimal QC flags for each value
fp.t_qc = uint16([]);           %             ^
fp.p_qc = uint16([]);           %             ^
fp.cndc_qc = uint16([]);        %             ^

fp.s_qc_status = '';    % Summary QC assessment of profile ('A' to 'F')
fp.t_qc_status = '';    %                ^
fp.p_qc_status = '';    %                ^
fp.cndc_qc_status = ''; %                ^

% These variables contain all values found in the '_raw' vectors, whether or
% not they have been flagged in QC tests.
% NOTE:
%   Since s is calibrated the whole profile is regarded as Adjusted rather 
% than Raw, hence the user may try to use values from t_calibrate. We fill 
% t_calibrate with t_raw values for their ease. JRD disapproves of this!

fp.p_calibrate = [];    % surface-offset corrected P
fp.s_calibrate = [];    % calibrated S
fp.t_calibrate = [];    % calibrated T
fp.cndc_calibrate = []; % calibrated conductivity

fp.c_ratio_calc = [];   % calculated calibration ratio
fp.c_ratio = [];        % calibration ratio actually used
fp.deltaS = [];
fp.calibrate_ref = [];

% Float type specific fields
if dbdat.oxy
    fp.oxy_raw = [];
    fp.oxy_calibrate = [];
    fp.oxy_qc = uint16([]);
    fp.oxy_qc_status = '';
    if dbdat.subtype ~= 40 & dbdat.subtype~=1008 & dbdat.subtype~=1007 
        fp.oxyT_raw = [];
        fp.oxyT_calibrate = [];
        fp.oxyT_qc = uint16([]);
        fp.oxyT_qc_status = '';
    end
    fp.parkO2 =[];
    if dbdat.subtype ~= 40 & dbdat.subtype ~= 1017 & dbdat.subtype~=1008
        fp.parkToptode = [];
    end
    if dbdat.subtype==1002 | dbdat.subtype==1006 | dbdat.subtype==1012 | ...
            dbdat.subtype==1020
        fp.park_Bphase = [];
    elseif  dbdat.subtype==1022 | dbdat.subtype == 1030 % added by uday and extended by AT
        fp.park_Tphase = [];
        fp.park_Rphase = [];
    elseif dbdat.subtype==1007 | dbdat.subtype==1008 | dbdat.subtype==22
        fp.park_SBEOxyfreq = [];
    end
    if dbdat.subtype==38
        fp.oxy_freq = [];
    end
    if dbdat.subtype==40
        fp.oxy_8hr = [];
        fp.oxy_park_av = [];
    end
    if dbdat.subtype==22
        fp.SBEoxyfreq_8hr = [];
        fp.SBEoxyfreq_park_av = [];
        fp.oxy_8hr = [];
        fp.oxy_park_av = [];
    end
    
end

if dbdat.tmiss
    fp.tm_counts = [];
    fp.tm_qc = uint16([]);
    fp.tm_qc_status = '';
    fp.currentpistonpos = [];
    fp.parkTmcounts = [];
    fp.CP_raw =     [];
    fp.parkCP_raw =   [];
    fp.CP_qc =     uint16([]);
    fp.parkCP_qc =   uint16([]);
    if dbdat.subtype==1026
        fp.parkBeamC  = [];
        fp.BeamC = [];
    end
end

if dbdat.flbb
    fp.CHLa_raw = [];
    fp.BBP700_raw = [];
    fp.CHLa_qc = uint16([]);
    fp.BBP700_qc = uint16([]);
    fp.Fsig = [];
    fp.Bbsig = [];
    fp.Tsig = [];
    if dbdat.subtype~=1020  & dbdat.maker~=4
        fp.SBEOxyfreq = [];
    end
    fp.parkCHLa_qc = uint16([]); %=== added by uday ====
    fp.parkBBP700_qc = uint16([]); %=== added by uday ====
    fp.parkCHLa = []; %=== added by uday ====
    fp.parkBBP700 = []; %=== added by uday ====
    fp.parkFsig = [];
    fp.parkBbsig = [];
    if dbdat.maker~=4 
        fp.parkTsig = [];
    end
    if dbdat.subtype==1006 | dbdat.subtype==1026  %floats with CDOM sensor
        fp.Cdsig = [];
        fp.parkCdsig = [];
        fp.CDOM_raw = [];
        fp.parkCDOM = [];
        fp.CDOM_qc = uint16([]);
        fp.parkCDOM_qc = uint16([]);
    end
end

if dbdat.irr & ~dbdat.irr2
   fp.irr412      =[];
   fp.irr443      =[];
   fp.irr490      =[];
   fp.irr555      =[];
   fp.rad412      =[];
   fp.rad443      =[];
   fp.rad490      =[];
   fp.rad555      =[];
   fp.park_irr412      =[];
   fp.park_irr443      =[];
   fp.park_irr490      =[];
   fp.park_irr555      =[];
   fp.park_rad412      =[];
   fp.park_rad443      =[];
   fp.park_rad490      =[];
   fp.park_rad555      =[];
   fp.dn_irr412_raw      =[];
   fp.dn_irr443_raw      =[];
   fp.dn_irr490_raw      =[];
   fp.dn_irr555_raw      =[];
   fp.up_rad412_raw      =[];
   fp.up_rad443_raw      =[];
   fp.up_rad490_raw      =[];
   fp.up_rad555_raw      =[];
   fp.park_dn_irr412_raw      =[];
   fp.park_dn_irr443_raw      =[];
   fp.park_dn_irr490_raw      =[];
   fp.park_dn_irr555_raw     =[];
   fp.park_up_rad412_raw      =[];
   fp.park_up_rad443_raw      =[];
   fp.park_up_rad490_raw      =[];
   fp.park_up_rad555_raw      =[];
   fp.dn_irr412_raw_qc       = uint16([]);
   fp.dn_irr443_raw_qc       = uint16([]);
   fp.dn_irr490_raw_qc       = uint16([]);
   fp.dn_irr555_raw_qc       = uint16([]);
   fp.up_rad412_raw_qc       = uint16([]);
   fp.up_rad443_raw_qc       = uint16([]);
   fp.up_rad490_raw_qc       = uint16([]);
   fp.up_rad555_raw_qc       = uint16([]);
   fp.park_dn_irr412_raw_qc      = uint16([]);
   fp.park_dn_irr443_raw_qc      = uint16([]);
   fp.park_dn_irr490_raw_qc      = uint16([]);
   fp.park_dn_irr555_raw_qc      = uint16([]);
   fp.park_up_rad412_raw_qc      = uint16([]);
   fp.park_up_rad443_raw_qc      = uint16([]);
   fp.park_up_rad490_raw_qc      = uint16([]);
   fp.park_up_rad555_raw_qc      = uint16([]);
end

if dbdat.irr2
   fp.irr380      =[];
   fp.irr412      =[];
   fp.irr490      =[];
   fp.irrPAR      =[];
   fp.park_irr380      =[];
   fp.park_irr412      =[];
   fp.park_irr490      =[];
   fp.park_irrPAR      =[];
   fp.dn_irr380_raw      =[];
   fp.dn_irr412_raw      =[];
   fp.dn_irr490_raw      =[];
   fp.dn_irrPAR_raw      =[];
   fp.dn_irr380_raw_qc       = uint16([]);
   fp.dn_irr412_raw_qc       = uint16([]);
   fp.dn_irr490_raw_qc       = uint16([]);
   fp.dn_irrPAR_raw_qc       = uint16([]);
   fp.park_dn_irr380_raw_qc      = uint16([]);
   fp.park_dn_irr412_raw_qc      = uint16([]);
   fp.park_dn_irr490_raw_qc      = uint16([]);
   fp.park_dn_irrPAR_raw_qc      = uint16([]);
end
if dbdat.eco
    fp.ecoBbsig700         =[]; %backscatters from the eco sensor - counts
    fp.ecoBbsig532         =[];
    fp.ecoBbsig470         =[];
    fp.park_ecoBbsig700         =[]; %backscatters from the eco sensor - counts
    fp.park_ecoBbsig532         =[];
    fp.park_ecoBbsig470         =[];
    fp.ecoBBP700_raw         =[]; %backscatters derived from the eco sensor
    fp.ecoBBP532_raw         =[];
    fp.ecoBBP470_raw         =[];
    fp.park_ecoBBP700_raw         =[]; %backscatters derived from the eco sensor
    fp.park_ecoBBP532_raw         =[];
    fp.park_ecoBBP470_raw         =[];
    fp.ecoBBP700_raw_qc         = uint16([]); 
    fp.ecoBBP532_raw_qc         = uint16([]);
    fp.ecoBBP470_raw_qc         = uint16([]);
    fp.park_ecoBBP700_raw_qc        =  uint16([]);
    fp.park_ecoBBP532_raw_qc        = uint16([]);
    fp.park_ecoBBP470_raw_qc        =  uint16([]);
end
    
    
    
if dbdat.em
    fp.velmatdir = [];
    fp.vel_name = [];
    fp.EmaProcessNvals = [];
    fp.HDOP = [];
    fp.emLAT = [];
    fp.emLON = [];
    fp.MLT_GPS = [];
    fp.MLT_ref = [];
    fp.NSAT = [];
    fp.P_ef_raw = [];
    fp.RotP = [];
    fp.STAT = [];
    fp.U1 = [];
    fp.U2 = [];
    fp.V1 = [];
    fp.V2 = [];
    fp.V1woW = [];
    fp.V2woW = [];
    fp.Verr1 = [];
    fp.Verr2 = [];
    fp.Wef = [];
    fp.alpha1 = [];
    fp.alpha2 = [];
    fp.ctd_mlt = [];
    fp.e1mean = [];
    fp.e1sdev = [];
    fp.e2mean = [];
    fp.e2sdev = [];
    fp.efp_mlt = [];
    fp.esep = [];
    fp.fh = [];
    fp.fz = [];
    fp.hpid = [];
    fp.magvar = [];
    fp.mlt_surface = [];
    fp.sfv1 = [];
    fp.sfv2 = [];
    fp.sfw = [];
    fp.theta = [];
    fp.scars = [];
    fp.tcars = [];
    fp.dht = [];
    fp.pt200 = [];
    fp.s200 = [];
    fp.sgem = [];
    fp.tgem = [];
    fp.activeballastadj = [];
    fp.buoyancypump_current = [];
    fp.descent_start_time = [];
    fp.DescentProfIsDone = [];
    fp.DoGpsAfter = [];
    fp.FastProfilingFlag = [];
    fp.Level2Flag = [];
    fp.LowerPressure = [];
    fp.MissionCrcBadCount = [];
    fp.MissionUpdateGotFile = [];
    fp.ParkDescentP = [];
    fp.ParkDescentPCnt  = [];
    fp.ParkObsDate = [];
    fp.ProfilingFlag = [];
    fp.RawEfSaveFlag = [];
    fp.TimeDescentProf = [];
    fp.UpperPressure = [];
    fp.YoyoFlag = [];
end

if dbdat.maker==1 | dbdat.maker==4  %Webb of Seabird - similar formats
    if dbdat.subtype==0
        fp.bottom_t = [];
        fp.bottom_s = [];
        fp.bottom_p = [];
        
    else
        % Webb Apex float
        fp.pistonpos = [];
        fp.formatnumber = [];
        fp.depthtable = [];
        fp.pumpmotortime = [];
        fp.batterycurrent = [];
        fp.airbladderpres = [];
        fp.airpumpcurrent = [];
        fp.SBEpumpcurrent = [];
        fp.park_t = [];
        fp.park_s = [];
        fp.park_p = [];
        if dbdat.RBR
            fp.park_c = [];
        end
        
        if dbdat.subtype==1
            fp.surfacepistonpos = [];
            fp.bottombatteryvolt = [];
            fp.bottompistonpos = [];
            fp.surfacebatteryvolt = [];
            
        elseif dbdat.subtype==2
            fp.t_8hr = [];
            fp.s_8hr = [];
            fp.p_8hr = [];
            fp.t_48hr = [];
            fp.s_48hr = [];
            fp.p_48hr = [];
            fp.t_88hr = [];
            fp.s_88hr = [];
            fp.p_88hr = [];
            fp.t_128hr = [];
            fp.s_128hr = [];
            fp.p_128hr = [];
            fp.t_168hr = [];
            fp.s_168hr = [];
            fp.p_168hr = [];
            fp.t_208hr = [];
            fp.s_208hr = [];
            fp.p_208hr = [];
            fp.surfacepistonpos = [];
            fp.surfacebatteryvolt = [];
            fp.bottombatteryvolt = [];
            fp.bottompistonpos = [];
            
        elseif dbdat.subtype==4
            fp.profilepistonpos = [];
            fp.surfacepistonpos = [];
            fp.surfacebatteryvolt = [];
            fp.parkbatteryvoltage = [];
            fp.parkpistonpos = [];
            
        elseif dbdat.subtype==10
            fp.surfacepistonpos = [];
            fp.bottombatterycurrent = [];
            fp.SBEpumpvoltage = [];
            
        else
            % all other subtypes (presently all Webb Apex2) have the following
            fp.profilepistonpos = [];
            fp.parkpistonpos = [];
            fp.SBEpumpvoltage = [];
            fp.parkbatteryvoltage = [];
            fp.parkbatterycurrent = [];
        end
        
        if dbdat.subtype==43 || dbdat.subtype==44
            fp.n_parkaverages = 0;
            fp.n_parksamps = 0;
            fp.t_park_av = [];
            fp.p_park_av = [];
        end
        
        if dbdat.subtype==20 | dbdat.subtype==10
            fp.bottombatteryvolt = [];
            fp.bottompistonpos = [];
            fp.n_parksamps = 0;
            fp.t_8hr = [];
            fp.s_8hr = [];
            fp.p_8hr = [];
            fp.t_park_av = [];
            fp.s_park_av = [];
            fp.p_park_av = [];
        end
        
        if dbdat.subtype==22
            fp.surfacepistonpos  = [];
            fp.n_parksamps       = [];
            fp.t_8hr = [];
            fp.s_8hr = [];
            fp.p_8hr = [];
            fp.SBEoxyfreq_8hr = [];
            fp.t_park_av = [];
            fp.s_park_av = [];
            fp.p_park_av = [];
            fp.SBEoxyfreq_park_av = [];
            fp.oxy_park_av = [];
        end
        
        if dbdat.subtype==40
            fp.t_8hr = [];
            fp.s_8hr = [];
            fp.p_8hr = [];
            fp.surfacepistonpos  = [];
            fp.n_parksamps = 0;
            fp.t_park_av = [];
            fp.p_park_av = [];
            fp.s_park_av = [];
        end
        
        if dbdat.ice
            fp.icedetection = [];
            if dbdat.iridium
                fp.iceMLSamples  = [];
                fp.iceMLMedianT = [];
            end
        end
        
        if dbdat.subtype>1000
            fp.SBE41status = [];
            fp.airpumpvoltage = [];
            
            fp.n_parkbuoyancy_adj = [];
            fp.n_parkaverages = [];
            
            if dbdat.subtype~=1004 & dbdat.subtype~=1006  & ...
                    dbdat.subtype~=1008 & dbdat.subtype~=1009 & ...
                    dbdat.maker~=4 & ...
                    dbdat.subtype~=1019 & dbdat.subtype~=1023
                fp.nparksamps =    [];
                fp.t_park_av = [];
                fp.p_park_av = [];
                fp.t_park_std =    [];
                fp.p_park_std =    [];
                fp.t_min =         [];
                fp.p_at_min_t =    [];
                fp.t_max =         [];
                fp.p_at_max_t =    [];
                fp.p_min =         [];
                fp.p_max =         [];
                fp.n_desc_p =      [];
                fp.p_end_pistonretract = [];
                fp.p_1_hour =      [];
                fp.p_2_hour =      [];
                fp.p_3_hour =      [];
                fp.p_4_hour =      [];
                fp.p_5_hour =      [];
            end
        end
        
        if dbdat.subtype == 1002 | dbdat.subtype==1012 % oxygen floats with APF9 controller
            fp.airvolume =                 [];
            fp.n_6secAirpumpbuoyancy_adj = [];
            fp.downtimeExpired_epoch =     [];
            fp.timestarttelemetry =        [];
            fp.surf_Oxy_pressure =         [];
            fp.surf_O2 =                   [];
            fp.surf_optode_Bphase =        [];
            fp.surf_optode_T =             [];
            fp.Bphase_raw =                [];
            fp.time_prof_init =            [];
        end
        if dbdat.subtype == 1003  % vanilla floats with ice detection APF9a controllers
            fp.nAirPumps =                 [];
            fp.VoltSecAirPump =            [];
            fp.iceEvasionBits =            [];
            fp.nMixedLayerSamples =        [];
            fp.medianMixedLayerT =         [];
            fp.infimumMLTmedian =          [];
        end
        if dbdat.subtype == 1004 | dbdat.subtype == 1009 | dbdat.subtype == 1006 | ...
                dbdat.subtype == 1007  | dbdat.subtype==1008 | dbdat.maker == 4 ...
                | dbdat.subtype == 1020 | dbdat.subtype == 1022 | dbdat.subtype == 1030 % apf9 and seabird iridium floats
            fp.jday_ascent_start =         [];
            fp.ftptime =                   [];
            fp.ftp_fname =                 [];
            fp.park_date =                 [];
            fp.park_jday =                 [];
            fp.nsamps =                    [];
            fp.GPSfixtime =                [];
            fp.jday_location =             [];
            fp.GPSsatellites =             [];
            fp.buoyancypumpcurrent =       [];
            fp.buoyancypumpvoltage =       [];
            fp.maxpistonpos =              [];
            fp.gpsfixtime =                [];
            fp.RTCskew =                   [];
            fp.descent_p =                 [];
            fp.descent_jday =              [];
        end
        
        if dbdat.subtype == 1010 | dbdat.subtype==1011 | dbdat.subtype == 1014 % vanilla floats with APF9 controller
            fp.pos_qc =                    [];  %added here so it doesn't break CSIRO processing
            fp.airvolume =                 [];
            fp.downtimeExpired_epoch =     [];
            fp.timestarttelemetry =        [];
        end
        
        if dbdat.subtype == 1005 % near surface T equipped floats
            fp.time_prof_init =            [];
            fp.nsurfpts =                  [];
            fp.nsurfpt =                   [];
            fp.nearsurfT =                 [];
            fp.nearsurfP =                 [];
            fp.nearsurfTpumped =           [];
            fp.nearsurfSpumped =           [];
            fp.nearsurfPpumped =           [];
        end
        
        if dbdat.subtype == 1006 | dbdat.subtype==1020 % optode low res data with high res T and S data
            fp.n_Oxysamples =              [];
            fp.Bphase_raw =                [];
            fp.p_oxygen =                  [];  %pressure for oxygen values
            fp.t_oxygen =                  [];
            fp.s_oxygen =                  [];
            fp.p_oxygen_qc =                  [];  %pressure for oxygen values
            fp.t_oxygen_qc =                  [];
            fp.s_oxygen_qc =                  [];
        end
        if dbdat.subtype == 1022  | dbdat.subtype == 1030  % optode low res data with high res T and S data (added by uday)
            fp.n_Oxysamples =              [];
            fp.Tphase_raw =                [];
            fp.Rphase_raw =                [];
            fp.p_oxygen =                  [];  %pressure for oxygen values
            fp.t_oxygen =                  [];
            fp.s_oxygen =                  [];
            fp.p_oxygen_qc =                  [];  %pressure for oxygen values
            fp.t_oxygen_qc =                  [];
            fp.s_oxygen_qc =                  [];
        end
        if dbdat.subtype == 1007 % seabird oxygen data on Tom Trull's floats
            fp.n_Oxysamples =              [];
            fp.SBEOxyfreq_raw =            [];
        end
        if dbdat.subtype==1008  %low res FLBB/oxygen data from Tom Trull's newest floats
            fp.n_Oxysamples =              [];
            fp.SBEOxyfreq_raw =            [];
            fp.FLBBoxy_raw =                 [];
            fp.p_oxygen =                    [];  %pressure for oxygen values
            fp.t_oxygen =                    [];
            fp.s_oxygen =                    [];
            fp.FLBBoxy_qc =                 uint16([]);
            fp.p_oxygen_qc =                uint16([]);  %pressure for oxygen values
            fp.t_oxygen_qc =                uint16([]);
            fp.s_oxygen_qc =                uint16([]);
        end
        if dbdat.subtype==1019 | dbdat.subtype==1023 %Webb APF11 floats
            fp.jday_ascent_start =         [];
            %hack here to cope with new floats
            if dbdat.subtype==1023
                fp.jday_ascent_to_surface =   [];  %when the sample was
%             STORED, not when it was COLLECTED!!
            end
            fp.jday_surfpres =            [];
            fp.ftptime =                   [];
            fp.ftp_fname =                 [];
%             fp.park_date =                 [];
            fp.park_jday =                 [];
            fp.nsamps =                    [];
            fp.GPSfixtime =                [];
            fp.jday_location =             [];
            %hack here to cope with new floats
            if dbdat.subtype==1023
                fp.GPSsatellites =             [];
            end
%             fp.buoyancypumpcurrent =       [];
%             fp.buoyancypumpvoltage =       [];
            fp.maxpistonpos =              [];
            fp.surfacepistonpos  =         [];
%             fp.gpsfixtime =                [];
            fp.RTCskew =                   [];
%             fp.descent_p =                 [];
%             fp.descent_jday =              [];
    %need new variables for tech data:
            fp.Tech_jday =                 [];
            fp.batteryvoltage =                 [];
            fp.humidity =                 [];
            fp.leak_voltage  =                 [];
            
            fp.coulomb_counter =           [];
            fp.humidity =                  [];
            fp.leakDetect_V =              [];
            fp.jday_start_descent_to_park = [];
            fp.P_descent_to_park =         [];
            if dbdat.RBR
                fp.T_descent_to_park =         [];
                fp.S_descent_to_park =         [];
                fp.C_descent_to_park =         [];
            end
            fp.jday_descent_to_park =         [];
            fp.jday_start_descent_to_profile = [];
            fp.descent_p =      []; % to profile
            if dbdat.RBR
                fp.descent_t =  [];
                fp.descent_s =  [];
                fp.descent_c =  [];
                fp.surfT = [];
                fp.surfS = [];
                fp.surfC = [];
                fp.surfpresCP = [];
                fp.surf_TCP = [];
                fp.surf_SCP = [];
                fp.surf_CCP = [];
                fp.surf_jdayCP = [];
                fp.surf_nsampsCP =[];
                fp.jday_ascent_to_surface =   [];
            end

            fp.descent_jday =      [];  % to profile
            fp.P_ascent_to_surface_spotsamp =      [];
            fp.T_ascent_to_surface_spotsamp =      [];
            fp.S_ascent_to_surface_spotsamp =      [];
            if dbdat.RBR
                            fp.C_ascent_to_surface_spotsamp =      [];
            end
            fp.jday_ascent_to_surface_spotsamp =      [];
%             fp.P_scan =                   [];              
%             fp.T_scan =                   [];
%             fp.S_scan =                   [];
            if dbdat.RBR
                fp.C_scan =               [];
            end
        end
        
        if dbdat.subtype == 1014  %newest vanilla format with internal vacuum moved
            fp.nAirPumps =                 [];
            fp.time_prof_init =            [];
            fp.p_divergence =              [];
            fp.psurf_now =                 [];
        end
        if dbdat.subtype == 1017  % seabird navis float with optical oxygen sensor
            fp.n_Oxysamples =              [];
            fp.O2phase_raw =               [];
            fp.p_oxygen =                  [];  %pressure for oxygen values
            fp.t_oxygen =                  [];
            fp.s_oxygen =                  [];
            fp.p_oxygen_qc =                uint16([]);  %pressure for oxygen values
            fp.t_oxygen_qc =                uint16([]);
            fp.s_oxygen_qc =                uint16([]);
            fp.park_O2phase =              [];
            fp.parkT_SBEO2 =               [];
        end
        if dbdat.subtype == 1021   % Indian APF9G floats
            fp.TelonicsStatus =             [];
            fp.n_6secAirpumpbuoyancy_adj = [];
        end
        if dbdat.subtype==1026 | dbdat.subtype==1027 | dbdat.subtype==1028 ...
                | dbdat.subtype==1029 |dbdat.subtype == 1031 % seabird bio floats
            fp.n_Oxysamples =              [];
            fp.O2phase_raw =               [];
            if dbdat.subtype==1027 | dbdat.subtype == 1031
                fp.p_oxygen =                  [];  %pressure for oxygen values on secondary axis
                fp.t_oxygen =                  [];
                fp.s_oxygen =                  [];
                fp.p_oxygen_qc =                uint16([]);  %pressure for oxygen values
                fp.t_oxygen_qc =                uint16([]);
                fp.s_oxygen_qc =                uint16([]);
            end
            fp.park_O2phase =              [];
            fp.parkT_volts =         [];
            fp.t_oxygen_volts =            [];
            
%             if dbdat.subtype==1029
%                 fp.p_oxygen =                  [];  %pressure for oxygen values on secondary axis
%                 fp.t_oxygen =                  [];
%                 fp.s_oxygen =                  [];
%                 fp.p_oxygen_qc =                uint16([]);  %pressure for oxygen values
%                 fp.t_oxygen_qc =                uint16([]);
%                 fp.s_oxygen_qc =                uint16([]);
%                 fp.O2phase_oxygen =             uint16([]);
%                 fp.O2phase_oxygen_qc =          uint16([]);
%                 fp.T_volts_oxygen =             uint16([]);
%                 fp.T_volts_oxygen_qc =          uint16([]);
%                 fp.Fsig_oxygen = [];
%                 fp.Fsig_oxygen_qc = uint16([]);
%                 fp.BBP532_oxygen = [];
%                 fp.BBP532_oxygen_qc = uint16([]);
%                 fp.Bbsig700_oxygen = [];
%                 fp.BBP700_oxygen = [];
%                 fp.BBP700_oxygen_qc = uint16([]);
%                 fp.Bbsig700_oxygen = [];
%                 fp.pHvolts_oxygen  =  [];
%                 fp.pH_oxygen  =  [];
%                 fp.pH_oxygen_qc  =  [];
%                 fp.pHT_oxygen  =  [];
%                 fp.pHT_oxygen_qc  =  [];
%                 fp.Tilt_oxygen  =  [];
%                 fp.Tilt_oxygen_sd  =  [];
%                 fp.irr380_oxygen      =[];
%                 fp.irr412_oxygen      =[];
%                 fp.irr490_oxygen      =[];
%                 fp.irrPAR_oxygen      =[];
%                 fp.dn_irr380_oxygen      =[];
%                 fp.dn_irr412_oxygen      =[];
%                 fp.dn_irr490_oxygen      =[];
%                 fp.dn_irrPAR_oxygen      =[];
%                 fp.dn_irr380_oxygen_qc       = uint16([]);
%                 fp.dn_irr412_oxygen_qc       = uint16([]);
%                 fp.dn_irr490_oxygen_qc       = uint16([]);
%                 fp.dn_irrPAR_oxygen_qc       = uint16([]);
%             end

            if dbdat.suna
                fp.no3_raw   = [];
                fp.no3_qc    =  [];
            end
            if dbdat.tmiss
                
            end
            if dbdat.flbb2
                fp.BBP532_raw = [];
                fp.BBP532_qc = uint16([]);
                fp.Bbsig532 = [];
                fp.parkBBP532_qc = uint16([]); %=== added by uday ====
                fp.parkBBP532 = []; %=== added by uday ====
                fp.parkBbsig532 = [];
            end
            if dbdat.pH
                fp.pHvolts  =  [];
                fp.pH_raw  =  [];
                fp.pH_qc  =  [];
                fp.pHT  =  [];
                fp.pHT_qc  =  [];
                fp.Tilt  =  [];
                fp.Tilt_sd  =  [];
                fp.park_pHvolts  =  [];
                fp.park_pHT  =  [];
                fp.park_pH  =  [];
                fp.park_Tilt  =  [];
            end   
        end
        if dbdat.subtype == 1031
            fp.Tilt  =  [];
            fp.Tilt_sd  =  [];
            fp.park_tilt  =  [];
        end 
        if dbdat.subtype==1030 %Peter Thompson's nitrate bio floats
            if dbdat.suna
                fp.no3_raw   = [];
                fp.no3_qc    =  [];
            end
        end
    end
    
elseif dbdat.maker==2
    % Provor float
    fp.desc_sttime = [];
    fp.n_valve_acts_surf = [];
    fp.first_stab_time = [];
    if dbdat.subtype==4
        fp.first_stab_p = [];
    end
    fp.n_valve_acts_desc = [];
    fp.n_pump_acts_desc = [];
    fp.desc_endtime = [];
    fp.n_repositions = [];
    fp.n_pump_acts_asc = [];
    fp.resurf_endtime = [];
    fp.n_pump_acts_surf = [];
    fp.float_time_hour = [];
    fp.float_time_min = [];
    fp.float_time_sec = [];
    fp.pres_offset = [];
    fp.internal_vacuum = [];
    fp.n_asc_blks = [];
    fp.n_asc_samps = [];
    fp.n_drift_blks = [];
    fp.drift_samp_period = [];
    fp.n_drift_samps = [];
    
    if dbdat.subtype==4
        fp.park_t = [];
        fp.park_s = [];
        fp.park_p = [];
        fp.n_desc_blks = [];
        fp.n_desc_samps = [];
        fp.n_desc_slices_shallow = [];
        fp.n_desc_slices_deep = [];
        fp.n_asc_slices_shallow = [];
        fp.n_asc_slices_deep = [];
        fp.max_desc_park_p = [];
        fp.max_park_p = [];
        fp.min_park_p = [];
        fp.asc_start_time =[];
        fp.n_entrance_drift_descent = [];
        fp.max_prof_p = [];
        fp.n_valve_acts_desc = [];
        fp.n_pump_acts_desc_prof = [];
        fp.n_valve_acts_desc_prof = [];
        fp.n_repositions_standby = [];
        fp.batvolt_drop_atPmax_pumpon = [];
        fp.desc_sttime_to_prof = [];
        fp.desc_endtime_to_prof = [];
        fp.RTC_state = [];
        fp.n_entrance_prof_target = [];
        fp.first_park_samp_time = [];
        fp.first_park_samp_date = [];
        fp.profile_samp_date = [];
 %       if dbdat.subtype==5 % descending profile information
            fp.profile_desc_samp_date = [];
            fp.s_desc_raw = [];              % Exactly as decoded from transmission - no QC
            fp.t_desc_raw = [];              % Exactly as decoded from transmission - no QC
            fp.p_desc_raw = [];              % Exactly as decoded from transmission - no QC
            fp.cndc_desc_raw = [];           % as computed from s_raw, t_raw and p_raw
            
            % Note: qc variables end up as strings of characters '0' to '9'. We keep them
            %   as numbers for now (for ease of testing), but use row vectors so that
            %   num2str produces a horizontal string.
            % Note: at this stage, QC only done once, so not required to have separate QC
            %   variables for '_raw' and '_calibrate' data.
            
            fp.s_desc_qc = uint16([]);           % Decimal QC flags for each value
            fp.t_desc_qc = uint16([]);           %             ^
            fp.p_desc_qc = uint16([]);           %             ^
            fp.cndc_desc_qc = uint16([]);        %             ^
            
            fp.s_desc_qc_status = '';    % Summary QC assessment of profile ('A' to 'F')
            fp.t_desc_qc_status = '';    %                ^
            fp.p_desc_qc_status = '';    %                ^
            fp.cndc_desc_qc_status = ''; %                ^
            
            % These variables contain all values found in the '_raw' vectors, whether or
            % not they have been flagged in QC tests.
            % NOTE:
            %   Since s is calibrated the whole profile is regarded as Adjusted rather
            % than Raw, hence the user may try to use values from t_desc_calibrate. We fill
            % t_calibrate with t_desc_raw values for their ease. JRD disapproves of this!
            
            fp.p_desc_calibrate = [];    % surface-offset corrected P
            fp.s_desc_calibrate = [];    % calibrated S
            fp.t_desc_calibrate = [];    % calibrated T
            fp.cndc_desc_calibrate = []; % calibrated conductivity

%        end
    else
        %         fp.n_pump_acts_surf = [];
        %         fp.drift_samp_period = [];
        fp.date_1st_driftsamp = [];
        fp.time_1st_driftsamp = [];
        fp.sevenV_batvolt = [];
        fp.fourteenV_batvolt = [];
        fp.asc_prof_num = [];
    end
    
elseif dbdat.maker == 3 | dbdat.maker==5 % Solo polynya floats; S2A MRV Solo II floats
    
    %     if dbdat.subtype == 1015  %solo polynya floats
    fp.park_date =                 [];
    fp.park_jday =                 [];
    fp.park_t = [];
    fp.park_s = [];
    fp.park_p = [];
    fp.nparksamps =    [];
    fp.PI =                         [];
    fp.inst_type =                  [];
    fp.rec_type =                   [];
    fp.syst_flags_depth =           [];
    fp.syst_flags_surface =         [];
    fp.p_internal_surface =         [];
    fp.CPUpumpvoltage =             [];
    fp.CPUpumpSURFACEvoltage =      [];
    fp.SBEpumpvoltage =             [];
    fp.SBEpumpSURFACEvoltage =      [];
    fp.driftpump_adj =              [];
    fp.pumpin_outatdepth =          [];
    fp.pumpin_outatsurface =        [];
    fp.GPScounter =                 [];
    fp.previous_position =          [];
    
    if dbdat.subtype==1018
        fp.n_parkaverages = 0;
        fp.t_park_av = [];
        fp.s_park_av = [];
        fp.p_park_av = [];
        %             fp.jday_qc = [];
    end
    
    %     end
end

% fp.jday_qc = [];
fp.pos_qc = zeros(1,'uint8');        % QC info

% messy but put this here because it wasn't done right originally and we
% need a new field...
if  dbdat.subtype==31 ||dbdat.subtype==32 || dbdat.subtype==35 ||dbdat.subtype==40
    fp.parkO2_umolar = [];  %31
    fp.oxy_umolar = [];
end

fp.satnam = [];
% fp.position_qc = [];


return

%------------------------------------------------------------------------
