%
% INPUT  
%       Bbsig - the raw BackScattering measurement from the float
%       
%       wmoid - used to find the Backscattering coefficients for the float
%          being processed
%       BS - the derived Backscattering value
%       wavelength - the sensor wavelength needed to select teh correct cal
%       coeffs with the implementation of multiple sensors on some bio
%       floats
%
%  for this routine, I think it's necessary to get the correct cal coeffs
%  before entering.  
%
%
% AUTHOR: Udaya Bhaskar - December 2014
%  additional wavelengths added - AT August 2015
% changed how this works - no longer need 'park' but do need wavelength and
% T/S values before works:
%
% USAGE: [BS] = convertBbsig(Bbsig,wmoid,wavelength);

function [BS,totbbt] = convertBbsig(Bbsig,fpT,fpS,wavelength,cal)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
% global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

bsk=Bbsig;
if(isnan(bsk))
    BS(1:length(bsk))=nan;
    return
end
kl=find(bsk==0);

bsk(kl)=NaN;

% we need to send these from the calling program because that's where we have 
%     all of the relevant information for simplicity
% kk=find(ARGO_O2_CAL_WMO==fp.wmo_id);
if isempty(cal)
    logerr(3,['error on convert BbSig to Backscattering: could not find calibration for ' num2str(wmoid)]);
    BS=0;
    return
% else
%     cal=THE_ARGO_O2_CAL_DB(kk);
end

% The expression used for converting is as follows
% Backscattering (Beta) = Scale Factor * (Output - Dark Counts)
% bst=cal.a33*(Bbsig - cal.a34)
%
% additional parameters added as per BACKSCATTERING_PROCESSING_V1.0_EB.pdf
% Jan 2015


for j=1:length(Bbsig)
    [betasw(j),beta90sw(j),bsw(j)]=betasw_ZHH2009(wavelength,fpT(j),cal.BBPangle,fpS(j));
end

totbbt=cal.FLBBscale*(bsk - cal.FLBBdc);
bst1=totbbt-betasw; %units m-1sr-1

bst = 2*pi*cal.BBPChi*bst1; %units m-1

BS=bst;  %units m-1



