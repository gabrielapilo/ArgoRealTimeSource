% PROCESS_PROFILE  Run decoding and processing of realtime Argo
%    float messages (after they have been stripped from the ftp download)
%
% INPUT
%   rawdat - struct with all repeated tranmissions for one profile
%   heads  - struct with ARGOS tranmission headers for one profile
%   b1tim  - struct with message num, time vector for each block1 message
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
% MODS:  JRD 29/5/2014 Add code for trajectory V3 files
%
% CALLED BY:  strip_argos_msg
%
% USAGE:  process_profile(rawdat,heads,b1tim,pmeta,dbdat,opts)

function  process_profile(rawdat,heads,b1tim,pmeta,dbdat,opts)

%  The ftp download presently happens every 6hr, but do not trust a message
%  to be complete until ~18hrs after it's first transmission time. We
%  also want to check back after about 2-3 days to make sure we got all
%  surface times/locations [just for drift info.] 
%
% To identify a given profile:
%   Use earliest trans date/time to identify a profile (because profile num
%   may be corrupted or non-unique, and date will be obviously plausible or
%   not, and because have 10day interval there should be no ambiguity.)
%
% Algorithm  (How stages of processing are flagged by "stage")
%   Stage will be [], and no further action will take place, if we resolve 
%   that this profile has already been processed.
%   If a profile is less than 18 hrs old, then it is too soon to process it
%   but we reset the Processing Record and set stage=0, to record that a
%   new profile has arrived.
%
%   If Profile > 18hrs old - check if already have a record for the profile.
%    - If not (it is new),  commence stage 1 (processing profile)
%      Set status(1)=-1 until successful completion, when set it to +1 
%
%    - If have previous record, and stage=1, and 3+ days old, start stage 2 
%      (final fix processing).
%      status(2)=-1 until set to 1 on successful completion
%
%   If want to force reworking stage 1 and/or stage 2 we use opts.redo to
%   override setting the 'stage' variable. To allow simultaneous reworking
%   both stages, the variable can be mutli-valued, eg stage = [1 2].
%
%   if the profile is properly decoded, export to text file archive (AT)
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
%  Apex China  = 6
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
%  Webb APF11 = 1019

global ARGO_SYS_PARAM
global PREC_FNM PROC_REC_WMO PROC_RECORDS
global ARGO_REPORT ARGO_RPT_FID

[ dbdat.argos_id dbdat.wmo_id ]

if nargin<6
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

if isempty(pmeta.ftptime)
   if opts.rtmode
      ftptime = julian(clock)-10/24;   % Estimate present UTC time
   else
      logerr(1,'PROCESS_PROFILE: ftptime required if rtmode~=1');
      return
   end
else
   ftptime = pmeta.ftptime;
end

% "qc" field is only found if edit_workfile has been used to manually trim
% the message packet
head = heads.dat;
satnam = heads.satnam;

if isfield(heads,'qc') && any(heads.qc~=0)
   ii = heads.qc~=0;
   head(ii,:) = [];
   satnam(ii) = [];
end

if isfield(b1tim,'qc') && any(b1tim.qc~=0)
   ii = find(b1tim.qc==0);
   b1tdat = b1tim.dat(ii,:);
else
   b1tdat = b1tim.dat;
end

% System tuning parameters (could be shifted to ARGO_SYS_PARAM ?)
Too_Old_Days = 11;         % Realtime: no interested beyond 10 and a bit days. 
First_Load_Time = ARGO_SYS_PARAM.run_time;  % Do first decode/load after 18 hrs (.75 days)
Final_Load_Time = 3;       % Do final decode/load after 3 days


jnow = julian(clock);      % Local time - now


% --- Check dates now because, although unlikely to be wrong, they are
% critical for identifying the profile and knowing if it is due for  
% processing.
			   
dt_min = [1997 1 1 0 0 0];
dt_max = [datestr(now+3,31)]; 
kk=strfind(dt_max,'-');
dt_max(kk)=' ';

dt_max=[str2num(dt_max(1:4)) 12 31 23 59 59];
dt_maxj=julian(dt_max);
dt_minj=julian(dt_min);

jdays = julian(head(:,1:6));

