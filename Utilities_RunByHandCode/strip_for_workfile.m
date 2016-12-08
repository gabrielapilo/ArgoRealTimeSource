% STRIP_FOR_WORKFILE  Program for decoding and processing realtime Argo
%    ARGOS float messages to regenerate workfiles, but not do the whole
%    profile processing.
%
% INPUT
%   fnm   - name of argos message dump file (created by script 'ftp_get_argos') 
%   flist - list of WMO or Argos id numbers of floats to process [only if you
%           want to restrict this]. (Program converts these to Argos numbers
%           when used to check against ftp message.)   If flist not supplied,
%           will process all floats found in the float master spreadsheet.
%   pns   - profile nos, one per flist entry
%
% OUTPUTS
%   npro  - 1 = one cycle decoded and saved to file
%
%   - intermediate workfiles created.
%
% Author: Jeff Dunn CSIRO-CMAR Sept 2013
%         devolved from strip_argos_msg
%
% CALLS: process_profile  idcrossref  getdbase
%        In this file:  process_one  trim_dat 
%
%
% USAGE: npro = strip_for_workfile(fnm,flist,pns)

function npro = strip_for_workfile(fnm,flist,pns)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

% *** Hardcoded parameters

maxblk = 50;       % Maxblk is a safe max number of blocks

blocklen = 32;     % So far, blocks are at most this long

maxreps = 60;      % The most reps of a block you would expect.

loc_time = 10/24;  % Rough localtime offset from UTC (eg EST is +10hrs)

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

% Our Argos ID, which marks the beginner of header lines 
our_id = ARGO_SYS_PARAM.our_id;


getdbase(0);

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
         disp(['Do not recognise float IDs: ' num2str(flist(kk))]);
      end
   end
end


% Open the report file. If this fails then reports will go to 2 (stderr).
% Then initialize report structure.
fclk = fix(clock);
tmp = sprintf('%04d%02d%02d_%02d:%02d',fclk(1:5));

fnm = deblank(fnm);
%disp(['Processing file ' fnm]);

[dum,ftp_fname] = fileparts(fnm);

% Open the input file
fid2 = fopen(fnm,'r');
if fid2<1
   error(['STRIP_ARGOS_MSG: Unable to open input file ' fnm]);
end



% Read first line of input file
nxtline = fgetl(fid2);


% Extract UTC date of ftp download
if isempty(nxtline)
   nxtline = fgetl(fid2);
