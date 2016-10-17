%
% INPUT  
%       Fsig - the raw Fsig measurement from the float
%       
%       wmoid - used to find the O2 calibration coefficients for the float
%          being processed
%       CP - the derived particulate value
%
%
% AUTHOR: Udaya Bhaskar - December 2014
%
% USAGE: [CHL] = convertFsig(Fsig,wmoid);

function [CP] = convertTmiss(Tmcnts,wmoid)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO

if isempty(THE_ARGO_BIO_CAL_DB)
    getBiocaldbase
end

cp0=Tmcnts;
if(isnan(cp0))
    CP=nan;
    return
end
kl=find(cp0==0);

cp0(kl)=NaN;

kk=find(ARGO_BIO_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert Tm counts to Particle beam attenuation: could not find calibration for ' num2str(wmoid)]);
    CP=0;
    return
else
    cal=THE_ARGO_BIO_CAL_DB(kk);
end

% The expression used for converting is as follows
% Chla = Scale Factor * (Output - Dark Counts)
% chla=cal.a31*(Fsig - cal.a32)
%


cp1 = (cp0-cal.TMdark)*(cal.TMref - cal.TMdark);
cp = -1/25*log(cp1);  % units "/m"

CP=cp;



