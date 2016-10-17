% convert_uMolar - takes raw dissolved oxygen in uM/l and converts to uM/kg
% for Argos processing
%
% usage:
% function [oxy]=convert_uMolar(O2a,pp,lat);
% where O2a = oxygen concentration in uM/l, 
%       pp = pressure
%       s = salinity
%       t = temperature
%       lat = latitude of the profile

function [O2]=convert_uMolar(O2a,pp,s,t,lat);

% 
% pressure correction for oxygen requires depth in metres 
%

depth= round(sw_dpth(pp,lat));
%O2 = O2 * (1 + 0.04*depth/1000);
O2a=O2a.*(1+(0.032*depth/1000));

%convert O2 to umol/kg
%
O2= O2a./(0.001*sw_pden(s,t,pp,0)); %umol/kg
%

