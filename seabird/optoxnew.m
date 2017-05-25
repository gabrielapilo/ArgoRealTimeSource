% function [ox] = optox(data,cf)
% function to convert SBE63 phase or pll voltage to oxygen concentration
% cf = vector of coefficients 
% cf(1) = A0 = zero oxygen offset
% cf(2) = A1 = zero oxygen slope
% cf(3-7) = b0,b1,c0,c1,c2 come from the coefficient fitting process
% cf(8) = A2 is a Ksv phase^2 term
% data is an (n x 2) matrix with column vectors 
% data(:,1) = phase,
% data(:,2) = window temperature (degrees C)
% Dan Quittman
% Copyright 2011 Sea-Bird Electronics
function [ox] = optoxnew(data,cf)
format long g;
delay = data(:,1);
T90 = data(:,2);
phs=delay;
d = cf(3) + cf(4)*(phs);
e = cf(1) + cf(2) * T90 + cf(8) * phs.^2;
%e = cf(1) + cf(2) * T90;
a = e ./ d;
b =  cf(5) + (cf(6) * T90) + cf(7) * (T90 .* T90);
ox = ((a - 1) ./ b);
end