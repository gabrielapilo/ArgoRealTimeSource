% function find_largest_file(filen)
%
% Find the largest file that exists - either in Iridium_Repository or on
% one of the servers.
%
%  input: filen is the filename of the file that we are looking for
%  (without the .log and .msg extension)
%  outputs: found - has a larger file been retrieved or not?
%
% Bec Cowley, Dec 2017

function found = find_largest_file(filen)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF
found = 0;
if strmatch('f',filen)
    fl=str2num(filen(2:5));
else
    fl=str2num(filen(1:4));
end
aic=ARGO_ID_CROSSREF;
kk=find(ARGO_ID_CROSSREF(:,2)==fl);
if isempty(kk)
    return
end

if length(kk) > 1
    kk = kk(end);
end

typ = {'log','msg'};
for ii = 1:length(typ)
    nfilen=[filen '.' typ{ii}];
    if ii == 1
    nfilen2=[filen '.' typ{2}];
    else
    nfilen2=[filen '.' typ{1}];
    end        
    d = dirc([ARGO_SYS_PARAM.iridium_path nfilen]);
    if isempty(d)
        %file is missing
        irdat_size = 0;
    else
        irdat_size = d{5};
    end
    
    %lookhere{1} = [ARGO_SYS_PARAM.rudics_server '/f' num2str(aic(kk,5),'%04i') '/datafiles/' nfilen];
    %lookhere{2} = [ARGO_SYS_PARAM.rudics_server '/f' num2str(aic(kk,5),'%04i') '/badfiles/' nfilen];
    %lookhere{3} = [ARGO_SYS_PARAM.rudics_server '/f' num2str(aic(kk,5),'%04i') '/' nfilen];
    %lookhere{4} = [ARGO_SYS_PARAM.secondary_server '/f' num2str(aic(kk,5),'%04i') '/datafiles/' nfilen];
    %lookhere{5} = [ARGO_SYS_PARAM.secondary_server '/f' num2str(aic(kk,5),'%04i') '/badfiles/' nfilen];
    %lookhere{6} = [ARGO_SYS_PARAM.secondary_server '/f' num2str(aic(kk,5),'%04i') '/' nfilen];
    
    siz = [];
%     for i=1:6
%         d=dirc(lookhere{i});
%         if ~isempty(d)
%             siz(i) = d{5};
%         end
%     end
    
%     %look in the stampdated files area
%     lookhere{7} = [ARGO_SYS_PARAM.iridium_repository '/f' num2str(aic(kk,5),'%04i') '/stampdatedfiles/*' nfilen];
%     d=dirc(lookhere{7});
%     if ~isempty(d)
%         [mm,im] = max([d{:,5}]);
%         siz(7) = mm;
%         lookhere{7} = [ARGO_SYS_PARAM.iridium_repository '/f' num2str(aic(kk,5),'%04i') '/stampdatedfiles/' d{im,1}];
%     end
    
    %look in iridium_processed files area
    lookhere{8} = [ARGO_SYS_PARAM.iridium_path 'iridium_processed/' num2str(aic(kk,1)) '/' nfilen];
    d=dirc(lookhere{8});
    if ~isempty(d)
        [mm,im] = max([d{:,5}]);
        siz(8) = mm;
        lookhere{8} = [ARGO_SYS_PARAM.iridium_path 'iridium_processed/' num2str(aic(kk,1)) '/' d{im,1}];
    end
    
    if ~isempty(siz)
        [mm,imax] = max(siz);
        
        % from 16/4/2024: only looks for larger file that got processed. If
        % there is an already larger file processed, leaves the smaller
        % file in iridium_data for manual check
        if mm > irdat_size
            %move the small file out
%             system(['mv -f ' ARGO_SYS_PARAM.iridium_path nfilen ' ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files'])
%             if imax == 7 %need to change file name
%                 system(['cp -f ' lookhere{imax} ' ' ARGO_SYS_PARAM.iridium_path '/' nfilen(end-11:end)]);
%                 system(['chmod 0666 '  ARGO_SYS_PARAM.iridium_path '/' nfilen(end-11:end)]);
%                 %If we updated any files, copy to BOM ftp
%                 BOM_retrieve_Iridium([ARGO_SYS_PARAM.iridium_path nfilen(end-11:end)])
%                 %and copy the matching msg/log file to make the pair
%                 try
%                     BOM_retrieve_Iridium([ARGO_SYS_PARAM.iridium_path nfilen2(end-11:end)])
%                 catch
%                     logerr(3,['Matching file not copied to BOM: ' nfilen2]);
%                 end
%             else
%                 system(['cp -f ' lookhere{imax} ' ' ARGO_SYS_PARAM.iridium_path '/' nfilen]);
%                 system(['chmod 0666 ' ARGO_SYS_PARAM.iridium_path '/' nfilen]);
                %If we updated any files, copy to BOM ftp
%                 BOM_retrieve_Iridium([ARGO_SYS_PARAM.iridium_path nfilen])
                %and copy the matching msg/log file to make the pair
%                 try
%                     BOM_retrieve_Iridium([ARGO_SYS_PARAM.iridium_path nfilen2])
%                 catch
%                     logerr(3,['Matching file not copied to BOM: ' nfilen2]);
%                 end
%             end
            found = 1;
        end
    end
end

return
