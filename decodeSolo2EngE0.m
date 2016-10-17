%==============================================================================
% SBD - SOLO2 DECODE THE ENGINEERING 0xE0 DIAGNOSTIC MESSAGE
% -----------------------------------------------------------------------------
% Engineering 0xe0 (224) 
% Diagnostic data in first diagnostic dive at start of mission
%
% pp. 5 of V1.2.pdf -manual pages
%==============================================================================
function Eng = decodeSolo2EngE0(sensor)
%begin
    %pressure decoding, returns vector:
    Eng = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) ~= 224)  return; end;

    %remove the first byte to match sequence with table indices on page 55:
    b = sensor;
    
    %number of bytes = 76
    n = b(2)*256 + b(3);
    if (n~=76) Eng = 'E0: message not 76 bytes'; return; end;
    
    %decode the message:
    %0 ID/Mission phase = 0xe0
    Eng.Bytes                       = n;                                %1-2 Number of bytes = 76= 0x4c
    Eng.Version                     = b(4);                             %3 Engineering message version =3
    Eng.nPackets                    = b(5);                             %4 #packets in current session
    Eng.Dummy                       = b(6:11);                          %5-10 0 (dummy filler)
    Eng.EP_SatTime                  =  256*b(12) + b(13);               %11-12 EP -> sattime to send previous messages
    Eng.DP_VoltageCPU               = (256*b(14) + b(15))*0.01;         %13-14 DP->Vcpu = CPU battery voltage counts 0.01V
    Eng.DP_VoltagePump              = (256*b(16) + b(17))*0.01;         %15-16 DP->Vpmp = Pump battery counts at surface(0.01V)
    Eng.DP_VoltageLastPump          = (256*b(18) + b(19))*0.01;         %17-18 DP->Vple = Pump battery counts at end of last pump(0.01V)
    Eng.BT_VacuumHg                 = (256*b(20) + b(21))*0.01;         %19-20 BTvac = BIT vacuum in 0.01 inHg
    Eng.DP_VacuumAfterHg            = (256*b(22) + b(23))*0.01;         %21-22 DP->Air[1] = vac after filling bladder at surface 0.01 inHg
    Eng.DP_VacuumBeforeHg           = (256*b(24) + b(25))*0.01;         %23-24 DP->Air[2] = vac before filling bladder at surface 0.01 inHg
    Eng.DP_IDRID                    =  256*b(26) + b(27);               %25-26 DP->ISRID = i.d. of last interrupt
    Eng.DP_HPavgImA                 = (256*b(28) + b(29))*1;            %27-28 DP->HPavgI = average pump current at bottom, LSB=1ma
    Eng.DP_HPmaxImA                 = (256*b(30) + b(31))*1;            %29-30 DP->HPmaxI = maximum pump current at bottom, LSB=1ma
    Eng.TotalPumpTimeSeconds        = (256*b(32) + b(33))*1;            %31-32 Total seconds pumped to surface
    Eng.SurfacePumpTimeSeconds      = (256*b(34) + b(35))*1;            %33-34 Seconds pumped at Surface
    Eng.DP_SurfacePressureEndAscend = (256*b(36) + b(37))*0.04  - 10;   %35-36 DP->P[5] = surf press counts @ end of ASCEND (LSB=.04dBar)
    Eng.DP_SurfacePressureSPRXprev  = (256*b(38) + b(38))*0.04  - 10;   %37-38 SPRX = Surf press before resetoffset (pertains to prev dive)
    Eng.DP_SurfacePressureSPRXLprev = (256*b(40) + b(41))*0.04  - 10;   %39-40 SPRXL = press after resetoffset (pertains to prev dive)
    Eng.Pdiag_SensedInWater         = (256*b(42) + b(43))*0.04  - 10;   %41-42 diagP[0] = Press when "in water" sensed
    Eng.Tdiag_SensedInWater         = (256*b(44) + b(45))*0.001 -  5;   %43-44 diagT[0] = Temp when "in water" sensed
    Eng.Sdiag_SensedInWater         = (256*b(46) + b(47))*0.001 -  1;   %45-46 diagS[0] = Salinity when "in water" sensed
    Eng.SBEnscans                   = (256*b(48) + b(49));              %47-48 SBnscan = # scans recorded by SBE
                                                                        %// -1 (0xffff) indicates unable to get scan count from SBE
                                                                        %// -2 (0xfffe) indicates SBE never started so SBE didn't reset
                                                                        %// scan count before returning an old value
    Eng.DP_SBstatus                 = (256*b(50) + b(51));              %49-50 Compacted SBntry,SBstrt,SBstop status (see misspec.h):
                                                                        %((DP->SBntry&0xf)<<4) | ((DP->SBstrt&0x3)<<2) | (DP->SBstop&0x3) )
    Eng.Pdiag_Shallowest            = (256*b(52) + b(53))*0.04  - 10;   %51-52 diagP[1] = Shallowest press in profile
    Eng.Tdiag_Shallowest            = (256*b(54) + b(55))*0.001 -  5;   %53-54 diagT[1] = Shallowest Temp in profile
    Eng.Sdiag_Shallowest            = (256*b(56) + b(57))*0.001 -  1;   %55-56 diagS[1] = Shallowest Salinity in profile
                                                                        %NOTE: See NOTE for diagP[1],T[1],S[1] under 0xe2
    Eng.BIT_Vacuum2Hg               = (256*b(58) + b(59))*0.01;         %57-58 BTvac = BIT vacuum in 0.01 inHg
    Eng.BIT_PumpCurrentmA           = (256*b(60) + b(61))*1;            %59-60 BTPcur = BIT motor current OUT, LSB=1mA
    Eng.BIT_PumpTimeSeconds         = (256*b(62) + b(63))*1;            %61-62 BTPsec = BIT Pump seconds
    Eng.BIT_PumpVacuumBeginTest     = b(64);                            %63 BTPvac[0] = BIT Pump vacuum at beginning of test, before pumping
    Eng.BIT_PumpVacuumAfterTest     = b(65);                            %64 BTPvac[1] = BIT Pump vacuum after pumping
    Eng.BIT_VoltageLastPump         = (256*b(66) + b(67))*0.01;         %65-66 BTVple = BIT pump batt 0.01V
    Eng.BIT_VoltageCPU              = (256*b(68) + b(69))*0.01;         %67-68 BTVcpu= BIT CPU batt 0.01V
    Eng.FlagsException              =  256*b(70) + b(71);               %69-70 exception flags
                                                                        %SOLOII X Messages SOLO2_Xformat_v1.2_20Dec11 8/17/12 Page 7 of 10
    Eng.VentTimeSeconds             = b(72)*0.1;                        %71 vent data; MSB=#0.1 seconds vent motor ran
    Eng.VentStatusLLD               = b(73);                            %72 LSB LLD status before/after vent ran
    Eng.AbortCode                   = 256*b(74) + b(75);                %73-74 AbrtCd = code for what caused abort_miss
    Eng.Terminator                  = b(76);                            %75 ; terminator character
end






