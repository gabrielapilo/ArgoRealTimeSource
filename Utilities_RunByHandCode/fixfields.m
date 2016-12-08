global ARGO_SYS_PARAM

namesfl=fieldnames(float);
% namesfp=filednames(fp);
newfield=new_profile_struct(dbdat);
namesnew=fieldnames(newfield);
for i=1:length(namesnew);
    if isfield(float,namesnew{i})
        for j=1:length(float)
            s=['newfield(j).' namesnew{i} '=float(j).' namesnew{i} ';'];
            eval(s)
        end
    end
end

float=newfield;

        