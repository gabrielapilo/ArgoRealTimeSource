function [ ] = plot_weight( nbfloat , document, H, H2, ground,fnm)
%
% This function permits to plot 3 different things in order to detect a
% gain of weight:
%
% Plot 1 : evolution of an estimation of the weight through time.
% Plot 2 : evolution of the surface piston position through time, with an
% ice detection.
% Part 3 : evolution of the parking piston position through time, with a
% grounding detection.
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

%% Plot 1: evolution of the weight.

% Determine the weight of the float through another program.
[weight] = get_weight_float(nbfloat , document) ;

% Plot the result with the usual test markcolor.
markcolor = usual_test(weight(3:end)) ;
figure(H);
subplot('Position',[lft(3) bot(2) wid hgt]);
plot(weight,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
title('Weight evolution');
xlabel('Cycle');
ylabel('Weight');
figure(H2);
plot(weight,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
title('Weight evolution');
xlabel('Cycle');
ylabel('Weight');
my_save_fig([fnm '/weight'],'clobber')
clf

%% Plot 2: evolution of surface piston position with ice detection.

% Load the document
lg = length(document.float);
prof = 1:lg;

figure(H);subplot('Position',[lft(4) bot(2) wid hgt]);
hold on

if isfield(document.float,'pistonpos')
    
    if isfield(document.float,'icedetection') 
        
        % Extraction of the relevant parameters
        ice = nan(1,lg);
        position = nan(1,lg);
        for ind = 1:lg
            ice(ind) = mean(document.float(ind).icedetection);
            position(ind) = mean(document.float(ind).pistonpos);
        % Plotting of this information with a code of colour precise:
        % 
        % Green : ice has been detected.
        % Blue  : ice has not been detected.
        end
        iice = ice == 1;
        figure(H);subplot('Position',[lft(4) bot(2) wid hgt]);
        scatter(prof(iice) , position(iice),'+','red')
        figure(H2)
        scatter(prof(iice) , position(iice),'+','red')
        figure(H);subplot('Position',[lft(4) bot(2) wid hgt]);
        scatter(prof(~iice) , position(~iice),'+','blue')
        figure(H2)
        scatter(prof(~iice) , position(~iice),'+','blue')
        
    
    % If no ice detection, only plot the evolution of the surface piston
    % position.
    else
        position = nan(1,lg);
        for ind = 1:lg
            position(ind) = mean(document.float(ind).pistonpos);
        end
        figure(H);subplot('Position',[lft(4) bot(2) wid hgt]);
        scatter(1:lg , position,'+','blue')
        figure(H2)
        scatter(1:lg , position,'+','blue')
        
    end
    
    % Add information on the figure.
    figure(H);subplot('Position',[lft(4) bot(2) wid hgt]);
    title('Surface piston position');
    xlabel('Cycle');
    ylabel('Surface piston position');
    figure(H2)
    title('Surface piston position');
    xlabel('Cycle');
    ylabel('Surface piston position');
my_save_fig([fnm '/surfpispos'],'clobber')
clf
end


%% Plot 3: evolution of parking piston position with grounding detection.


if isfield(document.float,'parkpistonpos')
    
%     if isfield(document.float,'grounded')

%         % Extract relevant parameters
%         ground = zeros(1,lg);
%         position = nan(1,lg);
%         for ind = 1:lg
%             if ~isempty(strmatch(document.float(ind).grounded,'Y'))
%                 ground(ind) = 1;
%             end
%             position(ind) = mean(document.float(ind).parkpistonpos);
%         % Plotting of this information with a code of colour precise:
%         % 
%         % Magenta : ground has been detected.
%         % Blue    : ground has not been detected.
%             if ground(ind)
%                 figure(H);subplot('Position',[lft(5) bot(2) wid hgt]);
%                 scatter(ind , position(ind),'+','magenta')
%                 hold on
%                 figure(H2)
%                 scatter(ind , position(ind),'+','magenta')
%                 hold on
%             else
%                 figure(H);subplot('Position',[lft(5) bot(2) wid hgt]);
%                 scatter(ind , position(ind),'+','blue')
%                 hold on
%                 figure(H2)
%                 scatter(ind , position(ind),'+','blue')
%                 hold on
%             end
%         end
        
        
    % If no ground detection, only plot the evolution of the surface
    % piston position.
%     else
        position = nan(1,lg);
        for ind = 1:lg
            position(ind) = mean(document.float(ind).parkpistonpos);
        end
        figure(H);subplot('Position',[lft(5) bot(2) wid hgt]);
        hold on
        scatter(prof , position,'+','blue')
        plot(prof(ground),position(ground),'m+')
        figure(H2)
        hold on
        scatter(prof , position,'+','blue')
        plot(prof(ground),position(ground),'m+')
        
%     end
    
    %Add information on the figure.
    figure(H);subplot('Position',[lft(5) bot(2) wid hgt]);
    title('Parking piston position');
    xlabel('Cycle');
    ylabel('Parking piston position');
    figure(H2)
    title('Parking piston position');
    xlabel('Cycle');
    ylabel('Parking piston position');
 my_save_fig([fnm '/parkpispos'],'clobber')
 clf  
end


end