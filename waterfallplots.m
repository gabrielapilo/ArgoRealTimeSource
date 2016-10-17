% WATERFALLPLOTS  Create timeseries of offset profiles for one float.
%  
% INPUT: fpp - struct array for the float
%
% OUTPUT:
%   Files   S_WMO_waterfall.tif  T_WMO_waterfall.tif PD_WMO_waterfall.tif
%
% AUTHOR: Jeff Dunn CMAR/BoM  Oct 2006  (evolved from earlier waterfallplots.m)
%
% CALLED BY:  Argo main program. Can be used standalone
% 
% USAGE: waterfallplots(fpp)

function waterfallplots(fpp)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

fwmo = num2str(fpp(end).wmo_id);
fpth = [ARGO_SYS_PARAM.web_dir 'floats/' fwmo '/'];
nprof = length(fpp);

cols = {'k','r','g','b','c'};

H = figure(8);
clf
set(H,'PaperPosition',[0 0 4.5 3])      % Controls final image size
axes('position',[.13 .1 .85 .7])
axis ij       % so that yaxis has 0 at the top
hold on
oset = 2;     % offset (x increment) between consecutive profiles

mxtt = [];
for kk = 1:nprof
   tt = qc_apply(fpp(kk).t_raw,fpp(kk).t_qc);
   ic = mod(kk,5)+1;
   if ~isempty(tt) & ~all(isnan(tt))
      plot(tt+oset*(kk-1),fpp(kk).p_calibrate,cols{ic});
      if ic==1
	 text(tt(1)+oset*(kk-1.2),1900,num2str(kk));  %fpp(kk).p_calibrate(end),num2str(kk));
      end
      mxtt = max(tt);
   end
end

if ~isempty(mxtt)
   axis([min(mxtt-1,0) max(mxtt,1)+1+oset*(nprof-1) 0 2000]);
end
set(gca,'XTickLabel',[]);
%xlabel('Temperature','fontsize',10);
xlabel('Profile number','fontsize',10);
ylabel('Depth (db)','fontsize',12);
title(['Argo ' fwmo ' Temperature (^oC) profiles']);

fnm = [fpth 'T_' fwmo '_waterfall'];
if(ispc)
    print('-dtiff',fnm);
else
    my_save_fig([fnm],'clobber')
end

clf
axes('position',[.13 .2 .85 .7])
axis ij       % so that yaxis has 0 at the top
hold on
oset = .05;     % offset (x increment) between consecutive profiles

mxss = [];
for kk = 1:nprof
   ss = qc_apply(fpp(kk).s_calibrate,fpp(kk).s_qc);
   ic = mod(kk,5)+1;
   if ~isempty(ss) & ~all(isnan(ss))
      plot(ss+oset*(kk-1),fpp(kk).p_calibrate,cols{ic});
      if ic==1
	 text(ss(1)+oset*(kk-1.2),1900,num2str(kk));  %fpp(kk).p_calibrate(end),num2str(kk));
      end
      mxss = max(ss);
   end
end

if ~isempty(mxss) & mxss>33.6
   axis([33.6 mxss+.25+oset*(nprof-1) 0 2000]);
end
set(gca,'XTickLabel',[]);
%xlabel('Salinity (psu)','fontsize',10);
xlabel('Profile number','fontsize',10);
ylabel('Depth (db)','fontsize',12);
title(['Argo ' fwmo ' Salinity (psu) profiles']);

fnm = [fpth 'S_' fwmo '_waterfall'];
if(ispc)
    print('-dtiff',fnm);
else
    my_save_fig([fnm],'clobber')
end

% add oxygen plots if available: AT July 2008

if(isfield(fpp,'oxy_raw'))
     clf
    axes('position',[.13 .2 .85 .7])
    axis ij       % so that yaxis has 0 at the top
    hold on
    oset2=10.;
   mxo2 = [];
    for kk = 1:nprof
       o2 = qc_apply(fpp(kk).oxy_raw,fpp(kk).oxy_qc);
       ic = mod(kk,5)+1;
       if ~isempty(o2) & ~all(isnan(o2))
           if(isfield(fpp,'p_oxygen') & ~isempty(fpp(kk).p_oxygen) & length(fpp(kk).p_oxygen)==length(o2))
               plot(o2+oset2*(kk-1),fpp(kk).p_oxygen,cols{ic});
           else
               plot(o2+oset2*(kk-1),fpp(kk).p_calibrate,cols{ic});
           end
           if ic==1
         text(o2(1)+oset2*(kk-1.2),1900,num2str(kk));  %fpp(kk).p_calibrate(end),num2str(kk));
          end
          mxss = max(o2);
       end
    end

    if ~isempty(mxo2) & mxo2>50
       axis([50 mxo2+.25+oset2*(nprof-1) 0 2000]);
    end
    set(gca,'XTickLabel',[]);
    %xlabel('Salinity (psu)','fontsize',10);
    xlabel('Profile number','fontsize',10);
    ylabel('Depth (db)','fontsize',12);
    title(['Argo ' fwmo ' Oxygen profiles']);

    fnm = [fpth 'O2_' fwmo '_waterfall'];
    if(ispc)
        print('-dtiff',fnm);
    else
        my_save_fig([fnm],'clobber')
    end
end

% include potential density plots 
%Rebecca Cowley March 2007
clf
axes('position',[.13 .2 .85 .7])
axis ij       % so that yaxis has 0 at the top
hold on
oset = .5;     % offset (x increment) between consecutive profiles

mxpd = [];
for kk = 1:nprof
   ss = qc_apply(fpp(kk).s_calibrate,fpp(kk).s_qc);
   tt = qc_apply(fpp(kk).t_raw,fpp(kk).t_qc);
   if(length(ss)==length(tt) & length(tt)==length(fpp(kk).p_calibrate))
       pt = sw_ptmp(ss,tt,fpp(kk).p_calibrate,0);
       pd = sw_pden(ss,pt,fpp(kk).p_calibrate,0)-1000;
       ic = mod(kk,5)+1;
       if ~isempty(pd) & ~all(isnan(pd))
          plot(pd+oset*(kk-1),fpp(kk).p_calibrate,cols{ic});
          if ic==1
         text(pd(1)+oset*(kk-1.2),1900,num2str(kk));  %fpp(kk).p_calibrate(end),num2str(kk));
          end
          mxpd = max(pd);
       end
   end
end

if ~isempty(mxpd) & mxpd>20
   axis([20 mxpd+.25+oset*(nprof-1) 0 2000]);
end
set(gca,'XTickLabel',[]);
%xlabel(texlabel('Potential Density Anomoly (sigma_0)'),'fontsize',10);
xlabel('Profile number','fontsize',10);
ylabel('Depth (db)','fontsize',12);
title(['Argo ' fwmo 'Potential Density Anomoly (sigma_0)']);

fnm = [fpth 'PD_' fwmo '_waterfall'];
if(ispc)
    print('-dtiff',fnm);
else
    my_save_fig([fnm],'clobber')
end

system(['chmod -f 664 ' fpth '*if']);


%-------------------------------------------------------------------------
