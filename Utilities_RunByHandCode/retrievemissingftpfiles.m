%retrieve missing files from rudics server breakdown.
% log into the ftp and scour the stampdated files for files since 0700 on
% 30 Jan, 2018
global ARGO_SYS_PARAM
set_argo_sys_params
cd /home/argo/ArgoRT/iridium_data

%connect to ftp
ftp_conn = ftp(ARGO_SYS_PARAM.ftp.ftp,ARGO_SYS_PARAM.ftp.name,ARGO_SYS_PARAM.ftp.pswd);

%now list all the files in the stampdated area
cd(ftp_conn,'stampdatedfiles');
details = dir(ftp_conn);

%go through each one to find dates > 1700 05 Feb and < 1320 06 Feb 2018
dt = datenum('05 Feb 2018 17:00:00');
dte = datenum('06 Feb 2018 13:20:00');

for a = 1:length(details)
    cd(ftp_conn,'/stampdatedfiles')
    if details(a).datenum > dt & details(a).datenum < dte
        %we want to delve in here
        fldet = dir(ftp_conn,details(a).name);
        if strmatch('f',fldet(1).name(1)) == 1
        cd('/home/argo/ArgoRT/iridium_data')
        cd(ftp_conn,details(a).name);
            %APF11 float, copy all files as is
            for b = 1:length(fldet)
                mget(ftp_conn,fldet(b).name)
                %copy to Iridium_Repository
                system(['cp ' fldet(b).name ' /home/argo/Iridium_Repository/' details(a).name])
                system(['cp ' fldet(b).name ' /home/argo/Iridium_Repository/' details(a).name '/stampdatedfiles/'])
            end
            continue
        end
        %copy all to Iridium_Repository, cd first
        cd(['/home/argo/Iridium_Repository/' details(a).name ...
            '/stampdatedfiles'])
        ind = zeros(1,length(fldet));
        cyc = ind;msglog = ind;siz= ind;
        cd(ftp_conn,details(a).name);
        for b = 1:length(fldet)
            if fldet(b).datenum > dt & fldet(b).datenum < dte
                ind(b) = 1;
                %find the cycle numbers
                cyc(b) = str2num(fldet(b).name(end-6:end-4));
                %is it a msg or log (1 or 2)
                if strmatch('msg',fldet(b).name(end-2:end)) == 1
                    msglog(b) = 1;
                else
                    msglog(b) = 2;
                end
                %size?
                siz(b) = fldet(b).bytes;
                %put in Iridium_Repository
                mget(ftp_conn,fldet(b).name)
            end
        end
        %change to iridium_data directory
        cd('/home/argo/ArgoRT/iridium_data')
        ind = find(ind);
        if ~isempty(ind)
            cy = cyc(ind);msglog = msglog(ind);siz = siz(ind);
            [ucyc,ia,ib] = unique(cy);
            for c = 1:length(ucyc) %for each unique cycle, find the biggest files
                icyc = find(ib==c);
                files = fldet(ind(icyc));
                %find the largest files
                imsg = find(msglog(icyc) == 1);
                [~,imax] = max(siz(icyc(imsg)));
                if ~isempty(imax)
                    %copy the file
                    mget(ftp_conn,files(imsg(imax)).name)
                    %copy to Iridium_Repository
                    system(['cp ' files(imsg(imax)).name ' /home/argo/Iridium_Repository/' details(a).name ...
                        '/' files(imsg(imax)).name(end-11:end)])
                    %and rename it in the iridium_data directory
                    system(['mv ' files(imsg(imax)).name ' ' files(imsg(imax)).name(end-11:end)]);
                end
                ilog = find(msglog(icyc) == 2);
                [~,imax] = max(siz(icyc(ilog)));
                if ~isempty(imax)
                    %copy the file
                    mget(ftp_conn,files(ilog(imax)).name)
                    %copy to Iridium_Repository
                    system(['cp ' files(ilog(imax)).name ' /home/argo/Iridium_Repository/' details(a).name ...
                        '/' files(ilog(imax)).name(end-11:end)])
                    %and rename it in the iridium_data directory
                    system(['mv ' files(ilog(imax)).name ' ' files(ilog(imax)).name(end-11:end)]);
                end
            end
        end
    end
end
close(ftp_conn);
