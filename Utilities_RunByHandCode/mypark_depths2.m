% finds safe park depths for solos and apex floats for float deployments
% from NODC data organized by Jeff Dunn
%
% uses climatological casts for deep part but replaces surface values 
% with true observed surface data , not the average
% god bless Jeff Dunn for making this so easy
%
% from surface_dens we have =already loaded in the upper 50m of 
% historical casts
%
% Edited 22-03-05 SEW CSIRO Marine
%   . changed APEX displacement to 245ml
%   . included a plot of safe park vs locations
%   . screen for and toss data on shelves.
%
% NOTE: use /home/argo/matlab/ballast/surface_dens_AT to update
%     raw_sfc_obs.mat  NOTE: NOW IN ArgoRT/src!!!


addpath /home/eez_data/software/matlab

% want print results into files?
iprint = 1

%change this to read each block as required - to limit size of raw_sfc_obs
%files:
%if ~exist('la'),load('raw_sfc_obs.mat'),end

% set up stddeps
sdep = [0:10:30,50:25:150,200:50:300,400:100:1500,1750,2000:500:5000]

% ok look at specific float locations:
%name_fl = ['A','B','C','D','E','F','G','H','I','J'];
%x_fl=[113., 117.5,121, 116.5,112.,116,109,107,106,105];
%y_fl=[-17,-17,-12,-12,-12,-9,-17,-12,-9,-7];

% Positions of 6 SO floats to be moved to Great Aust Bight.
%y_fl = [-45.5 -50 -52 -54 -56 -47 -40.1 -39.7 -39.2 -38.6 -37.8 -37.0];
%x_fl = [145.5 141 139 137 134 151 140.1 136.3 132.6 128.9 125.3 121.8];
% Positions of IX1 and 3 navy floats 12-8-2004


% load ('ArgoDepPlans2015_6_forgoogle.csv')
% holddepy=ArgoDepPlans2015_6_forgoogle(:,1);
% holddepx=ArgoDepPlans2015_6_forgoogle(:,2);

% holddepy(11)=-9.25;
% holddepy(33)=-47.5;
%holddepy=[];holddepx=[];

% holddepy=-19.75
% holddepx=175.5
%holddepy=[-10:.2:-8];
%holddepx(1:length(holddepy))=106; 
x_fl=holddepx;
y_fl=holddepy;

%y_fl = [-22.5 -20.6 -18.6 -16.7 -14.8 -12.8 -10.9 -12.7 -12.6 -15.6];
%x_fl = [111.4 110.6 109.8 109.1 108.3 107.6 106.9 113.5 119.5 116.4];
clear name_fl
% for j=1:length(x_fl)
%     name_fl(j,:) = num2str(j);   %[int2str(floor(j/10)) int2str(rem(j,10))];
% end

