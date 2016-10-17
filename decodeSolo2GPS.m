%=================================================================================
% SBD - SOLO2 DECODE THE X-01 GPS MESSAGE:
% --------------------------------------------------------------------------------
% SENSOR ID Code: 0x01-0x05 (ALL GPS DATA FORMATS)
% GPS 0x01 Fix at before leaving surface in Surface Drift
%
% Reference:
%         pp. 53,55,56: "MRVUserManual_FINAL_073112-win.pdf"
% Example:
%           ID                                                                  ';'
%   sensor=[ 1 0 24 2 230 112 28 132 87 209 217 23 6 167 1 5 17 5 6 35 39 47 20 59]
%==================================================================================
function u = decodesolo2GPS(sensor)
%begin 
    %first byte==1,2,3,4,5 ARE ALL GPS FIXES At different times:
    u = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) > 5)     return; end;
    if (length(sensor)<24) return; end;
    
    %prepare an empty output structure:
    u.ValidFix           = false;
    u.Latitude           = [];
    u.Longitude          = [];
    u.Date               = '';
    u.DayOfWeek          = [];
    u.Time               = '';
    u.AquisitionTime     = [];
    u.NumberOfSatellites = [];
    u.PowerLevelMindB    = [];
    u.PowerLevelAvedB    = [];
    u.PowerLevelMaxdB    = [];
    u.HorizonalDilution  = [];
    
    %remove the first byte to match sequence with table indices on page 55:
    bytes = sensor(2:end);
    %disp(bytes)    
    
    %byte-3:
    if (bytes(3)== 0)  
        u.ValidFix=false;
    else
        u.ValidFix=true;
        if bytes(3)==2
            sgn=+1;
        else
            sgn=-1;
        end
    end;   %invalid fix
%     if (bytes(3)==-2)  u.ValidFix=true;  sgn=-1;  end;   %west 
%     if (bytes(3)== 2)  u.ValidFix=true;  sgn=+1;  end;   %east 
        
    %byte-4:7 signed latitude:
    y=2147483648;
    u.Latitude = bytes(4)*256^3 + bytes(5)*256^2 + bytes(6)*256 + bytes(6);
    if (u.Latitude > y) u.Latitude = (u.Latitude - 2*y)/1e7; else u.Latitude=u.Latitude/1e7; end;
    
    %byte-8:11 signed longitude:
    y=2147483648;
    u.Longitude = bytes(8)*256^3 + bytes(9)*256^2 + bytes(10)*256 + bytes(11);
    if (u.Longitude > y) u.Longitude = (u.Longitude - 2*y)/1e7; else u.Longitude=u.Longitude/1e7; end;

    %byte-12:13 MS byte of GPS week + LS byte
    days   = 7*(256*bytes(12) + bytes(13));                   %number of days since first gps epoch    
    
    %byte-15: hour, byte-16:minutes
    u.DayOfWeek = bytes(14);
    u.Time      = sprintf('%02d:%02d:00', bytes(15), bytes(16)); 
    dnum   = days + u.DayOfWeek + datenum('06/01/1980', 'dd/mm/yyyy');  %first GPS epoch date (definition) whole days only
    u.Date = datestr(dnum, 'dd/mm/yyyy');                     %dnum is whole days no integer part
   
    %byte-17: aquisition time in seconds:
    u.AquisitionTime = bytes(17)*10;
    
    %byte-18: number of satellites:
    u.NumberOfSatellites = bytes(18);
    
    %byte-19:21: signal power level (min, average, max)
    u.PowerLevelMindB = bytes(19);
    u.PowerLevelAvedB = bytes(20);
    u.PowerLevelMaxdB = bytes(21);
    
    %byte-22: horizontal dilution of precision:
    u.HorizonalDilution = bytes(22)/10;
    
    %byte-23: ';' dont checkit
    
    %optional line decoding display:    
    %disp(u) 
    format = 'GPS:  [%s  %s]   Lat:%0.4f  Lon:%0.4f  T-Aquisition:%0.0f  Sat:%d  AvePowerdB:%d \n';
   % fprintf(format, u.Date, u.Time, u.Latitude, u.Longitude, u.AquisitionTime, u.NumberOfSatellites, u.PowerLevelAvedB);
    
end










