% cullInitialMissionAPF11
%
% for floats where the mission is contained in the log files, the first
% mission must be obtained from the .000.log file which is not usually
% read.  You must ensure that htis file is in the iridium_processed
% directory.
%
% this script uses the data from cullMissions_iridium and only obtains the
% data from the 000 file.
%
% coded Feb 2014 : AT
%

global ARGO_SYS_PARAM
global ARGO_ID_CROSSREF
aic=ARGO_ID_CROSSREF;


kk=find(aic(:,1)==wmo_id);
fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) 'aux.mat'];
% if (aic(kk,2)<1000)
%     fnm000=[ARGO_SYS_PARAM.root_dir 'iridium_data/iridium_processed/000files/0' num2str(aic(kk,2)) '.000.log']
% else
    fnm000=dirc([ARGO_SYS_PARAM.root_dir 'iridium_data/iridium_processed/000files/f' num2str(aic(kk,2)) '.000.*.system_log.txt']);
% end
 
fnm000=fnm000{end,1};

% fnm{k}(end-2:end)='log';
% fnm000=fnm{k};
% fnm000(end-6:end-4)='000';
% fnm000=fnm;
% fclose(fid)

fid2=fopen([ARGO_SYS_PARAM.root_dir 'iridium_data/iridium_processed/000files/' fnm000]);
if fid2==-1
    'Move file to 000files directory! '
    input([' Look in iridium_processed/ ' num2str(wmo_id) ' Done?'],'s')
    fid2=fopen(fnm000);
end
    
floatTech=[];

% fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) 'aux.mat']

l=fgetl(fid2);
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
    l=fgetl(fid2);
    
end

fclose(fid2);

% This is by definition mission 1

ms.mission_number = 1;
ms.new_mission = 1;

if ~isempty(ms)
    floatTech.Mission(1)=ms;
end

save (fn,'floatTech','-v6');


