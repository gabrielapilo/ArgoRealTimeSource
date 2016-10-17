
% TIME_SECTION_PLOT  
%
% INPUT: fpp - struct array for the float
%
% OUTPUT: 
%    Files:  S_WMO.tif   T_WMO.tif
%
% AUTHOR: Jeff Dunn CMAR/BoM  Oct 2006   (evolved from time_plot.m)
%
% CALLED BY:  Argo main program. Can be used standalone
% 
% USAGE:  time_section_plot(fpp)

function time_section_plot(fpp)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

dep=[2000:-100:1000 920:-60:500 480:-20:100 90:-10:10 5];

nprof = length(fpp);

while isempty(fpp(nprof).datetime_vec)
    nprof=nprof-1;
end
if nprof<2
   % Cannot do a section with only one profile
   return
end

fwmo = num2str(fpp(1).wmo_id);
if ispc
fpth = [ARGO_SYS_PARAM.web_dir 'floats\' fwmo];
else
fpth = [ARGO_SYS_PARAM.web_dir 'floats/' fwmo];
end
if ~exist(fpth,'dir')
   system(['mkdir ' fpth '; chmod -f ugo+rx ' fpth]);
end

%sometimes first profile is empty:
jj=1;
while(isempty(fpp(jj).datetime_vec))
    jj=jj+1;
end

% Time (x) axis from start of 1st year to end of last year. 
% Ticks every month (365.25/12 days)
yrs = fpp(jj).datetime_vec(1,1):fpp(nprof).datetime_vec(1,1);
xlim = [julian(yrs(1),1,1)  julian(yrs(end),12,31)];
ttic = xlim(1):(365.25/12):xlim(2);

xll = ['J';'F';'M';'A';'M';'J';'J';'A';'S';'O';'N';'D'];
labels = {'Temperature','Salinity','Potential Density anomoly','Oxygen'};
unts = {'^oC','psu','\sigma_0','micromole/kg'};
fpre = {'T','S','PD','O2'};

% Want to keep NaNs where missing profiles or gaps in profiles. Better to see
% gaps rather than interpolate through them and be deluded.
% Also, P has been screened, so no need to test for inversions.

for kk = 1:nprof
   pcal{kk} = qc_apply(fpp(kk).p_calibrate,fpp(kk).p_qc);
end

% Adjusted to include density section - Rebecca Cowley March 2007
for var = 1:4
    if var==1
        cax = [-4 30];
        col = -2:1:30;
    elseif var==2
        cax = [33 36];
        col = 33.1:.1:35.7;
    elseif var==3
        cax = [20 30];
        col = 20:.4:30;
    elseif var==4
        if isfield(fpp,'oxy_raw')
            cax = [50 300];
            col = 50:10:300;
        else
            return
        end
    end
    V = repmat(nan,[nprof length(dep)]);
    time = repmat(nan,[nprof 1]);
    
    druck2=0;
    druck=0;
    for kk = 1:nprof
        if(~isempty(fpp(kk).p_calibrate))
            if(max(fpp(kk).p_calibrate)<3000 & ~druck2)
                if var==1
                    vv = qc_apply(fpp(kk).t_raw,fpp(kk).t_qc);
                elseif var==2
                    vv = qc_apply(fpp(kk).s_calibrate,fpp(kk).s_qc);
                elseif var==3
                    vt = qc_apply(fpp(kk).t_raw,fpp(kk).t_qc);
                    vs = qc_apply(fpp(kk).s_calibrate,fpp(kk).s_qc);
                    %calculate potential temp
                    if(~isempty(vs) & ~isempty(vt))
                        pt = sw_ptmp(vs,vt,pcal{kk},0);
                        vv = sw_pden(vs,pt,pcal{kk},0)-1000;
                    end
                elseif var==4 & isfield(fpp,'oxy_raw')
                    vv = qc_apply(fpp(kk).oxy_raw,fpp(kk).oxy_qc);
                end
                if ~isempty(vv)
                    if(length(vv)==length(pcal{kk}))
                        jj = find(~isnan(vv) & ~isnan(pcal{kk}));
                        if length(jj)>1 & any((diff(fpp(kk).p_raw))<0)
                            if(any(diff(fpp(kk).p_raw(jj))==0))
                                [b,i,j]=unique(fpp(kk).p_raw(jj));
                                jj=i;
                            end
                            if(max(diff(fpp(kk).p_raw(jj))<0.5))
                                try
                                    V(kk,:)=interp1(pcal{kk}(jj),vv(jj),dep);
                                end
                            end
                        end
                    else  %float with subsampled oxygen - different variables:
                        try
                            jj = find(~isnan(vv) & ~isnan(fpp(kk).p_oxygen));
                            V(kk,:)=interp1(fpp(kk).p_oxygen(jj),vv(jj),dep);
                        end
                    end
                end
                if ~isempty(fpp(kk).jday)
                    time(kk) = fpp(kk).jday(1);
                end
            elseif druck
                druck2=1;
            else
                druck=1;
            end
        end
    end
    gg = find(~isnan(time));
    if length(gg)<2 | isnan(V)
        % Cannot do a section with only one profile
        return
    end
    
    jj=find(~isnan(V));
    if(~isempty(jj))
        % Deep section (500-2000dB)
        
        H = figure(1);
        clf;
        %   orient tall;
        set(H,'PaperPosition',[0 0 4.7 5.6])      % Controls final image size?
        axes('position',[.1 .15 .8 .35])
        try
        contourf(time(gg),-dep,V(gg,:)',col);
        end
        caxis(cax)
        hold on
        shading faceted
        axis([xlim -2000 -500]);
        set(gca,'ytick',-2000:500:-500);
        ylabel('Depth (db)','fontsize',12)
        set(gca,'xtick',ttic);
        set(gca,'xticklabel',xll);
        set(gca,'tickdir','out')
        
        for iyr = yrs
            midyr = 6 + 12*(iyr-yrs(1));
            text(ttic(midyr),-400,num2str(iyr),'fontsize',10);
        end
    end
    % Shallow section (0-500-dB)
    
    axes('position',[.1 .55 .8 .35]);
    try
    contourf(time(gg),-dep,V(gg,:)',col);
    end
    caxis(cax);
    hold on
    shading faceted
    axis([xlim -500 0]);
    set(gca,'ytick',-500:100:0);
    ylabel('Depth (db)','fontsize',10)
    set(gca,'xtick',ttic);
    %   set(gca,'xticklabel',xll);
    set(gca,'tickdir','out')
    set(gca,'XTickLabel',[]);
    
    title([labels{var} ' ' fwmo],'fontsize',14);  %,'fontweight','bold');
    
    
    % Colourbar
    
    axes('position',[.2 .05 .6 .03])
    contourf(col,[-1 1],[col' col']',col);
    caxis(cax);
    shading faceted
    %   set(gca,'xtick',col(2:2:end));
    set(gca,'ytick',-5:10:5);
    set(gca,'tickdir','out');
    %   xlabel(unts{var},'fontsize',12)
    if ispc
        print('-dtiff',[fpth '\' fpre{var} '_' fwmo]);
        system(['chmod -f 664 ' fpth '\*.tif']);
    else
        my_save_fig([fpth '/' fpre{var} '_' fwmo ],'clobber')
        system(['chmod -f 664 ' fpth '/*if']);
    end
    
end


%----------------------------------------------------------------------
