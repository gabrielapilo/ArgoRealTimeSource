% Collect Trajectory data for one cycle for an Apex Iridium float, and analyses
% accumulated time-series for float to deterine/update all values needed for
% trajectory files. 
% The log files contain the timing information for a profile (n), but the
% surface information for the end profile n is contained in the next
% profile (n+1). Therefore, when a log file is received, we need to add
% that surface information to the profile n-1 record, and use fill values for
% the profile n until profile n+1 is reported.
%fv.PTM
% INPUTS
%   traj:       trajectory mat structure if it exists. Load before call to
%               save on multiple load/saves if doing multiple profiles.
%   pmeta:    profile metadata from process_iridium.m.
%   dbdat:     our tech database record for this float
%   pro:       struct array of decoded profile data for this float 
%   floc:       override the default location of real time iridium log
%               files. Useful for reprocessing. [optional]
%
%
% OUTPUTS
%   traj:   see just below
%   traj_mc_order:  The event MEASUREMENT_CODEs appropriate to this float,
%                   and in the order required for their placement in the
%                   Rtraj file.
%
%
% FILES:
%   trajfiles  (input and updated)
%
% Rebecca Cowley, July 2015
%
% CALLS:
%
% CALLED BY: extract_Iridium_data.m
%
% USAGE: [traj] = load_traj_apex_iridium(traj,pmeta,dbdat,fpp,floc)

function [traj] = load_traj_apex_iridium(traj,pmeta,np,dbdat,fpp,floc)


% Floats which profile on ascent must provide
%  DST, DET, PET, DDET, AST, AET, TET, TST (Cookbook 3.2)
%
% Those profiling on descent might have DST, DDET, DAST, DET, PET, AST, AET

global ARGO_SYS_PARAM


pn = np;
if isempty(pn) || pn<0 || pn>999
    % Cannot do anything without a sensible profile number
    return
end

% Open new or existing trajectory workfile
fldnms = {'clockoffset','DST','DSP' 'DET','PST','PTM','PET','DDET','AST',...
    'DNT','AET','TST2','ST','TST','FMT','FLT','LLT','LMT','TET', ...
    'traj_mc_order','traj_mc_index'};

%Made up some new letter codes to match extra MC:
%     DSP = descent pressure
%     PTM = pressure temperature hourly measuremnts
%     DNT = downtime epoch - will only be visible and reported if the float
%     times out trying to find the profile pressure. Need to find a float
%     that does this before I can code it in.
%     TST2 = TST code 701
fld_n = {'DST','DSP' 'DET','PST','PTM','PET','DDET','AST',...
    'DNT','AET','TST2'};
fld_nminus1 = {'ST','TST','FMT','FLT','LLT','LMT','TET'};

%set up empty fldnms:
%set all fields as new - new report
for a = 1:length(fldnms)
    eval([fldnms{a} '= NaN;'])
end

%
% initialise outputs for new profile
% do this for all profiles, even if re-running.
%
traj(pn).clockoffset = 0; %Rtc skew value in each msg file
if length(traj) < pn
    %set up empty fields to indicate no data yet.
    for a = 1:length(fldnms)
        traj(pn).(fldnms{a}) = [];
    end
else
    for a = 1:length(fld_n)
        %set up empty fields to indicate no data yet.
        traj(pn).(fld_n{a}) = [];
    end
    for a = 1:length(fld_nminus1)
        if pn > 1
            %keep data from n+1 and delete data in n-1
            traj(pn-1).(fld_nminus1{a}) = [];
        else
            %keep data from n+1 and delete data in n-1
            traj(pn).on_deployment.(fld_nminus1{a}) = [];
        end
    end
end
% now need to get substructure associated with each field:
%     for b = 1:length(subfldnms)
%         traj(pn).(fldnms{a}).(subfldnms{b}) = defaultval{b};
%     end


%put in the on_deployment structure too
if pn == 1
    traj(1).on_deployment = [];
end

rtc_skew = 0;
sat_count = 0;
gps_count = 0;
STlat = NaN; STlon = NaN;

% Floats which profile on ascent must provide
%  DST, DET, PET, DDET, AST, AET and all surface times (Cookbook 3.2)
% Those profiling on descent might have DST, DDET, DAST, DET, PET, AST, AET

% ---- Load data and parameters from this cycle
if exist('floc','var') == 1
    fn = [floc pmeta.ftp_fname];
else
    fn = [ARGO_SYS_PARAM.iridium_path pmeta.ftp_fname];
end

