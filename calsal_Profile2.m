% CALSAL_CLIM  Calibrate salinity in raw (near-realtime) Argo float, and load
%         variables 's_calibrate', 'cndc_raw', 'cndc_qc', 'cndc_calibrate'
%
% INPUT  
%  float - struct array of profiles for one float. It is assumed that 
%          profiles have already been QCed.
% OUTPUT
%   s_cal - calibrated salinity, from the satellite profile.
% AUTHOR: Jeff Dunn  CMAR Oct 2007
%         Devolved from calsal.m  Aug 2006
%
% USAGE: [s_cal] = calsal_Profile2(float);
%
% note - this has been modified to apply the master calibration to a subset
% of salinity associated with a second, lower resolution profile : AT July
% 2012

function [s_cal] = calsal_Profile2(p2,s2,t2,p_c,c_ratio)

% The CTD reference set variables are loaded once and retained thereafter 
global ARGO_SYS_PARAM

% Do not work on any empty profiles, partly because they crash sw_ routines.


   % Now apply calibration to unscreened profiles, to retain values despite
   % QC flagging.
   cndr  = sw_cndr(s2,t2,p2);    
   s_cal = sw_salt(cndr*c_ratio,t2,p_c);

 
%---------------------------------------------------------------------------
