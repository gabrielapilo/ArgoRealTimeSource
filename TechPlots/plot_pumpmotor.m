function [ ] = plot_pumpmotor( float ,fnm)
% This function permits to characterize a problem of pump motor.
% Initialization:
lg = length(float);
pumptime = nan(1,lg);
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];


if isfield(float,'pumpmotortime')
    
    % Extract the evolution of pump motor time.
    for ind = 1:lg
        pumptime(ind) = mean(float(ind).pumpmotortime);
    end
    
    % Plot this information
    markcolor = usual_test(pumptime(3:end)) ;
    plot(pumptime,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
    set(gca,'fontsize',12)
    title('Pump motor evolution','fontsize',14);
    xlabel('Cycle','fontsize',14);
    ylabel('Pump motor time','fontsize',14);
    my_save_fig([fnm '/pumpmotor'],'clobber')
    
end

end