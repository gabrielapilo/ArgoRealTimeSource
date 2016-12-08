global ARGO_SYS_PARAM

global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
getdbase(-1)
aic=ARGO_ID_CROSSREF;
afdb=THE_ARGO_FLOAT_DB;

for i=501:600 %length(aic)
    m=[];
    if afdb(i).iridium & ~afdb(i).em & afdb(i).maker~=3
        
        fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(afdb(i).wmo_id) 'aux.mat']
try
        load(fn);
        if ~isempty(floatTech)
            for j=1:length(floatTech.Mission)
                m(j)=floatTech.Mission(j).mission_number;
            end
            if max(m)>4
                i=i
                afdb(i).wmo_id
                max(m)
 fix_iridium_missions_by_wmo               
            end
        end
catch
    a=['Empty float files ' num2str(afdb(i).wmo_id) ]
end
        
    end
end

    