% GETWODCSL:  Get data from WOD98 standard-level (CSL) dataset.
%
%  WARNING: It is very easy here to request huge blocks of data that will
%           exceed the memory of any machine.
% INPUT:
%  range   either [w e s n]     OR     [x1 y1; x2 y2; x3 y3; ... xn yn]
%  hvar    vector of one or more cast header info codes:
%          1)CPN   2)time   3)castflag   4)bot_depth   5)country   6)cruise   
%          7)pos_stat   8)OCL   9) Filetype
%  var     vector of property codes:  
%     ** NOTE: vars must all belong to the same file prefix, eg [1 2 7 9] is
%        ok because all from 'ts_' files, but [2 10] is not ok    **
%          1)t   2)s   3)02   4)Si   5)PO4   6)NO3   7)gamma   8)tflag
%          9)sflag   10)oflag   11)siflag   12)pflag   13)nflag  
%  suf     vector of suffix codes:
%          1-ctd  2-ctd2  3-bot  4-bot2  5-xbt  6-xbt2
%  deps    Vector of indices of CSL depth levels to extract 
%          [use round(dep_csl(depths)) to convert from +ve metres to indices]
%  scr     [] or 1 or [1 1] = use cast and data flag screening
%          [B B]  B=0 disables  cast and/or data flag screening respectively   
%
% OUTPUTS:
%  lat,lon  position of casts
%  vars     1 cell for each hvar and var specified (vars being [ncast ndep])
%
%   NOTE: casts with no good values in the depth range are removed.
%         depths below deepest available data are removed.
%         
% EXAMPLE:  [la,lo,vout] = getwodcsl([100 120 -40 -30],[1 7],[7 13],[2 5],[5 7 19]);
%           cpn = vout{1}; bdep = vout{2}; no3 = vout{3}; nflg = vout{4};
%
% USAGE [lat,lon,vout] = getwodcsl(range,hvar,var,suf,deps,scr);

function [lat,lon,vout] = getwodcsl(range,hvar,var,suf,deps,scr)

% $Id: getwodcsl.m,v 1.4 2002/04/15 02:17:18 dun216 Exp dun216 $
%  Devolved from getwod98.m,v 1.2
%
% Copyright J R Dunn, CSIRO Marine Research, Mar 2000
%
% Notes:
%   - feval is used to call some functions so that they can be hidden in the
%     'private' directory rather than cluttering the 'matlab' directory.
%
% MODS:  14/7/00 Make cast_flag and scast_flag profile blanking closer to the 
%        truth, esp. when both t & s requested.
   
ncquiet;

if nargin<4 | isempty(suf)
   help getwodcsl
   return
end

nvars = length(var);
nhv = length(hvar);
vout{nhv+nvars} = [];

idxv = find(var<=13);
notv = find(var>13);

lat=[];
lon=[];

if nargin<5 | isempty(deps)
   deps = 1:56;
else
   deps = deps(find(deps<=56));
end

if nargin<6 | isempty(scr)
   cflscr = 1;
   datscr = 1;
elseif length(scr)==1
   cflscr = scr;
   datscr = scr;
else
   cflscr = scr(1);
   datscr = scr(2);
end

pth = '/home/eez_data/hydro/';

varn = {'t','s','o2','si','po4','no3','neut_density','t_flag','s_flag',...
      'o2_flag','si_flag','po4_flag','no3_flag'};
varf = {'t_flag','s_flag','o2_flag','si_flag','po4_flag','no3_flag'};
hvarn = {'csiro_profile_no','time','cast_flag','botdepth','country_code',...
      'cruise_no','pos_stat','ocl_no'};
sufn = {'_ctd','_ctd2','_bot','_bot2','_xbt','_xbt2'};
prefn = {'ts','o2','si','po4','no3','t'};

