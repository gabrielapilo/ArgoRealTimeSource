% addNke2Iridium
%
% takes the decoded Iridium position and timing information obtained from the mails and puts it in
% a struture which will be stored later with the other technical data
%
% this is a script because the data is not in a structure to begin with: AT June 2017 by uday
%

tech.Lat = iridium_lat(kkl);
tech.Lon = iridium_lon(kkl);
tech.CEP = iridiumCEP(kkl);
tech.Msgno = msgno(kkl);
tech.jday_iridium = jday(kkl);
tech.Status = statt(kkl);
