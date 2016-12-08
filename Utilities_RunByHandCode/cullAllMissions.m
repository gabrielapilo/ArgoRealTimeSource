% cullAllMissions
%
% run this to create all mission files for all floats (only works for files
% in the iridium_processed directory)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

getdbase(-1)
aic=ARGO_ID_CROSSREF;

for i=1:length(aic)
    db=getdbase(aic(i,1));
    if db.iridium
        cullMissions_iridium(db,-1)
    end
end

    