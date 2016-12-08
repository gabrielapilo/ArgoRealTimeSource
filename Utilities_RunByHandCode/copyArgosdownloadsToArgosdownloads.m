a=dirc('argos*.log')
yy=input('download year (yy)=','s')
[m,n]=size(a)

for i=1:m
    oldfile=a(i,1);
    gg=strfind(oldfile{1},'argos');
    gdot=strfind(oldfile{1},'.');
    dnum=str2num(oldfile{1}(gg+5:gdot-1));
    dstr=sprintf('%3.3d',dnum)
    newfile=['/home/argo/ArgoRT/Kargo/argo/ArgoRT/argos_downloads/argos' yy '_' dstr '.log']
    [st]=system(['cp ' oldfile{1} ' ' newfile])
    
end