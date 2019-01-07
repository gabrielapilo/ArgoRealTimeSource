function [ ] = plot_weight( float , ground,fnm)
%
% This function permits to plot 3 different things in order to detect a
% gain of weight:
%
% Plot 1 : evolution of an estimation of the weight through time.
% Plot 2 : evolution of the surface piston position through time, with an
% ice detection.
% Part 3 : evolution of the parking piston position through time, with a
% grounding detection.

%% Plot 1: evolution of the weight.

% Determine the weight of the float through another program.
[weight] = get_weight_float(float) ;

% Plot the result with the usual test markcolor.
markcolor = usual_test(weight(3:end)) ;
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

plot(weight,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
set(gca,'fontsize',12)
title('Weight evolution','fontsize',14);
xlabel('Cycle','fontsize',14);
ylabel('Weight','fontsize',14);

my_save_fig([fnm '/weight'],'clobber')

%% Plot 2: evolution of surface piston position with ice detection.


lg = length(float);
prof = NaN*ones(lg,1);
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];
fig2 = figure(2);clf;hold on
fig2.OuterPosition=[230 250 700 500];

if isfield(float,'pistonpos')
    
    
    % Extraction of the relevant parameters
    ice = zeros(1,lg);
    position = nan(1,lg);parkpos = position;
    for ind = 1:lg
        if isfield(float,'icedetection')
            if ~isempty(float(ind).icedetection)
                ice(ind) = mean(float(ind).icedetection);
            end
        end
        if isfield(float,'parkpistonpos')
            parkpos(ind) = mean(float(ind).parkpistonpos);
        end
        position(ind) = mean(float(ind).pistonpos);
        if ~isempty(float(ind).profile_number)
            prof(ind) = float(ind).profile_number;
        end
    end
    ice = logical(ice);
    
    % Plotting of this information with a code of colour precise:
    %
    % Green : ice has been detected.
    % Blue  : ice has not been detected.
    % Add information on the figure.
    figure(1)
    plot(prof,position,'x-')
    figure(2)
    plot(prof,parkpos,'x-')
    
    figure(1)
    plot(prof(ice),position(ice),'ro','markerfacecolor','r')
    figure(2)
    plot(prof(ice),parkpos(ice),'ro','markerfacecolor','r');
    figure(1)
    plot(prof(ground),position(ground),'bd','markerfacecolor','b')
    figure(2)
    plot(prof(ground),parkpos(ground),'bd','markerfacecolor','b');
    
    figure(1)
    set(gca,'fontsize',12)
    title('Surface Piston position','fontsize',14);
    xlabel('Cycle','fontsize',14);
    ylabel('Piston position','fontsize',14);
    if sum(ice) > 0 & sum(ground) > 0
        legend('Piston pos','Ice','Grounded','Location','best')
    elseif sum(ice) > 0 & sum(ground) == 0
        legend('Piston pos','Ice','Location','best')
    elseif sum(ice) == 0 & sum(ground) > 0
        legend('Piston pos','Grounded','Location','best')
    end
    grid
    my_save_fig([fnm '/surfpispos'],'clobber')
    figure(2)
    set(gca,'fontsize',12)
    title('Park Piston position','fontsize',14);
    xlabel('Cycle','fontsize',14);
    ylabel('Piston position','fontsize',14);
    if sum(ice) > 0 & sum(ground) > 0
        legend('Piston pos','Ice','Grounded','Location','best')
    elseif sum(ice) > 0 & sum(ground) == 0
        legend('Piston pos','Ice','Location','best')
    elseif sum(ice) == 0 & sum(ground) > 0
        legend('Piston pos','Grounded','Location','best')
    end
    grid
    my_save_fig([fnm '/parkpispos'],'clobber')
end


end