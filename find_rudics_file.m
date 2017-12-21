% function find_rudics_file
%
% this script is in response to the many 'missing' rudics files that are
% eventually found in either the badfiles or the datafiles directories of
% a float on either rudics1-t110 or iridium2-t110.   When this now happens,
% I want to go to therelevant directory and see if the file exists, then
% copy it back to the argort iricium_data directory for processing. This
% should speed up processing for these floats.
% Only functions if processor is CSIRO.
%
%  input: filen is the filename of the file that's present
%  outputs: found - has a file been retrieved or not?
%
% Updated, Dec 2017, to find the largest file, and look in the
% iridium_repository

function [found]=find_rudics_file(filen)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF
found = 0;
if isfield(ARGO_SYS_PARAM,'processor')
    
    % Check for the data processor information - set in set_argo_sys_params.m
    if ~isempty(strfind(ARGO_SYS_PARAM.processor,'CSIRO'))
        found=0;
        if strmatch('f',filen)
            fl=str2num(filen(2:5));
        else
            fl=str2num(filen(1:4));
        end
        aic=ARGO_ID_CROSSREF;
        kk=find(ARGO_ID_CROSSREF(:,2)==fl);
        
        dot=strfind(filen,'.');
        
        typ=filen(dot(end)+1:end);
        nfilen=filen(1:dot(end));
        
        switch typ
            
            case 'log'
                nfilen=[nfilen 'msg'];
            case 'msg'
                nfilen=[nfilen 'log'];
                
        end
        
        lookhere{1} = [ARGO_SYS_PARAM.rudics_server '/f' num2str(aic(kk,5)) '/datafiles/' nfilen];
        lookhere{2} = [ARGO_SYS_PARAM.rudics_server '/f' num2str(aic(kk,5)) '/badfiles/' nfilen];
        lookhere{3} = [ARGO_SYS_PARAM.rudics_server '/f' num2str(aic(kk,5)) '/' nfilen];
        lookhere{4} = [ARGO_SYS_PARAM.secondary_server '/f' num2str(aic(kk,5)) '/datafiles/' nfilen];
        lookhere{5} = [ARGO_SYS_PARAM.secondary_server '/f' num2str(aic(kk,5)) '/badfiles/' nfilen];
        lookhere{6} = [ARGO_SYS_PARAM.secondary_server '/f' num2str(aic(kk,5)) '/' nfilen];
        
        siz = [];
        for i=1:6
            d=dirc(lookhere{i});
            if ~isempty(d)
                siz(i) = d{5};
            end
        end
        
        %look in the stampdated files area
        lookhere{7} = [ARGO_SYS_PARAM.iridium_repository '/f' num2str(aic(kk,5)) '/stampdatedfiles/*' nfilen];
        d=dirc(lookhere{7});
        if ~isempty(d)
            [mm,im] = max([d{:,5}]);
            siz(7) = mm;
            lookhere{7} = [ARGO_SYS_PARAM.iridium_repository '/f' num2str(aic(kk,5)) '/stampdatedfiles/' d{im,1}];
        end
        
        if ~isempty(siz)
            [mm,imax] = max(siz);
            
            if mm~=0
                system(['scp ' lookhere{imax} ' ' ARGO_SYS_PARAM.iridium_path '/' nfilen]);
                found=1;
                return
            end
        end
    end
end
    
return
