%  process_iridium function
%
% This function does all ldecoding for one porfile and returns the float
% structure to the main which is embedded in strip_argos_msg.
%
% INPUT
%       filenam - filename of the profile to be processed - this contains all
%           relevant information as to profile number and float id.
%   pmeta  - struct with download metadata
%   dbdat  - database record for this float
%   opts  - [optional] options, a structure containing any of the following 
%           fields:
%     .rtmode - [default from SYS PARAM] 0=delayed-mode reprocessing 
%     .savewk - [default from SYS_PARAM]]  
%               0=do not save intermediate work files
%               1=save file per float (overwrite previous)
%               2=save file per profile   
%     .redo   - {default .redo=[]} processing stages to redo. Eg .redo=1 means
%               force reworking stage 1 for every suitable profile
%               encountered. Can have .redo=1 or =2 or =[1 2]%
% OUTPUT  
%   profiles appended to float mat-files; 
%   processing reports, 
%   GTS message, netcdf files,
%   web pages updated and plots generated.
%
% Author: Jeff Dunn CMAR/BoM Aug 2006
%
% CALLED BY:  strip_argos_msg
%
% USAGE: process_iridium(pmeta,dbdat,opts)
% usage:

function process_phyfiles(pmeta,dbdat,opts)

global ARGO_SYS_PARAM
global PREC_FNM PROC_REC_WMO PROC_RECORDS
global ARGO_REPORT ARGO_RPT_FID

[ dbdat.argos_id dbdat.wmo_id ]
idatapath = ARGO_SYS_PARAM.iridium_path;

fn=pmeta.ftp_fname;
jnow=julian(clock);      % Local time - now
if nargin<3
    opts = [];
end

if ~isfield(opts,'rtmode') || isempty(opts.rtmode)
    opts.rtmode = ARGO_SYS_PARAM.rtmode;
end
if ~isfield(opts,'savewk') || isempty(opts.savewk)
    opts.savewk = ARGO_SYS_PARAM.save_work_files;
end
if ~isfield(opts,'redo')
    opts.redo = [];
end
if ~isfield(opts,'nocrc')
    opts.nocrc = 0;
end

fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
ss=strfind(fn,'.');
np=str2num(fn(ss(1)-3:ss(1)-1));
if(np<0);return;end

stage = 1;
pro = new_profile_struct(dbdat);


if ~exist([fnm '.mat'],'file')
    logerr(3,[fnm ' not found - opening new float file']);
    float(np+1) = pro;           %new_profile_struct(dbdat);
    %   pro = new_profile_struct(dbdat);
else

    load(fnm,'float');

    stage = unique([stage opts.redo]);
    ss=strfind(fn,'_');
    np=str2num(fn(ss(2)+1:ss(2)+3));
    if(length(float)<np+1);
        float(np+1)=new_profile_struct(dbdat);
    end

    if(isempty(float(np+1).proc_stage))
        float(np+1).proc_stage=1;
    end
    if float(np+1).rework==1
        % Leave stage=1, but now clear the rework flag (only want to
        % reprocess it once, not on every subsequent run!)
        float(np+1).rework = 0;
        %these are irrelevant for iridium since you need to copy the
        %profile file back ot the upper irectory to reprocess so it's
        %always a deliberate move...
        %      elseif float(np+1).proc_stage==1
        %         stage = 2;
        %      else
        %         % Already fully handled this profile, so do no more.
        %         stage = [];
    end
end

if ~isempty(stage)
    % --- Find the processing record for this float

    nprec = find(PROC_REC_WMO==dbdat.wmo_id);
    if isempty(nprec)
        logerr(3,['Creating new processing record as none found for float ' ...
            num2str(dbdat.wmo_id)]);
        nprec = length(PROC_REC_WMO) + 1;
        PROC_REC_WMO(nprec) = dbdat.wmo_id;
        if isempty(PROC_RECORDS)
            % This only ever happens when initialising a new processing system
            PROC_RECORDS = new_proc_rec_struct(dbdat,np);
        else
            PROC_RECORDS(nprec) = new_proc_rec_struct(dbdat,np);
        end
    end

    if any(stage==2)
        % Add to record from earlier processing stages
        prec = PROC_RECORDS(nprec);
    else
        % New profile, so get a record set to initial state:
        %  - IDs and profile number loaded
        %  - .new = 1
        %  - .*_count = 99
        %  - proc_status and stage_ecnt zeroed
        prec = new_proc_rec_struct(dbdat,np);
    end

    % .new tells the daily report program that this record has been updated.
    % (That program clears the flagged after generating the report page.)
    prec.new = 1;
