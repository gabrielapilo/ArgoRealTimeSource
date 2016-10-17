% new_tech_struct(dbdat)
%
% similar to new_profile_struct, this will create an empty structure to
% ensure matching between fields when running th soloII float processing.
% not ideal but it works...

function [tech] = new_tech_struct(dbdat)

if dbdat.subtype==1018  % note - this only handles one format at present
    
    tech.GPSEndFirstDive = [];
    tech.GPSEndSurface = [];
    tech.GPSEndProfile = [];
    tech.GPSProfileAbort = [];
    tech.GPSPEndOfOperationQuit = [];
    tech.GPSEndOfSelfTest = [];
    tech.Mission = [];
    tech.MissionConfig = [];
    tech.RiseRate = [];
    tech.FallRate = [];
    tech.PumpSeries = [];
    tech.TechE0 = [];
    tech.TechE2 = [];
    tech.TechE3 = [];
    tech.TechE5 = [];
    tech.IridiumPosn = [];
    
end
