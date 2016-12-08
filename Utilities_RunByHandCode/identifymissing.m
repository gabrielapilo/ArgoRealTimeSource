% check for kmissing files at the GDAC and put them in export for delivery.
%  Then do the delivery!!!

% find floats with missing profiles at the GDAC but the profile exists
% here - then deliver them!
global ARGO_ID_CROSSREF
getdbase(-1)
wmos = ARGO_ID_CROSSREF(:,1);
for i=1:length(wmos)
    a=dirc(['/home/argo/ArgoRT/netcdf/' num2str(wmos(i)) '/R' num2str(wmos(i)) '_*.nc']);
    [m,n]=size(a);
    for j=1:m-2
        fnm=['/home/argo/ArgoRT/netcdf/' num2str(wmos(i)) '/' a{j,1}];
        fnm2=['/home/argo/ArgoDM/cron_jobs/gdac_mirror/csiro/' num2str(wmos(i)) '/profiles/' a{j,1}];
        [c,d]=system(['diff ' fnm ' ' fnm2]); 
        if ~isingdac(fnm)
            fnm
            system(['cp ' fnm ' /home/argo/ArgoRT/export'])
        end
        if ~isempty(d) & isingdac(fnm)==1
            fnm
            system(['cp ' fnm ' /home/argo/ArgoRT/export'])  
        end
    end
end
%writeGDAC
            
