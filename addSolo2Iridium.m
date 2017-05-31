% addSolo2Iridium
%
% takes the decoded Iridium position and timing information and puts it in
% a struture which will be stored later with the other technical data
%
% this is a script because the data is not in a structure to begin with: AT November 2013
%

tech.Lat = iridium_lat(kkl);
tech.Lon = iridium_lon(kkl);
tech.CEP = iridiumCEP(kkl);
tech.Msgno = msgno(kkl);
tech.jday_iridium = jday(kkl);
tech.Status = statt(kkl);

