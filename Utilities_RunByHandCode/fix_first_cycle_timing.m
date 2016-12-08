% fix_first_cycle_timing(wmo)
%
% this function takes a wmo_id and assumes that the timing of the first
% profile is affected by test messags. It reruns the float using the best
% argos download and recreates the profie files and trajectory files with
% the correct data.

function fix_first_cycle_timing(wmo)

[fpp,dbdat]=getargo(wmo);

opts.redo=1;

[file]=find_argos_download(wmo,1)
strip_argos_msg(file,wmo,opts);
[fpp,dbdat]=getargo(wmo);
trajectory_nc(dbdat,fpp,-1);
