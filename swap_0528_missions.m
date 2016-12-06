% swap_0528_missions
% 
% called when dbdat.wmo_id==5905023
% changes missions automatically depending on profile number to change time
% of day and profile depth
% 
% usage:
% function swap_0528_mission(pn)
% 
% where pn==profile number
% 

function swap_0528_missions(pn)
global ARGO_SYS_PARAM;

if mod(pn,6)==0  % profile divisible by 6 (every 3rd mission swap)
    % swap in mission 3
system(['cp ' ARGO_SYS_PARAM.rudics_server '/f0528/mission_3_f0528_4d5hr_2000_midnight.cfg ' ARGO_SYS_PARAM.rudics_server '/f0528/mission.cfg'])
system(['cp ' ARGO_SYS_PARAM.secondary_server '/f0528/mission_3_f0528_4d5hr_2000_midnight.cfg ' ARGO_SYS_PARAM.secondary_server '/f0528/mission.cfg'])
elseif mod(pn,2) % odd number profile
%     swap in mission 2
system(['cp ' ARGO_SYS_PARAM.rudics_server '/f0528/mission_2_f0528_12hr_500_midnight.cfg ' ARGO_SYS_PARAM.rudics_server '/f0528/mission.cfg'])
system(['cp ' ARGO_SYS_PARAM.secondary_server '/f0528/mission_2_f0528_12hr_500_midnight.cfg' ARGO_SYS_PARAM.secondary_server '/f0528/mission.cfg'])

else %even number profile
%     swap in mission 1
system(['cp ' ARGO_SYS_PARAM.rudics_server '/f0528/mission_1_f0528_4d5_500_noon.cfg ' ARGO_SYS_PARAM.rudics_server '/f0528/mission.cfg'])
system(['cp ' ARGO_SYS_PARAM.secondary_server '/f0528/mission_1_f0528_4d5_500_noon.cfg ' ARGO_SYS_PARAM.secondary_server '/f0528/mission.cfg'])
end



