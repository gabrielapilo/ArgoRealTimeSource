function [ ] = plot_leak( nbfloat , document)
% This function permits to plot several information on the piston
% positionning system:
%
% Plot 1: evolution of internal pressure with time.
% Plot 2: evolution of inside volume with time.
% Plot 3: evolution of parking piston position with external density.
% Plot 4: evolution of surface piston position with an estimation of the
% change of volume to reach the surface from the float compressibility.


cd piston_position

%% Plot 1: evolution of internal pressure with time.
clf
% Initialization:
study = load(document) ;
lg = length(study.float);
axisX = [1:lg];

if isfield(study.float,'p_internal')
    
    % Extraction of the internal pressure of the float.
    internal_pressure = nan(1,lg);
    for ind = 1:lg
        internal_pressure(ind) = mean(study.float(ind).p_internal);
    end

    % Plot of the result.
    markcolor = usual_test(internal_pressure);
    plot(axisX , internal_pressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Internal pressure evolution');
    xlabel('Cycle');
    ylabel('Internal pressure');
end

print(strcat('../../',nbfloat,'/pressure.png'),'-dpng')


%% Plot 2: evolution of volume through time
clf
% Extraction of the density and the evolution of volume from another
% program.

[volume] = get_volume_float(nbfloat , document);
markcolor = usual_test(volume) ;
plot(volume,'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
title('Inside volume evolution');
xlabel('Cycle');
ylabel('Inside volume');
print(strcat('../../',nbfloat,'/insidevolume.png'),'-dpng')


%% Plot 3: evolution of parking piston position with external density.
clf
% Extraction of the density and the parking piston position
% from another program.

[density , parkpis , markcolor] = pistonpos_density (nbfloat, document);
if length(density) == length(parkpis)
    plot(density(2:end),parkpis(2:end),'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
    title('Parking piston position evolution') ;
    xlabel('External density');
    ylabel('Parking piston position');
end
print(strcat('../../',nbfloat,'/parkpis_compres.png'),'-dpng')


%% Plot 4: evolution of surface piston position with an deltaV
clf
% Extraction of the deltaV and the surface piston position
% from another program.

[deltaV , pispos , markcolor] = pistonpos_compressibility (nbfloat, document);
if length(deltaV) == length(pispos)
    plot(deltaV(2:end),pispos(2:end),'--^' , 'color' , markcolor , 'MarkerEdgeColor' , markcolor);
    title('Piston position evolution') ;
    xlabel('DeltaV for ascent');
    ylabel('Piston differentiate');
end
print(strcat('../../',nbfloat,'/pis_deltaV.png'),'-dpng')


%% Return to the file of main study.

cd ..

end