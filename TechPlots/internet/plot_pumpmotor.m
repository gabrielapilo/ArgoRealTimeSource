function [ ] = plot_pumpmotor( nbfloat , document)
% This function permits to characterize a problem of pump motor.

% Initialization:
clf
document = load(document) ;
lg = length(document.float);
axisX = [1:lg];
pumptime = nan(1,lg);


if isfield(document.float,'pumpmotortime')
    
    % Extract the evolution of pump motor time.
    for ind = 1:lg
        pumptime(ind) = mean(document.float(ind).pumpmotortime);
    end
    
    % Plot this information
    markcolor = usual_test(pumptime(3:end)) ;
    plot(pumptime,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Pump motor evolution');
    xlabel('Cycle');
    ylabel('Pump motor time');

end

print(strcat('../',nbfloat,'/pumpmotor.png'),'-dpng')

end