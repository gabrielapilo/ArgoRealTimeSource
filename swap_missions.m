% swap_missions
% 
% called for bio-argo floats with mission swapping in the following regime:
% M1 M2 M1 M2 M3 M2 over a 
% changes missions automatically depending on profile number to change time
% of day and profile depth
% 
% usage:
% function swap_missions(pn)
% 
% where pn==profile number
% where fn==float hull number as text string eg: '0527'

function swap_missions(pn,fn)
global ARGO_SYS_PARAM;

if mod(pn,6)==0  % profile divisible by 6 (every 3rd mission swap)
    % swap in mission 3
    system(['cp ' ARGO_SYS_PARAM.rudics_server '/f' fn '/mission_3.cfg ' ...
        ARGO_SYS_PARAM.rudics_server '/f' fn '/mission.cfg'])
    system(['cp ' ARGO_SYS_PARAM.secondary_server '/f' fn '/mission_3.cfg ' ...
        ARGO_SYS_PARAM.secondary_server '/f' fn '/mission.cfg'])
elseif mod(pn,2)==1 % odd number profile
    %     swap in mission 2
    system(['cp ' ARGO_SYS_PARAM.rudics_server '/f' fn '/mission_2.cfg ' ...
        ARGO_SYS_PARAM.rudics_server '/f' fn '/mission.cfg'])
    system(['cp ' ARGO_SYS_PARAM.secondary_server '/f' fn '/mission_2.cfg ' ...
        ARGO_SYS_PARAM.secondary_server '/f' fn '/mission.cfg'])
    
else %even number profile
    %     swap in mission 1
    system(['cp ' ARGO_SYS_PARAM.rudics_server '/f' fn '/mission_1.cfg ' ...
        ARGO_SYS_PARAM.rudics_server '/f' fn '/mission.cfg'])
    system(['cp ' ARGO_SYS_PARAM.secondary_server '/f' fn '/mission_1.cfg ' ...
        ARGO_SYS_PARAM.secondary_server '/f' fn '/mission.cfg'])
end



