% GET_ALL_CSL3  Get ocean cast data on CSIRO-standard-level v3 depths
%
%   NOTE:  No access yet to datasets 15  16  18  20  25-29  34
%
% INPUT:  
%  src    [w e s n] limits of region of required data
%      OR defining polygon [x1 y1; x2 y2; x3 y3; ... ] 
%  hvar   vector of one or more cast header info codes:
%         1)stnno   2)time   3)castflag  4)bot_depth   5)country   6)cruise
%         7)pos_stat   9) filetype  11) profile depth  12) bottom cast value
%           [3 11 & 12 apply to var(1) if multiple var]
%  var    vector of property codes: (see prop_name.m) 
%         1)t   2)s  3)02   4)Si  5)PO4   6)NO3   7)gamma  14)no4  15)nh3
%  dset   dataset codes - for info type:  dset_name
%  deps   Vector of indices of CSL v3 depth levels to extract
%         [use round(dep_csl(depths)) to convert from +ve metres to indices]
%         (Will interpolate to non CSL3 depths, but this is not recommended.)
%  scr    0 - disable pre-flagged bad-cast and bad-individual-data screening
%         1 - apply only originators' screening (eg NODC flags in WOD01)
%         2 - [default] all originator & local screening
%  dups   0= don't remove any dups
%         1= only remove dups if "primary" datasets are also requested [default]
%         2= remove all "secondary" casts which have dups in "primary" datasets
%            (whether or not the primary datasets are being extracted now.)
%         dups{n} = [m o ...] =remove casts in n duped in datasets m,o,...
%         Use SHOW_DUP_PREFS to see from which datasets dup profiles are taken. 
%  strp   0= return all casts, even if no data
%         1= return only casts with some data in some profiles [default]
%         2= return only casts with some data in all requested properties
% OUTPUT:
%  lat,lon, then header vars [ncast 1] in order requested, then profile vars
%  [ncast ndep] in order {where ndep may be less than number of depths requested, 
%  if no good data that deep for that particular variable.}
%
% NOTE:  Empty depth columns will only occur if there is deeper good data.
%   If strp=0, all stations will be returned.
%   If strp=1, for each cast-row there will be at least some data in at least one
%   of the returned variables. 
%   If strp=2, there will be at least some data in all of the returned variables. 
%
% Q: Duplicates where more than one variable requested - eg request T & S,
%    one station has T only and the same station in another dataset has S only?   
% A: We have a different list of duplicates for each property, so in the
%    above case both stations would be returned (unless strp=2).
%
% USAGE: [lat,lon,v1,v2,..] = get_all_csl3(src,hvar,vars,dsets,deps,scr,dups,strp);

% $Id: get_all_csl3.m,v 1.2 2006/01/04 05:55:53 dun216 Exp dun216 $
% Author: Jeff Dunn  CSIRO Marine Research Dec 1999
% Devolved from get_all_obs.m

function [lat,lon,varargout] = get_all_csl3(src,hvar,vars,dsets,deps,scr,dups,strp)

% Mods: 10/3/05 Extend dups system 
%       6/4/05  Add scr==2 code
%       23/8/06  Disabled auto-inclusion of dset 71 when ask for dset 7, var 6.

trng = [];

if nargin<5 | isempty(deps)
   disp('  GET_ALL_CSL3  requires 5 or 6 input arguments')
   help get_all_csl
   return
else
   deps = deps(:);
end

if nargin<6 | isempty(scr)
   scr = 2;
end   

if nargin<7 | isempty(dups)
   dups = 1;
end
if iscell(dups)
   % User has specified the dataset preference scheme for dup removal
   dupset = dups;
   if length(dupset)<max(dsets)
      dupset{max(dsets)} = [];
   end
   clear dups
   dups = 3;
elseif dups==1
   % Dup removal uses the standard preference scheme
   dupset = dsets;
elseif dups==2
   % Remove casts which duped in any other datasets, even if those datasets
   % are not being extracted	 
   dupset = [1:100];
end

if nargin<8 | isempty(strp)
   strp = 1;
end   

if strp==0 & dups>0
   global Get_All_Csl3_told
   if ~Get_All_Csl3_told
      disp('You have set dups>0 & strp=0, so duplicate casts will have profiles')
      disp('emptied of data, but they will still be returned');
      Get_All_Csl3_told = 1;
   end
end

if max(deps>79) | any(diff(deps)==10) | any(deps==0)
   disp([7 'The "deps" vector given suggests you have specified depths in m,']);
   disp('rather than depth level indices! If nec., convert using dep_csl.');
