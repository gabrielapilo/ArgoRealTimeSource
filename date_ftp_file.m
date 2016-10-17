% DATE_FTP_FILE  Scan an ftp download file and find newest ARGOS date-time
%    (to estimate the UTC time of the ftp transfer)
%
% INPUT
%   fid   - FID of open argos message dump file (created by 'ftp_get_argos') 
%   verbose  - 1=give stats of dates found  [default 0]
%
% OUTPUTS
%   lstdate - datenum of last date in the file (ie newest UTC fix time)
%
%  NOTE: *** The input file is left open and at the start (ie is rewound)
%
% Author: Jeff Dunn CSIRO-CMAR/BoM Oct 2006
%
% CALLS: nil
%
% USAGE: [lstdate,err] = date_ftp_file(fid,verbose);

function [lstdate,err] = date_ftp_file(fid,verbose)

global ARGO_SYS_PARAM

if nargin<2 | isempty(verbose)
   verbose = 0;
end

lstdate = NaN;
err = -1;

% Open the input file
if nargin==0 | isempty(fid) | fid<2
   logerr(1,'DATE_FTP_FILE:  Need to supplied FID for already-open input file');
   return
end


% Our Argos ID, which marks the beginner of header lines 
%our_id = '02039';  now set in set_sys_params
our_id=ARGO_SYS_PARAM.our_id;

tim = zeros(10000,1);
ndate = 0;
nxtline = fgetl(fid);

while ischar(nxtline)
   if length(nxtline)<15
      % EMPTY or short lines occur and are not of interest
      
   elseif strcmp(nxtline(1:4),'    ')
      % NOT A HEADER line
      
   elseif strcmp(nxtline(1:5),our_id)
      % A HEADER LINE. First decode it, and see if is the start of a new profile

      [id,num,t1,t2,t3,p_err,datcel,timcel] = ...
	  strread(nxtline,'%d %d %s %s %s %s %s %s',1);
						              
      % Load header info from this line
      datstr = char(datcel);
      timstr = char(timcel);
      if length(datstr)==10 & length(timstr)==8
	 tmp1 = sscanf(datstr,'%d-%d-%d');
	 tmp2 = sscanf(timstr,'%d:%d:%d');
	 if length(tmp1)==3 & length(tmp2)==3	    
	    ndate = ndate+1;
	    tim(ndate) = datenum([tmp1' tmp2']);
	 end
      end
      
   else
      % Some other type of line ??         
   end
      
   nxtline = fgetl(fid);
end              % Looping on every line of ARGOS message file

frewind(fid);

tim = tim(1:ndate);
ii = find(isnan(tim));
if ~isempty(ii)
   tim(ii) = [];
end

if isempty(tim)
   logerr(2,'DATE_FTP_FILE: Could not extract dates from ftp file');
else
   err = 0;
   lstdate = max(tim);
   mdtim = median(tim);
   if verbose
      tmp = sprintf('%d dates, range %s - %s, median %s\n',length(tim),...
		    datestr(min(tim)),datestr(max(tim)),datestr(mdtim));
      logerr(5,tmp);
   end

   mm = find(tim<lstdate);
   secondlast = max(tim(mm));

   if (lstdate-mdtim) > 10 | (lstdate-secondlast) > .1
      err = 1;
      logerr(3,['Suspect last time? 2nd last time: ' datestr(secondlast)]);
   end

   % The Fix times seem to be about the mean of the times of the group of
   % messages that follow. These seem to span about 10 minutes, so the Fix
   % time might be, say, 5 minutes before the last associated message time.
   % The lstdate should not be before the last time in the file, so add
   % 5-10mins to our last Fix time so ensure this is after the last
   % message time.
   lstdate = lstdate+.006;
end

return

%--------------------------------------------------------------------------