% open and parse file
%
fid=fopen([fn(1:end-3) 'log'],'r');
if fid > 0
    [tdata] = textscan(fid,'%s','Delimiter','|');
    fclose(fid);
else
    disp(['File not found: ' fn])
    return
end

%need the msg file too - not everything is extracted in extract_iridium at
%this stage, could be updated, but I don't want to delve into that now.
fid = fopen([fn(1:end-3) 'msg'],'r');
if fid > 0
    [msgdata] = textscan(fid,'%s','Delimiter','|');
    fclose(fid);
else
    disp(['File not found: ' fn(1:end-3) 'msg'])
    msgdata = [];
end
%and previous msg file
np = '000';
nps = num2str(pn-1);
np(end-length(nps)+1:end) = nps;
fn_p = [ARGO_SYS_PARAM.iridium_path 'iridium_processed/' num2str(pmeta.wmo_id) '/' pmeta.ftp_fname];
if exist([fn_p(1:end-7) np '.msg'],'file') == 0
    %look in 000files dir
    fn_p = [ARGO_SYS_PARAM.iridium_path 'iridium_processed/000files/' pmeta.ftp_fname];
end
fid = fopen([fn_p(1:end-7) np '.msg'],'r');
if fid < 0
    disp(['File not found: ' fn_p(1:end-7) np '.msg'])
    msgdata_prev = [];
else
    
    [msgdata_prev] = textscan(fid,'%s','Delimiter','|');
    fclose(fid);
end

%first find firmware revision date, some values calculated dependant upon
%this date.
ii = find(cellfun(@isempty,strfind(tdata{1},'FwRev:'))==0);
if ~isempty(ii)
    str = tdata{1}{ii};
    ii = findstr('FwRev:',str);
    fw = datenum(str(ii+7:end-1),'mmddyy');
    %for now, let's see if we have any with fw > 072314
    if fw > datenum('0722314','mmddyy')
        disp('Found firmware > 0722314')
%         keyboard
    end
else
    disp('No firmware date!')
    %     keyboard
end

