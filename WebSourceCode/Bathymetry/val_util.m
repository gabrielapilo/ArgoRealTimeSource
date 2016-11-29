% VAL_UTIL: Utility functions supporting "validate.m" GUI. 
%
%  Copyright     Jeff Dunn, CSIRO Marine Research, 3/3/2003
%
% Functions in this file:
%  val_util      wfbp                 fill_mld_flds               
%  setlimflds	 plot_cast            mixld
%  getlimflds	 plot_dmap
%  rectreg	 plot_scat
%  get_reg	 sclev_load           
%  byenow	 fill_axes_boxes
%  interpJD	 goto_curfig    
%
% WARNING: This code uses many globals, and clears those globals when exiting.

% $Id: val_util.m,v 1.3 2003/03/17 01:42:00 dun216 Exp dun216 $
% 

function val_util(action)

% This function contains the callbacks from the GUI, in the following order:
%  'init'             'auto_ylim'      'init4'         'initmld'  
%  'get_file'         'fix_xlim'       'd_dep'         'mld_dset' 
%  'set_property'     'fix_ylim'       'd_lev'         'mld_t'    
%  'reset_reg'	      'set_curfig'     'set_rng'       'mld_s'    
%  'select_reg'	      'print_plot'     'finish4'       'mld_sigdz'
%  'ew_region'         --              'init5'         'mld_sig'  
%  'ns_region'	      'finish'         '5_dep'         'mld_meth' 
%  'save_to_file'     'init2'          '5_lev'         'calcmld'  
%  'st_date'	      'next_cast'      'finish5'       'finishmld'
%  'end_date'	      'num_cast'        --
%  'load_reg'	      'sel_cast'        --
%  'auto_xlim'	      'finish2'         --

% Note: ndat is number of casts, but only where a simple property is
% selected. If a derived property is used (ie MLD) then ndat is set to 0
% as a flag that cast profiles cannot be plotted. If it doesn't matter 
% whether it is a simple or derived property, then we test isempty(lat),
% since lat & lon are used for both types of property. 

global alert guih defafs deftfs Vdeph Vlevh
global figs maph curh seeh timh tmh tloch loch regh proh 
global fvars labels ftyps unitl curprp mldmeth dsetnm
% model: time, time range, depths, num deps, lat, lon
global tm mtrng zm nz la lo
% cast data details
global nxt inlst ndat seen lon lat tim cpn ftyp ndat 
% data:  vc: cast, vmc: model interp to cast locs, vcm: cast interp to zm
%        cdif: vmc-vcm
global vc vmc vcm cdif
% depths: cast depths, max cast dep, model depth & level range of cast data 
global deps mxd zrng lrng
global trng mapax 
global defax Vxlim Vylim Vlev maplev curfig
global mldm mldc mldh
global tdmax rmax just1

persistent asc_save ncf fpth fnames plot_names nfiles fulsrc src Drng
persistent nx ny tmf flrng mldopt curset mldthr vars nxtprp
persistent Tc Sc bdep timm Tm Sm intS intT

nfg = 7; 
plot_names = {'Cast profile','Diff map','Scatter plot','Stat profile',...
	      'rms err prof'};
% relate plot_names to curfig, which indexes into figs and corresponding guih
plist_fig = [2 4 5 6 7];
fig_plist = [0 1 0 2 3 4 5];
ftyps = {'WOD98 CTD','WOD98 CTD2','WOD98 BOT','WOD98 BOT2','WOD98 XBT',...
	 'WOD98 XBT2','CSIRO','','NIWA'};
vars = {'temp','salt','Oxygen','Si02','DIP','NO3',''};
fvars = {'temperature','salt','oxygen','silicate','phosphate',...
	 'nitrate','ML_depth'};
labels = {'temperature','salt','oxygen','silicate','phosphate',...
	 'nitrate','mixed layer depth'};
unitl = {' (^oC)',' (PSU)',' (mg/m^3)',' (\muM)',' (mg/m^3)',' (mg/m^3)',' m'};
% Convert casts to model units
untsc = [1 1 (1/.00143) 1 30.97 14];
mldmeth = {'del T  only','del S  only','dSig/dz  only','n/a','max of ests',...
	   'min of ests','mean of ests','median of ests'};
dsetnm = {'Model','Observations'};

set(alert,'String','');