end


% now begin real processing of the data - do not do this in a subroutine as
% was done for 'decode_webb'

if any(stage==1)
    % --- Decode the profile
    %   (but wait until we have looked at date/pos data below, before
    %    further work on the profile data)

    % Set status to "stage 1 has failed", until we have succeeded!
    prec.proc_status(1) = -1;

    %trust the profile number reported by the float - but check for rollover later!
%     pro.profile_number=np;
    pro.position_accuracy='G';
    pro.SN=dbdat.maker_id;
    pro.subtype=1015;

    fid=fopen([idatapath fn]);
    j=0;
    gg=fgetl(fid);
 
    % here is where WHOI Solo format diverges from Apex iridium format:
    dp=[];
    ds=[];
    dt=[];
    dc=[];
    dd=[];
    jdays=[];
    dlat=[];
    dlon=[];
    
    while gg(1)~='='
        if strmatch('INTERNAL ID',gg)
%             pro.SN=str2num(gg(41:end));
        elseif strmatch('WMO ID',gg)
            pro.wmo_id=str2num(gg(41:end));
        elseif strmatch('PROFILE NUMBER',gg)
            pro.profile_number=str2num(gg(41:end));
        elseif strmatch('PI',gg)
            pro.PI=gg(41:end);
        elseif strmatch('WMO INSTRUMENT',gg)
            pro.inst_type=gg(41:end);
        elseif strmatch('WMO RECORDER',gg)
            pro.rec_type=gg(41:end);
        elseif strmatch('DRIFT PRESSURE',gg)
            dp=[dp str2num(gg(41:end))];
        elseif strmatch('DRIFT TEMPERATURE',gg)
            dt=[dt str2num(gg(41:end))];
        elseif strmatch('DRIFT SALINITY',gg)
            ds=[ds str2num(gg(41:end))];
        elseif strmatch('DRIFT MEASUREMENT TIME',gg)
            dc=[dc gg(41:end)];
        elseif strmatch('SYSTEM FLAGS AT DEPTH',gg)
            pro.syst_flags_depth=gg(41:end);
        elseif strmatch('SYSTEM FLAGS AT SURFACE',gg)
            pro.syst_flags_surface=gg(41:end);
        elseif strmatch('INTERNAL PRESSURE AT DEPTH',gg)
            pro.p_internal=str2num(gg(41:end));
        elseif strmatch('INTERNAL PRESSURE AT SURFACE',gg)
            pro.p_internal_surface=str2num(gg(41:end));
        elseif strmatch('CPU BATTERY VOLTAGE (VOLTS) AT DEPTH',gg)
            pro.CPUpumpvoltage=str2num(gg(42:end));
        elseif strmatch('CPU BATTERY VOLTAGE (VOLTS) AT SURFACE',gg)
            pro.CPUpumpSURFACEvoltage=str2num(gg(42:end));
        elseif strmatch('PUMP BATTERY VOLTAGE (VOLTS) AT DEPTH',gg)
            pro.SBEpumpvoltage=str2num(gg(43:end));
        elseif strmatch('PUMP BATTERY VOLTAGE (VOLTS) AT SURFACE',gg)
            pro.SBEpumpSURFACEvoltage=str2num(gg(43:end));
        elseif strmatch('PUMP ADJUST DURING DRIFT',gg)
            dd=[dd str2num(gg(43:end))];
            pro.driftpump_adj=dd;
        elseif strmatch('TOTAL PUMP TIME IN/OUT DEPTH',gg)
            pro.pumpin_outatdepth=gg(43:end);
        elseif strmatch('TOTAL PUMP TIME IN/OUT SURFACE',gg)
            pro.pumpin_outatsurface=gg(43:end);
        elseif strmatch('GPS LOOP',gg)
            pro.GPScounter=gg(41:end);
        elseif strmatch('PRESSURE OFFSET',gg)
            pro.surfpres=str2num(gg(41:end));
        elseif strmatch('POSITION LINE',gg)
            if isempty(findstr(gg(41:end),'999.999'))
                pro.previous_position=gg(41:end);
            end
        end
        gg=fgetl(fid);
    end
    
    
    % put park data in place:
    
    pro.park_p = dp;
    pro.park_s = ds;
    pro.park_t = dt;
    pro.park_date = dc;
    pro.nparksamps=length(pro.park_p);
