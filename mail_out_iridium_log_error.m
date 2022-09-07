% mail out function for sending .log or .msg
function mail_out_iridium_log_error(filename,type)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF

try
    if strfind('f',filename)
        fl=str2num(filename(2:5));
    else
        fl=str2num(filename(1:4));
    end
catch
    fl = str2num(filename);
end
if ~isempty(fl)
    kk=find(ARGO_ID_CROSSREF(:,2)==fl);
else
    kk = [];
end


filebad='badfile.txt';
fff=fopen(filebad,'w');
fprintf(fff,'%s:%s;%s',filename,num2str(ARGO_ID_CROSSREF(kk,1)),num2str(ARGO_ID_CROSSREF(kk,5)));
fclose(fff);
[st,host] = unix('hostname')
if strcmp(deblank(host),'oa-40-hba')
	if (type == 1)
		system(['cat ' filebad ' | ' ARGO_SYS_PARAM.root_dir 'xwmail.sh mail -s"[SEC=OFFICIAL] Missing Iridium log/msg file for ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	elseif (type == 2)
		system(['cat ' filebad ' | ' ARGO_SYS_PARAM.root_dir 'xwmail.sh mail -s"[SEC=OFFICIAL] Iridium log/msg file size zero ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	elseif (type == 3)
		system(['cat ' filebad ' | ' ARGO_SYS_PARAM.root_dir 'xwmail.sh mail -s"[SEC=OFFICIAL] Iridium log/msg file caused crash ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	elseif (type == 4)
		system(['cat ' filebad ' | ' ARGO_SYS_PARAM.root_dir 'xwmail.sh mail -s"[SEC=OFFICIAL] phy file caused crash ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	end
else
	if (type == 1)
		system(['cat ' filebad ' | mail -s"[SEC=OFFICIAL] Missing Iridium log/msg file for ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	elseif (type == 2)
		system(['cat ' filebad ' | mail -s"[SEC=OFFICIAL] Iridium log/msg file size zero ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	elseif (type == 3)
		system(['cat ' filebad ' | mail -s"[SEC=OFFICIAL] Iridium log/msg file caused crash ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	elseif (type == 4)
		system(['cat ' filebad ' | mail -s"[SEC=OFFICIAL] phy file caused crash ' filename ' " ' ARGO_SYS_PARAM.operator_addrs])
	end
end
end
