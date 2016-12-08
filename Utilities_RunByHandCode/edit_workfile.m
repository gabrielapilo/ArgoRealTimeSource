% RUN_FROM_WORKFILE   Interactively edit, test and process Ago profiles 
%     from 'workfiles'.   The only editing allowed is setting or clearing
%     the bad-data flags on any line of input message (and the special case
%     of auto-correcting message-number-wrap.) Changes are not
%     permanent until either the 'save' or 'accept' commands are used.
%
%     If have a block of profiles to just run through the processing
%     system, better to just use RUN_FROM_WORKFILE
%
%     Command "?" provides a detailed Help message. 
%
% INPUT:  
%   n_or_p   0 = "np" specified in matfile record index (n)
%            1 = "np" specified in Argo profile number (p)   [default]
%   showhex  0 = dispaly raw messages as decimal  [default]
%            1 = display raw messages in hex
%   rt_prec  0 = Processing records to "reprocessing_records.mat" [default]
%            1 =    "         "     RT records file.
%
% OUTPUT:  
%      edited workfiles, and the usual products if any profiles submitted
%      for processing.
%
% Jeff Dunn CSIRO/BoM Nov 2006
%
% SEE ALSO:   run_from_workfile
%
% CALLED BY:  for interactive use
%
% USAGE: edit_workfile(n_or_p,showhex,rt_prec)

function edit_workfile(n_or_p,showhex,rt_prec)


global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global ARGO_SYS_PARAM
global ARGO_REPORT  ARGO_RPT_FID
global PREC_FNM PROC_REC_WMO PROC_RECORDS

ARGO_RPT_FID = []; 

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if nargin<3 || isempty(rt_prec)
   rt_prec = 0;
end
if rt_prec
   PREC_FNM = [ARGO_SYS_PARAM.root_dir 'Argo_proc_records'];
else
   PREC_FNM = [ARGO_SYS_PARAM.root_dir 'reprocessing_records'];
end
if ~exist([PREC_FNM '.mat'],'file')
   disp([PREC_FNM ' does not exist - opening new file']);
   PROC_RECORDS = [];
   PROC_REC_WMO = [];
   save(PREC_FNM,'PROC_RECORDS','-v6');   
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

if nargin<1 | isempty(n_or_p)
   n_or_p = 1;
end

if nargin<2 | isempty(showhex)
   showhex = 0;
end
if showhex
   dfmt = '%0.2x ';
else
   dfmt = '%3d ';
end

npage = 45;             % Number of lines too display at one time
crc = {'?','B',' '};    % unknown, Bad, Good  CRC

hlpmsg={'The single letter commands can in some cases be followed by numbers',...
     ' in any Matlab format. That is, to reject lines 6,7,8, could input: ',...
     ' R6:8   or     R [6 7 8]     but not  R 6 7 8',...
     'Default numbers may be provided for some commands; for example, the',...
     'the next page of lines will be displayed if just input    L',...
     '         Listing Formats ',...
     'Headers:     lineno: qc date time lat lon pos_acc',...
     'B1tim:        lineno: msgno date time',...
     'Profile:       lineno: qc blkno CRC p1 p2 p3 p4 .. ',...
     '      where CRC is:  B=bad  ?=unknown  blank=good',' ',...
     'In the following:',...
     '   nn         indicates that numbers are required, ',...
     '   [def = ]   is default action is no numbers supplied',' ', ...	
     'A      Accept this modified data - submit the profile to ArgoRT',...
     'Bnn    list only Block nn   [def= next block]',...
     'C      check speed between positions',...
     'D      change to listing in decimal format',...
     'Fnn    work on another float   [no default action]',...
     'Gnn    flag lines as Good  (qc=0)   [no default action]',...
     'H      list only header lines',...
     'I      list only Block1 date/time lines',...
     'Jnn    unwrap these Block1 message numbers (add 256)',...  
     'Knn    rewrap these Block1 message numbers (subtract 256)',...  
     'Lnn    list page starting at line nn)  [default=next page]  ',...
     '       (Shows all header, profile data, and b1tim lines)',...
     'Pnn    next profile  [def=next profile]',...
     'Q      Quit',...
     'Rnn    Reject lines  (set qc=9)   [no default action]',...
     'S      save changes',...
     'T      test changes',...
     'U      Up  (list previous page)',...
     'V      view that page again (to check changes)',... 
     'X      change to listing in hex format',...
     '<CR>   same as "L" - list next page',...
     '?      this crumby help message'};


disp('Start with commands F then P.  Eg  F 5901170')
disp('then                               P 57') 

cmd = ' ';


