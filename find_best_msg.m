% FIND_BEST_MSG  For each array of repeated lines in a cell-array, find lines
%    with correct CRC and, if necessary, construct a line of most common
%    values for each nibble (ie character). Used to reduce error-prone ARGOS-
%    delivered Argo float transmissions to a single best profile message.
%
% INPUT  rawdat   .dat [nlin maxlinelength]  31 or 32 byte decimal lines
%                 .blkno [nlin 1]  block numbers
%        dbdat    float database struct including float maker and subtype codes
%        opts     struct from decoded Argos message including field "nocrc"
%
% OUTPUT best    [maxblk linelength]  single best profile message
%        fbm_report   8 activity counts:  (M_C_B = Most_Common_Byte)
%          1 - total number of all repetitions of all blocks
%          2 - total number with good CRC
%          3 - number of blocks, no ok CRC, used M_C_B
%          4 - number of blocks, no ok CRC, did NOT use M_C_B
%          5 - number of blocks with only one ok CRC 
%          6 - number of blocks where all ok-CRC messages are identical
%          7 - number of blocks, differing ok-CRC messages - used M_C_B
%          8 - where no ok-CRC, used M_C_B, number of bytes rejected
%              because no repeated values.
%       rawdat   Input structure, but with .crc & .maxblk added.
%
% Called by STRIP_ARGOS_MSG
%
% Jeff Dunn CMAR/BoM  July 2006
%
% USAGE: [best,fbm_report,rawdat] = find_best_msg(rawdat,dbdat,opts);

function [best,fbm_report,rawdat] = find_best_msg(rawdat,dbdat,opts)

% MODS: May2014 JD Tweaks during mods to whole system to allow for traj v3 files.

% Hardcoded Retrieval Level:
%  0 -> only use replicates with good CRC
%  1 -> when all reps fail CRC, but have 3+ reps, then try to find a line
%       of most common values [requiring 2 reps to accept any byte]
Rlevel = 1;
if dbdat.maker==2 && dbdat.subtype==3
    kk = find(isnan(rawdat.blkno));
    rawdat.blkno(kk) = 0;
    rawdat.blkno = rawdat.blkno+1;
end
if nargin<3
    opts.nocrc=0;
end
fbm_report = zeros(1,8);
best = [];       
% messages with unrealistic block numbers are given blkno=NaN,
% so that we can exclude flagged lines (Note that we do not put this
% "blknos" back into rawdat, so it is just a temporary change!)
blknos = rawdat.blkno(:)';
if isfield(rawdat,'qc') && any(rawdat.qc~=0)
   ii = find(rawdat.qc~=0);
   blknos(ii) = nan;
end
igd = find(~isnan(blknos));
if isempty(igd) & dbdat.maker~=2 & dbdat.subtype~=4
   % NOTE: according to this coding above, we will bypass this exit if Provor
   % (ie maker=2) or if subtype==4. Is that the intention?
   logerr(3,'FIND_BEST_MSG: no useful lines in message');
   return
end
if ~isfield(rawdat,'crc')
   rawdat.crc = zeros(size(rawdat.lineno));
end

maxblk = max(blknos(igd));
gdblk = -ones(maxblk,1);



