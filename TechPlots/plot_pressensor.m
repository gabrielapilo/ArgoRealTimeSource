function [ ] = plot_pressensor( nbfloat , document,H,H2,fnm)
% This function permits to characterize a problem of pressure sensor.
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

% Initialization:
lg = length(document.float);
surfpres = nan(1,lg);

if isfield(document.float,'surfpres_used')
    
    % Extract the evolution of the surface pressure.
    for ind = 1:lg
        surfpres(ind) = mean(document.float(ind).surfpres_used);
    end

    % Get a markcolor relevant with the problem under study.
    markcolorpres = [0 0.498 0];

    if length(surfpres) > 0
        if abs(surfpres(end)) > 5
            markcolorpres = 'red';
        end
    end
    
    % Plot the previous information.
    figure(H)
    subplot('Position',[lft(3) bot(4) wid hgt]);
    plot(surfpres,'--^','MarkerEdgeColor',markcolorpres,'color',markcolorpres);
    title('Surface pressure sensor');
    xlabel('Cycle');
    ylabel('Surface pressure');
    figure(H2)
    plot(surfpres,'--^','MarkerEdgeColor',markcolorpres,'color',markcolorpres);
    title('Surface pressure sensor');
    xlabel('Cycle');
    ylabel('Surface pressure');
    my_save_fig([fnm '/pres_sensor'],'clobber')
    clf

end

end