switch(action)

  case 'init'

    % For ease of testing:  % fpth = '/home/mgs/nws/annual/';
        
    nfiles = 0;
    ncf = [];
    mldh = [];
    guih{nfg} = [];
    Vxlim{nfg} = [];
    Vylim{nfg} = [];
    defax = ones(nfg,4);
    
    figs{nfg} = [];
    figs{7} = figure;
    set(gcf,'Name',['RMS err profile ' num2str(figs{7})],'NumberTitle','off');
    figs{6} = figure;
    set(gcf,'Name',['Stats profile ' num2str(figs{6})],'NumberTitle','off');
    figs{3} = figure;
    set(gcf,'Name',['List of Stats ' num2str(figs{3})],'NumberTitle','off');
    figs{2} = figure;
    proh = axes('position',[.13 .1 .85 .81]);
    set(gcf,'Name',['Casts ' num2str(figs{2})],'NumberTitle','off');
    figs{1} = figure;
    set(gcf,'Name',['Model domain ' num2str(figs{1})],'NumberTitle','off');
    
    curset = 1;
    mldopt = [5 5];
    mldthr = [.4 .03 .003 .06; .4 .03 .003 .06];
    lat = [];
    Tm = [];
    loch = [];
    regh = [];
    curh = [];
    curprp = 1;
    ndat = 0;
    cdif = [];
    asc_save = 0;
    Vlev = [1 1 1];
    curfig = plist_fig(1);
    tmh = [];

    set(findobj('Tag','plot_names'),'String',plot_names);
    set(findobj('Tag','set_prop'),'String',fvars);

    
  case 'get_file'    
    if ~isempty(fpth)
       [tmpn,tmpp] = uigetfile('*.nc','Model file name',[fpth '*.nc']);
    else
       [tmpn,tmpp] = uigetfile('*.nc','Model file name');
    end
    if ~isequal(tmpn,0)
       tmpn = [tmpp tmpn];
       ncf = netcdf(tmpn,'nowrite');
    end
    if isempty(ncf)
       warndlg(['Cannot open file ' tmpn]);
    else
       zm2 = -ncf{'zc'}(:);
       if isempty(zm2)
	  zm2 = -ncf{'z'}(:);
       end
       if isempty(zm2)
	  zm2 = -ncf{'z_centre'}(:);
       end
       if isempty(zm2)
	  set(alert,'String','Cannot use this file - no z variable');
	  ncf = close(ncf);
       end
    end
    if ~isempty(ncf)
       la = ncf{'latitude'}(:);
       lo = ncf{'longitude'}(:);
       if isempty(la)
	  la = ncf{'y'}(:);
	  lo = ncf{'x'}(:);
       end
       if isempty(la)
	  la = ncf{'y_centre'}(:);
	  lo = ncf{'x_centre'}(:);
       end
       if isempty(la)
	  set(alert,'String','Cannot use this file - no x variable');
	  ncf = close(ncf);
       end
    end
    if ~isempty(ncf) & nfiles>0
       % Check that new file matches previous ones 
       [iy,ix] = size(la);
       if iy~=ny | ix~=nx | length(zm2)~=nz
	  set(alert,'String','Dimensions in this file do not match others');
	  ncf = close(ncf);
       end
    end
    if ~isempty(ncf)
       fpth = tmpp;
       nfiles= nfiles+1;
       fnames{nfiles} = tmpn;

       % Get model time and convert to 1900 base year. Go tmxt days 
       % outside model time range.
       tmxt = 0;
       tm2 = ncf{'time'}(:);
       if isempty(tm2)
	  tm2 = ncf{'t'}(:);
       end
       tof = greg2time([1990 1 1 0 0 0]);
       tm2 = tm2+tof;
       
       if nfiles==1
	  [ny,nx] = size(la);
	  zm = zm2(:)';
	  nz = length(zm);
	  mxd = ceil(dep_csl(max(zm),2));
	  deps = csl_dep(1:mxd,2);

	  % Construct a polygon from perimeter coords
	  nys = ceil(ny/8);
	  nxs = ceil(nx/8);
	  ix = 1:nxs:nx;
	  if ix(end) ~= nx
	     ix = [ix nx];
	  end
	  iy = nys:nys:ny;
	  xs = [lo(1,ix)'; lo(iy,nx); lo(ny,fliplr(ix))'; lo(fliplr(iy),1)]; 
	  ys = [la(1,ix)'; la(iy,nx); la(ny,fliplr(ix))'; la(fliplr(iy),1)]; 
	  fulsrc = [xs ys];
	  src = fulsrc;
	  setlimflds(src);    

	  % Plot model grid and cast locations, and same for time domain.
	  loch = [];
	  curh = [];
	  regh = [];
	  timh = [];
	  figure(figs{1})
	  clf
	  maph = subplot('position',[.06 .3 .9 .6]);
	  plot(lo,la,'k.','markersize',2);
	  hold on;
	  mapax = axis;
	  gebco
	  title({'MODEL GRID and CAST LOCATIONS MAP',...
		 '(mouse buttons can be used to zoom in this figure)'})
	  zoom on;
       end

       tmf{nfiles} = tm2;
       tm = [];
       ifil = [];
       indx = [];
       for ii = 1:nfiles
	  tm = [tm; tmf{ii}(:)];
	  ifil = [ifil; repmat(ii,[length(tmf{ii}) 1])];
	  indx = [indx; (1:length(tmf{ii}))'];
       end
       % If any duplicated timesteps (presumably from different files) then
       % separate these by a small arbitrary amount, to avoid problems in
       % interpolating.
       [tm,itm] = sort(tm);
       ifil = ifil(itm);
       indx = indx(itm);
       if any(diff(tm)==0)
	  lstm = tm(1);
	  nrep = 0;
	  for ii = 2:length(tm)
	     if tm(ii)==lstm
		nrep = nrep+1;
		tm(ii) = tm(ii)+nrep*.1;
		tmf{ifil(ii)}(indx(ii)) = tm(ii);
	     else
		nrep = 0;
		lstm = tm(ii);
	     end
	  end
       end

       mtrng = [tm(1)-tdmax tm(end)+tdmax];
       trng = mtrng;
       tmp = time2greg(trng(1));
       set(findobj('Tag','st_date'),'String',num2str(tmp(1:3)));    
       tmp = time2greg(trng(2));
       set(findobj('Tag','end_date'),'String',num2str(tmp(1:3)));    

       set(findobj('Tag','filenames'),'String',fnames);
       ncf = close(ncf);
          
       figure(figs{1})
       if ishandle(timh)
	  axes(timh);
	  hold off;
       else
	  timh = subplot('position',[.06 .08 .9 .12]);
       end
       tmh = [];
       tloch = [];
       plot(tm/365,.7,'k+');
       hold on;
       title('Model and casts: temporal distribution')
       axis([trng/365 -.2 1.2])
       set(gca,'ytick',[]);
       xlabel('Year')

       Tm = [];
       lat = [];
       ndat = 0;
       cdif = [];
       set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);
       set(findobj('Tag','get_file'),'BackgroundColor',[.7 .7 .7]);
       set(alert,'String','Comparison region will default to entire model domain')
    end
    
  case 'set_property'
    nxtprp = get(findobj('Tag','set_prop'),'Value');
    % set curprp = nxtprp when load region, rather than now, so that no
    % chance of associating previous data with new property name.    
    set(alert,'String','Property change will take effect when "Load region"');    
    set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);

  case 'reset_reg'
    src = fulsrc;
    setlimflds(src);
    set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);
    
  case 'select_reg'
    astr='Draw rubber band box on map (click and drag mouse), then WAIT';
    set(alert,'String',astr);
    src = get_reg(figs{1});   
    setlimflds(src);    
    set(alert,'String','');
    set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);

  case 'ew_region'
    src = getlimflds;
    set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);
    
  case 'ns_region'
    src = getlimflds;
    set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);

  case 'save_to_file'
    if ndat==0
       warndlg('Cannot save casts because there are none!')
    else
       outfl = [vars{curprp} '_casts'];
       prom = {'Type of file: m=mat-file a=ASCII:','Name for file:'};
       def = {'m',outfl};
       answ = inputdlg(prom,'Save casts to file',1,def);
       outfl = answ{2};
    
       if strncmp(answ{1},'m',1);
	  save(outfl,'lon','lat','tim','cpn','ftyp','vc','deps','vmc'); 
       else
	  % Save to ASCII file
	  asc_save = 1;
	  fid = fopen(outfl,'w');
	  for ii = 1:ndat
	     ctim = time2greg(tim(ii));
	     fprintf(fid,'%5d%10d%8.3f%8.3f%3d  %2d/%0.2d/%4d %0.2d:%0.2d\n',...
		     ii,cpn(ii),lon(ii),lat(ii),ftyp(ii),ctim([3 2 1 4 5]));
	     ll = find(~isnan(vc(ii,:)));
	     fprintf(fid,'%4d %10.3f %10.3f\n',[deps(ll); vc(ii,ll); vmc(ii,ll)]);
	  end
	  fclose(fid);
       end
    end
        
  case 'st_date'
    tmp = str2num(get(findobj('Tag','st_date'),'String'));    
    if isempty(tmp)
       trng(1) = mtrng(1);
    elseif length(tmp)~=3
       set(alert,'String','Specify start date as y m d; eg 2003 12 31');
    else
       trng(1) = greg2time([tmp 0 0 0]);
       set(alert,'String','To apply start time, select "Load region"');
       set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);
    end
    
  case 'end_date'
    tmp = str2num(get(findobj('Tag','end_date'),'String'));
    if isempty(tmp)
       trng(2) = mtrng(2);
    elseif length(tmp)~=3
       set(alert,'String','Specify end date as y m d; eg 2003 12 31');
    else
       trng(2) = greg2time([tmp 0 0 0]);
       set(alert,'String','To apply end time, select "Load region"');
       set(findobj('Tag','load_region'),'BackgroundColor',[1 0 0]);
    end
    
  case 'load_reg'
    if nfiles==0
       set(alert,'String','Load the model files first!')
       return
    end
       
    curprp = nxtprp;
    if curprp~=7 & ishandle(mldh)
       % Geet rid of MLD calulation menu, so it cannot interfere with the
       % dataset we are about to load.
       close(mldh);
       mldh = [];
    end
       
    cdif = [];
    ndat = 0;
    lat = [];
    
    set(gcbf,'Pointer','watch');
    set(alert,'String',['Extracting ' fvars{curprp} ' fields & casts'])

    Drng = [];
    figure(figs{7})
    clf
    figure(figs{6})
    clf
    figure(figs{3})
    clf

    figure(figs{1})
    axes(timh);
    if ~isempty(tloch); delete(tloch); tloch = []; end
    axes(maph);
    if ~isempty(loch); delete(loch); loch = []; end
    if ~isempty(curh); delete(curh); curh = []; end

    if ~isempty(regh); delete(regh); end
    regh = plot(src([1:end 1],1),src([1:end 1],2),'k--');

    if curprp<7
       % Normal property
       % Extract data from model files (those that have this datatype)
       vv = [];
       tm = [];
       for ii=1:nfiles
	  ncf = netcdf(fnames{ii},'nowrite');
	  tmp = ncf{vars{curprp}}(:);
	  if isempty(tmp)
	     disp(['No ' vars{curprp} ' in ' fnames{ii}])
	  else
	     vv = cat(1,vv,tmp);
	     tm = [tm; tmf{ii}(:)];
	  end
       end       
       if isempty(vv)       
	  disp(['No ' vars{curprp} ' model fields'])
	  ndat = 0;
       else
	  % Reorder the records chronologically
	  [tm,itm] = sort(tm);
	  vv = vv(itm,:,:,:);	     
	  
	  if curprp==1
	     ftyp = [1:5 7 9];
	  elseif curprp==2
	     ftyp = [1:4 7 9];      
	  else
	     ftyp = [3 4 7 9];
	  end
	  [lat,lon,cpn,tim,ftyp,vc] = get_all_csl(src,[1 2 9],curprp,ftyp,[1:mxd]);
	  ndat = length(lat);
       end
       
       if ndat==0
	  disp(['No ' vars{curprp} ' casts found in region'])
       else
	  tin = find(tim>trng(1) & tim<trng(2)); 
	  ndat = length(tin);
	  lat = lat(tin);
	  lon = lon(tin);
	  cpn = cpn(tin);
	  tim = tim(tin);
	  ftyp = ftyp(tin);
	  vc = vc(tin,:).*untsc(curprp);
	  disp([num2str(ndat) ' ' vars{curprp} ' casts found in time & space domain'])
       end
       
       tmph = findobj('Tag','num_casts');
       if ~isempty(tmph)
	  set(tmph,'String',['Number of casts: ' num2str(ndat)]);
       end

       if ndat>0
	  seen = zeros(size(tin));
	  nxt = 0;
	  
	  vmc = interpJD(lat,lon,tim,la,lo,tm,vv);
	  
	  % Interp casts to model depths and calculate and plot summary stats
	  vcm = interp1(deps,vc',zm)';

	  mndif = repmat(nan,[1 nz]);
	  sdif =  repmat(nan,[1 nz]);
	  rmsdif = repmat(nan,[1 nz]);
	  
	  cdif = vmc-vcm;
	  for kk = 1:nz
	     ll = find(~isnan(cdif(:,kk)));
	     cnts(kk) = length(ll);
	     if cnts(kk)>1
		mndif(kk) = mean(cdif(ll,kk));
		sdif(kk) =  nanstd(cdif(ll,kk));
		rmsdif(kk) = sqrt(mean(cdif(ll,kk).^2));
	     end
	  end
	  % Find depth range with data (this works whether model depths 
	  % are ascending or not)
	  igd = find(cnts>0);
	  [zrng(1),tmp] = min(zm(igd));
	  lrng(1) = igd(tmp);
	  [zrng(2),tmp] = max(zm(igd));
	  lrng(2) = igd(tmp); 	       

	  % Also record orderred range of levels
	  flrng = [1 nz];
	  if zm(1)>zm(nz)
	     flrng = fliplr(flrng);
	  end
	  
	  zstr = sprintf('%3.1f - %3.1f m',zrng);
	  lstr = sprintf('%d - %d',lrng);
	  if ishandle(figs{4})
	     set(findobj('Tag','4_depth'),'String',{'Depth',zstr});
	     set(findobj('Tag','4_level'),'String',{'Level',lstr});
	  end
	  if ishandle(figs{5})
	     set(findobj('Tag','5_depth'),'String',{'Depth',zstr});
	     set(findobj('Tag','5_level'),'String',{'Level',lstr});
	  end

	  figure(figs{7})
	  subplot('position',[.13 .11 .84 .84]);
	  plot(rmsdif,-zm,'r')
	  hold on;
	  grid
	  xlabel(['RMS Error' unitl{curprp}]);
	  title(labels{curprp});
	  ylabel('depth (m)')
	  aa = axis;
	  aa(3) = -1.05*zrng(2);
	  defax(7,:) = aa;
	  if length(Vxlim{7})==2
	     aa(1:2) = Vxlim{7};
	  end
	  if length(Vylim{7})==2
	     aa(3:4) = Vylim{7};
	  end
	  axis(aa);
	  fill_axes_boxes(7);

	  
	  figure(figs{6})
	  subplot('position',[.13 .11 .84 .84]);
	  plot(mndif,-zm,'r')
	  hold on;
	  grid
	  % title('Stats of Model minus Data at each level')
	  plot(mndif+nanstd(cdif),-zm,'k--')
	  plot(mndif-nanstd(cdif),-zm,'k--')
	  legend({'Mean','Standard deviation'},0);
	  xlabel(['model minus observed ' fvars{curprp} unitl{curprp}]);
	  ylabel('depth (m)')
	  aa = axis;
	  aa(3) = -1.05*zrng(2);
	  defax(6,:) = aa;
	  if length(Vxlim{6})==2
	     aa(1:2) = Vxlim{6};
	  end
	  if length(Vylim{6})==2
	     aa(3:4) = Vylim{6};
	  end
	  axis(aa);
	  fill_axes_boxes(6);
	  
	  figure(figs{3})
	  subplot('position',[.09 .1 .38 .86]);
	  barh(-zm,cnts(:));
	  a2 = axis;
	  a2(3:4) = aa(3:4); 
	  defax(3,:) = a2;
	  if length(Vxlim{3})==2
	     a2(1:2) = Vxlim{3};
	  end
	  if length(Vylim{3})==2
	     a2(3:4) = Vylim{3};
	  end
	  axis(a2);
	  xlabel('Number of comparison samples')
	  ylabel('Depth (m)')
	  
	  subplot('position',[.5 .06 .47 .87]);
	  set(gca,'Xtick',[]);
	  set(gca,'Ytick',[]);
	  title('Stats of Model minus Data at each level')
	  axis([0 5 0 nz+1])
	  for nn = 1:nz
	     y = nn-.6;
	     text(0.1,y,num2str(nn));
	     text(.8,y,num2str(zm(nn)));
	     text(1.8,y,num2str(mndif(nn)));
	     text(3.1,y,num2str(sdif(nn)));
	     text(4.4,y,num2str(cnts(nn)));
	  end
	  y = nz+.3;
	  text(0.1,y,'Level');
	  text(.9,y,'Depth');
	  text(2,y,'Mean');
	  text(3.1,y,'StdDev');
	  text(4.3,y,'Count');
       end
       
    else
       % Derived quantity - Mixed Layer Depth

       Vlev = [1 1 1];
       
       set(alert,'String','Loading model and observed T & S')
       % Get obs MLDs
       [lat,lon,tim,Tc,Sc] = get_all_csl(src,2,[1 2],[1:4 7 9],1:25);
       
       if ~isempty(lat)
	  tin = find(tim>trng(1) & tim<trng(2)); 
	  lat = lat(tin);
	  lon = lon(tin);
	  tim = tim(tin);
	  % Have to rethink if ever model T & S in strange units
	  Tc = Tc(tin,:);
	  Sc = Sc(tin,:);
	  bdep = get_bath(lon,lat);
       end
       if isempty(lat)
	  set(alert,'String','No T & S casts found so cannot calc MLD')
       else
	  % Get corresponding model MLDS
	  Sm = [];
	  Tm = [];
	  timm = [];
	  for ii=1:nfiles
	     ncf = netcdf(fnames{ii},'nowrite');
	     stmp = ncf{'salt'}(:);
	     ttmp = ncf{'temp'}(:);
	     if ~isempty(ttmp) & ~isempty(stmp)
		Tm = cat(1,Tm,ttmp);
		Sm = cat(1,Sm,stmp);
		timm = [timm; tmf{ii}(:)];
	     end
	     close(ncf);
	  end
	  
	  [timm,itm] = sort(timm);
	  Sm = Sm(itm,:,:,:);
	  Tm = Tm(itm,:,:,:);
       end
       
       intT = interpJD(lat,lon,tim,la,lo,timm,Tm);
       intS = interpJD(lat,lon,tim,la,lo,timm,Sm);
       clear Tm Sm timm
    end    

    if ~isempty(lat)
       figure(figs{1})
       axes(maph)
       loch = plot(lon,lat,'r+');
       curh = []; seeh = [];
	  
       axes(timh)
       tloch = plot(tim/365,.3,'ro');
       if ~isempty(tmh); delete(tmh); tmh = []; end
    end

    if curprp==7
       % Invoke this GUI after fiddling the map above, so that the GUI is
       % in front of other windows.
       if ishandle(mldh)
	  figure(mldh);
       else
	  val_mld;
       end
    end    

    set(gcbf,'Pointer','arrow');
    set(findobj('Tag','load_region'),'BackgroundColor',[.7 .7 .7]);
    set(alert,'String','');
    
  
  case 'auto_xlim'
    tmp = get(findobj('Tag','auto_xlim'),'Value');
    if tmp==1 & ishandle(figs{curfig})
       Vxlim{curfig} = [];
       goto_curfig;
       aa = axis;
       aa(1:2) = defax(curfig,1:2);
       axis(aa);
       set(findobj('Tag','x_lim'),'String',num2str(aa(1:2)));
    end
    
  case 'auto_ylim'
    tmp = get(findobj('Tag','auto_ylim'),'Value');
    if tmp==1 & ishandle(figs{curfig})
       Vylim{curfig} = [];
       goto_curfig;
       aa = axis;
       aa(3:4) = defax(curfig,3:4);
       axis(aa);
       set(findobj('Tag','y_lim'),'String',num2str(aa(3:4)));
    end
  
  case 'fix_xlim'
    if ishandle(figs{curfig})
       tmp = str2num(get(findobj('Tag','x_lim'),'String'));
       if length(tmp)==2 & tmp(2)>tmp(1)
	  Vxlim{curfig} = tmp;
	  goto_curfig;
	  aa = axis;
	  aa(1:2) = tmp;
	  axis(aa);
	  set(findobj('Tag','auto_xlim'),'Value',0);
       else
	  set(findobj('Tag','x_lim'),'String','');
	  set(alert,'String','Requires a pair of numbers to set X axis');
       end
    end
    
  case 'fix_ylim'
    if ishandle(figs{curfig})
       tmp = str2num(get(findobj('Tag','y_lim'),'String'));
       if length(tmp)==2 & tmp(2)>tmp(1)
	  Vylim{curfig} = tmp;
	  goto_curfig;
	  aa = axis;
	  aa(3:4) = tmp;
	  axis(aa);
	  set(findobj('Tag','auto_ylim'),'Value',0);
       else
	  set(findobj('Tag','y_lim'),'String','');
	  set(alert,'String','Requires a pair of numbers to set Y axis');
       end
    end

  case 'set_curfig'
    ii   = get(findobj('Tag','plot_names'),'Value');
    curfig = plist_fig(ii);
    if ishandle(guih{curfig})
       figure(guih{curfig});
    elseif curfig==2
       val2;
    elseif curfig==4
       val4;
    elseif curfig==5
       val5;
    end
    if ishandle(figs{curfig})
       goto_curfig;
       fill_axes_boxes(curfig);
    end
    
  case 'print_plot'
    if isempty(figs{curfig}) | ~ishandle(figs{curfig})
       set(alert,'String','Cannot save a figure which does not exist!');
    else
       figure(figs{curfig});
       switch curfig
	 case 2
	   fnm = [fvars{curprp} '_' num2str(cpn(nxt)) '.eps'];
	 case 4
	   fnm = [fvars{curprp} '_' num2str(zm(Vlev(3))) '_m.eps'];
	 case 5
	   fnm = [fvars{curprp} '_scat.eps'];
	 case 6
	   fnm = [fvars{curprp} '_stats_p.eps'];
	 case 7
	   fnm = [fvars{curprp} '_rms_err.eps'];
       end
       print('-depsc','-tiff',fnm);
       set(alert,'String',['Plot saved to file ' fnm]);
    end
    
  case 'finish'
    if asc_save
       disp('ASCII output format:')
       disp(' Header records:  ID  CPN  Lon  Lat  DataType  Date/Time') 
       disp(' Data records:   depth(m)  obs_value  model_val')
    end
    byenow;

    
% GUI 2 callbacks --------------------
  
  case 'init2'
    set(findobj('Tag','num_casts'),'String',['Number of casts: ' num2str(ndat)]);
    if ndat==0
       set(alert,'String','No cast data available');
    else
       set(alert,'String',['Use the "Close" button when finished with the' ...
			   ' GUI, not the [X] in the top right']);
    end
  
  case 'next_cast'
    if ndat==0
       set(alert,'String','No cast data available!');
    elseif nxt >= ndat
       set(alert,'String','Already at last cast - no action taken');
    else
       nxt = nxt + 1;
       plot_cast;
    end

  case 'num_cast'
    tmp = eval(get(findobj('Tag','castnum'),'String'));    
    if ndat==0
       set(alert,'String','No cast data available!');
    elseif length(tmp) ~= 1
       set(alert,'String','Bad cast number given');
    elseif tmp > ndat | tmp < 0
       astr = ['Trying to plot the ' num2str(nxt) 'th out of ' num2str(ndat) ' casts!'];
       set(alert,'String',astr);
    else           
       nxt = tmp;
       plot_cast;
    end

  case 'sel_cast'
    if ndat==0
       set(alert,'String','No cast data available!');
    else
       jj = find(~seen);
       figure(figs{1});
       axes(maph);
       if isempty(jj)
	  set(alert,'String','You have already seen all casts. Refreshing the list.');
	  seen = ~seen;
	  if ~isempty(seeh); delete(seeh); end
	  if ~isempty(loch); delete(loch); end
	  loch = plot(lon,lat,'r+');
       end
       set(alert,'String','select a cast on the map');
       tmp = closest(lon(jj),lat(jj),ginput(1));
       nxt = jj(tmp);
       plot_cast;
    end
    
  case 'finish2'
    close(gcbf);
    guih{2} = [];

    
% GUI 4 (difference map) callbacks --------------------
  
  case 'init4'
    if isempty(lat)
       close(guih{4});
       guih{4} = [];
       set(alert,'String','Must load model and cast data first');
    else
       set(alert,'String',['Use the "Close" button when finished with the' ...
			   ' GUI, not the [X] in the top right']);
       str = sprintf('%3.1f - %3.1f m',zrng);
       set(findobj('Tag','4_depth'),'String',{'Depth',str});
       str = sprintf('%d - %d',lrng);
       set(findobj('Tag','4_level'),'String',{'Level',str});
    end
  
  case 'd_dep'
    tmp = str2num(get(Vdeph(3),'String'));
    if length(tmp)~=1
       set(alert,'String','Must specify just 1 depth for difference map');
    else
       tmp = round(interp1(zm,1:nz,tmp));
       sclev_load(tmp,3);
       plot_dmap(Drng);
    end
    
  case 'd_lev'
    tmp = round(str2num(get(Vlevh(3),'String')));
    if length(tmp)~=1
       set(alert,'String','Must specify just 1 level for difference map');
    else
       sclev_load(tmp,3);
       plot_dmap(Drng);  
    end
    
  case 'set_rng'
    tmp = str2num(get(findobj('Tag','4_rng'),'String'));
    if length(tmp)~=1
       set(alert,'String','Specify range (+/-) by just 1 value');    
    else
       Drng = tmp;
    end
    plot_dmap(Drng);

  case 'finish4'
    close(gcbf);
    guih{4} = [];
  
    
% GUI 5 (scatter plot) callbacks --------------------
  
  case 'init5'
    if isempty(lat)
       close(guih{5});
       guih{5} = [];
       set(alert,'String','Must load model and cast data first');
    else
       set(alert,'String',['Use the "Close" button when finished with the' ...
			   ' GUI, not the [X] in the top right']);
       % Specify fullrng rather than rnage with data, because may want to 
       % plot full range for consistency with other plots.
       str = sprintf('%3.1f - %3.1f m',[min(zm) max(zm)]);
       set(findobj('Tag','5_depth'),'String',{'Depth',str});
       str = sprintf('%d - %d',flrng);
       set(findobj('Tag','5_level'),'String',{'Level',str});
    end
    
  case '5_dep'
    tmp = str2num(get(Vdeph(2),'String'));
    tmp = round(interp1(zm,1:nz,tmp));
    sclev_load(tmp,2);
    plot_scat;
  
  case '5_lev'
    tmp = round(str2num(get(Vlevh(2),'String')));
    sclev_load(tmp,2);
    plot_scat;  

  case 'finish5'
    close(gcbf);
    guih{5} = [];
  
        
% MLD GUI callbacks --------------------
  
  case 'initmld'
    if nfiles==0
       close(mldh);
       set(alert,'String','Need to load some model files first');
    else
       fill_mld_flds(curset,mldopt,mldthr);
    end
    
  case 'mld_dset'
    curset = get(findobj('Tag','mld_dset'),'Value');
    fill_mld_flds(curset,mldopt,mldthr);
      
  case 'mld_t'
    tmp = str2num(get(findobj('Tag','mld_delt'),'String'));
    if length(tmp)==1
       mldthr(curset,1) = tmp;
    end

  case 'mld_s'
    tmp = str2num(get(findobj('Tag','mld_dels'),'String'));
    if length(tmp)==1
       mldthr(curset,2) = tmp;
    end

  case 'mld_sigdz'
    tmp = str2num(get(findobj('Tag','mld_sigdz'),'String'));
    if length(tmp)==1
       mldthr(curset,3) = tmp;
    end
  
  case 'mld_sig'
    tmp = str2num(get(findobj('Tag','mld_sig'),'String'));
    if length(tmp)==1
       mldthr(curset,4) = tmp;
    end

  case 'mld_meth'
    mldopt(curset) = get(findobj('Tag','mld_meth'),'Value');
    fill_mld_flds(curset,mldopt,mldthr);
      
  case 'calcmld'
    set(gcbf,'Pointer','watch');
    if curset==1       
       mldm = mixld(intT,intS,zm,bdep,mldthr(curset,:),mldopt(curset));
       str = sprintf('%d model MLDs, from %3.0f to %3.0f, mean %4.1f',...
		     sum(~isnan(mldm)),min(mldm),max(mldm),nanmean(mldm));
       set(alert,'String',str);
    else
       mldc = mixld(Tc,Sc,csl_dep(1:25,2),bdep,mldthr(curset,:),mldopt(curset));
       str = sprintf('%d obs MLDs, from %3.0f to %3.0f, mean %4.1f',...
		     sum(~isnan(mldc)),min(mldc),max(mldc),nanmean(mldc));
       set(alert,'String',str);
    end
    if ~isempty(mldm) & ~isempty(mldc)
       cdif = mldm-mldc;
       plot_dmap(Drng);
       plot_scat;
    end    
    set(gcbf,'Pointer','arrow');
    
  case 'finishmld'
    close(gcbf);
    mldh = [];
  
  
  otherwise
    warndlg(['Unknown action: ' action]);
    
end
    

%------------------------------------------------------------------------
function setlimflds(src)

tmp = rectreg(src);
set(findobj('Tag','ew_region'),'String',num2str(tmp([1 3],1)'));
set(findobj('Tag','ns_region'),'String',num2str(tmp([1 3],2)'));

return
%------------------------------------------------------------------------
function src = getlimflds()

we = str2num(get(findobj('Tag','ew_region'),'String'));
if length(we)~=2
   warndlg('You need to provide w and e limits: eg 149 155')
elseif we(2)<=we(1)
   warndlg('West limit must be less than east')
else          
   sn = str2num(get(findobj('Tag','ns_region'),'String'));
   if length(sn)~=2
      warndlg('You need to provide s and n limits: eg -48 -34')
   elseif sn(2)<=sn(1)
      warndlg('South limit must be less than north')
   else          
      src = [we([1 1 2 2]); sn([1 2 2 1])]';
   end
end

return
%----------------------------------------------------------------------
function out = rectreg(in)

t1 = in(:,1);
t2 = in(:,2);
out = [min(t1) min(t1) max(t1) max(t1); ...
      min(t2) max(t2) max(t2) min(t2)]';

return

%===========================================================================
% GET_REG  Let user define region using rubberband box on map
% 

function reg = get_reg(fig)

figure(fig);

zoom off;

% Use no-side effect WAITFORBUTTONPRESS
waserr = 0;
eval('keydown = wfbp;', 'waserr = 1;');
if(waserr == 1)
   if(ishandle(fig))
      set(fig,'pointer',pointer,'units',fig_units);
      disp('Interrupted');
   else
      disp('Interrupted by figure deletion');
   end
   byenow
end

ptr_fig = get(0,'CurrentFigure');
if(ptr_fig == fig)
   if ~keydown
      pt1 = get(gca, 'CurrentPoint');
	 
      % This is only used to draw the dashed line box - we ignore 'oo'
      oo = rbbox;
	 
      pt2 = get(gca, 'CurrentPoint');
	 
      x = [pt1(1,1) pt2(1,1)];	 
      if x(2)<x(1)
	 x = fliplr(x);
      end
      y = [pt1(1,2) pt2(1,2)];	 
      if y(2)<y(1)
	 y = fliplr(y);
      end
      reg = [x y];
	 
   end       % End keydown - mouse-click
end       % End (ptr_fig == fig)

zoom on;
return

%--------------------------------------------------------------------------------
% BYENOW - clear up figures, globals, and shutdown GUI to exit.

function byenow

global ncf figs guih defafs deftfs mldh

tmp = questdlg('Close all figures used?');
if strcmp(tmp,'Yes')
   for ii = 1:length(figs)
      if ishandle(figs{ii})
	 close(figs{ii});
      end
   end
   for ii = 1:length(guih)
     if ishandle(guih{ii})
	 close(guih{ii});
      end
   end
   if ishandle(mldh)
      close(mldh)
   end
end

set(0,'defaultaxesfontsize',defafs);
set(0,'defaulttextfontsize',deftfs);

close(ncf)
close(gcbf);

clear global ncf alert guih defafs deftfs Vdeph Vlevh
clear global figs maph curh seeh timh tmh tloch loch regh proh dmaph
clear global fvars labels ftyps unitl curprp
clear global tm mtrng zm nz la lo
clear global nxt inlst ndat seen lon lat tim vc cpn ftyp ndat 
clear global deps mxd vmc trng
clear global mapax cdif vcm lrng zrng
clear global defax Vxlim Vylim Vlev maplev curfig
clear global tdmax rmax just1
clear global dsetnm mldc mldh mldm mldmeth

% to clear pesistent variables
clear fun val_util

return

%===========================================================================
% INTERPJD  Interpolate model output to cast, in time and x-y space. When
%  needed, we interpolate the cast to the model depths (because we know that
%  the cast's standard levels are nicely spaced for interpolation.)

function vmc = interpJD(lat,lon,tim,la,lo,tm,vv)

global tdmax rmax just1

nz = size(vv,2);

ntm = length(tm);
vmc = repmat(nan,[length(lat) nz]);

for ii=1:length(lat)

   rwgt = [];
   
   % Find model timesteps before and after cast time.
   t2 = [];
   t1 = max((1:ntm)'.*(tm(:)<=tim(ii)));
   if isempty(t1)
      t1 = 1;
   elseif t1<ntm & abs(tim(ii)-tm(t1+1))<tdmax
      t2 = t1+1;
   end
   if abs(tim(ii)-tm(t1))>tdmax
      t1 = t2;
      t2 = [];
   end
   
   i4 = [];
   if ~isempty(t1)
      % Find nearest 4 model grid points
      lc = cos(lat(ii)*pi/180);
      rr = (lat(ii)-la).^2 + (lc.*(lon(ii)-lo)).^2;
      jj = 1:prod(size(rr));
      for kk = 1:4
	 [tmp,itmp] = min(rr(jj));
	 if tmp<rmax
	    i4 = [i4 jj(itmp)];
	 end
	 jj(itmp) = [];
      end
   end
   
   if ~isempty(i4)
      vtmp = reshape(vv(t1,:,:,:),[nz prod(size(la))]);
      vtmp = vtmp(:,i4);
      
      % If rather have just nearest profile rather than average profiles
      % of different depths, test for and arrange that now.
      if just1 & any(diff(sum(isnan(vtmp))))
	 i4 = i4(1);
	 vtmp = vtmp(:,1);
      end
      
      maxr = 1.05.*rr(i4(end));
      ww = 1-(rr(i4)./maxr);

      rwgt = ~isnan(vtmp)*ww(:);

      kk = find(isnan(vtmp));
      vtmp(kk) = zeros(size(kk));
      dat = vtmp*ww(:);
   end
      
   if ~isempty(t2) & ~isempty(i4)
      % If model timesteps straddle cast time, interpolate in time
      tdf = tm(t2)-tm(t1);
      t1w = 1 - (abs(tim(ii)-tm(t1))/tdf);
      t2w = 1-t1w;
      rwgt = rwgt.*t1w;
      dat = dat.*t1w;
      
      vtmp = reshape(vv(t2,:,:,:),[nz prod(size(la))]);
      vtmp = vtmp(:,i4);
	 
      rwgt = rwgt + t2w.*(~isnan(vtmp)*ww(:));
	 
      vtmp(kk) = zeros(size(kk));
      dat = dat + t2w.*(vtmp*ww(:));
   end

   if ~isempty(rwgt)
      ll = find(rwgt>0.0005);
      vmc(ii,ll) = (dat(ll)./rwgt(ll))';
   end
end

return

%===========================================================================
%WFBP   Replacement for WAITFORBUTTONPRESS that has no side effects.

function key = wfbp


% Remove figure button functions
fprops = {'windowbuttonupfcn','buttondownfcn', ...
	  'windowbuttondownfcn','windowbuttonmotionfcn'};
fig = gcf;
fvals = get(fig,fprops);
set(fig,fprops,{'','','',''})

% Remove all other buttondown functions
ax = findobj(fig,'type','axes');
if isempty(ax)
   ch = {};
else
   ch = get(ax,{'Children'});
end
for i=1:length(ch),
   ch{i} = ch{i}(:)';
end
h = [ax(:)',ch{:}];
vals = get(h,{'buttondownfcn'});
mt = repmat({''},size(vals));
set(h,{'buttondownfcn'},mt);

% Now wait for that buttonpress, and check for error conditions
waserr = 0;
eval(['if nargout==0,', ...
      '   waitforbuttonpress,', ...
      'else,', ...
      '   keydown = waitforbuttonpress;',...
      'end' ], 'waserr = 1;');

% Put everything back
if(ishandle(fig))
   set(fig,fprops,fvals)
   set(h,{'buttondownfcn'},vals)
end

if(waserr == 1)
   error('Interrupted');
end

if nargout>0, key = keydown; end

return

%-------------------------------------------------------
function plot_cast

global alert figs maph curh seeh timh tmh tloch loch regh proh
global fvars labels ftyps unitl curprp
global tm trng zm nz la lo
global nxt inlst ndat seen lon lat tim vc cpn ftyp ndat 
global deps mxd vmc
global defax Vxlim Vylim

clat = {'S','N'};
clon = {'W','E'};

if curprp<7 & ndat==0   
   set(alert,'String','No data! Have you clicked "Load region"?');
   return
elseif curprp==7 & isempty(cdif)
   set(alert,'String','No data! Have you calculated MLD yet?');
   return
end

% Plot location of this and other casts on map
figure(figs{1})
axes(maph);
if ~isempty(curh); delete(curh); end 
if ~isempty(seeh); delete(seeh); end
if ~isempty(loch); delete(loch); end
jj = find(seen);
seeh = plot(lon(jj),lat(jj),'+','color',[.6 .6 .6]);
jj = find(~seen);
loch = plot(lon(jj),lat(jj),'r+');
curh = plot(lon(nxt),lat(nxt),'go','markersize',12);
seen(nxt) = 1;

% Identify this cast on timeline
axes(timh);
if ~isempty(tmh); delete(tmh); end 
tmh = plot(tim(nxt)/365,.1,'b^','markersize',18);

% Plot individual profile
figure(figs{2})
axes(proh);
hold off
mcd = max(find(~isnan(vc(nxt,:))));  	 % Find deepest level with data
plot(vc(nxt,1:mcd),-deps(1:mcd),'ro');
grid
hold on
ctim = time2greg(tim(nxt));
cstr = sprintf('%2d/%2d/%4d %0.2d:%0.2d',ctim([3 2 1 4 5]));

title([fvars{curprp} unitl{curprp} '  '  num2str(abs(lon(nxt))) clon{1+(lon(nxt)>0)} ...
       '  ' num2str(abs(lat(nxt))) clat{1+(lat(nxt)>0)} '   ' cstr]);
str = [ftyps{ftyp(nxt)} ', cast ' num2str(nxt) ', CPN ' num2str(cpn(nxt))];
set(alert,'string',str);

mmcd = max(find(zm>deps(mcd)));
if isempty(mmcd); mmcd = nz; end
plot(vmc(nxt,mmcd:nz),-zm(mmcd:nz),'k--','linewidth',2);

aa = axis;
aa(3) = -1.05*deps(mcd);
defax(2,:) = aa;
if length(Vxlim{2}) == 2
   aa(1:2) = Vxlim{2};
end
if length(Vylim{2}) == 2
   aa(3:4) = Vylim{2};
end

axis(aa);
legend({'observed','model'},0);
xlabel([fvars{curprp} unitl{curprp}]);
ylabel('Depth (m)');

set(findobj('Tag','castnum'),'String',num2str(nxt));    

fill_axes_boxes(2);

return
%---------------------------------------------------------------------------
function plot_dmap(Drng)

global alert figs maph curh seeh timh tmh tloch loch regh proh dmaph
global fvars labels ftyps unitl curprp
global tm trng zm nz la lo
global nxt inlst ndat seen lon lat tim vc cpn ftyp ndat 
global deps mxd vmc 
global mapax cdif
global defax Vxlim Vylim Vlev

if isempty(lat)
   set(alert,'String','No data! Have you clicked "Load region"?');
   return
end
if curprp==7
   if isempty(cdif)
      set(alert,'String','No data - have you calculated MLD for both datasets?');
      return
   elseif size(cdif,1)==1
      % Need cdif to be a column
      cdif = cdif';
   end
end
if all(isnan(cdif(:,Vlev(3)))) 
   set(alert,'String','No data to compare at this level');
   return
end

if isempty(figs{4})
   figs{4} = figure;
   set(gcf,'Name',['Difference map ' num2str(figs{4})],'NumberTitle','off');
else
   figure(figs{4});
end
dmaph = subplot('position',[.08 .2 .85 .7]);
cla;
if isempty(Drng)
   rng = max(abs(cdif(:,Vlev(3))));
else
   rng = Drng;
end
kk = find(cdif(:,Vlev(3))>=0);
markerplot(lon(kk),lat(kk),cdif(kk,Vlev(3)),'rv',[0 rng],[1 16]);
kk = find(cdif(:,Vlev(3))<0);
markerplot(lon(kk),lat(kk),-cdif(kk,Vlev(3)),'o',[0 rng],[1 16]);
defax(4,:) = mapax;
aa = mapax;
if length(Vxlim{4})==2
   aa(1:2) = Vxlim{4};
end
if length(Vylim{4})==2
   aa(3:4) = Vylim{4};
end
axis(aa);
gebco
if min(size(cdif))==1
   title(['Model minus observed ' labels{curprp}]);
else
   title(['Model minus observed ' labels{curprp} ' at depth ' ...
	  num2str(zm(Vlev(3))) 'm']);
end

% Organise a scale the hard way. "legend" distorts the marker
% sizes to fit in the box, and so cannot be used as a scale.
subplot('position',[.08 .1 .85 .05]);
cla;
axis([-1.1*rng 1.1*rng -1 1]);	    
plot(0,0,'v','markersize',1);
hold on;	    
for rsc = 2:2:16
   plot(rsc*(rng/16),0,'rv','markersize',rsc);
end
for rsc = 2:2:16
   plot(-rsc*(rng/16),0,'o','markersize',rsc);
end
set(gca,'ytick',[]);
xlabel(['model low          ' labels{curprp} unitl{curprp} '          model high']);

axes(dmaph);
fill_axes_boxes(4);

return
%------------------------------------------------------------------------
function plot_scat

global alert figs maph curh seeh timh tmh tloch loch regh proh
global fvars labels ftyps unitl curprp
global tm trng zm nz la lo
global nxt inlst ndat seen lon lat tim vc cpn ftyp ndat 
global deps mxd vmc 
global mapax cdif vcm
global defax Vxlim Vylim Vlev
global mldm mldc

if isempty(lat)
   set(alert,'String','No data! Have you clicked "Load region"?');
   return
elseif isempty(cdif) & curprp==7
   set(alert,'String','No data - have you calculated MLD for both datasets?');
   return
end

if curprp==7
   modelv = mldm;
   obsv = mldc;
else
   modelv = vmc(:,Vlev(2):Vlev(1));
   obsv = vcm(:,Vlev(2):Vlev(1));
   depv = zm(Vlev(2):Vlev(1));
   depv = repmat(depv(:)',[ndat 1]);
end
ll = find(~isnan(modelv + obsv));
if isempty(ll)
   set(alert,'String','No data to compare in these levels!');
   return
end

if isempty(figs{5})
   figs{5} = figure;
   set(gcf,'Name',['Scatter ' num2str(figs{5})],'NumberTitle','off');
else
   figure(figs{5});
   clf
end
if Vlev(1)==Vlev(2)
   plot(modelv(ll),obsv(ll),'o');
else
   colourplot(modelv(ll),obsv(ll),depv(ll),'o');
   hcb = colbarv;
   set(hcb,'ydir','reverse');
   ylabel('Depth m')
   cc = caxis;
end
hold on;
xlabel(['Model ' labels{curprp} unitl{curprp}]);
ylabel(['Observed ' labels{curprp} unitl{curprp}]);

tmp = axis;
a2  = [min(tmp([1 3])) max(tmp([2 4]))];
defax(5,:) = [a2 a2]; 
aa = defax(5,:);
if length(Vxlim{5})==2
   aa(1:2) = Vxlim{5};
end
if length(Vylim{5})==2
   aa(3:4) = Vylim{5};
end
axis(aa);

plot(aa(1:2),aa(3:4),'k--');
grid

fill_axes_boxes(5);

return
%---------------------------------------------------------------------------
function sclev_load(tmp,ii)

global alert Vlev zm nz Vdeph Vlevh curprp

if curprp==7
   set(alert,'String','Cannot choose levels for ML depth - it is a 2D field');
   return
end

if any(isnan(tmp)) | any(tmp<1) | any(tmp>nz)
   set(alert,'String','Bad depth specified');
elseif ii==3
   Vlev(3) = tmp;
else
   if length(tmp)==1
      Vlev(1) = tmp;
      Vlev(2) = tmp;
   else
      if tmp(2) > tmp(1)
	 tmp = tmp([2 1]);
      end
      Vlev(1:2) = tmp;
   end
end

str = sprintf('%3.1f %3.1f',zm(tmp));
set(Vdeph(ii),'String',str);
set(Vlevh(ii),'String',num2str(tmp));

return
%---------------------------------------------------------------------
function fill_axes_boxes(ii)

global curfig Vxlim Vylim

if ii==curfig
   aa = axis;
   set(findobj('Tag','x_lim'),'String',num2str(aa(1:2)));
   set(findobj('Tag','y_lim'),'String',num2str(aa(3:4)));
   set(findobj('Tag','auto_xlim'),'Value',isempty(Vxlim{ii}));
   set(findobj('Tag','auto_ylim'),'Value',isempty(Vylim{ii}));
end

return
%-------------------------------------------------------------------
function goto_curfig

global figs curfig dmaph

figure(figs{curfig});
if curfig==4 & ishandle(dmaph)
   axes(dmaph);
end

return
%-------------------------------------------------------------------
function fill_mld_flds(curset,mldopt,mldthr)

global dsetnm mldmeth

dstr = {'Calc model','Calc obs'};

set(findobj('Tag','mld_dset'),'String',dsetnm,'Value',curset);
set(findobj('Tag','mld_delt'),'String',num2str(mldthr(curset,1)));
set(findobj('Tag','mld_dels'),'String',num2str(mldthr(curset,2)));
set(findobj('Tag','mld_sigdz'),'String',num2str(mldthr(curset,3)));
set(findobj('Tag','mld_sig'),'String',num2str(mldthr(curset,4)));
set(findobj('Tag','mld_meth'),'String',mldmeth,'Value',mldopt(curset));
set(findobj('Tag','calcmld'),'String',dstr{curset});

return
%--------------------------------------------------------------------
% MIXLD   Calculate mixed-layer depth for a cast
% INPUT:  
%   te   [ncast ndep] temperature observations (arbitrarily spaced)
%   sa   [ncast ndep] corresponding S values, if available
%   deps  [ndep] corresponding depths of observations
%   bdep  [ncast] depth of ocean bottom at cast location (*** +ve downwards) 
%   thr   4 thresholds for tests (recommended values shown):
%       1)  t-t(10m)   [.4C]
%       2)  s-s(10m)       [.03]
%       3)  dSigma/dz (below 10m)  [.003]
%       4)  Sigma-Sigma(10m) [.06]
%   mldopt  Options for choosing preferred of the 3 estimates:
%       1,2,3-the individual ests,  5-max  6-min  7-mean  8-median  
% OUTPUT:
%   mld    The estimate of mixed-layer depth
%
% The mixed layer estimates:
%  Notes: 
% #  For 1 start at first value beneath 8m, but fail if that is below
%    24m.
% #  For 1 & 2 the required T or S difference is usually straddled. Fail
%    if gap is 20m or more. We quadratic interpolate the MLD, assuming a +ve
%    d2t/d2z in larger gaps.
%
% USAGE:   mld = mixld(te,sa,deps,bdep,thr,mldopt)

function mld = mixld(te,sa,deps,bdep,thr,mldopt)

d2m = (0:2:450)'; 

ncast = size(te,1);
mld = repmat(nan,[1 ncast]);

% Need depths and profiles orderred shallow to deep (esp for deps_to_2m).
if deps(1)>deps(end)
   te = fliplr(te);
   sa = fliplr(sa);
   deps = fliplr(deps(:)');
end

for ii = 1:ncast
   mlds = [nan nan nan];
   tref3 = 0;
   sref2 = 0;
   tpro = [];
   spro = [];
   dens = [];

   T = te(ii,:);
   S = sa(ii,:);
   
   % idxo is index into original cast data
   idxo = find(~isnan(T));

   ngood = length(idxo);
   
   if ngood > 3 & max(deps(idxo)) > 24
      tpro = deps_to_2m(deps(idxo),T(idxo),450,-1);
      
      % MLD 1 - using change in temperature wrt a near-surface value,  
      % which is the first >= 10m. 
      
      i2r = find(~isnan(tpro(2:end)))+1;
      l2r = length(i2r);
      if l2r > 1
	 [rfdel10,refidx] = min(abs(d2m(i2r)-10));
	 i2r = i2r(refidx:end);
      end

      % Only proceed if have a suitable reference value above 25m, and at 
      % least 1 value below it. 
      % What is the appropriate delT depth? the one above, below, linearly 
      % interpolated? The bulk of cases should have t(z) curving near bottom
      % of ML so that an interpolated value would be too shallow. Counter 
      % this by a quadratic instead of linear interpolation.  

      if l2r > 1 & rfdel10 < 14    
	 kk = find(abs(tpro(i2r)-tpro(i2r(1))) > thr(1));
	 if ~isempty(kk)
	    k1 = i2r(kk(1)-1);
	    k2 = i2r(kk(1));
	    if tpro(k1)>tpro(k2)
	       tref3=tpro(i2r(1))-thr(1);
	    else 
	       tref3=tpro(i2r(1))+thr(1);
	    end
	    depdif = d2m(k2)-d2m(k1);
	    if depdif < 20
	       tratio = (tref3-tpro(k2))/(tpro(k1)-tpro(k2)); 
	       mlds(1) = d2m(k2) - depdif*(tratio^2);
	    end
	 elseif abs(bdep-d2m(i2r(end)))<=20 & bdep>10
	    mlds(1)=min(450,bdep);
	 end
	 % I don't believe in MLs deeper than 450m, so if haven't detected one
	 % here, then assume it was a missed subtle one, so do not set to 450
	 % but leave as NaN.      
      end
   end    

   % Calculation of mld due to a change in salinity.
   % Use only if there is more than three valid points, where the 
   % first point is at or below 10 m and the last is at or below 30 m
   % Use deps_to_2m to estimate interpolated salinity 
   % If there is a gap between sucessive data points greater than 10m
   % then do not use any values below the gap

   idxo = find(~isnan(S));
   ngood = length(idxo);

   if ngood > 3 & ~isempty(tpro) & max(deps(idxo)) >= 30
      spro = deps_to_2m(deps(idxo),S(idxo),450,-1);
      i2m = find(~isnan(spro) & ~isnan(tpro));
      l2m = length(i2m);
      gsize = i2m(2:l2m)-i2m(1:l2m-1);
      bigg = find(gsize>5);
      if ~isempty(bigg)
	 i2m = i2m(1:bigg(1));
	 l2m = length(i2m);
      end
   end

   if ~isempty(spro)
      j2m = find(~isnan(spro(6:end)))+5;
      l2m = length(j2m);
      if ~isempty(j2m)
	 refidx=j2m(1);
      end

      % Only proceed if we have a reference value above 25 m and at least
      % one value below it.
      % sref is determined by using quadratic interpolation.

      if l2m > 1 & d2m(refidx) < 25
	 kk = find((abs(spro(j2m)-spro(refidx)))>thr(2));  
	 if ~isempty(kk)
	    k1 = j2m(kk(1)-1);
	    k2 = j2m(kk(1));
	    if spro(k1)>spro(k2)
	       sref2=spro(refidx)-thr(2);
	    else 
	       sref2=spro(refidx)+thr(2);
	    end
	    depdif = d2m(k2)-d2m(k1);
	    if depdif < 20
	       sratio = (sref2-spro(k2))/(spro(k1)-spro(k2));
	       mlds(2) = d2m(k2) - depdif*(sratio^2);
	    end
	 elseif abs(bdep-d2m(j2m(end)))<=20 & bdep>10
	    mlds(2) = min(450,bdep);
	 end

	 % dSigma/dz
	 % DID use sw_dens, which calculates density including the depth effect.
	 % Decided to use sw_dens0 so that could use a lower threshold (than .01
	 % as previously used) and so be more sensitive to changes in t & s.
	 % This test often trips near surface, so start it (index k2m) at 16m.
	 % Tried .006 but a lot of real MLs were missed (on test Fr 10/94).
	 
	 k2m = j2m(find(j2m>=8));
	 dens = sw_dens0(spro(k2m),tpro(k2m));
	 dsdz = diff(dens)./(2*diff(k2m));
	 kk = find(abs(dsdz) > thr(3) | abs(dens(2:end)-dens(1)) > thr(4));
	 if ~isempty(kk)
	    mlds(3) = d2m(k2m(kk(1)));
	 elseif abs(bdep-d2m(k2m(end)))<=20 & bdep>10
	    mlds(3) = min(450,bdep);
	 end
      end
   end

   if mldopt<=3
      mld(ii) = mlds(mldopt);
   elseif mldopt==5
      mld(ii) = max(mlds);
   elseif mldopt==6
      mld(ii) = min(mlds);
   elseif mldopt==7 | sum(~isnan(mlds))<3
      mld(ii) = mean(mlds);
   else
      mlds = sort(mlds);
      mld(ii) = mlds(2);
   end
end

return
%----------------------------------------------------------------------
