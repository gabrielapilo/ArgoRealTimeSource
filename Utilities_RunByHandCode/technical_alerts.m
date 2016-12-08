% technical_alerts - this  is designed to check each float once a week and
% email if there are suspicious changes to the technical parameters that
% indicate problems with the float!

global ARGO_ID_CROSSREF

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

getdbase(0);
filealert='tech_alert.txt';
fff=fopen(filealert,'w');


for ii =1:length(THE_ARGO_FLOAT_DB)
    spres=0;
    pbv=0;
    ip=0;
    pap=0;
    prp=0;
    bottpp=0;
    spiston=0;
 
    [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if dbdat.maker==4
        cv=10;
    else
        cv=3;
    end
    if exist('fpp','var') & exist('dbdat','var') & length(fpp)>1
        [ii dbdat.wmo_id]
        if(julian(clock)-fpp(end).jday<25)
            if(strmatch(dbdat.status,'live'));
                if(abs(fpp(end).surfpres-fpp(max(1,length(fpp)-2)).surfpres)>10);spres=1;end
                if(isfield(fpp,'parkbatteryvoltage'))
                    if(abs(fpp(end).parkbatteryvoltage-fpp(max(1,length(fpp)-2)).parkbatteryvoltage)>1);pbv=1;end
                end
                if(abs(fpp(end).p_internal-fpp(max(1,length(fpp)-5)).p_internal)>.6);ip=1;end
                clear f
                for jj=1:length(fpp)
                    if ~isempty(fpp(jj).p_raw)
                        f(jj)=max(fpp(jj).p_raw);
                    end
                end
                if (dbdat.subtype == 1007 | dbdat.subtype == 1008) & max(diff(f))>500

                else
                    if (length (fpp)>3);
                        if(isfield(fpp,'parkpistonpos'))
                            if(fpp(end).parkpistonpos-fpp(max(1,length(fpp)-2)).parkpistonpos>cv);pap=1;end
                        end
                    end
                    if(isfield(fpp,'profilepistonpos'))
                        if(abs(fpp(end).profilepistonpos-fpp(max(1,length(fpp)-3)).profilepistonpos)>cv);prp=1;end
                    elseif (isfield(fpp,'bottompistonpos'))
                        if(abs(fpp(end).bottompistonpos-fpp(max(1,length(fpp)-3)).bottompistonpos)>cv);bottpp=1;end
                    end
                    if(isfield(fpp,'pistonpos'))
                        if(fpp(end).pistonpos-fpp(max(1,length(fpp)-2)).pistonpos>20);spiston=1;end
                    end
                end
            end
            if (spres | pbv | ip | pap | prp | bottpp | spiston)
                mail_out_tech_alerts
            end
        end
    end
end

fclose(fff);

system(['cat ' filealert ' | mail -s" Warning - floats in difficulty? '  ' " ' 'rebecca.cowley@csiro.au']); %, alan.poole@csiro.au, craig.hanstein@csiro.au']);
