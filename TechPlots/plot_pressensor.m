function [ ] = plot_pressensor( float ,fnm)
% This function permits to characterize a problem of pressure sensor.

% Initialization:
lg = length(float);
surfpres = nan(1,lg);
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

if isfield(float,'surfpres_used')
    
    % Extract the evolution of the surface pressure.
    for ind = 1:lg
        surfpres(ind) = mean(float(ind).surfpres_used);
    end

    % Get a markcolor relevant with the problem under study.
    markcolorpres = [0 0.498 0];

    if length(surfpres) > 0
        if abs(surfpres(end)) > 5
            markcolorpres = 'red';
        end
    end
    
    % Plot the previous information.
    set(gca,'fontsize',12)
    plot(surfpres,'--^','MarkerEdgeColor',markcolorpres,'color',markcolorpres,'markersize',8);
    title('Surface pressure sensor','fontsize',14);
    xlabel('Cycle','fontsize',14);
    ylabel('Surface pressure','fontsize',14);
    my_save_fig([fnm '/pres_sensor'],'clobber')

end

end