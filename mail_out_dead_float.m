% mail out function for notifying 'dead float talking'
% 
function mail_out_dead_float(wmo)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF

kk=find(ARGO_ID_CROSSREF(:,1)==wmo);

filedead='deadfloat.txt';
fff=fopen(filedead,'w');
fprintf(fff,'%s: %s; %s; %s','Hey - dead float talking!',...
    num2str(ARGO_ID_CROSSREF(kk,1)),num2str(ARGO_ID_CROSSREF(kk,2)),num2str(ARGO_ID_CROSSREF(kk,5)));
fclose(fff);
		
system(['cat ' filedead ' | mail -s "[SEC=UNCLASSIFIED] Warning - dead float alive? ' num2str(wmo) ...
    ' "  '  ARGO_SYS_PARAM.overdue_operator_addrs])
