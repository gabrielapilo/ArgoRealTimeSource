%used to regenerate technical, trajectory or metadata files:
%comment out what you don't need to produce...
clear all

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

getdbase(0);
count = 0; %using this to just do 5 floats.

%% ARGOS
for ii = 1:length(THE_ARGO_FLOAT_DB)
    %testing the creation of iridium traj files
    if THE_ARGO_FLOAT_DB(ii).iridium == 1
        continue
    end
%     if THE_ARGO_FLOAT_DB(ii).wmo_id ~= 5901166
%         
%         continue
%     end
    
    clear traj traj_mc_order
    
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);

    if ~isempty(fpp)
        %load the traj mat file just once:
        tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(THE_ARGO_FLOAT_DB(ii).wmo_id)];
        if exist([tfnm '.mat'],'file');
            load(tfnm);
        else
            traj = [];
        end
                
        if exist('traj','var') == 1
            %rebuild all the traj files, and recreate the netcdf files
            disp(['Building traj: ' num2str(THE_ARGO_FLOAT_DB(ii).wmo_id)])
            load_float_to_traj(THE_ARGO_FLOAT_DB(ii).wmo_id,1)
        end
    end
end

