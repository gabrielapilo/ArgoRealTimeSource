function ground = plot_bathymetry( float,fnm)
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

% Initialization of the important parameters:
lg = length(float);
axisX = NaN*ones(lg,1);
latitude = nan(1,lg);
longitude = nan(1,lg);
pressure = nan(1,lg);parkp = pressure;
ground = zeros(1,lg);
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

% Extraction of important parameters:
for index=1:lg
    if ~isempty(float(index).profile_number)
        axisX(index) = float(index).profile_number;
    end
    if isfield(float,'pos_qc')
        %find the first occurrence of a good position
        order = [1,2,0,5,8,9,7]; %what is 7 for?
        [~,ia,~] = intersect(float(index).pos_qc,order,'stable');
        if isempty(ia)
            continue
        end
    else
        ia = 1;
    end
    if ~isempty(float(index).lat)
        latitude(index) = float(index).lat(ia(1));
        longitude(index) = float(index).lon(ia(1));
    end
    if isfield(float,'grounded')
        if float(index).grounded == 'Y'
            ground(index) = 1;
        else
            ground(index) = 0;
        end
    end
    if length(max(float(index).p_raw)) > 0
        % Get the maximum pressure reached by the float.
        pressure(index) = max(float(index).p_raw);
        if isfield(float,'park_p')
            parkp(index) = mean(float(index).park_p);
        end
    end
    
    % Transforming the longitude and the latitude into index in order
    % to extract the bathymetry from terrainbase.nc
    lat_index = find(abs(latitude(index) - lat) <=0.05);
    lon_index = find(abs(longitude(index)-lon) <=0.05);

    % Extraction of the bathymetry.
    if ~isempty(lon_index) & ~isempty(lat_index)
        bathy_depth(index) = max(max(bathy(lon_index, lat_index))) ;
    end
    
end

%
% Extract firstly the evolution of depth for the float.
%

depth = sw_dpth(pressure , latitude) ;
depthpark = sw_dpth(parkp , latitude) ;

%
% Realise the final plot
%

fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

% The depth appears in orange
plot(axisX , -1 * depth , '-','color','b') ;
hold on
%now the park depth too
plot(axisX , -1 * depthpark , '-','color','r') ;
% The bathymetry appears in black
plot(axisX , bathy_depth , '-','color','black','LineWidth',2) ;

title('Bathymetry and depth');
xlabel('Cycle');
ylabel('Depth');
legend('Profile','Park','Bathymetry','orientation','horizontal','location','southoutside')
my_save_fig([fnm '/depth_bathy'],'clobber')

%%
%   ---------------------------------------------------------
%   ----- PART 2: Greographical evolution of bathymetry -----
%   ---------------------------------------------------------
%

% Determine the bathymetry around the position of the float:
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

fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];
contourf(xb2(1:4:end),yb2(1:4:end),hb(1:4:end,1:4:end)',[0:100:2000],'k');

% Inverse the colormap in order to have the water in blue!
caxis([0,2000]);
colormap(flipud(colormap))

% Adding information about the evolution of the float.
xlabel('Longitude');
ylabel('Latitude');

ground = logical(ground);
p1 = plot(longitude(1) ,latitude(1) ,'d','markerfacecolor','green');
p2 = plot(longitude(end) ,latitude(end) ,'d','markerfacecolor','red','markersize',10);
p3 = plot(longitude(ground),latitude(ground),'*','color',[1 , 0.5 , 0]);
legend([p1,p2,p3],'Deploy location','Current location','Grounded')

% Link every point
plot(longitude,latitude,'.-','color',[1,1,1])
my_save_fig([fnm '/trajectory'],'clobber')
end
