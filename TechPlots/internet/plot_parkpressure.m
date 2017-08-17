function [ ] = plot_parkpressure( nbfloat , document)
% This function permits to determine the pressure at parking.
clf
% Initialization
document = load(document) ;
lg = length(document.float);
axisX = [1:lg];
parkpressure = nan(1,lg);

if isfield(document.float,'park_p')
    
    % Extract the evolution of pressure at parking through time.
    
    for index = 1:lg
        parkpressure(index) = mean(document.float(index).park_p);
    end
    
    % Plot the previous information.
    markcolor = usual_test(parkpressure(3:end)) ;
    plot(parkpressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Parking pressure');
    xlabel('Cycle');
    ylabel('Parking pressure');

end

print(strcat('../',nbfloat,'/parkpressure.png'),'-dpng')


end