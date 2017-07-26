%=================================================================================
%SBD - ARVOR-I FLOAT PARAMETER PACKET (Type=6)
% --------------------------------------------------------------------------------
% Packet type Code: 0x06
% This message contains float's Hydraulic information
%
% Reference:
%         pp. 27,28: "Arvor-i flaot user manual, NKE instrumentation"
%==================================================================================
function u = decodeHydraulicPktTyp6(sensor)
%begin 
    %first byte==1 gives the packet type information:
    u = [];
    if (isempty(sensor))   return; end;
    if (sensor(1) > 14)     return; end;
    if (length(sensor)<100) return; end;

    %prepare an empty output structure:
      u.type = [];
      u.profile_number = [];
      u.cyc_bgn_rel_day = [];
      u.cyc_bgn_hour = [];
      u.hyd_act_type = [];
      u.hyd_act_hour = [];
      u.hyd_act_pres = [];
      u.hyd_act_dur = [];



    %remove the first byte to match sequence with table indices on page 55:
    bytes = sensor(1:end);

    %General information
    %byte-2&3: cycle number
    u.type = bytes(1);
    u.profile_number = bytes(2)*256 + bytes(3);
    u.cyc_bgn_rel_day = bytes(4)*256 + bytes(5);
    u.cyc_bgn_hour = bytes(6)*256 + bytes(7)
    %Actions during cycle (except)
    j = 1;
    for i=8:7:98
    u.hyd_act_type(j) = bytes(i);
    u.hyd_act_hour(j) = bytes(i+1)*256 + bytes(i+2);
    u.hyd_act_pres(j) = bytes(i+3)*256 + bytes(i+4);
    u.hyd_act_dur(j) = (bytes(i)+5*256 + bytes(i+6))-1280;
    j = j+1;
    end
end
