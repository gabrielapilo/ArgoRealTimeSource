% Optode type='Aanderaa 4330',
% INPUT  
%       Tphase - the raw Tphase measurement from the float
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
% AUTHOR: Udaya Bhaskar, INCOIS - December 2014
%
% USAGE: [O2] = convertTphase(Tphase,t,s,wmoid,pp,lat);

function [O2]=convertTphase(Tphase,t,s,wmoid,pp,lat)

% The CTD reference set variables are loaded once and retained thereafter
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

bp=Tphase;
if(isnan(bp))
    O2=nan;
    return
end

kk=find(ARGO_O2_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert Tphase to oxygen: ' num2str(wmoid)]);
    pO2=0;
    return
else
    cal=THE_ARGO_O2_CAL_DB(kk);
end
% tabcoef(1,  1:8) = [tempcoef0 tempcoef1 tempcoef2 tempcoef3 phasecoef0 phasecoef1 phasecoef2 phasecoef3]
% tabcoef(2, 1:28) = coefficients C0 to C13 stored in FoilCoefA and FoilCoefB
% tabcoef(3, 1:28) = temperature exponents m0 to m27 stored in FoilPolyDegT
% tabcoef(4, 1:28) = oxygen exponents n0 to n27 stored in FoilPolyDegO
% tabcoef(5,  1:2) = conccoefficients [conccoef0 conccoef1]
% S0 - Salinity configurable property, generally set to zero
% si raw_temp=temp, alors tabcoef(1,5:8)= [0 1 0 0]
% 
% now to assing the coefficiets which are read from argomaster_O2cal.csv file  
%
% check to see of the conversion is using Stern-Volmer equation
%
if isempty(cal.a9) | cal.a9==0
    % now the conversion
    c1 = cal.a0;
    c2 = cal.a1;
    c3 = cal.a2;
    c4 = cal.a3;
    c5 = cal.a4;
    c6 = cal.a5;
    c7 = cal.a6;

    DO2 = (((c4 + c5*t)./(c6 + c7*bp)) - 1)./(c1 + c2*t + c3*t.^2);

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
O2a=O2a.*(1+(0.032*pp/1000));

%convert O2 to umol/kg
%
% O2= O2a./(0.001*sw_dens0(s,t)); %umol/kg
O2= O2a./(0.001*sw_pden(s,t,pp,0)); %umol/kg

% Now for method based on 20 sensor-dependent coefficients 
% as described in TD269 Operting manual
else
tabcoef(1,  1:8) = [cal.a0 cal.a1 cal.a2 cal.a3 cal.a4 cal.a5 cal.a6 cal.a7];
tabcoef(2, 1:28) = [cal.a8 cal.a9 cal.a10 cal.a11 cal.a12 cal.a13 cal.a14 cal.a15 cal.a16 cal.a17 cal.a18 cal.a19 cal.a20 cal.a21 cal.a22 cal.a23 cal.a24 cal.a25 cal.a26 cal.a27 cal.a28 0.0 0.0 0.0 0.0 0.0 0.0 0.0];
tabcoef(3, 1:28) = [1 0 0 0 1 2 0 1 2 3 0 1 2 3 4 0 1 2 3 4 5 0 0 0 0 0 0 0];
tabcoef(4, 1:28) = [4 5 4 3 3 3 2 2 2 2 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0];
tabcoef(5,  1:2) = [cal.a29 cal.a30];

%temp = tabcoef(1,1) + tabcoef(1,2)*t + tabcoef(1,3)*t.^2 + tabcoef(1,4)*t.^3;
temp=t; % to assign the temperature values

calphase= tabcoef(1,5) + tabcoef(1,6)*bp + tabcoef(1,7)*bp.^2 + tabcoef(1,8)*bp.^3;
        
        deltaP=zeros(size(temp));
        for ii=1:28      
            deltaP=deltaP+tabcoef(2,ii)*(temp.^tabcoef(3,ii)).*(calphase.^tabcoef(4,ii));
        end
        
        nomairpress=1013.25;
        nomairmix=0.20946;
        pvapour=exp(52.57 - 6690.9./(temp+273.15) - 4.681*log(temp + 273.15));
        airsat=deltaP*100./((nomairpress-pvapour)*nomairmix);
        
        tabA= [2.00856;
              3.22400;
              3.99063;
              4.80299;
              9.78188e-1;
              1.71069];
        
        tabB = [-6.24523e-3;
               -7.37614e-3;
               -1.03410e-2;
               -8.17083e-3];
        C0 = -4.88682e-7;S0 = 0;
        Ts=log((298.15-temp)./(273.15+temp));
        expo=zeros(size(temp));
        for ii=1:6
            expo=expo+tabA(ii).*Ts.^(ii-1);
        end
        for ii=1:4
            expo=expo+S0*tabB(ii).*Ts.^(ii-1);
        end
        expo=expo+C0*S0^2;
        cstar=exp(expo);
        molar_doxy_tmp=cstar*44.614.*airsat/100;
	% check and see if Craig Neill, CSIRO condition need to applied
	if ~isempty(cal.a29) | ~isempty(cal.a30)
	molar_doxy=tabcoef(5,1) + tabcoef(5,2)*molar_doxy_tmp;
	end
% salinity correction to DO2 from Aanderaa manual
%
% original form:  O2a=DO2*(1000./sw_dens0(s,t))*exp(s*(e0+e1*ts+e2*ts^2+e3*ts^3)+f0*s^2);
%
   
    O2a=molar_doxy.*exp(s.*(tabB(1)+tabB(2)*Ts+tabB(3)*Ts.^2+tabB(4)*Ts.^3)+C0*s.^2); %umol/l
    
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
end
