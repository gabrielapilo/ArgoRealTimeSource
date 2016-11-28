% mail out function for sending .log or .msg
function mail_out_argos_log_error(filename,fl)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF

kk=find(ARGO_ID_CROSSREF(:,1)==fl);


filebad='badfile.txt';
fff=fopen(filebad,'w');
fprintf(fff,'%s:%s;%s;%s',filename,num2str(ARGO_ID_CROSSREF(kk,1)),num2str(ARGO_ID_CROSSREF(kk,2)),num2str(ARGO_ID_CROSSREF(kk,5)));
fclose(fff);
system(['cat ' filebad ' | mail -s" Argos log file caused crash ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
