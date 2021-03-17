function [SPIKE_T,SPIKE_S,BO_T,BO_S,TEMP_med,TEMP_medm,TEMP_medp,PSAL_med,PSAL_medm,PSAL_medp,DENS_med,DENS_medm,DENS_medp] = QTRT_spike_check_MEDD_main(PRES,TEMP,PSAL,DENS,LAT)
%
% Author: D.Dobler (IFREMER) 
% Date: 2019/11/20
% Version: 1.2
% Modification:	1.3 (2020/12/18): Add checks on input array dimensions and transpose if needed 
% 				1.2 (2019/11/20): specify units of inputs
%				1.1 (2019/11/05): separate robustness test steps from main call of the function to put it in operation
% 			    1.0 (2019/09/01): creation
%
% Description: This routine was developed to look for a better automatic test that would find spikes in profiles.
% 
% inputs: PRES: pressure values in [dbar]
%         TEMP: temperature values [°C - ITS90]
%         PSAL: salinity values [PSS-78] (should be NaN(size(PRES)) if not available)
%		  DENS: potential density values [kg/m3]  (should be NaN(size(PRES)) if not available)
% 		  LAT: latitude of the profiles in [degrees]
%
% outputs: SPIKE_T: array of size(PRES) with a 1 on temperature spikes, It is set to NaN if the computation could not be made
%		   SPIKE_S: array of size(PRES) with a 1 on salinity spikes, It is set to NaN if the computation could not be made
% 		   BO_T: breakout on temperature evaluation, set to 1 if the number of finite measures is less than 5, set to 0 otherwise
% 		   BO_S: breakout on salinity evaluation, set to 1 if the number of finite measures is less than 5, set to 0 otherwise
%		   The other outputs PROF_med, PROF_medm and PROF_medp with PROF = {'PSAL','TEMP','DENS'} are only used for display purpose for robustness tests
%			

% MODIF 2020/12/18:
% First some checks on dimensions:
if size(PRES,1)==1
    PRES=PRES'
end

if size(TEMP,1)==1
    TEMP=TEMP'
end

if size(PSAL,1)==1
    PSAL=PSAL'
end

if size(DENS,1)==1
    DENS=DENS'
end

if size(PRES,1)~=1 & size(PRES,2)~=1
	disp('ERROR: PRES dimensions are not correct, they should be 1 x n or n x 1')
	size(PRES)
	disp('exiting function')
	return
end

if size(TEMP,1)~=1 & size(TEMP,2)~=1
	disp('ERROR: TEMP dimensions are not correct, they should be 1 x n or n x 1')
	size(TEMP)
	disp('exiting function')
	return
end

if size(PSAL,1)~=1 & size(PSAL,2)~=1
	disp('ERROR: PSAL dimensions are not correct, they should be 1 x n or n x 1')
	size(PSAL)
	disp('exiting function')
	return
end

if size(DENS,1)~=1 & size(DENS,2)~=1
	disp('ERROR: DENS dimensions are not correct, they should be 1 x n or n x 1')
	size(DENS)
	disp('exiting function')
	return
end
% FIN MODIF 2020/12/18:


% Configuration of MEDD test 

Z_levels=[150;500;1000;1500];

Med_SlideW=[110;180;400 ;500];

Z_dpdz = [60 ; 150 ; 500 ; 1000 ; 2100];
dpdz_S =[ 1.000 ; 1.000 ; 0.080 ; 0.0200 ; 0.0040 ; 0.0002]; % [  PSU / dbar]
ddpdz_S=[ 0.010 ; 0.010 ; 0.005 ; 0.0001 ; 0.0002 ; 0.0002]; % [  PSU / dbar]
dpdz_T =[ 5.000 ; 3.500 ; 0.500 ; 0.1500 ; 0.0500 ; 0.0004]; % [   °C / dbar]
ddpdz_T=[ 0.080 ; 0.080 ; 0.030 ; 0.0100 ; 0.0030 ; 0.0004]; % [   °C / dbar]
dpdz_D =[ 1.500 ; 0.070 ; 0.070 ; 0.0050 ; 0.0050 ; 0.0004]; % [kg/m3 / dbar]
ddpdz_D=[ 0.006 ; 0.006 ; 0.001 ; 0.0004 ; 0.0004 ; 0.0004]; % [kg/m3 / dbar]


lat_eq   =10;
d_temp_alone   =[0.22;0.22;0.15;0.1]; % keep this one when only temp is available
d_temp_alone_eq=[0.6;0.18;0.15;0.1]; % keep this one when only temp is available for equatorial area
d_temp_dens_avail=[0.15;0.15;0.1;0.1]; % bounds for temp when density is available

if length(find(~isnan(PSAL)))==0 
	if abs(LAT) > lat_eq
		d_T=d_temp_alone; % keep this one when only temp is available
	else
		d_T=d_temp_alone_eq; % keep this one when only temp is available for equatorial area
	end
else
	d_T=d_temp_dens_avail; % bounds for temp when density is available
end
d_S=[0.08;0.08;0.07;0.07]; % bounds for salinity
d_D=[0.08;0.08;0.04;0.04]; % bounds for density



% Call of QTRT_spike_check_MEDD with the correct configuration
[spikeT,TEMP_med,TEMP_medm,TEMP_medp,BO_T] = ...
	QTRT_spike_check_MEDD('TEMP',TEMP, PRES, Z_levels, Med_SlideW,Z_dpdz,dpdz_T,ddpdz_T,d_T);

[spikeS,PSAL_med,PSAL_medm,PSAL_medp,BO_S] = ...
	QTRT_spike_check_MEDD('PSAL',PSAL, PRES, Z_levels, Med_SlideW,Z_dpdz,dpdz_S,ddpdz_S,d_S);
	
[spikeD,DENS_med,DENS_medm,DENS_medp,BO_D] = ...
	QTRT_spike_check_MEDD('DENS',DENS, PRES, Z_levels, Med_SlideW,Z_dpdz,dpdz_D,ddpdz_D,d_D);
	
if BO_T
	SPIKE_T=nan(size(TEMP));
else
	SPIKE_T = ( spikeT & ( spikeD | isnan(DENS) ) );
end

if BO_S
	SPIKE_S=nan(size(PSAL));
else
	SPIKE_S = ( spikeS & ( spikeD | isnan(DENS) ) );
end
