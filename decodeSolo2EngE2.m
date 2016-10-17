%==============================================================================
% SBD - SOLO2 DECODE THE ENGINEERING 0xE2 DIAGNOSTIC MESSAGE PORTION.
% -----------------------------------------------------------------------------
% Description:
%
%    ID: 0xE2 (226)
%    Ref: pp. 62-64 of "MRVUserManual_FINAL_073112-win.pdf"
%
% Input: sbdmessage (part of an sbd x-message starting with 0xe2):
%           sbdmessage                                  
%           +--+-----------------------------------------------+---+
% ...sbd... |E2|  Engineering data in normal profiling dive    | ; |  ...sbd...
%           +--+-----------------------------------------------+---+
%           98 bytes length.
% 
% Output:
%      Eng. Structure described below
%==============================================================================
function Eng = decodeSolo2EngE2(sensor)
%begin
    %Engineering returns a structure:
    Eng = [];
    
    %check ID, length and termination:
    if (isempty(sensor)  )  return; end;  %zero length message
    if (sensor(1)  ~= 226)  return; end;  %first character ID=0xE2
    if (sensor(end) ~= 59)  return; end;  %last character is ';'
    
    %invalid length message: nn=98
    nn = sensor(2)*256 + sensor(3);
    if (nn~=98) Eng = 'E2: message not 98 bytes'; return; end;
    
    %align the bytes with the manual (remove the first) 
    bytes = sensor(2:end);
    
    %decode it, p.64 of V1.2 user manual:
    Eng.Bytes                        = nn;                                                 %1-2 Number of bytes = 98 = 0x62
    Eng.MessageID                    = dec2hex(sensor(1));
    Eng.MessageVersion               = bytes(3);                                           %3 Engineering message version =3
    Eng.nPreviousPackets             = bytes(4);                                           %4 #packets sent in current surface session
    Eng.nPreviousConnectTries        = 256*bytes(5)   + bytes(6);                          %5-6 #tries to connect in previous surface session
    Eng.nPreviousReplyStatus         = 256*bytes(7)   + bytes(8);                          %7-8 parse_X_reply status in previous surface session
    Eng.nPreviousATSBDReplyStatus    = 256*bytes(9)   + bytes(10);                         %9-10 ATSBD return status in previous surface session
    Eng.nPreviousUplinkTimeSec       = 256*bytes(11)  + bytes(12);                         %11-12 EP->sattime Seconds taken in previous surface session to send all SBD messages
    Eng.VoltageCPU                   = (256*bytes(13) + bytes(14))/100;                    %13-14 DP->Vcpu = CPU battery voltage counts 0.01V
    Eng.VoltageSurfacePUMP           = (256*bytes(15) + bytes(16))/100;                    %15-16 DP->Vpmp = Pump battery counts at surface(0.01V)
    Eng.VoltageLastPUMP              = (256*bytes(17) + bytes(18))/100;                    %17-18 DP->Vple = Pump battery counts at end of last pump(0.01V)
    Eng.VacuumHgBIT                  = (256*bytes(19) + bytes(20))/100;                    %19-20 DP->Air[0] = pcase vac @end of xmit onlast dive before sink on this dive ,0.01 inHg
    Eng.VacuumHgAfterInflate         = (256*bytes(21) + bytes(22))/100;                    %21-22 DP->Air[1] = pcase vac after filling oil bladder at surface 0.01 inHg
    Eng.VacuumHgBeforeInflate        = (256*bytes(23) + bytes(24))/100;                    %23-24 DP->Air[2] = pcase vac before filling bladder at surface 0.01 inHg
    Eng.IDofLastInterruptISRID       = 256*bytes(25)  + bytes(26);                         %25-26 DP->ISRID = i.d. of last interrupt
    Eng.CurrentAveragePUMPmA         = 256*bytes(27)  + bytes(28);                         %27-28 DP->HPavgI = average pump current at bottom, LSB=1ma
    Eng.CurrentMaxPUMPmA             = 256*bytes(29)  + bytes(30);                         %29-30 DP->HPmaxI = maximum pump current at bottom, LSB=1ma
    Eng.TimePUMPBeforeSurfaceSeconds = 256*bytes(31)  + bytes(32);                         %31-32 Total seconds pumped to surface
    Eng.TimePUMPAtSurfaceSeconds     = 256*bytes(33)  + bytes(34);                         %33-34 Seconds pumped at Surface
    Eng.PressureSurfaceBeforeReset   = 0.04*(256*bytes(35)  + bytes(36))  - 10.00;         %35-36 SPRX = Surf press before resetoffset (pertains to prev dive)
    Eng.PressureSurfaceAfterReset    = 0.04*(256*bytes(37)  + bytes(38))  - 10.00;         %37-38 SPRXL = press after resetoffset (pertains to prev dive)
    Eng.PressureStartEndAscent(1)    = 0.04*(256*bytes(39)  + bytes(40))  - 10.00;         %39-40 diagP[0] = Pressure at start ascent/end ascent
    Eng.TemperatureStartEndAscent(1) = 0.001*(256*bytes(41)  + bytes(42)) - 5.000;         %41-42 diagT[0] = Temp start ascent/end ascent
    Eng.SalinityStartEndAscent(1)    = 0.001*(256*bytes(43)  + bytes(44)) - 1.000;         %43-44 diagS[0] = Salinity start ascent/end ascent
    Eng.PressureStartEndAscent(2)    = 0.04*(256*bytes(45)  + bytes(46))  - 10.00;         %45-46 diagP[1] = Last (shallowest) Pressure scan on ascent
    Eng.TemperatureStartEndAscent(2) = 0.001*(256*bytes(47)  + bytes(48)) - 5.000;         %47-48 diagT[1] = Last (shallowest) Temperature scan on ascent
    Eng.SalinityStartEndAscent(2)    = 0.001*(256*bytes(49)  + bytes(50)) - 1.000;         %49-50 diagS[1] = Last (shallowest) Salinity scan on ascent
                                                                                           %NOTE: If the HC12 board (i.e. the float )bin averages the profile [bin mode=2]
                                                                                           %diagP[1], diagT[1], and diagS[1] will be corrupted.
    Eng.SBENumberOfBadBins           = 256*bytes(51)  + bytes(52);                         %51-52 SBnbad = # bad bins from SBE
    Eng.SBENumberOfScans             = 256*bytes(53)  + bytes(54);                         %53-54 SBnscan = # scans recorded by SBE
                                                                                           %// -1 (0xffff) indicates unable to get scan count from SBE
                                                                                           %// -2 (0xfffe) indicates SBE never started so SBE didn't reset
                                                                                           %// scan count before returning an old value
    Eng.CompactedSBStatus            = 256*bytes(55)  + bytes(56);                         %55-56 Compacted SBntry,SBstrt,SBstop status (see misspec.h):
                                                                                           %((DP->SBntry&0xf)<<4) | ((DP->SBstrt&0x3)<<2) | (DP->SBstop&0x3) )
    Eng.PressureFalldbar(1)          = 0.04*(256*bytes(57) + bytes(58))  - 10.00;          %57-58 DP->P[0] = press counts before begin of FALL (LSB=.04dBar)      
    Eng.PressureFalldbar(2)          = 0.04*(256*bytes(59) + bytes(60))  - 10.00;          %59-60 DP->P[1] = press counts at end of FALL (LSB=.04dBar)
    Eng.PressureDriftdbar(1)         = 0.04*(256*bytes(61) + bytes(62))  - 10.00;          %61-62 DP->P[2] = press counts at beginning of DRIFT (LSB=.04dBar)
    Eng.PressureDriftdbar(2)         = 0.04*(256*bytes(63) + bytes(64))  - 10.00;          %63-64 DP->P[3] = press counts at end of DRIFT (LSB=.04dBar)
    Eng.PressureSurfaceEndAscend     = 0.04*(256*bytes(65) + bytes(66))  - 10.00;          %65-66 DP->P[5] = surf press counts @ end of ASCEND (LSB=.04dBar)
    Eng.PressureParkMean(1)          = 0.04*(256*bytes(67) + bytes(68))  - 10.00;          %67-68 DP->PAVG[0]=average pressure over first half of DRIFT
    Eng.TemperatureParkMean(1)       = 0.001*(256*bytes(69) + bytes(70)) - 5.000;          %69-70 DP->TAVG[0]=average temperature over first half of DRIFT
    Eng.SalinityParkMean(1)          = 0.001*(256*bytes(71) + bytes(72)) - 1.000;          %71-72 DP->SAVG[0]=average salinity over first half of DRIFT
    Eng.PressureParkMean(2)          = 0.04*(256*bytes(73) + bytes(74))  - 10.00;          %73-74 DP->PAVG[1]=average pressure over second half of DRIFT
    Eng.TemperatureParkMean(2)       = 0.001*(256*bytes(75) + bytes(76)) - 5.000;          %75-76 DP->TAVG[1]=average temperature over second half of DRIFT
    Eng.SalinityParkMean(2)          = 0.001*(256*bytes(77) + bytes(78)) - 1.000;          %77-78 DP->SAVG[1]=average salinity over second half of DRIFT
    Eng.TimeOpenValveToSinkSeconds   = 256*bytes(79) + bytes(80);                          %79-80 DP->fall_time = seconds from open air valve to end of settle
    Eng.VelocityDescentRatemmsec     = 256*bytes(81) + bytes(82);                          %81-82 DP->fall rate = avg mm/sec while sinking
    Eng.TimeFirstSeekSeconds         = 0.1*(256*bytes(83) + bytes(84));                    %83-84 DP-> SeekT = tenths seconds in 1st settle to drift
                                                                                           %SOLOII X Messages SOLO2_Xformat_v1.2_20Dec11 8/17/12 Page 8 of 10
    Eng.PressureFirstSeekdBars       = 0.1*signed16(256*bytes(85) + bytes(86));            %85-86 DP-> SeekP = change of depth (signed 0.1 dbar in 1st settle)
    Eng.FlagsException               = 256*bytes(87) + bytes(88);                          %87-88 exception flags (can be added)
                                                                                           %0x0001 Valve failed to open
                                                                                           %0x0002 Valve failed to close
                                                                                           %0x0004 Questionable pressure
                                                                                           %0x0008 Antenna was toggled
                                                                                           %0x0010 Antenna switch failure. (no satellites even after toggling)
                                                                                           %0x0020 GPS communication error (cannot talk to GPS unit)
                                                                                           %0x0080 Float took too long to leave the surface. (toggled valve)
                                                                                           %0x1000 Valve failure during Sink phase of mission
                                                                                           %0x2000 Valve failure during Ascend phase of mission
    Eng.VentMotorRunTimeSeconds      = 0.1*bytes(89);                                      %89 vent data; # 0.1 seconds vent motor ran
    Eng.VentLLDStatus                = bytes(90);                                          %90 vent data; LLD status before and after vent ran
    Eng.PressureOffset800            = 0.04*(256*bytes(91) + bytes(92)) - 10.00;           %91-92 SBE P offset(*800)
    Eng.TimePumpedToDepthSeconds     = (256*bytes(93) + bytes(94))/10;                     %93-94 PP->SeekSc; tenths of seconds pumped to target depth
    Eng.nPacketsToSendThisCycle      = 256*bytes(95) + bytes(96);                          %95-96 Number of Packets sent in previous cycle
    Eng.Terminator                   = char(bytes(97));                                    %97 ; terminator
    
end











