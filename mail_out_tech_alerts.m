% mail out function for notifying potential technical failures
% mail_out_tech_alerts - note script not function.

kk=find(ARGO_ID_CROSSREF(:,1)==dbdat.wmo_id);

fprintf(fff,'%s: %s; %s; %s; %s \n','possible problems! Prof Num ',...
    num2str(length(fpp)),num2str(ARGO_ID_CROSSREF(kk,1)),num2str(ARGO_ID_CROSSREF(kk,2)),num2str(ARGO_ID_CROSSREF(kk,5)));
if spres
    fprintf(fff,'%s: %s %s %s \n', 'surface pressure error: old',num2str(fpp(max(1,length(fpp)-2)).surfpres), ' new:', num2str(fpp(end).surfpres));
end
if pbv
    fprintf(fff,'%s: %s %s %s \n', 'park battery voltage error: old',num2str(fpp(max(1,length(fpp)-2)).parkbatteryvoltage), ' new:', num2str(fpp(end).parkbatteryvoltage));
end
if ip
    fprintf(fff,'%s: %s %s %s \n', 'internal pressure error: old',num2str(fpp(max(1,length(fpp)-5)).p_internal), ' new:', num2str(fpp(end).p_internal));
end
if pap
    fprintf(fff,'%s: %s %s %s \n', 'park piston position error: old',num2str(fpp(max(1,length(fpp)-2)).parkpistonpos), ' new:', num2str(fpp(end).parkpistonpos));
end
if prp
    fprintf(fff,'%s: %s %s %s \n', 'profile piston position error: old',num2str(fpp(max(1,length(fpp)-3)).profilepistonpos), ' new:', num2str(fpp(end).profilepistonpos));
end
if bottpp
    fprintf(fff,'%s: %s %s %s \n', 'bottom piston position error: old',num2str(fpp(max(1,length(fpp)-3)).bottompistonpos), ' new:', num2str(fpp(end).bottompistonpos));
end
if spiston
    fprintf(fff,'%s: %s %s %s \n', 'surface piston position error: old',num2str(fpp(max(1,length(fpp)-2)).pistonpos), ' new:', num2str(fpp(end).pistonpos));
end
fprintf(fff,'\n');
