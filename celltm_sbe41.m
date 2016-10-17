function [salt_cor] = celltm_sbe41(salt,temp,pres,e_time,alpha,tau);

% function [salt_cor] = celltm_sbe41(salt,temp,pres,e_time,alpha,tau);
% 
% Given a profile of SBE-41 (or SBE-41CP) data consisting of salinity
% (salt, pss-78), temperature (temp, deg. C, ITS-90), pressure (pres,
% dbar), and the elapsed time of the samples (e_time, seconds), this
% function returns a corrected salinity (salt_cor, pss-78).
%
% The elapsed time (e_time) must to be estimated using different methods
% for different models of float, and must reflect the time elapsed in
% seconds since the start of the profile for each samples.
% 
% For Apex 260 floats with the "maintain a minumum ascent rate of 0.08 m/s
% controllers" data from Dana Swift (UW) suggest a mean rise rate of 0.09
% dbar/second (with a standard deviation of +/- 0.015 dbar/s, and actual
% values ranging between about 0.06 and 0.12 dbar/s) should be used to
% derive elapsed time from pressure.
%
% Users of other floats should estimate their ascent rates and use these
% estimates to compute an e_time  in seconds.
%
% Estimates of alpha and tau=1/beta following Morison et al, (1994, JAOT)
% are also required.
%
% For SBE-41 CTDs I have estimated alpha = 0.021 and tau = 21.0 s using
% data from PMEL and UW Apex floats equipped with SBE-41 CTDs.
% 
% For SBE-41 CTDs I have estimated alpha = 0.164 and tau = 5.87 s using
% 1 Hz data in Arctic ocean thermohaline staircases from three Ice-Tethered
% profilers with ascent rates of about 0.25 dbar/s.
% 
% Note that routine is designed for vectors only from a single profile, not
% matrices.
%
% Note that the data (and the e_time) should be passed to this routine in
% the order that they were collected (sorted to go from deepest pressure to
% shallowest).
%
% Note that park data should not be corrected (and thus not passed through
% this routine) since the CTD should be in thermal equilibrium when at
% park.
%
% Note that the ucertainty in the correction is about the size of the
% correction itself.  This uncertainty should be treated as an independent
% error from other sources of error (such as the manufacturer's calibration
% uncertainty  and/or WJO/BS conductivity slope adjustment from historical
% T-S relationships) and thus should be combined in quadrature (square any
% relevant error terms, sum these squares, and then take the square root of
% the sum) for inclusion in psal_adjusted_error.
%
% Note that the CSIRO seawater toolkit is required for use of this function.
%
% Use this function at your own risk.  The author takes no responsibility
% for errors or omissions, but will be happy to receive suggestions for
% improvements or corrections so that they can be reviewed, implimented if
% warranted, and passed on to others.  Users should e-mail the author so
% that they can receive notice of any updates.
% 
% Gregory C. Johnson (e-mail: gregory.c.johnson@noaa.gov)
% 13 October 2005

% Compute the Nyquist frequency and the beta coefficient following Morison
% et al (JAOT, 1994).  Data will be interpolated to 1 Hz for the
% correction, so use freq=1.

freq=1;
f_nyquist=1./(2*freq);

% Do not accept a negative tau and flip signs if needed.  This is a legacy
% from use of the code for minimization to determine the coefficients and
% will be kept so that the code can continue to be used to estimate
% coefficients.

if tau<0
    tau=-tau;
    alpha=-alpha;
end 

% Compute a and b following Morison et al. (JAOT, 1994)

a_coef=4*f_nyquist*alpha*tau/(1+4*f_nyquist*tau);
b_coef=1-2*a_coef/alpha;

% Check dimensions of salt

[n,m]=size(salt);

if min([n,m])>1
    disp('Vector inputs only please')
    return
end % if min([n,m])>1

% Vectorize

v_salt=salt(:);
v_temp=temp(:);
v_pres=pres(:);
v_time=e_time(:);

% Keep original pressure

v_pres_orig=v_pres;

% Sort vectors so time is increasing if necessary

[ii,jj]=sort(v_time);

if isequal(ii,v_time)~=1
%    disp('Warning: time does not increase monotonically and has been sorted')
    v_salt=v_salt(jj);
    v_temp=v_temp(jj);
    v_pres=v_pres(jj);
    v_time=v_time(jj);
end


% Calculate conductivity from the reported variables

v_cond=sw_cndr(v_salt,v_temp,v_pres)*sw_c3515;

% Interpolate things to a uniform 1 Hz rate to keep the numerics happy.

% Exit if not enough data
if (max(v_time)-min(v_time))==0;
    salt_cor=0;
    return;
end    

i_time=min(v_time):1:max(v_time);
i_temp=interp1(v_time,v_temp,i_time)';
i_cond=interp1(v_time,v_cond,i_time)';
i_pres=interp1(v_time,v_pres,i_time)';


% Compute the backward-looking first difference of temperatures, setting
% the first value equal to zero because it is not used anyways.

i_temp_diff=[0;diff(i_temp)];

% Loop through to find the temperature adjustment for what it should be
% inside the conductivity cell for a given alpha and tau

i_temp_adj=0*i_temp;
for i=2:length(i_temp)
    i_temp_adj(i)=-b_coef*i_temp_adj(i-1)+a_coef*i_temp_diff(i);
end

% Go back and set the first temperature adjustment to the second, since the
% float is probably rising as it takes its first samples

i_temp_adj(1)=i_temp_adj(2);

% Subtract the tempertaure adjustment from the thermistor temperature
% to find the temperature inside the conductivity cell

i_temp_cond=i_temp-i_temp_adj;

% Compute the corrected salinity using the advanced conductivity and
% the estimated temperature of the fluid in the conductivity cell and the
% raw pressure

i_salt_cor=sw_salt(i_cond/sw_c3515,i_temp_cond,i_pres);

% Kludge to put the last sampled time the last interpolated time so the
% last sample is not lost in the resampling to original pressures.  This
% introduces an error in the last salinity sample equivalent to less than 1
% second of ascent time.

l=length(v_time);
v_time(l)=max(i_time);

% Resample at original pressures
  
salt_cor_unsort=interp1(i_time,i_salt_cor,v_time);

% Now resort to original pressures in case time was not monotonically
% increasing

for i=1:length(v_pres_orig)
    ii=find(v_pres==v_pres_orig(i));
    salt_cor(i)=salt_cor_unsort(ii);
end

% Now put salt_cor into the proper dimensions

if n>m
    salt_cor=salt_cor';
end
