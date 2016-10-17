%==============================================================================
% SBD - SOLO2 DECODE THE ASCII DUMP OF MISSION CONFIG PARAMETERS
% -----------------------------------------------------------------------------
%
% ID: 'd0-df'=208-223   Mission EEPROM Dump / Parameter configuration information
%
% Reference:     V1.2.pdf, page.9
%
% Revisions:     15 November 2012 (Created)
%==============================================================================
function Mission = decodeSolo2Config(sensor)
%begin
    %returns a structure:
    Mission = [];
    if (isempty(sensor))      return; end;   %no data
    if (sensor(1)<208 && sensor(1)>223)     return; end;   %first byte=240

    %number of values in block:
    nn = 256*sensor(2) + sensor(3);
    N  = (nn-4)/15;
 
    %15 byte increments give vector of data:
    for j=1:N
        k = (j-1)*15 + 4;  %start index for depth,
        Config(j) = {char(sensor(k:k+14))};
    end
    
    %up to four different types of config data blocks:
    if (sensor(1)==208) Mission.Config01 = Config; end;
    if (sensor(1)==209) Mission.Config02 = Config; end;
    if (sensor(1)==210) Mission.Config03 = Config; end;
    if (sensor(1)==211) Mission.Config04 = Config; end;
    
    %add more ...
end