% read through parsed file row by row and assign values
%
row_idx = 1;
while row_idx <= length(tdata{1})
    %
    % build date
    %
    t_date=NaN;
    if length(tdata{1}{row_idx}) >= 21
        try
            t_date = datenum(tdata{1}{row_idx}(2:21),'mmm dd yyyy HH:MM:SS');
        end
    end
    %
    % find the times one by one and assign, all times might not be present
    % if log file size limit is reached
    
    %get the previous profile surface time information:
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'Fix:')
        gps_count = gps_count + 1;
        %decode the satellite times:Allow for multiple
        %         if fmt_count == 1
        %             fmt1 = regexp(tdata{1}{row_idx-1},'\w*/\w*/\w*','match');
        %             fmt2 = upper(regexp(tdata{1}{row_idx-1},'h[hms]*','match')); %This will not work if the format is not HHMMSS!!
        %             fmt = [char(fmt1) ' ' char(fmt2)];
        %         end
        %Assume the format will remain constant:  lon     lat mm/dd/yyyy hhmmss nsat
        fmt = 'mm/dd/yyyy HHMMSS';
        dt = regexp(tdata{1}{row_idx},'\d+/\d+/\d+ [0-9]*','match');
        if ~isempty(dt)
            ST(gps_count) = datenum(dt,fmt);
            %collect the position information too: ASSUME IT IS LON FOLLOWED BY
            %LAT!!
            ll = regexp(tdata{1}{row_idx},'[-0-9]+\.[0-9]+','match');
            STlat(gps_count) = str2num(ll{2});
            STlon(gps_count) = str2num(ll{1});
        end
    end
    
    
    % get the current profile timing information:
    %clock offset information is applied to current profile.Do we apply the
    %previous offset to the surface data collected from this record?
    %What about Excessive RTC skew detected and clock adjusted (eg profile
    %107 of wmoid 5904677 - detected at the end of profile 106.
    if ~isnan(t_date) & ~isempty(strfind(tdata{1}{row_idx},'GpsServices()')) & ...
            ~isempty(strfind(tdata{1}{row_idx},'RTC skew ('))
        rtc_skew = str2double(tdata{1}{row_idx}(regexp(tdata{1}{row_idx},'RTC skew \(','end')+1:...
            regexp(tdata{1}{row_idx},'RTC skew \([-0-9]+s\)','end')-2))./86400;
    end
    if ~isnan(t_date) & ~isempty(strfind(tdata{1}{row_idx},'GpsServices()')) & ...
            ~isempty(strfind(tdata{1}{row_idx},'Excessive RTC skew'))
        %the clock may have been reset by a lot. Need to check these out
        %and figure out what to do with them
        if rtc_skew > 90/86400
%             fid = fopen('RTC_excessive.txt','a');
%             fprintf(fid,'%s\n',[fn ',' num2str(rtc_skew*86400)]);
%             fclose(fid);
            disp([pmeta.ftp_fname ' not written, excessive RTC_SKEW'])
            return
        end
        %if RTC Excessive is detected, the clock is reset, therefore rtc_skew =
        %0.
        rtc_skew = 0;
    end
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'DescentInit()')
        if ~strfind(tdata{1}{row_idx},['Deep profile ',num2str(pn),' initiated'])
            disp('log file is for wrong profile number')
            break
        end
        %just record this the first time it appears in DST
        if isnan(DST)
            DST = t_date;
            % this is also the TET value for the previous profile
            %for Navis floats, the manual suggests using 'logout'. I think
            %it should be 'TelemetryTerminate'. Both are available in the
            %apex iridium too. Leave TET=DST until confirmation of other
            %options.
            TET = DST;
        end
        %now get the surface pressure for the descent pressure values (DSP)
        if ~isempty(strfind(tdata{1}{row_idx},'Surface pressure:'))
            dcount = 1;
            DSP(dcount,1) = t_date;
            p = str2double(tdata{1}{row_idx}(regexp(tdata{1}{row_idx},'Surface pressure: ','end')+1:...
                regexp(tdata{1}{row_idx},'dbars','end')-5));
            DSP(dcount,2) = p;
        end
    end
    %look for remaining DSP values:
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'Descent()')
        dcount = dcount +1;
        DSP(dcount,1) = t_date;
        p = str2double(tdata{1}{row_idx}(regexp(tdata{1}{row_idx},'Pressure: ','end')+1:end));
        DSP(dcount,2) = p;
    end
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'ParkInit()')
        PST = t_date;
    end
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'ParkTerminate()') & length(PET) < 2
        PET = t_date;
        %Get the time and the PTS measurements:
        if regexp(tdata{1}{row_idx},'PTS')
            exp = 'PTS.*(?=PSU)';
            splitS = regexp(tdata{1}{row_idx},exp,'match');
            %get the pressure, sal, temp info
            exp = '(?<=:).*';
            str = regexp(splitS{1},exp,'match');
            str = str{1};
            isp = strfind(str,' ');
            ij = strfind(str,'db');
            PET(2) = str2num(str(isp(1):ij(1)-1));
            ij = strfind(str,'C');
            PET(3) = str2num(str(isp(2):ij-1));
            PET(4) = str2num(str(isp(3):end));
        end
    end
    %Navis floats have GoDeepInit to signify end of the park period.
    %Replace PET(1) with this if it exists in the file
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'GoDeepInit()')
        PET(1) = t_date;
    end    
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'ProfileInit()')
        ii = strfind(tdata{1}{row_idx},'Pressure:');
        if ~isempty(ii)
            AST = t_date;
            %get the pressure too and record it here
            ij = strfind(tdata{1}{row_idx},'dbar');
            AST(2) = str2num(tdata{1}{row_idx}(ii+9:ij(1)-1));
        end
    end
    % If this line exists, overwrite the first AST Value, as this has the
    % temperature and salinity data too.
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'Sample 0')
        ii = regexp(tdata{1}{row_idx},'PTS');
        if ~isempty(ii)
            AST = t_date;
            exp = 'PTS.*(?=PSU)';
            splitS = regexp(tdata{1}{row_idx},exp,'match');
            %get the pressure, sal, temp info
            exp = '(?<=:).*';
            str = regexp(splitS{1},exp,'match');
            str = str{1};
            isp = strfind(str,' ');
            if length(isp) < 3
                isp = [isp,strfind(str,',')];
            end    
            try
                ij = strfind(str,'dbar');
                AST(2) = str2num(str(isp(1):ij(1)-1));
                ij = strfind(str,'C');
                AST(3) = str2num(str(isp(2):ij-1));
                AST(4) = str2num(str(isp(3):end));
            catch
                disp(['Not all AST data extracted ' num2str(dbdat.wmo_id)])
            end
        end
    end
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'SurfaceDetect()')
        AET = t_date;
    end
    if ~isnan(t_date) & strfind(tdata{1}{row_idx},'Sbe41cpStopCP()')
        %for fw < 072314, this is time stamp for profile termination
        %After fw 072314, this is TimeStartTelemetry.
        TST2 = t_date;
    end
    row_idx = row_idx + 1;
