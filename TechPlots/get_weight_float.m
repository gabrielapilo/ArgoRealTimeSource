function [ weight ] = get_weight_float(nbfloat , document)
%
% This function permits to get the weight evolution of a float through the
% CTD profile and the position of the piston at parking.

% Load the document and considering the number of cycles.
lg = length(document.float);

% Initialization of each important parameter.
salinity = nan(1,lg);
temperature = nan(1,lg);
pressure = nan(1,lg);
parkpis = nan(1,lg);


if isfield(document.float,'park_s') & isfield(document.float,'park_t') & isfield(document.float,'park_p') & isfield(document.float,'pistonpos')
    
    % Create the list of each important parameters.
    for k=1:lg
        salinity(k) = mean(document.float(k).park_s) ;
        temperature(k) = mean(document.float(k).park_t) ;
        pressure(k) = mean(document.float(k).park_p) ;
        parkpis(k) = mean(document.float(k).pistonpos) ;
    end
    
    % Determine the density of the water through the CTD profile.
    dens = sw_dens(salinity,temperature,pressure) ;
    
    % Getting an estimation (linear transformation) of the weight if the
    % piston position permits to balance the weight.
    [ weight ] = (parkpis .* dens) ;
    
else
    weight = [];
end


return 


