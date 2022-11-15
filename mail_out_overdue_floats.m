% mail_out_overdue_floats
% mail out function for sending overdue float list to operators

[st,host] = unix('hostname')
if strcmp(deblank(host),'oa-40-hba')		
system(['cat ' fnm4 '| ' ARGO_SYS_PARAM.root_dir 'xwmail.sh mail -s "[SEC=OFFICIAL] Overdue floats" -r sem018@csiro.au ' ARGO_SYS_PARAM.overdue_operator_addrs]);
else
system(['cat ' fnm4 '| mail -s "[SEC=OFFICIAL] Overdue floats" ' ARGO_SYS_PARAM.overdue_operator_addrs]);
end
