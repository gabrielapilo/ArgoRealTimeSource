set_argo_sys_params
global ARGO_ID_CROSSREF
global ARGO_SYS_PARAM
getdbase(-1);
pref=[ARGO_SYS_PARAM.root_dir 'netcdf/'];
mirror=['/home/argo/ArgoDM/cron_jobs/gdac_mirror/link_to_mirror/csiro/']
export=[ARGO_SYS_PARAM.root_dir 'export_hold/'];
fid=fopen('version3-2.txt','a');

% kk=find(ARGO_ID_CROSSREF(:,1)==1901338)
kk=603

for i=kk:length(ARGO_ID_CROSSREF)
    i=i
    
    dd=[mirror num2str(ARGO_ID_CROSSREF(i,1)) '/profiles/R*']
    b=dirc(dd);
    if ~isempty(b)
        [m,n]=size(b);
        
        for j=1:m
            
            ss=[dd(1:end-2) b{j,1}];
            nc=netcdf(ss,'nowrite');
            
            presax=nc{'PRES'}.axis(1);
            if isempty(presax)
                o=' missing file in gdac'
                fprintf(fid,'%s %s\n',ss,o);
               
                ss2=[pref num2str(ARGO_ID_CROSSREF(i,1)) '/'  b{j,1}];
                [stat,w]=system(['cp ' ss2 ' ' export]);
                if stat
                    o='this file doesnt exist in netcdf! remove from mirror'
                    fprintf(fid,'%s %s\n',ss2,o);
                    
                end
            end
try
    vers=getnc(ss,'FORMAT_VERSION');
                if isempty(strmatch('3.1',vers'))
%                     try
                        ss2=[pref num2str(ARGO_ID_CROSSREF(i,1)) '/'  b{j,1}]
%                         system(['cp ' ss2 ' ' export]);
%                     catch
                        o='this file is not the correct version! reprocess'
                        ss2=ss2
%                     end
                fprintf(fid,'%s %s\n',ss2,o);
                end
%             end
catch 
    
end
ncclose('nc');
close('all');
% fclose('all');

        end
        ncclose('all')
        
    end
end
fclose(fid)
% writeGDAC
