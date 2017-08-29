% STRIP_ARGOS_MSG  Main program for decoding and processing realtime Argo
%    float messages (retrieved by ftp from Argos)
%
% INPUT
%   fnm   - name of argos message dump file (created by script 'ftp_get_argos') 
%   flist - list of WMO or Argos id numbers of floats to process [only if you
%           want to restrict this]. (Program converts these to Argos numbers
%           when used to check against ftp message.)   If flist not supplied,
%           will process all floats found in the float master spreadsheet.
%   opts  - [optional] options, a structure containing any of the following 
%           fields:
%     .rtmode - [default from SYS PARAM] 0=delayed-mode reprocessing 
%     .tr_now - [default from SYS PARAM]
%                 0/1  on/off:  Transmit to GTS, GDAC immediately  
%     .savewk - [default from SYS_PARAM]]  
%               0=do not save intermediate work files
%               1=save file per float (overwrite previous)
%               2=save file per profile   
%     .redo   - {default .redo=[]} processing stages to redo. Eg .redo=1 means
%               force reworking stage 1 for every suitable profile
%               encountered. Can have .redo=1 or =2 or =[1 2]
%     .prec_fnm  - non-default processing records filename (without ".mat") 
%               If new, this need to be pre-made (manual or PROC_RECS_REBUILD)
%
% OUTPUTS
%   - profiles appended to float mat-files
%   - TESAC message for GTS
%   - netCDF files for GDACs, 
%   - reports generated and emailled,
%   - webpages and plots updated, 
%   - intermediate workfiles optionally created.
%
% Author: Jeff Dunn CSIRO-CMAR/BoM July-Nov 2006
%
% CALLS: process_profile  idcrossref  getdbase
%        In this file:  process_one  (trim_dat) 
%
% EXAMPLE:   opts.rtmode = 0;
%            opts.savewk = 1;
%            fnm = 'argos_downloads/argos292.log';
%            flist = 5900850;
%            strip_argos_msg(fnm,flist,opts)
%
% USAGE: strip_argos_msg(fnm,flist,opts)

function strip_argos_msg(fnm,flist,opts)

% MODS:  many not recorded
%  6/5/2014 JRD Extract extra data for traj V3 files

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global ARGO_REPORT  ARGO_RPT_FID
global PREC_FNM PROC_REC_WMO PROC_RECORDS
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

% *** Hardcoded parameters
fclose('all');
close('all')

dd2=[];
maxblk = 50;       % Maxblk is a safe max number of blocks

blocklen = 32;     % So far, blocks are at most this long

maxreps = 60;      % The most reps of a block you would expect.

loc_time = 10/24;  % Rough localtime offset from UTC (eg EST is +10hrs)

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

%our_id = '02039';  now set in set_sys_params
% Our Argos ID, which marks the beginner of header lines 
our_id=ARGO_SYS_PARAM.our_id


getdbase(0);
if isempty(THE_ARGO_O2_CAL_DB)
   % Must be first call - so load the oxygen calibration details database
   try
      getO2caldbase;
   end
end

if nargin<2 || isempty(flist)
   % No list of floats specified, so use getdbase to load the float ID 
   % array and extract the list of ids for all our floats.
   flist = [];
   argosidlist = ARGO_ID_CROSSREF(:,2);
else
   % A list was supplied, and we allow it to contain WMO *or* Argos IDs - we
   % decide what they are and convert all to Argos IDs.  
   argosidlist = [];
   nfl = length(flist);
   [tmp,iwmo,i1] = intersect(flist,ARGO_ID_CROSSREF(:,1));
   if ~isempty(i1)
      argosidlist = ARGO_ID_CROSSREF(i1,2);
   end
   if length(i1)<nfl
      [tmp,iarg,i2] = intersect(flist,ARGO_ID_CROSSREF(:,2));
      if ~isempty(i2)
         argosidlist = [argosidlist; ARGO_ID_CROSSREF(i2,2)];
      end
      if length(i1)+length(i2)<nfl
         % Some IDs are not in database
         kk = 1:nfl;
         kk([iarg iwmo]) = [];
         flist = flist(:)';
         logerr(3,['Do not recognise float IDs: ' num2str(flist(kk))]);
      end
   end
