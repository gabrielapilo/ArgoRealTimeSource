function [ density , parkpis , markcolor ] = pistonpos_density( nbfloat , document)
% This function permits to plot the evolution of the piston position with
% the external density. In order to verify if the piston position permits 
% to keep the buyoncy of a float.

% Initialization
lg = length(document.float);
salinity = nan(1,lg);
temperature = nan(1,lg);
pressure = nan(1,lg);
parkpis = nan(1,lg);
markcolor = [0 0.498 0] ;


if isfield(document.float,'park_s') & isfield(document.float,'park_t') & isfield(document.float,'park_p') & isfield(document.float,'parkpistonpos') & isfield(document.float,'pistonpos')
    
    % Extraction of relevant parameters
    for k=1:lg
        salinity(k) = mean(document.float(k).park_s) ;
        temperature(k) = mean(document.float(k).park_t) ;
        pressure(k) = mean(document.float(k).park_p) ;
        parkpis(k) = mean(document.float(k).parkpistonpos) ;
    end
        
    % Extraction of the external density
    density = sw_dens(salinity , temperature , pressure) ;
    
    
    
else
    density = [];
    parkpis = [];
end

end