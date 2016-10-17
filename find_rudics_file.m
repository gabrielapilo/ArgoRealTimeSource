% function find_rudics_file
%
% this script is in response to the many 'missing' rudics files that are
% eventually found in either the badfiles or the datafiles directories of 
% a float on either rudics1-t110 or iridium2-t110.   When this now happens,
% I want to go to therelevant directory and see if the file exists, then
% copy it back to the argort iricium_data directory for processing. This
% should speed up processing for these floats. 
%
%  input: filen is the filename of the file that's present
%  outputs: found - has a file been retrieved or not?
%

function [found]=find_rudics_file(filen)

global ARGO_SYS_PARAM ARGO_ID_CROSSREF

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

lookhere{1} = ['/rudics-server-hf/f' num2str(aic(kk,5)) '/datafiles/' nfilen];
lookhere{2} = ['/rudics-server-hf/f' num2str(aic(kk,5)) '/badfiles/' nfilen];
lookhere{3} = ['/iridium2-t110/f' num2str(aic(kk,5)) '/datafiles/' nfilen];
lookhere{4} = ['/iridium2-t110/f' num2str(aic(kk,5)) '/badfiles/' nfilen];

for i=1:4
    d=dirc(lookhere{i});
    if ~isempty(d)
        if d{5}~=0
            dd=['system ' '''cp ' lookhere{i} ' /home/argo/ArgoRT/iridium_data'''];
            eval(dd);
            found=1;
            return
        end
    end            
end

return