end

% --- Set control variables from "opts" argument or system parameters
if nargin<3
   opts = [];
end

if ~isfield(opts,'rtmode') || isempty(opts.rtmode)
   opts.rtmode = ARGO_SYS_PARAM.rtmode;
end
if ~isfield(opts,'tr_now') || isempty(opts.tr_now)
   opts.tr_now = ARGO_SYS_PARAM.transmit_now;
end
if ~isfield(opts,'savewk') || isempty(opts.savewk)
   opts.savewk = ARGO_SYS_PARAM.save_work_files;
end
if ~isfield(opts,'redo')
   opts.redo = [];
end
if ~isfield(opts,'prec_fnm')
   opts.prec_fnm = [];
end


% Open the report file. If this fails then reports will go to 2 (stderr).
% Then initialize report structure.
fclk = fix(clock);
tmp = sprintf('%04d%02d%02d_%02d:%02d',fclk(1:5));
if ispc
rptfnm = [ARGO_SYS_PARAM.root_dir 'reports\R' tmp '.txt'];
else
rptfnm = [ARGO_SYS_PARAM.root_dir 'reports/R' tmp '.txt']; 
end

ARGO_RPT_FID = fopen(rptfnm,'a+');
if ARGO_RPT_FID<2
   disp(['WARNING: Cannot open report file ' rptfnm]);
   ARGO_RPT_FID = 2;
end
logerr(0);
fnm = deblank(fnm);
logerr(5,['Processing file ' fnm]);


% Open the processing record file and load the records
if ~isempty(opts.prec_fnm)
   PREC_FNM = opts.prec_fnm;   
elseif opts.rtmode
   PREC_FNM = [ARGO_SYS_PARAM.root_dir 'Argo_proc_records'];
else
   PREC_FNM = [ARGO_SYS_PARAM.root_dir 'reprocessing_records'];
end
if ~exist([PREC_FNM '.mat'],'file')
   disp(['Cannot open processing records file ' PREC_FNM]);
   disp('This should only occur on the first ever processing run (see ')
   disp('system initialisation instructions).')
   error('Run terminated so that error can be resolved!')
else
   load(PREC_FNM,'PROC_RECORDS');
   PROC_REC_WMO = [];
   if ~isempty(PROC_RECORDS)
      % This should always be the case, except when initialising a new system
      for ii = 1:length(PROC_RECORDS)
	 PROC_REC_WMO(ii) = PROC_RECORDS(ii).wmo_id;
      end
   end
end


npro = 0;
nlin = 0;


