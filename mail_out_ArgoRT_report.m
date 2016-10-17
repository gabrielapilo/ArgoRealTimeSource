% mail_out_ArgoRT_report
% mail out function for sending ArgoRT reports to operators

%[st,ww]=system(['cat ' rptfnm ' | mail -s"[SEC=UNCLASSIFIED] ArgoRT Report oeb-mog-uot" ' ARGO_SYS_PARAM.operator_addrs])

system(['cat ' rptfnm ' | mail -s "ArgoRT Report" ' ARGO_SYS_PARAM.operator_addrs]);
