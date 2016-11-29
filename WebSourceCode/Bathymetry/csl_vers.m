% GUI to set global var which determines the CSL version used

function csl_vers

global CSL_Version

CSL_Version = menu('CSL & Dataset version', ...
		   'WOD94 levels (defunct)', ...
		   'CARS2000 (56 levels)', ...
		   'vers 3 - 2004 - 79 levels');

vers = CSL_Version;

if vers<1 | vers>3
   disp('How did you stuff that? Do it again!')
else
   pth = dat_path(vers);
   disp(['Data will be sought in ' pth]);
end
