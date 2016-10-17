% REPORT_BAD_PROF  If FIND_BEST_MSG fails to extract a profile from a message
%    then this function just counts and reports repetitions of each block, as
%    a diagnostic.   Rarely used - maybe only for incomplete messages.
%
% INPUT  rawdat  {maxblks}[nreps,maxlinelength]  31 or 32 byte decimal lines
%
% OUTPUT   error message logged with diagnostic data.
%
%  Programmer: Yes, 'nreps' was already counted in STRIP_ARGOS_MSG, and also
%              found again in FIND_BEST_MSG - however I felt it better to
%              re-compute it here rather than pass it around just for the
%              very rare occasions it is wanted.
%
% Called by PROCESS_PROFILE
%
% Jeff Dunn CMAR/BoM  Nov 2006
%
% USAGE: report_bad_prof(rawdat)

function report_bad_prof(rawdat)

nblk = nanmax(rawdat.blkno);
dflen = [];

if isempty(nblk) || isnan(nblk) || nblk==0
   % No useful data - this will have already been reported in find_best_msg
   return
end

for jj = 1:nblk
   ii = find(rawdat.blkno==jj);
   nbyte = sum(~isnan(rawdat.dat(ii,:)'));
   nreps(jj) = sum(nbyte==max(nbyte));
   if nreps(jj)<length(ii)
      dflen = [dflen jj];
   end
end

str = sprintf('B%d:%d ',[1:nblk; nreps(1:nblk)]);
logerr(1,['Bad prof msg- Block:Reps  ' str]);

if ~isempty(dflen)
   str = sprintf('%d ',dflen);   
   logerr(3,['Different msg lengths within blocks ' str]);
end

%-------------------------------------------------------------------------------
