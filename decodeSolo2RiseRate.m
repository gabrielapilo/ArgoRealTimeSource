%==============================================================================
% SBD - SOLO2 DECODE THE ENGINEERING 0xE0 DIAGNOSTIC MESSAGE
% -----------------------------------------------------------------------------
%
% Engineering 0x50 Rise Rate and Fall Rate (40x) same format
%
% ID: 0x50
% pp. 54,56 of "MRVUserManual_FINAL_073112-win.pdf"
%
% Ex:  0x50    --n--
%       16     0   7     1     0   250    59
%
%  Vito Dirita - 2012, adapted by AT 2013
%==============================================================================
function RiseRate = decodeSolo2RiseRate(sensor)
%begin
    %pressure decoding, returns vector:
    RiseRate = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) ~= 80 && sensor(1) ~= 64)   return; end;

    %remove the first byte to match sequence with table indices on page 55:
    b = sensor;
    
    %returns single vector:
    %fprintf('Rise Rate 0x50 \n')
    
    %number of samples
    n  = b(2)*256 + b(3);  %message length:
    np = (n-8)/4;          %number of depth rise points:
    
    %check message length:
    if (length(b)~=n) disp('solo2_decodeRiseRate():: Error in message length'); end;
        
    %decode the message:
    seconds                   = b(4)*256^3 + b(5)*256^2 + b(6)*256 + b(7);
    RiseRate.StartTimeSeconds = seconds;
    RiseRate.StartTimeDate    = datenum('01/01/2000', 'dd/mm/yyyy') + seconds/86400;
    RiseRate.StartTimeDate    = datestr(RiseRate.StartTimeDate, 'dd/mm/yyyy HH:MM:SS');
    
 
    %repeat for each pressure reference point:
    for j=1:np
      b4 = b(j*4+4:j*4+7);                      %get 4 bytes [t t p p]
      t  = 256*b4(1) + b4(2);                   %seconds timer
      p  = 256*b4(3) + b4(4);                   %pressure value
      if (p==65535) p=nan; end;                 %invalid pressure reading
      RiseRate.TimeSeconds(j) = t;              %time in seconds
      RiseRate.Pressure(j)    = 0.04*p - 10;    %depth in dbars
    end

end

