#!/usr/bin/env python
#
import sys, os, posix, commands, math, string, mymod, subprocess
from time import localtime, strftime, sleep, time
from datetime import datetime

my_cmd = mymod.my_cmd

#
# To upload Dfiles automatically:
#  ./upload_dfiles.py TR 5904995
#  ./upload_dfiles.py TR 5904995 > log.5904995
#

# Set the WMO ID and the Operator initials
#wmo = "5904995" ... submitted
#wmo = "5905172"
#operator = "TR"

operator = sys.argv[1]
wmo      = sys.argv[2]
print "Operator initials are " + operator
print "WMO id is " + wmo

D_ddir = "/home/argo/data/dmode/newSoftwareTest/" + wmo + "/DFILES"
O_ddir = "/home/argo/ArgoRT/DMQC/"

today = datetime.today()
datestring= today.strftime("%Y") + today.strftime("%m") + today.strftime("%d")

# Build the output file names
gtar_name = "CSIRO_" + wmo + "_" + operator + "_" + datestring + ".tar.gz"
gtar_file = O_ddir + "/" + gtar_name

# Remove the output fiules if they already exist
cmd = "rm -f " + gtar_file
print "Executing command: " + cmd
my_cmd(cmd)

# Tar  and gzip the D-files
cmd = "tar czvf " + gtar_file + " " + D_ddir + "/D*.nc"
print "Executing command: " + cmd
my_cmd(cmd)

# Check that the file's created and moved
cmd = "ls -lh " + gtar_file
ret = commands.getstatusoutput(cmd)
status = ret[0]
message = ret[1]
print ""
print ""
print "Gzipped and tarred file created with properties ..."
print message
print ""
print ""

# upload file with AW's script
cmd = "/home/argo/ArgoRT/src/DMsoftware/ftpTarFilesAll"
print "Executing command: " + cmd
subprocess.call([ cmd ])

# remove gz file
cmd = "rm -f " + gtar_file
print "Executing command: " + cmd
my_cmd(cmd)

sys.exit(0)