end


%load the float technical file:
load([ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(pmeta.wmo_id) 'aux.mat'])
%try calculating empty values:
estpst = 0;
if isnan(PST)
    %can't calculate park start time, but can use values from msg file if
    %available.
    try
        PST = datenum(fpp(pn).park_date(1,:));
        estpst = 1;
    catch
    end
end
%if DST is empty, back-calculate from first park pressure time
estdst = 0;
if isnan(DST) & ~isnan(PST)
    try
        DST = PST(1) - floatTech.Mission(pn).ParkDescentTime/24/60;
        TET = DST;
        estdst = 1;
    catch
    end
end

estpet = 0;
if isnan(PET)
    %park end time can be calculated
    %I don't think this algorithm is correct. Included in the APF9i table,
    %but doesn't make sense to me CHECK with Megan
    if ~isempty(floatTech.Mission(pn).DownTime)
        PET = DST + floatTech.Mission(pn).DownTime/60/24 ...
            - floatTech.Mission(pn).DeepProfileDescentTime/60/24;
        estpet = 1;
    end
    if ~isempty(fpp(pn).park_date)
        if isnan(PET) | PET < datenum(fpp(pn).park_date(end,:))
            %try using last time from park info in msg file
            try
                PET = datenum(fpp(pn).park_date(end,:));
                estpet = 1;
            catch
            end
        end
    end
end

    
% to get DET, we need to get the park CTD
% information. DET is the time stamp for first PRES/TEMP sample within 3%
% of drift pressure.
% the structure fpp has already got this information, no need to read the
% msg file. For stand-alone function, you would need to read the msg file
% here.

% if Profile termination value is empty(TST2), we can get it from the msg
% file (sometimes the log file is truncated and doesn't have the full
% information). Note that these values are not the same in files where both
% are available. The time in the msg file is after the time recorded in the
% log file.
esttst2 = 0;
if ~isempty(fpp(pn).jday) & isnan(TST2)
    TST2 = datenum(gregorian(fpp(pn).jday(1))); %these are the GPS fixes from the msg file
    esttst2 = 1;
end

%if AST is empty, we can calculate it:
estast = 0;
if isnan(AST(1)) & ~isnan(DST)% & ~estdst 
    %downtime is in minutes
    if isfield(floatTech.Mission(pn),'TimeOfDay')
        if ~isempty(floatTech.Mission(pn).DownTime) && ...
                ~isempty(floatTech.Mission(pn).TimeOfDay) && ...
                ~isnan(floatTech.Mission(pn).TimeOfDay(1))...
                && isnumeric(floatTech.Mission(pn).TimeOfDay)
            dd = DST + floatTech.Mission(pn).DownTime/60/24;
            AST(1) = dd + floatTech.Mission(pn).TimeOfDay/60/24;
        end
    elseif ~isempty(floatTech.Mission(pn).DownTime)
        AST(1) = DST + floatTech.Mission(pn).DownTime/60/24;
    end
    %If the time does not make sense relative to actual PET (eg, the float hits
    %the bottom and times are screwed up), then use PET + DeepProfileDescentTime as the AST estimate.
    estast = 1;
    if AST(1) < PET(1) | AST(1) > TST2
        if ~estpet
            AST(1) = PET(1) + floatTech.Mission(pn).DeepProfileDescentTime/60/24;
            if AST(1) < PET(1) | AST(1) > TST2
                AST(1) = NaN;
                estast = 0;
            end
        else
            AST(1) = NaN;
            estast = 0;
        end
    end
end
%DNT is code 501 - it is the [down time end - time of day] .
%Time of day is in minutes after midnight.
%can get DNT from the float technical file. Not always set, mostly for bio floats:
%Time of day after midnight that downtime expires.
%To me, this is the same as AST.

if isfield(floatTech.Mission(pn),'TimeOfDay')
    if ~isempty(floatTech.Mission(pn).TimeOfDay) & ~isnan(floatTech.Mission(pn).TimeOfDay(1))...
            & isnumeric(floatTech.Mission(pn).TimeOfDay)
        %now we have AST, we can assign the DNT
        DNT = AST(1);
    end
end