while ~strcmp(cmd,'q')
   switch cmd(1)

     case 'a'
       % Accept (ie process) this profile

       savefile(heads,rawdat,b1tim,pmeta,fnm,hasqc);
	   
       logerr(0,['Reprocess ' num2str(wmoid)]);
       opts.savewk = 0;
       opts.rtmode = 0;
       opts.redo = [1 2];
       process_profile(rawdat,heads,b1tim,pmeta,dbdat,opts)
       disp('Submitted profile to ArgoRT - complete')

       
     case 'b'
       % List just one block

       if isempty(nn)
	  blockno = blockno+1;
       else
	  blockno = nn;
       end
       ii = find(rawdat.blkno==blockno);
       if ~isempty(ii)
	  for jj = ii(:)'
	     fprintf(1,'%3d: %d  %2d %s  ',rawdat.lineno(jj),rawdat.qc(jj), ...
		     rawdat.blkno(jj), crc{2+rawdat.crc(jj)});
	     fprintf(1,dfmt,rawdat.dat(jj,:));
	     fprintf(1,'\n');
	  end
       end

       
     case 'c'
       % Check speed between fixes
       jj = find(heads.qc==0);
       dat = heads.dat(jj,:);
       pos_fix_check(dat);

       
     case 'f'
       % Next float
       wmoid = nn;
       rawdat = [];
       np = 0;	  
       fpth = [ARGO_SYS_PARAM.root_dir 'workfiles/' num2str(wmoid) '/'];
       if ~exist(fpth,'dir')
	  nfils = 0;
       else
	  ffils = dir([fpth 'N*mat']);
	  nfils = length(ffils);
       end
       if nfils==0
	  disp(['No workfiles profiles for WMO ' num2str(wmoid) '. Try option f again.'])
	  wmoid = [];
	  fpth = [];
       else
	  fnps = zeros(nfils,2);
	  for ii = 1:nfils
	     fnps(ii,:) = sscanf(ffils(ii).name,'N%d_P%d');
	  end
	  dbdat = getdbase(wmoid);
	  fprintf(1,'Float %d:  %d workfiles, profiles %d to %d\n',...
		  wmoid,length(ffils),fnps([1 nfils],n_or_p+1));
       end

       
     case 'g'
       % Change flags to 'Good'
       jj = find(ismember(heads.lineno,nn));
       heads.qc(jj) = 0;
       jj = find(ismember(rawdat.lineno,nn));
       rawdat.qc(jj) = 0;
       rawdat.crc(jj)= 1;
       opts.nocrc = 1;
       jj = find(ismember(b1tim.lineno,nn));
       b1tim.qc(jj) = 0;
       
     
     case 'h'
       % List header lines only       
       for ii = 1:length(heads.lineno)
	  fprintf(1,'%3d: %d  %4d-%2d-%2d %0.2d:%0.2d:%0.2d %8.4f %8.4f %c\n',...
		  heads.lineno(ii),heads.qc(ii),heads.dat(ii,:));
       end
       
       
     case 'i'
       % List b1tim only       
       for ii = 1:length(b1tim.lineno)
	  fprintf(1,'%3d: %d   %d   %4d-%2d-%2d %0.2d:%0.2d:%0.2d\n',...
		  b1tim.lineno(ii),b1tim.qc(ii),b1tim.dat(ii,:));
       end
       
       
     case 'j'
       % unWrap message numbers
       jj = find(ismember(b1tim.lineno,nn) & b1tim.dat(:,1)<256);       
       b1tim.dat(jj,1) = b1tim.dat(jj,1) + 256;
       b1tim.msgno_mod = 1;

       
     case 'k'
       % Wrap message numbers
       jj = find(ismember(b1tim.lineno,nn) & b1tim.dat(:,1)>255);       
       b1tim.dat(jj,1) = b1tim.dat(jj,1) - 256;
       
     
     case {'l','u','v'}
       % List or refresh listing

       nn = (n1+1):min([n1+npage nlin]);

       for ii = nn
	  if any(heads.lineno==ii)
	     jj = find(heads.lineno==ii);
	     fprintf(1,'%3d: %d  %4d-%2d-%2d %0.2d:%0.2d:%0.2d %8.4f %8.4f %c\n',...
		     ii,heads.qc(jj),heads.dat(jj,:));
	  else
	     jj = find(rawdat.lineno==ii);
	     if ~isempty(jj)
		if rawdat.blkno(jj)==1
		   kk = find(b1tim.lineno==ii);
		   fprintf(1,'%3d:    %d   %4d-%2d-%2d %0.2d:%0.2d:%0.2d\n',...
			   b1tim.lineno(kk),b1tim.dat(kk,:));
		end
		fprintf(1,'%3d: %d  %2d %s  ',ii,rawdat.qc(jj), ...
			rawdat.blkno(jj), crc{2+rawdat.crc(jj)});
		fprintf(1,dfmt,rawdat.dat(jj,:));
		fprintf(1,'\n');
	     else
		fprintf(1,'Line %d missing?\n',ii);
	     end
	  end
       end
       if isempty(nn)
	  n1 = 0;
       else
	  n1 = nn(end);
       end
       if n1==nlin
	  fprintf(1,'------- End of Data ----------------------\n',ii);
       end
	
       
     case 'p'
       % Next Profile
       if isempty(nn)
	  np = np+1;
       else
	  np = nn;
       end
       kk = find(fnps(:,n_or_p+1)==np); 
       if isempty(kk)
	  disp(['No file for np=' num2str(np)]);
