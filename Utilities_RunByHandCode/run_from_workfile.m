% RUN_FROM_WORKFILE   Rerun Argo_RT processing, using workfiles as input 
%     instead of ftp downloads.   Use this especially when reprocessing a 
%     block of profiles.  For more interactively testing and rerunning just
%     a few profiles, EDIT_WORKFILE is more suitable.
%
% INPUT:  
%  wmo  - WMO list of floats [defaults to all listed in database]
%  np  -  profiles to effect. Scalar, vector, or empty. Default=all.
%         Use 999 to apply to last profile only
%  opts - structure of run options (only need fields which want to change)
%     .n_or_p   0 = "np" specified in matfile record index (n)
%               1 = "np" specified in Argo profile number (p)   [default]
%     .makewww  1 = make a webpage from this run (proc_tmp.html in argo www)
%               Default = 0.
%     .rtmode - 0=delayed-mode reprocessing.  Default = 0!
%     .tr_now - 0/1  on/off.    Default 0
%     .savewk - FIXED as 0 - Cannot override - does not make sense to!
%     .redo   - default=[1 2]     Processing stages to redo.
%     .prec_fnm  - Neater to specify a temporary records file for 
%              reworking jobs, unless doing recent profiles.
%
%  trange - [2 6] datevec of start and end range of jday(1) of profiles 
%           to reprocess.  Default = all.
%           If [1 6], process all profiles after that date. 
%           eg [2006 10 17 23 0 0; 2006 12 1 0 0 0]
%
% OUTPUT:  Usual 
%
% Jeff Dunn CSIRO/BoM Nov 2006
%
% SEE ALSO:   edit_workfile
%
% CALLED BY:  for interactive use
%
% USAGE: run_from_workfile(wmo,np,opts,trange)

function run_from_workfile(wmo,np,opts,trange)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global ARGO_REPORT  ARGO_RPT_FID
global PREC_FNM PROC_REC_WMO PROC_RECORDS

if nargin<1
   help  run_from_workfile
   return
end
if nargin<2
   np = [];
end
if nargin<3
   opts = [];
end
if nargin<4
   trange = [];
end

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if isempty(THE_ARGO_FLOAT_DB)
   getdbase(0);
end
db = THE_ARGO_FLOAT_DB;    % Just give it a shorter name

if isempty(wmo)
   iwmo = 1:length(db);
else
   iwmo = find(ismember(ARGO_ID_CROSSREF(:,1),wmo));
   iwmo = iwmo(:)';
end

tmp.n_or_p  = 0;
tmp.makewww = 0;
tmp.rtmode  = 0;
tmp.tr_now  = 0;
tmp.savewk =  0:     % Does NOT make sense to overwrite the input files!
tmp.redo = [1 2];
tmp.prec_fnm = [];   % See below

if ~isempty(opts) 
   if isfield(opts,'n_or_p') && ~isempty(opts.n_or_p)
      tmp.n_or_p = opts.n_or_p;
   end
   if isfield(opts,'makewww') && ~isempty(opts.makewww)
      tmp.makewww = opts.makewww;
   end
   if isfield(opts,'rtmode') && ~isempty(opts.rtmode)
      tmp.rtmode = opts.rtmode;
   end
   if isfield(opts,'redo') && ~isempty(opts.redo)
      tmp.redo = opts.redo;      
   end
   if isfield(opts,'prec_fnm') && ~isempty(opts.prec_fnm)
      tmp.prec_fnm = opts.prec_fnm;
   end
end
opts = tmp;


if isempty(opts.prec_fnm)
   opts.prec_fnm = 'workfile_proc_recs';
end

if ~exist([opts.prec_fnm '.mat'],'file')
   % If necessary, create a new records file - a copy of the existing RT one,
   % but with all new flags cleared (and no "ftp_details", since no relevant)
   load('Argo_proc_records','PROC_RECORDS');
   for ii = 1:length(PROC_RECORDS)
      PROC_RECORDS(ii).new = 0;
   end
   save(opts.prec_fnm,'PROC_RECORDS','-v6');
else
   load(opts.prec_fnm,'PROC_RECORDS');
end   
for ii = 1:length(PROC_RECORDS)
   PROC_REC_WMO(ii) = PROC_RECORDS(ii).wmo_id;
end
   

% Open the report file. If this fails then reports will go to 2 (stderr).
% Then initialize report structure.
fclk = fix(clock);
tmp = sprintf('%04d%02d%02d_%02d:%02d',fclk(1:5));
if ispc
rptfnm = [ARGO_SYS_PARAM.root_dir 'reports\W' tmp '.txt'];
else
rptfnm = [ARGO_SYS_PARAM.root_dir 'reports/W' tmp '.txt'];
end
ARGO_RPT_FID = fopen(rptfnm,'a+');
if ARGO_RPT_FID<2
   disp(['WARNING: Cannot open report file ' rptfnm]);
   ARGO_RPT_FID = 2;
end
logerr(0);


for ii = iwmo
   dbdat = db(ii);	    
   logerr(0,['WMO ' num2str(db(ii).wmo_id) ' ']);

   % Find all wokrfiles for this float, and get their N and P numbers
   if ispc
       fpth = [ARGO_SYS_PARAM.root_dir 'workfiles\' num2str(db(ii).wmo_id) '\'];
   else
       fpth = [ARGO_SYS_PARAM.root_dir 'workfiles/' num2str(db(ii).wmo_id) '/'];
   end
   wkfls = dir([fpth 'N*mat']);
   nid = [];
   for jj = 1:length(wkfls)
      nid(jj,:) = sscanf(wkfls(jj).name,'N%d_P%d');
   end
   
   % Find the profiles wanted
   lp = length(np);
   if lp==0
      kk = 1:size(nid,1);
   elseif lp==1 && np==999
      kk = lp;
   else
      kk = find(ismember(nid(:,1+opts.n_or_p)',np));
   end
   
   for jj = kk
      clear rawdat b1tim heads pmeta
      load([fpth wkfls(jj).name],'rawdat','b1tim','heads','pmeta');

      if ~isempty(rawdat)
	 process_profile(rawdat,heads,b1tim,pmeta,dbdat,opts);
      end
   end
end

% Close report file (but don't email it)
logerr(0,'');
logerr(5,['Processed ' num2str(npro) ' profiles']);
ARGO_RPT_FID = fclose(ARGO_RPT_FID);


%-------------------------------------------------------------------
