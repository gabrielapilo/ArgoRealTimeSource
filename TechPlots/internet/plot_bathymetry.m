function [ output_args ] = plot_bathymetry( nbfloat , document)

%
%This funtion permits to plot information about the bathymetry of the
% float:
%
% Plot 1: evolution of depth and bathymetry through different cycles.
% Plot 2: geographical evolution of the float in regard with the
% bathymetry.
%

% Load the document:
document = load(document);

% Check that the document is not empty.

if length(document.float) == 0 
    'Empty document'

else
    %%
    %   --------------------------------------------------------
    %   ----- PART 1: Evolution of depth and bathymetry --------
    %   --------------------------------------------------------
    
    %
    % Extracting relevant parameters:
    %
    
    % Initialization of the important parameters:
    lg = length(document.float);
    latitude = nan(1,lg);
    longitude = nan(1,lg);
    pressure = nan(1,lg);

    % Extraction of important parameters: 
    if isfield(document.float,'lat') & isfield(document.float,'lon') & isfield(document.float,'grounded') & isfield(document.float,'p_raw')
        for index=1:lg
            latitude(index) = mean(document.float(index).lat);
            longitude(index) = mean(document.float(index).lon);
            ground(index) = mean(document.float(index).grounded);
            if length(max(document.float(index).p_raw)) > 0
                % Get the maximum pressure reached by the float.
                pressure(index) = max(document.float(index).p_raw);
            end
        end
    end

    %
    % Extract firstly the evolution of depth for the float.
    %
    
    cd seawater
    depth = sw_dpth(pressure , latitude) ;
    cd ..

    %
    % Extract secondly the bathymetry around the position
    %
    
    % Initialization
    bathy_depth = nan(1 , lg);

    % Extraction:
    for index = 1 : lg

        % Reading the the terrainbase.nc in order to have an idea of the
        % bathymetry.
        bathy = ncread('terrainbase.nc' , 'height') ;

        % Transforming the longitude and the latitude into index in order
        % to extract the bathymetry from terrainbase.nc
        lon_index = round(longitude(index) * 4320 / 360) + 1 ;

        if latitude<0
            lat_index = round((latitude(index) + 90) * 2161 / 180) + 1 ;
        else
            lat_index = round((latitude(index) + 90) * 2161 / 180) ;
        end

        % Extraction of the bathymetry.
        if lon_index > 0 & lat_index > 0
            bathy_depth(index) = bathy(floor(lon_index) , floor(lat_index)) ;
        end

    end

    %
    % Realise the final plot
    %
    
    % The depth appears in orange
    plot([1:lg] , -1 * depth , '-','color',[1 , 0.5 , 0]) ;
    hold on
    % The bathymetry appears in black
    plot([2 : lg+1] , bathy_depth , '-','color','black','LineWidth',2) ;

    title('Bathymetry and depth');
    xlabel('Number of cycles');
    ylabel('Depth');
    
    print(strcat('../',nbfloat,'/depth_bathy.png'),'-dpng')

    %%
    %   ---------------------------------------------------------
    %   ----- PART 2: Greographical evolution of bathymetry -----
    %   ---------------------------------------------------------
    %

    clf
    
    % Determine the bathymetry around the position of the float:
    col=jet(100);
    fname = 'terrainbase.nc';
    
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
    contourf(xb2(1:4:end),yb2(1:4:end),hb(1:4:end,1:4:end)',[0:100:2000],'k');

    % Inverse the colormap in order to have the water in blue!
    caxis([0,2000]);
    colormap(flipud(colormap))

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
    % black  and  ^  : last cycle.
    % white  and  v  : first cycle.
    %
    for index = 2:lg-1
        if ground(index) == 'Y' & bathy_depth(index+1) >= -2000
            scatter(longitude(index) , latitude(index) ,'*','green')
            hold on
        end
        if ground(index) == 'Y' & bathy_depth(index+1) < -2000
            scatter(longitude(index) ,latitude(index) ,'^','filled','magenta')
            hold on
        end
        if ground(index) == 'N' & bathy_depth(index+1) >= -2000
            scatter(longitude(index) ,latitude(index) ,'*','magenta')
            hold on
        end
        if ground(index) == 'N' & bathy_depth(index+1) < -2000
            scatter(longitude(index) ,latitude(index) ,'^','filled','green')
            hold on
        end
        if bathy_depth(index+1) > -1*depth(index)
            scatter(longitude(index) ,latitude(index) ,'^','filled','red')
            scatter(longitude(index) ,latitude(index) ,'*','red')
            hold on
        end
    end
    
    scatter(longitude(1) ,latitude(1) ,'v','filled','black')
    scatter(longitude(end) ,latitude(end) ,'^','filled','white')

    % Link every points
    plot(longitude,latitude,'-','color','green')
    
    print(strcat('../',nbfloat,'/trajectory.png'),'-dpng')

    end

end
