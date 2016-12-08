%%%%
% cleanLOG:  Function for eliminating incomplete message obtained from CLS ARGOS
%    float messages (retrieved by ftp from Argos)
%
% INPUT
%   fin   - name of argos message log file (created by script 'ftp_get_argos') 
%   fout  - name of output file into which message with out incomplete lines are written
%           Generally to Temporary.log
%           and later moved to the input file
%
% Author: Pavan Jonnakuti INCOIS-MoES 25th August 2016
%
%
%       
%%%%

function cleanLOG(filename)

%% Read & create input input/output filenames
fin=deblank(filename);
fid = fopen(fin,'r');
if fid<1
   error(['cleanLOG: Unable to open input file ' filename]);
end
fout = '/home/argo/ARGO_RT/argos_downloads/Temporary.dat';    % until all the short messages are eliminated 
                           % write to a Temporary file and move to original file later
outFile = fopen(fout,'w');
if outFile<1
   error(['cleanLOG: Unable to create output file ' outFile]);
end

%% Read Entire File and store in tlines
tline = fgetl(fid);
tlines = cell(0,1);
set = cell(8,1) ;
while ischar(tline)
    tlines{end+1,1} = tline;
    tline = fgetl(fid);
end

%% Check for first two lines and write 
if strfind(cell2mat(tlines(1)),'UTC')
        fprintf(outFile,'%s',tlines{1});
end
if strfind(cell2mat(tlines(2)),'prv')
        fprintf(outFile,'\n%s',tlines{2});
end
%%

lines = 1:length(tlines) ;
temp = zeros(length(tlines),1) ;
fLoc=strfind(tlines,'-');
idx=find(~cellfun(@isempty,fLoc));

%% Run loop for number of headers with respect to country code ' 02602'
count = 1 ;
for i = 1:length(fLoc)
    if isempty(fLoc{i})
        count = count+1 ;
        temp(i) = count ;
    else
        count = 1 ;
        temp(i) = count ;
    end
end

% Get country code 
yLoc=strfind(tlines,'02602');
idy=find(~cellfun(@isempty,yLoc));
idy(1) = [] ;
temp(idy) = 02602 ;

%% Get positions where complete packets with length =8
pos = lines(temp==8) ;
pos0 = pos ;
for kloop=1:length(idy)-1
    fprintf(outFile,'\n%s',tlines{idy(kloop)});
    temp =  pos(pos>idy(kloop) & pos<idy(kloop+1)) ;
    pos0 = setdiff(pos0,temp) ;
    for jloop=1:length(temp)
                fprintf(outFile,'\n%s',tlines{temp(jloop)-7:temp(jloop)});
    end
end

% Write the last set left if any
if ~isempty(pos0)
    fprintf(outFile,'\n%s',tlines{idy(end)});
    for jloop=1:length(pos0)
        fprintf(outFile,'\n%s',tlines{pos0(jloop)-7:pos0(jloop)});
    end
end
fprintf(outFile,'\n%s',tlines{end-1:end}); 
fclose('all'); 

%% Rename input log File

[SUCCESS,MESSAGE,MESSAGEID] = movefile(fout,fin);
if SUCCESS
    fprintf('File renamed succefully')
else
    fprintf('Error')
end
