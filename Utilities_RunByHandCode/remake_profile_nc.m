%recreate netcdf files for selected floats

 global ARGO_ID_CROSSREF
 getdbase(-1)
 aic=ARGO_ID_CROSSREF;
% bad = [];
for i=1:length(aic)
    disp(i)
    [fpp,dbdat]=getargo(aic(i,1));
    if dbdat.wmo_id ~= 5905023 & dbdat.wmo_id ~= 1901348 & dbdat.wmo_id ~= 5905165
        continue
    end
    if any([dbdat.flbb,dbdat.flbb2,dbdat.irr, dbdat.irr2, ...
            dbdat.pH])
%     if dbdat.oxy
        for j=1:length(fpp)
            [i j]
            if ~isempty(fpp(j).lat)
                try
                    argoprofile_Bfile_nc(dbdat,fpp(j))
                catch
                    bad = [bad;i,j];
                end
            end
        end
    end
end