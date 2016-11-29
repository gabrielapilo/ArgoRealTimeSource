% GET_ALL_CSL  Get CSIRO-standard-level hydro & CTD data
%     
% INPUT:  
%  src    [w e s n] limits of region of required data
%      OR defining polygon [x1 y1; x2 y2; x3 y3; ... ] 
%  hvar   vector of one or more cast header info codes:
%         1)CPN   2)time   3)castflag  4)bot_depth   5)country   6)cruise
%         7)pos_stat   8)OCL  9) filetype
%  var    vector of property codes:  
%         ** WOD98 vars must all belong to the same file prefix, eg 
%            [1 2 3 9] is ok (all from 'ts_' files), but [2 10] is not **
%         1)t   2)s  3)02   4)Si  5)PO4   6)NO3   7)gamma  8)tflag
%         9)sflag   10)oflag   11)siflag   12)pflag   13)nflag  14)no4
%         15)nh3
%  suf    vector of suffix codes  (For details, type:   help suf_codes):
%         1)ctd  2)ctd2  3)bot  4)bot2  5)xbt  6)xbt2  7)CSIRO(CTD&Hyd)
%         8)CSIRO XBT archive  9)NIWA  10) French CD 
% *NEW* ->21-24) WOD01:  21-CTD  22-OSD (hydro/bottle) 23-PFL (profiling float)
%                24-UOR ("undulating ocean recorder" - eg SeeSaw or TowYo)  
%         NOTE: only T & S available for WOD01. Preliminary QC (scr>0) is 
%           available only for [30 220 -70 30]; unscreened data is provided
%           outside of this region.
%  deps    Vector of indices of CSLv2 depth levels to extract (not nec contiguous)
%          [use round(dep_csl(depths)) to convert from +ve metres to indices]
%  scr     0 - disable pre-flagged bad-cast and bad-individual-data screening
%          1 - [default] apply screening in data files (eg NODC flags in WOD98)
% *NEW* -> 2 - apply CARS T/S and mapping-residuals screening as well 
%
% OUTPUT:
%  v1 etc  [ncast ndep] for property vars, [ncast] for header vars
%
% NOTE:  For each cast-row there will be at least some data in at least one
%   of the returned variables. Empty depth columns will only occur if there
%   is deeper good data.
%
% USAGE: [lat,lon,v1,v2,..] = get_all_csl(src,hvar,vars,suf,deps,scr);

% $Id: get_all_csl.m,v 1.7 2004/10/12 22:45:24 dun216 Exp dun216 $
% Author: Jeff Dunn  CSIRO Marine Research Dec 1999
% Devolved from get_all_obs.m

function [lat,lon,varargout] = get_all_csl(src,hvar,vars,suf,deps,scr)

if nargin<5 | isempty(deps)
   disp('  GET_ALL_CSL  requires 5 or 6 input arguments')
   help get_all_csl
   disp('  NOTE: ');
   disp('Can only extract data from one prefix-type of WOD98 files at a time.');
   disp('PREFIX   SUFFIX      VARS');
   disp(' ts     bot  ctd     t   s  gamma  tflag  sflag');
   disp(' o2     bot  ctd     o2  gamma  o2_flag');
   disp(' no3    bot          no3 gamma  no3_flag');
   disp(' po4    bot          po4 gamma  po4_flag');
   disp(' si     bot          si  gamma  si_flag');
   disp(' t      xbt          t   t_flag');
   disp(' Note: suffix bot implies bot and bot2, likewise for ctd & xbt');
   return
end

if nargin<6 | isempty(scr)
   scr = 1;
end   

if max(deps>56) | any(diff(deps)==10) | any(deps==0)
   disp([7 'The "deps" vector given suggests you have specified depths in m,']);
   disp('rather than depth level indices! If nec., convert using dep_csl.');
end

if isempty(hvar)
   icpn = [];
else
   icpn = find(hvar==1);
