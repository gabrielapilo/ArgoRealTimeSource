%retrieve_doxy
%get doxy data from the original matfiles for oxygen floats where it didn't
%transfer correctly...


aa = dbdat.argos_id;
if floor(aa/100)==210
   aa = aa-21000;
elseif floor(aa/100)==212
   aa = aa-21200;
end

ifnm = [ipth 'float' num2str(aa)];
ofnm = [opth 'float' num2str(dbdat.wmo_id)];

load(ifnm);
eval(['float = float' num2str(aa) ';']);

if(~isempty(float(j+1).oxy_raw))
    fpp(j).oxy_raw=float(j+1).oxy_raw;
    fpp(j).oxyT_raw=float(j+1).oxyT_raw;
    fpp(j).oxy_qc(1:length(float(j+1).oxy_raw))=0;
    fpp(j).oxyT_qc(1:length(float(j+1).oxy_raw))=0;
end
   save(ofnm,'float');


    