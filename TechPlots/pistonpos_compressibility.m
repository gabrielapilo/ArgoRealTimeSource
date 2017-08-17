function [ deltaV , pispos , markcolor ] = pistonpos_compressibility(nbfloat , document)
%
% This function permits to compare the difference of piston position
% (surface - parking) with the supposed changed of volume of the float.

% Initialization
weight = 27000;
ga = 2.27 * 10 ^ -6 ;
al = 6.9 * 10 ^ -5 ;
lg = length(document.float);
salinity = nan(1,lg);
temperature = nan(1,lg);
pressure = nan(1,lg);
pispos = nan(1,lg);
    
if isfield(document.float,'park_s') & isfield(document.float,'park_t') & isfield(document.float,'park_p') & isfield(document.float,'pistonpos') & isfield(document.float,'parkpistonpos')

    % Extraction of relevant parameters
    for k=1:lg
        salinity(k) = mean(document.float(k).park_s) ;
        temperature(k) = mean(document.float(k).park_t) ;
        pressure(k) = mean(document.float(k).park_p) ;
        % Consider the difference of piston position!
        pispos(k) = mean(document.float(k).pistonpos) - mean(document.float(k).parkpistonpos) ;
    end
      
    % Determine the values of delta V
    [deltaV , V0 ] = float_compress(salinity,temperature,pressure,weight,ga,al);
    
    % Get rid off irrelevant values
    index1 = find(pispos == 0);
    pispos(index1) = [];
    deltaV(index1) = [];
    
    index2 = find(deltaV == 0);
    pispos(index2) = [];
    deltaV(index2) = [];
    
    markcolor = [0 0.498 0];
    
else
    pispos = [];
    deltaV = [];
    markcolor = [0 0.498 0];
end


return 


