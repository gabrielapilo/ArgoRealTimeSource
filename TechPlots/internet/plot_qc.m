function [ ] = plot_qc( nbfloat , document)
% This function permits to characterize a problem of air bladder.

%% Initialization
clf
document = load(document) ;
lg = length(document.float);
axisX = [1:lg];

%% Salinity part

salinity_test = nan(1,lg);

if isfield(document.float,'s_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).s_qc ;
        salinity_test(ind) = overall_qcflag(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(salinity_test,'--^','DisplayName','Salinity');
end

hold on

%% Temperature part

temperature_test = nan(1,lg);

if isfield(document.float,'t_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).t_qc ;
        temperature_test(ind) = overall_qcflag(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(temperature_test,'--^','DisplayName','Temperature');
end

hold on

%% Pressure part

pressure_test = nan(1,lg);

if isfield(document.float,'p_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).p_qc ;
        pressure_test(ind) = overall_qcflag(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(pressure_test,'--^','DisplayName','Pressure');
end

hold on


%% Cndc part

conductivity_test = nan(1,lg);

if isfield(document.float,'cndc_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).cndc_qc ;
        conductivity_test(ind) = overall_qcflag(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(conductivity_test,'--^','DisplayName','Conductivity');
end

hold on


%% Oxygen part

oxygen_test = nan(1,lg);

if isfield(document.float,'oxy_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).oxy_qc ;
        oxygen_test(ind) = overall_qcflag(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(oxygen_test,'--^','DisplayName','Oxygen');
end

hold on


%% Position part

position_test = nan(1,lg);

if isfield(document.float,'pos_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).pos_qc ;
        position_test(ind) = overall_qcflag(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(position_test,'--^','DisplayName','Position');
end

hold on


%% General aspect

title('Quality control test');
xlabel('Cycle');
ylabel('Quality');
ylim([0.5 6.5]);
if exist('h','var')
    set(get(h,'Parent'),'YTickLabel',{'A' 'B' 'C' 'D' 'E','F'});
end
legend('show','Location','northwest');
print(strcat('../',nbfloat,'/quality_control.png'),'-dpng')

    
end