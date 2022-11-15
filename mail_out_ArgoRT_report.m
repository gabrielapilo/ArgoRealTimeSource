% mail_out_ArgoRT_report
% mail out function for sending ArgoRT reports to operators

%[st,ww]=system(['cat ' rptfnm ' | mail -s"[SEC=UNCLASSIFIED] ArgoRT Report oeb-mog-uot" ' ARGO_SYS_PARAM.operator_addrs])
[st,host] = unix('hostname')
if strcmp(deblank(host),'oa-40-hba')
    system(['cat ' rptfnm ' | ' ARGO_SYS_PARAM.root_dir 'xwmail.sh mail -s "[SEC=OFFICIAL]_ArgoRT_Report" -r sem018@csiro.au ' ARGO_SYS_PARAM.operator_addrs]);
else
    system(['cat ' rptfnm ' | mail -s "[SEC=OFFICIAL] ArgoRT Report" ' ARGO_SYS_PARAM.operator_addrs]);
end