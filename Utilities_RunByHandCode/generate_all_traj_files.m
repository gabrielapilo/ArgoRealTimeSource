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
%     %testing the creation of iridium traj files
%     if isempty(strfind(THE_ARGO_FLOAT_DB(ii).controlboardnumstring,'i'))
%         continue
%     end
%     %only webb and seabird iridium floats
%     if THE_ARGO_FLOAT_DB(ii).maker ~= 4 & THE_ARGO_FLOAT_DB(ii).maker ~= 1 
%         continue
%     end
    if THE_ARGO_FLOAT_DB(ii).wmo_id ~= 5903915 %already done it
        
        continue
    end
    
    clear traj traj_mc_order
    
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if isempty(fpp)
        continue
    end
    if ~dbdat.iridium %just do the iridium floats first
        continue
    end
   %quick and dirty check to avoid the EM floats & APF11. 
    if dbdat.subtype >=3000 || dbdat.subtype == 1023  || dbdat.subtype == 1015 || dbdat.subtype == 1018 
        disp(['APF11, NKE, SOLO OR EM FLOAT!: ' num2str(dbdat.wmo_id)])
%         pause
        continue
    end
    float = qc_tests(dbdat,fpp,[],1); %redo the qc properly for position only
    %and save it
    save(['matfiles/float' num2str(dbdat.wmo_id) '.mat'],'float')
    fpp = float;
    if ~isempty(fpp)
        %construct a location for the log files that have been processed
        floc = [ARGO_SYS_PARAM.iridium_path 'iridium_processed/' ...
            num2str(THE_ARGO_FLOAT_DB(ii).wmo_id) '/'];
%         floc = ARGO_SYS_PARAM.iridium_path;
        
        % get the file metadata information
        pmeta.wmo_id = THE_ARGO_FLOAT_DB(ii).wmo_id;
        %load the traj mat file just once:
        tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(pmeta.wmo_id)];
        if exist([tfnm '.mat'],'file');
            load(tfnm);
        else
            traj = [];
        end
        
%         if length(fpp) - 10 > 0
%             strt = length(fpp) - 10;
%         else
            strt = 1;
%         end
        for j=strt:length(fpp)
            pn = '000';
            pns = num2str(j);
            pn(end-length(pns)+1:end) = pns;
            fn = '0000';
            fns = num2str(dbdat.argos_id);
            fn(end-length(fns)+1:end) = fns;
            pmeta.ftp_fname = [fn '.' pn '.log'];
            pmeta.pn = j;
            % create the netcdf and matlab trajectory files.
            disp(['WMO: ' num2str(pmeta.wmo_id) ', pn: ' num2str(pmeta.pn)])
%             try
            traj = load_traj_apex_iridium(traj,pmeta,pmeta.pn,dbdat,fpp,floc); %for iridium floats
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
    end
    %                 %open a file to write the message out for later checking
    %                 fid = fopen('trajfilesremade_Nov2017.txt','a');
    %                 fprintf(fid,'%s\n',num2str(pmeta.wmo_id));
    %                 fclose(fid);
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
return
%% ARGOS
kk = [5903624
    5905415
    5905418];
for ii = 1:length(THE_ARGO_FLOAT_DB)
    %testing the creation of iridium traj files
    if THE_ARGO_FLOAT_DB(ii).maker ~= 1
        continue
    end
%     if THE_ARGO_FLOAT_DB(ii).iridium == 1
%         continue
%     end
    disp(THE_ARGO_FLOAT_DB(ii).wmo_id)
    if ~any(THE_ARGO_FLOAT_DB(ii).wmo_id == kk)
        
        continue
    end
    clear traj traj_mc_order
    
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    float = qc_tests(dbdat,fpp,[],1); %redo the qc properly for position only
    %and save it
    save(['matfiles/float' num2str(dbdat.wmo_id) '.mat'],'float')
    fpp = float;

    if ~isempty(fpp)
        disp(THE_ARGO_FLOAT_DB(ii).wmo_id)
        %load the traj mat file just once:
        tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(THE_ARGO_FLOAT_DB(ii).wmo_id)];
        if exist([tfnm '.mat'],'file') == 2
            load(tfnm);
        else
            traj = [];
        end
                
        if exist('traj','var') == 1
            %rebuild all the traj files, and recreate the netcdf files
            disp(['Building traj: ' num2str(THE_ARGO_FLOAT_DB(ii).wmo_id)])
%             load_float_to_traj(THE_ARGO_FLOAT_DB(ii).wmo_id,1)
            trajectory_nc(dbdat,fpp,traj,traj_mc_order)
        end
    end
end
return
%% ARGOS, but force remake of some files
% see code: traj_rebuild_failed_files.m

%% copy all the test files up to a export directory for sending to gdac in one hit
% next step is to put code into processing
%and copy to Lisa
clear
fln = load('csiro_trajectory_29032019.csv');
% fldn = dirc('/home/argo/ArgoRT/netcdf/','de');
% matdir = '/home/argo/ArgoRT/trajfiles/';

for a = 1:size(fln,1)
%     if fldn(a).isdir == 0 | fldn(a).name(1) == '.'
%         continue
%     end
    fn = dir(['netcdf/' num2str(fln(a)) '/*Rtraj.nc'])
    if ~isempty(fn)
%         if fn.datenum > 737426
            system(['cp /home/argo/ArgoRT/netcdf/' num2str(fln(a)) '/*Rtraj*.nc /home/argo/ArgoRT/export_hold/'])
%         end
    end
    
end
%then ran writeGDAC manually to transfer the files to ifremer only.