if isempty(strmatch(fnm,'iridium'))
   
   [dum,ftp_fname] = fileparts(fnm);

   % Open the input file
   fid = fopen(fnm,'r');
   if fid<1
      logerr(1,['STRIP_ARGOS_MSG: Unable to open input file ' fnm]);
      fclose(ARGO_RPT_FID);
      error(['STRIP_ARGOS_MSG: Unable to open input file ' fnm]);
   end

   % Read first line of input file
   nxtline = fgetl(fid);

   % Extract UTC date of ftp download
   if isempty(nxtline)
      nxtline = fgetl(fid);
   end
   if length(nxtline)>=20 && strncmp(nxtline(1:3),'UTC',3)
      tmp = sscanf(nxtline(1:20),'UTC %d-%d-%d %d:%d');
      ftptime = julian([tmp([3 2 1 4 5])' 0]);
      nxtline = fgetl(fid);
   elseif strncmp(nxtline(1:3),'Try',3)  
      % 2006 Argos format ... untested!!!
      yy = strfind(fnm(1,:),'log');
      year = str2num(fnm(yy-7:yy-6))+2000;
      if year>2098
	 year = year-100;
      end
      while isempty(strfind(nxtline,'UTC'))
	 nxtline=fgetl(fid);
      end
      day=str2num(nxtline(15:17));    % Why not handle as in case above ? JRD
      ti1=str2num(nxtline(19:20));
      ti2=str2num(nxtline(21:22));
      dv=datevec(datenum(year,1,1,ti1,ti2,0) + day-1);
      ftptime=julian(dv);
      nxtline = fgetl(fid);
      
      nxtline = fgetl(fid);
      nxtline = fgetl(fid);
   elseif(strncmp(nxtline(1:3),'PRV',3)) || (strncmp(nxtline(1:3),'prv',3)) 
      % 2001 Argos format
      yy=strfind(fnm(1,:),'log');
      year=str2num(fnm(yy-7:yy-6))+2000;
      day=str2num(ftp_fname(9:end))+9;
      if(day>365);day=day-365;year=year+1; end         % What about leap years!  JRD
      dv=datevec(datenum(year,1,1,0,0,0) + day-1);
      ftptime=julian(dv);
   else
      % Need to estimate this (from last fix date in file)
      [lstdate,err] = date_ftp_file(fid);
      if err>=0
	 ftptime = julian(datevec(lstdate+2));
	 if ftptime > .1 + julian(clock)-loc_time;
	    logerr(3,['FTP file time apparently in the future by ' ...
		      num2str(ftptime-(julian(clock)-loc_time)) ' days']);
	 end
      else
	 logerr(1,'Need to resolve a date for input file before proceeding');
	 fclose(ARGO_RPT_FID);
	 fclose(fid);
	 return
      end
   end


   % set up a blank array to use to preallocate space (because that is faster)
   nblank = maxreps*maxblk;
   blank = nan([nblank blocklen]);

   argosid = -1;
   plino = 0;        % Line number for this profile
   ndat = 0;         % Count of message lines

   % loop, reading and identifying one line at a time from the input file.
   % When a new float-profile is encountered (or at the end of the input file), 
   % process the profile previously collated.

   possible_test=[];
   pos_test1=[];
   pos_test2=[];
   blk=[];
   nxtline2=[];
   cnt2=[];
   dbdat=[];

   while ischar(nxtline)
      nlin = nlin+1;
      
      if length(nxtline)<15
	 % EMPTY or short lines occur and are not of interest
	 
      elseif strcmp(nxtline(1:4),'    ')
	 % NOT A HEADER line

	 if ~strcmp(nxtline(5:8),'    ')
	    % probably a block line1 (the first segment) - let's see if it 
	    % starts with a date to confirm this

	    yr = sscanf(nxtline(6:10),'%d');
	    if length(yr)~=1 || yr<1999 || yr>2020
	       logerr(3,['STRIP: Strange date Line#' num2str(nlin) '> ' nxtline]);
	    end
	    try
	       jd=julian([str2double(nxtline(7:10)) str2double(nxtline(12:13)) str2double(nxtline(15:16))...
			  str2double(nxtline(18:19)) str2double(nxtline(21:22)) str2double(nxtline(24:25))]);
	    end
	    
	    nxtline2 = fgetl(fid);

	    % Decode the first 4 hex numbers, and extract the block number
	    [dd,cnt] = sscanf(nxtline(37:end),'%2x');

	    if cnt<4 || length(nxtline2)<8 || ~strcmp(nxtline2(5:8),'    ')
	       %designed to catch first lines only of a block with no further data...
	       nxtline=nxtline2;
	       nxtline2=fgetl(fid);
	       if length(nxtline)>36 && ~strcmp(nxtline(1:5),'     ')
		  [dd,cnt] = sscanf(nxtline(37:end),'%2x');
	       else
		  if nxtline<0         % nxtline is a char array, so this is a
				       % strange test ??? JRD
				       break             % So where do we end up with this ??? JRD
		  end
		  if length(nxtline2) >= 37
		     [dd2,cnt2] = sscanf(nxtline2(37:end),'%2x');
		  end
	       end
	    elseif length(nxtline2)>10 && strcmp(nxtline2(1:4),'    ')
	       % designed to catch argos downloads that 
	       % end with first line of a block and nothing else...
	       [dd2,cnt2] = sscanf(nxtline2(37:end),'%2x');
	    else
	       nxtline2=[];
	    end

	    if cnt>1; blk = dd(2);  end

	    % if cnt==4; possible_test(1) = dd(3); possible_test(2) = dd(4); end

	    % we need a new method to detect test messages for APF9 controller boards:
% if dbdat.maker~=2
	    if(~isempty(cnt2))
	       
	       if cnt==4 & cnt2==4 && blk==1; 
		  pos_test1(1) = dd(4); 
		  pos_test1(2) = dd2(1);
		  pos_test1(3) = dd2(2);
		  pos_test1(4) = dd2(3);
		  pos_test1(5) = dd2(4);
	       end
	    end
	    if cnt==4 && blk==2 & ~isempty(dd2);
	       pos_test2(1) = dd(4); 
	       pos_test2(2) = dd2(1);
	       pos_test2(3) = dd2(2);
	    end
	    
	    % this only works for APF8 controller boards:
	    %          if(exist('old_ptest'))
	    %              if(blk~=oldblk & old_ptest(1)==possible_test(1) & old_ptest(2)==possible_test(2))
	    %                  %this is a test block from deployment - remove
	    %                  oldblk=blk;
	    %                  blk=nan;       % Flag as junk
	    %                  %we need to get rid of the header for this bit as well...
	    %                  nhead=max(0,nhead-1);
	    %                  plino=max(0,plino-1);
	    %                  old_ptest=possible_test;
	    %              end
	    %          else
	    %              old_ptest=possible_test;
	    %              oldblk=blk;
	    %          end

	    % now try using the apf9 method which will be more accurate - one float
	    % tripped over this at a higher profile number...


	    %now check APF9s for test messages: check software revision dates
	    if blk==1 & ~isempty(dbdat)
	       try
		  if h2b(pos_test1(4:5),1) == dbdat.controlboardnum
		     %this is a test block from deployment - remove
		     blk=nan;       % Flag as junk
				    % we need to get rid of the header for this bit as well...
				    nhead=max(0,nhead-1);
				    plino=max(0,plino-1);
		  end
	       end
	       
	    elseif blk==2 & ~isempty (pos_test1)  & ~isempty (pos_test2)          
	       if pos_test1(1:3)==pos_test2(1:3)
		  %this is a test block from deployment - remove
		  blk=nan;       % Flag as junk
				 %we need to get rid of the header for this bit as well...
				 nhead=max(0,nhead-1);
				 plino=max(0,plino-1);
	       end
	    end            


	    if cnt<=1 || blk<1 || blk>=maxblk || (blk ==1 & length(nxtline)<25)
	       % We get bad block numbers often - so don't make a fuss of it!
	       blk = nan;        % Flag as junk
        end
% end

        if cnt>0
	       ndat = ndat+1;
	       if ndat>nblank
		  logerr(1,'Pre-allocated rawdat.dat is not large enough!')
	       end
	       plino = plino+1;
	       rawdat.dat(ndat,1:cnt) = dd;
	       rawdat.blkno(ndat) = blk;
	       rawdat.lineno(ndat) = plino;
	       rawdat.juld(ndat) = jd;
	    end
	    nseg = 1;

	    if blk==1
	       tmp = sscanf(nxtline(6:25),'%d-%d-%d %d:%d:%d')';
	       if length(tmp)==6
		  nb1 = nb1+1;
		  b1tim.dat(nb1,1:7) = [dd(3) tmp];  % loads repeat-count in dat(:,1)
		  b1tim.lineno(nb1) = plino;
	       end
	    end
	    
	 else
	    
	    % looks like any line 2-8 of a  block, so just decode and store
	    % it as the next segment of 'cnt' (usually 4) hex numbers

	    [dd,cnt] = sscanf(nxtline(37:end),'%2x');
	    if cnt>0
	       ii = 4*nseg + (1:cnt);
	       rawdat.dat(ndat,ii) = dd;
	       nseg = nseg+1;
	    end
	 end
	 
      elseif strcmp(nxtline(1:5),our_id)
	 % A HEADER LINE. First decode it, and see if is the start of a new profile

	 [id,num,t1,t2,satnam,p_err,datcel,timcel,lat,lon] = ...
	     strread(nxtline,'%d %d %s %s %s %s %s %s %f %f',1);
	 
	 if length(num)~=1 || num~=argosid
	    % Starting a NEW PROFILE..
	    
	    
	    clear old_ptest  %so will check new profile agains itself, not the previous profile
	    pos_test1 = [];
	    pos_test2 = [];
        
        if ndat>0 && any(argosidlist==argosid)
            try
                % Unless we have just started, process the previous profile
                npro = process_one(rawdat,heads,b1tim,pmeta,dbdat,opts,npro);
            catch Me
                mail_out_argos_log_error(fnm,dbdat.wmo_id)
                logerr(5,['error in processing argos float - ' num2str(dbdat.wmo_id)])
                logerr(5,['Message: ' Me.message ])
                for jk = 1:length(Me.stack)
                    logerr(5,Me.stack(jk).file)
                    logerr(5,['Line: ' num2str(Me.stack(jk).line)])
                end
            end
        end
	    
	    argosid = num;	 
	    if length(num)~=1
	       % Bad ID num 
	       argosid = -1;
	       logerr(0,'');
	       dbdat = [];
	    elseif ~any(argosidlist==argosid)	    
	       % Not a float we know or want
	       logerr(0,'');
	       dbdat = [];
	       % If flist supplied then this is simply one of the floats we are
	       % not interested in. Otherwise, it is not known to our database, 
	       % so either a corrupted id or the database is out of date.
	       if isempty(flist)
		  logerr(3,['? New float, Argos ID=' num2str(argosid)]);
	       end
	    else
	       % Set details for the next profile
	       pmeta.wmo_id = idcrossref(argosid,2,1);
	       if length(pmeta.wmo_id)>1  %more than one result so find wmo_id by profile date
		  db = [];
		  for ii = 1:length(pmeta.wmo_id)
		     dbdat = getdbase(pmeta.wmo_id(ii));
		     db(ii) = str2double(dbdat.launchdate);
		  end
		  greg=gregorian(ftptime);
		  gr=greg(1)*10000000000+greg(2)*100000000+greg(3)*1000000+greg(4)*10000+greg(5)*100;
		  db(end+1) = gr;
		  [ss,ind]=sort(db);
		  kk=find(ss==db(end));
		  pmeta.wmo_id=pmeta.wmo_id(max(kk-1,1));
	       end
	       
	       pmeta.ftptime = ftptime;
	       pmeta.ftp_fname = ftp_fname;
	       
	       dbdat = getdbase(pmeta.wmo_id);
	       logerr(0,num2str(pmeta.wmo_id));
	    end

	    % Re-initialise for next profile
	    plino = 0;        % Line number for this profile
	    ndat = 0;         % Count of message lines
	    rawdat.dat = blank;
	    rawdat.lineno = zeros(nblank,1);
	    rawdat.blkno = zeros(nblank,1);	 
	    rawdat.juld = zeros(nblank,1);
	    nhead = 0;
	    heads.dat = zeros([maxreps 9]);
	    heads.lineno = zeros(maxreps,1);	 
	    heads.satnam = repmat(' ',[maxreps 1]);
	    nb1 = 0;
	    b1tim.dat = zeros([maxreps 7]);
	    b1tim.lineno = zeros(maxreps,1);
	 end
	 
	 % Load header info from this line
	 datstr = char(datcel);
	 timstr = char(timcel);
	 if length(datstr)==10 && length(timstr)==8 && ~isempty(lat) && ~isempty(lon) 
	    tmp1 = sscanf(datstr,'%d-%d-%d');
	    tmp2 = sscanf(timstr,'%d:%d:%d');
	    if length(tmp1)==3 && length(tmp2)==3	    
	       nhead = nhead+1;
	       plino = plino+1;
	       heads.lineno(nhead) = plino;
	       heads.dat(nhead,1:3) = tmp1;
	       heads.dat(nhead,4:6) = tmp2;
	       heads.dat(nhead,7:8) = [lat lon];
	       heads.dat(nhead,9) = double(char(p_err));
	       tmp = strtrim(satnam{1});
	       if ~isempty(tmp)
		  % Satnam is now stored as str*1, so assume it will never be 2 chars
		  heads.satnam(nhead) = tmp(1);
	       end
	    end
	 end
	 
      elseif ~isempty(strfind(nxtline(1:10),'prv')) || ... 
	     ~isempty(strfind(nxtline(1:10),'ARGO')) || ... 
	     ~isempty(strfind(nxtline(1:10),'PRV'))  
	 % An ftp request line - ignore   
	 
      else
	 % Some other type of line ??      
	 logerr(3,['STRIP: Strange line, #' num2str(nlin) '> ' nxtline]);
      end
      
      if  ~isempty(nxtline2)
	 nxtline = nxtline2;
%      nxt2=nxtline
	 nxtline2 = [];
      else
	 nxtline = fgetl(fid);
%      nxtline=nxtline
      end

      
   end              % Looping on every line of ARGOS message file

   fclose(fid);


   if ndat>0 && any(argosidlist==argosid)
       % Unless somehow there were no profiles found, process the last profile
       try
           npro = process_one(rawdat,heads,b1tim,pmeta,dbdat,opts,npro);
       catch Me
           mail_out_argos_log_error(fnm,dbdat.wmo_id)
           logerr(5,['error in processing argos float - ' num2str(dbdat.wmo_id)])
           logerr(5,['Message: ' Me.message ])
           for jk = 1:length(Me.stack)
               logerr(5,Me.stack(jk).file)
               logerr(5,['Line: ' num2str(Me.stack(jk).line)])
           end
       end
   end

   % finished with argos delivery processing - 
   % now process any iridium profiles that have arrived: this is a script so
   % all variables are returned as if the code was inserted here:  AT Nov 2008

   % Record the ftp file details in the processing records
   prec_dat = load(PREC_FNM);
   if isfield(prec_dat,'ftp_details')
      ftp_details = prec_dat.ftp_details;
      ndet = length(ftp_details);
      ftp_details(2:ndet) = ftp_details(1:(ndet-1));
   else
      % ftp_details array does not exist yet, so create a new one (it stores 
      % details of the last 5 ftp files)
      ftp_details(5).ftptime = nan;
      ftp_details(5).nlines = 0;
      ftp_details(5).nprofiles = 0;
   end
   ftp_details(1).ftptime = ftptime;
   ftp_details(1).nlines = nlin;
   ftp_details(1).nprofiles = npro;

   load(PREC_FNM,'PROC_RECORDS');
   save(PREC_FNM,'PROC_RECORDS','ftp_details','-v6');
end


%diagnostic line:
disp('Processing Iridium Files ...')

%need to transfer to ftp (only works if CSIRO is processor). Do it once for
%all iridium files.
% Does nothing if the ARGO_SYS_PARAM.processor is not set or does not have
% 'CSIRO' or 'BOM' in the field.
try
     BOM_retrieve_Iridium
catch Me
    logerr(5,'error in iridium ftp transfer')
    logerr(5,['Message: ' Me.message ])
    for jk = 1:length(Me.stack)
        logerr(5,Me.stack(jk).file)
        logerr(5,['Line: ' num2str(Me.stack(jk).line)])
    end
end

extract_Iridium_data


%APF 11 floats
try
    extract_apf11data
catch Me
    logerr(5,['error in processing APF11 float - ' num2str(dbdat.wmo_id)])
    logerr(5,['Message: ' Me.message ])
    for jk = 1:length(Me.stack)
        logerr(5,Me.stack(jk).file)
        logerr(5,['Line: ' num2str(Me.stack(jk).line)])
    end
end
%only for CSIRO operations
if isfield(ARGO_SYS_PARAM,'processor')
    if ~isempty(strfind(ARGO_SYS_PARAM.processor,'CSIRO'))
        
        retrieve_phy_data %this data is delivered to the 'incoming' ftp site and
        %needs to be copied to iridium_data
    end
end
extract_phy_data   %polynya floats. 3 only.

extract_Solo2_data  % new code to process solo2 floats ourselves
	  
eval(['cd ' ARGO_SYS_PARAM.root_dir]);

logerr(0,'');
logerr(5,['Processed ' num2str(npro) ' profiles']);


% Now transmit all GTS messages and netCDF files 
if opts.tr_now
   export_argo;
end

% Record the ftp file details in the processing records
%does this get used for iridium data, phy, solo2? Review.
prec_dat = load(PREC_FNM);
if isfield(prec_dat,'ftp_details')
   ftp_details = prec_dat.ftp_details;
   ndet = length(ftp_details);
   ftp_details(2:ndet) = ftp_details(1:(ndet-1));
else
   % ftp_details array does not exist yet, so create a new one (it stores 
   % details of the last 5 ftp files)
   ftp_details(5).ftptime = nan;
   ftp_details(5).nlines = 0;
   ftp_details(5).nprofiles = 0;
end
try
    ftp_details(1).ftptime = ftptime;
    ftp_details(1).nlines = nlin;
    ftp_details(1).nprofiles = npro;
catch Me
    logerr(3,['Warning: FTPtime etc details not recorded for float - ' num2str(dbdat.wmo_id)])
    logerr(3,['Message: ' Me.message ])
    for jk = 1:length(Me.stack)
        logerr(5,Me.stack(jk).file)
        logerr(5,['Line: ' num2str(Me.stack(jk).line)])
    end

end
   load(PREC_FNM,'PROC_RECORDS');
   save(PREC_FNM,'PROC_RECORDS','ftp_details','-v6');		  
		  
% Close report file and send it to system operators 
ARGO_RPT_FID = fclose(ARGO_RPT_FID);
%system(['cat ' rptfnm ' | mail -s"ArgoRT Report" ' ARGO_SYS_PARAM.operator_addrs]);
mail_out_ArgoRT_report

web_database

if ~isempty(strmatch(ARGO_SYS_PARAM.processor,'CSIRO'))
    % and regenerate the tech pages:
    % do for each column
    UpdateTechIndexPage('HULLID')
    UpdateTechIndexPage('DEPORDER')
    UpdateTechIndexPage('WMOID')
    UpdateTechIndexPage('ARGOSID')
end
return


%---------------------------------------------------------------------------
% PROCESS_ONE  Have entire message for a profile - now handle according to
% it's status.

function npro = process_one(rawdat,heads,b1tim,pmeta,dbdat,opts,npro)

if (~isempty(strfind('exhausted',dbdat.status)) | ~isempty(strfind('dead',dbdat.status)))...
        & (isempty(opts.redo))
   logerr(3,['Hey - "dead" float talking: ' num2str(pmeta.wmo_id)]);
   mail_out_dead_float(pmeta.wmo_id);
elseif ~isempty(strfind('expected',dbdat.status))
   logerr(3,['LOOK - "expected" float transmitting: ' num2str(pmeta.wmo_id)]);
% elseif ~isempty(strfind('evil',dbdat.status)) & (isempty(opts.redo) | ~opts.redo)
%    logerr(3,['evil float still alive...:' num2str(pmeta.wmo_id)]);
%    % Ignore this bad float (wish it would die!)
else
   % Trim array of unused space, and save for testing ('expected' floats)
   % or process ('live' floats) 
   [rawdat,heads,b1tim] = trim_dat(rawdat,heads,b1tim);
   
   %for fast cycling floats, you may have more than one profile in the
   %download - remove here:
   if ~isempty(b1tim.dat)
      [rawdat,heads,b1tim] = remove_old_data(rawdat,heads,b1tim,pmeta);
   end
   
   npro = npro+1;
   if ~isempty(strfind('expected',dbdat.status))
      pmeta.np = 0;
      pmeta.pnum = 0;
      save_workfiles(rawdat,heads,b1tim,pmeta,opts.savewk);
      logerr(4,['Expected float ' num2str(pmeta.wmo_id) ...
		' - message saved to workfile N0_P0']);
   else
       process_profile(rawdat,heads,b1tim,pmeta,dbdat,opts);
   end
end

return

%--------------------------------------------------------------------------
% TRIM_DAT   remove unused space from raw profile message arrays
%
% CALLED BY: strip_argos_msg
%
% USAGE: [rawdat,heads,b1tim] = trim_dat(rawdat,heads,b1tim);
%   note - test in here for test messages and remove from hex array - AT
%   11/05/2007

function [rawdat,heads,b1tim] = trim_dat(rawdat,heads,b1tim)

mxl = find(rawdat.lineno>0,1,'last');
rawdat.lineno = rawdat.lineno(1:mxl);
rawdat.blkno = rawdat.blkno(1:mxl);
rawdat.dat = rawdat.dat(1:mxl,:);
rawdat.juld = rawdat.juld(1:mxl,:);

mxl = find(heads.lineno>0,1,'last');
heads.lineno = heads.lineno(1:mxl);
heads.dat = heads.dat(1:mxl,:);
heads.satnam = heads.satnam(1:mxl);

mxl = find(b1tim.lineno>0,1,'last');
b1tim.lineno = b1tim.lineno(1:mxl);
b1tim.dat = b1tim.dat(1:mxl,:);

return

%--------------------------------------------------------------------------
% REMOVE_OLD_DATA   remove previous profiles from fast cycling floats
%    from raw profile message arrays. Also trims out any stray bad dates.
%
% CALLED BY: strip_argos_msg
%
% USAGE: [rawdat,heads,b1tim] = remove_old_data(rawdat,heads,b1tim);
%   

function [rawdat,heads,b1tim] = remove_old_data(rawdat,heads,b1tim,pmeta)

jday = rawdat.juld;

if (max(jday)-min(jday))>1.3  % more than a day gap so assume more than one profile in the download...   
   % Old code:
   % oldl = find(rawdat.juld<jmax-2);   
   %    This was a blunt instrument. I saw cases where a whole cycle was 
   %    thrown out because of one wrong date.

%    if any(jday<(pmeta.ftptime-11))
%       % Try to remove any wacky dates - more than one cycle prior to date of
%       % ftp. Should set this limit according to float cycle interval...
%       jday(jday<(pmeta.ftptime-11)) = nan;
%    end

   nn = length(jday);
   nout = ceil(nn/50);
   n4 = round(nn/4);
   % calc index grouping values into 1-day groups
   j0 = min(jday)-.01;    
   grp = ceil(jday-j0);
   ii = unique(grp);
   cnt = zeros(1,max(grp));
   for kk = row(unique(grp))
      cnt(kk) = sum(grp==kk);
      if cnt(kk)<=nout
	 % Reject isolated points (stray bad times?)
	 jday(grp==kk) = nan;
      end
   end
   
   nmin = max([25 sum(~isnan(jday))/4]);
   if sum(jday>(max(jday)-1)) > nmin
      % At least a quarter (and a quorum) in the last day, so assume this
      % really is the latest profile and the rest is left-overs of previous
      % profiles, so use this group and reject the rest
      jday(jday<(max(jday)-1)) = nan;
   else
      % Just pick largest grp, but then re-centre that group (in case it
      % straddles a day end/start) and reject the rest
      [~,kk] = max(cnt);
      jday(abs(jday-mean(jday(grp==kk)))>0.75) = nan;
   end
         
   ibd = isnan(jday);
   rawdat.lineno(ibd) = [];
   rawdat.blkno(ibd) = [];
   rawdat.dat(ibd,:) = [];
   rawdat.juld(ibd) = [];
end

jj = julian(heads.dat);
irej = jj<(max(jday)-1.5);
heads.lineno(irej) = [];
heads.dat(irej,:) = [];

[m,n] = size(b1tim.dat);
for jj = 1:m
   jb1(jj) = julian([b1tim.dat(jj,2:n) 0]);
end
irej = jb1<(max(jday)-1.5);
b1tim.lineno(irej) = [];
b1tim.dat(irej,:) = [];

return
%--------------------------------------------------------------------
%  (256*h1 + h2) converts 2 hex (4-bit) numbers to an unsigned byte. 

function bb = h2b(dd,sc)

bb = (256*dd(1) + dd(2)).*sc;

return