end
if isempty(icpn) & scr==2
   hvar = [hvar(:)' 1];
   icpn = length(hvar);
   wantcpn = 0;
else
   wantcpn = 1;
end

nhv = length(hvar);
nvar = length(vars);
iv = nhv+(1:nvar);

lat = []; lon = [];
varargout{nhv+nvar} = [];


if any(suf==8)
   % Get CSIRO "Thermal Archive" (TA) XBT, and WOD XBT if required. If no TA
   % casts in src region, leave WOD XBT for other WOD extraction below.

   suf(find(suf==8)) = [];
   [lat,lon,vout] = getCSIROxbt(src,hvar,vars,deps);   

   if ~isempty(lat)
      varargout = vout;

      ii = find(suf==5 | suf==6);
      if ~isempty(ii)
	 % If want WOD98 XBT data, need to chop out that which is already in the 
	 % Thermal Archive. Can't just restrict src, because it might be a
	 % polygon (could adjust the polygon, but that requires too much thinking).
	 wsuf = suf(ii);
	 suf(ii) = [];
	 [la,lo,vout] = getwodcsl(src,hvar,vars,wsuf,deps,scr);
	 kk = find(la<=0 & lo>=90 & lo<=145);
	 if ~isempty(kk)
	    la(kk) = [];
	    lo(kk) = [];
	    for jj = 1:nhv
	       vout{jj}(kk) = [];
	    end
	    for jj = iv
	       vout{jj}(kk,:) = [];
	    end
	 end
	 if ~isempty(la)
	    lat = [lat; la];
	    lon = [lon; lo];   
	    for jj = 1:nhv
	       varargout{jj} = [varargout{jj}; vout{jj}];
	    end
	    [mpad,npad] = addvout(size(varargout{iv(1)}),size(vout{iv(1)}));
	    for jj = iv
	       varargout{jj} = [[varargout{jj} mpad]; [vout{jj} npad]];
	    end
	 end
      end
   end
end


% Now load all WOD98 data (except any XBT data which may have just been
% loaded above.)
ii = find(suf<=6);
wsuf = suf(ii);
suf(ii) = [];

if ~isempty(wsuf)
   [la,lo,vout] = getwodcsl(src,hvar,vars,wsuf,deps,scr);
   if ~isempty(la)
      if isempty(lat)
	 lat = la;
	 lon = lo;
	 varargout = vout;
      else
	 lat = [lat; la];
	 lon = [lon; lo];   
	 for jj = 1:nhv
	    varargout{jj} = [varargout{jj}; vout{jj}];
	 end
	 [mpad,npad] = addvout(size(varargout{iv(1)}),size(vout{iv(1)}));
	 for jj = iv
	    varargout{jj} = [[varargout{jj} mpad]; [vout{jj} npad]];
	 end
      end
   end
end


% Load any WOD01 data - TEMPORARY and INTERIM implementation - Oct 04

ii = find(suf>=21 & suf<=24);
wsuf = suf(ii);
suf(ii) = [];

if all(vars~=1) & all(vars~=2)
   wsuf = [];
end
   
dpth = platform_path('cascade','oez5/eez_data/duplicates/');

for ids = wsuf(:)'
   [la,lo,time,bdep,stnno,tz,sz] = getwod01(src,ids,vars,deps,scr);

   jj = 1:length(la);
   
   % Remove duplicates between this and other requested datasets
   if ids==21 | ids==22
      if any(suf==7)
	 load([dpth num2str(ids) '_7_dups']);
	 ii = ~ismember(stnno(jj),dupstn);
	 jj = jj(ii);
	 if vars(1)==6
	    load([dpth num2str(ids) '_71_dups']);
	    ii = ~ismember(stnno(jj),dupstn);
	    jj = jj(ii);
	 end
      end
      if any(suf==9)
	 load([dpth num2str(ids) '_9_dups']);
	 ii = ~ismember(stnno(jj),dupstn);
	 jj = jj(ii);
      end
   end
   if ids==22 & any(suf==21)
      load([dpth '22_21_dups']);
      ii = ~ismember(stnno(jj),dupstn);
      jj = jj(ii);
   end
   
   if ~isempty(jj)
      lat = [lat; la(jj)];
      lon = [lon; lo(jj)];   
      for kk = 1:nhv
	 if hvar(kk)==1
	    varargout{kk} = [varargout{kk}; stnno(jj)];
	 elseif hvar(kk)==2
	    varargout{kk} = [varargout{kk}; time(jj)];
	 elseif hvar(kk)==4
	    varargout{kk} = [varargout{kk}; bdep(jj)];
	 elseif hvar(kk)==8
	    % For WOD01, stnno *is* OCL 
	    varargout{kk} = [varargout{kk}; stnno(jj)];
	 elseif hvar(kk)==9
	    varargout{kk} = [varargout{kk}; repmat(ids,size(la(jj)))];
	 else
	    varargout{kk} = [varargout{kk}; repmat(nan,size(la(jj)))];
	 end
      end
      if vars(1)==1
	 [sz1,sz2] = size(tz(jj,:));
      else
	 [sz1,sz2] = size(sz(jj,:));
      end
      [mpad,npad] = addvout(size(varargout{iv(1)}),[sz1 sz2]);

      for kk = iv
	 if vars(kk-nhv)==1
	    varargout{kk} = [[varargout{kk} mpad]; [tz(jj,:) npad]];
	 elseif vars(kk-nhv)==2
	    varargout{kk} = [[varargout{kk} mpad]; [sz(jj,:) npad]];
	 else
	    varargout{kk} = [[varargout{kk} mpad]; [repmat(nan,[sz1 sz2]) npad]];
	 end
      end
   end
end



for isuf = suf
   if isuf==7
      [la,lo,vout] = getCSIROcsl(src,hvar,vars,deps,scr);
   elseif isuf==9
      [la,lo,vout] = get_niwa(src,hvar,vars,deps,scr);
   elseif isuf==10
      [la,lo,vout] = get_french(src,hvar,vars,deps,scr);
   else
      la = [];
   end

   if ~isempty(la) & nvar>0
      % Get rid of profiles with no data in any var in the required depth range

      [ncst,ndep] = size(vout{iv(1)});
      some = zeros(1,ncst);
      for jj = iv
	 if ndep==1
	    some = (some | ~isnan(vout{jj}'));
	 else
	    some = (some | any(~isnan(vout{jj}')));
	 end
      end
      rr = find(~some);
      if ~isempty(rr)
	 la(rr) = [];
	 lo(rr) = [];
	 for jj = 1:nhv
	    vout{jj}(rr) = [];
	 end
	 for jj = iv
	    vout{jj}(rr,:) = [];
	 end	    
      end

      % Get rid of depths below the last data in any cast in any var.

      some = zeros(nvar,ndep);
      for jj = iv
	 some(jj,:) = any(~isnan(vout{jj}));
      end
      if nvar==1
	 ldp = max(find(some));
      else
	 ldp = max(find(any(some)));
      end	 
      if ldp < ndep
	 for jj = iv
	    vout{jj}(:,(ldp+1):ndep) = [];
	 end	    
      end

      [mpad,npad] = addvout(size(varargout{iv(1)}),size(vout{iv(1)}));
      for jj = iv
	 varargout{jj} = [[varargout{jj} mpad]; [vout{jj} npad]];
      end
   end
      
   if ~isempty(la)
      lat = [lat; la];
      lon = [lon; lo];   
      for jj = 1:nhv
	 varargout{jj} = [varargout{jj}; vout{jj}];
      end
   end
end


if scr==2
   % Apply EEZ screening (T-S and mapping-residuals screening) 
   infodir = platform_path('cascade','dunn/eez/qc_data/');
   par = {'t','s','o2','si','po4','no3'};
   cpn = varargout{icpn};

   for ii = 1:nvar
      if vars(ii)<=6 & ~isempty(varargout{iv(ii)}) 
	 for jj = 1:size(varargout{iv(ii)},2)
	    depm = csl_dep(deps(jj),2);
	    fname = [infodir par{vars(ii)} '_' num2str(depm) '_scr'];
	    if exist([fname '.mat'],'file')
	       load(fname,'cpnscr');
	       II = find(ismember(cpn,cpnscr));
	       if ~isempty(II)
		  varargout{iv(ii)}(II,jj) = repmat(nan,size(II));
	       end
	    end
	 end
      end
   end

   if ~wantcpn
      varargout(icpn) = [];
   end
end

return

%------------------------------------------------------------------------
% GET_NIWA  Get NIWA CSL CTD data from .mat file

function [la,lo,vaout] = get_niwa(src,hvar,vars,deps,scr)

la = [];
lo = [];
nhv = length(hvar);
nv = length(vars);
for ii = 1:(nhv+nv)
   vaout{ii} = [];
end

if all(vars>4) & all(hvar>4)
   return
end

% Calc and restrict stdep as only 57 levels in NIWA file.

deps = deps(find(deps<=57));

fnm = platform_path('fips','eez_data/hydro/niwa_csl');
load(fnm);

mm = 1:length(lon);

% If screening, remove indices to flagged casts
if scr
   rr = find(cflag~=0);
   if ~isempty(rr)
      mm(rr) = [];
   end
end
   
if min(size(src))==1
   ii = mm(find(lon(mm)>=src(1) & lon(mm)<=src(2) & lat(mm)>=src(3) & lat(mm)<=src(4)));
else
   ii = mm(find(isinpoly(lon(mm),lat(mm),src(:,1),src(:,2))));
end

if ~isempty(ii)
   la = lat(ii);
   lo = lon(ii);

   for jj = 1:nhv
      switch hvar(jj)
       case 1
	  vaout{jj} = prid(ii);
       case 2
	  vaout{jj} = time(ii);
       case 3
	  vaout{jj} = cflag(ii);
       case 4
	  vaout{jj} = botdepth(ii);
       case 9
	  % "FileType" which is 9 for NIWA data.
	  vaout{jj} = repmat(9,size(prid(ii)));
       otherwise
	  vaout{jj} = repmat(nan,size(prid(ii)));
      end
   end
	
   for jj = 1:nv
      switch vars(jj)
       case 1
	  vaout{nhv+jj} = t(ii,deps);
       case 2
	  vaout{nhv+jj} = s(ii,deps);
       case 3
	  vaout{nhv+jj} = o2(ii,deps);
       case 7
	  vaout{nhv+jj} = nutdens(ii,deps);
       otherwise
	  vaout{nhv+jj} = repmat(nan,[length(ii) length(deps)]);      
      end
   end
end

return


%------------------------------------------------------------------------
% GET_FRENCH  Get French_CD_2001  CSL data from .mat file

function [la,lo,vaout] = get_french(src,hvar,vars,deps,scr)

la = [];
lo = [];
nhv = length(hvar);
nv = length(vars);
for ii = 1:(nhv+nv)
   vaout{ii} = [];
end

if all(vars>2 & vars~=7) & all(hvar>6)
   return
end

% Calc and restrict stdep as only 57 levels in french_csl file.

deps = deps(find(deps<=57));

fnm = platform_path('fips','eez_data/hydro/french_csl');
load(fnm);

mm = 1:length(lon);

% If screening, remove indices to flagged casts
if scr
   rr = find(cflag~=0);
   if ~isempty(rr)
      mm(rr) = [];
   end
end
   
if min(size(src))==1
   ii = mm(find(lon(mm)>=src(1) & lon(mm)<=src(2) & lat(mm)>=src(3) & lat(mm)<=src(4)));
else
   ii = mm(find(isinpoly(lon(mm),lat(mm),src(:,1),src(:,2))));
end

% These variables need to be vectors

if ~isempty(ii)
   la = lat(ii)';
   lo = lon(ii)';

   for jj = 1:nhv
      switch hvar(jj)
	case 1
	  vaout{jj} = 80000000+ii(:);
	case 2
	  vaout{jj} = time(ii)';
	case 3
	  vaout{jj} = cflag(ii)';
	case 4
	  vaout{jj} = botdepth(ii)';
	case 6
	  vaout{jj} = cru_num(ii)';
	case 9
	  % "FileType" which is 10 for French CD data.
	  vaout{jj} = repmat(10,size(ii(:)));
       otherwise
	  vaout{jj} = repmat(nan,size(ii(:)));
      end
   end
	
   for jj = 1:nv
      switch vars(jj)
       case 1
	  vaout{nhv+jj} = t(ii,deps);
       case 2
	  vaout{nhv+jj} = s(ii,deps);
       case 7
	  vaout{nhv+jj} = nutdens(ii,deps);
       otherwise
	  vaout{nhv+jj} = repmat(nan,[length(ii) length(deps)]);      
      end
   end
end

return


%---------------------------------------------------------------------------
function [mpad,npad] = addvout(so,sn)

% Create padding so that can append new to existing data, even if have
% different number of depths

if sn(2)>so(2)
   mpad = repmat(nan,so(1),sn(2)-so(2));
   npad = [];
elseif sn(2)<so(2)
   mpad = [];
   npad = repmat(nan,sn(1),so(2)-sn(2));
else
   mpad = [];
   npad = [];
end

%--------------------------------------------------------------------------
% GETWOD01
%
% As an interim treatment, this plugs into files in /home/oez5/eez_data/wod01csl3/
% These are CSL v3 (like the ones in /home/oez5/eez_data/wod01csl/ from which
% they are derived) but have had preliminary T-S and CARS screening.
%
% INPUT:
%  range   [w e s n]  OR   [x1 y1; x2 y2; x3 y3; ... xn yn]
%
% USAGE [la,lo,tim,bdep,cpn,tt,ss] = getwod01(range,ids,vars,deps,scr);

function [la,lo,tim,bdep,cpn,tt,ss] = getwod01(range,ids,vars,deps,scr)

cpn = [];
la = [];
lo = [];
tim = [];
bdep = [];
tt = [];
ss = [];

tdeps = csl_dep(1:79,3);
mdeps = csl_dep(deps,2);
idep = find(ismember(tdeps,mdeps));

if scr==0
   pth = platform_path('cascade','oez5/eez_data/wod01csl/');
else
   pth = platform_path('cascade','oez5/eez_data/wod01csl3/');
   pth2 = platform_path('cascade','oez5/eez_data/wod01csl/');
end

prefx = {'CTD','OSD','PFL','UOR'};

if isempty(range)
   range = [0 0 360 360; 90 -80 -80 90]';
elseif min(size(range))==1
   wmosq = getwmo(range);
   range = range(:)';
   range = [range([1 1 2 2]); range([3 4 4 3])]'; 
else
   wmosq = getwmo(...
       [min(range(:,1)) max(range(:,1)) min(range(:,2)) max(range(:,2))]);
end


for wmo = wmosq
   fnm = [pth prefx{ids-20} filesep prefx{ids-20} num2str(wmo) 'csl.mat'];
   if ~exist(fnm,'file') & scr>0
      fnm = [pth2 prefx{ids-20} filesep prefx{ids-20} num2str(wmo) 'csl.mat'];
   end

   if exist(fnm,'file')
      load(fnm)
      isin = find(inpolygon(lon,lat,range(:,1),range(:,2)))';

      t = t(isin,idep);
      s = s(isin,idep);

      if ~isempty(isin) & exist('tcflag','var')
	 bd = find(tcflag(isin)>0);	 
	 if ~isempty(bd)
	    t(bd,:) = nan;
	 end
	 bd = find(scflag(isin)>0);
	 if ~isempty(bd)
	    s(bd,:) = nan;
	 end
      end
	 
      % Remove empty casts
      if any(vars==1) & any(vars==2)
	 bd = find(all(isnan(t),2) + all(isnan(s),2));
      elseif any(vars==1)
	 bd = find(all(isnan(t),2));
      else	 
	 bd = find(all(isnan(s),2));
      end
      if ~isempty(bd)
	 isin(bd) = [];
	 t(bd,:) = [];
	 s(bd,:) = [];
      end
	 
      if ~isempty(isin)
	 la = [la; lat(isin)'];
	 lo = [lo; lon(isin)'];
	 tim = [tim; time(isin)'];
	 bdep = [bdep; botdep(isin)'];
	 cpn = [cpn; ocl(isin)'];
	 if any(vars==1)
	    tt = [tt; t];
	 end
	 if any(vars==2)
	    ss = [ss; s];
	 end
      end
   end
end

return

%---------------------------------------------------------------------------
