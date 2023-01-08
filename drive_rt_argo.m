% This MUST be run within the Argo RT root directory 
%
% Plotting routines especially can throw up warnings - so make sure the
% session doesn't halt in the debugger if such a warning occurs
dbclear if warning

% addpath src

%[st,lfile] = system('ls -1tr argos_downloads_new/argos2*.log | tail -1');
%if st~=0
%  error('Cannot find latest download file');
%end

global ARGO_SYS_PARAM

set_argo_sys_params

% Check to see if there are any argos files available
%today = now;
%day1 = datenum(str2num(datestr(now,'YYYY')),1,1);
%doy = round(today-day1);

%if doy - str2num(lfile(end-7:end-5)) >= 1; % if argos files too old, process iridium only
    strip_argos_msg('iridium')
%else
%   strip_argos_msg(lfile)
%end

web_processing_report
