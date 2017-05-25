% function [temp] = optox_tempvolts(data,cf)
% function to convert SBE63 thermistor voltage into film temperature
% Output is in degrees centigrade (K - 273.15)
% cf = vector of coefficients 
% cf(1) = TA0
% cf(2) = TA1
% cf(3) = TA2
% cf(4) = TA3
% data is a column vector of SBE63 thermistor voltage
% Copyright 2011 Dan Quittman, Sea-Bird Electronics

function [temp] = optox_temp(data,cf)
%CRUCIAL STEP - MUST TRANSFORM VOLTAGE TO RESISTANCE FIRST
Rt = 100e3 * data ./ (3.300000 - data);
L1 = log(Rt);
L2 = L1 .* L1;
L3 = L2 .* L1;
temp = (1 ./ (cf(1) + cf(2).*L1 + cf(3).*L2 + cf(4).*L3))-273.15;
end