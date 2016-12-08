%% code for Lisa to get these into her directories easily
% CHANGE 'directory' TO THE RIGHT DIRECTORY NAME
fns = dir('directory/*.nc');
for a = 1:length(fns)
    ii = strfind(fns(a).name,'_');
    wmo = fns(a).name(1:ii-1);
    system(['mv directory/' fns(a).name ' /home/ArgoRT/netcdf/' num2str(wmo) '/' ])
end