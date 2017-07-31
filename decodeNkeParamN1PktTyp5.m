%=================================================================================
%SBD - ARVOR-I FLOAT PARAMETER PACKET (Type=5)
% --------------------------------------------------------------------------------
% Packet type Code: 0x05
% This message contains float's mission and technical commands
%
% Reference:
%         pp. 27,28: "Arvor-i flaot user manual, NKE instrumentation"
%==================================================================================
function u = decodeParamN1PktTyp5(sensor)
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
      u.float_time_sec  = [];
      u.float_date_day = [];
      u.float_date_mon = [];
      u.float_date_year = [];
      u.flt_srl_num = [];
      u.n_cyc_total_MC0 = [];
      u.n_cyc_prd1_MC1 = [];
      u.cyc_prd1_MC2 = [];
      u.cyc_prd2_MC3 = [];
      u.ref_day_MC4 = [];
      u.tim_at_surf_MC5 = [];
      u.delay_b4_msn_MC6 = [];
      u.ctd_acqu_mode_MC7 = [];
      u.des_samp_prd_MC8 = [];
      u.drift_samp_prd_MC9 = [];
      u.Asc_samp_prd_MC10 = [];
      u.drift_depMC1_MC11 = [];
      u.prof_depMC_MC12 = [];
      u.drift_depMC2_MC13 = [];
      u.prof_depMC2MC14 = [];
      u.t_profil_alt_MC15 = [];
      u.p_profil_alt_MC16 = [];
      u.thres_surfint_pres_MC17 = [];
      u.thres_intbtm_pres_MC18 = [];
      u.surf_slice_thick_MC19 = [];
      u.intr_slice_thick_MC20 = [];
      u.btm_slice_thick_MC21 = [];
      u.ird_EOL_trns_prd_MC22 = [];
      u.ird_ssn_wait2_prd_MC23 = [];
      u.ground_mode_MC24 = [];
      u.ground_switch_pres_MC25 = [];
      u.delay_ground_surf_MC26 = [];
      u.optode_type_MC27 = [];
      u.ctd_cutoff_pres_MC28 = [];
      u.cyc_inair_cycle_MC29 = [];
      u.cyc_inair_samp_MC30 = [];
      u.inair_tot_dur_MC31 = [];
      u.ev_act_surf_TC0 = [];
      u.ev_max_vol_TC1 = [];
      u.max_pump_repost_TC2 = [];
      u.pump_durat_asc_TC3 = [];
      u.pump_durat_surf_TC4 = [];
      u.pres_delta_TC5 = [];
      u.max_pres_b4_emergency_asc_TC6 = [];
      u.thold_buoy_reduct1_TC7 = [];
      u.thold_buoy_reduct1_TC8 = [];
      u.repost_thold_TC9 = [];
      u.max_vol_ground_TC10 = [];
      u.ground_pres_TC11 = [];
      u.pres_delta_TC12 = [];
      u.avg_des_speed_TC13 = [];
      u.pres_incr_TC14 = [];
      u.asc_end_pres_TC15 = [];
      u.avg_asc_speed_TC16 = [];
      u.float_speed_cntr_TC17 = [];
      u.pres_speed_cntr_TC18 = [];
      u.gps_ssn_dur_TC19 = [];
      u.hyd_msg_trans_TC20 = [];
      u.delay_resetoffset_TC21 = [];
      u.duration_pump_inair_TC22 = [];
      u.coeffa_TC23 = [];
      u.coeffb_TC24 = [];


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

    %Mission parameters - Next cycle
    u.n_cyc_total_MC0 = bytes(13)*256 + bytes(14);
    u.n_cyc_prd1_MC1 =  bytes(15)*256 + bytes(16);
    u.cyc_prd1_MC2 =  bytes(17)*256 + bytes(18);
    u.cyc_prd2_MC3 =  bytes(19)*256 + bytes(20);
    u.ref_day_MC4 = bytes(21);
    u.tim_at_surf_MC5 = bytes(22);
    u.delay_b4_msn_MC6 = bytes(23);
    u.ctd_acqu_mode_MC7 = bytes(24);
    u.des_samp_prd_MC8 = bytes(25);
    u.drift_samp_prd_MC9 = bytes(26);
    u.Asc_samp_prd_MC10 = bytes(27);
    u.drift_depMC1_MC11 = bytes(28)*256 + bytes(29);
    u.prof_depMC_MC12 = bytes(30)*256 + bytes(31);
    u.drift_depMC2_MC13 = bytes(32)*256 + bytes(33);
    u.prof_depMC2MC14 = bytes(34)*256 + bytes(35);
    u.t_profil_alt_MC15 = bytes(36);
    u.p_profil_alt_MC16 = bytes(37)*256 + bytes(38);
    u.thres_surfint_pres_MC17 = bytes(39)*256 + bytes(40);
    u.thres_intbtm_pres_MC18 = bytes(41)*256 + bytes(42);
    u.surf_slice_thick_MC19 = bytes(43);
    u.intr_slice_thick_MC20 = bytes(44);
    u.btm_slice_thick_MC21 = bytes(45);
    u.ird_EOL_trns_prd_MC22 = bytes(46)*256 + bytes(47);
    u.ird_ssn_wait2_prd_MC23 = bytes(48)*256 + bytes(49);
    u.ground_mode_MC24 = bytes(50);
    u.ground_switch_pres_MC25 = bytes(51);
    u.delay_ground_surf_MC26 = bytes(52);
    u.optode_type_MC27 = bytes(53);
    u.ctd_cutoff_pres_MC28 = bytes(54);
    u.cyc_inair_cycle_MC29 = bytes(55);
    u.cyc_inair_samp_MC30 = bytes(56)*256 + bytes(57);
    u.inair_tot_dur_MC31 = bytes(58)*256 + bytes(59);

    %Technical Parameter - Next cycle
    u.ev_act_surf_TC0 = bytes(60)*256 + bytes(61);
    u.ev_max_vol_TC1 = bytes(62);
    u.max_pump_repost_TC2 = bytes(63)*10;
    u.pump_durat_asc_TC3 = bytes(64)*10;
    u.pump_durat_surf_TC4 = bytes(65)*1000;
    u.pres_delta_TC5 = bytes(66);
    u.max_pres_b4_emergency_asc_TC6 = bytes(67)*256 + bytes(68);
    u.thold_buoy_reduct1_TC7 = bytes(69);
    u.thold_buoy_reduct1_TC8 = bytes(70);
    u.repost_thold_TC9 = bytes(71);
    u.max_vol_ground_TC10 = bytes(72);
    u.ground_pres_TC11 = bytes(73);
    u.pres_delta_TC12 = bytes(74)*256 + bytes(75);
    u.avg_des_speed_TC13 = bytes(76);
    u.pres_incr_TC14 = bytes(77)*256 + bytes(78);
    u.asc_end_pres_TC15 = bytes(79);
    u.avg_asc_speed_TC16 = bytes(80);
    u.float_speed_cntr_TC17 = bytes(81);
    u.pres_speed_cntr_TC18 = bytes(82);
    u.gps_ssn_dur_TC19 = bytes(83);
    u.hyd_msg_trans_TC20 = bytes(84);
    u.delay_resetoffset_TC21 = bytes(85);
    u.duration_pump_inair_TC22 = bytes(86)*1000;
    u.coeffa_TC23 = bytes(87)*256 + bytes(88);
    u.coeffb_TC24 = bytes(89)*256 + bytes(90);

end
