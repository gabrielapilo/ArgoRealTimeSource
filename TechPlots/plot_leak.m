function [ ] = plot_leak( nbfloat , document, H, H2, fnm)
% This function permits to plot several information on the piston
% positionning system:
%
% Plot 1: evolution of internal pressure with time.
% Plot 2: evolution of inside volume with time.
% Plot 3: evolution of parking piston position with external density.
% Plot 4: evolution of surface piston position with an estimation of the
% change of volume to reach the surface from the float compressibility.

lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

%% Plot 1: evolution of internal pressure with time.

% Initialization:
lg = length(document.float);
axisX = [1:lg];

if isfield(document.float,'p_internal')
    
    % Extraction of the internal pressure of the float.
    internal_pressure = nan(1,lg);
    for ind = 1:lg
        internal_pressure(ind) = mean(document.float(ind).p_internal);
    end

    % Plot of the result.
    markcolor = usual_test(internal_pressure);
    figure(H);subplot('Position',[lft(2) bot(3) wid hgt]);
    plot(axisX , internal_pressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Internal pressure evolution');
    xlabel('Cycle');
    ylabel('Internal pressure');
    figure(H2)
    plot(axisX , internal_pressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Internal pressure evolution');
    xlabel('Cycle');
    ylabel('Internal pressure');
my_save_fig([fnm '/pressure'],'clobber')
clf
end


%% Plot 2: evolution of volume through time

% Extraction of the density and the evolution of volume from another
% program.

[volume] = get_volume_float(nbfloat , document);
markcolor = usual_test(volume) ;
figure(H);subplot('Position',[lft(3) bot(3) wid hgt]);
plot(volume,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
title('Inside volume evolution');
xlabel('Cycle');
ylabel('Inside volume');
figure(H2)
plot(volume,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
title('Inside volume evolution');
xlabel('Cycle');
ylabel('Inside volume');

my_save_fig([fnm '/insidevolume'],'clobber')
clf

%% Plot 3: evolution of internal pressure with time.

% Extraction of the density and the parking piston position
% from another program.

[density , parkpis , markcolor] = pistonpos_density (nbfloat, document);
if length(density) == length(parkpis)
figure(H);subplot('Position',[lft(4) bot(3) wid hgt]);
    plot(density,parkpis,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
    title('Parking piston position evolution') ;
    xlabel('External density');
    ylabel('Parking piston position');
    figure(H2)
    plot(density,parkpis,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
    title('Parking piston position evolution') ;
    xlabel('External density');
    ylabel('Parking piston position');
my_save_fig([fnm '/parkpis_compres'],'clobber')
clf
end


%% Plot 4: evolution of surface piston position with an deltaV

% Extraction of the deltaV and the surface piston position
% from another program.

[deltaV , pispos , markcolor] = pistonpos_compressibility (nbfloat, document);
if length(deltaV) == length(pispos)
figure(H);subplot('Position',[lft(5) bot(3) wid hgt]);
    plot(deltaV,pispos,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
    title('Piston position evolution') ;
    xlabel('DeltaV for ascent');
    ylabel('Piston differentiate');
    figure(H2)
    plot(deltaV,pispos,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
    title('Piston position evolution') ;
    xlabel('DeltaV for ascent');
    ylabel('Piston differentiate');
my_save_fig([fnm '/pis_deltaV'],'clobber')
clf
end


end