% Which of prefices 1-6 goes with any var, for each suffix 
suf2pre = [1 1 2 0 0 0 1 1 1 2 0 0 0;
	   1 1 2 0 0 0 1 1 1 2 0 0 0;
	   1 1 2 3 4 5 1 1 1 2 3 4 5;
	   1 1 2 3 4 5 1 1 1 2 3 4 5;
	   6 0 0 0 0 0 0 6 0 0 0 0 0;
	   6 0 0 0 0 0 0 6 0 0 0 0 0];

for jj = idxv(:)'
   ii = find(~suf2pre(suf,var(jj)));
   if ~isempty(ii)
      suf(ii) = [];
      disp(['Some suffices do not go with data variable "' varn{var(jj)} '"']);
      bell
   end
end
if isempty(suf)
   disp(' ');
   disp('Can only extract data from one prefix-type of WOD98 files at a time.');
   disp('PREFIX   SUFFIX      VARS');
   disp(' ts     bot  ctd     t   s  gamma  tflag  sflag');
   disp(' o2     bot  ctd     o2  gamma  o2_flag');
   disp(' no3    bot          no3 gamma  no3_flag');
   disp(' po4    bot          po4 gamma  po4_flag');
   disp(' si     bot          si  gamma  si_flag');
   disp(' t      xbt          t   t_flag');
   disp(' Note: suffix bot implies bot and bot2, likewise for ctd & xbt');
   disp(' ');
   disp('You have not complied with the rule above - NO ACTION PERFORMED');
   return
end
   
% If salt required, comes from a t&s file, which is only case where have two
% lots of cast flags in one file. Set flag 'salt' so we know to check the
% second set of cast flags.
salt = any(var==2);
tem = any(var==1);

% Clumsy way to extract s_cast_flag instead of cast_flag if only looking at salt
if salt & ~tem
   hvarn{3} = 's_cast_flag';
end

% If range specified as [w e n s] limits, expand to a polygon specification
% so only have to handle that type of spec when selecting casts.
if size(range) == [1 4]
   wmosq = feval('getwmo',range);
   range = [range([1 2 2 1])' range([3 3 4 4])'];
else
   wmosq = feval('getwmo',[min(range(:,1)) max(range(:,1)) min(range(:,2)) max(range(:,2))]);
end


