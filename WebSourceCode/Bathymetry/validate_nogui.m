% VALIDATE  Extract cast data and compare with model output file
%
% INPUTS:
%  fnm - full path filename for model file (inc '.nc' extension) 
%  fsz - [optional] Fontsize for plots. Default 16. 
%
% Jeff Dunn CSIRO Marine Research   23/10/2001
% $Id: validate_nogui.m,v 1.7 2003/03/03 22:41:15 dun216 Exp dun216 $
%
% EXAMPLE: validate('/home/blah/model_out.nc')
%
% USAGE: validate(fnm,fsz)

function validate(fnm,fsz)

if nargin<2 | isempty(fsz)
   fsz = 16;
end

defafs = get(0,'defaultaxesfontsize');
deftfs = get(0,'defaulttextfontsize');
set(0,'defaultaxesfontsize',fsz);
set(0,'defaulttextfontsize',fsz);

ncquiet

vers = version;
if ~strcmp(vers(1),'6')
   error('Sorry - VALIDATE will only work in Matlab version 6')
end

add_dunn = 0;
spath = which('markerplot');
if isempty(spath)
   disp('Adding path /home/dunn/matlab/, for functions called by "validate"')
   addpath /home/dunn/matlab/ -end
   add_dunn = 1;
end
add_hesm = 0;
spath = which('dep_csl');
if isempty(spath)
   disp('Adding path /home/eez_data/software/matlab/, for functions called by "validate"')
   addpath /home/eez_data/software/matlab/ -end
   add_hesm = 1;
end

asc_save = 0;
% draw data from tmxt days outside model timerange 
tmxt = 0;

