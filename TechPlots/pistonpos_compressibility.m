function [ deltaV , pispos , markcolor ] = pistonpos_compressibility(float )
%
% This function permits to compare the difference of piston position
% (surface - parking) with the supposed changed of volume of the float.

% Initialization
weight = 27000;
ga = 2.27 * 10 ^ -6 ;
al = 6.9 * 10 ^ -5 ;
lg = length(float);
salinity = nan(1,lg);
temperature = nan(1,lg);
pressure = nan(1,lg);
pispos = nan(1,lg);
    
if isfield(float,'park_s') & isfield(float,'park_t') & isfield(float,'park_p') & isfield(float,'pistonpos') & isfield(float,'parkpistonpos')

    % Extraction of relevant parameters
    for k=1:lg
        salinity(k) = nanmean(float(k).park_s) ;
        temperature(k) = nanmean(float(k).park_t) ;
        pressure(k) = nanmean(float(k).park_p) ;
        % Consider the difference of piston position!
        pispos(k) = nanmean(float(k).pistonpos) - mean(float(k).parkpistonpos) ;
    end
    ig = ~isnan(pressure.*temperature.*salinity.*pispos);
    if sum(ig) > 1
        pressure = pressure(ig);
        temperature = temperature(ig);
        salinity = salinity(ig);
        pispos = pispos(ig);
        
        % Determine the values of delta V
        [deltaV , V0 ] = float_compress(salinity,temperature,pressure,weight,ga,al);
        
        % Get rid off irrelevant values
        markcolor = [0 0.498 0];
    else
        pispos = [];
        deltaV = [];
        markcolor = [0 0.498 0];
    end
    
else
    pispos = [];
    deltaV = [];
    markcolor = [0 0.498 0];
end


return 


