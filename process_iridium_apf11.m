%  process_iridium_apf11 function
%
% This function does all decoding for one profile and returns the float
% structure to the main which is embedded in strip_argos_msg.  APF11s are
% fundamentally different in how they deliver the data so this needs to be
% handled in a separate script, even though these are iridium floats. 
%
% INPUT
%       
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
%
% From dbdat we obtain:
% np0 - correction to float number due to "profiles" counted after
%       deployment but while still in the cardboard box
% subtype - Webb format number
% oxy     - does it have oxygen?
% ice     - does it have ice detection?
% tmiss   - does it have transmissiometer?

% subtypes are presently: 
%  pre-Apex   = 0
%  Apex1      = 1
%  Apex early Korea = 2
%  Apex Indian = 4
%  Apex Korea = 10
%  Apex2      = 11
%  Apex2ice Korea = 20
%  Apex2 SBE DO Korea = 22
%  Apex2ice   = 28   
%  Apex2oxyice= 31   
%  Apex2oxy   = 32   
%  Apex2oxyTmiss = 35
%  Apex2SBEoxy Indian = 38
%  ApexOptode Korea = 40
%  Apex2var Park T,P = 43
%  Apex2var Park T,P + ice detection = 44
%  ApexAPF9a   = 1001
%  ApexAPF9aOptode = 1002
%  ApexAPF9aIce = 1003
%  ApexIridium = 1004 - with and without ice (decode_iridium)
%  ApexSurfaceT Indian = 1005
%  ApexIridiumO2 = 1006  (decode_iridium) with and without flbb sensor
%  ApexIridiumSBEOxy = 1007  (decode_iridium)
%  ApexIridiumSBEOxy = 1008 - with flbb
%  ApexAPF9Indian = 1010
%  ApexAPF9 with an extra point = 1011
%  ApexAPF9 format (oxygen, 1002) with extra point = 1012
%  ApexAPF9 with engineering data at end of data = 1014
%  Solo Polynya floats = 1015
%  Seabird Navis Vanilla float = 1016
%  Seabird Navis Optical Oxygen = 1017
%  MRV Solo II Vanilla = 1018
%  Webb APF11  = 1019
%  ApexAPF9OxyFLBB (no CDOM, Anderaa optode) = 1020
%  ApexAPF9OxyFLBB (Indian floats, Anderaa optode) = 1022
%  Webb APF11 latest format including RBR float = 1023
% usage:

function process_iridium_apf11(pmeta,dbdat,opts)

global ARGO_SYS_PARAM
global PREC_FNM PROC_REC_WMO PROC_RECORDS
global ARGO_REPORT ARGO_RPT_FID

[ dbdat.argos_id dbdat.wmo_id ]
idatapath = ARGO_SYS_PARAM.iridium_path;

fn=pmeta.ftp_fname;      % science log
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
np=str2num(fn(ss(1)+1:ss(2)-1));
np=np-dbdat.np0;
if(np==0);return;end

p_raw=[];
stage = 1;
pro = new_profile_struct(dbdat);

if ~exist([fnm '.mat'],'file')
    logerr(3,[fnm ' not found - opening new float file']);
    float = pro;           %new_profile_struct(dbdat);
    %   pro = new_profile_struct(dbdat);
else
    
    load(fnm,'float');
    
    stage = unique([stage opts.redo]);
    ss=strfind(fn,'.');
%     np=str2num(fn(ss(1)+1:ss(2)-1))-dbdat.np0;
    if(length(float)<np);
        float(np)=new_profile_struct(dbdat);
    end
    
    if(isempty(float(np).proc_stage))
        float(np).proc_stage=1;
    end
    if float(np).rework==1
        % Leave stage=1, but now clear the rework flag (only want to
        % reprocess it once, not on every subsequent run!)
        float(np).rework = 0;
        %these are irrelevant for iridium since you need to copy the
        %profile file back ot the upper irectory to reprocess so it's
        %always a deliberate move...
        %      elseif float(np).proc_stage==1
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
    pro.profile_number=np  ; %-dbdat.np0;
    pro.position_accuracy='G';
    pro.SN=dbdat.maker_id;
    ff=0;
    
    try
        fclose(fid);
    end
    
    cullAPF11Missions_iridium(dbdat,np);  %& No mission
