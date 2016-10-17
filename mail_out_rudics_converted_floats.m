% mail out function for notifying 'dead float talking'
function mail_out_dead_float(wmo_id)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF

filerudics='rudicsfloat.txt';
fff=fopen(filerudics,'w');
for k=1:length(wmo_id)

    kk=find(ARGO_ID_CROSSREF(:,1)==wmo_id(k));

    fprintf(fff,'%s: %s; %s; %s \n','Hey - rudics float reported!',...
        num2str(ARGO_ID_CROSSREF(kk,1)),num2str(ARGO_ID_CROSSREF(kk,2)),num2str(ARGO_ID_CROSSREF(kk,5)));
end
fclose(fff);
		
system(['cat ' filerudics ' | mail -s" Rudics floats reported in last 24 hours ' ' " '  ARGO_SYS_PARAM.overdue_operator_addrs])
