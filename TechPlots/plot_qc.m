function [ ] = plot_qc( float ,fnm)
% This function permits to characterize a problem of air bladder.
%% Initialization

lg = length(float);
fig1 = figure(1);clf;hold on
fig1.OuterPosition=[230 250 700 500];

%% Salinity part

salinity_test = nan(1,lg);

if isfield(float,'s_qc')
    
    for ind = 1:lg
        sal_element = float(ind).s_qc ;
        salinity_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    plot(salinity_test,'--^','DisplayName','Salinity','markersize',8);
    set(gca,'fontsize',12)
end


%% Temperature part

temperature_test = nan(1,lg);

if isfield(float,'t_qc')
    
    for ind = 1:lg
        sal_element = float(ind).t_qc ;
        temperature_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(temperature_test,'-^','DisplayName','Temperature','markersize',8);
end

%% Pressure part

pressure_test = nan(1,lg);

if isfield(float,'p_qc')
    
    for ind = 1:lg
        sal_element = float(ind).p_qc ;
        pressure_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    plot(pressure_test,'-^','DisplayName','Pressure','markersize',8);
end


%% Cndc part

conductivity_test = nan(1,lg);

if isfield(float,'cndc_qc')
    
    for ind = 1:lg
        sal_element = float(ind).cndc_qc ;
        conductivity_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    plot(conductivity_test,'--^','DisplayName','Conductivity','markersize',8);
end




%% Oxygen part

oxygen_test = nan(1,lg);

if isfield(float,'oxy_qc')
    
    for ind = 1:lg
        sal_element = float(ind).oxy_qc ;
        oxygen_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(oxygen_test,'--^','DisplayName','Oxygen','markersize',8);
end


%% Position part

position_test = nan(1,lg);

if isfield(float,'pos_qc')
    
    for ind = 1:lg
        sal_element = float(ind).pos_qc ;
        position_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    h = plot(position_test,'--^','DisplayName','Position','markersize',8);
    
end

%% General aspect
title('Quality control test','fontsize',18);
xlabel('Cycle','fontsize',18);
ylabel('Quality','fontsize',18);
ylim([0.5 6.5]);
if exist('h','var')
    set(get(h,'Parent'),'YTickLabel',{'A' 'B' 'C' 'D' 'E','F'});
end
set(gca,'fontsize',16)
my_save_fig([fnm '/quality_control'],'clobber')
end