%if the GPS fixes are missing in log file, can be present in msg file
%(previous one).
if isnan(STlat) & ~isempty(msgdata_prev)
    igps = find(cellfun(@isempty,strfind(msgdata_prev{1},'Fix:'))==0);
    if ~isempty(igps)
        for gps_count = 1:length(igps)
            fmt = 'mm/dd/yyyy HHMMSS';
            dt = regexp(msgdata_prev{1}{igps(gps_count)},'\d+/\d+/\d+ [0-9]*','match');
            if ~isempty(dt)
                ST(gps_count) = datenum(dt,fmt);
                %collect the position information too: ASSUME IT IS LON FOLLOWED BY
                %LAT!!
                ll = regexp(msgdata_prev{1}{igps(gps_count)},'[-0-9]+\.[0-9]+','match');
                STlat(gps_count) = str2num(ll{2});
                STlon(gps_count) = str2num(ll{1});
            else
                [ST(gps_count),STlat(gps_count), STlon(gps_count)] = deal(NaN);
            end
        end
    end
end

% % Can get approximate DSP values from the msg file (currently not decoded from
% % the msg files in extract_iridium, so get directly here.
% estdsp = 0;
% if isnan(DSP) & ~isempty(msgdata)
%      ii = find(cellfun(@isempty,strfind(msgdata{1},'ParkDescentP'))==0);
%      if ~isempty(ii)
%          dsp = msgdata{1}(ii);
%          %don't have a time, so can't fill that information
%          ieq = strfind(dsp{1},'=');
%          cnt = str2num(dsp{1}(ieq+1:end));
%          for a = 1:cnt
%              ieq = strfind(dsp{a},'=');
%              dp = str2num(dsp{a}(ieq+1:end));
%              DSP(a,1) = NaN;
%              DSP(a,2) = dp*10;
%          end
%          estdsp = 1;
%      end
% end

%check for pressures within 3% of park depth:
%use 'Eventual Drift Pressure', ie, not the programmed value
% In the case of a float that overshoots on descent, DET is the time of the overshoot.
[npark_samp,ndisc_samp] = deal([]);
if ~isempty(fpp(pn).park_p)
    idiscrete = find(strncmp('$ Discrete',msgdata{1},10));
    iparks = length(find(cellfun(@isempty,strfind(msgdata{1},'(Park Sample)'))==0));
    iparks2 = length(find(cellfun(@isempty,strfind(msgdata{1},'ParkPts'))==0));
    if iparks2 == 0 %probably a bio float
        iparks2 = length(find(cellfun(@isempty,strfind(msgdata{1},'ParkObs:'))==0));
    end        
    if ~isempty(idiscrete)
        str = msgdata{1}{idiscrete};
        ij = findstr(':',str);
        ndisc_samp = str2num(str(ij+1:end));
        if ~isempty(iparks)
            npark_samp = iparks + iparks2;
        end
    end
    
    pd = fpp(pn).park_p(1:npark_samp);
    pd = pd(~isnan(pd));
    pd = median(pd);
    if fpp(pn).park_p(1) > pd
        %float has overshot, use first value
        DET = datenum(fpp(pn).park_date(1,:));
    else
        perr = 0.03*pd;
        [dcheck,ind] = find(abs(pd - fpp(pn).park_p(1:size(fpp(pn).park_date,1))) < perr);
        
        if isempty(ind)
            DET = PST;
        else
            DET = datenum(fpp(pn).park_date(ind(1),:));
            %make sure DET comes after PST - eg in 5903625 pn 1, park_jday is
            %incorrect, need to fix!
            if DET < PST
                DET = PST;
%                 fid = fopen('bad_fpp_park_date.txt','a');
%                 fprintf(fid,'%s\n',[fn ',' num2str(pn)]);
%                 fclose(fid);
            end
        end
    end
    %assign the PTM while we are here:
    PTM = NaN*ones(size(fpp(pn).park_date,1)+length(npark_samp),4);
    %note that the P/T/S park measurement does not have a date associated
    %with it in the fpp structure, however, in the log file, the time is
    %recorded with 'ParkTerminate', PET value. PTS from end of the park
    %period is now to be associated with the PET value (MC 300).
    %also, there can be more than one measurement. In this case, the last
    %one is likely to be the AST value, the first one the PET value. The
    %log file will have both measurements labelled, so I'm inclined to get
    %them from the log file. The fpp data comes from the unlabelled msg
    %file. The data matches.
    try
        PTM(:,1) = [datenum(fpp(pn).park_date); NaN*npark_samp];
        PTM(:,2) = reshape(fpp(pn).park_p(1:npark_samp),[],1);
        PTM(:,3) = reshape(fpp(pn).park_t(1:npark_samp),[],1);
        PTM(:,4) = reshape(fpp(pn).park_s(1:npark_samp),[],1);
    catch
        disp(['Problem with Park temp/pres/psal for float ' num2str(pmeta.wmo_id)])
    end
    %make sure DET comes after PST - eg in 5903625 pn 1, park_jday is
    %incorrect, need to fix!
    if PTM(1) < PST
        PTM(1) = PST;
%         fid = fopen('bad_fpp_park_date.txt','a');
%         fprintf(fid,'%s\n',[fn ',' num2str(pn)]);
%         fclose(fid);
    end
    
    %look for dodgy values in msg file:
    ii = find(PTM(:,2:4) > 10000);
    if any(ii)
        dat = PTM(:,2:4);
        dat(ii) = NaN;
        PTM(:,2:4) = dat;
%         fid = fopen('bad_PTS.txt','a');
%         fprintf(fid,'%s\n',[fn ',' num2str(pn)]);
%         fclose(fid);
    end        
    
    %at this stage, put in a fix for when the matrix size of the
    %fpp(pn).park_s is wrong. Happened a couple of times:
    if length(fpp(pn).park_s) ~= length(fpp(pn).park_p)
        ps = NaN*fpp(pn).park_p;
        ii = length(fpp(pn).park_s);
        ps(end-ii+1:end) = fpp(pn).park_s;
        fpp(pn).park_s = ps;
%         fid = fopen('traj_files_need_fixing.txt','a');
%         fprintf(fid,'%s\n',[fn ',' num2str(pn)]);
%         fclose(fid);
    end
    
    %only use the PET times that match the CTD measurements - use pressure
    %only as salinity could be dodgy.
    if ~estpet & length(PET) > 1
        ii = find(abs(fpp(pn).park_p - PET(2)) < 5);
    else
        %have to use the park pressure from dbdat
        ii = find(abs(fpp(pn).park_p - dbdat.parkpres) < 300);
    end        
    if ~isempty(ii) 
        % use the last value minus the AST value (if there is one)
        PET(2) = fpp(pn).park_p(ii(end));
        PET(3) = fpp(pn).park_t(ii(end));
        PET(4) = fpp(pn).park_s(ii(end));
    end
    % keep an eye on the +/-100m criteria:
    if length(PET) > 1 & isempty(ii)
        disp('No park data in msg file within +/- 5m of log file value or 300m of expected park pressure')
%         keyboard
    end
    
    % Get PTS for mc 503 - PTS of deepest bin in ascending profile float.
    % is not being recorded as 503 at the moment, but as 500 PTS.
    if length(AST)<2
        if ~isempty(fpp(pn).p_calibrate)
            AST(2) = fpp(pn).p_calibrate(1);
        elseif ~isempty(fpp(pn).p_raw)
            AST(2) = fpp(pn).p_raw(1);
        end
    end
    if length(AST)<3
        
        if ~isempty(fpp(pn).t_calibrate)
            AST(3) = fpp(pn).t_calibrate(1);
        elseif ~isempty(fpp(pn).t_raw)
            AST(3) = fpp(pn).t_raw(1);
        end
    end
    if length(AST)<4
        if ~isempty(fpp(pn).s_calibrate)
            AST(4) = fpp(pn).s_calibrate(1);
        elseif ~isempty(fpp(pn).s_raw)
            AST(4) = fpp(pn).s_raw(1);
        end
    end
end
%assign some more times and pressures and positions as required.
FMT = min(ST);FLT = min(ST);
TST = FMT; %these are the same for iridiums
LMT = max(ST); LLT = max(ST);
DDET = AST(1); %Same for these floats.

%-----------------------------------------------------------------------
%check the times are in chronological order. Define the traj_mc_order for
%each cycle because multiple satellite connections means we can't just put
%ST in at the start. Also, last PTM only becuase the first one (or more) might be
%before DET.
%So, order ST, TST, FMT, LMT, TET AND DET, PTM 
%remember that the first part of the timing is for the previous profile.

times_previous = [ST TST FMT LMT TET];
tp_ind = [1:length(ST) ones(1,4)];
[~,ii] = sort(times_previous);

times_park = [DET PTM(:,1)'];
tc_ind = [1 1:size(PTM,1)];
[~,ij] = sort(times_park);

%seems AET and TST2 can be out of order when the CTD has failed to stop the
% profile for some reason. So sort AET and TST2:
times_surf = [AET TST2];
[~,ik] = sort(times_surf);

times_current = [DST DSP(:,1)' ...
    PST times_park(ij) ...
    PET(1) DDET AST(1) times_surf(ik) ];%remove DNT from the check
%     for now, need clarity on what it is (a minute value or a time?)
%     PET(1) DDET AST(1) DNT times_surf(ik) ]; 

times = [times_previous(ii) times_current];

if any(diff(times(~isnan(times))) < 0)
    disp('Times out of order!')
    ti = times(~isnan(times));
    ib = find(diff(ti) < 0);
    
    disp(datestr(ti(ib+1)))
    disp(ib+1)
%     fid = fopen('times_out_of_order.txt','a');
%     fprintf(fid,'%s\n',[fn ',' num2str(pn)]);
%     fclose(fid);
    
%     keyboard
end

%record the order for writing the netcdf file:
%need the MC codes and the index into each. Insert 301 (rep park pressure)
% and 903(surface offset pressure) which are
%extras in the trajectory_iridium_nc code.
mc_previous = [repmat(703,1,length(ST)), 700, 702, 704, 800];
traj_float_order = [200, repmat(290,1,size(PTM,1))];
surf_t = [600, 701];
mc_current = [100, repmat(190,1,size(DSP,1)), 250, ...
            traj_float_order(ij), 300, 301, 400, 500, surf_t(ik), 903];%, 501
%mc order information
traj(pn).traj_mc_order = mc_current;
%now the indices:
traj(pn).traj_mc_index = [1, 1:size(DSP,1), 1, ...
    tc_ind(ij), ones(1,7)];
%put the satellite information on the previous profile:
if pn > 1
    %if this is a re-process, remove the existing indices first
    if length(traj) ~= pn
        iclear = find(traj(pn-1).traj_mc_order == 703);
        traj(pn-1).traj_mc_order(iclear:end) = [];
        traj(pn-1).traj_mc_index(iclear:end) = [];
    end
    traj(pn-1).traj_mc_order = [traj(pn-1).traj_mc_order mc_previous(ii)];
    traj(pn-1).traj_mc_index = [traj(pn-1).traj_mc_index tp_ind(ii)];
else
    %zero profile
    traj(pn).on_deployment.traj_mc_order = mc_previous(ii);
    traj(pn).on_deployment.traj_mc_index = tp_ind(ii);
end


%now add all the information to the traj structure, and assign status
%flags and 'adjusted' information:
%
fld_n = {'DST','DSP' 'DET','PST','PTM','PET','DDET','AST',...
    'DNT','AET','TST2'};
fld_nminus1 = {'TST','FMT','FLT','LLT','LMT','TET'};
sub_fld = {'juld','pressure','temperature','salinity'};
%list the status values if we have obtained a successful number from the
%file. If no number, the default of 9 remains.
%adj values are used to denote if adjusted for clock time.
statval_n = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]; %default, not adjusted with RTC
adj_n = [0,0,0,0,0,0,0,0,0,0,0]; %
statval_nminus1 = [4, 4, 4, 4, 4, 2];
adj_nminus1 = [0,0,0,0,0,0];

