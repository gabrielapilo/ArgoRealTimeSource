global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
set_argo_sys_params
getdbase(0);


for i=1:length(ARGO_ID_CROSSREF)
wmoid=ARGO_ID_CROSSREF(i,1)
[fpp,dbdat]=getargo(wmoid);
    if(~isempty(fpp))
        float=fpp;
	    time_section_plot(float);
	    waterfallplots(float);
        locationplots(float);
        tsplots(float);
    end
end