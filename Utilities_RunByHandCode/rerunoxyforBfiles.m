 
 global ARGO_ID_CROSSREF
 getdbase(-1)
 aic=ARGO_ID_CROSSREF;

for i=1:length(aic)
    i=i
    [fpp,dbdat]=getargo(aic(i,1));
    if dbdat.oxy
        for j=1:length(fpp)
            [i j]
            if ~isempty(fpp(j).lat)
                argoprofile_Bfile_nc(dbdat,fpp(j))
            end
        end
    end
    ncclose('all')
    close('all')
end