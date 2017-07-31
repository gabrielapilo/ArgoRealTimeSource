%=================================================================================
%SBD - ARVOR-I FLOAT PARAMETER N2 PACKET (Type=7)
% --------------------------------------------------------------------------------
% Packet type Code: 0x07
% This message contains float's additional mission and technical commands
%
% Reference:
%         pp. 27,28: "Arvor-i flaot user manual, NKE instrumentation"
%==================================================================================
function u = decodeParamN2PktTyp7(sensor)
%begin 
    %first byte==1 gives the packet type information:
    u = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) > 14)     return; end;
    if (length(sensor)<100) return; end;

    %prepare an empty output structure:
      u.type = [];
      u.profile_number = [];
      u.ird_ssn_num = [];
      u.float_time_hour  = [];
      u.float_time_min  = [];
      u.float_time_sec = [];
      u.float_date_day = [];
      u.float_date_mon = [];
      u.float_date_year = [];
      u.flt_srl_num = [];
      u.days_noasct_ice_detect_IC0 = [];
      u.days_force_ascnt_ice_detect_IC1 = [];
      u.ice_confirm_IC2 = [];
      u.strt_pres_detect_IC3 = [];
      u.stop_pres_detect_IC4 = [];
      u.temp_threshold_IC5 = [];
      u.decl_threshold_IC6 = [];
      u.pres_acquisition_IC7 = [];
      u.stab_pres_asc_IC8 = [];
      u.pump_act_dur_IC9 = [];
      u.gps_timeout_IC10 = [];
      u.gps_lockout_IC11 = [];
      u.gps_cnfm_delay_IC12 = [];
      u.pres_offset_IC13 = [];
      u.val_act_IC14 = [];
      u.max_val_vol_IC15 = [];


    %remove the first byte to match sequence with table indices on page 55:
    bytes = sensor(1:end);

    %General information
    %byte-2&3: cycle number
    u.type = bytes(1);
    u.profile_number = bytes(2)*256 + bytes(3);
    u.ird_ssn_num = bytes(4);
    u.float_time_hour  = bytes(5);
    u.float_time_min  = bytes(6);
    u.float_time_sec  = bytes(7);
    u.float_date_day = bytes(8);
    u.float_date_mon = bytes(9);
    u.float_date_year = bytes(10);
    u.flt_srl_num = bytes(11)*256 + bytes(12);

    %Ice detection parameters - Next cycle
    u.days_noasct_ice_detect_IC0 = bytes(13)*256 + bytes(14);
    u.days_force_ascnt_ice_detect_IC1 = bytes(15)*256 + bytes(16);
    u.ice_confirm_IC2 = bytes(17);
    u.strt_pres_detect_IC3 = bytes(18);
    u.stop_pres_detect_IC4 = bytes(19);
    % temp coded in two's complement
    %u.temp_threshold_IC5 = bytes(20)*256 + bytes(21);
    tt = [dec2hex(bytes(20)) dec2hex(bytes(21))];
    intt = dec2bin(hex2dec(tt),16);
    if str2num(intt(1)) == 1
       u.temp_threshold_IC5 = (hex2dec(tt) - 2^16)/1000.0;
    else
       u.temp_threshold_IC5 = hex2dec(tt)/1000.0;
    end
    u.decl_threshold_IC6 = bytes(22)*256 + bytes(23);
    u.pres_acquisition_IC7 = bytes(24);
    u.stab_pres_asc_IC8 = bytes(25);
    u.pump_act_dur_IC9 = bytes(26)*256 + bytes(27);
    u.gps_timeout_IC10 = bytes(28);
    u.gps_lockout_IC11 = bytes(29);
    u.gps_cnfm_delay_IC12 = bytes(30);
    u.pres_offset_IC13 = bytes(31);
    u.val_act_IC14 = bytes(32);
    u.max_val_vol_IC15 = bytes(33)*256 + bytes(34);
      
end
