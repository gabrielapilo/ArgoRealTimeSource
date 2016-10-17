% mail_out_overdue_floats
% mail out function for sending overdue float list to operators

		
system(['cat ' fnm4 '| mail -s "Overdue floats" ' ARGO_SYS_PARAM.overdue_operator_addrs]);
