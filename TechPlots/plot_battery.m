function [ ] = plot_battery( float,fnm)
% This function permits to plot every data around battery in order to get
% easily an failure of it.
%
% For each plot, the power is represented through time with a code of
% colour based on the voltage.
%
% The plots are :
% Main value of the battery.
% Park battery.
% SBE pump.
% Air pump.
% Buoyancy pump.

%set up the figures

lg = length(float);
axisX = NaN*ones(lg,1);

% The strucuture of the program is the same for each plot.
% Extract the list of voltage and current from the matfile.
[volt1,int1,volt2,int2,volt3,int3,volt4,int4,volt5,int5] = deal(nan(1,lg));

flds = {'voltage','batterycurrent';'parkbatteryvoltage','parkbatterycurrent';...
    'SBEpumpvoltage','SBEpumpcurrent';'airpumpvoltage','airpumpcurrent';...
    'buoyancypumpvoltage','buoyancypumpcurrent'};

for ind = 1:lg
    if ~isempty(float(ind).profile_number)
        axisX(ind) = float(ind).profile_number;
    end
    for b = 1:size(flds,1)
        if isfield(float,flds{b,1})
            eval(['volt' num2str(b) '(ind) = nanmean(float(ind).(flds{b,1}));'])
        end
        if isfield(float,flds{b,2})        
            eval(['int' num2str(b) '(ind) = nanmean(float(ind).(flds{b,2}));'])
        end
    end
end

%% cycle through the five variables and plot:
close all
nms = {'Main','Park',...
    'CTD','Air Pump',...
    'Buoyancy Pump'};
fnms = {'/main_battery','/park_battery','/SBEpump','/AIRpump','/buoyancy'};
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];
fig2 = figure(2);clf;hold on
fig2.OuterPosition=[230 250 700 500];
fig3 = figure(3);clf;hold on
fig3.OuterPosition=[230 250 700 500];
fig4 = figure(4);clf
fig4.OuterPosition=[230 250 500 400];
fig5 = figure(5);clf
fig5.OuterPosition=[230 250 500 400];
linecolor = {'b','g','k','m','r'};
for a = 1:5
    % Consider both voltage an battery current, because sometimes there is no
    % information about the current, two assets are required:
    %         If the current information are relevant, consider the power of
    %         the float:
    
    eval(['volt = volt' (num2str(a)) ';'])
    eval(['int = int' (num2str(a)) ';'])
    power = volt .* int;
    
    %plot power first
    figure(1)
    plot(axisX , power,'-^','MarkerEdgeColor',linecolor{a},'color',linecolor{a},'markersize',8);
    %now plot voltage
    figure(2)
    plot(axisX , volt,'-^','MarkerEdgeColor',linecolor{a},'color',linecolor{a},'markersize',8);
    %now plot amps
    figure(3)
    plot(axisX , int,'-^','MarkerEdgeColor',linecolor{a},'color',linecolor{a},'markersize',8);
    
    %plot and save individuals
    markcolor = flag_battery(volt) ;
    figure(4)
    plot(axisX , power,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
    set(gca,'FontSize',12)
    xlabel('Cycle','Fontsize',14);
    ylabel('Power (voltage x current)','Fontsize',14);
    title([nms{a} ' power'],'Fontsize',14);
    my_save_fig([fnm fnms{a} '_power'],'clobber')
    
    figure(5)
    plot(axisX , volt,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',8);
    set(gca,'FontSize',12)
    xlabel('Cycle','Fontsize',14);
    title([nms{a} ' voltage'],'Fontsize',14);
    ylabel('Voltage','Fontsize',14);
    my_save_fig([fnm fnms{a} '_voltage'],'clobber')
end
figure(1)
set(gca,'FontSize',12)
xlabel('Cycle','Fontsize',14);
ylabel('Power (voltage x current)','Fontsize',14);
title('Battery power','Fontsize',14);
legend(nms,'Fontsize',12,'Location','southoutside','orientation','horizontal');
my_save_fig([fnm '/battery_power'],'clobber')

figure(2)
set(gca,'FontSize',12)
xlabel('Cycle','Fontsize',14);
title('Battery voltage','Fontsize',14);
ylabel('Voltage','Fontsize',14);
legend(nms,'Fontsize',12,'Location','southoutside','orientation','horizontal');
my_save_fig([fnm '/battery_voltage'],'clobber')

figure(3)
set(gca,'FontSize',14)
xlabel('Cycle','Fontsize',14);
title('Battery current','Fontsize',14);
ylabel('Amps','Fontsize',14);
legend(nms,'Fontsize',12,'Location','southoutside','orientation','horizontal');
my_save_fig([fnm '/battery_amps'],'clobber')


