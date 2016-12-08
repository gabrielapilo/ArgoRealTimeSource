% move profile numbers...

[fpp,dbdat]=getargo(5900862);
for i=length(fpp):-1:1
    fpp(i+1)=fpp(i);
    if ~isempty(fpp(i+1).profile_number)
        fpp(i+1).profile_number=i+1;
    end
end
fpp(1)=new_profile_struct(dbdat);
fnm='/home/argo/ArgoRT/matfiles/float5900862.mat'
float=fpp;
save(fnm,'float','-v6');