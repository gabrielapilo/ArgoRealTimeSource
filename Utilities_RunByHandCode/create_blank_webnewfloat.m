% create_blank_webpages
% designed to create empty web pages for floats that died on deployment
% can be run whenever a new float is deployed, just in case(?)
%
% usage:  create_blank_web_newfloat(wmoid)
%

function create_blank_webnewfloat(wmoid)

global ARGO_SYS_PARAM
global ARGO_ID_CROSSREF

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

getdbase(-1);

for ii =  wmoid     %1:length(THE_ARGO_FLOAT_DB)
    
    [float,dbdat] = getargo(wmoid);    %getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if(isempty(float))
        web_float_summary(float,dbdat,1)
    end
end