%     information for older apf11s!  Therefore must create mission for the
%     successive profiles: and be flexible so can handle newer floats which
%     DO report missions

    dtype=0;  %start out initialized to 0 because you can't decode data 
    % if you don't know when it was collected!
    
    fid=fopen([idatapath fn]);
    j=0;
    gg=fgetl(fid);
    %first lines are park descent data but don't rely on this - use the message line:
    pdm=0;  %park descent mission
    pkm=0;  %park mission
    ddm=0;  %deep descent mission
    prom=0; %profile mission (ascent to surface) - cp sampled
    prospot=0;  % profile mission - spot sampled values
    surfD=0;  % surface offset data - larger for RBR floats and may contain in-air measurements
    gps=0;  %gps data
    previouslocation=[];
    thislocation=[];
    numlines=0;
    while gg~=-1
        numlines=numlines+1;
        if strfind(gg,'Park Descent Mission')
            dtype = 1;
            pro.jday_start_descent_to_park=pts(gg);
        elseif strfind(gg,'Park Mission')
            dtype = 2;
            pro.jday_descent_to_park=pts(gg);
        elseif strfind(gg,'Deep Descent Mission')
            dtype = 3;
            pro.jday_start_descent_to_profile=pts(gg);
        elseif strfind(gg,'Profiling Mission')
            pro.jday_ascent_start=pts(gg);
            dtype = 4;
        elseif strfind(gg,'Surface Mission')
            pro.jday_ascent_end=pts(gg);
            pro.jday=pro.jday_ascent_end;
            dtype = 5;
        elseif strfind(gg,'GPS')
            gps=gps+1;
            comma=strfind(gg,',');
            pro.jday_location(gps)=pts(gg);
            pro.GPSfixtime(gps)=pro.jday_location(gps);
            pro.lat(gps)=str2num(gg(comma(2)+1:comma(3)-1));
            if length(comma) == 4
                pro.lon(gps)=str2num(gg(comma(3)+1:comma(4)-1));
                pro.GPSsatellites = str2num(gg(comma(4)+1:end));
            else
                pro.lon(gps)=str2num(gg(comma(3)+1:end));
            end
            if pro.lon(gps)<0; pro.lon(gps)=360+pro.lon(gps); end
            pro.datetime_vec(gps,:)=gregorian(pro.jday_location(gps));
            if numlines<10
                previouslocation=[previouslocation gps];
            else
                thislocation=[thislocation gps];
            end
            if dbdat.RBR % theses have a surface pressure offset measured 
