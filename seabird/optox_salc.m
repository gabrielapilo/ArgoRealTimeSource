% function [o2] = optox_salc([T90,S])
% function to correct SBE63 oxygen values for salinity
% data is a matrix of columns, T90 = data(:,1), PSU=data(:,2)
% Copyright 2011 Dan Quittman, Sea-Bird Electronics
% Garcia/Gordian default coefs
% Garcia & Gordon coefs 1992, Benson and Krause 1984 data
%OXSOLB0 = -0.00624523;
%OXSOLB1 = -0.00737614; 
%OXSOLB2 = -0.010341;
%OXSOLB3 = -0.00817083; 
%OXSOLC0 = -4.886820e-7;

function [sfactor] = optox_salc(data)
T90=data(:,1);
PSU=data(:,2);
PSU=(PSU>0).*PSU; % Clamp negative values to zero

%%%%%%%%%% DELETE THE FOLLOWING - TEST ONLY!!!! %%%%%%%%%%
%PSU=PSU+1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Garcia & Gordon coefs 1992, Benson and Krause 1984 data
OXSOLB0 = -0.00624523;
OXSOLB1 = -0.00737614; 
OXSOLB2 = -0.010341;
OXSOLB3 = -0.00817083; 
OXSOLC0 = -4.886820e-7;



%OXSOLB0 = -0.00664523;
%OXSOLB1 = -0.00437614; 
%OXSOLB2 = -0.0010341;
%OXSOLB3 = -0.0517083; 
%OXSOLC0 = -1.886820e-6;

Ts = log((298.15 - T90) ./ (273.15 + T90));
Ts2 = Ts .* Ts;
Ts3 = Ts2 .* Ts;
SaltFactor = PSU .* (OXSOLB0 + OXSOLB1 .* Ts + OXSOLB2 .* Ts2 + OXSOLB3 .* Ts3);
SaltFactor = SaltFactor + OXSOLC0 .* PSU .* PSU;
sfactor = exp(SaltFactor);
end