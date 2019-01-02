%function test_argomaster_csv
% Test the created csv sheets to ensure they don't break the processing
function test_argomaster_csv

fnm = '/home/argo/ArgoRT/spreadsheet_master/argomaster.csv';

if ~exist(fnm,'file')
    error(['Cannot find database file ' fnm]);
end

fid = fopen(fnm,'r');
%35 columns. Edit here if we need to add/remove columns
tmpdb = textscan(fid,repmat('%s',1,35),'delimiter',',','headerlines',2);
fclose(fid);


nodeps = max(cell2num(tmpdb{10}));
sz = cellfun(@max,cellfun(@size,tmpdb,'UniformOutput',0));
msize = max(sz);
mnsize = min(sz);

if msize ~= nodeps & mnsize ~= nodeps
    disp(['argomaster.csv has problems, should have ' num2str(nodeps) ' values'])
    disp(msize)
else
    disp('argomaster is fine, well done!')    
end

% now test the sensorinfo sheet:
fnm = '/home/argo/ArgoRT/spreadsheet_master/argomaster_sensorinfo.csv';

if ~exist(fnm,'file')
    error(['Cannot find database file ' fnm]);
end

fid = fopen(fnm,'r');
%42 columns. Edit here if we need to add/remove columns
tmpdb = textscan(fid,repmat('%s',1,42),'delimiter',',','headerlines',2);
fclose(fid);


nodeps = max(cell2num(tmpdb{4}));
sz = cellfun(@max,cellfun(@size,tmpdb,'UniformOutput',0));
msize = max(sz);
mnsize = min(sz);
if msize ~= nodeps | mnsize ~= nodeps
    disp(['argomaster_sensorinfo.csv has problems, should have ' num2str(nodeps) ' values'])
    disp(sz)
else
    disp('argomaster_sensorinfo is fine, well done!')    
end