function [ ] = plot_airblad( float ,fnm)
% This function permits to characterize a problem of air bladder.
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

% Initialization
lg = length(float);
airbl = nan(1,lg);

if isfield(float,'airbladderpres')
    
    % Extract the evolution of the air bladder pressure through time.
    for ind = 1:lg
        airbl(ind) = mean(float(ind).airbladderpres);
    end
    
    
    % Plot the previous information:
    markcolor = usual_test(airbl(3:end)) ;
    plot(airbl,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
    set(gca,'fontsize',12)
    title('Air bladder','fontsize',14);
    xlabel('Cycle','fontsize',14);
    ylabel('Air bladder pressure','fontsize',14);
    my_save_fig([fnm '/airbladder'],'clobber')
end

end