% GET_SST_XY  Get SST at given locations and for a single time, from any of 
%    the local datasets. The nearest time estimate is returned, except for 
%    dataset 22 where we interpolate to the specified time.
%
% A reorganisation around 20/7/02 lead to many datasets being terminated,
% and the full Aus Region ("Au") ones commencing at 3, 6, and 10 day windows
% in /home/satdata1/SST/. All composite data was then available in disimp,
% single-date netcdf, and 3D netcdf files. In May 2004 the NOO-funded
% "Decade of SST" project produced 1,2,3,10 and 15-day window AVHRR composites 
% of the Australasian region in netCDF year files. However, many of the
% previous datasets have been retained as they extend beyond the Decade, or 
% have unique characteristics.
%
% Note that this code is very slow - it spends most time working out which 
% file to open next, so especially if a time series is required, manually
% accessing the 3D netcdf files is much quicker. 
%
% INPUT
%  x,y  - vector or matrices of locations
%  tim  - single Unix time of required data; eg greg2time([2001 12 31 0 0 0])
%  pref - vector of dataset preferences (default [18 22 13 16 17 1])
%         1  Walker/Wilkin Pathfinder space-time 9km 10day OI
%         2  Walker/Wilkin ACRES Pathfinder space-time OI 5km 10day OI
%         3  [ DEFUNCT ]  3-day comp east
%         5  [ DEFUNCT ]  5-day comp west
%         6  [ DEFUNCT ]  6-day comp east
%         7  [ DEFUNCT ]  10-day comp southern 
%         8  Rathbone/Griffin east composite
%         9  [ DEFUNCT ]  Rathbone/Griffin west composite
%        10  [ DEFUNCT ]  10-day comp east
%        11  15-day comp GAB
%        12  [ DEFUNCT ]  10-day comp west 
%        13  10-day comp full Aus  20/7/02 ->
%        14  6-day comp  full Aus  11/7/02 ->
%        15  3-day comp  full Aus  19/7/02 ->
%        16  3-day ave AMSR SSMI Microwave, Global 1/6/02 ->
%        17  7-day ave AMSR SSMI Microwave, Global 1/6/02 ->
%        18  1-day 2004 AVHRR NOO Stitched 1-day spaced 1/10/93-6/6/03
%        19  3-day 2004 AVHRR NOO Stitched 1-day spaced 1/10/93-6/6/03
%        20  6-day 2004 AVHRR NOO Stitched 1-day spaced 1/10/93-6/6/03
%        21  10-day 2004 AVHRR NOO Stitched 2-day spaced 1/10/93-6/6/03
%        22  15-day 2004 AVHRR NOO Stitched 6-day spaced 1/10/93-6/6/03
%        23  3-day AVHRR "Aasia" NRT 20/10/04 ->
%        24  6-day AVHRR "Aasia" NRT 19/10/04 ->
%        25  10-day AVHRR "Aasia" NRT 17/10/04 ->
%        26  15-day AVHRR "Aasia" NRT   [not available?]
%        27  20-day AVHRR "Aasia" NRT   [not available?]
%        28  6-day "Patchwork" V7  1/6th degree 15/6/92-17/8/2004
%        29  6-day "Patchwork" V8  1/6th degree 17/8/2004-26/4/2005
%        30  6-day Reynolds V7  1 degree 15/6/92-17/8/2004
%        31  6-day Reynolds V8  1 degree 17/8/2004-26/4/2005
%
%  opt  - vector of any of the following options (defaults in []):
%         1: 1=get from one dataset only, not topup from others [0]
%         2: 1=single timu value from first dataset used [0]
%  o_val - vector of values corresponding to the options specified above
%
% OUTPUT
%  sst  - SST at x,y locations (nan where no data available)
%  timu - timestamp of data used (nth element is value for nth dataset, as
%         listed above - eg if only data from "3-day comp", the only non-zero
%         value will be in element 3). Note that this refers to centre of
%         time window.
%  dset - dataset used (see pref above) for each x,y
%
% SEE ALSO:   get_sst_xyt.m   get_sst.m
%
% SEE http://www.marine.csiro.au/eez_data/doc/sst_datasets.html
%
% Jeff Dunn  CSIRO CMR 5/4/02 -
% 
%          Now access netCDF rather than disimp daily files       28/2/03
%          Access to ACRES Pathfinder 5km 10day OI                4/3/03
%          Added Global 3-day & 7-day SSMI (AMSR) microwave SST    8/8/03
%          Access to 2004 Stitched Archive composites             10/6/04
%          Access to AVHRR NRT composites                         18/7/05
% **NEW**  Patchwork V8 and Reynolds V7,V8.                       1/8/06
%
% USAGE: [sst,timu,dset] = get_sst_xy(x,y,tim,pref,opt,o_val);