if dbdat.maker==2 & dbdat.subtype==4  % martek provor CTS-3 floats - 
    %     all blocks are used and decoded.
    % AT addition sometime between Aug2013 and May2014.
    
    for nblk = 1:length(rawdat.lineno)
        iblk=nblk;
        gdblk(nblk) = ~isempty(iblk);    % I do not understand. iblk is a
                                         % copy of the loop counter!? But
                                         % that doesn't matter because this
                                         % value is never used. JRD      
        dat = rawdat.dat(iblk,:);
        nbyte = sum(~isnan(dat'));
        mxbyt = max(nbyte);
        reps=iblk;
        
        if isempty(best) && mxbyt>0
            mxbytb1 = mxbyt;
            best = repmat(nan,[maxblk mxbyt]);
        elseif mxbytb1 ~= mxbyt
            % This should never happen!
            logerr(3,['FIND_BEST_MSG: diff length B1 vs B' num2str(nblk) ' : ' ...
                num2str([mxbytb1 mxbyt])]);
        end
        
        if(~opts.nocrc | ~isfield(opts,'nocrc'))
            ok = zeros(size(nbyte));
            
            for rep = reps
                ok = CRCcheck(dat,dbdat);
            end
            rawdat.crc(iblk) = ok;
        else
            ok=find(rawdat.crc(reps));
        end
    end
    gdblk=rawdat.crc;

else
   for nblk = unique(blknos(igd))
      % Get all reps of the next block
      iblk = find(blknos==nblk);
      gdblk(nblk) = ~isempty(iblk);
      dat = rawdat.dat(iblk,:);

      % How many bytes per line (should be 31 or 32, but could be mishaps)
      nbyte = sum(~isnan(dat'));
      mxbyt = max(nbyte);

      if isempty(best) && mxbyt>0
	 mxbytb1 = mxbyt;
	 best = nan([maxblk mxbyt]);
      elseif mxbytb1 ~= mxbyt
	 % This should never happen, and prob indicates crap in file!
	 logerr(3,['FIND_BEST_MSG: diff length B1 vs B' num2str(nblk) ' : ' ...
		   num2str([mxbytb1 mxbyt])]);
      end

      % Find out how many reps (with full lines)
      if any(nbyte>0 & nbyte<mxbyt)
	 % Some incomplete lines, so select complete ones
	 reps = find(nbyte==mxbyt);
      else
	 % All lines complete
	 reps = 1:sum(nbyte>0);
      end
      nreps = length(reps);
      fbm_report(1) = fbm_report(1)+nreps;
      if mxbyt<size(dat,2)
	 dat = dat(:,1:mxbyt);
      end

      if isfield(opts,'nocrc') && opts.nocrc==1
	 % Ignore for now, but this is wrong because:
	 % - crc will be zeros at this stage so ok=[] always
	 % - it is searching/indexing only in the reps subset rather than dat full array 
	 % - we use ok=find(ok) further down, so any indexing would be lost anyway! 
	 %%ok = find(rawdat.crc(reps));   % AT
	 
	 ok = ones(size(nbyte));
	 rawdat.crc(iblk) = ok;
      else
	 ok = zeros(size(nbyte));

	 for rep = reps
	    ok(rep) = CRCcheck(dat(rep,:),dbdat);
	 end
	 rawdat.crc(iblk) = ok;
      end

      % Cases:
      % # no ok
      %     If Rlevel is 0
      %           -> reject
      %     If Rlevel is 1 AND nrep>3
      %           -> use most-common-byte approach to try to get a line, and
      %              issue a warning
      %
      % # some ok
      %   [arguable that we should make some use of "bad" lines, esp if
      %   lots of those and few "good" lines, but for now... ]
      %   - - - - - - > count on the good lines
      %
      % # all ok
      %   - 1 block  -> use it
      %   - multiblock
      %     - all agree -> use it
      %     - differences   - - - - -> count on the good lines


      % When checking if all repeated lines the same, need to skip first 3 bytes
      % if block 1, because the 3rd byte is an incrementing message num (hence
      % it and byte1 (the CRC) changes.)
      if nblk==1 || (dbdat.maker==2 && dbdat.subtype==2 && nblk==2)
	 n1 = 4;
      else
	 n1 = 1;
      end
      
      ok = find(ok);
      nok = length(ok);
      fbm_report(2) = fbm_report(2)+nok;
      if nok==0
	 if Rlevel==1 && nreps>=2
	    % Despite no good blocks, try to retrieve a most-common version
	    % (requiring at least 2 instances of each byte value)
	    fbm_report(3) = fbm_report(3)+1;
	    [best(nblk,1:mxbyt),fcnt] = most_common_bytes(dat(reps,:),mxbyt,2);
	    fbm_report(8) = fbm_report(8)+fcnt;
	 else
	    % do nothing - bad block
	    gdblk(nblk) = 0;
	    fbm_report(4) = fbm_report(4)+1;
	    % but use the line if you have it - see what happens...
	    if dbdat.maker~=4
	       % THE CODE BELOW SHOULD FAIL because nblk is scalar and reps
               % is a vector. Exclude for now.  JRD may14
	       
	       %  only use a bad block if it's in the range of expected blocks
	       d=diff(unique(blknos));
	       ll=find(unique(blknos)==nblk);
	       if(ll==1 | max(d(1:ll-1))<=2)
		 try
% 		    best(nblk,1:mxbyt) = dat(reps,:);
% 		    gdblk(nblk) = 1;
		 end
	       end
	    end
	 end
      elseif nok==1
	 % Only one good rep - so just use it
	 gdblk(nblk) = 1;
	 best(nblk,1:mxbyt) = dat(ok,:);
	 fbm_report(5) = fbm_report(5)+1;
      elseif all(all(dat(ok,n1:end)==repmat(dat(ok(1),n1:end),[nok 1])))
	 % More than one good rep, and all have same data, so just  use the
	 % first.
	 best(nblk,1:mxbyt) = dat(ok(1),:);
	 fbm_report(6) = fbm_report(6)+1;
      else
	 % More than one good rep, and some differences, so find the most common
	 % value for each element
	 best(nblk,1:mxbyt) = most_common_bytes(dat(ok,:),mxbyt);
	 fbm_report(7) = fbm_report(7)+1;
      end
   end
end


% Find last good block and trim back pre-allocated array to just the
% bits containing useful data
if any(gdblk==1)
   maxblk = find(gdblk==1,1,'last');
   if dbdat.maker==2 && dbdat.subtype==4
      % now rearrange so eliminate duplicates and have them in the correct
      % order for processing:
      [~,ind]=sort(rawdat.dat(maxblk,1));
      rawd=unique(rawdat.dat(maxblk(ind),1:31),'rows');
      best=rawd;
   else
      best = best(1:maxblk,:);
   end
else
   maxblk = 0;
   best = [];
end
rawdat.maxblk = maxblk;

return

%--------------------------------------------------------------------------

function [mcomb,mcb_fail] = most_common_bytes(dat,mxbyt,mincnt)

% Find the most common value for each element [not most common line, as 
% previously used.]

% Max retrieval if we break back down to hex nibbles (ie every
% character we get in the ftp text ) rather than staying in decimal bytes

% Straight math method (prob also faster than using hex2dec etc)
ij = 2:2:(mxbyt*2);
hh(:,ij) = rem(dat,16);
hh(:,ij-1) = (dat-hh(:,ij))./16;

% Now find most common value for each 
cnts = zeros(16,mxbyt*2);
for ii=0:15
   cnts(ii+1,:) = sum(hh==ii);
end
[mx,val] = max(cnts);

val = val-1;      % Convert back from position 1-16 to value 0-15

if nargin==3
   % Imposed minimum repetition level for each element
   ii = find(mx<mincnt);
   val(ii) = NaN;
   mcb_fail = length(ii);
else
   mcb_fail = 0;
end

% Convert back to decimal
mcomb = val(ij-1)*16 + val(ij);  

% The author of the following code should explain what it is intended to do, and why.
% If it is just undoing the effect of the minimum repetition test above then would
% it not be better just to reduce or remove that test? 
if any(isnan(mcomb))
   ii = find(isnan(mcomb));
   j = zeros(size(dat,1),1);
   for gg = 1:size(dat,1)
      jj = find(dat(gg,:)==mcomb);
      if ~isempty(jj)
	 j(gg)=length(jj);
      end
   end
   gg = find(j==max(j),1,'last');
   mcomb(ii) = dat(gg,ii);
end


return

%---------------------------------------------------------------------------
