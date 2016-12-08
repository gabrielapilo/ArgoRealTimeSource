set_argo_sys_params
global ARGO_ID_CROSSREF
global ARGO_SYS_PARAM
getdbase(-1)
c=clock;
filen=['missing_GDACprofile_list_' num2str(c(1)) '_' num2str(c(2)) '_' num2str(c(3)) '.txt'] 
fid=fopen(filen,'w')
aBRd=[];
for i=1:length(ARGO_ID_CROSSREF)
%   for i=235
      i=i
    [fpp,dbdat]=getargo(ARGO_ID_CROSSREF(i,1));
    if(~isempty(fpp) ) & ~dbdat.RBR  %  & isempty(strmatch('dead',dbdat.status)) ...
        %  & isempty(strmatch('evil',dbdat.status)))
        %         fn=['/home/argo/data/gdac_mirror/csiro/'    num2str(ARGO_ID_CROSSREF(i,1)) '/profiles/R' ...
        %             num2str(ARGO_ID_CROSSREF(i,1)) '*']
        % %         fnBR=['/home/argo/ArgoDM/cron_jobs/gdac_mirror/csiro/'    num2str(ARGO_ID_CROSSREF(i,1)) '/BR' ...
        % %             num2str(ARGO_ID_CROSSREF(i,1)) '*']
        %
        %         Rd=dirc(fn);
        %         BRd=dirc(fnBR);
        
        fna=['/home/argo/ArgoRT/netcdf/' num2str(ARGO_ID_CROSSREF(i,1))  '/*'  num2str(ARGO_ID_CROSSREF(i,1)) '*.nc']
        %         fnaBR=['/home/argo/ArgoRT/netcdf/' num2str(ARGO_ID_CROSSREF(i,1))  '/BR'  num2str(ARGO_ID_CROSSREF(i,1)) '*']
        
        aRd=dirc(fna);
%                 aBRd=dirc(fnaBR);
        dnow=datenum(now);
        if ~isempty(aRd)
            [m,n]=size(aRd);
            for j=4:m
                % for j=85
                %                 ddm=isingdac(aRd(j,1));
                %                 if ddm==1 %file is on mirror but need to check
                %                 date-update
                
                fn=(['/home/argo/data/gdac_mirror/csiro/' ...
                    num2str(ARGO_ID_CROSSREF(i,1)) '/profiles/' aRd{j,1}]);
                fnD=(['/home/argo/data/gdac_mirror/csiro/' ...
                    num2str(ARGO_ID_CROSSREF(i,1)) '/profiles/D' aRd{j,1}(2:end)]);
                mirr=dirc(fn);
                mirrD=dirc(fnD);
                if isempty(mirr) & isempty(mirrD)
                    dsar=datenum(aRd{j,4});
                    if dnow-dsar >.1 %file not on mirror but exists in my directory
                        %profile totally missing from mirror
                        fprintf(fid,'missing profile %s \n ',aRd{j,1});
                        system(['cp /home/argo/ArgoRT/netcdf/' num2str(ARGO_ID_CROSSREF(i,1)) '/' ...
                            aRd{j,1} ' /home/argo/ArgoRT/export2']);
                    end
                elseif isempty(mirrD) & ~isempty(mirr)
                    aRd{j,1}
                    dsmirr=datenum(mirr{1,4});
                    dsar=datenum(aRd{j,4});
                    if dsmirr<dsar-1 & dnow-dsar >.2  %file created after mirror updated
                        %error - my file is more recent - note - need to
                        %remove "-3" from next run!!!
                        fprintf(fid,'older profile %s \n ',aRd{j,1});
                        system(['cp /home/argo/ArgoRT/netcdf/' num2str(ARGO_ID_CROSSREF(i,1)) '/' ...
                            aRd{j,1} ' /home/argo/ArgoRT/export2']);
                    end
                    %                     end
                    
                    %                     else
                    % %                 elseif ddm==0
                    % %                     dsar=datenum(aRd{j,4});
                    % %                     if dnow-dsar >4 %file not on mirror but exists in my directory
                    %                     %profile totally missing from mirror
                    %                     fprintf(fid,'missing profile %s \n ',aRd{j,1});
                    %                         system(['cp /home/argo/ArgoRT/netcdf/' num2str(ARGO_ID_CROSSREF(i,1)) '/' ...
                    %                             aRd{j,1} ' /home/argo/ArgoRT/export2']);
                    %                     end
                end
            end
        end
            %         if ~isempty(aBRd)
            %             [m,n]=size(aBRd);
            %             for j=1:m
            %                 % ddm=isingdac(aBRd(j,1));
            %                 % if ddm==1 %file is on mirror but need to check date-update
            %                 fn=(['/home/argo/ArgoDM/cron_jobs/gdac_mirror/csiro/' ...
            %                     num2str(ARGO_ID_CROSSREF(i,1)) '/profiles/' aBRd{j,1}]);
            %                 mirr=dirc(fn);
            %                 if ~isempty(mirr)
            %                     dsmirr=datenum(mirr{1,4});
            %                     dsar=datenum(aBRd{j,4});
            %                     if dsmirr<dsar-2
            %                         %error - myfile is more recent
            %                         fprintf(fid,'older profile %s \n ',aBRd{j,1});
            %          system(['cp /home/argo/ArgoRT/netcdf/' num2str(ARGO_ID_CROSSREF(i,1)) '/' ...
            %                             aBRd{j,1} ' /home/argo/ArgoRT/export2']);
            %                      end
            %                 else
            %                     %                 elseif ddm==0  %file not on mirror but exists in my directory
            %                     %profile totally missing from mirror
            %                     fprintf(fid,'missing profile %s \n ',aBRd{j,1});
            %           system(['cp /home/argo/ArgoRT/netcdf/' num2str(ARGO_ID_CROSSREF(i,1)) '/' ...
            %                             aBRd{j,1} ' /home/argo/ArgoRT/export2']);
            %                end
            %             end
            %         end
            
            
    end
end
fclose(fid)

