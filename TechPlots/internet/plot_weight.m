function [ ] = plot_weight( nbfloat , document)
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
clf
% Determine the weight of the float through another program.
[weight] = get_weight_float(nbfloat , document) ;

% Plot the result with the usual test markcolor.
markcolor = usual_test(weight(3:end)) ;
plot(weight,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
title('Weight evolution');
xlabel('Cycle');
ylabel('Weight');

print(strcat('../',nbfloat,'/weight.png'),'-dpng')

%% Plot 2: evolution of surface piston position with ice detection.
clf
% Load the document
document = load(document) ;
lg = length(document.float);
axisX = [1:lg];

if isfield(document.float,'pistonpos')
    
    if isfield(document.float,'icedetection') 
        
        % Extraction of the relevant parameters
        ice = nan(1,lg);
        position = nan(1,lg);
        for ind = 1:lg
            ice(ind) = mean(document.float(ind).icedetection);
            position(ind) = mean(document.float(ind).pistonpos);
        end
        
        % Plotting of this information with a code of colour precise:
        % 
        % Green : ice has been detected.
        % Blue  : ice has not been detected.
        for index = 1:lg
            if ice(index) >= 1
                scatter(index , position(index),'+','green')
                hold on
            else
                scatter(index , position(index),'+','blue')
                hold on
            end
        end
    
    % If no ice detection, only plot the evolution of the surface piston
    % position.
    else
        position = nan(1,lg);
        for ind = 1:lg
            position(ind) = mean(document.float(ind).pistonpos);
        end
        
        for index = 1:lg
            scatter(index , position(index),'+','blue')
            hold on
        end
    end
    
    % Add information on the figure.
    title('Surface piston position');
    xlabel('Cycle');
    ylabel('Surface piston position');

end

print(strcat('../',nbfloat,'/surfpispos.png'),'-dpng')

%% Plot 3: evolution of parking piston position with grounding detection.
clf
if isfield(document.float,'parkpistonpos')
    
    if isfield(document.float,'grounded')

        % Extract relevant parameters
        ground = nan(1,lg);
        position = nan(1,lg);
        for ind = 1:lg
            if length(document.float(ind).grounded) == 1
                ground(ind) = document.float(ind).grounded;
            end
            position(ind) = mean(document.float(ind).parkpistonpos);
        end
        
        % Plotting of this information with a code of colour precise:
        % 
        % Magenta : ground has been detected.
        % Blue    : ground has not been detected.
        for index = 1:lg
            if ground(index) == 89 | ground(index) == 'Y'
                scatter(index , position(index),'+','magenta')
                hold on
            else
                scatter(index , position(index),'+','blue')
                hold on
            end
        end
        
    % If no ground detection, only plot the evolution of the surface
    % piston position.
    else
        position = nan(1,lg);
        for ind = 1:lg
            position(ind) = mean(document.float(ind).parkpistonpos);
        end
        
        for index = 1:lg
            scatter(index , position(index),'+','blue')
            hold on
        end

    end
    
    %Add information on the figure.
    title('Parking piston position');
    xlabel('Cycle');
    ylabel('Parking piston position');

end

print(strcat('../',nbfloat,'/parkpispos.png'),'-dpng')

end