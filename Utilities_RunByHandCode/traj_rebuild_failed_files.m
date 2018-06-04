% remake argos trajectory files.
% But remake the work files for selected floats/profiles that are failing
% the file checker from the GDAC.

%list the XML files
fcd = '/home/argo/ArgoRT/trajchecker/out/';
fnms = dir([fcd '*.filecheck']);
fid = fopen('trajArgosForRerun.txt','a');

jj = 0;
for a = 1:length(fnms)
    
    % read in the XML file
    s = parseXML([fcd fnms(a).name]);
    
    % identify which trajectory files need re-making
    for b = 1:length(s.Children)
        ii = strfind('errors',s.Children(b).Name);
        if ~isempty(ii)
            break
        end
    end
        
    no_errs = str2num(s.Children(b).Attributes.Value);
    if no_errs == 0
        %nothing to fix
        continue
    end
    
    %let's output the wmo id to a file
    fprintf(fid,'%s\n',fnms(a).name(1:7))
    jj = jj+1;
end
fclose(fid)