if ~isempty(rtc_skew)
    statval_n = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; %set to 3 because of adjustment for RTC skew applied
    adj_n = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];%
    statval_nminus1 = [4, 4, 4, 4, 4, 3];
    adj_nminus1 = [0,0,0,0,0,1];
end
if estdst == 1
    %DST
    statval_n(1) = 3;
    adj_n(1) = 1;
    %TET too
    statval_nminus1(end) = 3;
    adj_nminus1(end) = 1;
end
% if estdsp == 1
%     statval_n(2) = 3;
%     adj_n(2) = 1;
% end
if esttst2 == 1 %this comes from the GPS now, so flag as 4
    statval_n(end) = 4;
    adj_n(end) = 0;
end
if estast == 1
    statval_n(7:9) = 3;
    adj_n(7:9) = 1; 
end
if estpet == 1
    statval_n(6) = 3;
    adj_n(6) = 1;
end
if estpst == 1
    statval_n(4) = 3;
    adj_n(4) = 1;
end

%all times are adjusted for rtc skew, unless they are satellite times. Even
%estimated times are adjusted.
for a = 1:length(fld_n)
    eval(['data = ' fld_n{a} ';'])
    [m,n] = size(data);
    if ~isnan(data) & (m == 1 & n == 1)
        traj(pn).(fld_n{a}).juld   = julian(str2num([datestr(data-rtc_skew,'yyyy mm dd HH MM SS')]));
        traj(pn).(fld_n{a}).stat = num2str(statval_n(a));
        traj(pn).(fld_n{a}).adj = adj_n(a);
    elseif n > 1
        %fields with multiple measurements:
        for c = 1:n
            %get rid of excess stat and adj fields from initial setup:
            if isfield(traj(pn).(fld_n{a}),'stat')
                traj(pn).(fld_n{a}) = rmfield(traj(pn).(fld_n{a}),'stat');
                traj(pn).(fld_n{a}) = rmfield(traj(pn).(fld_n{a}),'adj');
            end
            if c == 1 & isnan(data(:,1))
                traj(pn).(fld_n{a}).(sub_fld{c}) = NaN;
            elseif c == 1
                traj(pn).(fld_n{a}).(sub_fld{c}) = julian(str2num([datestr(data(:,1)-rtc_skew,'yyyy mm dd HH MM SS')]));
                stat = repmat(num2str(statval_n(a)),1,m);
                adj = repmat(adj_n(a),1,m);
            else
                traj(pn).(fld_n{a}).(sub_fld{c}) = data(:,c);
                stat = repmat(num2str(2),1,m);
                adj = zeros(1,m);
            end
            %index of NaNs
            imissing = isnan(data(:,c));
            stat(imissing) = '9';
            adj(imissing) = 0;
            eval(['traj(pn).' fld_n{a} '.' sub_fld{c} '_stat = stat;'])
            eval(['traj(pn).' fld_n{a} '.' sub_fld{c} '_adj = adj;'])
        end
    end
