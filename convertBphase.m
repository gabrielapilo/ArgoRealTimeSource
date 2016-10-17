% CALO2_CLIM  Calibrate salinity in raw (near-realtime) Argo float, and load
%         variables 's_calibrate', 'cndc_raw', 'cndc_qc', 'cndc_calibrate'
%
% INPUT  
%       Bphase - the raw Bphase measurement from the float
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
% USAGE: [O2] = convertBphase(Bphase,t,s,wmoid,pp,lat);

function [O2] = convertBphase(Bphase,t,s,wmoid,pp,lat)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

if isempty(THE_ARGO_O2_CAL_DB)
    getO2caldbase
end
bp=Bphase;
if(isnan(bp))
    O2=nan;
    return
end

kk=find(ARGO_O2_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert Bphase to oxygen: ' num2str(wmoid)]);
    O2=nan;
    return
else
    cal=THE_ARGO_O2_CAL_DB(kk);
end

[mt,nt] = size(t);
[mbp,nbp] = size(bp);
[ms,ns] = size(s);
[mp,np] = size(pp); 

% Check that inputs have the same shape or are singular
if ((ms~=mt)||(ns~=nt)||(mbp~=mt)||(nbp~=nt)||(mp~=mt)|| (np~=nt)) ...
        && (ms+ns>2) && (mt+nt>2) && (mbp+nbp>2) && (mp+np>2)...
   error('bphase_conv: T, BP, S & P must be same dimensions or singular')
O2=nan;
end

%------
% BEGIN
%------

%check if this is a Uchida conversion (7 calibration coeffs only)
if isempty(cal.a7) | cal.a7==0
    % now the conversion
    c1 = cal.a0;
    c2 = cal.a1;
    c3 = cal.a2;
    c4 = cal.a3;
    c5 = cal.a4;
    c6 = cal.a5;
    c7 = cal.a6;
    
    DO2 = (((c4 + c5*t)./(c6 + c7*bp)) - 1)./(c1 + c2*t + c3*t.^2);
else
    % on 30 Jan 2009,. Craig  sent more calibration files for 3 optodes; 106 577
    % and 720. These only had 14 coeffiecients and this is new code to use the
    % new coefficients
    
    % pO2=cal.a0*t*bp^4+cal.a1*bp^5+cal.a2*bp^4 +cal.a3*bp^3+cal.a4*t*bp^3+...
    %     cal.a5*t^2*bp^3+cal.a6*bp^2+cal.a7*t*bp^2+cal.a8*t^2*bp^2+...
    %     cal.a9*t^3*bp^2+cal.a10*bp+cal.a11*t*bp+cal.a12*t^2*bp+cal.a13*t^3*bp+...
    %     cal.a14*t^4*bp+cal.a15+cal.a16*t+cal.a17*t^2+cal.a18*t^3+cal.a19*t^4+...
    %     cal.a20*t^5;
    
    % pO2 = cal.a0*t.*bp.^4 + cal.a1*bp.^5 + cal.a2*bp.^4 + cal.a3*bp.^3 + cal.a4*t.*bp.^3 +...
    %     cal.a5*t.^2.*bp.^3 + cal.a6*bp.^2 + cal.a7*t.*bp.^2 + cal.a8*t.^2.*bp.^2 +...
    %     cal.a9*t.^3.*bp.^2 + cal.a10*bp + cal.a11*t.*bp + cal.a12*t.^2.*bp + cal.a13*t.^3.*bp +...
    %     cal.a14*t.^4.*bp + cal.a15 + cal.a16*t + cal.a17*t.^2 + cal.a18*t.^3 + cal.a19*t.^4 +...
    %     cal.a20*t.^5;
    
    pO2 = cal.a0 + cal.a1*t + cal.a2*bp + cal.a3*t.^2 + cal.a4*t.*bp + cal.a5*bp.^2 +...
        cal.a6*t.^3 + bp.*t.^2*cal.a7 + t.*bp.^2*cal.a8 + cal.a9*bp.^3 +...
        bp.*t.^3*cal.a10 + t.^2.*bp.^2*cal.a11 + t.*bp.^3*cal.a12 + cal.a13*bp.^4;
    
    s1=zeros(size(t));   %0.;;% salinity in the case of the calibrations is 0 but the correct salinity needs to be used for seawater.
    % convert to dissolved oxygen
    %
    DO2 = (pO2.*O2sol(s1,t).*0.001.*sw_dens0(s1,t))./(0.20946*1013.25*(1-vpress(s1,t)));% units micromol/l
    %
    %
    % enter salinity correction coefficients for DO2 from Aanderaa manual
    %
end    
%     e0 = -6.24097e-3;
%     e1 = -6.93498e-3;
%     e2 = -6.90358e-3;
%     e3 = -4.29155e-3;
%     f0 = -3.11680e-7;

% new coeffs:

    e0 = -6.24523e-3;
    e1 = -7.37614e-3;
    e2 = -1.03410e-2;
    e3 = -8.17083e-3;
    f0 = -4.88682e-7;
    %
    %scale Temperature
    %
    
    ts = log((298.15-t)/(273.15+t));
    
    %;
    % salinity correction to DO2 from Aanderaa manual
    %
    
    % original form:  O2a=DO2*(1000./sw_dens0(s,t))*exp(s*(e0+e1*ts+e2*ts^2+e3*ts^3)+f0*s^2);
    %
    
    O2a=DO2.*exp(s.*(e0+e1*ts+e2*ts.^2+e3*ts.^3)+f0*s.^2);%umol/l
    
%
% pressure correction for optodes requires depth in metres
%

% depth= round(sw_dpth(pp,lat));
%O2 = O2 * (1 + 0.04*depth/1000);
O2a=O2a*(1+(0.032*pp/1000));

%convert O2 to umol/kg
%
% O2= O2a./(0.001*sw_dens0(s,t)); %umol/kg
O2= O2a./(0.001*sw_pden(s,t,pp,0)); %umol/kg


%
