function [gregtime] = time2greg(nodctime)
% Convert time (decimal days since 1900) to gregorian time (yr mon day ...)
%
% function [gregtime] = time2greg(nodctime)
% 
% INPUT: nodctime - decimal time (base 1900) as used in NODC WOA94 dataset.
%
% OUTPUT: gregorian time vector:   yr mon day hr min sec
%
% JRD 29/1/96 
 
gregtime = gregorian(nodctime + 2415020.5);

