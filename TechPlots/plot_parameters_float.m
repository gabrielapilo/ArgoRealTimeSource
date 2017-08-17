function [ ] = plot_parameters_float ( nbfloat , document , floatnum , floatbatt , typebatt )
% Created by Benjamin Briat, for CSIRO.
% This function permits to plot useful information about the float.
%
% Input :  * WMO-ID of float, ex: 5905043.
%
% Output : * a figure, cf. slides to understand the meaning.
%
%
plot_battery(nbfloat , document) ;
plot_bathymetry(nbfloat , document);
plot_weight(nbfloat , document ) ;
plot_leak(nbfloat , document) ;
plot_pumpmotor(nbfloat , document );
plot_pressensor(nbfloat , document );
plot_airblad(nbfloat , document );
plot_parkpressure( nbfloat , document)
plot_qc(nbfloat , document) ;


end