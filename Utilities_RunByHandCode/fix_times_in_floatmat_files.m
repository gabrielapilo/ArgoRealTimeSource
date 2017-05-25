%Script to do two things in IRIDIUM files:
% 1. Fix the float*.mat files that contain incorrect date/time information
% in the float.park_date and float.park_jday fields. Keep track of these.
% 2. Identify the files that have float.jday dates out by 12 hours. These
% will need to be reprocessed and identified to Esmee & Catriona so they
% can re-create any D-files. Q: Will Argos floats have the same problem???
%
%Bec Cowley, 17 August, 2016

%% % 1. Fix the float*.mat files that contain incorrect date/time information
% in the float.park_date and float.park_jday fields. Keep track of these.
% don't see any other thorough way except by going through every profile
% and checking for a match of date/time in the msg file.
clear

do1 = 1;
do2 = 0;

j1950 = julian([1950 1 1 0 0 0]);
inp = '/home/argo/ArgoRT/iridium_data/iridium_processed/';
global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
    set_argo_sys_params;
end

getdbase(0);
%%
if do1
for ii = 718:length(THE_ARGO_FLOAT_DB)
    %testing the creation of iridium traj files
    if THE_ARGO_FLOAT_DB(ii).maker ~= 4
        continue
    end
%     if isempty(strmatch('9i',THE_ARGO_FLOAT_DB(ii).controlboardnumstring))
%         continue
%     end
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(THE_ARGO_FLOAT_DB(ii).wmo_id)];
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    
    flid = dbdat.wmo_id;
    flid2 = dbdat.argos_hex_id;
    
    disp(THE_ARGO_FLOAT_DB(ii).wmo_id)
    % go through each profile
    adj = 0;
    for ij = 1:length(fpp)
        pn = '000';
        pns = num2str(ij);
        pn(end-length(pns)+1:end) = pns;
        fn = [inp num2str(flid) '/' flid2 '.' pn '.msg'];
        fid = fopen(fn);
        if fid > 0
            c = textscan(fid,'%s','Delimiter','|');
        else
            disp(['Missing file ' fn]);
            continue
        end
        fclose(fid);
        
        %get the parkPt times and check against the mat files:
        iii = find(cellfun(@isempty,strfind(c{:},'ParkPt')) == 0);
        %check the arrays are the same length
        if isempty(iii)
            iii = find(cellfun(@isempty,strfind(c{:},'ParkObs:')) == 0);
        end
        if length(iii) ~= length(fpp(ij).park_jday)
            
            disp('Arrays not same size!!')
            keyboard
            continue
        end
        %just need to check first one!!
        if ~isempty(iii)
            str = c{:}{iii(1)};
            expression = '(?<month>\w+) (?<day>\d+) (?<year>\d+) (?<hour>\d+):(?<min>\d+):(?<sec>\d+)';
            ti = regexp(str,expression,'match');
            ti = datenum(ti{:});
           if abs(ti - datenum(fpp(ij).park_date(1,:))) ~= 0
                %this date is wrong, need to fix the matfile park date and jday:
                tim = NaN*ones(length(iii),6);
                for ik = 1:length(iii)
                    str = c{:}{iii(ik)};
                    ti = regexp(str,expression,'match');
                    tim(ik,:) = str2num(datestr(datenum(ti{:}),'yyyy mm dd HH MM SS'));
                end
                fpp(ij).park_jday = julian(tim)';
                fpp(ij).park_date = tim;
                adj = 1;
                %record the float number and profile number
                fid = fopen('park_datetime_fixed.log','a');
                fprintf(fid,'%s\n',[num2str(dbdat.wmo_id) ',' num2str(ij)]);
                fclose(fid);
            end
        end
    end
    %now save it
    if adj %we have changed the park times
        float = fpp;
        save(fnm,'float')
    end
