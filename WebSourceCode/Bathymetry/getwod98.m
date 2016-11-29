% GETWOD98:  Get data from WOD98 observed level dataset. Differs from GETHYDOBS
%        in all vars required to be from same file type, and no cell-output
%        option (which makes it much faster and simpler).
%
%  WARNING: It is very easy here to request huge blocks of data that will
%           exceed the memory of any machine.
% INPUT:
%  range   either [w e s n]
%          or     [x1 y1; x2 y2; x3 y3; ... xn yn]
%  hvar    vector of one or more cast header info codes:
%     1)CPN   2)time   3)OCL   4)castflag   5)country   6)cruise   
%     7)bot_depth   8)pos_stat  9) filetype (ie suf, see below)
%  var     vector of property codes:  
%     ** NOTE: vars must all belong to the same file prefix, eg [1 2 3 9] is
%        ok because all from 'ts_' files, but [2 10] is not ok    **
%     1)t   2)s   3)gamma   4)02   5)Si   6)PO4   7)NO3   8)tflag
%     9)sflag   10)oflag   11)siflag   12)pflag   13)nflag  
%  suf     vector of suffix codes:
%          1-ctd  2-ctd2  3-bot  4-bot2  5-xbt  6-xbt2
%  dlim    [Optional] upper and lower depth limits
%  dmid    [Optional] target depth (return nearest nvals values to this depth)
%  nvals   [Optional] max number of values to return (in dlim range, closest 
%          dmid if dmid given, otherwise limited trim off at bottom of profile.
%
% OUTPUTS:
%  lat,lon  position of casts
%  deps     depths associated with each profile  [ndeps ncasts]
%  hvars    [ncasts X 1] in order specified
%  vars     1 cell for each hvar and var specified (vars being [ndep ncast]
%           profiles) 
%   NOTE: casts with no good values in variable 1 in the depth range are removed.
%
% Copyright J R Dunn, CSIRO Marine Research, Dec 1999
%
% EXAMPLE:  [la,lo,dep,vout] = getwod98([100 120 -40 -30],...
%             [1 7],[7 13],[2 5],[0 2000],[],20);
%           cpn = vout{1}; bdep = vout{2}; no3 = vout{3}; nflg = vout{4};
%
% USAGE [lat,lon,deps,{hvars},{vars}] = 
%               getwod98(range,hvar,var,suf,dlim,dmid,nvals);

function [lat,lon,deps,vout] = getwod98(range,hvar,var,suf,dlim,dmid,nvals)

% $Id: getwod98.m,v 1.4 2002/03/13 10:07:24 dun216 Exp dun216 $
%
% MODS:
% 11/11/99 Speed up by loading directly into output arrays instead of cells,
%          and replacing calls to scaleget by smarter code.
%
% Notes:
%   - feval is used to call some functions so that they can be hidden in the
%     'private' directory rather than cluttering the 'matlab' directory.
%   - output arrays are allocated in blocks for speed ('addbulk' columns
%     whenever needed).

ncquiet;

if nargin<4 | isempty(suf)
   help getwod98
   return
end

if nargin<7
   nvals = [];
end
if nargin<6
   dmid = [];
elseif ~isempty(dmid)
   if isempty(nvals)
      nvals = 1;
   end
end

if nargin<5
   dlim = [];
elseif length(dlim)==1
   dlim = [0 dlim];
end

pth = '/home/eez_data/hydro_obs/';

varn = {'t','s','neut_density','o2','si','po4','no3','t_flag','s_flag',...
      'o2_flag','si_flag','po4_flag','no3_flag'};
hvarn = {'csiro_profile_no','time','ocl_no','cast_flag','country_code',...
      'cruise_no','botdepth','pos_stat'};
sufn = {'_ctd','_ctd2','_bot','_bot2','_xbt','_xbt2'};
prefn = {'ts','o2','si','po4','no3','t'};

% Which of prefices 1-6 goes with any var, for each suffix 
suf2pre = [1 1 1 2 0 0 0 1 1 2 0 0 0;
	   1 1 1 2 0 0 0 1 1 2 0 0 0;
	   1 1 1 2 3 4 5 1 1 2 3 4 5;
	   1 1 1 2 3 4 5 1 1 2 3 4 5;
	   6 0 0 0 0 0 0 6 0 0 0 0 0;
	   6 0 0 0 0 0 0 6 0 0 0 0 0];

nvars = length(var);
ii = find(~suf2pre(suf,var(1)));
if ~isempty(ii)
   suf(ii) = [];
   disp('Some suffices do not go with this data variable');
end

% If salt required, comes from a t&s file, which is only case where have two
% lots of cast flags in one file. Set flag 'salt' so we know to check the
% second set of cast flags.
salt = find(var==2);
if isempty(salt)
   salt = 0;
end

temp = find(var==1);
if isempty(temp)
   temp = 0;
end

nhv = length(hvar);

addbulk = 2000;
maxd = 1;
for iv=1:nvars
   vout{nhv+iv} = repmat(nan,[maxd addbulk]);
end
deps = repmat(nan,[maxd addbulk]);
nbulk = addbulk;

ntot = 0;
lat=[];
lon=[];
dfval = [];

% If range specified as [w e n s] limits, expand to a polygon specification
% so only have to handle that type of spec when selecting casts.
if size(range) == [1 4]
   wmosq = feval('getwmo',range);
   range = [range([1 2 2 1])' range([3 3 4 4])'];
else
   wmosq = feval('getwmo',[min(range(:,1)) max(range(:,1)) min(range(:,2)) max(range(:,2))]);
end


for isf = suf(:)'
   for wmo = wmosq
      fnm = [pth prefn{suf2pre(isf,var(1))} '_obs_' num2str(wmo) sufn{isf} '.nc'];
      if exist(fnm,'file')
	 nco = netcdf(fnm,'nowrite');
	 la = nco{'lat'}(:);
	 lo = nco{'lon'}(:);

	 % Only use casts with cast flag = zero  (If t & s, only exclude
         % casts with non-zero flag for both.) 

	 cflg = nco{'cast_flag'}(:);
	 if salt
	    scflg = nco{'s_cast_flag'}(:);
	    if temp
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
	 end
	 

	 % Catch any rare but possible degenerate profiles (with zero depths)
	 
	 if ~isempty(isin) 
	    ndp = nco{'number_of_depths'}(:);
	    ii = find(ndp(isin)<1);
	    if ~isempty(ii)
	       isin(ii) = [];
	    end
	 end

	 if ~isempty(isin)
	    lat = [lat; la(isin)];
	    lon = [lon; lo(isin)];

	    for hh = 1:nhv
	       if hvar(hh)==9
		  vout{hh} = [vout{hh}; repmat(isf,size(isin))];
	       else
		  tmp = nco{ hvarn{hvar(hh)} }(:);
		  % botdepth & pos_stat may have missing values
		  if hvar(hh)>=7
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
	    
	    % Get the Fill, Missing & scaling values only once, and ASSUME
	    % that Fill & Missing are both large -ve, so can just screen on
	    % the higher of the two. Also ASSUME these are the same for the
	    % same variable throughout the dataset.
	    
	    if isempty(dfval)
	       dfval = nco{'depth'}.FillValue_(:);
	       dmiss = nco{'depth'}.missing_value(:);
	       dfval = max([dfval dmiss]);

	       for iv=1:nvars
		  vfval(iv) = nco{varn{var(iv)}}.FillValue_(:);
		  vmiss = nco{varn{var(iv)}}.missing_value(:);
		  vfval(iv) = max([vfval(iv) vmiss]);

		  tmp = nco{varn{var(iv)}}.scale_factor(:);
		  if isempty(tmp)
		     vscf(iv) = 1;
		  else
		     vscf(iv) = tmp;
		  end
		  tmp = nco{varn{var(iv)}}.add_offset(:);
		  if isempty(tmp)
		     vado(iv) = 0;
		  else
		     vado(iv) = tmp;
		  end
	       end
	    end

	    dep = nco{'depth'}(:);
	    ibd = find(dep<=dfval);
	    if ~isempty(ibd)
	       dep(ibd) = repmat(NaN,size(ibd));
	    end

	    vv = [];
	    for iv=1:nvars     
	       vv(:,iv) = nco{varn{var(iv)}}(:);
	       ibd = find(vv(:,iv)<=vfval(iv));
	       vv(:,iv) = (vv(:,iv).*vscf(iv)) + vado(iv);
	       if ~isempty(ibd)
		  vv(ibd,iv) = repmat(NaN,size(ibd));
	       end
	    end
	    
	    sti = nco{'start_index'}(:);
	    
	    for kk = 1:length(isin)
	       nn = isin(kk);
	       ipx = sti(nn):(sti(nn)+ndp(nn)-1);
	       
	       % Limit to depth range, if required
	       if ~isempty(dlim)
		  ipx = ipx(dep(ipx)>=dlim(1) & dep(ipx)<=dlim(2));
	       end

	       % Limit number of values, if required
	       if ~isempty(nvals) &  length(ipx)>nvals
		  % Extract around a mid-depth, if required
		  if ~isempty(dmid)
		     [tmp,sss] = sort(abs(dep(ipx)-dmid));
		     ipx = ipx(sort(sss(1:nvals)));
		  else
		     ipx = ipx(1:nvals);
		  end
	       end
	       
	       npx = length(ipx);
	       if npx>maxd
		  nadd = npx-maxd;
		  deps = [deps; repmat(nan,[nadd nbulk])];
		  for iv=1:nvars
		     vout{nhv+iv} = [vout{nhv+iv}; repmat(nan,[nadd nbulk])];
		  end
		  maxd = npx;
	       end

	       if ntot+kk > nbulk
		  deps = [deps repmat(nan,[maxd addbulk])];
		  for iv=1:nvars
		     vout{nhv+iv} = [vout{nhv+iv} repmat(nan,[maxd addbulk])];
		  end
		  nbulk = nbulk+addbulk;		  
	       end

	       if npx > 0
		  deps(1:npx,ntot+kk) = dep(ipx);
		  for iv=1:nvars
		     vout{nhv+iv}(1:npx,ntot+kk) = vv(ipx,iv);
		  end
		  if temp & salt
		     if scflg(nn)~=0
			vout{nhv+salt}(1:npx,ntot+kk) = repmat(nan,size(ipx));
		     end
		     if cflg(nn)~=0
			vout{nhv+temp}(1:npx,ntot+kk) = repmat(nan,size(ipx));
		     end
		  end
	       end
	       
	    end                 % Looping (index kk & nn) on casts in region
	    ntot = length(lat);
	 end                    % end of "if there is wanted data"
	 close(nco);
      end                       % end of "if the file exists"
   end                          % Looping on WMOs
end                             % Looping on suffices

if isempty(lat)
   disp('None of this type of data in this region')
   deps = [];
   return
end


% Get rid of profiles with no data in var 1 in the required depth range

ii = find(any(~isnan(vout{nhv+1}(:,1:ntot))));
if ~isempty(ii)
   lat=lat(ii);
   lon=lon(ii);
   deps = deps(:,ii);
   for jj = 1:nhv
      vout{jj} = vout{jj}(ii);
   end
   for jj = 1:nvars
      vout{nhv+jj} = vout{nhv+jj}(:,ii);
   end
else
   lat = [];
   lon = [];
   deps = [];
   for jj = 1:(nhv+nvars)
      vout{jj} = [];
   end   
end
   
%-------------------------------------------------------------------------
