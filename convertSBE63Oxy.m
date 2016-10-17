% convertSBE63Oxy 
%
%  Decodes the SBE 63 Oxygen sensors on the Navis floats
%
% INPUT  
%       Phase - the raw measurements from the float
%       t - the temperature from the Seabird CTD (not the oxygen
%           temperature)
%       s - the salinity from the CTD
%       wmoid - used to find the O2 calibration coefficients for the float
%          being processed
%       pp - the pressure from the CTD - converted to depth for the final
%          calculation
%       lat - required for the pressure to depth conversion
% OUTPUT
%       O2 - the derived oxygen concentration (umol/kg)
%
%
% AUTHOR: Ann Thresher - March 2008
%
% USAGE: [O2] = convertSBE63Oxy(Phase,t,s,wmoid,pp,lat);

function [O2] = convertSBE63Oxy(Phase,t,s,wmoid,pp,lat)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

bp=Phase;
if(isnan(bp))
    O2=nan;
    return
end
if isempty(ARGO_O2_CAL_WMO)
    getO2caldbase
end
kk=find(ARGO_O2_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert Phase to oxygen: ' num2str(wmoid)]);
    pO2=0;
    return
else
    cal=THE_ARGO_O2_CAL_DB(kk);
end
%simplify the coefficients:
    a0 = cal.a0;
    a1 = cal.a1;
    a2 = cal.a2;
    b0 = cal.a3;
    b1 = cal.a4;
    c0 = cal.a5;
    c1 = cal.a6;
    c2 = cal.a7;
    e = cal.a8;

% get temperature in Kelvin:
k = t + 273.15;

%convert to ml/l
V = Phase/39.457071;

o2_mlperL=(((a0 + a1*t + a2 * V.^2)./(b0 + b1*V) - 1.0)./(c0 + c1*t + c2*t.^2)) .* exp(e * pp./k);  % units ml/L
ts = log((298.15-t)/(273.15+t));  %??


% need to correct for Salinity:
    B0 = -6.24523e-3;
    B1 = -7.37614e-3;
    B2 = -1.03410e-2;
    B3 = -8.17083e-3;
    C0 = -4.88682e-7;

O2a=o2_mlperL.*exp(s.*(B0+B1*ts+B2*ts.^2+B3*ts.^3)+C0*s.^2);  %units ml/l

% now convert to umol/kg
%O2 = o2_mlperL*44659.6./(sw_pden(s,t,pp,0)+1000);% units micromol/kg 
%try new formula:
O2 = O2a*44659.6./(sw_pden(s,t,pp,0));% units micromol/kg

%


