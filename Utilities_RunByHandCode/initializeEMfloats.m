%  initializeEMfloats
%
% the EM flaots deployed by Helen Phillips are now dead and need to be
% processed and added to the argo database.  This program takes the
% spreadsheet, correlates the hull id with the wmo id and creates all
% necessary files after populating the float structure.  This should be
% useable for other EM floats as well.\

%load /home/argo/ArgoRT/EMsrc/emapex_raw.mat

getdbase(-1)
global ARGO_ID_CROSSREF
global ARGO_SYS_PARAM

a=dirc('/home/argo/ArgoRT/EMsrc/float*raw.mat')

[m,n]=size(a);

for ie=2:m
    
    load (a{ie,1});
    b=str2num(a{ie,1}(6:12));
    cc=find(ARGO_ID_CROSSREF==b);
    eval(['f=float' num2str(ARGO_ID_CROSSREF(cc,5))]);
    eval(['load ema-vitals/ema-' num2str(ARGO_ID_CROSSREF(cc,5)) '-vit.mat;'])

    dbdat=getdbase(b);
    clear float
    processEMfloats;
    
    
    fnm=[ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(b) '.mat'];
    save(fnm,'float','-v6');
    web_float_summary(float,dbdat,1);
    time_section_plot(float);
    waterfallplots(float);
    locationplots(float);
    tsplots(float);
    trajectory_nc(dbdat,float,-1);

    close('all')
 
end
    

    
    
    