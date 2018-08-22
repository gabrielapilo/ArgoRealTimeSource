%% Determine the different data from different floats
function plot_tech(float,dbdat)
%taken from Ben's run_all.m and adjusted to automate into RT system.
% RC August 2017, 
% RC More coding changes August 2018

global ARGO_SYS_PARAM;

%% load up the spreadsheets
if nargin == 0
    disp('No float or dbdat arguments passed in to plot_tech.m');
    return
end

close all
fnm = strcat(ARGO_SYS_PARAM.web_dir, '/tech/img/',num2str(float(1).wmo_id));

if ~isdir(fnm)
    mkdir(fnm)
end

plot_battery(float , H, H2,fnm) ;
ground = plot_bathymetry(float , H, H2,fnm);
plot_weight(float , H, H2, ground,fnm ) ;
plot_leak(float , H, H2,fnm) ;
plot_pumpmotor(float , H, H2,fnm );
plot_pressensor(float , H, H2,fnm );
plot_airblad(float , H, H2,fnm );
plot_parkpressure( float , H, H2,fnm)
plot_qc(float , H, H2,fnm) ;

figure(H)
plot_information(float ,dbdat , floatnum , floatbatt , typebatt);


my_save_fig([fnm '/overall'],'clobber')



