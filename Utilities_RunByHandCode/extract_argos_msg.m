% EXTRACT_ARGOS_MSG  Extract the messages for specified floats from an 
%    ftp download from Argos, or just make a copy of an ftp download file,
%    but adding UTC date as the first line.
%
% INPUT 
%   fnm   - name of argos message dump file (created by script 'ftp_get_argos') 
%           Do not give path - file is assumed to be in the usual spot. 
%   flist - list of *ARGOS* id numbers for the float(s) to extract
%           If empty, will just make a copy of the input file, but add the
%           UTC last-fix-time as the first record (if not already in file)
% OUTPUT  
%   a single file, named with the parent file prefix and the first requested
%   id number, ie fnm '_' flist(1) '.log', and placed in 'work/'
%   If no 'flist' then "_new" will the appended to the fnm prefix.
%
% Author: Jeff Dunn CSIRO-CMAR/BoM Oct 2006
%
% CALLED BY:   for operator use only 
%
% USAGE: extract_argos_msg(fnm,flist)

function extract_argos_msg(fnm,flist)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

% Construct the second part of output filename
if nargin<2 | isempty(flist)
   fadd = '_new';
   wantall = 1;
   wanted = 1;
else
   fadd = ['_' num2str(flist(1))];
   wantall = 0;
   wanted = 0;
end   

fpin = [ARGO_SYS_PARAM.root_dir 'argos_downloads/']; 
fpout = [ARGO_SYS_PARAM.root_dir 'work/']; 

% Open the input files
fid = fopen([fpin fnm],'r');
if fid<1
   error(['Unable to open input file ' fpin fnm]);
end

% Construct the first part of output filename, and open it
ii = strfind(fnm,'.log');
if isempty(ii)
   fnmo = ['argos' fadd '.log'];
else
   fnmo = [fnm(1:(ii-1)) fadd '.log'];
end
fido = fopen([fpout fnmo],'w');
if fido<1
   error(['Unable to open output file ' fpout fnmo]);
end



% Read first record
nxtline = fgetl(fid);


% Put estimated UTC time of ftp transfer in first line of new file 

if length(nxtline)>=20 & strncmp(nxtline(1:3),'UTC',3)
   % Input file already has this, so copy it over.
   fprintf(fido,'%s\n',nxtline);
else
   % Need to estimate this (from last fix date in file)
   [lstdate,err] = date_ftp_file(fid,1);
   if err>=0
      tmp = datevec(lstdate);
      fprintf(fido,'UTC %0.2d-%0.2d-%0.4d %0.2d:%0.2d\n',tmp([3 2 1 4 5]));
   end
end
nxtline = fgetl(fid);


% Our Argos ID, which marks the beginner of header lines 
%our_id = '02039';  now set in set_sys_params
our_id=ARGO_SYS_PARAM.our_id

while ischar(nxtline)
   if wantall
      % Don't care what the line is - just copy it out to new file
      
   elseif length(nxtline)<15
      % EMPTY or short lines occur and are not of interest
      
   elseif strcmp(nxtline(1:4),'    ')
      % NOT A HEADER line
      
   elseif strcmp(nxtline(1:5),our_id)
      % A HEADER LINE. Get the ID number
      [id,num] = strread(nxtline,'%d %d',1);
      if length(num)==1
	 wanted = any(flist==num);
      end
            
   else
      % Some other type of line ??      
   end
      
   if wanted
      fprintf(fido,'%s\n',nxtline);
   end
   nxtline = fgetl(fid);
end

fclose(fid);
fclose(fido);

%--------------------------------------------------------------------------
