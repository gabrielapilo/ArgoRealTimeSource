% EXPORT_ARGO  Read float processing records to find which TESAC messages
%   and GDAC netCDF files to transmit, organise transmission, update records.
%
% INPUT  
%    reads Argo_proc_records.mat,  finds .bin (BUFR) and .nc files
%
% OUTPUT
%    updates Argo_proc_records.mat, emails BUFR, calls writeGDACfiles to
%    ftp the netCDF files
%   
% Author: Jeff Dunn CMAR/BoM Sep-Oct 2006
%       : Updated Bec Cowley, July, 2018 to only deliver BUFR
%
% CALLED BY:  strip_argos_msg  (or can be used standalone)
%
% SEE ALSO:  write_BUFR.m   *_nc.m    writeGDACfiles
%
% USAGE:  export_argo

function export_argo

global ARGO_SYS_PARAM PROC_RECORDS

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
    eBUFRdir = [ARGO_SYS_PARAM.root_dir 'exportBUFR\'];
    ndir = [ARGO_SYS_PARAM.root_dir 'netcdf\'];
    backupdir = [ARGO_SYS_PARAM.root_dir 'textfiles\'];
else
    edir = [ARGO_SYS_PARAM.root_dir 'export/'];
    eBUFRdir = [ARGO_SYS_PARAM.root_dir 'exportBUFR/'];
    ndir = [ARGO_SYS_PARAM.root_dir 'netcdf/'];
    backupdir = [ARGO_SYS_PARAM.root_dir 'textfiles/'];
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
        % GTS BUFR message
        pnum = pr.profile_number;
        pno=sprintf('%3.3i',pnum);
        
        [status,fnm] = system(['find ' eBUFRdir ' -name ''*R' num2str(pr.wmo_id) '_' pno '.bin'' -print']);
        if pr.gts_count < ARGO_SYS_PARAM.gts_max
            if status ~= 0 | isempty(fnm)
                %check if we have a backup copy, if so, assume it has been
                %sent.
                [st2,fnm2] = system(['find ' backupdir '/' num2str(pr.wmo_id) ' -name ''*R' num2str(pr.wmo_id) '_' pno '.bin'' -print']);
                if st2 ~= 0 | isempty(fnm2)
                    if today-fpp(pnum).jday(1)<=20 %only warn us if inside GTS delivery window
                        logerr(5,['Cannot find BUFR file for ' num2str(pr.wmo_id)]);
                    else
                        %reset GTS counts
                        pr.gts_count = DoneFlag;
                    end
                else
                    %reset GTS counts
                    pr.gts_count = DoneFlag;
                end
            else
                if today-fpp(pnum).jday(1)>20 %outside GTS delivery window
                    %remove from the BUFR delivery directory
                    [~,ij] = regexp( fnm, '[^\w/.]', 'match' ); %how many files?
                    s = 1;
                    for a = 1:length(ij)
                        [status,~]=system(['rm -f ' strtrim(fnm(s:ij(a)))]);
                        s = ij(a)+1;
                        logerr(5,['Old file in BUFR directory, removing: ' num2str(pr.wmo_id) ' profile ' num2str(pr.profile_number)]);
                    end
                    
                else
                    pr.gts_count = pr.gts_count + 1;
                    cnts(1) = cnts(1)+1;
                end
            end
        elseif pr.gts_count ~= DoneFlag
            % Flag that finished with this message, and remove it.
            pr.gts_count = DoneFlag;
            %remove from the BUFR delivery directory, file already sent to
            %the GTS.
            if ~isempty(fnm)
                [~,ij] = regexp( fnm, '[^\w/.]', 'match' ); %how many files?
                s = 1;
                for a = 1:length(ij)
                    [status,~]=system(['rm -f ' strtrim(fnm(s:ij(a)))]);
                    s = ij(a)+1;
                    logerr(5,['Old file in BUFR directory, removing: ' num2str(pr.wmo_id) ' profile ' num2str(pr.profile_number)]);
                end
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
else
    logerr(5,'Send of netcdf files to GDACs successful');
end

% Save the updated proc_record
save(prnam,'PROC_RECORDS','ftp_details','-v6');


logerr(5,['Files to send: GTS, profile, tech, meta, trajectory: ' num2str(cnts)])


% Check for files that have slipped through the system and are hanging around
[status,ww] = system(['find ' eBUFRdir ' -mtime +2 -print']);
if ~isempty(ww)
    [~,ii] = regexp( ww, '[^\w/.]', 'match' ); %how many files?
    s = 1;
    for a = 1:length(ii)
        [status,~]=system(['rm -f ' strtrim(ww(s:ii(a)))]);
        s = ii(a)+1;
        logerr(5,['Old files in exportBUFR/, removing ' strtrim(ww(s:ii(a)))]);
    end
end

% Now look at any old time-stamped netcdf files so we don't deliver them to
% GDAC by accident
[status,ww] = system(['find ' edir ' -mtime +2 -print']);
if ~isempty(ww)
    [~,ii] = regexp( ww, '[^\w/.]', 'match' ); %how many files?
    s = 1;
    for a = 1:length(ii)
        [status,~]=system(['rm -f ' strtrim(ww(s:ii(a)))]);
        s = ii(a)+1;
        logerr(5,['Old netcdf files in export/, removing ' strtrim(ww(s:ii(a)))]);
    end
end


% export_BUFR call - deliver BUFR messages to GTS
[status,ww] = system(['ls ' eBUFRdir]);
if ~isempty(ww)
    if ispc
        [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src\GroupSpecific\write_BUFR_ftp']);
    else
        [status,ww] = system([ARGO_SYS_PARAM.root_dir 'src/GroupSpecific/write_BUFR_ftp']);
    end
    if(status~=0) %write to BOM ftp fails if status ~= 0
        logerr(2,['Send of BUFR messages failed, reason is ' ww]);
    else
        logerr(5,'Send of BUFR messages to GTS successful');
    end
end

%-----------------------------------------------------------------------
