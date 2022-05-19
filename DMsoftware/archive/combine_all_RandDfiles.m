 set_argo_sys_params
    global ARGO_SYS_PARAM
    global ARGO_ID_CROSSREF
    if isempty(ARGO_ID_CROSSREF)
        getdbase(-1);
    end
    Dpath=['/home/argo/data/dmode/4/']; 
    
    aic=ARGO_ID_CROSSREF;
    for i = 1:length(aic);
      DP = [Dpath num2str(aic(i,1))]
      if 
          
        combineDandRfileV3_1final(aic(i,1)) 
      end
    end
    
    