function [ ] = plot_pumpmotor( nbfloat , document,H,H2,fnm)
% This function permits to characterize a problem of pump motor.
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

% Initialization:
lg = length(document.float);
pumptime = nan(1,lg);


if isfield(document.float,'pumpmotortime')
    
    % Extract the evolution of pump motor time.
    for ind = 1:lg
        pumptime(ind) = mean(document.float(ind).pumpmotortime);
    end
    
    % Plot this information
    markcolor = usual_test(pumptime(3:end)) ;
    figure(H)
    subplot('Position',[lft(2) bot(4) wid hgt]);
    plot(pumptime,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Pump motor evolution');
    xlabel('Cycle');
    ylabel('Pump motor time');
    figure(H2)
    plot(pumptime,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',12);
    title('Pump motor evolution','fontsize',18);
    xlabel('Cycle','fontsize',18);
    ylabel('Pump motor time','fontsize',18);
    set(gca,'fontsize',12)
    my_save_fig([fnm '/pumpmotor'],'clobber')
    set(gca,'fontsize',16)
    clf
    
end

end