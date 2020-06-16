% THERMAL_LAG_CALC  Sets up call to celltm_sbe41 for a single profile, 
%    to apply thermal lag correction to salinity.
%
% INPUT
%  dbdat- Database record for this float  
%  fp   - structure for one profile. It is assumed that has been QCed.
%
% OUTPUT
%  fp -  fp but with adjusted 's_calibrate' vector (values corrected unless they
%        are QC flagged) and set TL_cal_done=1.
%
% NOTE:  Assume SBE-41 T/S sensor
%
% AUTHOR: Jeff Dunn  CMAR/BoM August 2006
%
% USAGE: fp = thermal_lag_calc(dbdat,fp);

function fp = thermal_lag_calc(dbdat,fp)

if fp.TL_cal_done==1
   logerr(3,['THERMAL_LAG_CALC: PrNum ' num2str(fp.profile_number) ...
	     ' cal aborted as TL_cal_done flag already set']);
   return
end
 
% Doco in celltm_sbe41.m quotes alpha=.021 & tau=21.0 for Apex floats, and 
% alpha=.164 and tau=5.87 for "Ice-Tethered profiles with asc rates ~.25
% dbar/s"
% GSP, 16/6/2020: we are now using tau and alpha from Johnson et al., 2007
%
%   In write_celltm_and_press_corr_apex_sbe41.m (author unknown) alpha=.173 
% and tau=6.07 are used, without comment. Tseviet says these are the coeffs  
% for the SBE-41CP sensors, of which we have none (so far).
%
% On a single test profile the SBE-41CP coeffs gave an adjustment mostly about
% 2.3 times the size of adjustment given by the SBE-41 coeffs! 

if strcmp(dbdat.ctd_sensor_type,'sbe-41')
   alpha = .0267;  
   tau = 18.6;
elseif strcmp(dbdat.ctd_sensor_type,'sbe-41cp')
   alpha = .141;  
   tau = 6.68;
else
   % Don't know how to cal this, so just return (without setting TLcal flag)
   return
end

fp.TL_cal_done = 1;

% If we only use T,S,P that have passed QC then obviously we will not have
% a corrected version of the QC-rejected values [which we are meant to
% supply in var PSAL_ADJUSTED]   If we use all values irrespective of QC
% then bad T and P will potentially muck up the calibration.  We could recode
% celltm_sbe41, at the stage of interpolating back from 1Hz to orignal P, so
% that we interpolate to all P irrespective of QC.  I will take approach of
% only using "good" values - leaving "bad" ones unadjusted, with
% justification that this correction is small, especially compared to 
% whatever signal/aberation lead to the QC flagging.

ss = qc_apply(fp.s_calibrate,fp.s_qc);
tt = qc_apply(fp.t_raw,fp.t_qc);
pp = qc_apply(fp.p_calibrate,fp.p_qc);

kk = find(~isnan(ss) & ~isnan(tt) & ~isnan(pp));
if length(kk)<2
   return
else
   ss = ss(kk);
   tt = tt(kk);
   pp = pp(kk);
end

% Since pp has been QC it will be monotonic. Ascent rate of .09 seems an
% accepted mean value for "Apex260" floats.
e_time = (pp-max(pp))/-.09;
if (any((diff(fp.p_raw))<0))
    try
        fp.s_calibrate(kk) = celltm_sbe41(ss,tt,pp,e_time,alpha,tau);
    catch
        fp.s_calibrate=nan(1,length(fp.s_raw));
        fp.s_calibrate(kk)=ss;
        return
    end
else
    fp.s_calibrate(kk) = ss(kk);
end

%-----------------------------------------------------------------------------
