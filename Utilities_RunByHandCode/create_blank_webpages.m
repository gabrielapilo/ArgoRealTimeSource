%create_blank_webpages
% designed to create empty web pages for floats that died on deployment
% can be run whenever a new float is deployed, just in case(?)

global ARGO_SYS_PARAM
global ARGO_ID_CROSSREF
global THE_ARGO_FLOAT_DB

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

getdbase(-1);

for ii =1:length(THE_ARGO_FLOAT_DB)
    
    [float,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if(isempty(float))
        web_float_summary(float,dbdat,1)
    end
end
