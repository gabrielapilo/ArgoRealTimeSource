function [ density , parkpis , markcolor ] = pistonpos_density( float )
% This function permits to plot the evolution of the piston position with
% the external density. In order to verify if the piston position permits 
% to keep the buyoncy of a float.

% Initialization
lg = length(float);
salinity = nan(1,lg);
temperature = nan(1,lg);
pressure = nan(1,lg);
parkpis = nan(1,lg);
markcolor = [0 0.498 0] ;


if isfield(float,'park_s') & isfield(float,'park_t') & isfield(float,'park_p') & isfield(float,'parkpistonpos') & isfield(float,'pistonpos')
    
    % Extraction of relevant parameters
    for k=1:lg
        salinity(k) = nanmean(float(k).park_s) ;
        temperature(k) = nanmean(float(k).park_t) ;
        pressure(k) = nanmean(float(k).park_p) ;
        parkpis(k) = nanmean(float(k).parkpistonpos) ;
    end
        
    % Extraction of the external density
    density = sw_dens(salinity , temperature , pressure) ;
    
    
    
else
    density = [];
    parkpis = [];
end

end