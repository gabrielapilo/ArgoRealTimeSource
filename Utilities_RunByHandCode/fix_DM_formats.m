% adapt this code to fix D-moded files when format changes are required.
global  ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB 

set_argo_sys_params

dirn = '/home/argo/data/dmode/newSoftwareTest/';

getdbase(0);
fln = [5904226
    3901467
    5904221
    5904224
    ];
%open a text file to record the files changed:
% fid = fopen('/home/argo/ArgoRT/Irrformat_changes.txt','a');

for a = 1:length(THE_ARGO_FLOAT_DB)
    %     if THE_ARGO_FLOAT_DB(a).oxy
    if ~isempty(find(THE_ARGO_FLOAT_DB(a).wmo_id==fln))
        flist = dir([dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) '/DFILES/D*.nc']);
%         flds = {'RAW_DOWNWELLING_IRRADIANCE412','RAW_DOWNWELLING_IRRADIANCE490',...
%             'RAW_DOWNWELLING_PAR','RAW_DOWNWELLING_IRRADIANCE380'};
        flds = {'PLATFORM_TYPE'};
        for b = 1:length(flist)
            fn = [dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) ...
                '/DFILES/' flist(b).name];
            %CHANGE the value
            pn = 'S2A                             ';
            ncwrite(fn,'PLATFORM_TYPE',pn');
            
            
%             fnnew = [dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) ...
%                 '/DFILES/new' flist(b).name];
%             nc = ncinfo(fn);
%                        
%             for c = 1:4
%                 ii = strmatch(flds{c},{nc.Variables.Name},'exact');
%                 %make a new file with the correct schema
%                 nc.Variables(ii).Datatype = 'single';
%                 ij = strmatch('_FillValue',{nc.Variables(ii).Attributes.Name},'exact');
%                 nc.Variables(ii).Attributes(ij).Value = single(nc.Variables(ii).Attributes(ij).Value);
%             end
%             %now write out the new file
%             ncwriteschema(fnnew,nc);
%             for m = 1:length(nc.Variables)
%                 dat = ncread(fn,nc.Variables(m).Name);
%                 ncwrite(fnnew,nc.Variables(m).Name,dat);
%             end
%             %now move the old file out and move in the new
%             system(['mv ' fn ' ' fn '.old'])
%             system(['mv ' fnnew ' ' fn])
%             fprintf(fid,'%s\n',fn);
        end
        
    end
end
% fclose(fid);
% %% submit to GDAC
% fid = fopen('/home/argo/ArgoRT/Irrformat_changes.txt','r');
% fns = textscan(fid,'%s\n')
% fclose(fid);
% fns = fns{1};
% 
% for a = 1:length(fns)
%     if ~isempty(findstr('BD',fns{a}))
%         system(['cp ' fns{a} ' /home/argo/ArgoRT/export'])
%     end
% end

