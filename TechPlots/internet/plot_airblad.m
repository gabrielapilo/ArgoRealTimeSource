function [ ] = plot_airblad( nbfloat , document)
% This function permits to characterize a problem of air bladder.

% Initialization
clf
document = load(document) ;
lg = length(document.float);
axisX = [1:lg];
airbl = nan(1,lg);

if isfield(document.float,'airbladderpres')
    
    % Extract the evolution of the air bladder pressure through time.
    for ind = 1:lg
        airbl(ind) = mean(document.float(ind).airbladderpres);
    end
    
    
    % Plot the previous information:
    markcolor = usual_test(airbl(3:end)) ;
    plot(airbl,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Air bladder');
    xlabel('Cycle');
    ylabel('Air bladder pressure');

end

print(strcat('../',nbfloat,'/airbladder.png'),'-dpng')


end