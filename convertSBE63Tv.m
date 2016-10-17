% convertSBE63Tv
%
%  Decodes the SBE 63 Oxygen sensor T voltages on the Navis floats
%
% INPUT  
%       Phase - the raw measurements from the float
%       Tv - the temperature in volts from teh SBE 63 from the Seabird CTD (not the oxygen
%           temperature)
%       s - the salinity from the CTD
%       wmoid - used to find the O2 calibration coefficients for the float
%          being processed
%       pp - the pressure from the CTD - converted to depth for the final
%          calculation
%       lat - required for the pressure to depth conversion
% OUTPUT
%       T - the derived temperature measured by the SBE63 oxygen T sensor
%
%
% AUTHOR: Ann Thresher - March 2008
%
% USAGE: [O2] = convertSBE63Tv(Tv,wmoid);

function [O2T] = convertSBE63Tv(Tv,wmoid)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO


if(isnan(Tv))
    O2T=nan;
    return
end

kk=find(ARGO_O2_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert T volts to TEMP: ' num2str(wmoid)]);
    O2T=0;
    return
else
    cal=THE_ARGO_O2_CAL_DB(kk);
end

%simplify the coefficients:
    T0 = cal.T0;
    T1 = cal.T1;
    T2 = cal.T2;
    T3 = cal.T3;

% transform voltage to resistance:  Basic code from Seabird script
% optox_tempvolts.m

R = 100000 * Tv ./ (3.300000 - Tv)   ;
R = abs(R);
L1 = log(R);
L2 = L1 .* L1;
L3 = L2 .* L1;
temp = (1 ./ (T0 + T1.*L1 + T2.*L2 + T3.*L3))-273.15;

O2T = temp;
%


