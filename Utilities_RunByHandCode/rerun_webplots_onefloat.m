%% regenerate web files to fix inconsistencies....

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global ARGO_REPORT  ARGO_RPT_FID
global PREC_FNM PROC_REC_WMO PROC_RECORDS

wmos = {
    5905209
    5905040
    5905201
    5905032
    5903908
    7900316
    5903912
    5904996
    1901340
    5905039
    7900609
    5904925
    };

getdbase(0);
if isempty(wmos) | ~exist('wmos','var')
else
    
    for i=1:length(wmos)
        i=i
        %    try
        %        mkdir(['netcdf/' num2str(wmos(i))])
        %    end
        [fpp,dbdat]=getargo(wmos{i});
        if ~isempty (fpp)
%             for  j=1:length(fpp)
                web_profile_plot(fpp(end),dbdat);
            web_float_summary(fpp,dbdat,1);
            time_section_plot(fpp);
            waterfallplots(fpp);
            locationplots(fpp);
            tsplots(fpp);
                
%             end
        end
    end
end
