#!/bin/csh

cd /home/argo/ArgoRT/

/usr/local/bin/setupxvfb 2
export DISPLAY=:2


/home/matlab7.2/bin/matlab -nosplash -nodesktop -c 1712@plume < src/drive_web_report.m

# The following line removes daily processing report pages greater than 20 days
# old. It may be desirable.
#
# find /home/gronell/pub_web/ArgoRT/processing/* -name "report*html" -mtime +21 -exec rm -f {} \;
