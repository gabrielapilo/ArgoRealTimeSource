function [ ] = plot_pumpmotor( float ,fnm)
% This function permits to characterize a problem of pump motor.
% Initialization:
lg = length(float);
pumptime = nan(1,lg);
surfpres = nan(1,lg);
airbl = nan(1,lg);
parkpressure = nan(1,lg);
markcolorpres = [0 0.498 0];

% Extract the evolution of pump motor time.
for ind = 1:lg
    if isfield(float,'pumpmotortime')
        pumptime(ind) = mean(float(ind).pumpmotortime);
    end
    if isfield(float,'surfpres_used')
        surfpres(ind) = mean(float(ind).surfpres_used);
        % Get a markcolor relevant with the problem under study.
        
        if length(surfpres) > 0
            if any(surfpres) > 5
                markcolorpres = 'red';
            end
        end
    end
    if isfield(float,'airbladderpres')
        airbl(ind) = mean(float(ind).airbladderpres);
    end
    if isfield(float,'park_p')
        parkpressure(ind) = mean(float(ind).park_p);
    end
end


% Plot this information
markcolor = usual_test(pumptime(3:end)) ;
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];
plot(pumptime,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
set(gca,'fontsize',12)
title('Pump motor evolution','fontsize',14);
xlabel('Cycle','fontsize',14);
ylabel('Pump motor time','fontsize',14);
my_save_fig([fnm '/pumpmotor'],'clobber')

fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];
set(gca,'fontsize',12)
plot(surfpres,'--^','MarkerEdgeColor',markcolorpres,'color',markcolorpres,'markersize',8);
title('Surface pressure sensor','fontsize',14);
xlabel('Cycle','fontsize',14);
ylabel('Surface pressure','fontsize',14);
my_save_fig([fnm '/pres_sensor'],'clobber')

fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];
markcolor = usual_test(airbl(3:end)) ;
plot(airbl,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
set(gca,'fontsize',12)
title('Air bladder','fontsize',14);
xlabel('Cycle','fontsize',14);
ylabel('Air bladder pressure','fontsize',14);
my_save_fig([fnm '/airbladder'],'clobber')
    
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];
markcolor = usual_test(parkpressure(3:end)) ;
plot(parkpressure,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
set(gca,'fontsize',12)
title('Parking pressure','fontsize',14);
xlabel('Cycle','fontsize',14);
ylabel('Parking pressure','fontsize',14);
my_save_fig([fnm '/parkpressure'],'clobber')
end

