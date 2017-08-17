function [ result ] = get_volume_float( nbfloat , document )
% This function permits to determine an estimation of the volume of a float
% at each cycle.
%
% Output: result -> list of volume through the different cycles.

% Load the document
 
if isfield(document.float,'p_internal') & isfield(document.float,'t_raw')
    
    % Initialization
    pressure = nan ( 1 , length(document.float)) ;
    temperature = nan( 1 , length(pressure) ) ;  
    
    for indice = 1 : length(pressure)
        
        % Extract the temperature of the water outside, we assume the
        % permanent regime has been reached and t(int) = t(ext)
        if length(document.float(indice).t_raw) > 0
            temperature(indice) = document.float(indice).t_raw(1) ;
        else
            temperature(indice) = nan ;
        end
        
        % Extract the pressure at parking
        if length(document.float(indice).p_internal) > 0
            pressure(indice) = mean(document.float(indice).p_internal) ;
        else
            pressure(indice) = nan ;
        end
    end
        
    % From PV = NRT we get : V = NRT / P then : V = cte * P/T
    % If a float has leaked, then V changed.
    result = temperature ./ pressure ;
    result (result == Inf) = [] ;
    result = abs(result) ;

else
    result = [] ;
end