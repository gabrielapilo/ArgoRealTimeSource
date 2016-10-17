%==============================================================================
% SBD - SOLO2 DECODE THE ENGINEERING 0xE0 DIAGNOSTIC MESSAGE
% -----------------------------------------------------------------------------
% Engineering 0xe5 (229) 
%       ID=0xe5, Engineering message following BITest
%
% pp. 8 of V1.2.pdf -manual pages
%==============================================================================
function Eng = decodeSolo2EngE5(sensor)
%begin
    %pressure decoding, returns vector:
    Eng = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) ~= 229)  return; end;

    %remove the first byte to match sequence with table indices on page 55:
    b = sensor;
    
    %number of bytes = 76
    n = b(2)*256 + b(3);
    if (n~=58) Eng = 'E5: message not 58 bytes'; return; end;
    
    %decode message:
    Eng.Bytes                    = n;                                 %1-2 Number of bytes = 76= 0x4c
    Eng.Version                  = b(4);                              %3 Engineering message version =3
    Eng.nPackets                 = b(5);                              %4 #packets sent in this surface session
    Eng.Poffsetdbars             = (256*b(6)  +  b(7))*0.04 - 10;     %5-6 SBE P Offset(*800)
    Eng.VoltageCPU               = (256*b(8)  +  b(9))*0.01;          %7-8 CPU battery voltage 0.01 V
    Eng.VoltageNoLoad            = (256*b(10) + b(11))*0.01;          %9-10 no load pump battery voltage 0. 01 V
                                                                      %SOLOII X Messages SOLO2_Xformat_v1.2_20Dec11 8/17/12 Page 9 of 10
    Eng.VoltagePumpLast          = (256*b(12) + b(13))*0.01;          %11-12 pump battery voltage counts at end of last pump (0.01V)
    Eng.DP_HPavglmA              = (256*b(14) + b(15));               %13-14 DP->HPavgl = average pump current at bottom, LSB=1ma
    Eng.TimeTestPumpSeconds      = (256*b(16) + b(17));               %15-16 seconds pumped out during test
    Eng.VacuumOilBeforeBladderHg = (256*b(18) + b(19))*0.01;          %17 Oil vacuum before filling bladder 0.01inHG
    Eng.VacuumOilAfterBladderHg  = (256*b(20) + b(21))*0.01;          %18 Oil vacuum after filling bladder 0.01 inHG
    Eng.VacuumAtStartTestHg      = (256*b(20) + b(21))*0.01;          %19-20 Pcase Vacuum at beginning of test. (Oil Bladder Empty) 0.01 inHg
    Eng.VacuumBeforeTxHg         = (256*b(22) + b(23))*0.01;          %21-22 Pcase Vacuum just before xmit with air bladder inflated. 0.01 inHg
    Eng.nOpenValveTries          =  b(24);                            %23 Number of tries needed to open valve
    Eng.nCloseValveTries         =  b(25);                            %24 Number of tries to close valve
    Eng.IDRID                    =  256*b(26) + b(27);                %25-26 i.d. of last interrupt
    Eng.SBEstring                =  char(b(28:57));                   %27-56 string returned from SBE pt command
    Eng.Terminator               = b(58);                             %57 ; terminator
    
end

