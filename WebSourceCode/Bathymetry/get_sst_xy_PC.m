% GET_SST_XY_PC  
%
%     This is no longer supported. get_sst_xy should now provide SST access 
%     for both Unix and PC systems. Please let Jeff Dunn know if there are
%     problems.
%                       12/8/03

disp('This is no longer supported. get_sst_xy should now provide SST access')
disp('for both Unix and PC systems. Please let Jeff Dunn know if there are')
disp('problems.');
return

%    Chase up the best SST data from all the disparate datasets, at
%    given locations. Use ONLY for dates prior to July 2002 - after this
%    use the CSIRO whole Au data set. See also GET_SST, which returns SST
%    dataset grid in given region.
%
% Last modified S. Bestley November 2002. Note many path changes as data
%     consolidated into \\narrows\griffin\satdata1\SST\
%
% INPUT
%  x,y  - vector or matrices of locations
%  tim  - single Unix time of required data; eg greg2time([2001 12 31 0 0 0])
%  pref - vector of dataset preferences (default [3 5 6 7 12 11 10 8 9 1])
%         1  Walker\Wilkin Pathfinder space-time OI 1989-1994
%         3  3-day comp east 1999\10\6 - July 2002
%         5  5-day comp west 2000\9\20 - July 2002
%         6  6-day comp east 1999\5\10 - July 2002
%         7  10 comp, south - 2000\8\25 - July 2002
%         8  Rathbone\Griffin east composite netcdf 15\9\1991-13\3\1999
%         9  Rathbone\Griffin west composite netcdf 6\1\1995-26\12\1999
%        10  10-day comp east 3\10\1999-July 2002
%        11  15-day comp GAB 7\12\1989-July 2002
%        12  10-day comp west 6\1\1995 - July 2002
%  opt  - vector of any of the following options (defaults in []):
%         1: 1=get from one dataset only, not topup from others [0]
%         2: 1=single timu value from first dataset used [0]
%  o_val - vector of values corresponding to the options specified above
%
% OUTPUT
%  sst  - SST at x,y locations (nan where no data available)
%  timu - actual timestamp of data (nth element is value for nth dataset, as
%         listed above - eg if only data from "3-day comp", the only non-zero
%         value will be in element 3).
%  dset - dataset used (see pref above) for each x,y
%
% See \home\dunn\SST\Notes & www.marine.csiro.au\~griffin\OISST
%
% Jeff Dunn  CSIRO CMR 5\4\02  
%  
% USAGE: [sst,timu,dset] = get_sst_xy_PC(x,y,tim,pref,opt,o_val);

function [sst,timu,dset] = get_sst_xy_PC(x,y,tim,pref,opt,o_val)

if nargin<4 | isempty(pref)
   pref = [3 5 6 12 11 10 8 9 1 ];
end
npref = length(pref);

sngl = 0;
tmu1 = 0;
if nargin<5 | isempty(opt)
   % use defaults above
elseif nargin<6 | isempty(o_val)
   warning('GET_SST_XY: Need to specify values to go with "opt" options');
else
   for ii = 1:length(opt)
      switch opt(ii)
      case 1
         sngl = o_val(ii);
      case 2
         tmu1 = o_val(ii);
      otherwise
         disp(['GET_SST_XY: Option ' num2str(opt(ii)) ' means nix to me!']);
      end
   end
end

% Create output variables and set up loop control
dset = zeros(size(x));
timu = zeros([1 max(pref)]);
sst = repmat(nan,size(x));
nval = prod(size(x));
jj = 1:nval;
req = 1;
ip = 1;

disp([num2str(size(sst))]);

% Loop through the possible datasets in order of preference

