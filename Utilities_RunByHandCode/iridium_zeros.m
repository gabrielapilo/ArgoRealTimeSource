%find all iridium profiles with 0 first or surface points...

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

wmoid=ARGO_ID_CROSSREF(:,1);
fileout='zerofirstpoints.txt'
fid=fopen(fileout,'w');

for i=1:length(wmoid)
    [fpp,dbdat]=getargo(wmoid(i));
    if dbdat.iridium
        for j=1:length(fpp)
            zz=min(fpp(j).p_raw);
            if(zz==0)
                fprintf(fid,'%s %s\n',num2str(wmoid(i)),num2str(j));
            end
        end
    end
end
