%  load_techfile(wmo_id,cycle_number) - loads the tech file for a given float and
%  returns a character array with the variable name associated with the
%  variable value for easy scanning.

function techdata = load_techfile(wmo_id,cycle_number)


global ARGO_ID_CROSSREF;

global ARGO_SYS_PARAM;
if ispc
file=[ARGO_SYS_PARAM.folder_ncdf num2str(wmo_id) '\' num2str(wmo_id) '_tech.nc']
else
file=[ARGO_SYS_PARAM.folder_ncdf num2str(wmo_id) '/' num2str(wmo_id) '_tech.nc']
end
techdata='';
techv=getnc(file,'TECHNICAL_PARAMETER_VALUE');
techn=getnc(file,'TECHNICAL_PARAMETER_NAME');
cycle=getnc(file,'CYCLE_NUMBER');

kk=find(cycle==cycle_number);
if(~isempty(kk))
    for i=1:length(kk)
        techdata(i,1:51)=[techn(kk(i),1:30) ' ' techv(kk(i),1:20)];
    end
end


    
    