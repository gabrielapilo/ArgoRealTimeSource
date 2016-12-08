%% regenerate web files to fix inconsistencies....

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global ARGO_REPORT  ARGO_RPT_FID
global PREC_FNM PROC_REC_WMO PROC_RECORDS

getdbase(0);

for i=1:length(THE_ARGO_FLOAT_DB)
    wmos(i) = THE_ARGO_FLOAT_DB(i).wmo_id;
end
rebuild=1;
for i=1:length(wmos)
    i=i
%    try
%        mkdir(['netcdf/' num2str(wmos(i))])
%    end
    [fpp,db]=getargo(wmos(i));
    if ~isempty (fpp)
        for  j=1:length(fpp)
            web_float_summary(fpp,db,rebuild);
            web_profile_pages_noplot(fpp(j),db)
        end
    end
end