%       elseif length(kk)>1
%	  disp('File not opened - the following files match this number:')
%	  for jj = kk(:)'
%	     disp(ffils(jj).name);
%	  end
       else
	  % Load the profile and add qc fields if not already present (these
	  % fields are only present if create previously by this function.)
	  % Display metadata and a linecount of the all components.
	  clear heads rawdat b1tim pmeta
	  fnm = [fpth ffils(kk(1)).name]; 
	  load(fnm);
	  blockno = 0;
	  n1 = 0;
	  nlin = max(rawdat.lineno);
	  hasqc = isfield(rawdat,'qc');
	  if ~hasqc
	     rawdat.qc = zeros(nlin,1);
	  elseif ~isempty(rawdat.qc) && any(rawdat.qc~=0)	     
	     disp('Profile already has some flagged lines') 
	  end
	  if ~isfield(rawdat,'crc')
	     rawdat.crc = -ones(nlin,1);
	  end
	  if ~isfield(heads,'qc')
	     heads.qc = zeros(length(heads.lineno),1);
	  end
	  if ~isfield(b1tim,'qc')
	     b1tim.qc = zeros(length(b1tim.lineno),1);
	  end
	  fprintf(1,'Profile %d   %d lines, %d headers, %d Block1\n',...
		  np,nlin,length(heads.qc),length(b1tim.qc));
	  pmeta
	  disp(['ftptime: ' datestr(gregorian(pmeta.ftptime))]);
       end
       
       
     case 'r'
       % Reject - change flags to 'Bad'
       jj = find(ismember(heads.lineno,nn));
       heads.qc(jj) = 9;
       jj = find(ismember(rawdat.lineno,nn));
       rawdat.qc(jj) = 9;
       rawdat.crc(jj) = 0;
       opts.nocrc = 1;
       jj = find(ismember(b1tim.lineno,nn));
       b1tim.qc(jj) = 9;
       
       
     case 's'
       % Save changes
       savefile(heads,rawdat,b1tim,pmeta,fnm,hasqc)
       
       
     case 't'
       % Test it
       rawdat = test_process(rawdat,heads,b1tim,pmeta,dbdat);
       
       
     case '?'
       % Help
       msgbox(hlpmsg,'Edit_Workfile  -  Help');

       
     case ' '
       % Do nothing (just pass through to prompt for first command)
       
       
     otherwise
       disp(['Do not understand ' cmd])       
   end

   
   cmd = lower(input('(Type ? for help) : ','s'));

   
   % Decode any numbers attached to the command, and perform other preparation
   nn = [];
   lcmd = length(cmd);   
   if lcmd==0
      cmd = 'l';
   elseif lcmd==1
      switch cmd
	case 'x'
	  dfmt = '%0.2x ';
	  cmd = 'v';
	  n1 = max([0 n1-npage]);
	case 'd'
	  dfmt = '%3d ';
	  cmd = 'v';
	  n1 = max([0 n1-npage]);
	case 'u'
	  n1 = max([0 n1-(2*npage)]);
	case 'v'
	  n1 = max([0 n1-npage]);
      end	 
   else
      try
	 nn = eval(cmd(2:end));
	 if strcmp(cmd(1),'l')
	    n1 = nn(1) - 1;
	 end
      catch
	 disp([cmd ' does not scan properly?!']);
      end
   end
   
end


%--------------------------------------------------------------------
function savefile(heads,rawdat,b1tim,pmeta,fnm,hasqc)

if isempty(rawdat)
   return
end

if hasqc || any(rawdat.qc>0) || any(heads.qc>0) || any(b1tim.qc>0) || ...
       isfield(b1tim,'msgno_mod')
   save(fnm,'heads','rawdat','b1tim','pmeta','-v6');
   disp(['Saved to ' fnm])
else
   disp(['No changes made to ' fnm])
end

return
%---------------------------------------------------------------------
