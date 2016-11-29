function [NODCtime] = greg2time(gregtime)

% Convert gregorian time (yr mon day ...) to decimal days since 1900
%
% function [NODCtime] = greg2time(gregtime)
% 
% INPUT: gregorian time vector:   yr mon day hr min sec
% OUTPUT: nodctime - decimal time (base 1900) as used in NODC WOA94 dataset.
%
% JRD 15/5/96 

NODCtime = julian(gregtime) - 2415020.5;

