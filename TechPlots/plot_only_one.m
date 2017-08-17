function [ ] = plot_only_one ( nbfloat )
% Created by Benjamin Briat, for CSIRO.
% This function permits to plot useful information about the float.
%
% Input :  * WMO-ID of float, ex: 5905043.
%
% Output : * a figure, cf. slides to understand the meaning.
%
%
% Optimization of the program duration by reading the Argomaster
% spreadsheet only one time:


nbfloat = int2str(nbfloat) ;

% Ben's computer:
document = strcat('X:/float',nbfloat,'.mat') ;
cd Y:\ArgoRT\briat\float_status


% Bec's computer:
%[floatnum , floatbatt , typebatt] = increase_speed() ;
%document = strcat('/home/argo/ArgoRT/matfiles/float',nbfloat,'.mat') ;
%cd /home/argo/ArgoRT/briat/float_status




fig = figure('PaperPosition',[.25 .25 50 30]);
plot_battery(nbfloat , document) ;
plot_bathymetry(nbfloat , document);
plot_weight(nbfloat , document ) ;
plot_leak(nbfloat , document) ;
plot_pumpmotor(nbfloat , document );
plot_pressensor(nbfloat , document );
plot_airblad(nbfloat , document );
plot_parkpressure( nbfloat , document)
plot_qc(nbfloat , document) ;


% Ben's computer:
plot_information_ben(nbfloat , document , floatnum , floatbatt , typebatt);

% Bec's computer:
%plot_information(nbfloat , document , floatnum , floatbatt , typebatt);


if isdir(strcat('../',nbfloat))
    print(strcat('../',nbfloat,'/overall.png'),'-dpng')
else
    new_floder = strcat('../',nbfloat) ;
    mkdir new_folder
    print(strcat('../',nbfloat,'/overall.png'),'-dpng')
end


end