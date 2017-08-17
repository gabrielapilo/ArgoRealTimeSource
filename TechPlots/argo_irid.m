function [ res ] = argo_irid( nbfloat , document , type )
% This function permits to determine if a flaot uses the ARGOs system or
% the Iridium one, by comparing the number of samples take during one
% cycle.

% Load the document

if isfield(document.float,'npoints')
    
    % Determine the list of points
    nb = [document.float.npoints]' ;
    
    % Compare with 200, if lower then ARGOs, else Iridium.
    if mean(nb) < 200
        res = 'ARGOs' ;
    else
        res = 'Iridium' ;
    end
    
% Si aucune données sur le nombre de points, résultats = Unknown.    
else
    res = 'Unknown' ;
    
end

end