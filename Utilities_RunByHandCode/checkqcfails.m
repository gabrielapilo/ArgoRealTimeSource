global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB 

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

getdbase(0);

jj = 0;
wmo = NaN;
prof = NaN;
for a = 1:length(THE_ARGO_FLOAT_DB)
    wmoid = THE_ARGO_FLOAT_DB(a).wmo_id;
    [fpp,dbdat] = getargo(wmoid);
    
    for b = 1:length(fpp)
        if isempty(fpp(b).testsfailed)
            continue
        end
        if fpp(b).testsfailed(14) == 1;
            jj = jj+1;
            wmo(jj) = wmoid;
            prof(jj) = b;
        end
    end
end

fid = fopen('qctest14fails.txt','a');
for a = 1:length(wmo)
    fprintf(fid,'%s\n',[num2str(wmo(a)) ',' num2str(prof(a))])
end
fclose(fid);