end

mxdp = length(deps);
depm = csl_dep(deps,3);

ii = find(dsets==29);
if ~isempty(ii)
   pth = platform_path('cascade','oez5/boa_obslvl/wod01/SURF/surf_all.mat');
   disp('WOD01 SURF (dset 29) is not handled by GET_ALL_CSL. Access it')
   disp(['directly from ' pth]);
   dsets(ii) = [];
   if isempty(dsets)
      return
   end
end

ii = find(dsets<=6);
if ~isempty(ii)
   disp('There is no CSL3 version of WOD98 dsets (1:6)');
   dsets(ii) = [];
   if isempty(dsets)
      return
   end
end

% 23/8/06 Disabled auto-inclusion of old CSIRO nitrate, because it appears
% to contain so much crap!
%if any(vars==6) & any(dsets==7) & ~any(dsets==71)
   % If want NO3 and CSIRO data, then also access the CSIRO Historical 
   % NO3 dataset (71). Added separately because this data was not in WOD98.
%   dsets = [dsets(:); 71];
%end
   
nhv = length(hvar);
ndv = length(vars);

lat = []; lon = [];

varargout{nhv+ndv} = [];

ndep = 0;

dpth = platform_path('cascade','oez5/eez_data/csl3/');
dupth = platform_path('cascade','oez5/eez_data/duplicates/');
infodir = platform_path('cascade','oez5/eez_data/qc_data/');
parnm = {'t','s','o2','si','po4','no3'};


for dset = dsets(:)'
   if any(dset==[21:28])
      [lo,la,stnno,hv,vv] = get_wod01(dset,src,trng,deps,hvar,vars,scr,dpth);
   else
      [lo,la,stnno,hv,vv] = get_dset(dset,src,trng,deps,hvar,vars,scr,dpth);      
   end
   
   jj = 1:length(lo);
   
   if dups>0 
      % If dup checking, nan-fill all profiles in duplicate casts.
      % Messy if more than one var, because datasets have different
      % combinations of vars, so vars for the same cast can have
      % different dup status with respect to another dataset.
      % For each var we set dup profiles to nan. We then get rid of whole 
      % stations with only all-nan profiles.
      for jv = 1:ndv
	 if dups<3
	    dulst = dset_dup_pref(dupset,vars(jv),dset);
	 else
	    dulst = dupset{dset};
	 end
	 for odset = dulst
	    fnm = sprintf('%s%d_%d_%d_dups',dupth,dset,odset,vars(jv));
	    if exist([fnm '.mat'],'file')
	       load(fnm);
	       [tmp,ii] = intersect(stnno(jj),dupstn);
	       if ~isempty(ii)
		  vv{jv}(jj(ii),:) = nan;
	       end
	    end
	 end	 
      end   
   end

   if scr==2
      % Apply all local screening
      for jv = 1:ndv
	 if vars(jv)<=6 & ~isempty(vv{jv}) 
	    fnm = [infodir num2str(dset) filesep parnm{vars(jv)} '_scr'];
	    if exist([fnm '.mat'],'file')
	       load(fnm,'scrstn');
	       for jdep = 1:size(vv{jv},2)
		  II = find(ismember(stnno,scrstn{deps(jdep)}));
		  if ~isempty(II)
		     vv{jv}(II,jdep) = nan;
		  end
	       end
	    end
	 end
      end
   end
   
   % If removing casts with all (strp=1) or any (strp=2) empty profiles
   if strp>0
      if ndv==1
	 ii = find(all(isnan(vv{1}(jj,:)),2));
      else
	 bad = zeros([ndv length(jj)]);
	 for jv = 1:ndv
	    bad(jv,:) = all(isnan(vv{jv}(jj,:)),2)';
	 end
	 if strp==1
	    ii = find(all(bad));
	 else
	    ii = find(any(bad));
	 end
      end
      jj(ii) = [];
   end
   
   if ~isempty(jj)
      lat = [lat; la(jj)];
      lon = [lon; lo(jj)];   
      for ii = 1:nhv
	 varargout{ii} = [varargout{ii}; hv{ii}(jj)];
      end

      % For each variable...
      for ii = 1:ndv
	 % find depth of deepest data in any new cast
	 ldp = max(find(any(~isnan(vv{ii}(jj,:)),1)));
	 if isempty(ldp); ldp = 0; end	    
         [ncast,ndep] = size(varargout{nhv+ii});
	 
	 if ldp == ndep
	    % If existing output the same, just add to it
	    varargout{nhv+ii} = [varargout{nhv+ii}; vv{ii}(jj,1:ldp)];
	 elseif ldp < ndep
	    if size(vv{ii},2) >= ndep
	       varargout{nhv+ii} = [varargout{nhv+ii}; vv{ii}(jj,1:ndep)];
	    else
	       vpad = repmat(nan,[length(jj) ndep-ldp]);	       
	       varargout{nhv+ii} = [varargout{nhv+ii}; [vv{ii}(jj,1:ldp) vpad]];
	    end
	 else
	    % If new data deeper than existing output, pad out the output
	    vpad = repmat(nan,[ncast ldp-ndep]);
	    varargout{nhv+ii} = [[varargout{nhv+ii} vpad]; vv{ii}(jj,1:ldp)];
	 end
      end
   end
   
