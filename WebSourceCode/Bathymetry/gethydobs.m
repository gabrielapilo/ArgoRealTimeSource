% GETHYDOBS:  Get data from WOA98 observed level datasets
%
%    BUG: doesn't check s_cast_flag - so bad salinity casts may be included!
%
%    WARNING: Memory use within this script is 2x that of outputs, and
%             it is very easy to request huge outputs!
%INPUT:
%  range   either [w e s n]
%          or     [x1 y1; x2 y2; x3 y3; ... xn yn]
%  hvar    vector of one or more cast header info codes:
%     1)CPN   2)time   3)OCL   4)castflag   5)country   6)cruise   
%     7)bot_depth   8)pos_stat
%  var     vector of one or more property codes: 
%     1)t   2)s   3)gamma   4)02   5)Si   6)PO4   7)NO3   8)tflag
%     9)sflag   10)oflag   11)siflag   12)pflag   13)nflag  
%  iftyp   vector of filetype codes:
%          1-ctd  2-bot  3-xbt  5-noNODAR  6-NODARonly  8-CSIRO
%  dlim    [Optional] upper and lower depth limits
%  dmid    [Optional] target depth (return nearest nvals values to this depth)
%  nvals   [Optional] max number of values to return (in dlim range, closest 
%          dmid if dmid given, otherwise limited trim off at bottom of profile.
%  ara     [Optional] 0 = leave profiles as vectors of cells [default 1] 
%  oset    [Optional] 1=hydro_obs 2=hydro_obs2 [default 1]
%
%OUTPUTS:
%  lat,lon  position of casts
%  deps     depths associated with each profile  [ndeps ncasts]
%  header_vars   1 argument for each hvar specified
%  data_vars     1 argument for each var specified, each consisting of
%           .profile  [ndep ncast] profiles for this var 
%           .idx      links these profile to header variables
%  NOTE: some variables do not have data for every station
%
% Copyright J R Dunn, CSIRO Marine Research, Tue Dec 15 17:08:43 EDT 1998
%
%EXAMPLE:  [la,lo,dep,cpn,botdep,no3,s,gam] = gethydobs([100 120 -40 -30],...
%             [1 7],[7 2 3],[2 5],[0 2000],[],20);
%          ii = no3.idx;     plot(lo(ii),la(ii),'+'); 
%          jj = no3.idx(5);  plot(no3.profile(:,5),depth(:,jj))
%
%USAGE [lat,lon,deps,{header_vars},{data_vars}] = 
%               gethydobs(range,hvar,var,iftyp,dlim,dmid,nvals,ara,oset);

% $Id: gethydobs.m,v 1.4 1999/07/09 00:46:01 dunn Exp dun216 $
%
% BEWARE  - this IS a hideous piece of code. The task might seem simple, but
%           its NOT. An earlier version loaded profiles into a self-expanding
%           3-D matrix (so didn't need to muck around with keeping track of
%           cells) but self-expansion uses 0s instead of NaNs, so had to take
%           care to NaN those expansion 0s. That version was no more 
%           maintainable, and had less functionality and user-friendliness.
%
%           Use of a temporary main variable storage was also abandonned as
%           memory consumption was such an issue - so now load straight into
%           varargout.
%
% Notes:
%   - feval is used to call some functions so that they can be hidden in the
%     'private' directory rather than cluttering the 'matlab' directory.
%     Cannot do this for 'scaleget' as feval crashes if given string arguments.

function [lat,lon,deps,varargout] = gethydobs...
      (range,hvar,var,iftyp,dlim,dmid,nvals,ara,oset)

ncquiet;

if nargin<4 | isempty(iftyp)
   help gethydobs
   return
end

if nargin<9 | isempty(oset)
   oset = 1;
end
if nargin<8 | isempty(ara)
   ara = 1;
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

if oset==1
   pth = '/home/eez_data/hydro_obs/';
else
   pth = '/home/eez_data/hydro_obs2/';
end

varn = {'t','s','neut_density','o2','si','po4','no3','t_flag','s_flag',...
      'o2_flag','si_flag','po4_flag','no3_flag'};
hvarn = {'csiro_profile_no','time','ocl_no','cast_flag','country_code',...
      'cruise_no','botdepth','pos_stat'};
sufn = {'_ctd','_ctd2','_bot','_bot2','_xbt','_xbt2'};
prefn = {'ts','o2','si','po4','no3','t'};

% Which prefices goes with CTD suffices
ctdpref =  [1 1 1 2 0 0 0 1 1 2 0 0 0];
% Which prefices goes with BOT suffices
botpref =  [1 1 1 2 3 4 5 1 1 2 3 4 5];
% Which vars go with which of prefices 1-6. 
pref2var = [1 1 1 0 0 0 0 1 1 0 0 0 0;      
            0 0 0 1 0 0 0 0 0 1 0 0 0;
	    0 0 0 0 1 0 0 0 0 0 1 0 0;
	    0 0 0 0 0 1 0 0 0 0 0 1 0;
	    0 0 0 0 0 0 1 0 0 0 0 0 1;
            1 0 0 0 0 0 0 1 0 0 0 0 0];

nhv = length(hvar);

% v2a identifies which vars are required and their order as output arguments
v2a = zeros([1 13]);
v2a(var) = nhv + (1:length(var));

varargout{nhv+length(var)} = [];
varidx{max(var)} = [];

if ~isempty(find(iftyp==8))
   bell; 
   disp('Sorry - CSIRO observed level data extraction not yet implemented') 
   if length(iftyp)==1
      return
   end
end

np_tot = 0;
lat=[];
lon=[];
cpn=[];
deps=[];
depth={};


% If range specified as [w e n s] limits, expand to a polygon specification
% so only have to handle that type of spec when selecting casts.
if size(range) == [1 4]
   wmosq = feval('getwmo',range);
   range = [range([1 2 2 1])' range([3 3 4 4])'];
else
   wmosq = feval('getwmo',[min(range(:,1)) max(range(:,1)) min(range(:,2)) max(range(:,2))]);
end


% Make list of required file types
suf = zeros(1,6);
if any(iftyp==1); suf(1:2) = [1 1]; end
if any(iftyp==2); suf(3:4) = [1 1]; end
if any(iftyp==3); suf(5:6) = [1 1]; end
if any(iftyp==5); suf([2 4 6]) = [0 0 0]; end
if any(iftyp==6); suf([1 3 5]) = [0 0 0]; end
suf = find(suf);


for isf = suf
   %disp(['Files ending in ' sufn{isf}])
   
   % Which prefices are appropriate for these suffices and required properties?
   if isf==1 | isf==2
      prefs = unique(ctdpref(find(v2a & ctdpref)));
   elseif isf==3 | isf==4
      prefs = unique(botpref(find(v2a & botpref)));
   else
      prefs = 6;
   end

   for wmo = wmosq
      cpn_wmo = [];
      vars_wmo = [];
      np_wmo = 0;
      for ip = prefs
	 % Which of required vars go with this prefix
	 reqv = find(pref2var(ip,:) & v2a); 

	 fnm = [pth prefn{ip} '_obs_' num2str(wmo) sufn{isf} '.nc'];
	 if exist(fnm,'file')
	    nco = netcdf(fnm,'nowrite');
	    la = nco{'lat'}(:);
	    lo = nco{'lon'}(:);

	    % Only use casts with cast flag = zero

	    cflg = nco{'cast_flag'}(:);
            ii = find(cflg==0);
	    if isempty(ii)
	       isin = [];
	    else
 	       isin = ii(find(feval('isinpoly',lo(ii),la(ii),...
		         range(:,1),range(:,2))));
	    end
	
	    % Catch any rare but possible degenerate profiles

	    if ~isempty(isin) 
	       ndp = nco{'number_of_depths'}(:);
	       ii = find(ndp(isin)<1);
	       if ~isempty(ii)
		  isin(ii) = [];
	       end
	    end

	    % isin=index of wanted stations in this latest file
	    % nio=index of isin stations already read in this WMO & suffix
	    % oin=index of old stations in isin
	    % isnew=index of completely new stations in this file
	    
	    if ~isempty(isin)
	       tmp = nco{'csiro_profile_no'}(:);	       
	       [junk,oin,nio] = intersect(cpn_wmo,tmp(isin));
	       isnew = isin;
	       isnew(nio) = [];

	       cpn_wmo = [cpn_wmo; tmp(isnew)];
	       cpn = [cpn; tmp(isnew)];
	       lat = [lat; la(isnew)];
	       lon = [lon; lo(isnew)];

	       for hh = 1:nhv
		  tmp = nco{ hvarn{hvar(hh)} }(:);
		  % botdepth & pos_stat may have missing values
		  if hvar(hh)>=7
		     ii = find(tmp<=-32765);
		     tmp(ii) = repmat(nan,size(ii));
		  end		  
		  varargout{hh} = [varargout{hh}; tmp(isnew,:)];
	       end
	       
	       dep = scaleget(nco,'depth');
	       sti = nco{'start_index'}(:);
	       for iv = reqv
		  vv{iv} = scaleget(nco,varn{iv});
	       end
	       
	       % Collect extra variables for already started stations
	       for ii = 1:length(nio)
		  nn = nio(ii);
		  ipx = sti(nn):(sti(nn)+ndp(nn)-1);
		  oo = oin(ii) + np_tot;
		  [dtot,iol,ine,ovl] = feval('combine',depth{oo},dep(ipx));
		  if ovl<1
		     % New depths, so existing vars must be stretched
		     depth{oo} = dtot;
		     for iv = vars_wmo
			if varidx{iv}(oo)
			   vt = varargout{v2a(iv)}{oo};
			   varargout{v2a(iv)}{oo} = repmat(nan,size(dtot));
			   varargout{v2a(iv)}{oo}(iol) = vt;
			end
		     end
		  end
		  if ovl<2
		     % New vars must be stretched to match existing depths
		     for iv = reqv
			varidx{iv}(oo) = 1;
			varargout{v2a(iv)}{oo} = repmat(nan,size(dtot));
			varargout{v2a(iv)}{oo}(ine) = vv{iv}(ipx);
		     end
		  else
		     % New profiles have same depths as existing
		     for iv = reqv		     
			varidx{iv}(oo) = 1;
			varargout{v2a(iv)}{oo} = vv{iv}(ipx);
		     end
		  end
	       end
	       
	       
	       % Collect all new stations
	       for ii = 1:length(isnew)
		  nn = isnew(ii);
		  ipx = sti(nn):(sti(nn)+ndp(nn)-1);
		  depth{np_tot+np_wmo+ii} = dep(ipx);
		  for iv = reqv
		     varidx{iv}(np_tot+np_wmo+ii) = 1; 
		     varargout{v2a(iv)}{np_tot+np_wmo+ii} = vv{iv}(ipx);
		  end
	       end
	       
	       np_wmo = np_wmo+length(isnew);
	       vars_wmo = [vars_wmo reqv];	       
	    end                    % end of "if there is new data"
	    close(nco);
	 end                       % end of "if the file exists"
      end                          % Looping on prefices
      np_tot = np_tot + np_wmo;      
   end                             % Looping on WMOs
end                                % Looping on suffices


% Limit to depth range, if required
depi = {};
if ~isempty(dlim)
   for ip = 1:np_tot 
      depi{ip} = find(depth{ip}>=dlim(1) & depth{ip}<=dlim(2));
   end
else
   for ip = 1:np_tot 
      depi{ip} = 1:length(depth{ip});
   end
end

% Limit number of values, if required
if ~isempty(nvals)
   % Extract around a mid-depth, if required
   if ~isempty(dmid)
      for ip = 1:np_tot
	 if length(depi{ip}) > nvals
	    [tmp,sss] = sort(abs(depth{ip}(depi{ip})-dmid));
	    depi{ip} = depi{ip}(sort(sss(1:nvals)));
	 end
      end
   else
      for ip = 1:np_tot 
	 ndep = length(depi{ip});
	 if ndep > nvals
	    depi{ip} = depi{ip}(1:nvals);
	 end
      end
   end
end


if isempty(lat)
   disp('None of this type of data in this region')
   return
end

% If required, trim depth and vars 
if ~isempty(nvals) | ~isempty(dlim) 
   % Trim depths
   for ip = 1:np_tot 
      depth{ip} = depth{ip}(depi{ip});
   end
   % Trim vars, ascertaining max profile length for each data variable, and
   % cull index to any now-empty profiles
   for iv = var
      maxd(iv) = 0;
      idx = find(varidx{iv});
      for ip = idx
	 ll = length(depi{ip});
	 if ll==0
	    varidx{iv}(ip) = 0;
	 else
	    varargout{v2a(iv)}{ip} = varargout{v2a(iv)}{ip}(depi{ip});
	    if maxd(iv)<ll; maxd(iv) = ll; end
	 end
      end
   end
   clear depi
else
   for iv = var
      maxd(iv) = 0;
      for ip = find(varidx{iv})
	 maxd(iv) = max([maxd(iv) length(varargout{v2a(iv)}{ip})]);
      end
   end
end


if ara
   % Require outputs as rectangular matrices
   for iv = var
      idx = find(varidx{iv});
      dat.idx = idx;
      dat.profile = repmat(nan,[maxd(iv) length(idx)]);
      for jj = 1:length(idx)
	 dat.profile(1:length(varargout{v2a(iv)}{idx(jj)}),jj) = ...
	       varargout{v2a(iv)}{idx(jj)};
      end
      varargout{v2a(iv)} = dat;
   end
   clear dat

   deps = repmat(nan,[max(maxd) np_tot]);
   for ip = 1:np_tot
      if ~isempty(depth{ip})
	 deps(1:length(depth{ip}),ip) = depth{ip};
      end
   end   
else
   % Leave outputs as cell arrays 
   for iv = var
      varargout{v2a(iv)}.profile = varargout{v2a(iv)};
      idx = find(varidx{iv});
      varargout{v2a(iv)}.idx = idx;
   end

   deps = depth;
end

%-------------------------------------------------------------------------
