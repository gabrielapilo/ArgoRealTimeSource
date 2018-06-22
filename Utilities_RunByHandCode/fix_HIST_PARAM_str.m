global  ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB 

set_argo_sys_params

dirn1 = '/home/argo/data/dmode/newSoftwareTest/';
dirn2 = '/home/argo/ArgoRT/netcdf/';
getdbase(0);
fln = [1901339
1901156
1901157
1901158
1901159
1901152
1901153
1901154
1901155
5903954
5903956
5903957
5904218
5903955
1901135
5901646
5901647
5901648
5901697
5901699
5903226
5903242
5903248
5903255
5903256];

%open a text file to record the files changed:
fid = fopen('/home/argo/ArgoRT/HisParam_changes_oxy.txt','a');

for a = 1:length(THE_ARGO_FLOAT_DB)
%     if THE_ARGO_FLOAT_DB(a).oxy
    if ~isempty(find(THE_ARGO_FLOAT_DB(a).wmo_id==fln))
        for cc = 1:2 %for both D and R files
            eval(['dirn = dirn' num2str(cc) ';'])
            if cc == 1
                flist = dir([dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) '/DFILES/BD*.nc']);
            else
                flist = dir([dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) '/BR*.nc']);
            end
            
            for b = 1:length(flist)
                if cc == 1
                    fn = [dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) ...
                        '/DFILES/' flist(b).name];
                    fnnew = [dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) ...
                        '/DFILES/new' flist(b).name];
                else
                    fn = [dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) ...
                        '/' flist(b).name];
                    fnnew = [dirn '/' num2str(THE_ARGO_FLOAT_DB(a).wmo_id) ...
                        '/new' flist(b).name];
                end
                hp = ncread(fn,'HISTORY_PARAMETER');
                if size(hp,1) ~= 64
                    disp(flist(b).name)
                    %make a new HIST_P field
                    h = repmat(' ',64,size(hp,2),size(hp,3));
                    h(1:size(hp,1),:,:) = hp;
                    nc = ncinfo(fn);
                    ii = strmatch('HISTORY_PARAMETER',{nc.Variables.Name});
                    %make a new file with the correct schema
                    nc.Variables(ii).Dimensions(1).Name = 'STRING64';
                    nc.Variables(ii).Dimensions(1).Length = 64;
                    %now write out the new file
                    ncwriteschema(fnnew,nc);
                    for c = 1:length(nc.Variables)
                        if c~=ii
                            dat = ncread(fn,nc.Variables(c).Name);
                            ncwrite(fnnew,nc.Variables(c).Name,dat);
                        else
                            ncwrite(fnnew,'HISTORY_PARAMETER',h);
                        end
                    end
                    %now move the old file out and move in the new
                    system(['mv ' fn ' ' fn '.old'])
                    system(['mv ' fnnew ' ' fn])
                    fprintf(fid,'%s\n',fn);
                    
                end
            end
        end
    end
    
end
fclose(fid);

%% submit to GDAC
fid = fopen('/home/argo/ArgoRT/HisParam_changes.txt','r');
fns = textscan(fid,'%s\n')
fclose(fid);
fns = fns{1};

for a = 1:length(fns)
    if ~isempty(findstr('BR',fns{a}))
        system(['cp ' fns{a} ' /home/argo/ArgoRT/export'])
    end
end