end                                 


return


%------------------------------------------------------------------------
function [lo,la,stn,hv,vv] = get_dset(dset,src,trng,deps,hvar,vars,scr,dpth);

la = [];
lo = [];
stn = [];
%stnno = [];
nhv = length(hvar);
ndv = length(vars);
hv{ndv} = [];
vv{ndv} = [];

% Header names: 1-stn  2-time  3-cflag  4-botdep  5-co  6-cru  
%  9 is generated from 'dset'
% Header vars are all column vectors

inov = 1:ndv;
inoh = 1:nhv;
[iv,ih] = dset_vars(dset,2,vars,hvar);
if isempty(iv)
   return
end
inov(iv) = [];
inoh(ih) = [];


vnm = {'t','s','o2','si','po4','no3','nutdens','','','','','','','no4','nh3'};

cflag = [];
for ii = 1:ndv
   eval([vnm{vars(ii)} ' = [];']);
   eval([vnm{vars(ii)} '_castflag = [];']);
end

lon = []; lat = [];


switch dset
   
  case 7
    % CSIRO
    fnm = [dpth 'csiro' filesep 'csiro_csl'];
    lat = getnc(fnm,'lat');
    lon = getnc(fnm,'lon');
    time = getnc(fnm,'time');
    stnno = getnc(fnm,'stnno');
    if any(hvar==4)
       botdep = getnc(fnm,'botdepth');
    end
    if any(hvar==5)
       co = repmat(12345,size(lat));
    end
    if any(hvar==6)
       cru = floor(stnno/1000);
    end
    %if any(hvar==11 | hvar==12)
    %   bnm = [vnm{vars(1)} 'bot'];
    %   eval([bnm ' = getnc(fnm,bnm);']);
    %end
    for ii = iv
       nm = vnm{vars(ii)};
       eval([nm ' = getnc(fnm,nm);']);
       if scr>0 & vars(ii)~=7
	  flnm = [nm '_castflag'];
	  eval([flnm ' = getnc(fnm,flnm);']);
       end    
    end
    
  case 8
    % IOTA East
    
    % Calc and restrict stdep as only 55 levels in IOTA file.
    deps = deps(find(deps<=55));

    load([dpth 'csiro_therm_archive' filesep 'iota_east_csl3']);

    botdep = bdep;
    t = tz;
    clear tz bdep dtyp indx 
    
  case 9
    % NIWA
    load([dpth 'niwa_csl3']);
    cru = floor(stnno/10000);
    if any(hvar==5)
       co = repmat(13873,[length(lon) 1]);
    end
    
  case 10 
    % French Indian 2001 CD
    load([dpth 'french01_csl3'])
    
    % These cruise codes are crap - almost worth not using them!
    cru = cru_num;    
    
  case 11
    % ARGO floats  (only available to depth 67 (2250m))
    deps = deps(find(deps<=67));
    load([dpth 'argo_csl3'])
    
  case {12,121}
    % TAO moorings  (only available to depth 50 (750m))
    deps = deps(find(deps<=50));    
    if isempty(deps)
       return
    end
    
    % tao_csl3 has 333870 daily profiles. For mapping purposes, efficient to
    % instead use tao_month_csl3 (dset 121), the seasonal averages! 
    % 'cru' is our consecutive mooring number.
    if dset==12
       load([dpth 'tao_csl3']);
    else
       load([dpth 'tao_month_csl3']);
    end
        
  case 13
    % Antarctic CRC
    fnm = [dpth 'crc_csl3'];
    lat = getnc(fnm,'lat');
    lon = getnc(fnm,'lon');
    time = getnc(fnm,'time');
    stnno = getnc(fnm,'stnno');
    if any(hvar==4)
       botdep = getnc(fnm,'botdepth');
    end
    if any(hvar==5)
       co = repmat(12345,[length(lat) 1]);
    end
    if any(hvar==6)
       cru = getnc(fnm,'cru_idx');
    end
    for ii = iv
       nm = vnm{vars(ii)};
       eval([nm ' = getnc(fnm,nm);']);
       if scr>0 & vars(ii)<=6
	  flnm = [nm '_castflag'];
	  eval([flnm ' = getnc(fnm,flnm);']);
       end
    end    
       
       
  case 14
    % Willis global QC-ed thermal
    % This is a 750MB dataset, so is split into chunks. get_willis collates it.
    % Also because it is huge, we select only the required depths. To make
    % this work, need to adjust "deps" so that it corresponds to the index of
    % the extracted data. eg if want depths 50 60 75 120, ie Willis depths 
    % [5 6 7.5 12], then extract 5:12 and adjust "deps" to [1 2 3.5 8].
        
    % Convert CSLv3 indices to Willis depth indices (non-integer is an (n+5)m
    % CSL depth required).
    wdep = 0:10:750;
    deps = interp1(wdep,1:length(wdep),csl_dep(deps,3));
    deps = deps(find(deps>=1 & deps<=length(wdep)));
    
    % Reduce to minimum required block of depths, and adjust index to start
    % at 1 for the first of these depths.
    ii = min(floor(deps)):max(ceil(deps));
    deps = deps+1-ii(1);
    wdep = wdep(ii);

    [lon,lat,time,t,botdep,a1,a2,a3,a4,stnno] = get_willis(src,wdep);
    clear a?
    
        
  case 15
    % #### French Pacific SSS
    disp('No access to Pacific SSS')

  case 16
    % #### Far Seas
    disp('No access to Far Seas yet, but is only CSLv1 anyway')

  case 17
    % IOTA West XBT
    % Calc and restrict stdep as only 55 levels in IOTA file.
    deps = deps(find(deps<=55));

    load([dpth 'csiro_therm_archive' filesep 'iota_westA_csl3']);
    botdep = bdep;
    t = tz;
    
    B = load([dpth 'csiro_therm_archive' filesep 'iota_westB_csl3']);
    lon = [lon; B.lon];
    lat = [lat; B.lat];
    time = [time; B.time];
    stnno = [stnno; B.stnno];
    t = [t; B.tz];
    botdep = [botdep; B.bdep];
    t_castflag = [t_castflag; B.t_castflag];

    clear B tz bdep dtyp indx 
        
  case 18
    % #### MEDS GTS XBT etc
    disp('No access to MEDS GTS QCed Thermal yet!')

  case 19
    % WOCE WHP
    load([dpth 'woce_csl3']);
    if any(hvar==6)
       % Any WOCE station may be associated with up to 3 cruise codes
       % (which were used to make up the original netcdf station file name.)
       % The 352 unique codes are in variable 'cruz'. 'cri1' points to the 
       % first cruise code for each station, 'cri2' to the second (if
       % required), 'cri3' to the third, if required. We can't pass that 
       % complication through this general function, so just use cri1.
       cru = cri1;
    end
    
  case 20
    % #### WOCE UOT
    disp('No access to WOCE UOT yet!')
  
  case 31
    % Other small dsets, esp AIMS Torres CTD 
    % Restrict deps as only 11 levels in Torres file.
    deps = deps(find(deps<=11));

    load([dpth 'other_csl3']);   
    %load([dpth 'torres_csl3']);   

    if any(hvar==5)
       co = repmat(12345,[length(lon) 1]);
    end
    
  case 34
    % #### High density XBT
    disp('No access to dset 34 [high density XBT] yet!')
  
  case 35
    % AWI (Alfred Wegener Institute) CTD
    load([dpth 'awi_csl3']);    
  
  case 70
    disp('Dataset 70 (CSIRO 2db CTD) is an obs-level-only dataset.')
  
  case 71
    % CSIRO historical nitrate
    fnm = [dpth 'csiro' filesep 'csiro_no3'];
    lat = getnc(fnm,'lat');
    lon = getnc(fnm,'lon');
    time = getnc(fnm,'time');
    stnno = getnc(fnm,'stnno');
    if any(hvar==4)
       botdep = getnc(fnm,'botdepth');
    end
    if any(hvar==6)
       cru = floor(stnno/1000);
    end
    for ii = iv
       nm = vnm{vars(ii)};
       eval([nm ' = getnc(fnm,nm);']);
       if scr>0 & vars(ii)<=6
	  flnm = [nm '_castflag'];
	  eval([flnm ' = getnc(fnm,flnm);']);
       end
    end    

  case 72
    disp('Dataset 72 (CSIRO Hydro) is an obs-level-only dataset.')
  
  otherwise
    disp(['Do not yet have access to dataset ' num2str(dset)]);
    
