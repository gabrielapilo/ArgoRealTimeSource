%fix missions with too many 'new'


global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
getdbase(-1)
aic=ARGO_ID_CROSSREF;
afdb=THE_ARGO_FLOAT_DB;

for j=522:599
    
    if afdb(j).subtype==1004
        [fpp,dbdat]=getargo(afdb(j).wmo_id);
        if ~isempty(fpp)
            fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id) 'aux.mat']
            missNO=[];
            
            load(fn);
            if dbdat.maker==4
                dff=40;
            else
                dff=15;
            end
            
            missNO(1)=1;
            for i=2:length(floatTech.Mission)
                differs=0;
                ms=floatTech.Mission(i);
                names = fieldnames(ms);
                try
                    missNO(i)=floatTech.Mission(i-1).mission_number;
                catch
                    missNO(i)=0;
                end
                
                for g=i-1:-1:1
                    differs=0;
                    try
                        missNO(g)=floatTech.Mission(g).mission_number;
                    catch
                        missNO(g)=0;
                    end
                    if missNO(g)~=0
                        
                        for gg=1:length(names)
                            if isempty(strmatch('mission_number',names{gg})) & isempty(strmatch('new_mission',names{gg}))
                                v1=getfield(ms,names{gg});
                                v2=getfield(floatTech.Mission(i-1),names{gg});
                                if isnan(v1);v1=-99;end
                                if isnan(v2);v2=-99;end
                                
                                if strmatch(names{gg},'DeepProfilePistonPos') %& (pn-i-1==1);
                                    if abs(v1-v2)>dff
                                        differs=1;
                                    end
                                elseif strmatch(names{gg},'DeepProfileBuoyancyPos') %& (pn-i-1==1);
                                    if abs(v1-v2)>dff
                                        differs=1;
                                    end
                                elseif strmatch(names{gg},'ParkPistonPos') % & (pn-i-1==1);
                                    if abs(v1-v2)>dff
                                        differs=1;
                                    end
                                elseif strmatch(names{gg},'ParkBuoyancyPos') % & (pn-i-1==1);
                                    if abs(v1-v2)>dff
                                        differs=1;
                                    end
                                elseif strmatch(names{gg},'TimeOfDay') % & (pn-i-1==1);
                                    if strmatch('DISABLED',v2)
                                        floatTech.Mission(i-1). TimeOfDay=NaN;
                                    end
                                else
                                    if v1~=v2
                                        differs=1;
                                    end
                                end
                            end
                        end
                        if ~differs
                            floatTech.Mission(i).mission_number = floatTech.Mission(g).mission_number;
                            floatTech.Mission(i).new_mission = 0;
                            break
                        end
                    end
                    if differs
                        floatTech.Mission(i).mission_number = max(missNO)+1;
                        floatTech.Mission(i).new_mission = 1;
                    end
                end
                
            end
            
            save (fn,'floatTech','-v6');
            
            metadata_nc(dbdat,fpp)
            
            for i=1:length(fpp)
                [missmeta,cfg]=getmission_number(dbdat.wmo_id,i,0,dbdat);
                pno=sprintf('%3.3i',i)
                fnm=['/home/argo/ArgoRT/netcdf/' num2str(dbdat.wmo_id) '/R' num2str(dbdat.wmo_id) '_' pno '.nc'];
                missn=getnc(fnm,'CONFIG_MISSION_NUMBER');
                
                if missn~=missmeta
                    [missn missmeta]
                    % for kk=1:length(fpp)
                    argoprofile_nc(dbdat,fpp(i));
                end
            end
        end
    end
end
        
        
