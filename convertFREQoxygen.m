% CALO2_CLIM  Calibrate oxygen in from the raw values reported by the Argo float, and load
%         variables 'o_calibrate', and 'o_raw'
%
% INPUT  
%       freqO2 - the raw oxygen measurement from the float
%       t - the temperature from the Seabird CTD (not the oxygen
%           temperature)
%       s - the salinity from the CTD
%       wmoid - used to find the O2 calibration coefficients for the float
%          being processed
%       pp - the pressure from the CTD -
%       
% OUTPUT
%       O2 - the derived oxygen saturation
%
%
% AUTHOR: Ann Thresher - March 2008
%
% USAGE: [O2] = convertFREQoxygen(t,s,pp,freqO2,wmoid);

function [O2] = convertFREQoxygen(t,s,pp,freqO2,wmoid)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

O2=[];
if(isnan(pp))
    return
end
if(isempty(ARGO_O2_CAL_WMO))
  getO2caldbase;
end   
kk=find(ARGO_O2_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert Frequency to oxygen: ' num2str(wmoid)]);
    O2=0;
    return
else
    cal=THE_ARGO_O2_CAL_DB(kk);
end

% pO2=cal.a0*t*bp^4+cal.a1*bp^5+cal.a2*bp^4 +cal.a3*bp^3+cal.a4*t*bp^3+...
%     cal.a5*t^2*bp^3+cal.a6*bp^2+cal.a7*t*bp^2+cal.a8*t^2*bp^2+...
%     cal.a9*t^3*bp^2+cal.a10*bp+cal.a11*t*bp+cal.a12*t^2*bp+cal.a13*t^3*bp+...
%     cal.a14*t^4*bp+cal.a15+cal.a16*t+cal.a17*t^2+cal.a18*t^3+cal.a19*t^4+...
%     cal.a20*t^5;

%oxsat = O2sol(s,t);
%O2 = (cal.a0 * (freqO2+cal.a1)) * exp(cal.a2 * t) * oxsat * exp(cal.a3 * pp);     

o2Sol_mlperL=O2sol(s,t)*(sw_dens0(s,t)+1000)/44659.6; % units ml/L
% oxsat = O2sol(s,t);
pO2 = (cal.a0 * (freqO2+cal.a1)) * exp(cal.a2 * t) * o2Sol_mlperL * exp(cal.a3 * pp);     
O2 = pO2*44659.6/(sw_pden(s,t,pp,0))   %+1000);% units micromol/kg

return


