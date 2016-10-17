%==============================================================================
% SBD - SOLO2 DECODE THE ENGINEERING 0xE0 DIAGNOSTIC MESSAGE
% -----------------------------------------------------------------------------
% Engineering 0xe3 (227) 
%       ID=0xe3, Engineering message following mission abort
%
% pp. 8 of V1.2.pdf -manual pages
%==============================================================================
function Eng = decodeSolo2EngE3(sensor)
%begin
    %pressure decoding, returns vector:
    Eng = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) ~= 227)  return; end;

    %remove the first byte to match sequence with table indices on page 55:
    b = sensor;
    
    %number of bytes = 76
    n = b(2)*256 + b(3);
    if (n~=30) Eng = 'E3: message not 30 bytes'; return; end;
    
    %decode message:
                                                                %0 ID/Mission phase = 0xe3
    Eng.Bytes                    = n;                           %1-2 Number of bytes = 30 = 0x1e
    Eng.Version                  = b(4);                        %Engineering message version =3
    Eng.nPackets                 = b(5);                        %4 #packets sent in current surface session
    Eng.nConnectTriesLast        =  256*b(6) + b(7);            %5-6 #tries to connect in last surface session
    Eng.parseXreplyLast          =  256*b(8) + b(9);            %7-8 parse_X_reply status in last surface session
    Eng.ATSBDstatusLast          =  256*b(10) + b(11);          %9-10 ATSBD return status in last surface session
    Eng.TimeTransmittLastSeconds =  256*b(12) + b(13);          %11-12 Seconds taken in sending last SBD message
    Eng.VoltageCPULatest         = (256*b(14) + b(15))*0.01;    %13-14 current CPU battery voltage counts 0.01V
    Eng.VoltagePumpLatest        = (256*b(16) + b(17))*0.01;    %15-16 current pump battery counts 0.01V
    Eng.DP_VacuumAfterPrevTxHg   = (256*b(18) + b(19))*0.01;    %17-18 DP->Air[0] = pcase vacuum just after previous xmit 0.01inHg
    Eng.DP_VacuumBeforeFillOilHg = (256*b(20) + b(21))*0.01;    %19-20 DP->Air[1] = pcase vacuum before filing oil bladder at surface 0.01 inHg
                                                                %21-22 ?
    Eng.DP_ISRIDlast             =  256*b(24) + b(25);          %23-24 DP->ISRID = i.d. of last interrupt
    Eng.AbortCode                =  256*b(26) + b(27);          %25-26 AbrtCd = code for what caused abort_miss
                                                                %0 = no error
                                                                %1 = current time is later than RTCabort
                                                                %2 = unable to WakeOST
                                                                %3 = unable to send Dive number to SOLO II (LOdiveNo)
                                                                %4 = Iridium ground station commanded to go to abort
                                                                %5 = FnlDiv was completed. Mission is done
                                                                %6 = Diagnostic dive failed to get GPS fix, pressure never>dBarGo, or unable to send message to Iridium
                                                                %7 = pressure sensor failure
                                                                
                                                                %27-28 Empty
    Eng.Terminator               = b(30);                       %29 ; terminator
    
end

