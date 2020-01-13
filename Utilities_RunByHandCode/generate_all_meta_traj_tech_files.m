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
% kk = [5904994; 5905006; 5905007; ...
%     5905013; 5905014; 5905015; 5905016;...
%     5905017; 5905018; 5905019; 5905020; 5905021]; % wrong sensor numbers from Roger, GP 20/Dec/2019

clc
kk = [5901165;          1901338; 1901339; 5904882; ... % 5901146 was dead on deployment
      5903955; 5904218; 5905199; 5904923; 5904924; ...
      5905167; 1901347; 5905022; 1901348; 5905165; ...
      5903629; 5903630; 5903649; 5903660; 5903679; ...
      5903678;          1901329; 5905023; 5905197; ... % /home/argo/ArgoRT/matfiles/float1901328 is empty
      5905198; 5905194; 5905395; 5905396; 5905397]; % BGC new system: [5905441; 5905442]
  
  kk = 5905446;
  
for ii = 1%24:length(kk);
    kk(ii)
    [float,dbdat] = getargo(kk(ii));
    if ~isempty(float);
%         trajectory_nc(dbdat,fpp);
%         techinfo_nc(dbdat,fpp);
        metadata_nc(dbdat,float);
%     plot_tech(fpp,dbdat)
% make_tech_webpage(dbdat.wmo_id);
    end
end

