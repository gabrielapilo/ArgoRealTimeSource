% forceSoloII_processing
%
% read solo2 matfiles and force processing of any new profiles

addpath /home/argo/ArgoRT/PHYSbd/WHOI_SOLO-II_Processing_Software;
addpath /home/argo/ArgoRT/PHYSbd/WHOI_SOLO-II_Processing_Software/matlab;

dataprefix=['/home/argo/ArgoRT/solo2_data/mat'];
b='running solo II processing'
a=dirc([dataprefix '/*.mat']);

[m,n]=size(a)
for i=1:m
    load ([dataprefix '/' a{i,1}]);
    
    generate_new_Soloprofiles(data);

end
