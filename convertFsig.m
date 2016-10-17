%
% INPUT  
%       Fsig - the raw Fsig measurement from the float
%       
%       wmoid - used to find the O2 calibration coefficients for the float
%          being processed
%       CHL - the derived chlorophyll value
%
% AUTHOR: Udaya Bhaskar - December 2014
%
% USAGE: [CHL] = convertFsig(Fsig,wmoid);

function [CHL] = convertFsig(Fsig,wmoid)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO

if isempty(ARGO_BIO_CAL_WMO)
    getBIOcaldbase
end

ch=Fsig;
if(isnan(ch))
    CHL(1:length(ch))=nan;
    return
end
kl=find(ch==0);

if ~isempty(kl)
    ch(kl)=NaN;
end

kk=find(ARGO_BIO_CAL_WMO==wmoid);
if isempty(kk)

    logerr(3,['error on convert FSig to chlorophyll: could not find calibration for ' num2str(wmoid)]);
    CHL=0;
    return
else
    cal=THE_ARGO_BIO_CAL_DB(kk);
end

% The expression used for converting is as follows
% Chla = Scale Factor * (Output - Dark Counts)
% chla=cal.a31*(Fsig - cal.a32)
%


chla = cal.FLBBCHLscale*(ch - cal.FLBBCHLdc);

CHL=chla;



