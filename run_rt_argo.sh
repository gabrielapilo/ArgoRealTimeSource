#!/bin/csh

set AROOT="/home/argo/ArgoRT"

cd $AROOT

set DATEJ=`/bin/date '+%Y%m%d_%H%M'`
set crsh_fnm=($AROOT"/run_logs/crash_"$DATEJ)
set log_fnm=($AROOT"/run_logs/run_"$DATEJ".log")

/home/argo/ArgoRT/src/ftp_get_argos

rm -f ArgoRT.log ArgoRT.crash

setenv DISPLAY `vncserver |& sed -n 's/.*desktop is \(.*\)/\1/p'`

( /home/matlab/R2015b/bin/matlab -nosplash -nodesktop < src/drive_rt_argo.m >! ArgoRT.log ) >& ArgoRT.crash

vncserver -kill $DISPLAY

# The crash file is always create, but is empty unless there has been a crash.
# So, copy it to form a proper crash report if there has been one, otherwise just
# leave it here to be deleted at the start of the next run.

find . -name ArgoRT.crash -not -size 0 -exec cp ArgoRT.crash $crsh_fnm \;

touch $log_fnm
cat ArgoRT.log >> $log_fnm
