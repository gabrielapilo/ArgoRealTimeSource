% EXPORT_ARGO  Read float processing records to find which TESAC messages
%   and GDAC netCDF files to transmit, organise transmission, update records.
%
% INPUT  
%    reads Argo_proc_records.mat,  finds .tesac and .nc files
%
% OUTPUT
%    updates Argo_proc_records.mat, emails tesac, calls writeGDACfiles to
%    ftp the netCDF files
%   
% Author: Jeff Dunn CMAR/BoM Sep-Oct 2006
%
% CALLED BY:  strip_argos_msg  (or can be used standalone)
%
% SEE ALSO:  write_tesac.m   *_nc.m    writeGDACfiles
%
% USAGE:  export_argo

function export_argo

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
   
DoneFlag = 99;

% Need to change from traj to Rtraj, but this also provides the fieldname in the
% PROC_RECORDS struct, so have to carry those changes through to other places that it is used. 
pp = {'prof','tech','meta','traj'};   
pp1 = {'prof','tech','meta','Rtraj'};   

if ispc
    edir = [ARGO_SYS_PARAM.root_dir 'export\'];
    eIdir = [ARGO_SYS_PARAM.root_dir 'exportIridium\'];
    eBUFRdir = [ARGO_SYS_PARAM.root_dir 'exportBUFR\'];
    ndir = [ARGO_SYS_PARAM.root_dir 'netcdf\'];
    tdir = [ARGO_SYS_PARAM.root_dir 'tesac\'];
else
    edir = [ARGO_SYS_PARAM.root_dir 'export/'];
    eIdir = [ARGO_SYS_PARAM.root_dir 'exportIridium/'];
    eBUFRdir = [ARGO_SYS_PARAM.root_dir 'exportBUFR/'];
    ndir = [ARGO_SYS_PARAM.root_dir 'netcdf/'];
    tdir = [ARGO_SYS_PARAM.root_dir 'tesac/'];
end

% Load the proc_record array. Do not use the global version of PROC_RECORDS
% because we might want to use this function on its own.
prnam = [ARGO_SYS_PARAM.root_dir 'Argo_proc_records.mat'];
load(prnam);    %,'PROC_RECORDS'); 

% Initialise activity counters and reporting
cnts = [0 0 0 0 0];
logerr(0,'EXPORT_ARGO: ')

today=julian(clock);
for ii = 1:length(PROC_RECORDS)
    pr = PROC_RECORDS(ii);
    
    [fpp,dbdat]=getargo(pr.wmo_id);
    if ~strcmp('evil',dbdat.status) & ~strcmp('hold',dbdat.status)
        % GTS message
        pnum = pr.profile_number;
        pno=sprintf('%3.3i',pnum);
        
        fnm = [tdir 'R' num2str(pr.wmo_id) '_' pno '.tesac'];   %num2str(pr.profile_number) '.tesac'];
        if pr.gts_count < ARGO_SYS_PARAM.gts_max
            if ~exist(fnm,'file')
                logerr(2,['Cannot find ' fnm]);
            else
                if today-fpp(pnum).jday(1)<=40
                    if dbdat.iridium
                        [st,ww] = system(['cp -f ' fnm ' ' eIdir]);
                    else
                        mail_out_TESAC
                        if st==0
                            delete(fnm);
                        end
                    end
                else
                    st=[];
                end
                
                if isempty(st)
                else
                    if st ~= 0
                        logerr(2,['Mail ' fnm ' to GTS failed: ' ww]);
                    else
                        pr.gts_count = pr.gts_count + 1;
                        cnts(1) = cnts(1)+1;
                    end
                end
            end
        elseif pr.gts_count ~= DoneFlag
            % Flag that finished with this message, and remove it.
            pr.gts_count = DoneFlag;
            if exist(fnm,'file')
                delete(fnm);
            end
        end
        
        % netCDF files
        for ff = 1:4
            if ff==1
                if ispc
                    fnm = [num2str(pr.wmo_id) '\R' num2str(pr.wmo_id) '_' ...
                        pno '.nc'];
                    fnmbr = [num2str(pr.wmo_id) '\BR' num2str(pr.wmo_id) '_' ...
                        pno '.nc'];
                else
                    fnm = [num2str(pr.wmo_id) '/R' num2str(pr.wmo_id) '_' ...
                        pno '.nc'];
                    fnmbr = [num2str(pr.wmo_id) '/BR' num2str(pr.wmo_id) '_' ...
                        pno '.nc'];
                end
                %    num2str(pr.profile_number) '.nc'];
                cc = pr.prof_nc_count;
                cntmax = ARGO_SYS_PARAM.send_cdf_max;
            else
                %no traj,meta, nc files for BR files
                fnmbr = [];
                if ispc
                    fnm = [num2str(pr.wmo_id) '\' num2str(pr.wmo_id) '_' pp1{ff} '.nc'];
                else
                    fnm = [num2str(pr.wmo_id) '/' num2str(pr.wmo_id) '_' pp1{ff} '.nc'];
                end
                eval(['cc = pr.' pp{ff} '_nc_count;']);
                cntmax = ARGO_SYS_PARAM.send_meta_max;
            end
            
            if cc < cntmax
                
                if ~exist([ndir fnm],'file')
                    logerr(2,['Cannot find ' fnm]);
                elseif isingdac(fnm)~=2
                    %             % Copy the file to export/ to be sent
                    if ispc
                        [status,ww] =system(['copy /Y ' ndir fnm ' ' edir]);
                    else
                        [status,ww] = system(['cp -f ' ndir fnm ' ' edir]);
                    end
                    if status~=0
                        logerr(2,['Copy of ' fnm ' to export/ failed:' ww]);
                    else
                        cc = cc + 1;
                        cnts(ff+1) = cnts(ff+1)+1;
                    end
                end
                if ~isempty(fnmbr)
                    if ~exist([ndir fnmbr],'file')
%                         logerr(2,['Cannot find ' fnmbr]);
                    elseif isingdac(fnmbr)~=2
                        %             % Copy the file to export/ to be sent
                        if ispc
                            [status,ww] =system(['copy /Y ' ndir fnmbr ' ' edir]);
                        else
                            [status,ww] = system(['cp -f ' ndir fnmbr ' ' edir]);
                        end
                        if status~=0
                            logerr(2,['Copy of ' fnmbr ' to export/ failed:' ww]);
                        end
                    end
                end
            elseif cc ~= DoneFlag
                % Flag that have finished with this file.
                cc = DoneFlag;
            end
            
            eval(['pr.' pp{ff} '_nc_count = cc;']);
        end
        PROC_RECORDS(ii) = pr;
    end
end

%  Because the expect-run writeGDAC code is prone to hanging we now start it
%  as a spawned process, so that this Matlab program can finish independantly 
%  of it. To have it as a completely separate process (not started from here)
%  would mean it would run even if transmit_now=0  so that this function is 
%  NOT called. Either way it may crash and not send files (which we have 
%  just flagged above as having been sent.)
%
%  IF it appears that these processes ARE reliable, then we can run them in
%  the foreground and so report on their exit status and maybe accordingly 
%  save or lose the updated processing records.
%
% send netCDF

if ispc
    [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src\GroupSpecific\writeGDAC&']);%%%PUTDATA dengdeng
else
    [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src/GroupSpecific/writeGDAC &']);
end
if status ~= 0
    logerr(2,['initiating writeGDAC failed: ' ww]);
end

% Save the updated proc_record
save(prnam,'PROC_RECORDS','ftp_details','-v6');


logerr(5,['Files to send: GTS, profile, tech, meta, trajectory: ' num2str(cnts)])


% Check for files that have slipped through the system and are hanging around
[status,ww] = system(['find ' tdir ' -mtime +2 -print']);
if ~isempty(ww)
    [pp,ff] = fileparts(ww(1,:));
    logerr(2,['Old files in tesac/, first is ' ff]);
    [status,ww]=system(['rm -f ' tdir '*.tesac']);
end

[status,ww] = system(['find ' edir ' -mtime +1 -print']);
if ~isempty(ww)
    [pp,ff] = fileparts(ww(1,:));
    logerr(2,['Old files in export/, first is ' ff]);
end

% export_Iridium_tesac call
[status,ww] = system(['ls ' eIdir]);
if ~isempty(ww)
    if ispc
        [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src\GroupSpecific\write_Iridium_tesac']);
    else
        [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src/GroupSpecific/write_Iridium_tesac']);
    end
    if(status~=0)
        logerr(2,['Send of Iridium tesac failed, reason is ' ww]);
    end
end


%%%%%%%%%%%%%%%% BOM ONLY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% export_BUFR call
[status,ww] = system(['ls ' eBUFRdir]);
if ~isempty(ww)
    if ispc
        [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src\GroupSpecific\write_BUFR_ftp']);
    else
        [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src/GroupSpecific/write_BUFR_ftp']);
    end
    if(status==0)
        logerr(2,['Send of BUFR nc messages failed, reason is ' ww]);
    end
end

%-----------------------------------------------------------------------
