% This MUST be run within the Argo RT root directory 
%
% Plotting routines especially can throw up warnings - so make sure the
% session doesn't halt in the debugger if such a warning occurs
dbclear if warning

% addpath src

[st,lfile] = system('ls -1tr argos_downloads/argos2*.log | tail -1');
if st~=0
   error('Cannot find latest download file');
end

global ARGO_SYS_PARAM

set_argo_sys_params

strip_argos_msg(lfile);

web_processing_report
