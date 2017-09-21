function [ ] = plot_qc( nbfloat , document,H,H2,fnm)
% This function permits to characterize a problem of air bladder.
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.12;

%% Initialization

lg = length(document.float);

%% Salinity part

salinity_test = nan(1,lg);

if isfield(document.float,'s_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).s_qc ;
        salinity_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    figure(H)
    subplot('Position',[lft(2) bot(5) wid hgt]);
    plot(salinity_test,'-^','DisplayName','Salinity');
    hold on
    figure(H2)
    plot(salinity_test,'--^','DisplayName','Salinity','markersize',12);
    set(gca,'fontsize',16)
    hold on
end


%% Temperature part

temperature_test = nan(1,lg);

if isfield(document.float,'t_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).t_qc ;
        temperature_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    figure(H)
    subplot('Position',[lft(2) bot(5) wid hgt]);
    h = plot(temperature_test,'--^','DisplayName','Temperature');
    figure(H2)
    h = plot(temperature_test,'-^','DisplayName','Temperature','markersize',12);
end

%% Pressure part

pressure_test = nan(1,lg);

if isfield(document.float,'p_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).p_qc ;
        pressure_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    figure(H)
    subplot('Position',[lft(2) bot(5) wid hgt]);
    plot(pressure_test,'--^','DisplayName','Pressure');
    figure(H2)
    plot(pressure_test,'-^','DisplayName','Pressure','markersize',12);
end


%% Cndc part

conductivity_test = nan(1,lg);

if isfield(document.float,'cndc_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).cndc_qc ;
        conductivity_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    figure(H)
    subplot('Position',[lft(2) bot(5) wid hgt]);
    plot(conductivity_test,'--^','DisplayName','Conductivity');
    figure(H2)
    plot(conductivity_test,'--^','DisplayName','Conductivity','markersize',12);
end




%% Oxygen part

oxygen_test = nan(1,lg);

if isfield(document.float,'oxy_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).oxy_qc ;
        oxygen_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    figure(H)
    subplot('Position',[lft(2) bot(5) wid hgt]);
    h = plot(oxygen_test,'--^','DisplayName','Oxygen');
    figure(H2)
    h = plot(oxygen_test,'--^','DisplayName','Oxygen');
end


%% Position part

position_test = nan(1,lg);

if isfield(document.float,'pos_qc')
    
    for ind = 1:lg
        sal_element = document.float(ind).pos_qc ;
        position_test(ind) = overall_qcflag_tech(sal_element) ;
    end
    
    % Plot the previous information:
    figure(H)
    subplot('Position',[lft(2) bot(5) wid hgt]);
    h = plot(position_test,'--^','DisplayName','Position');
    figure(H2)
    h = plot(position_test,'--^','DisplayName','Position','markersize',12);
    
end

%% General aspect
    figure(H)
    subplot('Position',[lft(2) bot(5) wid hgt]);

title('Quality control test');
xlabel('Cycle');
ylabel('Quality');
ylim([0.5 6.5]);
if exist('h','var')
    set(get(h,'Parent'),'YTickLabel',{'A' 'B' 'C' 'D' 'E','F'});
end
    figure(H2)

title('Quality control test','fontsize',18);
xlabel('Cycle','fontsize',18);
ylabel('Quality','fontsize',18);
ylim([0.5 6.5]);
if exist('h','var')
    set(get(h,'Parent'),'YTickLabel',{'A' 'B' 'C' 'D' 'E','F'});
end
set(gca,'fontsize',16)
my_save_fig([fnm '/quality_control'],'clobber')
clf    
end