%==============================================================================
% SBD - SOLO2 DECODE THE PUMP SERIES DATA MESSAGE
% -----------------------------------------------------------------------------
%
% Engineering 0x50 Rise Rate and Fall Rate (40x) same format
%
% ID: 0x60
% pp. 5 of Manual: V1.2.pdf
%
% Ex:  0x50    --n--
%       16     0   7     1     0   250    59
%==============================================================================
function RiseRate = decodesolo2PumpSeries(sensor)
%begin
    %pressure decoding, returns vector:
    RiseRate = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) ~= 96)   return; end;

    %remove the first byte to match sequence with table indices on page 55:
    nn = 256*sensor(2) + sensor(3);
    N  = (nn-4)/10;
    
    %fprintf('Pump Series 0x60 \n')
    %10 byte increments give vector of data:
    for j=1:N
        k    = (j-1)*10 + 4;  %start index for depth,
        Pres = 256*sensor(k) + sensor(k+1);
        if (Pres==65535) Pres=nan; end;
        RiseRate.Pressure(j)     = 0.04*Pres - 10;
        RiseRate.TimeSeconds(j)  = (256*sensor(k+2) + sensor(k+3))*1;
        RiseRate.Voltage(j)      = (256*sensor(k+4) + sensor(k+5))*0.01;
        RiseRate.CurrentmA(j)    = (256*sensor(k+6) + sensor(k+7))*1;
        RiseRate.VacuumAfter(j)  = (sensor(k+8))*1;
        RiseRate.VacuumBefore(j) = (sensor(k+9))*1;
    end
end
