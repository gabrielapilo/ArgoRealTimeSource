% mail out function for notifying 'dead float talking'
% 
function mail_out_dead_float(wmo)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF

kk=find(ARGO_ID_CROSSREF(:,1)==wmo);

% Check if its a newsystem float
newsystem_fl = load([ARGO_SYS_PARAM.root_dir 'src/newsystem.txt']);
if isempty(find(ARGO_ID_CROSSREF(kk,2) == newsystem_fl))

filedead='deadfloat.txt';
fff=fopen(filedead,'w');
fprintf(fff,'%s: %s; %s; %s','Hey - dead float talking!',...
    num2str(ARGO_ID_CROSSREF(kk,1)),num2str(ARGO_ID_CROSSREF(kk,2)),num2str(ARGO_ID_CROSSREF(kk,5)));
fclose(fff);

[st,host] = unix('hostname')
if strcmp(deblank(host),'oa-40-hba')		
	system(['cat ' filedead ' | ' ARGO_SYS_PARAM.root_dir 'xwmail.sh  mail -s "[SEC=OFFICIAL] Warning - dead float alive? ' num2str(wmo) ...
    ' "  '  ARGO_SYS_PARAM.overdue_operator_addrs])
else
system(['cat ' filedead ' | mail -s "[SEC=OFFICIAL] Warning - dead float alive? ' num2str(wmo) ...
    ' "  '  ARGO_SYS_PARAM.overdue_operator_addrs])
end
else
    unix(['rm -f ' ARGO_SYS_PARAM.iridium_path '*' num2str(ARGO_ID_CROSSREF(kk,2)) '.*'])
end
