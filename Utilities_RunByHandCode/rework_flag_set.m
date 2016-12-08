% REWORK_FLAG_SET   Set (or clear) the "rework" flag in a range of profiles
%    and/or floats, so that those profiles will be reprocessed when next
%    encountered in a processing run. 
%
% INPUT:  
%  rwrk - 1=set for reworking   0=clear rework flags 
%  wmo - WMO list of floats [defaults to all listed in database]
%  np -  profiles to effect. Default = all.
%        Use 999 to apply to last profile only
%  opt - {'myfield',val_range}  Selection range for a single-valued profile 
%        field. 
%        Eg      {'maker','provor'}
%          or    {'subtype',[43 999]}        ( all subtype>=43 )
%          or    {'jday_ascent_end',[julian(2006,10,1) realmax]}
%
% OUTPUT  rework flags modified in Argo matfiles
%
% Jeff Dunn CSIRO/BoM Nov 2006   (Derived from fix_all_matfiles.m)
%
% CALLED BY:  for interactive use only
%
% USAGE:   Envisage that may want to rework a subset of profiles. This allows
%   the .rework flag to be set so those particular existing profiles will be
%   reworked.  
%    Eg
%     wmo = [];  np = 999;  opt = {'surfpres',[15 9999]};
%     rework_flag_set(1,wmo,np,opt)
%
%   Alternatively, can set flag for entire data holdings and ALL profiles 
%   encountered in download files will be reworked. When satisfied with
%   the reprocessing, can then clear the (remaining) flags.  
%   
%     rework_flag_set(1)
%     ... reprocess one or more download files
%     rework_flag_set(0)

function rework_flag_set(rwrk,wmo,np,opt)

if nargin<1
   help rework_flag_set
   return
end
if rwrk~=0 && rwrk~=1
   error('"rwrk" needs to be either 0 or 1');
end
if nargin<2
   wmo = [];
end
if nargin<3
   np = [];
end
if nargin<4
   opt = [];
end

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

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

rtyp = 0;
if ~isempty(opt) 
   if iscell(opt) && length(opt)==2 
      fld = opt{1};
      rng = opt{2};
      if ischar(rng)
	 rtyp = 1;
      elseif length(rng)==2
	 rtyp = 2;
      else
	 rtyp = 3;
      end
   else
      disp('Argument "opt" is incorrectly constructed - ABORTING')
      return
   end
end

for ii = iwmo
   fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(db(ii).wmo_id)];

   if exist([fnm '.mat'],'file')
      load(fnm,'float');
      if ~isempty(float)
	 nn = length(float);
	 
	 if isempty(np)
	    kk = 1:nn;
	 elseif length(np)==1 && np==999
	    kk = nn;
	 else
	    kk = [];
	    for jj = 1:nn
	       if any(np==float(jj).profile_number)
		  kk = [kk jj];
	       end
	    end
	 end
	 
	 mods = 0;
	 
	 for jj = kk
	    ok = 0;
	    switch rtyp
	      case 0
		ok = 1;
	      case 1
		ok = strcmp(getfield(float(jj),fld),rng);
	      case 2
		vv = getfield(float(jj),fld);
		ok = (vv>=rng(1) & vv<=rng(2));
	      otherwise
		vv = getfield(float(jj),fld);
		ok = vv==rng;
	    end
	    if ok
	       float(jj).rework = rwrk;
	       mods = 1;
	    end
	 end
      
	 if mods	    
	    save(fnm,'float','-append','-v6');
	 end
      end
   end
end


%-------------------------------------------------------------------