% now look at each float:
for j2= 1:length(x_fl);
    % x_fl(48)=121.5
    %load raw_sfc_obs here now:
    x=floor(x_fl(j2)/10.)*10.;
    load(['/home/argo/ArgoRT/raw_sfc_obs_new_' num2str(x) '.mat']);
    j=j2

    special_text=[];
    % check for bottom depth!
    x2=rem(x_fl(j),10.);
    bot_fl(j) = -1*topongdc(y_fl(j),x_fl(j));
    if bot_fl(j2) > 2000,
        
        
        % get the historical climatological full depth cast:
        
        [aa,days,midd]=names_of_months;
        tc = get_clim_casts('t',x_fl(j),y_fl(j),sdep,midd,'cars2009',1);
        sc = get_clim_casts('s',x_fl(j),y_fl(j),sdep,midd,'cars2009',1);
        %tc = get_clim_casts('t',x_fl(j),y_fl(j),sdep,[],'filled');
        %sc = get_clim_casts('s',x_fl(j),y_fl(j),sdep,[],'filled');
        
        orient tall
        % extract good sfc data within 3 degrees
        ig = find(abs(la-y_fl(j)) <= 3. & abs(lon-x_fl(j)) <= 3. & ~isnan(s(1,j)) & ~isnan(t(1,j)));
        % get bottom depth at nearby obs. and toss data on the shelf:
        botdepth =  -1*topongdc(la(ig),lon(ig));
        ishallow = find(botdepth < 100);
        ig(ishallow) = [];
        % find nt least dens sfc values
        [val,im]=sort(den(1,ig)');
        nt = 300;
        if(nt>length(im));
            nt=length(im)
        end
        
        if nt==0
            disp(['No raw surface obs. for float ',num2str(j)])
            im=zeros(12,1);   %        im=0;
            nt=12;            %        nt=1;
            % continue with CARS profile only
        else
            im = ig(im(1:nt));
        end
        
        
        % now find safe park depths and volume displacements for 2000db
        % APEX
        p_A = NaN*ones(1,nt);
        dV_A = NaN*ones(1,nt);
        
        orient landscape
        clf
        subplot(221)
        hold on
        for n=1:nt
            k =im(n);
            if(k==0)
                tc = get_clim_casts('t',x_fl(j),y_fl(j),sdep,midd(n),'cars2009',1);
                sc = get_clim_casts('s',x_fl(j),y_fl(j),sdep,midd(n),'cars2009',1);
            end
            clear ss tt pp
            ii = find(~isnan(sc));
            ss = sc(ii); tt = tc(ii); pp = sdep(ii)';
            if ~isempty(ss)     %If there is CARS data continue
                if k>0          % There is surface data
                    jj = find(~isnan(s(:,k)) & ~isnan(t(:,k)) );
                    % Replace the top of the cars profile with the raw observations.  If there is no data in the raw profile then skip this one.
                    if ~isempty(jj)
                        ideep = find(pp>dep(jj(end),k));
                        ss = [s(jj,k);ss(ideep)];
                        tt = [t(jj,k);tt(ideep)];
                        pp = [dep(jj,k);pp(ideep)];
                    end
                else
                    % Continue with CARS profile only
                    special_text = 'CARS profile only!';
                end
                % APEX
                ddpp=diff(pp);
                ddkkpp=find(ddpp==0);
                
                if(~isempty(ddkkpp))
                    ss(ddkkpp(1))=[];
                    tt(ddkkpp(1))=[];
                    pp(ddkkpp(1))=[];
                end
                [dV,Vo]=float_compress(ss,tt,pp,25600,2.27e-6,6.9e-5);   %originally 27000
                % safe park
                
                [dV_sort,kk]=sort(dV);
                try
                    if(max(dV) < 245.)
                        p_A(n) = interp1(dV_sort,pp(kk),max(dV));
                    else
                        p_A(n) = interp1(dV_sort,pp(kk),245.);
                    end
                end
                try
                    if(max(pp(kk)) < 2000)
                        dV_A(n)=interp1(pp(kk),dV_sort,max(pp(kk)));
                    else
                        %            if(j==27);pp(1)=0;end
                        dV_A(n)=interp1(pp(kk),dV_sort,2000);
                    end
                    
                end
                plot(dV,-pp,'-')
                
            end
            
            
        end
        
        xlabel('Required Displacement(ml)')
        axis([0.,300.,-2500,0.]),grid
        ylabel('Depth (m)')
        
        if ~isempty(special_text)
            title([special_text,'   Float ',num2str(j),' at ',num2str(abs(y_fl(j))),'S,',num2str(x_fl(j)),'E'],'color','r','fontsize',14,'hor','left')
            if iprint == 1
                eval(['print -dpsc park_depths_',num2str(j),'.ps'])
                eval(['print -dtiff park_depths_',num2str(j),'.tif'])
                disp(['Printed park_depths_',num2str(j)])
            end
            
        else
            subplot(222)
            if diff(range(-p_A)) > 0,
                colourplot(lon(im),la(im),-p_A ,'.',min(-p_A),diff(range(-p_A)),10),hold on,gebco('k'),colorbar
            else
                plot(lon(im),la(im),'r.'),hold on,gebco('k')
            end
            
            xlabel('Longitude')
            ylabel('Latitude')
            title([' Float park info ',num2str(j),' at ',num2str(abs(y_fl(j))),'S,',num2str(x_fl(j)),'E'])
            
            subplot(223)
            plot(tim(im),-p_A,'^')
            v=axis;
            axis([1995,2015,v(3:4)])
            xlabel('Decimal Year')
            ylabel('Safe Park Pressure (dbar)')
            
            subplot(224)
            [np,xp]=hist(p_A,20);
            plot(xp,np)
            hold
            title('20 bin Park Depth Histogram')
            xlabel('Park Pressure (dbar)')
            ylabel('number of occurences')
            
            if iprint == 1
                eval(['print -dpsc park_depths_',num2str(j),'.ps'])
                eval(['print -dtiff park_depths_',num2str(j),'.tif'])
                disp(['Printed park_depths_',num2str(j)])
            end
        end
        pause (5)
    else
        display([' This float position is shallower than 2000m! ',num2str([j,x_fl(j),y_fl(j)])]),
        display([' NGDC bottom depth is ',num2str(bot_fl(j)),'m']),
    end
end