end


if isempty(src)
   jj = 1:length(lon);
elseif min(size(src))==1
   jj = find(lon>=src(1) & lon<=src(2) & lat>=src(3) & lat<=src(4));
else
   jj = find(inpolygon(lon,lat,src(:,1),src(:,2)));
end
    
if ~isempty(trng) & ~isempty(jj)
   kk = find(time(jj)<trng(1) | time(jj)>=trng(2));
   jj(kk) = [];
end

if ~isempty(jj)
   nj = length(jj);
       
   la = lat(jj);
   lo = lon(jj);
   stn = stnno(jj);
   
   for ii = ih
      switch hvar(ii)
	case 1
	  hv{ii} = stn;
	case 2
	  hv{ii} = time(jj);
	case 3
	  if isempty(cflag) & ~isempty(iv)
	     cfnm = [vnm{vars(iv(1))} '_castflag'];
	     if ~isempty(eval(cfnm))
		eval(['cflag = ' cfnm ';']);
	     end
	  end
	  if ~isempty(cflag)
	     hv{ii} = cflag(jj);
	  end
	case 4
	  hv{ii} = botdep(jj);
	case 5
	  hv{ii} = co(jj);
	case 6
	  hv{ii} = cru(jj);
	case 9
	  hv{ii} = repmat(dset,[nj 1]);
	case 11
	  hv{ii} = eval([vnm{vars(1)} 'bot(jj,1)']);
	case 12
	  hv{ii} = eval([vnm{vars(1)} 'bot(jj,2)']);
	otherwise
	  hv{ii} = repmat(nan,[nj 1]);		 
      end
   end
   
   for ii = inoh
      hv{ii} = repmat(nan,[nj 1]);
   end	

   ndp = length(deps);
   
   for ii = iv
      if isempty(eval([vnm{vars(ii)} '_castflag'])) & ~isempty(cflag)
	 % One castflag for all variables, so use an approp named copy
	 eval([vnm{vars(ii)} '_castflag = cflag;']);
      end
      switch vars(ii)
	case 1
	  vv{ii} = [vv{ii}; scrload(t,jj,deps,t_castflag,scr)];
	case 2
	  vv{ii} = [vv{ii}; scrload(s,jj,deps,s_castflag,scr)];
	case 3
	  vv{ii} = [vv{ii}; scrload(o2,jj,deps,o2_castflag,scr)];
	case 4
	  vv{ii} = [vv{ii}; scrload(si,jj,deps,si_castflag,scr)];
	case 5
	  vv{ii} = [vv{ii}; scrload(po4,jj,deps,po4_castflag,scr)];
	case 6
	  vv{ii} = [vv{ii}; scrload(no3,jj,deps,no3_castflag,scr)];
	case 7
	  vv{ii} = nutdens(jj,deps);
	case 14
	  vv{ii} = [vv{ii}; scrload(no4,jj,deps,no4_castflag,scr)];
	case 15
	  vv{ii} = [vv{ii}; scrload(nh3,jj,deps,nh3_castflag,scr)];
	otherwise
	  vv{ii} = repmat(nan,[nj ndp]);		 
      end
   end

   for ii = inov
      vv{ii} = repmat(nan,[nj ndp]);
   end
