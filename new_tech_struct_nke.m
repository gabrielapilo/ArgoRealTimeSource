% new_tech_struct(dbdat)
%
% similar to new_profile_struct, this will create an empty structure to
% ensure matching between fields when running th soloII float processing.
% not ideal but it works...

function [tech] = new_tech_struct(dbdat)

if dbdat.subtype==1024  % note - this only handles one format at present
    
    tech.TechPkt1Info = [];
    tech.TechPkt2Info = [];
    tech.ParamN1PktInfo = [];
    tech.HydraulicPktInfo = [];
    tech.ParamN2PktInfo = [];
    tech.IridiumPosn = [];
end