end
if length(nxtline)>=20 && strncmp(nxtline(1:3),'UTC',3)
   tmp = sscanf(nxtline(1:20),'UTC %d-%d-%d %d:%d');
   ftptime = julian([tmp([3 2 1 4 5])' 0]);
   nxtline = fgetl(fid2);
elseif strncmp(nxtline(1:3),'Try',3)  
   % 2006 Argos format ... untested!!!
   yy = strfind(fnm(1,:),'log');
   year = str2double(fnm(yy-7:yy-6))+2000;
   if year>2098
      year = year-100;
   end
   while isempty(strfind(nxtline,'UTC'))
      nxtline=fgetl(fid2);
   end
   day=str2double(nxtline(15:17));    % Why not handle as in case above ? JRD
   ti1=str2double(nxtline(19:20));
   ti2=str2double(nxtline(21:22));
   dv=datevec(datenum(year,1,1,ti1,ti2,0) + day-1);
   ftptime=julian(dv);
   nxtline = fgetl(fid2);
   
   nxtline = fgetl(fid2);
   nxtline = fgetl(fid2);
elseif(strncmp(nxtline(1:3),'PRV',3)) || (strncmp(nxtline(1:3),'prv',3))
   % 2001 Argos format
   yy=strfind(fnm(1,:),'log');
   year=str2double(fnm(yy-7:yy-6))+2000;
   if year>2098
      year = year-100;
   end
   day=str2double(ftp_fname(9:end))+9;
   if(day>365);day=day-365;year=year+1; end         % What about leap years!  JRD
   dv=datevec(datenum(year,1,1,0,0,0) + day-1);
   ftptime=julian(dv);
else
   % Need to estimate this (from last fix date in file)
   [lstdate,err] = date_ftp_file(fid2);
   if err>=0
      ftptime = julian(datevec(lstdate));
      if ftptime > .1 + julian(clock)-loc_time;
	 disp(['FTP file time apparently in the future by ' ...
	       num2str(ftptime-(julian(clock)-loc_time)) ' days']);
      end
   else
      disp('Need to resolve a date for input file before proceeding');
      fclose(fid2);
      return
   end
end


% set up a blank array to use to preallocate space (because that is faster)
nblank = maxreps*maxblk;
blank = nan([nblank blocklen]);

argosid = -1;
npro = 0;
nlin = 0;
ndat = 0;   
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
         if length(yr)~=1 || yr<1999 || yr>2025
            %disp(['STRIP: Strange date Line#' num2str(nlin) '> ' nxtline]);
         end
	 try
	    jd=julian([str2double(nxtline(7:10)) str2double(nxtline(12:13)) str2double(nxtline(15:16))...
		       str2double(nxtline(18:19)) str2double(nxtline(21:22)) str2double(nxtline(24:25))]);
	 end
	 
         nxtline2 = fgetl(fid2);

	 % Decode the first 4 hex numbers, and extract the block number
         [dd,cnt] = sscanf(nxtline(37:end),'%2x');

         if cnt<4 || length(nxtline2)<8 || ~strcmp(nxtline2(5:8),'    ')
	    %designed to catch first lines only of a block with no further data...
	    nxtline = nxtline2;
	    nxtline2 = fgetl(fid2);
	    if length(nxtline)>36 && ~strcmp(nxtline(1:5),'     ')
	       [dd,cnt] = sscanf(nxtline(37:end),'%2x');
	    else
	       if nxtline<0         % nxtline is a char array, so this is a
                                    % strange test ??? JRD
		  break             % So where do we end up with this ??? JRD
	       end
	       if length(nxtline2)>=37
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

	 if ~isempty(cnt2)	    
	    if cnt==4 && cnt2==4 && blk==1; 
	       pos_test1(1) = dd(4); 
	       pos_test1(2) = dd2(1);
	       pos_test1(3) = dd2(2);
	       pos_test1(4) = dd2(3);
	       pos_test1(5) = dd2(4);
	    end
	 end
         if cnt==4 && blk==2 && ~isempty(dd2);
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
		  % this is a test block from deployment - remove
		  % we need to get rid of the header for this bit as well...
		  blk=nan;       % Flag as junk
		  nhead=max(0,nhead-1);
		  plino=max(0,plino-1);
	       end
	    end
	    
         elseif blk==2 & ~isempty (pos_test1)  & ~isempty (pos_test2)          
            if pos_test1(1:3)==pos_test2(1:3)
	       %this is a test block from deployment - remove
	       %we need to get rid of the header for this bit as well...
	       blk=nan;       % Flag as junk
	       nhead=max(0,nhead-1);
	       plino=max(0,plino-1);
            end
         end            


         if cnt<=1 || blk<1 || blk>=maxblk || (blk ==1 & length(nxtline)<25)
            % We get bad block numbers often - so don't make a fuss of it!
            blk = nan;        % Flag as junk
         end
         if cnt>0
            ndat = ndat+1;
            if ndat>nblank
               disp('Pre-allocated rawdat.dat is not large enough!')
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
	    pmeta.np = pns(find(argosidlist==argosid));
	    pmeta.pnum = pns(find(argosidlist==argosid));
	    % Unless we have just started, process the previous profile
	    npro = process_one(rawdat,heads,b1tim,pmeta,dbdat,npro);
	 end
	 
	 argosid = num;	 
	 if length(num)~=1
 	    % Bad ID num 
	    argosid = -1;
	    dbdat = [];
	 elseif ~any(argosidlist==argosid)	    
 	    % Not a float we know or want
	    dbdat = [];
	    % If flist supplied then this is simply one of the floats we are
	    % not interested in. Otherwise, it is not known to our database, 
	    % so either a corrupted id or the database is out of date.
	    if isempty(flist)
	       disp(['? New float, Argos ID=' num2str(argosid)]);
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
	    %disp(num2str(pmeta.wmo_id));
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
      %disp(['STRIP: Strange line, #' num2str(nlin) '> ' nxtline]);
   end
   
   if  ~isempty(nxtline2)
      nxtline = nxtline2;
      nxtline2 = [];
   else
      nxtline = fgetl(fid2);
   end
   
end              % Looping on every line of ARGOS message file

fclose(fid2);


if ndat>0 && any(argosidlist==argosid)
   pmeta.np = pns(find(argosidlist==argosid));
   pmeta.pnum = pns(find(argosidlist==argosid));
   % Unless somehow there were no profiles found, process the last profile
   npro = process_one(rawdat,heads,b1tim,pmeta,dbdat,npro);
end

return


%---------------------------------------------------------------------------
% PROCESS_ONE  Have entire message for a profile - now handle according to
% it's status.

function npro = process_one(rawdat,heads,b1tim,pmeta,dbdat,npro)

% Trim array of unused space, and save for testing ('expected' floats)
% or process ('live' floats) 
[rawdat,heads,b1tim] = trim_dat(rawdat,heads,b1tim);

%for fast cycling flaots, you may have more than one profile in the
%download - remove here:
if ~isempty(b1tim.dat)
   [rawdat,heads,b1tim] = remove_old_data(rawdat,heads,b1tim,pmeta);
end

if ~isempty(strfind('expected',dbdat.status))
   pmeta.np = 0;
   pmeta.pnum = 0;
   save_wkfile(rawdat,heads,b1tim,pmeta,2);
   disp(['Expected float ' num2str(pmeta.wmo_id) ...
	 ' - message saved to workfile N0_P0']);
   npro = npro+1;
else
   stus = process_just_workfile(rawdat,heads,b1tim,pmeta,dbdat);
   if stus
      npro = npro+1;
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
%REMOVE_OLD_DATA   remove previous profiles from fast cycling floats
%               from raw profile message arrays
%
% CALLED BY: strip_argos_msg
%
% USAGE: [rawdat,heads,b1tim] = remove_old_data(rawdat,heads,b1tim,pmeta);
%   

function [rawdat,heads,b1tim] = remove_old_data(rawdat,heads,b1tim,pmeta)

jday = rawdat.juld;
   
if (max(jday)-min(jday))>1.3  % more than a day gap so assume more than one profile in the download...   
   % Old code:
   % oldl = find(rawdat.juld<jmax-2);   
   %    This was a blunt instrument. I saw cases where a whole profile was 
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
      % At least a quarter (and a quorum) in the last day, so use this and
      % reject the rest
      jday(jday<(max(jday)-1)) = nan;
   else
      % Just pick largest grp, but then re-centre that grp and reject the rest
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
irej = jj<(mean(jday)-1);
heads.lineno(irej) = [];
heads.dat(irej,:) = [];

[m,n] = size(b1tim.dat);
for jj = 1:m
   jb1(jj) = julian([b1tim.dat(jj,2:n) 0]);
end
irej = jb1<(mean(jday)-1);
b1tim.lineno(irej) = [];
b1tim.dat(irej,:) = [];

return

%--------------------------------------------------------------------
%  (256*h1 + h2) converts 2 hex (4-bit) numbers to an unsigned byte. 

function bb = h2b(dd,sc)

bb = (256*dd(1) + dd(2)).*sc;

return

%-----------------------------------------------------------------------
% PROCESS_JUST_PROFILE  Run decoding and processing of realtime Argo
%    float messages (after they have been stripped from the ftp download)
%
% INPUT
%   rawdat - struct with all repeated tranmissions for one profile
%   heads  - struct with ARGOS tranmission headers for one profile
%   b1tim  - struct with message num, time vector for each block1 message
%   pmeta  - struct with download metadata
%   dbdat  - database record for this float
% OUTPUT  
%    stus  - 1=success
%   profiles appended to float mat-files; 
%   processing reports, 
%   GTS message, netcdf files,
%   web pages updated and plots generated.
%
% Author: Jeff Dunn CMAR/BoM Aug 2006
%
% CALLED BY:  strip_argos_msg
%
% USAGE:  stus = process_just_workfile(rawdat,heads,b1tim,pmeta,dbdat)

function  stus = process_just_workfile(rawdat,heads,b1tim,pmeta,dbdat)

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

stus = 0;
opts.nocrc = 0;

if isempty(pmeta.ftptime)
   disp('PROCESS_PROFILE: ftptime required if rtmode~=1');
   return
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
dt_max = datestr(now+3,31); 
kk=strfind(dt_max,'-');
dt_max(kk)=' ';

dt_max=[str2double(dt_max(1:4)) 12 31 23 59 59];
dt_maxj=julian(dt_max);
dt_minj=julian(dt_min);

jdays = julian(head(:,1:6));

% Check dates
for jj = 1:size(head,1)
   if any(head(jj,1:6)<dt_min) || any(head(jj,1:6)>dt_max)
      disp(['Implausible date/time components: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;
   elseif jdays(jj)>ftptime || jdays(jj)<(ftptime-Too_Old_Days)
      disp(['Implausible dates: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;
   elseif jdays(jj)<dt_minj || jdays(jj)>dt_maxj
      disp(['Implausible date/time components: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;       
   end
end

gdhed = find(~isnan(jdays));
if isempty(gdhed)
   disp('No usable date info');
   return
end


jday1 = min(jdays(gdhed));


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
   disp('Redundant ARGOS fixes removed.');
   gdhed(rej) = [];
end

% Check Argos location & time info (and for range -180<=lons<=180 )
% Also find deepest point within a +/- .25degree range, and reject if 
% not offshore (ie a very lenient test)
lats = head(gdhed,7);  
lons = head(gdhed,8);  

deps = get_ocean_depth(lats,lons);      
kk = find(isnan(lats) | isnan(lons) | lats<-90 | lats>90 ...
	  | lons<-180 | lons>360 | deps<0);
if ~isempty(kk)
   disp('Implausible locations');
   gdhed(kk) = [];
   if isempty(gdhed)
      disp('No good location fixes!');
   end
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
   delT(delT<240) = 240;
   dist = sqrt(diff(la).^2 + (diff(lo)*lcor).^2)*111119;
   speed = dist ./ delT;
   if any(speed > 4)
      disp('Unresolved excessive speeds between fixes');
   end
end


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

% Some early Apex floats just completely failed CRCs until 27/4/2001 !
wm_badcrc = [53553 53555 56501 56508];
jbadcrc = julian([2001 4 27 0 0 0]);
if any(wm_badcrc==pmeta.wmo_id) && length(gdhed)>1 ...
       && (max(jdays(gdhed))<jbadcrc)
   opts.nocrc = 1;
end

[~,~,rawdat] = find_best_msg(rawdat,dbdat,opts);

save_wkfile(rawdat,heads,b1tim,pmeta,2)
stus = 1;

return


%--------------------------------------------------------------------------------

function save_wkfile(rawdat,heads,b1tim,pmeta,savewk)

global ARGO_SYS_PARAM

if savewk==1
   % One file per float, overwritten with each new profile (ie temporary
   % work files.)
   wfnm = ['workfiles/R' num2str(pmeta.wmo_id)];
   save(wfnm,'rawdat','heads','b1tim','pmeta');

elseif savewk==2
   % A new file per profile, viewed as permanent work files.
   wdir = [ARGO_SYS_PARAM.root_dir 'workfiles/' num2str(pmeta.wmo_id) '/'];
   if ~exist(wdir,'dir')
      system(['mkdir ' wdir]);
   end	 
   wfnm = ['N' num2str(pmeta.np) '_P' num2str(pmeta.pnum)]; 
   if exist([wdir wfnm '.mat'],'file')
      % We have an old workfile of this name, so either this is stage 2, 
      % OR we are reprocessing,  OR there is somehow a repeat of both 
      % profile numbers??  No harm in clobbering the old file if it has 
      % not been edited.
      
      old = load([wdir wfnm]);

      if isfield(old.rawdat,'qc')
	 % This file has had editing, so we don't want to clobber it!
	 disp(['*** ' wfnm ' exists, has been edited, and contains ' ...
	       'different data, so saving instead to ' wfnm '_A']);
	 wfnm = [wfnm '_A'];
      else
	 % Now always replace
	 %
	 % PREVIOUS: A quick but fallible test for different data in new and old versions
	 %if length(old.rawdat.blkno)~=length(rawdat.blkno) || ...
	 %    any(old.rawdat.blkno~=rawdat.blkno)
	    %disp(['Data in ' wfnm ' has changed']);	    	    
	 %elseif ~isfield(old.rawdat,'juld') || ~isfield(old.rawdat,'crc');
	    % Quietly replace file because we are just adding a missing field
	 %else
	    % No new data, so no reason to save file!
	 %   wfnm = [];
	 %end
      end
   end
   
   if ~isempty(wfnm)
      save([wdir wfnm],'rawdat','heads','b1tim','pmeta');
   end

elseif savewk==3
   % A new file per profile, but stored locally.
   wdir = ['workfiles/' num2str(pmeta.wmo_id) '/'];
   if ~exist(wdir,'dir')
      system(['mkdir ' wdir]);
   end	 
   wfnm = ['N' num2str(pmeta.np) '_P' num2str(pmeta.pnum)];    
   save([wdir wfnm],'rawdat','heads','b1tim','pmeta');
end

return
%-----------------------------------------------------------------------------