end

%now add the information to the previous profile:
%allow for multiple ST records (use repmat)
if pn > 1
    for a = 1:length(fld_nminus1)
        eval(['data = ' fld_nminus1{a} ';'])
        if ~isnan(data) %otherwise, set to defaults.
            if statval_nminus1(a) == 4 %satellite data, no adjustment for RTC
                traj(pn-1).(fld_nminus1{a}).juld   = julian(str2num([datestr(data,'yyyy mm dd HH MM SS')]));
            else
                traj(pn-1).(fld_nminus1{a}).juld   = julian(str2num([datestr(data-rtc_skew,'yyyy mm dd HH MM SS')]));
            end
            traj(pn-1).(fld_nminus1{a}).stat = repmat(num2str(statval_nminus1(a)),1,length(data));
            traj(pn-1).(fld_nminus1{a}).adj =repmat(adj_nminus1(a),1,length(data));
        end
    end
    %put in ST seperately. 
    if ~isnan(ST)
        for c = 1:length(ST)
            traj(pn-1).ST.juld(c) = julian(str2num([datestr(ST(c),'yyyy mm dd HH MM SS')]));
            traj(pn-1).ST.stat(c) = '4';
            traj(pn-1).ST.adj(c) = 0;
        end
        traj(pn-1).ST.lat = STlat;
        traj(pn-1).ST.lon = STlon;
    end
