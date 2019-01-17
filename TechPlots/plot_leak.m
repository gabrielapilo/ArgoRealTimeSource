function [ ] = plot_leak( float , fnm)
% This function permits to plot several information on the piston
% positionning system:
%
% Plot 1: evolution of internal pressure with time.
% Plot 2: evolution of inside volume with time.
% Plot 3: evolution of parking piston position with external density.
% Plot 4: evolution of surface piston position with an estimation of the
% change of volume to reach the surface from the float compressibility.

%% Plot 1: evolution of internal pressure with time.

% Initialization:
lg = length(float);
axisX = [1:lg];
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

if isfield(float,'p_internal')
    
    % Extraction of the internal pressure of the float.
    internal_pressure = nan(1,lg);
    for ind = 1:lg
        internal_pressure(ind) = mean(float(ind).p_internal);
    end

    % Plot of the result.
    markcolor = usual_test(internal_pressure);
    plot(axisX , internal_pressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
    set(gca,'FontSize',12)
    title('Internal pressure evolution','fontsize',14);
    xlabel('Cycle','fontsize',14);
    ylabel('Internal pressure','fontsize',14);
    my_save_fig([fnm '/pressure'],'clobber')
end


%% Plot 2: evolution of volume through time

% Extraction of the density and the evolution of volume from another
% program.
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

[volume] = get_volume_float(float);
markcolor = usual_test(volume) ;
plot(volume,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor,'markersize',8);
    set(gca,'FontSize',12)
title('Inside volume evolution','fontsize',14);
xlabel('Cycle','fontsize',14);
ylabel('Inside volume','fontsize',14);

my_save_fig([fnm '/insidevolume'],'clobber')

%% Plot 3: evolution of internal pressure with time.

% Extraction of the density and the parking piston position
% from another program.
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

[density , parkpis , markcolor] = pistonpos_density (float);
if length(density) == length(parkpis)
    plot(density,parkpis,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor,'markersize',8);
    set(gca,'FontSize',12)
    title('Parking piston position evolution','fontsize',14) ;
    xlabel('External density','fontsize',14);
    ylabel('Parking piston position','fontsize',14);
my_save_fig([fnm '/parkpis_compres'],'clobber')
end


%% Plot 4: evolution of surface piston position with an deltaV

% Extraction of the deltaV and the surface piston position
% from another program.
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

[deltaV , pispos , markcolor] = pistonpos_compressibility (float);
if length(deltaV) == length(pispos)
    plot(deltaV,pispos,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor,'markersize',8);
    set(gca,'FontSize',12)
    title('Piston position evolution','fontsize',14) ;
    xlabel('DeltaV for ascent','fontsize',14);
    ylabel('Piston differentiate','fontsize',14);
    my_save_fig([fnm '/pis_deltaV'],'clobber')
end

%% APF11 leak voltage and humidity information

if isfield(float,'leak_voltage')
    fig1 = figure(1);clf;hold on
    fig1.OuterPosition=[230 250 700 500];
    for ind = 1:lg
        leak_v(ind) = mean(float(ind).leak_voltage);
    end
    
    plot(axisX,leak_v,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor,'markersize',8);
    set(gca,'FontSize',12)
    title('Leak Detect voltage','fontsize',14) ;
    xlabel('Cycle number','fontsize',14);
    ylabel('Voltage','fontsize',14);
    my_save_fig([fnm '/AIRpump_voltage'],'clobber')
    
end
if isfield(float,'humidity')
    fig1 = figure(1);clf;hold on
    fig1.OuterPosition=[230 250 700 500];
    for ind = 1:lg
        hum(ind) = mean(float(ind).humidity);
    end
    
    plot(axisX,hum,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor,'markersize',8);
    set(gca,'FontSize',12)
    title('Humidity','fontsize',14) ;
    xlabel('Cycle number','fontsize',14);
    ylabel('Humidity, percent relative','fontsize',14);
    my_save_fig([fnm '/AIRpump_power'],'clobber')
    
end
if isfield(float,'coulomb_counter')
    fig1 = figure(1);clf;hold on
    fig1.OuterPosition=[230 250 700 500];
    
    for ind = 1:lg
        cc(ind) = mean(float(ind).coulomb_counter);
    end
    
    plot(axisX,cc,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor,'markersize',8);
    set(gca,'FontSize',12)
    title('Coulomb Counter','fontsize',14) ;
    xlabel('Cycle number','fontsize',14);
    ylabel('Coulombs, milliamp hours','fontsize',14);
    my_save_fig([fnm '/pumpmotor'],'clobber')
    
end