while req
   pr = pref(ip);
   
   % Get time and region limits for this dataset 
   switch pr
   case 1
      % Walker\Wilkin PF OI  14\2\1989-27\6\1994
      t1 = 31820; 
      t2 = 34510;
      gg = [90 199.95 -69.96 -.09];
   case 3
      % 3-day comp, east - 1999\10\6 - July 2002 (OK dates)
      t1 = 36319;
      t2 = inf;
      gg = [147.49 163.74 -46.00 -20.91];
   case 5
      % 5-day comp, west - 2000\9\20 - July 2002 (OK dates)
      t1 = 36787;
      t2 = inf;
      gg = [100.00 125.03 -42.03 -19.02];
   case 6
      % 6-day comp, east - 1999\5\10 - July 2002 (OK dates)
      t1 = 36436;
      t2 = inf;
      gg = [147.49 163.74 -46.00 -20.91];
   case 7
      % 10 comp, south - 2000\8\25 - July 2002 (OK dates)
      t1 = 36761;
      t2 = inf;
      gg = [108 148 -47.01 -27];
   case 8
      % Rathbone\Griffin east - 15\9\1991-13\3\1999
      t1 = 33484;
      t2 = 36230;
      gg = [147.26 156.92 -43.02 -25.32];
   case 9
      % Rathbone\Griffin west - 6\1\1995-26\12\1999
      t1 = 34703;
      t2 = 36518;
      gg = [100.02 125.04 -42.03 -19.01];
   case 10
      % 10-day comp east - 3\10\1999-July 2002 (OK dates)
      t1 = 36434;
      t2 = inf;
      gg = [147.49 163.74 -46.00 -20.91];
   case 11
      % 15-day comp GAB - 7\12\1989-July 2002 (OK dates)
      t1 = 32847;
      t2 = inf;
      gg = [110.01 159.96 -46.96 -30.01];
   case 12
      % 10-day comp west - 6\1\1995 - July 2002 (OK dates)
      t1 = 34703;
      t2 = inf;
      gg = [100.00 125.03 -42.03 -19.02];
   otherwise
      warning(['GET_SST_XY: do not understand preference ' num2str(pr)]);       
      gg = [];
   end
   
   jin = [];
   if ~isempty(gg)
      if tim>t1 & tim<t2 
         xp = gg([1 1 2 2]); yp = gg([3 4 4 3]);
         jin = jj(find(inpolygon(x(jj),y(jj),xp,yp)));
      end
   end
   
   vg = [];
   if isempty(jin)
      % not points to be found in this dataset
   elseif pr==1
      % PF OI 
      % Set up range of remaining required points, with border > grid
      % interval so that can interpolate to all points. Restrict to dataset
      % region to stop pfsst from complaining.
      rng = [min(x(jin))-.12 max(x(jin))+.12 min(y(jin))-.12 max(y(jin))+.12];
      rng([1 3]) = max([rng([1 3]); gg([1 3])]); 
      rng([2 4]) = min([rng([2 4]); gg([2 4])]); 
      [vg,glo,gla,timug] = pfsst_PC(rng,time2greg(tim));
      timu(pr) = timug-julian([1900 1 1 0 0 0]);
      
   elseif (pr>=3 & pr<=7) | pr>=10
      % disimp files
      if pr==3
         dnm = '\\narrows\griffin\satdata1\SST\comp3d\east\lldisimp\'; 
      elseif pr==5
         dnm = '\\narrows\griffin\satdata1\SST\comp5d\west\lldisimp\';
      elseif pr==6
         dnm = '\\narrows\griffin\satdata1\SST\comp6d\east\lldisimp\';
      elseif pr==7
         dnm = '\\narrows\griffin\satdata1\SST\comp10d\south\lldisimp\';
      elseif pr==10
         dnm = '\\narrows\griffin\satdata1\SST\comp10d\east\lldisimp\';
      elseif pr==11
         dnm = '\\narrows\griffin\satdata1\SST\comp15d\GAB\lldisimp\';
      elseif pr==12
         dnm = '\\narrows\griffin\satdata1\SST\comp10d\west\lldisimp\';
      end
      
      % Get a directory listing; decode filenames to times; find nearest time
      dirl = dir([dnm '*.dat']);
      if ~isempty(dirl)
         ftim = zeros([1 length(dirl)]);
         for ii = 1:length(dirl)
	    if dirl(ii).bytes > 0
	       yr = str2num(dirl(ii).name(1:4));
	       mo = str2num(dirl(ii).name(5:6));
	       da = str2num(dirl(ii).name(7:8));
	       ftim(ii) = greg2time([yr mo da 0 0 0]);
	    else
	       ftim(ii) = nan;
	    end
         end
         [dum,itm] = min(abs(ftim-tim));
         
	 if isnan(dum)
	    % no good files
	    vg = [];
	 else
	    fnm = [dnm dirl(itm).name];
	    timu(pr) = ftim(itm);	 
	    [vg,glo,gla] = get_disimp(fnm,0,1e8);
	 end
      end
      
   elseif pr==8 | pr==9
      % netCDF composite files
      if pr==8
         fnm = '\\narrows\griffin\satdata1\SST\comp15deast'; 
      else
         fnm = '\\narrows\griffin\satdata1\SST\comp10d\sst_west'; 
      end
      t0 = greg2time([1990 1 1 0 0 0]);
      stim = getnc(fnm,'time')+t0;
      [dum,itm] = min(abs(stim-tim));
      timu(pr) = stim(itm);
      gla = getnc(fnm,'lat');
      glo = getnc(fnm,'lon');
      vg = getnc(fnm,'sst',[itm -1 -1],[itm 1 1]);
   end
   
   % Have some gridded data, so interpolate to our locations and set dset 
   % appropriately where data is obtained at our locations.
   if ~isempty(vg)
      sst(jin) = interp2(glo,gla,vg,x(jin),y(jin));
      dset(jin) = ~isnan(sst(jin)).*pr;      
   end
   
   % Find what locations still need filling, and test whether to continue
   jj = find(isnan(sst));
   req = ~isempty(jj) & ip<length(pref) & ~(sngl & any(~isnan(sst(:))));
   ip = ip+1;
end

% If require only first timestamp, then organise it.
if tmu1
   ii = find(timu);
   if isempty(ii)
      timu = 0;
   else
      timu = timu(ii(1));
   end
end

%---------------------------------------------------------------------------