if nargin<1 | isempty(fnm)
   % Test file : '/home/oez1/condie/reg_mod_archive/SA/simple_out/jan-mar.nc';
   % also: /home/mgproja/jems/acom3/*_ext.nc
   fnm = input('Full path and name for model file : ','s');
end

if exist(fnm,'file')
   nc = netcdf(fnm,'nowrite');
   if isempty(nc)
      disp([7 'Cannot open file ' fnm]);
      return
   end
else
   disp([7 'Cannot find file ' fnm]);
   return
end


ss = input('Using figs 10-14 unless specify another 6 (eg [1 2 3 5 7 9]) : ');
if ~isempty(ss) & length(ss)==6
   figs = ss;
else
   figs = [10 11 12 13 14 15];
end
figure(figs(6));
figure(figs(5));
figure(figs(4));
figure(figs(3));
figure(figs(2));
figure(figs(1));

% Get model time and convert to 1900 base year. Go tmxt days outside model
% time range.

tm = nc{'time'}(:);
if isempty(tm)
   tm = nc{'t'}(:);
end
tof = greg2time([1990 1 1 0 0 0]);
tm = tm+tof;
trng = [min(tm)-tmxt max(tm)+tmxt];

zc = -nc{'zc'}(:);
if isempty(zc)
   zc = -nc{'z'}(:);
end
if isempty(zc)
   zc = -nc{'z_centre'}(:);
end
if isempty(zc)
   error('aborting: cannot find "z", "zc", or "z_centre" in this file!');
end

nz = length(zc);
mxd = ceil(dep_csl(max(zc),2));
indx = 1:mxd;
deps = csl_dep(indx,2);

la = nc{'latitude'}(:);
lo = nc{'longitude'}(:);
if isempty(la)
   la = nc{'y'}(:);
   lo = nc{'x'}(:);
end
if isempty(la)
   la = nc{'y_centre'}(:);
   lo = nc{'x_centre'}(:);
end
[ny,nx] = size(la);


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

disp('Comparison region will default to entire model domain.')

% Plot model grid and cast locations, and same for time domain.
figure(figs(1))
clf
maph = subplot('position',[.06 .3 .9 .6]);
plot(lo,la,'k.','markersize',2);
hold on;
mapax = axis;
gebco
title({'MODEL GRID and CAST LOCATIONS MAP',...
       '(mouse buttons can be used to zoom in this figure)'})
zoom on;
loch = [];
regh = [];
curh = [];

timh = subplot('position',[.06 .08 .9 .12]);
plot(tm/365,.7,'k+');
hold on;
title('Model and casts: temporal distribution')
axis([trng/365 -.2 1.2])
set(gca,'ytick',[]);
xlabel('Year')
tmh = [];
tloch = [];


ftyps = {'WOD98 CTD','WOD98 CTD2','WOD98 BOT','WOD98 BOT2','WOD98 XBT',...
	 'WOD98 XBT2','CSIRO','','NIWA'};
%vars = {'temp','salt','oxygen','silicate','phosphate','nitrate'};
vars = {'temp','salt','Oxygen','Si02','DIP','NO3'};
fvars = {'temperature','salt','oxygen','silicate','phosphate','nitrate', ...
		    ' FINISH '};
unitl = {' (^oC)',' (PSU)',' (mg/m^3)',' (\muM)',' (mg/m^3)',' (mg/m^3)',''};

% Convert casts to model units
untsc = [1 1 (1/.00143) 1 30.97 14];

regsel = {'As is','Entire model domain','Input new region','Select on map'};


jj = menu('Property to validate',fvars);

while jj<7

   figure(figs(1))
   axes(timh);
   if ~isempty(tloch); delete(tloch); tloch = []; end
   axes(maph);
   if ~isempty(loch); delete(loch); loch = []; end
   if ~isempty(curh); delete(curh); curh = []; end
   kk = menu('Region Selection',regsel);
   switch kk
     case 1
       % leave as is
     case 2
       src = fulsrc;
     case 3
       src = [];
       while isempty(src)
	  src = input('Enter w e s n in [], eg [100 120 -45 -30] : '); 
	  if length(src)<4 | ~(src(2)>src(1) & src(4)>src(3))
	     src = [];
	  end
       end
     case 4
       src = get_reg(figs(1));   
   end

   if min(size(src))==1
      xs = src([1 2 2 1]);
      ys = src([4 4 3 3]);
      src = [xs(:) ys(:)];
   end
   if ~isempty(regh); delete(regh); end
   regh = plot(src([1:end 1],1),src([1:end 1],2),'k--');
   
   
   disp(['Extracting ' fvars{jj} ' fields & casts'])
   vv = nc{vars{jj}}(:);
   if isempty(vv)
      disp(['No ' vars{jj} ' model fields'])
      ndat = 0;
   else
      
      %-  Don't know why this was ever here!!?
      % rej = find(vv>1000);
      % vv(rej) = repmat(nan,size(rej));
      % clear rej
      
      if jj==1
	 ftyp = [1:5 7 9];
      elseif jj==2
	 ftyp = [1:4 7 9];      
      else
	 ftyp = [3 4 7 9];
      end
      [lat,lon,cpn,tim,ftyp,vc] = get_all_csl(src,[1 2 9],jj,ftyp,[1:mxd]);
      ndat = length(lat);
   end
   
   if ndat==0
      disp(['No ' vars{jj} ' casts found in region'])
   else
      tin = find(tim>trng(1) & tim<trng(2)); 
      ndat = length(tin);
      disp([num2str(ndat) ' ' vars{jj} ' casts found in time & space domain'])
   end

   
   if ndat>0
      lat = lat(tin);
      lon = lon(tin);
      cpn = cpn(tin);
      tim = tim(tin);
      ftyp = ftyp(tin);
      vc = vc(tin,:).*untsc(jj);
      
      intp = interpJD(lat,lon,tim,la,lo,tm,vv);
      
      figure(figs(1))
      axes(maph)
      loch = plot(lon,lat,'b+');
      mph = []; curh = [];
      
      axes(timh)
      tloch = plot(tim/365,.3,'ro');
      if ~isempty(tmh); delete(tmh); tmh = []; end
        
      % Set up axes for indivdual cast plots
      figure(figs(2))
      clf
      proh = axes('position',[.13 .1 .85 .81]);
      
      xlim = input('Property range for plots eg [34.1 35.7]. Hit Enter to auto-scale : ');
      if length(xlim) == 2
	 if ~(xlim(2)>xlim(1))
	    disp([7 'Can only accept LH < RH limits. Now auto-scaling plots']);
	    xlim = [];
	 end
      else
	 xlim = [];
      end
	    
      ylim = input('Depth limits for profiles eg [0 1000]. Hit Enter to auto-scale : ');
      if length(ylim) == 2
	 ii = find(ylim>0);
	 ylim(ii) = -ylim(ii);
	 ylim = [min(ylim) max(ylim)];
      else
	 ylim = [];
      end

      % View individual profiles
      
      inlst = 1:ndat;

      [nxt,inlst] = next_prof(1,inlst,lat,lon,[],figs,maph);

      while nxt <= length(inlst)

	 figure(figs(1))
	 axes(maph);
	 if ~isempty(curh); delete(curh); end 
	 if ~isempty(mph); delete(mph); end
	 ii = inlst(nxt);
	 inlst(nxt) = [];
	 mph = plot(lon(inlst),lat(inlst),'r+');
	 curh = plot(lon(ii),lat(ii),'go','markersize',12);

	 axes(timh);
	 if ~isempty(tmh); delete(tmh); end 
	 tmh = plot(tim(ii)/365,.1,'b^','markersize',18);

	 
	 % Plot individual profiles
	 figure(figs(2))
	 hold off
	 mcd = max(indx.*~isnan(vc(ii,:)));  	 % Find deepest level with data
	 plot(vc(ii,1:mcd),-deps(1:mcd),'ro');
	 grid
	 hold on
	 ctim = time2greg(tim(ii));
	 cstr = sprintf('%2d/%2d/%4d %0.2d:%0.2d',ctim([3 2 1 4 5]));

	 clat = {'S','N'};
	 clon = {'W','E'};

	 title([fvars{jj} unitl{jj} '  '  num2str(abs(lon(ii))) clon{1+(lon(ii)>0)} ...
		'  ' num2str(abs(lat(ii))) clat{1+(lat(ii)>0)} '   ' cstr]);
	 disp([ftyps{ftyp(ii)} ', cast ' num2str(ii) ', CPN ' num2str(cpn(ii))]);
	 
	 mmcd = max(find(zc>deps(mcd)));
	 if isempty(mmcd); mmcd = nz; end
	 plot(intp(ii,mmcd:nz),-zc(mmcd:nz),'k--','linewidth',2);
	 aa = axis;
	 if ~isempty(xlim)
	    aa(1:2) = xlim;
	 end
	 if ~isempty(ylim)
	    aa(3:4) = ylim;
	 else
	    aa(3) = -1.05*deps(mcd);
	 end
	 axis(aa);
	 legend({'observed','model'},0);
	 xlabel([fvars{jj} unitl{jj}]);
	 ylabel('Depth (m)');
	 
	 fnm = [fvars{jj} '_' num2str(cpn(ii)) '.eps'];
	 
	 % Ask which profile to plot next	 
	 [nxt,inlst] = next_prof(nxt,inlst,lat,lon,fnm,figs,maph);
      
      end     % looping through casts

      
      
      % Save casts to file

      outfl = [vars{jj} '_casts'];
      ss = input('Save profiles to file: m=mat-file, a=ASCII, [default=neither] : ','s');
      if isempty(ss)
	 % do nothing - don't want to save casts
      else
	 sofl = input(['Name for output file [' outfl '] : '],'s');
	 if ~isempty(sofl)
	    outfl = sofl;
	 end
	 if ss=='a' | ss=='A'
	    % Save to ASCII file
	    asc_save = 1;
	    fid = fopen(outfl,'w');
	    for ii = 1:ndat
	       ctim = time2greg(tim(ii));
	       fprintf(fid,'%5d%10d%8.3f%8.3f%3d  %2d/%0.2d/%4d %0.2d:%0.2d\n',...
		       ii,cpn(ii),lon(ii),lat(ii),ftyp(ii),ctim([3 2 1 4 5]));
	       ll = find(~isnan(vc(ii,:)));
	       fprintf(fid,'%4d %10.3f\n',[deps(ll); vc(ii,ll)]);
	    end
	    fclose(fid);
	 else
	    % Save to mat-file
	    save(outfl,'lon','lat','tim','cpn','ftyp','vc','deps'); 
	 end
      end

      
      % Calculate and report stats

      ss = input('Prepare summary stats [y] : ','s');
      if ~isempty(ss) & (ss=='n' | ss=='N')
	 % do not generate stats
      else
	 vcm = interp1(deps,vc',zc)';
	 
	 cdif = intp-vcm;
	 mndif = nanmean(cdif);
	 sdif =  nanstd(cdif);
	 cnts = sum(~isnan(cdif));
	 
	 figure(figs(6))
	 clf
	 subplot('position',[.13 .11 .84 .84]);
	 plot(mndif,-zc,'r')
	 hold on;
	 grid
	 % title('Stats of Model minus Data at each level')
	 plot(mndif+nanstd(cdif),-zc,'k--')
	 plot(mndif-nanstd(cdif),-zc,'k--')
	 legend({'Mean','Standard deviation'},0);
	 xlabel(['model minus observed ' fvars{jj} unitl{jj}]);
	 ylabel('depth (m)')
	 a1 = axis;
	 mxc = max(zc.*~~(cnts(:)));    % Find deepest level with data
	 a1(3) = -1.05*mxc;
	 axis(a1);
	 

	 figure(figs(3))
	 clf
	 subplot('position',[.09 .1 .38 .86]);
	 barh(-zc,cnts(:));
	 a2 = axis;
	 axis([a2(1:2) a1(3:4)]);
	 xlabel('Number of comparison samples')
	 ylabel('Depth (m)')
	 
	 disp('Casts are interpolated to model depths for comparison');
	 subplot('position',[.5 .06 .47 .87]);
	 set(gca,'Xtick',[]);
	 set(gca,'Ytick',[]);
	 title('Stats of Model minus Data at each level')
	 axis([0 5 0 nz+1])
	 for nn = 1:nz
	    y = nn-.6;
	    text(0.1,y,num2str(nn));
	    text(.8,y,num2str(zc(nn)));
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
	 
	 % Loop, markerplot'ing differences at requested levels.
	 % ncl is new valid level to display, and icl is presently displayed
	 % level (which may then be saved to eps file.)
	 
	 icl = 0;
	 disp(['To view a level (1-' num2str(nz) '), enter its number, OR to'...
	       ' save plots enter p s OR m -']);
	 ss = input('p:stats_profile, s:scatter, m:map [OR just hit Enter to FINISH] : ','s');

	 while ~isempty(ss)
	    ncl = 0;
	    if ss=='s'
	       if icl>0
		  figure(figs(5))
		  fnm = [vars{jj} '_' num2str(zc(icl)) '_s.eps'];
		  set_axes;
		  print('-depsc','-tiff',fnm);
		  disp(['Scatter plot saved to file ' fnm]);
	       end
	    elseif ss=='m'
	       if icl>0
		  figure(figs(4))
		  fnm = [vars{jj} '_' num2str(zc(icl)) '_m.eps'];
		  set_axes;
		  print('-depsc','-tiff',fnm);
		  disp(['Map of differences plot saved to file ' fnm]);
	       end
	    elseif ss=='p'
	       figure(figs(6))
	       fnm = [vars{jj} '_stats_p.eps'];
	       set_axes;
	       print('-depsc','-tiff',fnm);
	       disp(['Statistics profile plot of saved to file ' fnm]);
	    else
	       tmp = str2double(ss);
	       if tmp>0 & tmp<=nz 
		  if cnts(tmp)
		     ncl = tmp;
		  else
		     disp('No comparison data in that level!');
		  end
	       else
		  disp([7 'That input did not make sense!'])
	       end
	    end
	    if ncl
	       icl = ncl;
	       
	       figure(figs(4))
	       subplot('position',[.08 .2 .85 .7]);
	       cla;
	       kk = find(cdif(:,icl)>=0);
	       rng = max(abs(cdif(:,icl)));
	       mrng = [1 16];
	       markerplot(lon(kk),lat(kk),cdif(kk,icl),'v',[0 rng],mrng);
	       kk = find(cdif(:,icl)<0);
	       markerplot(lon(kk),lat(kk),-cdif(kk,icl),'o',[0 rng],mrng);
	       axis(mapax);
	       gebco
	       title(['Model minus observed ' fvars{jj} unitl{jj} ' at depth ' num2str(zc(icl)) 'm']);	    
	       
	       % Organise a scale the hard way. "legend" distorts the marker
	       % sizes to fit in the box, and so cannot be used as a scale.
%	       subplot('position',[.08 .07 .85 .05]);
	       subplot('position',[.08 .1 .85 .05]);
	       cla;
	       axis([-1.1*rng 1.1*rng -1 1]);	    
	       plot(0,0,'v','markersize',1);
	       hold on;	    
	       for rsc = 2:2:16
		  plot(rsc*(rng/16),0,'v','markersize',rsc);
	       end
	       for rsc = 2:2:16
		  plot(-rsc*(rng/16),0,'o','markersize',rsc);
	       end
	       set(gca,'ytick',[]);
	       xlabel(['model low          ' fvars{jj} '          model high']);

	       
	       figure(figs(5));
	       hold off;
	       ll = find(~isnan(intp(:,icl)+vcm(:,icl)));
	       plot(intp(ll,icl),vcm(ll,icl),'o');
	       hold on;
	       xlabel(['Model ' fvars{jj} unitl{jj}]);
	       ylabel(['Observed ' fvars{jj} unitl{jj}]);

	       % title(['Cast vs Model ' fvars{jj} ' for depth ' num2str(zc(icl))]);
	       a2 = axis;
	       a3 = [min(a2([1 3])) max(a2([2 4]))];
	       axis([a3 a3]);
	       xa = a3(1) + (a3(2)-a3(1))/20;
	       ya = a3(2) - (a3(2)-a3(1))/10;
	       text(xa,ya,['depth = ' num2str(zc(icl)) ' m']);
	       plot(a3,a3,'k--');
	       grid
	    end
	    
	    
	    disp(['To view a level (1-' num2str(nz) '), enter its number, OR to'...
		  ' save plots enter p s OR m -']);
	    ss = input('p:stats_profile, s:scatter, m:map [OR just hit Enter to FINISH] : ','s');
	 end      
      end     % if calculate and report stats
      

   end     % if there are model fields and casts for this property

   jj = menu('Property to validate',fvars);
end     % Choosing properties to compare


if asc_save
   disp('ASCII output format:')
   disp(' Header records:  ID  CPN  Lon  Lat  DataType  Date/Time') 
   disp(' Data records:   depth(m)  value')
end

if add_dunn
   rmpath /home/dunn/matlab/
end
if add_hesm
   rmpath /home/eez_data/software/matlab/
end

set(0,'defaultaxesfontsize',defafs);
set(0,'defaulttextfontsize',deftfs);

return

%===========================================================================
% NEXT_PROF  Get index (in 'inlst') to next profile to plot.
%
% NOTE: when the previous profile was used it was removed from inlst, so
%       setting nxt=in has the effect of incrementing the profile number.

function [nxt,lst] = next_prof(in,inlst,lat,lon,fnm,figs,maph)

ndat = length(lon);
nxt = [];

if isempty(inlst)
   disp('Have been through all profiles - resetting list to all casts');
   lst = 1:ndat;
   in = 1;
else
   lst = inlst;
end


while isempty(nxt)
   ss = input(['f:finish, s:select, r:refresh list, p:save plot, OR profile number [next] : '],'s');
   if isempty(ss)
      if in>length(lst)
	 nxt = 1;
      else
	 nxt = in;
      end
   elseif ss == 'p'
      if ~isempty(fnm)
	 figure(figs(2));
	 print('-depsc','-tiff',fnm);
      end
   elseif ss == 'f'
      % Setup to fail the while loop test (nxt<=ndat)
      nxt = ndat+1;
   elseif ss == 'r'
      lst = 1:ndat;
      in = 1;
      nxt = [];
   elseif ss == 's'
      disp('Click mouse on cast to select')
      figure(figs(1));
      axes(maph);
      nxt = closest(lon(lst),lat(lst),ginput(1));
   else
      ii = str2double(ss);
      if isnan(ii) | ii<1 | ii>length(lst)
	 disp([7 'Out of range or could not decode that - try again.'])
	 nxt = [];
      else
	 nxt = find(lst==ii);
	 if isempty(nxt)
	    lst = [lst ii];
	    nxt = length(lst);
	 end
      end
   end
end

return

%===========================================================================
% GET_REG  Let user define region using rubberband box on map
%
% 

function reg = get_reg(fig)

disp('    Draw rubber band box on map (click and drag mouse), then WAIT')
zoom off;

% Use no-side effect WAITFORBUTTONPRESS
waserr = 0;
eval('keydown = wfbp;', 'waserr = 1;');
if(waserr == 1)
   if(ishandle(fig))
      set(fig,'pointer',pointer,'units',fig_units);
      error('Interrupted');
   else
      error('Interrupted by figure deletion');
   end
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

%===========================================================================
% INTERPJD  Interpolate model output to cast, in time and x-y space. When
%  needed, we interpolate the cast to the model depths (because we know that
%  the cast's standard levels are nicely spaced for interpolation.)
%

function intp = interpJD(lat,lon,tim,la,lo,tm,vv)

nz = size(vv,2);

intp = repmat(nan,[length(lat) nz]);

for ii=1:length(lat)

   % Find model timesteps before and after cast time.
   t2 = [];
   jj = find(tm<tim(ii));
   if ~isempty(jj)
      t1 = jj(end);
      if t1~=length(tm)
	 t2 = t1+1;
      end
   else
      t1 = 1;
   end

   % Find nearest 4 model grid points
   lc = cos(lat(ii)*pi/180);
   rr = (lat(ii)-la).^2 + (lc.*(lon(ii)-lo)).^2;
   jj = 1:prod(size(rr));
   for kk = 1:4
      [tmp,i4(kk)] = min(rr(jj));
      jj(i4(kk)) = [];
   end

   maxr = 1.05.*max(rr(i4));
   ww = 1-(rr(i4)./maxr);

   vtmp = reshape(vv(t1,:,:,:),[nz prod(size(la))]);
   vtmp = vtmp(:,i4);
   
   rwgt = ~isnan(vtmp)*ww(:);

   kk = find(isnan(vtmp));
   vtmp(kk) = zeros(size(kk));
   dat = vtmp*ww(:);
   
   if ~isempty(t2)
      % If model timesteps straddle cast time, interpolate in time
      tdf = tm(t2)-tm(t1);
      t1w = abs(tim(ii)-tm(t1))/tdf;
      t2w = abs(tim(ii)-tm(t2))/tdf;
      rwgt = rwgt.*t1w;
      dat = dat.*t1w;
      
      vtmp = reshape(vv(t2,:,:,:),[nz prod(size(la))]);
      vtmp = vtmp(:,i4);
   
      rwgt = rwgt + t2w.*(~isnan(vtmp)*ww(:));

      vtmp(kk) = zeros(size(kk));
      dat = dat + t2w.*(vtmp*ww(:));
   end

   ll = find(rwgt>0.0001);
   intp(ii,ll) = (dat(ll)./rwgt(ll))';
end

return
%---------------------------------------------------------------------------
function set_axes

ss = input('Want to adjust axes [n] : ','s');
if isempty(ss) | ss=='n' | ss=='N'
   % do nothing
else
   aa = axis;
   nn = input(['X axis limits [' num2str(aa(1:2)) '] : ']);
   if length(nn) == 2
      aa(1:2) = nn;
   end
   nn = input(['Y axis limits [' num2str(aa(3:4)) '] : ']);
   if length(nn) == 2
      aa(3:4) = nn;
   end
   axis(aa);
end

return
%--------------------------------------------------------------------------
