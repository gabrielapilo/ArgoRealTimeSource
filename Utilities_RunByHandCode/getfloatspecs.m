%run with mypark_depths2

%holddepy=-45.92;
%holddepx=137.86;

% holddepy=[-62.5 -62 -60 -10 -27 -30]
% holddepx=[115 117.25 122.75 85.25 107 110]
% 
% load 'Book4.csv'
% load floatspecs_IMOS2012.csv
% f= [-46 147.75
% -48 147
% -50 146.25
% -52 145.75]
% 
%         %floatspecs_IMOS2012
% holddepy=K(:,1);
% holddepx=K(:,2);
% holddepy=reb(:,1)';
% holddepx=reb(:,2)';
% 
glat=holddepy;
glon=holddepx;

%glat=holddepy(33:52);
%glon=holddepx(33:52);


GLAT = glat';
GLON = glon';

% [rang1,ang] = sw_dist(glat,glon,'km');
% RANG=[nan rang1/1000];

data = [GLAT; GLON]'   %; RANG]';
% data = [GLAT;GLON];


% Get climatological data : temperature and salinity at 2000m
addpath /home/eez_data/software/matlab
sdp = [0;10;20;30;50;75;100;125;150;200;250;300;400;500;600;700;...
    800;900;1000;1100;1200;1300;1400;1500;1800;2000;2500];
[tc,out] = get_clim_profs('t',data(:,2),data(:,1),sdp,[],'cars2006',1);
[sc,out] = get_clim_profs('s',data(:,2),data(:,1),sdp,[],'cars2006',1);
figure
col = jet(length(data));
subplot(1,2,1)
hold on
[m,n]=size(data)
for l=1:m
    h2(l)=plot(tc(:,l),sdp,'-','color',col(l,:));
end
axis ij
xlabel('Potential Temperature (C)')
ylabel('Pressure (dbar)')
subplot(1,2,2)
hold on
for l=1:m
    plot(sc(:,l),sdp,'-','color',col(l,:))
end
axis ij
xlabel('Salinity (psu)')
ylabel('Pressure (dbar)')
%legend(h2,int2str([1:length(data)]'))

data2=[]

data2 = [data2 tc(1,:)' sc(1,:)' tc(19,:)' sc(19,:)' tc(26,:)' sc(26,:)'];  % Append cars t and s at surface, park depth (1000) and profile depth (2000)

% save float_pos_15-16.dat data2 -ascii
% glat=glat'
% glon=glon'

data3=[glat glon data2];
fnm=input('enter the name of the file for the data outputs:','s');
% save floatsdata13-14.txt data3 -ascii
save(fnm,'-ascii','data3')
completedata=data3  %[glat glon data2];
% save holddepdata12-13.mat holddepx holddepy
fnm2=[fnm(1:end-3) '.mat']
save(fnm2,'-mat','holddepx','holddepy');
% Find conditions at profile depth for floats that don't all go to 2000
%ifl = [31:36 59:64];    %IX1 and 6 navy floats
%ifl_pr = [2000 2000 2000 1900 1800 1650 1800 1800 2000 1650 2000 1800]

%ifl = [44 74];    %floats with extra sensors for southern ocean
%ifl_pr = [1500 1500]

%for k=1:length(ifl)
%    tpark(k) = interp1(sdp,tc(:,ifl(k)),ifl_pr(k));
%    spark(k) = interp1(sdp,sc(:,ifl(k)),ifl_pr(k));
%data2(ifl(k),5)=tpark(k);
%data2(ifl(k),6)=spark(k);
%end

title(['Float deployment planning to date ' date ' 14-15 floats'])
save_fig (['Float_deployment_planning_14-15.gif'])



  
