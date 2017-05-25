% function [o2] = optox_pcorr(T90,P,E)
% function to correct SBE63 oxygen values for pressure
% Copyright 2011 Dan Quittman, Sea-Bird Electronics

function [pcorr] = optox_pcorr(T90,P,E)
P=(P>0).*P; % Clamp negative values to zero
pcorr = exp(E * P ./ (T90 + 273.15));
end