function [sst,timu,dset] = get_sst_xy(x,y,tim,pref,opt,o_val)

% Number of underscores in filename before start of date string (for each
% data stream)
ndsh = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 0 0 0 0 0 1 1 1 1 1 0];

% Days to subtract from file date to get analysis or window centre date
% (for each data stream.)  [So far, have only considered this for 16 & 17]
toff = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 .5 2.5 0 0 0 0 0 0 0 0 0 0 0];

if nargin<4 | isempty(pref)
   % pref = [13 16 17 14 3 5 6 7 12 11 10 8 9 2 1];
   pref = [18 22 13 16 17 1];
end
npref = length(pref);

% What sort of computer are we running on?
cname = computer;
if strncmp(cname,'PC',2)
   pth = '\\rsc-hf\satdata1\SST\';
   pth2 = '\\reg-hf\reg2\SST_mw\netcdf\';
   pth3 = '\\rsj-hf\imgjj\sensor\avhrr\sstcr04\yearfiles\';
   pth4 = '\\rsj-hf\imgjj\sensor\avhrr\sstcr04nrt\';
   pth5 = '\\reg-hf\reg2\SST_model\';   
   slsh = '\';
elseif strncmp(cname,'MAC',3)
   disp([7 'Sorry - do not how to find datafiles from a Mac'])
   return
else
   % Assuming not a VAX, must be Unix
   pth = '/home/satdata1/SST/';
   pth2 = '/home/reg2/SST_mw/netcdf/';
   pth3 = '/home/imgjj/sensor/avhrr/sstcr04/yearfiles/';
   pth4 = '/home/imgjj/sensor/avhrr/sstcr04nrt/';
   pth5 = '/home/reg2/SST_model/';
   slsh = '/';
end
   
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


% Loop through the possible datasets in order of preference