end
end
%% 2. Identify the files that have float.jday dates out by 12 hours. These
% will need to be reprocessed and identified to Esmee & Catriona so they
% can re-create any D-files. Q: Will Argos floats have the same problem???
% At the same time, check the dbdat.argos_hex_id value matches the numbers
% in the float iridium directories.
if do2
for ii = 732:length(THE_ARGO_FLOAT_DB)
    %testing the creation of iridium traj files
    if isempty(strmatch('9i',THE_ARGO_FLOAT_DB(ii).controlboardnumstring))
        continue
    end
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(THE_ARGO_FLOAT_DB(ii).wmo_id)];
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    
    flid = dbdat.wmo_id;
    flid2 = dbdat.controlboardnum;
    flid3 = dbdat.argos_id;
    
    disp(THE_ARGO_FLOAT_DB(ii).wmo_id)
    % go through each profile
    adj = 0;
    for ij = 1:length(fpp)
        pn = '000';
        pns = num2str(ij);
        pn(end-length(pns)+1:end) = pns;
        fn = [inp num2str(flid) '/' num2str(flid2) '.' pn '.msg'];
        fid = fopen(fn);
        if fid < 1
            fn = [inp num2str(flid) '/' num2str(flid3) '.' pn '.msg'];
            fid = fopen(fn);
        end
        
        if fid > 0
            c = textscan(fid,'%s','Delimiter','|');
        else
            %does the directory exist?
            if exist([inp num2str(flid)],'dir') == 0
                fid = fopen('missing_iridium_processed_dir.log','a');
                fprintf(fid,'%s\n',num2str(dbdat.wmo_id));
                fclose(fid);
                break
            end               
            fnn = dir([inp num2str(flid) '/*.msg']);
            
            if str2num(dbdat.argos_hex_id) ~= str2num(fnn(1).name(1:4))
                fid = fopen('bad_argox_hex_id_dbdat.log','a');
                fprintf(fid,'%s\n',num2str(dbdat.wmo_id));
                fclose(fid);
            end
            if flid2 ~= str2num(fnn(1).name(1:4))
                keyboard
            end
            disp(['Missing file ' fn]);
            continue
        end
        fclose(fid);
        
        %get the parkPt times and check against the mat files:
        iii = find(cellfun(@isempty,strfind(c{:},'$ Profile')) == 0);
        %check the arrays are the same length
        if length(iii) ~= length(fpp(ij).jday)
            disp('Arrays not same size!!')
            fid = fopen('jday_datetime_is_wrong.log','a');
            fprintf(fid,'%s\n',[num2str(dbdat.wmo_id) ',' num2str(ij)]);
            fclose(fid);
            continue
        end
        %just need to check first one!!
        if ~isempty(iii)
            str = c{:}{iii(1)};
            expression = ['(?<month>\w+)  (?<day>\d+) (?<hour>\d+):(?<min>\d+):(?<sec>\d+) (?<year>\d+)|' ...
                '(?<month>\w+) (?<day>\d+) (?<hour>\d+):(?<min>\d+):(?<sec>\d+) (?<year>\d+)'];
            ti = regexp(str,expression,'match');
            ti = datenum(ti{:});
           if abs(ti - datenum(gregorian(fpp(ij).jday))) ~= 0
                %this date is wrong,record teh file name:
                %record the float number and profile number
                disp([num2str(dbdat.wmo_id) ',' num2str(ij)]);
                fid = fopen('jday_datetime_needs_fix.log','a');
                fprintf(fid,'%s\n',[num2str(dbdat.wmo_id) ',' num2str(ij)]);
                fclose(fid);
            end
        end
    end
end
end

%% Now run a script each day to shift up 40 of the files that need reprocessing
% to the iridium_data directory.
clear
fid = fopen('jday_datetime_needs_fix.log','r');
c = textscan(fid,'%f,%f');
fclose(fid);
%%
for a = 121:length(c{1})
    str = ['/home/argo/ArgoRT/iridium_data/iridium_processed/' num2str(c{1}(a)) '/'];
    fns = dir([str '*.001.msg']);
    %get the hull number:
    hn = fns.name(1:4);
    %profile number
    pn = '000';
    pns = num2str(c{2}(a));
    pn(end-length(pns)+1:end) = pns;
    
    %copy up the file:
    str2 = [str hn '.' pn '.*'];
    system(['cp ' str2 ' /home/argo/ArgoRT/iridium_data/oldfiles'])
    
end

%% Now zip up all the relevant files and send to Lisa
clear
fid = fopen('/home/argo/ArgoRT/src_cowley/traj_src_devel/error_logs/jday_datetime_needs_fix.log','r');
c = textscan(fid,'%f,%f');
fclose(fid);
umat = unique(c{1})
%matfiles
for a = 1:length(umat)
system(['cp /home/argo/ArgoRT/matfiles/float' num2str(umat(a)) '.mat /home/argo/ArgoRT/files_for_lisa_Sept2016'])
end

%profile netcdf files R*.nc
for a = 1:length(c{1})
    pn = '000';
    pns = num2str(c{2}(a));
    pn(end-length(pns)+1:end) = pns;
    
    system(['cp /home/argo/ArgoRT/netcdf/' num2str(c{1}(a)) '/R' num2str(c{1}(a)) '_' pn '.nc /home/argo/ArgoRT/files_for_lisa_Sept2016'])
    
end

%also the files from jday_datetime_is_wrong.log
fid = fopen('/home/argo/ArgoRT/src_cowley/traj_src_devel/error_logs/jday_datetime_is_wrong.log','r');
c = textscan(fid,'%f,%f');
fclose(fid);
umat = unique(c{1})
%matfiles
for a = 1:length(umat)
system(['cp /home/argo/ArgoRT/matfiles/float' num2str(umat(a)) '.mat /home/argo/ArgoRT/files_for_lisa_Sept2016'])
end

%profile netcdf files R*.nc
for a = 1:length(c{1})
    pn = '000';
    pns = num2str(c{2}(a));
    pn(end-length(pns)+1:end) = pns;
    
    system(['cp /home/argo/ArgoRT/netcdf/' num2str(c{1}(a)) '/R' num2str(c{1}(a)) '_' pn '.nc /home/argo/ArgoRT/files_for_lisa_Sept2016'])
    
end

%% code for Lisa to get these into her directories easily
fns = dir('files_for_lisa_Sept2016/*.nc');
for a = 1:length(fns)
    wmo = fns(a).name(2:end-7);
    system(['mv directory/' fns(a).name ' /home/ArgoRT/netcdf/' num2str(wmo) ])
end