for isf = suf(:)'
   fpref = prefn{suf2pre(isf,var(idxv(1)))};
   for wmo = wmosq
      fnm = [pth fpref '_' num2str(wmo) sufn{isf} '.nc'];
      if exist(fnm,'file')
	 nc = netcdf(fnm,'nowrite');
	 la = nc{'lat'}(:);
	 lo = nc{'lon'}(:);

	 % If castflag screening, only use casts with cast flag = zero  
	 % (If t & s, only exclude casts with non-zero flag for both.) 

	 sout = [];
	 cout = [];
	 if cflscr
	    cflg = nc{'cast_flag'}(:);
	    if salt
	       scflg = nc{'s_cast_flag'}(:);
	       if tem
		  ii = find(cflg==0 | scflg==0);
	       else
		  ii = find(scflg==0);
	       end
	    else
	       ii = find(cflg==0);
	    end
	    if isempty(ii)
	       isin = [];
	    else
	       isin = ii(find(feval('isinpoly',lo(ii),la(ii),range(:,1),range(:,2))));
	       if ~isempty(isin) & salt
		  sout = find(scflg(isin)~=0);
		  if tem
		     cout = find(cflg(isin)~=0);
		  end
	       end
	    end
	 else
	    isin = find(feval('isinpoly',lo,la,range(:,1),range(:,2)));
	 end
	 
	 if ~isempty(isin)
            ndp = length(nc('depth'));
	    reqd = deps(find(deps<=ndp));
	    if isempty(reqd); isin = []; end
	 end
	 
	 if ~isempty(isin)
	    lat = [lat; la(isin)];
	    lon = [lon; lo(isin)];

	    for hh = 1:nhv
	       if hvar(hh)==9
		  vout{hh} = [vout{hh}; repmat(isf,size(isin))];
	       else
		  tmp = nc{ hvarn{hvar(hh)} }(:);
		  % botdepth & pos_stat may have missing values
		  if hvar(hh)==4 | hvar(hh)==7
		     ii = find(tmp<=-32765);
		     tmp(ii) = repmat(nan,size(ii));
		  end
		  % Convert country_code from char*2 to double
		  if hvar(hh)==5
		     tmp = double(tmp(:,1)*256) + double(tmp(:,2));
		  end
		  vout{hh} = [vout{hh}; tmp(isin)];
	       end
	    end
	    
            % Netcdf files can only be read in contiguous blocks, so we
            % extract the block dp1:dp2 which contains all the reqd depths.
	    % If already have more depths than available in this file, pad
            % new data block to size of existing block. If more new depths
	    % than existing, need to pad existing.
	    
            dp1 = min(reqd);
	    dp2 = max(reqd);
	    ndp = length(reqd);
	    [nco,ndo] = size(vout{nhv+1});
	    for iv = idxv
	       vtmp = nc{varn{var(iv)}}(:,dp1:dp2);
	       % Extract required casts and depths from the hyperslab read.
	       vtmp = vtmp(isin,reqd+1-dp1);
	       if var(iv)==2 & ~isempty(sout)
		  vtmp(sout,:) = repmat(nan,length(sout),ndp);
	       elseif ~isempty(cout) 
		  vtmp(cout,:) = repmat(nan,length(cout),ndp);
	       end
	       if ndo > ndp
		  vtmp = [vtmp repmat(nan,length(isin),ndo-ndp)];
	       elseif ndo < ndp
		  vout{nhv+iv} = [vout{nhv+iv} repmat(nan,nco,ndp-ndo)];
	       end

	       if datscr & var(iv)<=6
		  flg = nc{varf{var(iv)}}(:,dp1:dp2);
		  rr = find(flg(isin,reqd+1-dp1));
		  vtmp(rr) = repmat(nan,size(rr));
	       end
		  
	       vout{nhv+iv} = [vout{nhv+iv}; vtmp];
	    end
	    
	 end                    % end of "if there is wanted data"
	 close(nc);
      end                       % end of "if the file exists"
   end                          % Looping on WMOs
end                             % Looping on suffices

if isempty(lat)
   disp('None of this type of data in this region')
   deps = [];
   return
end


% Remove useless rows or columns. Restrict testing to data properties, ie
% exclude any 'flags' from testing, because they have zeros instead of NaNs
% where corresponding data is missing (so they would foil the testing).

iv = find(var<=7);
if ~isempty(iv)
   % Get rid of profiles with no data in any var in the required depth range
   
   [nco,ndo] = size(vout{nhv+iv(1)});
   some = zeros(1,nco);
   for ii = iv
      if ndo == 1
	 some = (some | ~isnan(vout{nhv+ii}'));
      else
	 some = (some | any(~isnan(vout{nhv+ii}')));
      end
   end
   rr = find(~some);
   
   if ~isempty(rr)
      lat(rr) = [];
      lon(rr) = [];
      for jj = 1:nhv
	 vout{jj}(rr) = [];
      end
      for jj = idxv
	 vout{nhv+jj}(rr,:) = [];
      end
   end

   % Get rid of depths below the last data in any cast in any var.
   % Add an extra row of zeros to 'some' so that even if length(iv)==1 the
   % "any(some)" will still act column-wise, rather than switching to
   % row-wise.
   
   some = zeros(length(iv)+1,ndo);
   for ii = iv
      some(ii,:) = any(~isnan(vout{nhv+ii}));
   end
   ldp = max(find(any(some)));

   if ldp < ndo
      for jj = idxv
	 vout{nhv+jj}(:,(ldp+1):ndo) = [];
      end
   end
end


% Fill in vars unavailable in WOD98 with dummy outputs.

if ~isempty(notv)
   [nco,ndo] = size(vout{nhv+idxv(1)});
   for jj = notv
      vout{nhv+jj} = repmat(nan,nco,ndo);
   end
end
   
%-------------------------------------------------------------------------