%     pro.park_jday = julian(
    
    gg=fgetl(fid);
    ll=0;

    while gg(1)~='='
        if ~isempty(findstr(gg,'LATITUDE'))
            
        else
            dlat=[str2num(gg(1:12)) dlat ];
            dlon=[str2num(gg(13:23)) dlon ];
            yyyy=str2num(gg(24:27));
            mm=str2num(gg(29:30));
            dd=str2num(gg(32:33));
            hh=str2num(gg(35:36));
            minu=str2num(gg(38:39));
            ss=str2num(gg(41:42));
            jdays=[julian([yyyy mm dd hh minu ss]) jdays ];
            ll=ll+1;
            dtvec(ll,:)=[yyyy mm dd hh minu ss];
        end
        gg=fgetl(fid);
    end
    
    pro.jday=jdays;
    pro.jday_ascent_end=pro.jday(1);
    pro.lat=dlat;
    pro.lon=dlon;
    pro.datetime_vec=dtvec;
    
    gg=fgetl(fid);
    kk=0;
    % now we should be in the profile data:
    while ~isempty(gg) & gg(1)~=-1
        kk=kk+1;
        data=str2num(gg);
        pro.p_raw(kk)=data(1);
        pro.t_raw(kk)=data(2);
        pro.s_raw(kk)=data(3);
        gg=fgetl(fid);
    end
    pro.t_calibrate=pro.t_raw;
    pro.s_calibrate=pro.s_raw;
    pro.p_calibrate=pro.p_raw;
    pro.npoints=length(pro.p_raw);
    
 %check whether date is reasonable:
    
    dt_min = [1997 1 1 0 0 0];
    dt_max = [datestr(now+3,31)];
    kk=strfind(dt_max,'-');
    dt_max(kk)=' ';
    kk=strfind(dt_max,':');
    
    dt_max=[str2num(dt_max(1:4)) 12 31 23 59 59];
    dt_maxj=julian(dt_max);
    dt_minj=julian(dt_min);

    head=gregorian(jdays);
    [m,n]=size(head);
    for h=1:m
        if any(head(h,1:6)<dt_min) || any(head(h,1:6)>dt_max)
            logerr(2,['Implausible date/time components: ' num2str(head(h,1:6))]);
            jdays = NaN;
        elseif jdays(h)<dt_minj || jdays(h)>dt_maxj
            logerr(2,['Implausible date/time components: ' num2str(head(h,1:6))]);
            jdays(h) = NaN;
        end
        gdhed = find(~isnan(jdays));
        if isempty(gdhed)
            logerr(1,'No usable date info');
            return
        end
    end

%check this information here:
deps = get_ocean_depth(pro.lat,pro.lon);
kk = find(isnan(pro.lat) | isnan(pro.lon) | pro.lat<-90 | pro.lat>90 ...
    | pro.lon<-180 | pro.lon>360 | deps<0 );
if ~isempty(kk) | isempty(pro.lat) | isempty(pro.lon);
    logerr(2,'Implausible locations');
    goodfixes = 1:length(pro.lat);
    goodfixes(kk)=[];
    pro.lat(kk) = NaN;
    pro.lon(kk) = NaN;
%     pro.jday(kk) = [];
    if isempty(goodfixes)
        logerr(2,'No good location fixes!');
        %                     try
        %                         [latarr,lonarr]=interpolate_locations(dbdat);
        %                     end
    end
end


fclose(fid);

float(np+1) = pro;
    prec.profile_number = float(np+1).profile_number;

    %still need to plot and further process float:
    cal_rep = zeros(1,6);
    if(pro.npoints>0)  %do we have data?!
         float = calibrate_p(float,np+1); 
         
        % Apply prescribed QC tests to T,S,P. Need whole float array because
        % previous profiles used in some tests. Also check for grounded float.
        float = qc_tests(dbdat,float,np+1);

        % Calibrate conductivity, salinity... - not for these!

%         [float,cal_rep] = calsal(float,np+1);

        % Thermal lag calc presently applies to SBE-41 & 41CP sensors only, and
        % uses an estimate of ascent-rate. We may have to actually provide
        % ascent-rate estimates (via the database).
        %  turn off for now!!!  turned back on 25/11/2009 AT

%         float(np+1) = thermal_lag_calc(dbdat,float(np+1));
    end
    
    % Build new profile netCDF file, and extend tech netCDF file
    % Clear counts so that these files are exported.
    if(length(float(np+1).p_raw)>0)
        argoprofile_nc(dbdat,float(np+1));
        if(np==0)
            metadata_nc(dbdat,float)
        end
    end

    if(pro.npoints>0)  %do we have data?!

        % Range check (just to alert our personnel to investigate)
        check_profile(float(np+1));
        rejtests = [2 3 4 13];

        if any(float(np+1).testsfailed(rejtests))
            % Will not transmit this profile because of failing critical tests
            logerr(3,'Failed critical QC, so no TESAC msg sent!');
        elseif opts.rtmode && ~strcmp('suspect',dbdat.status)
            % If not reprocessing, and not a "suspect" float, create tesac file
            write_tesac(dbdat,float(np+1));

            % BOM write BUFR call
            BOM_write_BUFR;

            prec.gts_count = 0;
        elseif strcmp('dead',dbdat.status)
            % dead float returned - send email to alert operator - 
            mail_out_dead_float(dbdat.wmo_id);
        end
    
%         export_text_files
        prec.prof_nc_count = 0;
    end
    
    if opts.rtmode
        techinfo_nc(dbdat,float,(np+1));
        prec.tech_nc_count = 0;
    end
    if (np+1)==1
        metadata_nc(dbdat,float);
        web_select_float
        prec.meta_nc_count = 0;
    end

    % Update float summary plots and web page

    if opts.rtmode
        
        web_float_summary(float,dbdat,1);
        time_section_plot(float);
        waterfallplots(float);
        locationplots(float);
        tsplots(float);
%         trajectory_nc(dbdat,float,np+1);
        prec.traj_nc_count = 0;
        prec.proc_status(2) = 1;
        logerr(5,['Successful stage 2, np=' num2str(float(np+1).profile_number)]);
    end

    prec.proc_status(1) = 1;
    logerr(5,['Successful stage 1, np=' num2str(float(np+1).profile_number)]);
else
    logerr(5,['Stage 1 complete but no good fixes, np=' ...
        num2str(float(np+1).profile_number)]);
end

float(np+1).cal_report = cal_rep;


% proc record update
prec.stage_ecnt(1,:) = ARGO_REPORT.ecnt;
%       float(np+1).fbm_report = fbm_rep;  only relevant for find_best_msg
float(np+1).stage_ecnt(1,:) = ARGO_REPORT.ecnt;
float(np+1).stage_jday(1) = jnow;
float(np+1).ftp_download_jday(1) = pmeta.ftptime;
if opts.rtmode
    float(np+1).stg1_desc = ['RT auto V' ARGO_SYS_PARAM.version];
else
    float(np+1).stg1_desc = ['reprocess V' ARGO_SYS_PARAM.version];
end
% ---- Web page update and Save data (both stage 1 & 2)
if any(stage>0)
    float(np+1).proc_stage = max(stage);
    float(np+1).proc_status = prec.proc_status;
    % Write float array back to file
    save(fnm,'float','-v6');

    % Stage 2 adds new info to profile page, so generate it at both stages.
    web_profile_plot(float(np+1),dbdat);
end


if ~isempty(stage)
    % Write postprocessing rec back to file, so that these records are saved
    % even if the this program is interrupted.
    prec.ftptime = pmeta.ftptime;
    prec.proc_stage = max(stage);
    PROC_RECORDS(nprec) = prec;
    load(PREC_FNM,'ftp_details');
    save(PREC_FNM,'PROC_RECORDS','ftp_details','-v6');
end
    
return


%--------------------------------------------------------------------
%  (256*h1 + h2) converts 2 hex (4-bit) numbers to an unsigned byte. 

function bb = h2b(dd,sc)

bb = (256*dd(1) + dd(2)).*sc;

%--------------------------------------------------------------------
function t = calc_temp(dd)

t = (256*dd(1) + dd(2)).*.001;
if t > 62.535
   t = t - 65.536;
end

%--------------------------------------------------------------------
function v = calc_volt(dd)

v = dd*.1 + .4;

%--------------------------------------------------------------------
function v = calc_volt9(dd)

v = dd*.078 + .5;
%--------------------------------------------------------------------
%--------------------------------------------------------------------
function v = calc_volt9a(dd)

v = dd*.077 + .486;
%--------------------------------------------------------------------

