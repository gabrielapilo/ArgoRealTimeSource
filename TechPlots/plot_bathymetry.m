function ground = plot_bathymetry( float, H, H2,fnm)
global ARGO_SYS_PARAM;

%
%This funtion permits to plot information about the bathymetry of the
% float:
%
% Plot 1: evolution of depth and bathymetry through different cycles.
% Plot 2: geographical evolution of the float in regard with the
% bathymetry.
%

%%
%   --------------------------------------------------------
%   ----- PART 1: Evolution of depth and bathymetry --------
%   --------------------------------------------------------

%
% Extracting relevant parameters:
%
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

% Initialization of the important parameters:
lg = length(float);
latitude = nan(1,lg);
longitude = nan(1,lg);
pressure = nan(1,lg);
ground = nan(1,lg);

% Extraction of important parameters:
for index=1:lg
    %find the first occurrence of a good position
    order = [1,2,0,5,8,9,7]; %what is 7 for?
    [~,ia,~] = intersect(float(index).pos_qc,order);
    if isempty(ia)
        continue
    end
    latitude(index) = float(index).lat(ia);
    longitude(index) = float(index).lon(ia);
    if isfield(float,'ground')
        ground(index) = mean(float(index).grounded);
    end
    if length(max(float(index).p_raw)) > 0
        % Get the maximum pressure reached by the float.
        pressure(index) = max(float(index).p_raw);
    end
end

%
% Extract firstly the evolution of depth for the float.
%

depth = sw_dpth(pressure , latitude) ;

%
% Extract secondly the bathymetry around the position
%

% Initialization
bathy_depth = nan(1 , lg);
% Reading the the terrainbase.nc in order to have an idea of the
% bathymetry.
bathy = ncread(ARGO_SYS_PARAM.ocean_depth , 'height') ;
lon = ncread(ARGO_SYS_PARAM.ocean_depth , 'lon') ;
lat = ncread(ARGO_SYS_PARAM.ocean_depth , 'lat') ;


% Extraction:
for index = 1 : lg
    
    % Transforming the longitude and the latitude into index in order
    % to extract the bathymetry from terrainbase.nc
    lat_index = find(abs(latitude(index) - lat) <=0.05);
    lon_index = find(abs(longitude(index)-lon) <=0.05);

    % Extraction of the bathymetry.
    if ~isempty(lon_index) & ~isempty(lat_index)
        bathy_depth(index) = max(max(bathy(lon_index, lat_index))) ;
    end
    
end

%grounded?
ground = depth >= -1*bathy_depth;
%
% Realise the final plot
%
figure(H)
subplot('Position',[lft(2) bot(2) wid hgt]);

% The depth appears in orange
plot([1:lg] , -1 * depth , '-','color',[1 , 0.5 , 0]) ;
hold on
% The bathymetry appears in black
plot([2 : lg+1] , bathy_depth , '-','color','black','LineWidth',2) ;

title('Bathymetry and depth');
xlabel('Cycle');
ylabel('Depth');

figure(H2)
% The depth appears in orange
plot([1:lg] , -1 * depth , '-','color',[1 , 0.5 , 0]) ;
hold on
% The bathymetry appears in black
plot([2 : lg+1] , bathy_depth , '-','color','black','LineWidth',2) ;

title('Bathymetry and depth');
xlabel('Cycle');
ylabel('Depth');
my_save_fig([fnm '/depth_bathy'],'clobber')
clf

%%
%   ---------------------------------------------------------
%   ----- PART 2: Greographical evolution of bathymetry -----
%   ---------------------------------------------------------
%

% Determine the bathymetry around the position of the float:
col=jet(100);
fname = ARGO_SYS_PARAM.ocean_depth;

% Set limits of mapping where lat and lon are an array of positions

lla=range(latitude);
llo=range(longitude);
xlimit=[llo(1)-5 llo(2)+5];
ylimit=[lla(1)-5 lla(2)+5];

xb = ncread(fname,'lon');
yb = ncread(fname,'lat');

v=[xlimit ylimit];

ix = find(xb > v(1) & xb < v(2));
iy = find(yb > v(3) & yb < v(4));

% Determine the bathymetry in the area of the float.
hbe = -1*ncread(fname,'height',[min(ix) min(iy)],[max(ix)-min(ix)+1 max(iy)-min(iy)+1]);


