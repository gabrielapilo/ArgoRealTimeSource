%==============================================================================
% SBD - SOLO2 DECODE THE ARGO DATA MESSAGE
% -----------------------------------------------------------------------------
%
% ID: 'f0'=240   After each dive, specific dive information for creating the 
%                PHY file for the ARGO community is sent. Dive information for 
%                creating the PHY file. Mission configuration information.
%
% pp. 51,70:     Reference: "MRVUserManual_FINAL_073112-win.pdf"
%
% Revisions:     11 October 2012 (Created)
% coded by Vito Dirita, adapted by AT October 2013
%==============================================================================
function Mission = decodeSolo2Mission(sensor)
%begin
    %returns a structure:
    Mission = [];
    if (isempty(sensor))      return; end;   %no data
    if (sensor(1) ~= 240)     return; end;   %first byte=240
    if (sensor(end) ~= 59)    return; end;   %last byte=';' or 59
    if (length(sensor)~=25)   return; end;   %exactly 23 bytes message

    %remove the first byte to match sequence with table indices on page 55:
    bytes = sensor(2:end);
    
    %decode the message:
    Mission.ConfigDataVersion            = bytes(3);                    %typically = 1
    Mission.ConfigDeepProfilePressure    = 256*bytes(4)  + bytes(5);    %typically = 2000 (dbars)
    Mission.ConfigParkPressure           = 256*bytes(6)  + bytes(7);    %typically = 2000 (dbars)
    Mission.ConfigAscentTimeoutMinutes   = 256*bytes(8)  + bytes(9);    %typically = 500 (minutes) --> ascent timeout
    Mission.ConfigParkDescentTimeMinutes = 256*bytes(10) + bytes(11);   %typically = 400 (minutes) --> ascent timeout
    Mission.ConfigDeepDescentTimeMinutes = 256*bytes(12) + bytes(13);   %typically = 400 (minutes) --> ascent timeout
    Mission.ConfigDownTimeMinutes        = 256*bytes(14) + bytes(15);   %typically = 13260 (minutes) --> down time in minutes
    Mission.ConfigAscentRate             = 256*bytes(16) + bytes(17);   %typically = 7-11 (cm/sec) --> ascent rate cm/sec
    Mission.ConfigMaxSeeks               = 256*bytes(18) + bytes(19);   %typically > 1 (number of seeks ?)
    Mission.ConfigUpTimeMinutes          = 256*bytes(19) + bytes(20);   %typically = 300 (minutes) --> up time in minutes
    
end

