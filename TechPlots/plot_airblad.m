function [ ] = plot_airblad( nbfloat , document,H,H2,fnm)
% This function permits to characterize a problem of air bladder.
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

% Initialization
lg = length(document.float);
airbl = nan(1,lg);

if isfield(document.float,'airbladderpres')
    
    % Extract the evolution of the air bladder pressure through time.
    for ind = 1:lg
        airbl(ind) = mean(document.float(ind).airbladderpres);
    end
    
    
    % Plot the previous information:
    markcolor = usual_test(airbl(3:end)) ;
    figure(H)
    subplot('Position',[lft(4) bot(4) wid hgt]);
    plot(airbl,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Air bladder');
    xlabel('Cycle');
    ylabel('Air bladder pressure');
    figure(H2)
    plot(airbl,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
    title('Air bladder');
    xlabel('Cycle');
    ylabel('Air bladder pressure');
    my_save_fig([fnm '/airbladder'],'clobber')
    clf
end

end