% surface_dens_Argo
%
% this is an updated version of surface_dens_AT which ran using WOD98 -
% very outdated.  So we now load the Argo reference database to create an
% updated reference database for ballasting floats.  This also helps you
% decide if they need additional buoyancy in areas of low surface density.
%
% usage:
% surface_dens_argo
clear *

la=[];
lon=[];
dep=[];
tim=[];
den=nan(100,1000);
idx=0
dep=nan(100,1000);
% sdep = [0:10:30,50:25:150,200:50:300,400:100:1500,1750,2000:500:5000];

% cd /home/argo/climatology/reference_databases/ARGO_for_DMQC_2013V04/

for i=20:10:220

    i=i
    idx=0;
    clear la lon dep tim den id s t
    clear la2 lon2 dep2 tim2 den2 id2 s2 t2
    for j=-65:10:15
        
        try
            wmono=wmo(i+10,j);
            file=['/home/argo/climatology/reference_databases/ARGO_for_DMQC_2013V04/argo_' num2str(wmono) '.mat'];
            
            load(file);
            [m,n]=size(pres);
            
            for ll=1:n
                
%                 sdepS=deps_to_stddep(pres(:,ll),sal(:,ll),1,sdep);
%                 sdepT=deps_to_stddep(pres(:,ll),temp(:,ll),1,sdep);
                kk=find(pres(:,ll)<=50);
                idx=idx+1;
                
                la2(idx)=lat(ll);
                lon2(idx)=long(ll);
                dep2(kk,idx)=pres(kk,ll);
                tim2(idx)=dates(ll);
                den_raw=sw_dens(sal(:,ll),temp(:,ll),0);
                den2(kk,idx)=den_raw(kk);
                id2(idx)=idx;
                
                s2(kk,idx)=sal(kk,ll);
                
                t2(kk,idx)=temp(kk,ll);
                
            end
        catch
        end
         
    end
    
    s2=change(s2,'==',0,nan);
    t2=change(t2,'==',0,nan);
    dep2(2:end,:)=change(dep2(2:end,:),'==',0,nan);
    den2=change(den2,'==',0,nan);
    
    load(['/home/argo/ArgoRT/raw_sfc_obs_' num2str(i) '.mat']);
    tim=(tim/365.25)+1900;
    tim2=tim2/10^10;
    la=[la2 la'];
    lon=[lon2 lon'];
    [m2,n2]=size(s2);
    [m3,n3]=size(s);
    maxarr=nan(max(m2,m3),n2+n3);
    ttmp=maxarr;
    ttmp(1:m2,1:n2)=dep2;
    ttmp(1:m3,n2+1:n2+n3)=dep(1:m3,:);
    dep=ttmp;
    tim=[tim2 tim'];
    ttmp=maxarr;
    ttmp(1:m2,1:n2)=den2;
    ttmp(1:m3,n2+1:n2+n3)=den;
    den=ttmp;
    id=[id2 id'];
    ttmp=maxarr;
    ttmp(1:m2,1:n2)=s2;
    ttmp(1:m3,n2+1:n2+n3)=s;
    s=ttmp;
    ttmp=maxarr;
    ttmp(1:m2,1:n2)=t2;
    ttmp(1:m3,n2+1:n2+n3)=t;
    t=ttmp;
        
    save (['raw_sfc_obs_new_' num2str(i) '.mat']);

end