else
    %first profile, keep the deploy surface info with this cycle,
    %because we can't index it to cycle 0.
    %keep it in the field traj(1).on_deployment.ST .FMT, .TST, .LMT, .TET
    for a = 1:length(fld_nminus1)
        eval(['data = ' fld_nminus1{a} ';'])
        if ~isnan(data) %otherwise, set to defaults.
            if statval_nminus1(a) == 4 %satellite data, no adjustment for RTC
                traj(pn).on_deployment.(fld_nminus1{a}).juld   = julian(str2num([datestr(data,'yyyy mm dd HH MM SS')]));
            else
                traj(pn).on_deployment.(fld_nminus1{a}).juld   = julian(str2num([datestr(data-rtc_skew,'yyyy mm dd HH MM SS')]));
            end
            traj(pn).on_deployment.(fld_nminus1{a}).adj = adj_nminus1(a);
            traj(pn).on_deployment.(fld_nminus1{a}).stat = num2str(statval_nminus1(a));
        end
    end
    %put in ST seperately. 
    if ~isnan(ST)
        for c = 1:length(ST)
            traj(pn).on_deployment.ST.juld(c) = julian(str2num([datestr(ST(c),'yyyy mm dd HH MM SS')]));
            traj(pn).on_deployment.ST.stat(c) = '4';
            traj(pn).on_deployment.ST.adj(c) = 0;
        end
        traj(pn).on_deployment.ST.lat = STlat;
        traj(pn).on_deployment.ST.lon = STlon;
    end
end


%assign the clock offset in decimal days
traj(pn).clockoffset = rtc_skew;

%--------------------------------------------------------------
