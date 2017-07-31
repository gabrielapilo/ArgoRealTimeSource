%=================================================================================
%SBD - ARVOR-I FLOAT TECHNICAL PACKET1 (Type=0)
% --------------------------------------------------------------------------------
% Packet type Code: 0x01-0x07 
% GPS 0x01 Fix at before leaving surface in Surface Drift
%
% Reference:
%         pp. 27,28: "Arvor-i flaot user manual, NKE instrumentation"
%==================================================================================
function u = decodeTechPkt1Typ0(sensor)
%begin 
    %first byte==1,2,3,4,5 ARE ALL GPS FIXES At different times:
    u = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) > 14)     return; end;
    if (length(sensor)<100) return; end;

    %prepare an empty output structure:
    u.type                          = [];
    u.profile_number                = [];
    u.ird_ssn_num                   = [];
    u.chk_sum                       = [];
    u.flt_srl_num                   = [];
    u.bgn_day                       = [];
    u.bgn_mnt                       = [];
    u.bgn_year                      = [];
    u.rlt_st_day                    = [];
    u.cyc_st_time                   = [];
    u.hydralic_act_duration         = [];
    u.n_valve_acts_surf             = [];
    u.grounded                      = [];
    u.desc_sttime                   = [];
    u.first_stab_time               = [];
    u.desc_endtime                  = [];
    u.n_valve_acts_desc             = [];
    u.n_pump_acts_desc              = [];
    u.first_stab_p                  = [];
    u.max_desc_park_p               = [];
    u.drift_phase_abs_day           = [];
    u.n_entrance_drift_descent      = [];
    u.n_repositions                 = [];
    u.min_park_p                    = [];
    u.max_park_p                    = [];
    u.n_valve_p                     = [];
    u.n_pump_p                      = [];
    u.desc_sttime_to_prof           = [];
    u.desc_endtime_to_prof          = [];
    u.n_valve_act_desc_prof         = [];
    u.n_pump_act_desc_prof          = [];
    u.max_prof_p                    = [];
    u.n_entrance_prof_target        = [];
    u.n_repositions_standby         = [];
    u.n_valve_driftP                = [];
    u.n_pump_driftP                 = [];
    u.min_park_dirftP               = [];
    u.max_park_driftP               = [];
    u.asc_start_time                = [];
    u.resurf_endtime                = [];
    u.n_pump_acts_asc               = [];
    u.float_time_hour               = [];
    u.float_time_min                = [];
    u.float_time_sec                = [];
    u.float_date_day                = [];
    u.float_date_mon                = [];
    u.float_date_year               = [];
    u.pres_offset                   = [];
    u.internal_vacuum               = [];
    u.batvolt_drop_atPmax_pumpon    = [];
    u.RTC_state                     = [];
    u.coh_prob_cntr                 = [];
    u.oxy_status                    = [];
    u.gps_lat_deg                   = [];
    u.gps_lat_min                   = [];
    u.gps_lat_minfrac               = [];
    u.gps_lat_orientation           = [];
    u.gps_lon_deg                   = [];
    u.gps_lon_min                   = [];
    u.gps_lon_minfrac               = [];
    u.gps_lon_orientation           = [];
    u.gps_valid                     = [];
    u.gps_ssn                       = [];
    u.gps_retire                    = [];
    u.gps_pump_dur                  = [];
    u.ant_status                    = [];
    u.end_life_flg                  = [];
    u.end_life_hr                   = [];
    u.end_life_min                  = [];
    u.end_life_sec                  = [];
    u.end_life_day                  = [];
    u.end_life_mon                  = [];
    u.end_life_year                 = [];

    %remove the first byte to match sequence with table indices on page 55:
    bytes = sensor(1:end);
    %disp(bytes)    
  
  % check to see if cycle_number and float serial number is 0
  %if((bytes(2)*256 + bytes(3)) == 0 && (bytes(7)*256 + bytes(8)) == 0);
  %else
    %General information
    %byte-2&3: cycle number
    u.type = bytes(1);
    u.profile_number = bytes(2)*256 + bytes(3);

    %byte-4 Iridium session number
    u.ird_ssn_num = bytes(4);

    %byte-5&6 Floats's firmware checksum
    u.chk_sum = bytes(5)*256 + bytes(6);

    %byte-7&8
    u.flt_srl_num = bytes(7)*256 + bytes(8);

    %Emergence reduction
    %byte-9:11 Day,Month and Year of beginning
    u.bgn_day = bytes(9);
    u.bgn_mnt = bytes(10);
    u.bgn_year = bytes(11);
    u.rlt_st_day = bytes(12)*256 + bytes(13);
    u.cyc_st_time = bytes(14)*256 + bytes(15);
    u.hydralic_act_duration = bytes(16)*256 + bytes(17);
    u.n_valve_acts_surf = bytes(18);
    u.grounded = bytes(19);
    %Parking depth descent
    u.desc_sttime = (bytes(20)*256 + bytes(21))/60.0;
    u.first_stab_time = (bytes(22)*256 + bytes(23))/60.0;
    u.desc_endtime = (bytes(24)*256 + bytes(25))/60.0;
    u.n_valve_acts_desc = bytes(26);
    u.n_pump_acts_desc = bytes(27);
    u.first_stab_p = bytes(28)*256 + bytes(29);
    u.max_desc_park_p  = bytes(30)*256 + bytes(31);
    %Parking drift phase
    u.drift_phase_abs_day = bytes(32);
    u.n_entrance_drift_descent = bytes(33);
    u.n_repositions = bytes(34);
    u.min_park_p  = bytes(35)*256 + bytes(36);
    u.max_park_p  = bytes(37)*256 + bytes(38);
    u.n_valve_p = bytes(39);
    u.n_pump_p = bytes(40);
    %Descent to profile depth
    u.desc_sttime_to_prof  = (bytes(41)*256 + bytes(42))/60.0;
    u.desc_endtime_to_prof  = (bytes(43)*256 + bytes(44))/60.0;
    u.n_valve_act_desc_prof = bytes(45);
    u.n_pump_act_desc_prof = bytes(46);
    u.max_prof_p  = bytes(47)*256 + bytes(48);
    %Drift to P Profile phase
    u.n_entrance_prof_target = bytes(49);
    u.n_repositions_standby = bytes(50);
    u.n_valve_driftP  = bytes(51);
    u.n_pump_driftP  = bytes(52);
    u.min_park_dirftP = bytes(53)*256 + bytes(54);
    u.max_park_driftP = bytes(55)*256 + bytes(56);
    %Ascent Phase
    u.asc_start_time = (bytes(57)*256 + bytes(58))/60.0;
    u.resurf_endtime = (bytes(59)*256 + bytes(60))/60.0;
    u.n_pump_acts_asc = bytes(61);
    %General information
    u.float_time_hour = bytes(62);
    u.float_time_min  = bytes(63);
    u.float_time_sec  = bytes(64);
    u.float_date_day = bytes(65);
    u.float_date_mon = bytes(66);
    u.float_date_year = bytes(67);
    % pres_offset coded in tow's complement hence check for priority bit
    junkp = dec2bin(bytes(68),8);
    if str2num(junkp(1)) == 1
        u.pres_offset = (bytes(68) - 2^8);
    else
        u.pres_offset = bytes(68);
    end
    u.internal_vacuum  = bytes(69)*5.0;
    u.batvolt_drop_atPmax_pumpon  = 15.0 - (bytes(70)*0.1);
    u.RTC_state  = bytes(71);
    u.coh_prob_cntr  = bytes(72);
    u.oxy_status  = bytes(73);
    %GPS data information
    u.gps_lat_deg = bytes(74);
    u.gps_lat_min  = bytes(75);
    u.gps_lat_minfrac = bytes(76)*256 + bytes(77);
    u.gps_lat_orientation = bytes(78);
    u.gps_lon_deg  = bytes(79);
    u.gps_lon_min  = bytes(80);
    u.gps_lon_minfrac = bytes(81)*256 + bytes(82);
    u.gps_lon_orientation = bytes(83);
    u.gps_valid = bytes(84);
    u.gps_ssn = bytes(85)*256 + bytes(86);
    u.gps_retire = bytes(87);
    u.gps_pump_dur = bytes(88)*256 + bytes(89);
    u.ant_status = bytes(90);
    %End of life information
    u.end_life_flg = bytes(91);
    u.end_life_hr = bytes(92);
    u.end_life_min = bytes(93);
    u.end_life_sec = bytes(94);
    u.end_life_day = bytes(95);
    u.end_life_mon = bytes(96);
    u.end_life_year = bytes(97);
%   end
end
