function make_tech_webpage(nbfloat)
% make the tech web pages for the float
% based on Ben Briat's code.

global ARGO_SYS_PARAM;
fnm = strcat(ARGO_SYS_PARAM.web_dir, 'tech/',nbfloat);
fnmi = strcat(ARGO_SYS_PARAM.web_dir, 'tech/img/',nbfloat);
fnmf =  strcat(ARGO_SYS_PARAM.web_dir, 'tech/nbfloat');

if ~isdir(fnm)
    mkdir(fnm);
end
%also check the img folder has a directory for the float
if ~isdir(fnmi)
    mkdir(fnmi);
end

nbfloat_implementation( [fnmf '/overview.html'] , nbfloat , strcat(fnm,'/overview') );
nbfloat_implementation( [fnmf '/battery.html'] , nbfloat , strcat(fnm,'/battery') );
nbfloat_implementation( [fnmf '/bathymetry.html'] , nbfloat , strcat(fnm,'/bathymetry') );
nbfloat_implementation( [fnmf '/weight.html'] , nbfloat , strcat(fnm,'/weight') );
nbfloat_implementation( [fnmf '/leak.html'] , nbfloat , strcat(fnm,'/leak') );
nbfloat_implementation( [fnmf '/others.html'] , nbfloat , strcat(fnm,'/others') );







