% cullMissions_iridium
%
% designed to gather mission information from iridium floats
% this is then stored in float#####aux.mat so the mission number can be
% calculated.
%
% It can be used either to cull all missions from existing floats or add
% missions from new profiles to an existing file.
%
%  AT: Feb 2014
%
%  Usage:  cullMissions_iridium(fname)
% where fname contains the path to the iridium msg file for one profile
% fname=-1 regenerates all missions from the iridium_processed directory
% for a given float - note this is based on cullMissions_iridium

function cullAPF11Missions_iridium(wmo_id,pn)

global ARGO_SYS_PARAM
global ARGO_ID_CROSSREF
aic=ARGO_ID_CROSSREF;

kk=find(aic(:,1)==wmo_id);

fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) 'aux.mat'];

if exist(fn,'file')
    try
        load(fn);
    catch
        floatTech=[];
    end
else
    floatTech=[];
end
fnm=[];
ms=[];
dbdat=getdbase(wmo_id);
% create the file name here:
pns=sprintf('%3.3i',pn+dbdat.np0);

fnm=dirc([ARGO_SYS_PARAM.iridium_path 'f' num2str(aic(kk,2)) '.' pns '.*.system_log.txt']);


if ~isempty(fnm)
    
    fnm=fnm{end,1};
    
    
    % go and get the mission data from individual iridium data files
    fid=fopen(fnm);
    if ~isempty(floatTech) & pn>1
        try
            if isempty(ms)
                ms=floatTech.Mission(pn-1);
            end
        catch  %looks like empty missions exist - fill:
            % found a good mission:
            for jl=length(floatTech.Mission)+1:pn
                floatTech.Mission(jl)=floatTech.Mission(end);
            end
            if isempty(ms)
                ms=floatTech.Mission(pn-1);
            end
        end
    elseif pn==1
        cullInitialMissionAPF11
        ms=floatTech.Mission(1);
    end
    
    % now go and get the mission information from the system log file:
    l=fgetl(fid);
    while(l~=-1)
        if isempty(strfind(l,'Mission Parameters'))
            config=strfind(l,'MissionCfg');
            if ~isempty(config) & isempty(strfind(l,'|-----'))
                l=l(config+11:end);
                par=strfind(l,' ');
                %         par2=strfind(l,')');
                if ~isempty(par)
                    mn=['ms.' l(1:par-1) '=' l(par+1:end) ';'];
                    try
                        eval(mn);
                    catch
                        mn=['ms.' l(1:par-1) '= ''' l(par+1:end) ''';'];
                        eval(mn);
                    end
                end
            end
        end
        l=fgetl(fid);
        
    end
    
    fclose(fid);
    
else
    if pn>1
        ms=floatTech.Mission(pn-1);
    elseif pn==1 & ~isempty(floatTech.Mission(1).mission_number)
        ms=floatTech.Mission(1);
    end
end

if ~isempty(ms)
    names = fieldnames(ms);
    
    if pn>1
        
        for g=pn-1:-1:1
            differs=0;
            try
                missNO(g)=floatTech.Mission(g).mission_number;
            catch
                missNO(g)=0;
            end
            if missNO(g)~=0
                for gg=1:length(names)-2
                    v1=getfield(ms,names{gg});
                    v2=getfield(floatTech.Mission(g),names{gg});
                    if strmatch(names{gg},'DeepDescentCount') & (pn-g==1);
                        if abs(v1-v2)>10
                            differs=1;
                        end
                    elseif strmatch(names{gg},'ParkDescentCount') & (pn-g==1);
                        if abs(v1-v2)>10
                            differs=1;
                        end
                    else
                        if v1~=v2
                            differs=1;
                        end
                    end
                end
                if ~differs
                    ms.mission_number = floatTech.Mission(g).mission_number;
                    ms.new_mission = 0;
                    break
                end
            end
            
            if differs
                ms.mission_number = max(missNO)+1;
                ms.new_mission = 1;
            end
        end
        
        
    else
        ms.mission_number = 1;
        ms.new_mission = 1;
    end
end
if ~isempty(ms)
    try
        floatTech.Mission(pn)=ms;
    catch
        floatTech=[];
        floatTech.Mission=ms;
    end
end

try
    fclose(fid);
end
save (fn,'floatTech','-v6');