while req
   pr = pref(ip);
   
   t0 = greg2time([1970 1 1 0 0 0]);
   
   % Get time and region limits for this dataset 
   switch pr
     case 1
       % Walker/Wilkin PF 9km 10-day OI  14/2/1989-27/6/1994
       t1 = 31820; 
       t2 = 34510;
       gg = [90 199.95 -69.96 -.09];
     case 2
       % Walker/Wilkin PF 10-day OI ACRES 5km 18/3/1991-3/8/1997
       t1 = 33313;
       t2 = 35643;
       gg = [106.80 160.16 -44.94 -3.95];
       fnm = [pth 'oi5k10dsst1'];
       t0 = greg2time([1990 1 1 0 0 0]);
     case 8
       % Rathbone/Griffin east - 15/9/1991-13/3/1999
       t1 = 33484;
       t2 = 36230;
       gg = [147.26 156.92 -43.02 -25.32];
       fnm = [pth 'comp15deast'];
       t0 = greg2time([1990 1 1 0 0 0]);
     case 11
       % 15-day comp GAB - 7/12/1989-17/7/02
       t1 = 32847;
       t2 = 37452;
       gg = [110.01 159.96 -46.96 -30.01];
       dnm = [pth 'comp15d' slsh 'GAB' slsh 'nc' slsh];
     case 13
       % 10-day comp Aus - 20/7/02 - present
       t1 = 37455;
       t2 = inf;
       gg = [100.00 171.42 -47.03 -0.018];
       dnm = [pth 'comp10d' slsh 'Au' slsh 'nc' slsh];
     case 14
       % 6-day comp Aus - 11/7/02 - present
       t1 = 37446;
       t2 = inf;
       gg = [100.00 171.42 -47.03 -0.018];
       dnm = [pth 'comp6d' slsh 'Au' slsh 'nc' slsh];
     case 15
       % 3-day comp Aus - 19/7/02 - present
       t1 = 37454;
       t2 = inf;
       gg = [100.00 171.42 -47.03 -0.018];
       dnm = [pth 'comp3d' slsh 'Au' slsh 'nc' slsh];
     case 16
       % 3-day ave SSMI Microwave;  Global - 1/6/02 - present
       % Note: filename dates are END of 3 day averaging period
       t1 = 37406;
       t2 = inf;
       gg = [0 360 -90 90];
       dnm = [pth2 '3_day' slsh 'all' slsh];
     case 17
       % 7-day ave SSMI Microwave;  Global - 1/6/02 - present
       % Note: filename dates are END of 7 day averaging period
       t1 = 37406;
       t2 = inf;
       gg = [0 360 -90 90];
       dnm = [pth2 'weekly' slsh];

     case {18,19,20,21,22}     
       % NOO-funded 2004 stitched archive. Australiasia, 1/10/93-6/6/03
       itper = pr-17;
       t1 = t0 + [8674.5 8675.5 8677 8680 8681.5];
       t1 = t1(itper);
       t2 = t0 + [12216.5 12215.5 12214 12212 12209.5];
       t2 = t2(itper);
       tper = [1 3 6 10 15];
       tper = tper(itper);       
       gg = [79.987 190.03 -64.998 10.026];
       fnm = [pth3 'SSTcomp' num2str(tper) 'd_Aasia_'];
              
     case {23,24,25}     
       % Australiasia, NRT, lon .042, lat .036 deg, 0ct 2004 ->
       itper = pr-22;
       t1 = t0 + [12711 12710 12708];
       t1 = t1(itper);
       t2 = inf;
       tper = [3 6 10];
       tper = tper(itper);       
       gg = [79.987 190.03 -64.998 10.026];
       dnm = [pth4 'comp' num2str(tper) 'd' slsh 'Aasia' slsh];
     
     case {26,27}     
       % Australiasia, NRT, 0ct 2004 ->
       disp(['*** GET_SST_XY: Dataset ' num2str(pr) ' not yet generated']);       
       gg = [];       
     
     case 28
       % "Patchwork" V7. Australiasia, 1/6th degree lat and lon, 6 day space.
       t1 = 33768;
       t2 = 38214;
       gg = [84.916 185.083 -75.084 25.083];
       fnm = [pth5 'high_res_6_day_V7'];
       t0 = greg2time([1990 1 1 0 0 0]);
              
     case 29
       % "Patchwork" V8. Australiasia, 1/6th degree lat and lon, 6 day space.
       t1 = 38214;
       t2 = 38466;
       gg = [84.916 185.083 -75.084 25.083];
       fnm = [pth5 'high_res_6_day_V8'];
       t0 = greg2time([1990 1 1 0 0 0]);
              
     case 30
       %  Reynolds V7. Global, 1 degree lat and lon, 6 day space.
       t1 = 33768;
       t2 = 38214;
       gg = [84.916 185.083 -75.084 25.083];
       fnm = [pth5 'Reynolds_6_day_V7'];
       t0 = greg2time([1990 1 1 0 0 0]);
              
     case 31
       %  Reynolds V8 Global, 1 degree lat and lon, 6 day space.
       t1 = 38214;
       t2 = 38466;
       gg = [84.916 185.083 -75.084 25.083];
       fnm = [pth5 'Reynolds_6_day_V7'];
       t0 = greg2time([1990 1 1 0 0 0]);
              
     case {3,4,5,6,7,9,10,12}
       warning(['GET_SST_XY no longer accesses dataset ' num2str(pr)]);       
       gg = [];       
       
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
      % PF OI 8km
      % Set up range of remaining required points, with border > grid
      % interval so that can interpolate to all points. Restrict to dataset
      % region to stop pfsst from complaining.
      rng = [min(x(jin))-.12 max(x(jin))+.12 min(y(jin))-.12 max(y(jin))+.12];
      rng([1 3]) = max([rng([1 3]); gg([1 3])]); 
      rng([2 4]) = min([rng([2 4]); gg([2 4])]); 
      [vg,glo,gla,timug] = pfsst(rng,time2greg(tim));
      timu(pr) = timug-julian([1900 1 1 0 0 0]);
   
   elseif any([3 5 6 7 10 11 12 13 14 15 16 17 23 24 25]==pr)
      % Daily composite netCDF files (previously accessed disimp versions)      
      % Get a directory listing; decode filenames to times; find nearest time
      dirl = dir([dnm '*.nc']);
      if ~isempty(dirl)	 
	 ftim = zeros([1 length(dirl)]);
	 idsh = findstr(dirl(1).name,'_');
	 if length(idsh) ~= ndsh(pr)
	    disp([7 'Problem with filenames in ' dnm]);
	    dum = nan;
	 else
	    idsh = idsh(ndsh(pr));
	    for ii = 1:length(dirl)
	       if dirl(ii).bytes > 0
		  yr = str2num(dirl(ii).name(idsh+(1:4)));
		  mo = str2num(dirl(ii).name(idsh+(5:6)));
		  da = str2num(dirl(ii).name(idsh+(7:8)));
		  ftim(ii) = greg2time([yr mo da 0 0 0]) - toff(pr);
	       else
		  ftim(ii) = nan;
	       end
	    end
	    [dum,itm] = min(abs(ftim-tim));
	 end
	 
	 if isnan(dum)
	    % no good files
	    vg = [];
	 else
	    fnm = [dnm dirl(itm).name];
	    if pr>12
	       tmp = getnc(fnm,'time');
	       if ~isempty(tmp)
		  timu(pr) = tmp+t0 ;
	       end
	    else
	       timu(pr) = ftim(itm);	 
	    end
	    gla = getnc(fnm,'lat');
	    glo = getnc(fnm,'lon');
	    vg = getnc(fnm,'sst',[1 -1 -1],[1 1 1]);
	 end
      end
      
   elseif pr==2 | pr==8 | pr==9
      % netCDF timeseries composite files
      stim = getnc(fnm,'time')+t0;
      [dum,itm] = min(abs(stim-tim));
      timu(pr) = stim(itm);
      gla = getnc(fnm,'lat');
      glo = getnc(fnm,'lon');
      vg = getnc(fnm,'sst',[itm -1 -1],[itm 1 1]);
   
   
   elseif any([18 19 20 21]==pr)
      % Yearly netCDF files
      greg = time2greg(tim);
      fnm = [fnm num2str(greg(1))];
      stim = getnc(fnm,'time')+t0;
      [dum,itm] = min(abs(stim-tim));
      timu(pr) = stim(itm);      
      gla = getnc(fnm,'lat');
      glo = getnc(fnm,'lon');
      ix1 = sum(glo<min(x(jin)));
      ix2 = length(glo)+1 - sum(glo>max(x(jin)));
      iy1 = sum(gla>max(y(jin)));
      iy2 = length(gla)+1 - sum(gla<min(y(jin)));
      glo = glo(ix1:ix2);
      gla = gla(iy1:iy2);
      vg = getnc(fnm,'sst',[itm iy1 ix1],[itm iy2 ix2]);
            
   elseif pr==22
      % Yearly netCDF files with 15-day window, 6-day spacing, so interpolate
      % in time before interp in space.
      % Yearly netCDF files
      greg = time2greg(tim);
      stim = getnc([fnm num2str(greg(1))],'time')+t0;
      nn = length(stim);

      gla = getnc([fnm num2str(greg(1))],'lat');
      glo = getnc([fnm num2str(greg(1))],'lon');      
      ix1 = sum(glo<min(x(jin)));
      ix2 = length(glo)+1 - sum(glo>max(x(jin)));
      iy1 = sum(gla>max(y(jin)));
      iy2 = length(gla)+1 - sum(gla<min(y(jin)));
      glo = glo(ix1:ix2);
      gla = gla(iy1:iy2);

      if tim<stim(1)
	 st2 = stim(1);
	 stim = getnc([fnm num2str(greg(1)-1)],'time')+t0;
	 nn = length(stim);
	 st1 = stim(nn);
	 vg = getnc([fnm num2str(greg(1)-1)],'sst',[nn iy1 ix1],...
				  [nn iy2 ix2]);
	 vg = cat(3,vg,getnc([fnm num2str(greg(1))],'sst',[1 iy1 ix1],...
					   [1 iy2 ix2]));
      elseif tim>stim(nn)
	 st1 = stim(nn);
	 stim = getnc([fnm num2str(greg(1)-1)],'time')+t0;
	 st2 = stim(1);
	 vg = getnc([fnm num2str(greg(1))],'sst',[nn iy1 ix1],[nn iy2 ix2]);
	 vg = cat(3,vg,getnc([fnm num2str(greg(1)+1)],'sst',[1 iy1 ix1],...
					   [1 iy2 ix2]));
      else
	 it1 = find(stim<tim);
	 it1 = it1(end);
	 st1 = stim(it1);
	 st2 = stim(it1+1);	 
	 vg = getnc([fnm num2str(greg(1))],'sst',[it1 iy1 ix1],...
				  [it1+1 iy2 ix2]);
      end
      timu(pr) = tim;  

      trat = (tim-st1)/(st2-st1);
      vg = sq(vg(1,:,:)) + (trat.*sq(vg(2,:,:)-vg(1,:,:)));
   
   elseif any([28 29 30 31]==pr)
      % Single netCDF file with 6-day spacing, so interpolate in time
      stim = getnc(fnm,'time')+t0;
      nn = length(stim);

      gla = getnc(fnm,'latitude');
      glo = getnc(fnm,'longitude');      
      ix1 = sum(glo<min(x(jin)));
      ix2 = length(glo)+1 - sum(glo>max(x(jin)));
      iy1 = sum(gla<min(y(jin)));
      iy2 = length(gla)+1 - sum(gla>max(y(jin)));
      glo = glo(ix1:ix2);
      gla = gla(iy1:iy2);

      it1 = find(stim<tim);
      it1 = it1(end);
      vg = getnc(fnm,'sst',[it1 iy1 ix1],[it1+1 iy2 ix2]);

      stm = stim([it1 it1+1]);
      trat = (tim-stm(1))/diff(stm);
      vg = sq(vg(1,:,:)) + (trat.*sq(vg(2,:,:)-vg(1,:,:)));

      timu(pr) = tim;  
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
