%% copy files from one directory to each floats netcdf directory
clear
trajfils = '/home/argo/ArgoRT/trajchecker/netcdf/';
fn = dir([trajfils '/*.nc']);

for a = 1:length(fn)
    system(['cp ' trajfils fn(a).name ' /home/argo/ArgoRT/netcdf/' fn(a).name(1:end-9) '/'])
    
end
%then ran writeGDAC manually to transfer the files to ifremer only.