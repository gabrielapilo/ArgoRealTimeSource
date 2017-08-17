function [ ] = plot_battery( nbfloat , document)
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


document = load(document) ;
lg = length(document.float);
axisX = [1:lg];

% The strucuture of the program is the same for each plot.

%% Main battery:

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:
if isfield(document.float,'voltage') 
    
    if isfield(document.float,'batterycurrent')
    
        % Extract the list of voltage and current from the matfile.
        volt1 = nan(1,lg);
        int1 = nan(1,lg);
        for ind = 1:lg
            volt1(ind) = mean(document.float(ind).voltage);
            int1(ind) = mean(document.float(ind).batterycurrent);
        end

        % If the current information are relevant, consider the power of
        % the float:
        if min(isnan(int1)) == 0
            puis1 = volt1 .* int1 ;
            markcolor = flag_battery(volt1) ;
            plot(axisX , puis1,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Power');
            title('Main battery');
            
        % If the current information are altered, only consider the voltage
        % evolution through time:
        else
            markcolor = flag_battery(volt1) ;
            plot(axisX , volt1,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('Main battery');
        end
        
    % If no information on the current, only consider the voltage:    
    else
        
        % Extract the list of voltage from the matfile.
        volt1 = nan(1,lg);
        for ind = 1:lg
            volt1(ind) = mean(document.float(ind).voltage);
        end
        
        markcolor = flag_battery(volt1) ;
        plot(axisX , volt1,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
        xlabel('Cycle');
        ylabel('Voltage');
        title('Main battery');
    end
end

print(strcat('../',nbfloat,'/main_battery.png'),'-dpng')



%% Park battery

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:
if isfield(document.float,'parkbatteryvoltage')
    
    if isfield(document.float,'parkbatterycurrent')
    
        % Extract the list of voltage and current from the matfile.
        volt2 = nan(1,lg);
        int2 = nan(1,lg);
        for ind = 1:lg
            volt2(ind) = mean(document.float(ind).parkbatteryvoltage);
            int2(ind) = mean(document.float(ind).parkbatterycurrent);
        end

        % If the current information are relevant, consider the power of
        % the float:
        
        if min(isnan(int2)) == 0
            puis2 = volt2 .* int2 ;
            markcolor = flag_battery(volt2) ;
            plot(axisX , puis2,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Power');
            title('Park battery');
            
        % If the current information are altered, only consider the voltage
        % evolution through time:
        else
            markcolor = flag_battery(volt2) ;
            plot(axisX,volt2,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('Park battery');
        end 
    
    % If no information on the current, only consider the voltage:    
    else
        % Extract the list of voltage from the matfile.
        volt2 = nan(1,lg);
        for ind = 1:lg
            volt2(ind) = mean(document.float(ind).parkbatteryvoltage);
        end
        markcolor = flag_battery(volt2) ;
        plot(axisX,volt2,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
        xlabel('Cycle');
        ylabel('Voltage');
        title('Park battery');
        end 
end

print(strcat('../',nbfloat,'/park_battery.png'),'-dpng')

%% Sea Bird pump

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:
if isfield(document.float,'SBEpumpvoltage') 
    
    if isfield(document.float,'SBEpumpcurrent')
        
        % Extract the list of voltage and current from the matfile.
        volt5 = nan(1,lg);
        int5 = nan(1,lg);
        for ind = 1:lg
            volt5(ind) = mean(document.float(ind).SBEpumpvoltage);
            int5(ind) = mean(document.float(ind).SBEpumpcurrent);
        end

        % If the current information are relevant, consider the power of
        % the float:
        
        if min(isnan(int5)) == 0
            puis5 = volt5 .* int5 ;
            markcolor = flag_battery(volt5) ;
            plot(axisX,puis5,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Power');
            title('SBE pump');
            
        % If the current information are altered, only consider the voltage
        % evolution through time:
        else
            markcolor = flag_battery(volt5) ;
            plot(axisX,volt5,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('SBE pump');
        end
        
    % If no information on the current, only consider the voltage:        
    else
        % Extract the list of voltage from the matfile.
        volt5 = nan(1,lg);
        for ind = 1:lg
            volt5(ind) = mean(document.float(ind).SBEpumpvoltage);
        end
        markcolor = flag_battery(volt5) ;
        plot(axisX,volt5,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
        xlabel('Cycle');
        ylabel('Voltage');
        title('SBE pump');
    end
        
end

print(strcat('../',nbfloat,'/SBEpump_battery.png'),'-dpng')


%% Air pump :

% Consider both voltage an battery current, because sometimes there is no
% information about the current, two assets are required:
if isfield(document.float,'airpumpvoltage') 
    
    if isfield(document.float,'airpumpcurrent')
        
        % Extract the list of voltage and current from the matfile.
        volt3 = nan(1,lg);
        int3 = nan(1,lg);
        for ind = 1:lg
            volt3(ind) = mean(document.float(ind).airpumpvoltage);
            int3(ind) = mean(document.float(ind).airpumpcurrent);
        end

        % If the current information are relevant, consider the power of
        % the float:
        
        if min(isnan(int3)) == 0
            puis3 = volt3 .* int3 ;
            markcolor = flag_battery(volt3) ;
            plot(axisX,puis3,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Power');
            title('Air pump');
            
        % If the current information are altered, only consider the voltage
        % evolution through time:
        else
            markcolor = flag_battery(volt3) ;
            plot(axisX,volt3,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('Air pump');
        end
        
    % If no information on the current, only consider the voltage:        
    else
        % Extract the list of voltage from the matfile.
        volt3 = nan(1,lg);
        for ind = 1:lg
            volt3(ind) = mean(document.float(ind).airpumpvoltage);
        end
        markcolor = flag_battery(volt3) ;
        plot(axisX,volt3,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
        xlabel('Cycle');
        ylabel('Voltage');
        title('Air pump');
    end
end

print(strcat('../',nbfloat,'/AIRpump_battery.png'),'-dpng')

%% BUoyancy pump:

if isfield(document.float,'buoyancypumpvoltage') 
    
    if isfield(document.float,'buoyancypumpcurrent')
        volt4 = nan(1,lg);
        int4 = nan(1,lg);
        for ind = 1:lg
            volt4(ind) = mean(document.float(ind).buoyancypumpvoltage);
            int4(ind) = mean(document.float(ind).buoyancypumpcurrent);
        end

        % If the current information are relevant, consider the power of
        % the float:
        
        if min(isnan(int4)) == 0
            puis4 = volt4 .* int4 ;
            markcolor = flag_battery(volt4) ;
            plot(axisX,puis4,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Power');
            title('Buoyancy pump');
            
        % If the current information are altered, only consider the voltage
        % evolution through time:
        
        else
            markcolor = flag_battery(volt4) ;
            plot(axisX,volt4,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
            xlabel('Cycle');
            ylabel('Voltage');
            title('Buoyancy pump');
        end
        
    % If no information on the current, only consider the voltage:        
    else
        volt4 = nan(1,lg);
        for ind = 1:lg
            volt4(ind) = mean(document.float(ind).buoyancypumpvoltage);
        end
        markcolor = flag_battery(volt4) ;
        plot(axisX,volt4,'--^','MarkerEdgeColor',markcolor,'color',markcolor);
        xlabel('Cycle');
        ylabel('Voltage');
        title('Buoyancy pump');
    end
end

print(strcat('../',nbfloat,'/buoyancy_battery.png'),'-dpng')


end