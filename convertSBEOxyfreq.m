% CALO2_CLIM  Calibrate salinity in raw (near-realtime) Argo float, and load
%         variables 's_calibrate', 'cndc_raw', 'cndc_qc', 'cndc_calibrate'
%
%  this decodes the SBE Oxygen sensors
%
% INPUT  
%       Freq - the raw frequency measurement from the float
%       t - the temperature from the Seabird CTD (not the oxygen
%           temperature)
%       s - the salinity from the CTD
%       wmoid - used to find the O2 calibration coefficients for the float
%          being processed
%       pp - the pressure from the CTD - converted to depth for the final
%          calculation
%       lat - required for the pressure to depth conversion
% OUTPUT
%       O2 - the derived oxygen saturation
%
%
% AUTHOR: Ann Thresher - March 2008
%
% USAGE: [O2] = convertSBEOxyFreq(Freq,t,s,wmoid,pp,lat);

function [O2] = convertSBEOxyfreq(Freq,t,s,wmoid,pp,lat)

% The CTD reference set variables are loaded once and retained thereafter 

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

bp=Freq;
if(isnan(bp))
    O2=nan;
    return
end

B0 = -6.24523e-3;
B1 = -7.37614e-3;
B2 = -1.03410e-2;
B3 = -8.17083e-3;
C0 = -4.88682e-7;

A0 = 2.00907;
A1 = 3.22014;
A2 = 4.05010;
A3 = 4.94457;
A4 = -2.56847e-01;
A5 = 3.88767;

if isempty(ARGO_O2_CAL_WMO)
    getO2caldbase
end
kk=find(ARGO_O2_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert Frequency to oxygen: ' num2str(wmoid)]);
    pO2=0;
    return
else
    cal=THE_ARGO_O2_CAL_DB(kk);
end

ts = log((298.15-t)/(273.15+t));

% s1=0.;;% salinity in the case of the calibrations is 0 but the correct salinity needs to be used for seawater.
% convert to dissolved oxygen
%

%o2Sol_mlperL=O2sol(s,t)*(sw_dens0(s,t))/44659.6;  % units ml/L
% new process here - don't use o2sol because that is in wrong units:
% Checked and agrees with Luke's code
o2Sol_mlperL = exp(A0+A1*ts+A2*ts.^2+A3*ts.^3+A4*ts.^4+A5*ts.^5 + s.*(B0+B1*ts+B2*ts.^2+B3*ts.^3)+C0*s.^2);%ml/l

pO2 = cal.a0*(Freq+cal.a1).*(1+cal.a2*t+cal.a3*t.^2+cal.a4*t.^3).*o2Sol_mlperL.*exp(cal.a5*pp./(t+273.15));% units ml/L
    
% *O2solSBE(s,t)
% DO2 = pO2*O2sol(s1,t)*0.001*sw_dens0(s1,t)/(0.20946*1013.25*(1-vpress(s1,t)));% units micromol/kg
O2 = pO2*44659.6/(sw_pden(s,t,pp,0));   %+1000);% units micromol/kg

%