%                 at the same time as the GPS but not identified in any way ;-(
                  gg=fgetl(fid);
                  surfD=surfD+1;
                  if gg~=-1
                      [pro.jday_surfpres(surfD),pro.surfpres(surfD)]=pts(gg);
                  end
            end
        elseif strfind(gg,'Prelude/Self')
            dtype=0;
        else   % decode the data based on case here:
            switch dtype
                case 0
                    
                case 1  %descent to park
                    pdm=pdm+1;
                    comma=strfind(gg,',');
                    if strfind(gg,'CTD_PTSC')
                       [pro.jday_descent_to_park(pdm),pro.P_descent_to_park(pdm),pro.T_descent_to_park(pdm),...
                          pro.S_descent_to_park(pdm), pro.C_descent_to_park(pdm)]=pts(gg); 
                    else
                    [pro.jday_descent_to_park(pdm),pro.P_descent_to_park(pdm)]=pts(gg);
                    end
                case 2   %park mission
                    pkm=pkm+1;
%                     if dbdat.subtype==1023
                    if strfind(gg,'CTD_PTSC')
                        [pro.jday_descent_to_park(pkm),pro.park_p(pkm),pro.park_t(pkm),...
                            pro.park_s(pkm), pro.park_c(pkm)]=pts(gg);
                    elseif strfind(gg,'CTD_PT')
                        [pro.park_jday(pkm),pro.park_p(pkm),pro.park_t(pkm)]=pts(gg);
                        
                    elseif strfind(gg,'CTD_PTS')
                        [pro.park_jday(pkm),pro.park_p(pkm),pro.park_t(pkm),pro.park_s(pkm)]=pts(gg);
                    end
                case 3 %deep descent (to profile)
                    ddm=ddm+1;
                    if dbdat.RBR
                        [pro.descent_jday(ddm),pro.descent_p(ddm),pro.descent_t(ddm),...
                            pro.descent_s(ddm),pro.descent_c(ddm)]=pts(gg);  %descent to profile
                    else
                        [pro.descent_jday(ddm),pro.descent_p(ddm)]=pts(gg);  %descent to profile
                    end
                case 4  % profile mission - note this is more complicated because there are spot sampled values as well as cp values:
                    % spot sampled format 1023 RBR & new APF11 (2017 &
                    % later models)
                    if ~isempty(strfind(gg,'CTD_PTSC')) | ~isempty(strfind(gg,'CTD_PTS'))
                        prospot=prospot+1;
                        [pro.jday_ascent_to_surface_spotsamp(prospot),pro.P_ascent_to_surface_spotsamp(prospot), ...
                            pro.T_ascent_to_surface_spotsamp(prospot),pro.S_ascent_to_surface_spotsamp(prospot)] = pts(gg);
                        
                    elseif strfind(gg,'CTD_CP')  %format 1023 and 1019, non RBR floats
                        prom=prom+1;
                        [jday_ascent_to_surface,pro.p_raw(prom),pro.t_raw(prom),pro.s_raw(prom),pro.nsamps(prom)]=pts(gg);
                        [jday_ascent_to_surface,p_raw(prom),t_raw(prom),s_raw(prom),ns(prom)]=pts(gg);
                    elseif strfind(gg,'CTD,')  % spot sampled original APF11 format - 1019
                        prospot=prospot+1;
                        [pro.jday_ascent_to_surface_spotsamp(prospot),pro.P_ascent_to_surface_spotsamp(prospot), ...
                            pro.T_ascent_to_surface_spotsamp(prospot),pro.S_ascent_to_surface_spotsamp(prospot)] = pts(gg);
                        
                    end
                    
                case 5  %surface pressure offset report. Here is where the continuous profiling information is recorded
                    % note that the time is not the time of the data, but
                    % the time the data was recorded.
                    if strfind(gg,'CTD_PTSC')
                        surfD=surfD+1;
                        [pro.jday_surfpres(surfD),pro.surfpres(surfD),pro.surfT(surfD),pro.surfS(surfD),pro.surfC(surfD)]=pts(gg);
                    elseif ~isempty(strfind(gg,'CTD_CP+'))
                        prom=prom+1;
                        [pro.jday_ascent_to_surface(prom),pro.p_raw(prom),pro.t_raw(prom),pro.s_raw(prom),pro.cndc_raw(prom),...
                            pro.nsamps(prom)]=pts(gg);
                    elseif ~isempty(strfind(gg,'CTD_CP')) %add CP for new APF11 (>2017 models)
                        prom=prom+1;
                        [pro.jday_ascent_to_surface(prom),p_raw(prom),t_raw(prom),s_raw(prom),...
                            ns(prom)]=pts(gg);
                    elseif ~dbdat.RBR %all other old APF11
                        [pro.jday_surfpres,pro.surfpres]=pts(gg);
                    end
                       
            end
            
        end
            gg=fgetl(fid);
    end
    
 % need to store CP surface offset value for RBR flaot into correct place:
 % assume this is always and only the last CP point...
 if dbdat.RBR & ~isempty(p_raw)
     pro.surfpresCP=pro.p_raw(end);
     pro.surf_TCP=pro.t_raw(end);
     pro.surf_SCP=pro.s_raw(end);
     pro.surf_CCP=pro.cndc_raw(end);
     pro.surf_jdayCP=pro.jday_ascent_to_surface(end);
     pro.surf_nsampsCP=pro.nsamps(end);
     pro.p_raw(end)=[];
     pro.s_raw(end)=[];
     pro.t_raw(end)=[];
     pro.cndc_raw(end)=[];
     pro.jday_ascent_to_surface(end)=[];
     pro.nsamps(end)=[];
 end
    
 % need to turn around the arrays to go in the correct direction: except
 % RBR floats are already in the correct direction... 

 if ~dbdat.RBR & ~isempty(p_raw)
    irev=[length(p_raw):-1:1];
    %     pro.jday_ascent_to_surface=jday_ascent_to_surface(irev);
    pro.p_raw=p_raw(irev);
    pro.t_raw=t_raw(irev);
    pro.s_raw=s_raw(irev);
    pro.nsamps=ns(irev);
 end
 if ~isempty(pro.p_raw)   
    kk=find(pro.p_raw==0 & pro.t_raw==0 & pro.s_raw==0);
    if ~isempty(kk)
        pro.p_raw(kk)=[];
        pro.t_raw(kk)=[];
        pro.s_raw(kk)=[];
        if dbdat.RBR
            pro.cndc_raw(kk)=[];
        end
        pro.nsamps(kk)=[];
        %         pro.jday_ascent_to_surface(kk)=[];
    end
   
    pro.npoints=length(pro.p_raw);

 
    pro.n_parkaverages=length(pro.park_jday);
 end     
     
    % now we need to sort out the location information - one position is
    % reported from the end of the previous surface drift and needs to be
    % moved to that profile:
    
    if np==1
%         if length(pro.lat)>1
%             for ll=2:length(pro.lat)
%                 pro.lat(ll-1)=pro.lat(ll);
%                 pro.lon(ll-1)=pro.lon(ll);
%                 pro.jday_location(ll-1)=pro.jday_location(ll);
%                 pro.GPSfixtime(ll-1)=pro.jday_location(ll);
%                 pro.datetime_vec(ll-1,:)=gregorian(pro.jday_location(ll));
%             pro.lat(end)=[];
%             pro.lon(end)==[];
%             pro.jday_location(end)=[];
%             pro.GPSfixtime(end)=[];
%             pro.datetime_vec(end,:)=[];
%                
%             end
    else
        % ensure that date is around the time of the previous profile
        % before add it in at that spot:
        
        if ~isempty(previouslocation)
                pl=length(previouslocation);
            
            if ~isnan(float(np-1).lat)
                %             lk=find(pro.jday_location-float(np-1).jday_location(1) <1);
                %             if ~isempty(lk)
                lv=length(float(np-1).lat);
                float(np-1).lat(lv+1:lv+pl)=pro.lat(previouslocation);
                float(np-1).lon(lv+1:lv+pl)=pro.lon(previouslocation);
                float(np-1).jday_location(lv+1:lv+pl)=pro.jday_location(previouslocation);
                float(np-1).GPSfixtime(lv+1:lv+pl)=pro.jday_location(previouslocation);
                float(np-1).datetime_vec(lv+1:lv+pl,:)=pro.datetime_vec(previouslocation,:);
                
                pro.lat(previouslocation)=[];
                pro.lon(previouslocation)=[];
                pro.jday_location(previouslocation)=[];
                pro.GPSfixtime(previouslocation)=[];
                pro.datetime_vec(previouslocation,:)=[];
                if isempty(pro.lat);pro.lat=nan;end
                if isempty(pro.lon);pro.lon=nan;end
                
            else
                if isempty(float(np-1).lat)
                    float(np-1).lat=nan;
                end
                if isnan(float(np-1).lat)
                    %                 lm=find(diff(pro.jday_location)>1);
                    %                 if ~isempty(lm)
                    %                     lk=1:lm(1)
                    lv=length(float(np-1).lat)-1;
                    float(np-1).lat(lv+1:lv+pl)=pro.lat(previouslocation);
                    float(np-1).lon(lv+1:lv+pl)=pro.lon(previouslocation);
                    float(np-1).jday_location(lv+1:lv+pl)=pro.jday_location(previouslocation);
                    float(np-1).GPSfixtime(lv+1:lv+pl)=pro.jday_location(previouslocation);
                    float(np-1).datetime_vec(lv+1:lv+pl,:)=pro.datetime_vec(previouslocation,:);
                    
                    %now we need to regenerate the profile file for this previous cycle:
                    float(np-1).position_accuracy='G';
                    if ~isempty(float(np-1).jday)
                        argoprofile_nc(dbdat,float(np-1));
                    end
                    
                    pro.lat(previouslocation)=[];
                    pro.lon(previouslocation)=[];
                    pro.jday_location(previouslocation)=[];
                    pro.GPSfixtime(previouslocation)=[];
                    pro.datetime_vec(previouslocation,:)=[];
                    if isempty(pro.lat);pro.lat=nan;end
                    if isempty(pro.lon);pro.lon=nan;end
                end
            end
        end
        pro.pos_qc = zeros(1,length(pro.lat),'uint8');
        
        %also need to check location information:
        if ~isempty(pro.lat) && ~isnan(pro.lat)
            if any(~isnan(pro.lat))
                [maxdeps,mindeps] = get_ocean_depth(pro.lat,pro.lon,0.03);
                deps = nanmin(mindeps);
            end
        else
            deps = NaN;
        end
        if isempty(pro.lat) | isempty(pro.lon) | isnan(deps) || deps < 0;
            logerr(2,'Implausible locations');
            goodfixes = [];
            pro.lat = NaN;
            pro.lon = NaN;
            pro.pos_qc = 9;
            if isempty(goodfixes)
                logerr(2,'No good location fixes!');
            end
        end
        %this is where we should now be doing the position interpolation if
        %needed.
        %                 % check for missing profile locations from ice floats and
        % add to the affected profiles:
        try
            [float,pro,gennc]=interpolate_locations(dbdat,float,pro);
        catch
            logerr(5,'Interpolate_locations.m fails for this float')
        end
    end
    
end


    %now open system log file and vitals log file and read further technical data:
    fclose(fid);
    
    % first deal with missing gps locations for a profile: This will allow
    % us to interpololate positions if necessary
    if isempty(pro.jday_location)
        pro.jday_location=pro.jday_ascent_end;
        pro.datetime_vec=gregorian(pro.jday_ascent_end);        
    end
    dot=strfind(fn,'.');
    slog=dirc([idatapath fn(1:dot(2)) '*system_log.txt']);

    if ~isempty(slog)
        fid=fopen([idatapath slog{1,1}]);  %System log
        %     else
        %         fid=-1
        %         return
        %     end
        %     if fid<=0
        %         return
        %     else
        
        gg=fgetl(fid);
        while(gg~=-1)
            if ~isempty(gg)
                if dbdat.subtype~=1023
                    ll=strfind(gg,'do_park');
                    if(~isempty(ll))
                        lk=strfind(gg,'Adjusting Buoyancy');
                        if ~isempty(lk)
                            pro.parkpistonpos = str2num(gg(lk+21:end));
                        end
                    end
                    ll=strfind(gg,'do_dive');
                    if(~isempty(ll))
                        lk=strfind(gg,'Adjusting Buoyancy');
                        if ~isempty(lk)
                            pro.profilepistonpos = str2num(gg(lk+21:end));
                        end
                    end
                    
                    ll=strfind(gg,'do_ascent');
                    if(~isempty(ll))
                        lk=strfind(gg,'Adjusting Buoyancy');
                        if ~isempty(lk)
                            pro.surfacepistonpos = str2num(gg(lk+21:end));
                        end
                    end
                else
                    ll2=strfind(gg,'PARK_DESCENT');
                    if(~isempty(ll2))
                        lk=strfind(gg,'Adjusting Buoyancy');
                        if ~isempty(lk)
                            pro.parkpistonpos = str2num(gg(lk+21:end));
                        end
                    end
                    ll2=strfind(gg,'DEEPDESCENT');
                    if(~isempty(ll2))
                        lk=strfind(gg,'Adjusting Buoyancy');
                        if ~isempty(lk)
                            pro.profilepistonpos = str2num(gg(lk+21:end));
                        end
                    end
                    
                    ll2=strfind(gg,'ASCENT');
                    if(~isempty(ll2))
                        lk=strfind(gg,'Adjusting Buoyancy');
                        if ~isempty(lk)
                            pro.surfacepistonpos = str2num(gg(lk+21:end));
                        end
                    end
                end
                gg=fgetl(fid);
                while isempty(gg)
                gg=fgetl(fid);
                end
            end
        end
            fclose(fid);
    end
    
    vlog=dirc([idatapath fn(1:dot(2)+1) '*vitals_log.csv']);
    fid=fopen([idatapath vlog{1}]);  %Vitals log - technical data - unknown where it belongs  
    techno=0;
    if fid<=0
        
    else
        gg=fgetl(fid);
        while(gg~=-1)
            if ~isempty(strfind(gg,'vitals'))
        
                techno=techno+1;
                pro.Tech_jday(techno)=pts(gg);
                data=textscan(gg(comma(2)+1:end),'%f','delimiter',',');
                pro.airbladderpres(techno)=data{1}(1);
                pro.batteryvoltage(techno)=data{1}(2);
                pro.humidity(techno)=data{1}(3);
                pro.leak_voltage(techno)=data{1}(4);
                pro.p_internal(techno)=data{1}(5);
                pro.coulomb_counter(techno)=data{1}(6);
                
            end
            gg=fgetl(fid);
        end
    end
    
    fclose(fid);
                        
    float(np) = pro;
    prec.profile_number = float(np).profile_number;
    
    %still need to plot and further process float:
    cal_rep = zeros(1,6);
    if(pro.npoints>0)  %do we have data?!
        float = calibrate_p(float,np);
        
        % Apply prescribed QC tests to T,S,P. Need whole float array because
        % previous profiles used in some tests. Also check for grounded float.
        float = qc_tests(dbdat,float,np);
        
        % Calibrate conductivity, salinity...
        
        [float,cal_rep] = calsal(float,np);
        
        % Thermal lag calc presently applies to SBE-41 & 41CP sensors only, and
        % uses an estimate of ascent-rate. We may have to actually provide
        % ascent-rate estimates (via the database).
        %  turn off for now!!!  turned back on 25/11/2009 AT
        
        float(np) = thermal_lag_calc(dbdat,float(np));
    end
    
    % Build new profile netCDF file, and extend tech netCDF file
    % Clear counts so that these files are exported.
    if(length(float(np).p_raw)>0)
        argoprofile_nc(dbdat,float(np));
        if(np==1)
            metadata_nc(dbdat,float)
            web_select_float
        end
    end
    % now re-generate netcdf files that had interpolation done:
    if exist('gennc','var') == 1
        if any(gennc) > 0
            for g=1:length(gennc)
                if gennc(g) == np
                    continue
                end
                if gennc(g) > 0
                    if ~isempty(float(gennc(g)).jday) & ~isempty(float(gennc(g)).wmo_id)
                        argoprofile_nc(dbdat,float(gennc(g)));
                        %                         write_tesac(dbdat,float(gennc(g)));
                    end
                end
            end
        end
    end
    
    if(pro.npoints>0)  %do we have data?!
        
        % Range check (just to alert our personnel to investigate)
        check_profile(float(np));
        rejtests = [2 3 4 13];
        
        if any(float(np).testsfailed(rejtests))
            % Will not transmit this profile because of failing critical tests
            logerr(3,'Failed critical QC, so no BUFR msg sent!');
            prec.gts_count = 99;
        elseif opts.rtmode && ~strcmp('suspect',dbdat.status)
            % If not reprocessing, and not a "suspect" float, create tesac file
%             write_tesac(dbdat,float(np));
            
            % BOM write BUFR call
            BOM_write_BUFR;
            if outcome == 1
                prec.gts_count = 0;
            else
                prec.gts_count = 99;
            end                
        elseif strcmp('dead',dbdat.status) | strcmp('exhausted',dbdat.status)
            % dead float returned - send email to alert operator -
            mail_out_dead_float(dbdat.wmo_id);
        end
        
        %         export_text_files
        prec.prof_nc_count = 0;
    end
    
    if opts.rtmode
        techinfo_nc(dbdat,float,np);
        prec.tech_nc_count = 0;
    end
    if np==1
        metadata_nc(dbdat,float);
        web_select_float
        prec.meta_nc_count = 0;
    end
    
    % Update float summary plots and web page
    
    try
        web_float_summary(float,dbdat,1);
        time_section_plot(float);
        waterfallplots(float);
        locationplots(float);
        tsplots(float);
        %        try
        %             trajectory_nc(dbdat,float,np);
        %        end
        prec.traj_nc_count = 0;
        prec.proc_status(2) = 1;
        logerr(5,['Successful stage 2, np=' num2str(float(np).profile_number)]);
    catch
        logerr(5,['error in plotting routines - ' num2str(dbdat.wmo_id) ' profile ' num2str(float(np).profile_number)])
    end
    
    prec.proc_status(1) = 1;
    logerr(5,['Successful stage 1, np=' num2str(float(np).profile_number)]);
if isempty(thislocation)
    logerr(5,['Stage 1 complete but no good fixes, np=' ...
        num2str(float(np).profile_number)]);
end

float(np).cal_report = cal_rep;


% proc record update
prec.stage_ecnt(1,:) = ARGO_REPORT.ecnt;
%       float(np).fbm_report = fbm_rep;  only relevant for find_best_msg
float(np).stage_ecnt(1,:) = ARGO_REPORT.ecnt;
float(np).stage_jday(1) = jnow;
float(np).ftp_download_jday(1) = pmeta.ftptime;
if opts.rtmode
    float(np).stg1_desc = ['RT auto V' ARGO_SYS_PARAM.version];
else
    float(np).stg1_desc = ['reprocess V' ARGO_SYS_PARAM.version];
end
% ---- Web page update and Save data (both stage 1 & 2)
if any(stage>0)
    float(np).proc_stage = max(stage);
    float(np).proc_status = prec.proc_status;
    % Write float array back to file
    save(fnm,'float','-v6');
    
    % Stage 2 adds new info to profile page, so generate it at both stages.
    web_profile_plot(float(np),dbdat);
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
    function v = calc_volt9a(dd)
                    
        v = dd*.077 + .486;
%--------------------------------------------------------------------
%     function ttjd=ttjd(gg)
%         
%         comma=strfind(gg,',');
%         tt=str2num(gg(comma(1)+1):gg(comma(2)+1));
% 
%         ttjd=julian([str2num(tt(1:4)) str2num(tt(5:6)) str2num(tt(7:8)) ...
%              str2num(tt(10:11)) str2num(tt(12:13)) str2num(tt(14:15))]);
%--------------------------------------------------------------------
        function [varargout]=pts(gg)  % this takes the line from the science log
            %         and turns it into physical variables
            
            out = textscan(gg,'%s','delimiter',',');
            out = out{:};
            %skip the first code part in this context
            varargout = cell(1,length(out)-1);
            b=1;
            for a = 2:length(out)
                varargout{b} = out{a};
                if a > 2
                    varargout{b} = str2num(varargout{b});
                end
                b = b+1;
            end
            tt = out{2};
            varargout{1}=julian([str2num(tt(1:4)) str2num(tt(5:6)) str2num(tt(7:8)) ...
                str2num(tt(10:11)) str2num(tt(12:13)) str2num(tt(14:15))]);
        
%--------------------------------------------------------------------
                        