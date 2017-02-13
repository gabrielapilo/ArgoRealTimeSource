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

%% Iridium
for ii = 1:length(THE_ARGO_FLOAT_DB)
    %testing the creation of iridium traj files
    if isempty(strmatch('9i',THE_ARGO_FLOAT_DB(ii).controlboardnumstring))
        continue
    end
    if THE_ARGO_FLOAT_DB(ii).wmo_id ~= 1901160
        
        continue
    end
    
    clear traj traj_mc_order
    
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    %quick and dirty check to avoid the EM floats. 
    if dbdat.subtype == 9999
        disp(['EM FLOAT!: ' num2str(dbdat.wmo_id)])
%         pause
        continue
    end
    if ~isempty(fpp)
        %construct a location for the log files that have been processed
        floc = [ARGO_SYS_PARAM.iridium_path 'iridium_processed/' ...
            num2str(THE_ARGO_FLOAT_DB(ii).wmo_id) '/'];
        
        % get the file metadata information
        pmeta.wmo_id = THE_ARGO_FLOAT_DB(ii).wmo_id;
        not_last = 1;
        %load the traj mat file just once:
        tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(pmeta.wmo_id)];
        if exist([tfnm '.mat'],'file');
            load(tfnm);
        else
            traj = [];
        end
        
        if length(fpp) - 10 > 0
            strt = length(fpp) - 10;
        else
            strt = 1;
        end
        for j=strt:length(fpp)
            pn = '000';
            pns = num2str(j);
            pn(end-length(pns)+1:end) = pns;
            pmeta.ftp_fname = [num2str(dbdat.argos_id) '.' pn '.log'];
            pmeta.pn = j;
            
            if j == length(fpp)
                not_last = 0;
            end
            % create the netcdf and matlab trajectory files.
            disp(['WMO: ' num2str(pmeta.wmo_id) ', pn: ' num2str(pmeta.pn)])
%             try
            traj = load_traj_apex_iridium(traj,pmeta,pmeta.pn,dbdat,fpp,floc); %for iridium floats
%             [traj,traj_mc_order] = load_traj_apex(traj,pmeta,dbdat,fpp,not_last,floc); % for argos floats
%             catch Me
%                 %open a file to write the message out for later checking
%                 fid = fopen('traj_runtime_errors.txt','a');
%                  msg = getReport(Me,'extended','hyperlinks','off');
%                 fprintf(fid,'%s\n',[num2str(pmeta.wmo_id) ',' pmeta.ftp_name]);
%                 fprintf(fid,'%s\n',msg);
%                 fprintf(fid,'%s\n','%_______________________');
%                 fclose(fid);               
%             end
        end
        
        if exist('traj','var') == 1
            if ~isempty(traj)
                %now save the traj mat file:
%                 save(tfnm,'traj','traj_mc_order') %for Argos Floats
                save(tfnm,'traj') %for iridium floats
                
%                 count = count+1;
%                 if count == 6
%                     return
%                 end
            end
            
            %do this after we have created all the traj mat files.
            %One netcdf file is created for each float.
            %!!Let's make 5 traj mat files up, then troubleshoot the netcdf
            %creation:
%             try
                trajectory_iridium_nc(dbdat,fpp,traj)
%             catch Me
%                 %open a file to write the message out for later checking
%                 fid = fopen('traj_runtime_errors.txt','a');
%                 msg = getReport(Me,'extended','hyperlinks','off');
%                 fprintf(fid,'%s\n',[num2str(pmeta.wmo_id) ',' pmeta.ftp_name]);
%                 fprintf(fid,'%s\n',msg);
%                 fprintf(fid,'%s\n','%_______________________');
%                 fclose(fid);
%                 
%             end
        end
    end
end
return
%% ARGOS
for ii = 1:length(THE_ARGO_FLOAT_DB)
    %testing the creation of iridium traj files
    if THE_ARGO_FLOAT_DB(ii).iridium == 1
        continue
    end
    if THE_ARGO_FLOAT_DB(ii).wmo_id ~= 5901667
        
        continue
    end
    
    clear traj traj_mc_order
    
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);

    if ~isempty(fpp)
        %construct a location for the log files that have been processed
        floc = [ARGO_SYS_PARAM.iridium_path 'iridium_processed/' ...
            num2str(THE_ARGO_FLOAT_DB(ii).wmo_id) '/'];
        
        % get the file metadata information
        pmeta.wmo_id = THE_ARGO_FLOAT_DB(ii).wmo_id;
        not_last = 1;
        %load the traj mat file just once:
        tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(pmeta.wmo_id)];
        if exist([tfnm '.mat'],'file');
            load(tfnm);
        else
            traj = [];
        end
                
        if exist('traj','var') == 1
            trajectory_nc(dbdat,fpp,traj,traj_mc_order)
        end
    end
end
return
%% copy all the test files up to a export directory for sending to gdac in one hit
% next step is to put code into processing
%and copy to Lisa
clear

fldn = dir('/home/argo/ArgoRT/netcdf_test')
matdir = '/home/argo/ArgoRT/trajfiles/';

for a = 1:length(fldn)
    if fldn(a).isdir == 0 | fldn(a).name(1) == '.'
        continue
    end
%     system(['cp /home/argo/ArgoRT/netcdf_test/' fldn(a).name '/*.nc /home/argo/ArgoRT/exporttest/'])
    system(['cp ' matdir 'T' fldn(a).name '.mat /home/argo/ArgoRT/exporttest/'])
    
end
%then ran writeGDAC manually to transfer the files to ifremer only.
