function [ ] = plot_pressensor( nbfloat , document)
% This function permits to characterize a problem of pressure sensor.

% Initialization:
clf
document = load(document) ;
lg = length(document.float);
axisX = [1:lg];
surfpres = nan(1,lg);

if isfield(document.float,'surfpres_used')
    
    % Extract the evolution of the surface pressure.
    for ind = 1:lg
        surfpres(ind) = mean(document.float(ind).surfpres_used);
    end

    % Get a markcolor relevant with the problem under study.
    markcolorpres = 'green';

    if length(surfpres) > 0
        if abs(surfpres(end)) > 5
            markcolorpres = 'red';
        end
    else
        markcolorpres = 'green';
    end
    
    % Plot the previous information.
    plot(surfpres,'--^','MarkerEdgeColor',markcolorpres,'color',markcolorpres);
    title('Surface pressure sensor');
    xlabel('Cycle');
    ylabel('Surface pressure');

end

print(strcat('../',nbfloat,'/pres_sensor.png'),'-dpng')

end