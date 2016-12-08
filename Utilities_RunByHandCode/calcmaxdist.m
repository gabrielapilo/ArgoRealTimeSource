set_argo_sys_params

global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

getdbase(0)

wmo=ARGO_ID_CROSSREF(:,1);
for i=1:length(wmo)
    [fpp,dbdat]=getargo(wmo(i));
    try
        for j=1:length(fpp)
            try
                latr=[fpp(j).lat(1) fpp(j).lat(end)];
                lonr=[fpp(j).lon(1) fpp(j).lon(end)];
                    
                [dd(i,j),ph]=sw_dist(latr,lonr,'km');
            end
        end
    end
end

for i=1:length(wmo)
    maxd(i)=max(dd(i,:));
    meand(i)=mean(dd(i,:));
    med(i)=median(dd(i,:));
end