end


return

%------------------------------------------------------------------------
function vo = scrload(vv,jj,deps,cflg,scr)

% Are some of the deps BETWEEN rather than ON CSL3 levels?
intp = any(round(deps)~=deps);

if intp
   % If the data depth is close to a CSL depth, we say that is close enough
   % (these are indices, so .1 refers to portion of depth *interval*)
   if max(abs(round(deps)-deps))<.1
      deps = round(deps);
      intp = 0;
   else
      % Use 1q because it doesn't stop with a warning if nan's in data.
      vo = interp1q([1:size(vv,2)]',vv(jj,:)',deps)';
   end
end
if ~intp
   vo = vv(jj,deps);
end

if scr & ~isempty(cflg)
   kk = find(cflg(jj)>0);
   vo(kk,:) = nan;
end

return

%------------------------------------------------------------------------
% WOD01 is different because stored in WMO files.

function [lo,la,stn,hv,vv] = get_wod01(dset,src,trng,deps,hvar,vars,scr,dpth);


la = [];
lo = [];
stn = [];
nhv = length(hvar);
ndv = length(vars);
hv{nhv} = [];
vv{ndv} = [];

if dset>=25
   disp(['No access to dataset ' num2str(dset) ' yet!'])
   return
end
  
vnm = {'t','s','o2','si','po4','no3','nutdens'};


