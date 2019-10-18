%used to regenerate technical, trajectory or metadata files:
%comment out what you don't need to produce...

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
getdbase(0);

%% run this for the whole database

for ii = 1:length(THE_ARGO_FLOAT_DB)

    [float,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if ~dbdat.iridium %just do the iridium floats first
        continue
    end
    if ~isempty(float)
        float = qc_tests(dbdat,float,[],1); %redo the qc properly for position only
        %and save it
        save(['matfiles/float' num2str(dbdat.wmo_id) '.mat'],'float')
%         if ~isempty(strmatch('APF11',dbdat.boardtype))
        if dbdat.iridium
            trajectory_iridium_nc(dbdat,float);
        else
            trajectory_nc(dbdat,float);
        end
%         techinfo_nc(dbdat,fpp);
%         metadata_nc(dbdat,fpp);
%     plot_tech(fpp,dbdat)
% make_tech_webpage(dbdat.wmo_id);
%         end
    end
end

%% run this for floats by WMO ID
kk = [ 5904923
    5904924
    1901347
    1901348
    5905022
    5905023
    ];

for ii = 1:length(kk)
    [float,dbdat] = getargo(kk(ii));
    if ~isempty(float)
%         trajectory_nc(dbdat,fpp);
%         techinfo_nc(dbdat,fpp);
        metadata_nc(dbdat,float);
%     plot_tech(fpp,dbdat)
% make_tech_webpage(dbdat.wmo_id);
    end
end