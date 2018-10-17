%apply flags for the drifting SBE floats
%RC Sept, 2018

fid = fopen('/home/argo/ArgoRT/salty_drift_DodgyCTDList.csv');
c = textscan(fid,'%f%f%f','Delimiter',',')
fclose(fid);

for a = 61:62%length(c{1})
    rerun_grey_listed(c{1}(a), c{2}(a),350,-1,c{3}(a))
end