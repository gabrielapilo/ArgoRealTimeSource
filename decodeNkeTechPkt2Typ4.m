%=================================================================================
%SBD - ARVOR-I FLOAT TECHNICAL PACKET1 (Type=4)
% --------------------------------------------------------------------------------
% Packet type Code: 0x04
% Additional parameter which are not in Packet1 are given here
%
% Reference:
%         pp. 27,28: "Arvor-i flaot user manual, NKE instrumentation"
%==================================================================================
function u = decodeTechPkt2Typ4(sensor)
%begin 
    %first byte==1,2,3,4,5 ARE ALL GPS FIXES At different times:
    u = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) > 14)     return; end;
    if (length(sensor)<100) return; end;

    %prepare an empty output structure:
      u.type = [];
      u.profile_number         = [];
      u.ssn_indicator         = [];
      u.n_desc_blks         = [];
      u.n_drift_blks         = [];
      u.n_asc_blks         = [];
      u.n_ctd_near_surf_pkt         = [];
      u.n_ctd_in_air_pkt         = [];
      u.n_desc_slices_shallow         = [];
      u.n_desc_slices_deep         = [];
      u.n_drift_samps         = [];
      u.n_asc_slices_shallow         = [];
      u.n_asc_slices_deep         = [];
      u.n_ctd_near_surf_mes         = [];
      u.n_ctd_in_air_mes         = [];
      u.sub_surf_pres         = [];
      u.sub_surf_temp         = [];
      u.sub_surf_psal         = [];
      u.sub_surf_c1Phase         = [];
      u.sub_surf_c2Phase         = [];
      u.sub_surf_opttemp         = [];
      u.ground_num         = [];
      u.ground_pres1         = [];
      u.ground_pres1_day         = [];
      u.ground_pres1_hour         = [];
      u.ground_pres1_phase         = [];
      u.ground_pres1_ev         = [];
      u.ground_pres2         = [];
      u.ground_pres2_day         = [];
      u.ground_pres2_hour         = [];
      u.ground_pres2_phase         = [];
      u.ground_pres2_ev         = [];
      u.emergency_asc_num         = [];
      u.emergency_asc_time         = [];
      u.emergency_asc_pres         = [];
      u.n_pump_emergency_asc         = [];
      u.emergency_asc_rel_day         = [];
      u.n_rem_files_rcvd         = [];
      u.n_rem_files_rejected         = [];
      u.n_rem_cmd_rcvd         = [];
      u.n_rem_cmd_rejected         = [];
      u.prv_ird_trans_dur         = [];
      u.n_sbd_recpt         = [];
      u.n_sbd_trans         = [];
      u.n_pump_b4_asc         = [];
      u.int_vac_asc_stup         = [];
      u.last_reset_hr         = [];
      u.last_reset_min         = [];
      u.last_reset_sec         = [];
      u.last_reset_day         = [];
      u.last_reset_mon         = [];
      u.last_reset_year         = [];
      u.auto_test         = [];
      u.auto_test_detailed         = [];
      u.param_integrity_tst         = [];
      u.positive_buoy_depl         = [];
      u.ctd_status         = [];
      u.float_phase         = [];
      u.hyd_type         = [];

    %remove the first byte to match sequence with table indices on page 55:
    bytes = sensor(1:end);
    %disp(bytes)    

    %General information
    %byte-2&3: cycle number
    u.type = bytes(1);
    u.profile_number = bytes(2)*256 + bytes(3);

    %byte-4 Iridium session indicator
    u.ssn_indicator = bytes(4);

    % Data information
    u.n_desc_blks = bytes(5);
    u.n_drift_blks = bytes(6);
    u.n_asc_blks = bytes(7);
    u.n_ctd_near_surf_pkt = bytes(8);
    u.n_ctd_in_air_pkt = bytes(9);
    u.n_desc_slices_shallow = bytes(10)*256 + bytes(11);
    u.n_desc_slices_deep = bytes(12)*256 + bytes(13);
    u.n_drift_samps = bytes(14);
    u.n_asc_slices_shallow = bytes(15)*256 + bytes(16);
    u.n_asc_slices_deep = bytes(17)*256 + bytes(18);
    u.n_ctd_near_surf_mes = bytes(19);
    u.n_ctd_in_air_mes = bytes(20);

    %Sub-surface Point
    % Pres and temperature are coded in two's complement
    %u.sub_surf_pres = bytes(21)*256 + bytes(22);
    ppp = [dec2hex(bytes(21)) dec2hex(bytes(22))];
    intpp = dec2bin(hex2dec(ppp),16);
    if str2num(intpp(1)) == 1
       u.sub_surf_pres = ((hex2dec(ppp) - 2^16) + 10000.0)/10.0;
    else
       u.sub_surf_pres = (hex2dec(ppp) + 10000.0)/10.0;
    end
    %u.sub_surf_temp = bytes(23)*256 + bytes(24);
    ttt = [dec2hex(bytes(23)) dec2hex(bytes(24))];
    inttt = dec2bin(hex2dec(ttt),16);
    if str2num(inttt(1)) == 1
       u.sub_surf_temp = (hex2dec(ttt) - 2^16)/1000.0;
    else
       u.sub_surf_temp = hex2dec(ttt)/1000.0;
    end
    u.sub_surf_psal  = (bytes(25)*256 + bytes(26))/1000.0;
    u.sub_surf_c1Phase   = bytes(27)*256 + bytes(28);
    u.sub_surf_c2Phase  = bytes(29)*256 + bytes(30);
    u.sub_surf_opttemp  = bytes(31)*256 + bytes(32);

    %Grounding
    u.ground_num = bytes(33);
    u.ground_pres1  = bytes(34)*256 + bytes(35);
    u.ground_pres1_day = bytes(36);
    u.ground_pres1_hour = bytes(37)*256 + bytes(38);
    u.ground_pres1_phase = bytes(39);
    u.ground_pres1_ev = bytes(40);
    u.ground_pres2 = bytes(41)*256 + bytes(42);
    u.ground_pres2_day = bytes(43);
    u.ground_pres2_hour = bytes(44)*256 + bytes(45); 
    u.ground_pres2_phase = bytes(46);
    u.ground_pres2_ev = bytes(47);

    %Emergency ascent
    u.emergency_asc_num = bytes(48);
    u.emergency_asc_time = bytes(49)*256 + bytes(50);
    u.emergency_asc_pres = bytes(51)*256 + bytes(52);
    u.n_pump_emergency_asc = bytes(53);
    u.emergency_asc_rel_day = bytes(54);
    u.n_rem_files_rcvd = bytes(55);
    u.n_rem_files_rejected = bytes(56);
    u.n_rem_cmd_rcvd = bytes(57);
    u.n_rem_cmd_rejected = bytes(58);
    u.prv_ird_trans_dur = bytes(59)*256 + bytes(60);;
    u.n_sbd_recpt = bytes(61);
    u.n_sbd_trans = bytes(62)*256 + bytes(63);
    u.n_pump_b4_asc = bytes(64);
    u.int_vac_asc_stup = bytes(65)*5;
    u.last_reset_hr    = bytes(66);
    u.last_reset_min = bytes(67);
    u.last_reset_sec = bytes(68);
    u.last_reset_day = bytes(69);
    u.last_reset_mon = bytes(70);
    u.last_reset_year = bytes(71);
    u.auto_test         = bytes(72);
    u.auto_test_detailed = bytes(73)*256 + bytes(74);
    u.param_integrity_tst = bytes(75);
    u.positive_buoy_depl  = bytes(76);
    u.ctd_status         = bytes(77);
    u.float_phase         = bytes(78);
    u.hyd_type         = bytes(79);
end
