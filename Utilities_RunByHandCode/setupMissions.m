% setupMissions
% in theory, this only needs to be run once to cull all missions from
% initial iridium files and the log files where iridium doesn't deliver
% mission data in the msg files.

global ARGO_SYS_PARAM
global ARGO_ID_CROSSREF
aic=ARGO_ID_CROSSREF;

for i=307:length(aic)
    [fpp,dbdat]=getargo(aic(i,1));
    if dbdat.iridium & ~dbdat.em
        fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id) 'aux.mat']
        if ~exist(fn,'file')
            cullMissions_iridium(dbdat,-1);
        end
    end
end

