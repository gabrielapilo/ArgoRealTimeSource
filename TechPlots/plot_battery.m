function [ ] = plot_battery( float, dbdat)
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
axisX = [1:lg];

% The strucuture of the program is the same for each plot.
% Extract the list of voltage and current from the matfile.
[volt1,int1,volt2,int2,volt3,int3,volt4,int4,volt5,int5] = deal(nan(1,lg));

flds = {'voltage','batterycurrent';'parkbatteryvoltage','parkbatterycurrent';...
    'SBEpumpvoltage','SBEpumpcurrent';'airpumpvoltage','airpumpcurrent';...
    'buoyancypumpvoltage','buoyancypumpcurrent'};

for ind = 1:lg
    for b = 1:size(flds,1)
        if isfield(float,flds{b,1})
            eval(['volt' num2str(b) '(ind) = nanmean(float(ind).(flds{b,1}));'])
        end
        if isfield(float,flds{b,2})        
            eval(['int' num2str(b) '(ind) = nanmean(float(ind).(flds{b,2}));'])
        end
    end
end


%% Main battery:

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:
%         If the current information are relevant, consider the power of
%         the float:

power = volt1 .* int1 ;
            
markcolor = flag_battery(volt1) ;
%plot power first
figure;
plot(axisX , power,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',12);
xlabel('Cycle','Fontsize',18);
title('Main battery','Fontsize',18);
ylabel('Power','Fontsize',18);
set(gca,'FontSize',16)
my_save_fig([fnm '/main_battery_power'],'clobber')
clf
%now plot voltage
plot(axisX , volt1,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',12);
xlabel('Cycle','Fontsize',18);
title('Main battery','Fontsize',18);
ylabel('Voltage','Fontsize',18);
set(gca,'FontSize',16)
my_save_fig([fnm '/main_battery_voltage'],'clobber')
clf


%% Park battery

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:
markcolor = flag_battery(volt2) ;
power = volt2 .* int2 ;
%plot power
clf;
plot(axisX,power,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',12);
xlabel('Cycle','fontsize',18);
ylabel('Voltage','fontsize',18);
title('Park battery Power','fontsize',18);
set(gca,'fontsize',16)
my_save_fig([fnm '/park_battery_power'],'clobber')
%plot voltage
clf;
plot(axisX,volt2,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',12);
xlabel('Cycle','fontsize',18);
ylabel('Voltage','fontsize',18);
title('Park battery Voltage','fontsize',18);
set(gca,'fontsize',16)
my_save_fig([fnm '/park_battery_voltage'],'clobber')
clf

%% Sea Bird pump

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:

%plot power
power = volt5 .* int5 ;
plot(axisX,power,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
xlabel('Cycle');
ylabel('Power');
title('SBE pump');

%             % If the current information are altered, only consider the voltage
%             % evolution through time:
markcolor = flag_battery(volt3) ;
figure(H);subplot('Position',[lft(3) bot(1) wid hgt]);
plot(axisX,volt3,'-^','MarkerEdgeColor',markcolor,'color',markcolor);
xlabel('Cycle');
ylabel('Voltage');
title('SBE pump');
figure(H2)
plot(axisX,volt3,'-^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',12);
xlabel('Cycle','fontsize',18);
ylabel('Voltage','fontsize',18);
title('SBE pump','fontsize',18);
set(gca,'fontsize',16)
my_save_fig([fnm '/SBEpump_battery'],'clobber')

clf
%         end
%         
%         % If no information on the current, only consider the voltage:
%     else
%         % Extract the list of voltage from the matfile.
%         volt5 = nan(1,lg);
%         for ind = 1:lg
%             volt5(ind) = mean(float(ind).SBEpumpvoltage);
%         end
%         markcolor = flag_battery(volt5) ;
%         subplot(5,5,3);
%         plot(axisX,volt5,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
%         xlabel('Cycle');
%         ylabel('Voltage');
%         title('SBE pump');
%     end
    
end


%% Air pump :

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:
if isfield(float,'airpumpvoltage')
    
%      if isfield(float,'airpumpcurrent')
                
        % If the current information are relevant, consider the power of
        % the float:
        
%         if min(isnan(int3)) == 0
%             puis3 = volt3 .* int3 ;
%             markcolor = flag_battery(volt3) ;
%             subplot(5,5,4);
%             plot(axisX,puis3,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
%             xlabel('Cycle');
%             ylabel('Power');
%             title('Air pump');
%             
%             % If the current information are altered, only consider the voltage
%             % evolution through time:
%         else
            markcolor = flag_battery(volt4) ;
            figure(H);subplot('Position',[lft(4) bot(1) wid hgt]);
            plot(axisX,volt4,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('Air pump');
            figure(H2)
            plot(axisX,volt4,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('Air pump');
my_save_fig([fnm '/AIRpump_battery'],'clobber')
clf
%         end
%         
%         % If no information on the current, only consider the voltage:
%     else
%         % Extract the list of voltage from the matfile.
%         volt3 = nan(1,lg);
%         for ind = 1:lg
%             volt3(ind) = mean(float(ind).airpumpvoltage);
%         end
%         markcolor = flag_battery(volt3) ;
%         subplot(5,5,4);
%         plot(axisX,volt3,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
%         xlabel('Cycle');
%         ylabel('Voltage');
%         title('Air pump');
%     end
end


%% BUoyancy pump:

if isfield(float,'buoyancypumpvoltage')
    
%     if isfield(float,'buoyancypumpcurrent')
        
        % If the current information are relevant, consider the power of
        % the float:
        
%         if min(isnan(int4)) == 0
%             puis4 = volt4 .* int4 ;
%             markcolor = flag_battery(volt4) ;
%             subplot(5,5,5);
%             plot(axisX,puis4,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
%             xlabel('Cycle');
%             ylabel('Power');
%             title('Buoyancy pump');
%             
%             % If the current information are altered, only consider the voltage
%             % evolution through time:
%             
%         else
            markcolor = flag_battery(volt5) ;
            figure(H);subplot('Position',[lft(5) bot(1) wid hgt]);
            plot(axisX,volt5,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('Buoyancy pump');
            figure(H2)
            plot(axisX,volt5,'--^','MarkerEdgeColor',markcolor,'color',markcolor,'markersize',12);
            xlabel('Cycle','fontsize',18);
            ylabel('Voltage','fontsize',18);
            title('Buoyancy pump','fontsize',18);
            set(gca,'fontsize',16)
my_save_fig([fnm '/buoyancy_battery'],'clobber')
clf
%         end
%         
%         % If no information on the current, only consider the voltage:
%     else
%         volt4 = nan(1,lg);
%         for ind = 1:lg
%             volt4(ind) = mean(float(ind).buoyancypumpvoltage);
%         end
%         markcolor = flag_battery(volt4) ;
%         subplot(5,5,5);
%         plot(axisX,volt4,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
%         xlabel('Cycle');
%         ylabel('Voltage');
%         title('Buoyancy pump');
%     end
%     
end


end