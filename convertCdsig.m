%
% INPUT  
%       Cdsig - the raw Cdom measurement from the float
%       
%       wmoid - used to find the O2 calibration coefficients for the float
%          being processed
%       CDOM - the derived  value
%
%
% AUTHOR: Udaya Bhaskar - December 2014 - converted for CDOM, Ann Thresher Jan 2015
%
% USAGE: [CDOM] = convertCdsig(Cdsig,wmoid);

function [CDOM] = convertCdsig(Cdsig,wmoid)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO

if isempty(ARGO_BIO_CAL_WMO)
    getBIOcaldbase
end

cd=Cdsig;
if(isnan(cd))
    CDOM=nan;
    return
end
kl=find(cd==0);

cd(kl)=NaN;

kk=find(ARGO_BIO_CAL_WMO==wmoid);
if isempty(kk)
    logerr(3,['error on convert FSig to CDOM: could not find calibration for ' num2str(wmoid)]);
    CDOM=0;
    return
else
    cal=THE_ARGO_BIO_CAL_DB(kk);
end

% kk=find(ARGO_O2_CAL_WMO==wmoid);
% if isempty(kk)
%     logerr(3,['error on convert FSig to CDOM: could not find calibration for ' num2str(wmoid)]);
%     CDOM=0;
%     return
% else
%     cal=THE_ARGO_O2_CAL_DB(kk);
% end

% The expression used for converting is as follows
% CDOM = Scale Factor * (Output - Dark Counts)
% CDOM=cal.a31*(Cdsig - cal.a32)
%


cdom = cal.CDOMscale*(cd - cal.CDOMdc);

CDOM=cdom;



