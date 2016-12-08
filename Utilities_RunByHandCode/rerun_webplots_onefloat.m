%% regenerate web files to fix inconsistencies....

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global ARGO_REPORT  ARGO_RPT_FID
global PREC_FNM PROC_REC_WMO PROC_RECORDS

getdbase(0);
if isempty(wmos) | ~exist('wmos','var')
else
    
    for i=1:length(wmos)
        i=i
        %    try
        %        mkdir(['netcdf/' num2str(wmos(i))])
        %    end
        [fpp,dbdat]=getargo(wmos(i));
        if ~isempty (fpp)
            for  j=1:length(fpp)
                web_profile_plot(fpp(j),dbdat);
            end
            time_section_plot(fpp);
        end
    end
end