pth = [dpth 'wod01' filesep];
prefx = {'CTD','OSD','PFL','UOR','DRB','MBT','MRB','XBT'};
ids = dset-20;

if isempty(src)
   src = [0 360 -80 80];
end    
if min(size(src))==1
   wmosq = getwmo(src);
else
   wmosq = getwmo(...
       [min(src(:,1)) max(src(:,1)) min(src(:,2)) max(src(:,2))]);
end


for wmo = wmosq
   fnm = [pth prefx{ids} filesep prefx{ids} num2str(wmo) 'csl.mat'];

   if exist(fnm,'file')
      load(fnm)
      if min(size(src))==1
	 jj = find(lon>=src(1) & lon<=src(2) & lat>=src(3) & lat<=src(4));
      else
	 jj = find(inpolygon(lon,lat,src(:,1),src(:,2)))';
      end

      if ~isempty(trng) & ~isempty(jj)
	 kk = find(time(jj)<trng(1) | time(jj)>=trng(2));
	 jj(kk) = [];
      end

      if ~isempty(jj)
	 nj = length(jj);

	 la = [la; lat(jj)];
	 lo = [lo; lon(jj)];
	 stn = [stn; ocl(jj)];
	 
	 for ii = 1:nhv
	    switch hvar(ii)
	      case 1
		hv{ii} = [hv{ii}; ocl(jj)];
	      case 2
		hv{ii} = [hv{ii}; time(jj)];
	      case 3
		if ~isempty(vars)
		   cfnm = [vnm{vars(1)} '_castflag'];
		   if ~isempty(eval(cfnm))
		      eval(['cflag = ' cfnm ';']);
		      hv{ii} = [hv{ii}; cflag(jj)];
		   end
		end
	      case 4
		hv{ii} = [hv{ii}; botdep(jj)];
	      case 5
		hv{ii} = [hv{ii}; cc(jj)];
	      case 6
		hv{ii} = [hv{ii}; cru(jj)];
	      case 9
		hv{ii} = [hv{ii}; repmat(dset,[nj 1])];
	      case 11
		hv{ii} = [hv{ii}; eval([vnm{vars(1)} 'bot(jj,1)'])];
	      case 12
		hv{ii} = [hv{ii}; eval([vnm{vars(1)} 'bot(jj,2)'])];
	      otherwise
		hv{ii} = [hv{ii}; repmat(nan,[nj 1])];		 
	    end
	 end	

	 for ii = 1:ndv
	    if vars(ii)<=7 & exist(vnm{vars(ii)},'var')
	       switch vars(ii)
		 case 1
		   vv{ii} = [vv{ii}; scrload(t,jj,deps,t_castflag,scr)];
		 case 2
		   vv{ii} = [vv{ii}; scrload(s,jj,deps,s_castflag,scr)];
		 case 3
		   vv{ii} = [vv{ii}; scrload(o2,jj,deps,o2_castflag,scr)];
		 case 4
		   vv{ii} = [vv{ii}; scrload(si,jj,deps,si_castflag,scr)];
		 case 5
		   vv{ii} = [vv{ii}; scrload(po4,jj,deps,po4_castflag,scr)];
		 case 6
		   vv{ii} = [vv{ii}; scrload(no3,jj,deps,no3_castflag,scr)];
		 case 7
		   vv{ii} = [vv{ii}; nutdens(jj,deps)];
		 otherwise
		   vv{ii} = [vv{ii}; repmat(nan,[nj length(deps)])];
	       end
	    else  
	       vv{ii} = [vv{ii}; repmat(nan,[nj length(deps)])];
	    end
	 end
      end    % endif ~isempty(jj)
   
      clear t s o2 si po4 no3 nutdens
   end    % endif exist(fnm,'file')
end     % endfor wmo = wmosq 
	 

%-----------------------------------------------------------------------------