% Plot the bathymetry of the float around the position.
hb = hbe;
xb2 = xb(ix);
yb2 = yb(iy);

figure(H);subplot('Position',[lft(1) bot(2) wid hgt]);
contourf(xb2(1:4:end),yb2(1:4:end),hb(1:4:end,1:4:end)',[0:100:2000],'k');

% Inverse the colormap in order to have the water in blue!
caxis([0,2000]);
colormap(flipud(colormap))

% Adding information about the evolution of the float.
xlabel('Longitude');
ylabel('Latitude');

hold on

figure(H2);clf
contourf(xb2(1:4:end),yb2(1:4:end),hb(1:4:end,1:4:end)',[0:100:2000],'k');

% Inverse the colormap in order to have the water in blue!
caxis([0,2000]);
colormap(flipud(colormap))
colorbar

% Adding information about the evolution of the float.
xlabel('Longitude');
ylabel('Latitude');

hold on

% Plotting each cycle with a code very precise:
%
% green   and  * : bathymetry higher than 2.000 and detected.
% magenta and  * : bathymetry higher than 2.000 but not detected.
% green   and  ^ : bathymetry lower than 2.000 and not detected.
% magenta and  ^ : bathymetry lower than 2.000 but detected as shoal.
% red            : estimation of the depth higher than the bathymetry.
% white  and  ^  : last cycle.
% black  and  v  : first cycle.
%
% for index = 2:lg-1
%     if ground(index) == 'Y' & bathy_depth(index+1) >= -2000
%         figure(H);subplot('Position',[lft(1) bot(2) wid hgt])
%         scatter(longitude(index) , latitude(index) ,'*',[0 0.498 0])
%         figure(H2);
%         scatter(longitude(index) , latitude(index) ,'*',[0 0.498 0])
%     end
%     if ground(index) == 'Y' & bathy_depth(index+1) < -2000
%         figure(H);subplot('Position',[lft(1) bot(2) wid hgt])
%         scatter(longitude(index) ,latitude(index) ,'^','filled','magenta')
%         figure(H2);
%         scatter(longitude(index) ,latitude(index) ,'^','filled','magenta')
%     end
%     if ground(index) == 'N' & bathy_depth(index+1) >= -2000
%         figure(H);subplot('Position',[lft(1) bot(2) wid hgt])
%         scatter(longitude(index) ,latitude(index) ,'*','magenta')
%         figure(H2);
%         scatter(longitude(index) ,latitude(index) ,'*','magenta')
%     end
%     if ground(index) == 'N' & bathy_depth(index+1) < -2000
%         figure(H);subplot('Position',[lft(1) bot(2) wid hgt])
%         scatter(longitude(index) ,latitude(index) ,'^','filled',[0 0.498 0])
%         figure(H2);
%         scatter(longitude(index) ,latitude(index) ,'^','filled',[0 0.498 0])
%     end
%     if bathy_depth(index+1) > -1*depth(index)
%         figure(H);subplot('Position',[lft(1) bot(2) wid hgt])
%         scatter(longitude(index) ,latitude(index) ,'^','filled','red')
%         scatter(longitude(index) ,latitude(index) ,'*','red')
%         figure(H2);
%         scatter(longitude(index) ,latitude(index) ,'^','filled','red')
%         scatter(longitude(index) ,latitude(index) ,'*','red')
%     end
% end
% 
figure(H);subplot('Position',[lft(1) bot(2) wid hgt])
plot(longitude(1) ,latitude(1) ,'d','markerfacecolor','green')
plot(longitude(end) ,latitude(end) ,'d','markerfacecolor','red','markersize',10)
plot(longitude(ground),latitude(ground),'r*')
% Link every points
plot(longitude,latitude,'.-','color',[1,1,1])

figure(H2);
p1 = plot(longitude(1) ,latitude(1) ,'d','markerfacecolor','green');
p2 = plot(longitude(end) ,latitude(end) ,'d','markerfacecolor','red','markersize',10);
p3 = plot(longitude(ground),latitude(ground),'r*');
legend([p1,p2,p3],'Deploy location','Current location','Grounded')

% Link every points
plot(longitude,latitude,'.-','color',[1,1,1])
my_save_fig([fnm '/trajectory'],'clobber')
clf
end
