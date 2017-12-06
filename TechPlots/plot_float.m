function [ ] = plot_float ( float,dbdat , floatnum , floatbatt , typebatt )
% Created by Benjamin Briat, for CSIRO.
% This function permits to plot useful information about the float.
%
% Input :  * WMO-ID of float, ex: 5905043.
%
% Output : * a figure, cf. slides to understand the meaning.
%
%
global ARGO_SYS_PARAM;
fnm = strcat(ARGO_SYS_PARAM.web_dir, '/tech/img/',num2str(float(1).wmo_id));

if ~isdir(fnm)
    mkdir(fnm)
end

H = figure('Position',[10,100,1600,900]);
hold on
H2 = figure('Position',[10,100,900,900]);
set(gca,'fontsize',16);
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

end