% Check dates
for jj = 1:size(head,1)
   if any(head(jj,1:6)<dt_min) || any(head(jj,1:6)>dt_max)
      logerr(2,['Implausible date/time components: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;
   elseif ~opts.redo & (jdays(jj)>ftptime || jdays(jj)<(ftptime-Too_Old_Days))
      logerr(2,['Implausible dates: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;
   elseif jdays(jj)<dt_minj || jdays(jj)>dt_maxj
      logerr(2,['Implausible date/time components: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;       
   end
end
   
gdhed = find(~isnan(jdays));
if isempty(gdhed)
   logerr(1,'No usable date info');
   return
end


jday1 = min(jdays(gdhed));

if ftptime-jday1<First_Load_Time
   % --- do no processing for now, but wait until likely that whole message 
   % has been transmitted. However, set stage=0 so that a processing record 
   % is created and saved, so that operator knows this new profile has 
   % arrived.
   stage = 0;
   np = 0;
   
else   
   % --- Open float file, find record for this profile
   if ispc
   fnm = [ARGO_SYS_PARAM.root_dir 'matfiles\float' num2str(dbdat.wmo_id)];
   else
   fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];       
   end
   stage = 1;
   if ~exist([fnm '.mat'],'file')
      logerr(3,[fnm ' not found - opening new float file']);
      np = 1;
   else
       
      load(fnm,'float');
    
      np = length(float);
      if isempty(float(np).jday)
          np = np-1;
      end
      tdiff = jday1 - float(np).jday(1);

      if abs(tdiff)>1
	 % For RT processing, tdiff should be ~0 [this is our last profile]
	 % or ~10 [this is the next profile].  If reprocessing, we may have
	 % an earlier profile - so now look to see if that is the case.
	 tdel = nan(1,np);
	 for kk = 1:np
	    if ~isempty(float(kk).jday)
	       tdel(kk) = jday1 - float(kk).jday(1);
	    end
	 end
	 [tdiff,nn] = min(abs(tdel));
	 if tdiff<1
	    np = nn;
	 end
      end
      
      if abs(tdiff)<1
	 % Generously allow present est of start time to be quite different to
	 % previous est, and still call it the same profile. Should only be
	 % non-identical if a subsequent ftp transfer somehow loses a previous
	 % early time or comes up with a new earlier time. 
	 
	 if isempty(float(np).proc_stage)
	    float(np).proc_stage = 1;
	 end
	 if float(np).rework==1
	    % Leave stage=1, but now clear the rework flag (only want to
	    % reprocess it once, not on every subsequent run!)
	    float(np).rework = 0;
	 elseif float(np).proc_stage==1 && ftptime-jday1>Final_Load_Time
	    stage = 2;
	 else
	    % Already fully handled this profile, so do no more.
	    stage = [];
	 end
	 
      elseif abs(tdiff-10)<2
	 % It seem this is the expected next profile - it is around 10 days later.
	 np = np+1;
	 
      else
	 % Date is not around 10 days from previous profile, but until
         % checked we should make this the next profile anyway 
	 tstr = num2str([jday1 float(np).jday(1)]); 
	 logerr(3,['Screwy times, old v new: ' tstr]);
	 np = np+1;
      end
   end

   % We may force a redo of stages, even if it is apparently not needed.  
   stage = unique([stage opts.redo]);
end   


prof = [];

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
   % (That program clears the flagg after generating the report page.)
   prec.new = 1;
end

%rearranged so have lat to pass to oxygen calibrations...AT 08/07/2008

if any(stage>=1)
   % ---- Resolve ARGOS date/position fixes  (both stage 1 and 2)
      
   % Save heads with dates, even if bad location info. The dates enable the 
   % profile to be identified, and it can then be saved to file (so recording
   % that stage 1 processing complete, and stopping attempts to rework it 
   % every 6 hours.) Any cast data might be of some use for timeseries QC. 
   % Of course, there is no other value in the profile if it has no location, 
   % so do not forward it to GDAC.
   
   if any(diff(jdays(gdhed))<0)
      % fixes are often out of order. If so, we reorder them. That is, after
      % this step, jday(1),lats(1) etc IS the first fix after surfacing. 
      % This is such a common event that we now do not report it!
      %logerr(4,'ARGOS fixes put in chrono order.');
      [tmp,ij] = sort(jdays(gdhed));
      gdhed = gdhed(ij);
   end

   % Identify and reject any lower-quality redundant location fixes 
   % Up to now it appears this never happens anyway!
   rej = resolve_dup_fixes(satnam(gdhed),head(gdhed,9),jdays(gdhed));   
   if any(rej)
      logerr(4,'Redundant ARGOS fixes removed.');
      gdhed(rej) = [];
   end

%   % resolve_dup_fixes now removes any same-time fixes  
%   if any(diff(jdays(gdhed))==0)
%      % Awkward and not right to have same-time fixes (don't know if this 
%      % will ever happen?)
%      logerr(4,'ARGOS fixes at identical time - one removed.');
%      kk = find(diff(jdays(gdhed))==0);
%      gdhed(kk) = [];
%   end
   
   % Check Argos location & time info (and for range -180<=lons<=180 )
   % Also find deepest point within a +/- .25degree range, and reject if 
   % not offshore (ie a very lenient test)
   lats = head(gdhed,7);  
   lons = head(gdhed,8);  
   
   [maxdeps,mindeps] = get_ocean_depth(lats,lons,0.03);
   inan = isnan(mindeps);
   deps = max(mindeps(~inan));
   kk = find(isnan(lats) | isnan(lons) | lats<-90 | lats>90 ...
       | lons<-180 | lons>360 | deps<0);
   if ~isempty(kk)
       logerr(2,'Implausible locations or location on land');
%        gdhed(kk) = [];
%        if isempty(gdhed)
           logerr(2,'No good location fixes or location on land!');
%        end
   end


   % *** Now replace this with test #20 ***
   %
   % Check speeds. Simple diagonal distance, lat corrected, converted
   % to metres. Force a minimum of 240 sec for delT, because (I guess)
   % different satellites might give near-simulataneous fixes, but with 
   % different small positioning biases. A small delT makes this look
   % like a large speed diff. Limiting delT also prevents divide-by-0.
   % Also allow a larger speed limit (than between profiles.)
   if length(gdhed)>1
      la = head(gdhed,7);  
      lo = head(gdhed,8);  
      lcor = cos(mean(la)*(pi/180));
      
      delT = diff(jdays(gdhed))*86400;   % Converts from days to seconds
      kk = find(delT<240);
      delT(kk) = 240;
      dist = sqrt(diff(la).^2 + (diff(lo)*lcor).^2)*111119;
      speed = dist ./ delT;
      if any(speed > 4)
	 logerr(3,'Unresolved excessive speeds between fixes');
      end
   end   
end

if any(stage>=1)
   % --- Decode the profile 
   %   (but wait until we have looked at date/pos data below, before 
   %    further work on the profile data)
      
   % Set status to "stage 1 has failed", until we have succeeded!
   prec.proc_status(stage) = -1;

   % Decode the new profile, Do not change dbdat.maker here - but check for
   % it in find_best_msg.
   
   if dbdat.maker==2 && dbdat.subtype==3
       % 
   elseif dbdat.maker==2 && dbdat.subtype==4
       % we need to reset the blocknumber field here because provors don't
       % have sensible numbers:
       for i=1:length(rawdat.blkno)

           cc=dec2hex(rawdat.dat(i,1:3),2)';
           cc=cc(:)';
           rawdat.messagetype(i)=hex2dec(cc(1));   
           if(rawdat.messagetype(i)==0);
               crc_no(i)=0;
%                rawdat.blkno(i)=1;
           else
               crc_no(i)=hex2dec(cc(2:5));
           end

       end
       tp=unique(rawdat.messagetype);
       jk=0;
       for i=1:length(tp)
           kl=find(rawdat.messagetype==tp(i));
           uni=unique(crc_no(kl));

           for j=1:length(uni)
               kk=find(crc_no(kl)==uni(j));
               jk=jk+1;
               rawdat.blkno(kl(kk))=jk;
           end
       end
   else
      %
   end
   
   if (isfield(opts,'nocrc'))
       if dbdat.maker==2 & dbdat.subtype==4
           jj=find(isnan(rawdat.dat));
           rawdat.dat(jj)=0;
       end
       
      [prof,fbm_rep,rawdat] = find_best_msg(rawdat,dbdat,opts);
   else
      [prof,fbm_rep,rawdat] = find_best_msg(rawdat,dbdat);
   end
      
   if isempty(prof)
      report_bad_prof(rawdat);
      fp = [];
   else
      if dbdat.maker==2
	 pos = head(gdhed,1:6);
	 fp = decode_provor(prof,dbdat,pos);
      else
          %need lat for oxygen processing:
	 fp = decode_webb(prof,dbdat,head(gdhed(1),7),ARGO_SYS_PARAM.processor);
      end
   end
   
   gotprofile = ~isempty(fp);
   if gotprofile
      fp.lat = head(gdhed,7);
      fp.lon = head(gdhed,8);
      fp.datetime_vec = head(gdhed,1:6);
      fp.jday = jdays(gdhed);
      %fp.jday_qc = ones(size(gdhed));
      fp.pos_qc = zeros(1,length(fp.lat),'uint8');
      fp.position_accuracy = char(head(gdhed,9));
      fp.satnam = satnam(gdhed);
      
      if exist('float','var') && length(float)>5    
	 %  check for rollover here!!!
	 fp.profile_number = profile_rollover(fp,float,dbdat);
      end
      
      np = fp.profile_number;
      if dbdat.subtype==3 & dbdat.maker==2  % provor seabird profiles with cycle 0
	 np = np+1;
      end
      if exist('float','var') & float(1).profile_number==0
	 np = np+1;
      end
      
      % Check if numbers of fields in structures are the same
      tempfloat = float(np-1);
      if length(fieldnames(tempfloat)) > length(fieldnames(fp));
          % Find missing fields in fp and add them
          missing_fields = setdiff(fieldnames(tempfloat),fieldnames(fp));
          for imiss = 1: length(missing_fields);     
              fp.(char(missing_fields(imiss))) = [];
          end
      end
      
      float(np) = fp;      

   elseif dbdat.maker~=2
      % If not Provor and no profile data, will still load a profile structure 
      % if some valid location fixes, so that the empty profile is recorded. 
      
      if np>1 && ~isempty(float(np-1).profile_number)
	 np = float(np-1).profile_number + 1;
      end

      float(np) = new_profile_struct(dbdat);

      float(np).lat = head(gdhed,7);
      float(np).lon = head(gdhed,8);
      float(np).datetime_vec = head(gdhed,1:6);
      float(np).jday = jdays(gdhed);
      %float(np).jday_qc = ones(size(gdhed));
      %float(np).position_qc = ones(size(gdhed));
      float(np).position_accuracy = char(head(gdhed,9));
      float(np).satnam = satnam(gdhed);
      
      logerr(1,'Empty or undecodable profile');
      if dbdat.subtype==3 & dbdat.maker==2
	 float(np).profile_number = np-1;
      else
	 float(np).profile_number = np;
      end
   end
   prec.profile_number = float(np).profile_number;
end


if any(stage>=1)
   % ---- Analyse and generate reports and products for this profile

   if gotprofile
      float = calibrate_p(float,np);
      
      % Apply prescribed QC tests to T,S,P. Need whole float array because 
      % previous profiles used in some tests. Also check for grounded float.      
      float = qc_tests(dbdat,float,np);
      if isfield(float,'p_desc_raw')
          float = qc_desc_tests(dbdat,float,np);
      end
      % Calibrate conductivity, salinity...

       [float,cal_rep] = calsal(float,np);

      % Thermal lag calc presently applies to SBE-41 & 41CP sensors only, and
      % uses an estimate of ascent-rate. We may have to actually provide
      % ascent-rate estimates (via the database).
      %  turn off for now!!!  turned back on - 25/11/2009
      
       float(np) = thermal_lag_calc(dbdat,float(np));
 
      % Range check (just to alert our personnel to investigate)
      check_profile(float(np));

      if ~isempty(gdhed)
	 % Estimate the time at which the float surfaced
	 float(np).jday_ascent_end = calc_ascent_end(...
	     b1tdat,rawdat.maxblk,dbdat,float(np));
     if isempty(float(np).jday_ascent_end)
         float(np).jday_ascent_end=float(np).jday(1);
     else
         prec.jday_ascent_end = float(np).jday_ascent_end;
         if abs(float(np).jday_ascent_end-float(np).jday(1))>=.9
             float(np).jday_ascent_end=float(np).jday(1);
         end
     end
	 % We only send a GTS message if none of the following tests were failed 
	 rejtests = [1 2 3 4];    
	 if isempty(opts.redo)
	    opts.redo=0;
	 end
     
	 % Build new profile netCDF file, and extend tech netCDF file
	 % Clear counts so that these files are exported.
     
	 if(length(float(np).p_raw)>0)
	    argoprofile_nc(dbdat,float(np));
	 end

	 if any(float(np).testsfailed(rejtests))
	    % Will not transmit this profile because of failing critical tests	 
	    logerr(3,'Failed critical QC, so no BUFR msg sent!'); 
        prec.gts_count = 99;
     elseif ~strcmp('hold',dbdat.status) & ~strcmp('evil',dbdat.status) & ...
             ~any(stage==2) && ~opts.redo
         % If not reprocessing, and not a "suspect" float, create tesac
         % file. Disabled, 2 July, 2018
         % 	    write_tesac(dbdat,float(np));
         
         BOM_write_BUFR;
         if outcome == 1
             prec.gts_count = 0;
         else
             prec.gts_count = 99;
         end
	 end
% 	 export_text_files
        
	 prec.prof_nc_count = 0;	 
	 if opts.rtmode && any(stage>=1)
	    techinfo_nc(dbdat,float,np);
	    prec.tech_nc_count = 0;
	 end
	 if np==1
	    metadata_nc(dbdat,float);
	    prec.meta_nc_count = 0;
	 end
	 
	 % Update float summary plots and web page
	 % first save the data to this point - AT July 2011
	 save(fnm,'float','-v6');

	 if opts.rtmode
	    try
            web_profile_plot(float(np),dbdat);
	       web_float_summary(float,dbdat,1);
	       time_section_plot(float);
	       waterfallplots(float);
	       locationplots(float);
	       tsplots(float);
	    catch
	       logerr(5,['plots failed in process profile for float ' ...
			 num2str(dbdat.wmo_id) ' profile ' num2str(float(np).profile_number)]);
	    end
	 end
	    
	 prec.proc_status(stage) = 1;      
	 logerr(5,['Successful stage 1, np=' num2str(float(np).profile_number)]);
      else
	 logerr(5,['Stage 1 complete but no good fixes, np=' ...
		   num2str(float(np).profile_number)]);	 
      end
      
      float(np).cal_report = cal_rep;
   else
      logerr(5,['Stage 1 complete but no usable profile, np=' ...
		num2str(float(np).profile_number)]);   
   end
   
   % proc record update
   prec.stage_ecnt(1,:) = ARGO_REPORT.ecnt;
   float(np).fbm_report = fbm_rep;
   float(np).stage_ecnt(1,:) = ARGO_REPORT.ecnt;
   float(np).stage_jday(1) = jnow;
   float(np).ftp_download_jday(1) = ftptime;
   if opts.rtmode
      float(np).stg1_desc = ['RT auto V' ARGO_SYS_PARAM.version];
   else
      float(np).stg1_desc = ['reprocess V' ARGO_SYS_PARAM.version];
   end
end


pmeta.np = np;
if exist('float','var') && ~isempty(float)
   pmeta.pnum = float(np).profile_number;
else
   pmeta.pnum = [];
end

if any(stage==2) | opts.redo
   % ---- Generate Stage 2 products 
   
   if ~isempty(gdhed) && any(~isnan(float(np).p_raw))      
      if opts.rtmode
	 % Extract everything required for trajectory files, and load into
         % traj_work files.
         try
 	 [traj,trajmco] = load_traj_apex_argos(rawdat,heads,b1tim,pmeta,dbdat,float);
% 	 
% 	 % Only send Trajectory netCDF files if some fixes, and there is a
% 	 % profile. Clear counts so that this file is exported
	 trajectory_nc(dbdat,float);      
	 prec.traj_nc_count = 0;
         end
      end
      prec.proc_status(2) = 1;
%       logerr(5,['Successful stage 2, np=' num2str(float(np).profile_number)]);
   else
      prec.proc_status(2) = -1;
%       logerr(5,['Stage 2 complete but either no good fixes OR no profile. np=' ...
% 		num2str(float(np).profile_number)]);
   end

   prec.stage_ecnt(2,:) = ARGO_REPORT.ecnt;
   float(np).stage_ecnt(2,:) = ARGO_REPORT.ecnt;
   float(np).stage_jday(2) = jnow;
   float(np).ftp_download_jday(2) = ftptime;
   if opts.rtmode
      float(np).stg2_desc = ['RT auto V' ARGO_SYS_PARAM.version];
   else
      float(np).stg2_desc = ['reprocess V' ARGO_SYS_PARAM.version];
   end
end


% ---- Web page update and Save data (both stage 1 & 2)
if any(stage>0)
   float(np).proc_stage = max(stage);
   float(np).proc_status = prec.proc_status;
   % Write float array back to file
   save(fnm,'float','-v6');

   % If saving intermediate files..
   if opts.savewk>0
      save_workfiles(rawdat,heads,b1tim,pmeta,opts.savewk);
   end
   
   try
      % Stage 2 adds new info to profile page, so generate it at both stages. 
      web_profile_plot(float(np),dbdat);
   end
end


if ~isempty(stage)
   % Write postprocessing rec back to file, so that these records are saved 
   % even if the this program is interrupted. 
   prec.ftptime = ftptime;
   prec.proc_stage = max(stage);
   PROC_RECORDS(nprec) = prec;
   load(PREC_FNM,'ftp_details');
   save(PREC_FNM,'PROC_RECORDS','ftp_details','-v6');
end

return

%-----------------------------------------------------------------------------
