function [ ] = plot_parkpressure( nbfloat , document,H,H2,fnm)
% This function permits to determine the pressure at parking.
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

% Initialization
lg = length(document.float);
parkpressure = nan(1,lg);

if isfield(document.float,'park_p')
    
    % Extract the evolution of pressure at parking through time.
    
    for index = 1:lg
        parkpressure(index) = mean(document.float(index).park_p);
    end
    
    % Plot the previous information.
    markcolor = usual_test(parkpressure(3:end)) ;
    figure(H)
    subplot('Position',[lft(5) bot(4) wid hgt]);
    plot(parkpressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Parking pressure');
    xlabel('Cycle');
    ylabel('Parking pressure');
    figure(H2)
     plot(parkpressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Parking pressure');
    xlabel('Cycle');
    ylabel('Parking pressure');
   my_save_fig([fnm '/parkpressure'],'clobber')
    clf

end

end