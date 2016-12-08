% PROC_RECS_REBUILD  Used to rebuild or extend processing records file from 
%     matfiles. Maybe only ever used when start up a system, or when add new
%     floats to database and want a 10-day watch active for their first 
%     profile?
%
% INPUT
%   fnm   - [optional] name of processing records file (def to standard)
%   create  1=clobber existing file and build new one from scratch
%           0=just append records for any floats in database that are not
%             found in existng file     [default 0]
%
% OUTPUTS   new or updated processing records file
%
% Author: Jeff Dunn CSIRO-CMAR/BoM Nov 2006
%
% CALLS:   getdbase
%
% CALLED BY:  standalone, if ever...
%
% USAGE: proc_recs_rebuild(fnm,create)

function proc_recs_rebuild(fnm,create)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global PREC_FNM PROC_REC_WMO PROC_RECORDS


if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

getdbase(0);

if nargin<2
   create = 0;
end

% Open the processing record file and load the records
if ~isempty(fnm)
   PREC_FNM = fnm;
else
   PREC_FNM = [ARGO_SYS_PARAM.root_dir 'Argo_proc_records'];
end

if ~exist([PREC_FNM '.mat'],'file')
   disp(['Cannot open processing records file ' PREC_FNM]);
   if create
      disp('Building new file');
      PROC_RECORDS = [];
      PROC_REC_WMO = [];
   else
      disp('If you want a new one built from scratch, rerun with create=1')
      return
   end
elseif create
   ss = input('Are you sure you want to replace this file [n] : ','s');
   if ~isempty(ss) && (strncmp(ss,'y',1) || strncmp(ss,'Y',1))
      PROC_RECORDS = [];
      PROC_REC_WMO = [];
      ftp_details=[];
   else
      disp('Ok - aborting');
      return
   end
else   
   load(PREC_FNM);
   PROC_REC_WMO = [];
   if ~isempty(PROC_RECORDS)
      % This should always be the case, except when initialising a new system
      for ii = 1:length(PROC_RECORDS)
	 PROC_REC_WMO(ii) = PROC_RECORDS(ii).wmo_id;
      end
   end
end


nprec = length(PROC_RECORDS);
[m,n]=size(ARGO_ID_CROSSREF);

for ii = 1:m
   wmo = ARGO_ID_CROSSREF(ii,1);
   
   if ~any(PROC_REC_WMO==wmo)
      fmat = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo)];
      if exist([fmat '.mat'],'file')
	 load(fmat);
      else
	 float = [];
      end
      
      dbdat = getdbase(wmo);
      nprec = nprec+1;
      if nprec==1
	 PROC_RECORDS = new_proc_rec_struct(dbdat,0);
      else
	 PROC_RECORDS(nprec) = new_proc_rec_struct(dbdat,0);
      end
      PROC_RECORDS(nprec).new = 0;
      PROC_REC_WMO(nprec) = wmo;

      nn = length(float);
      if nn==0
	 np = 0;
      else
	 PROC_RECORDS(nprec).profile_number = float(nn).profile_number;
	 PROC_RECORDS(nprec).proc_stage = float(nn).proc_stage;
	 PROC_RECORDS(nprec).jday_ascent_end = float(nn).jday_ascent_end;
      end
   end
end


if create
   % ftp_details array does not exist yet, so create a new one (it stores 
   % details of the last 5 ftp files)
   ftp_details(5).ftptime = nan;
   ftp_details(5).nlines = 0;
   ftp_details(5).nprofiles = 0;   
   save(PREC_FNM,'PROC_RECORDS','ftp_details','-v6');
else
   save(PREC_FNM,'PROC_RECORDS','ftp_details','-v6');
end

return

%--------------------------------------------------------------------------
