%retrieve_phy_data  - polynya float data
%
% this script moves any .phy files from /home/ftp/incoming to
% /home/argo/ArgoRT/iridium_data for processing

global ARGO_SYS_PARAM

system(['mv /home/ftp/incoming/*.phy ' ARGO_SYS_PARAM.iridium_path])
system(['chmod go+rw ' ARGO_SYS_PARAM.iridium_path '*.phy'])

%update to use the new ftp area dedicated for argo:
% Bec Cowley, June, 2016
ts = ftp('pftp.csiro.au','argo','B6uPnhH9ca');
cd(ts,'iridium_data')
mput(ts,'/home/ftp/incoming/*.phy')
close(ts);