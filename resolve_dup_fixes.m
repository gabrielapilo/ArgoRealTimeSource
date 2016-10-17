% RESOLVE_DUP_FIXES  Identify lower quality redundant location fixes from 
%                    an Argos download for one Argo profile. We don't even
%                    know if this will ever happen! 
%
% Jeff Dunn CMAR  August 2013
%
% INPUTS:  already arranged in chronological order
%
% USAGE: rej = resolve_dup_fixes(satnam,loc_class,jday)

function rej = resolve_dup_fixes(satnam,loc_class,jday)


% We should retain one fix per satellite pass. 
% Passes are about 100min apart and viewing window is about 10mins. 
% If more than one fix per pass then reject the lesser quality ones.

% Location classes. From Argos doco:
%    classes 0, 1, 2, 3 indicate that the location was obtained with 4
%    messages or more and provides the accuracy estimation,
%    class A indicates that the location was obtained with 3 messages,
%    class B indicates that the location was obtained with 2 messages,
%    class G indicates that the location is a GPS fix obtained by a GPS
%    receiver attached to the platform. The accuracy is better than 100 meters.
%    class Z indicates that the location process failed.
%
% The accuracy cannot be estimated for classes A and B (not enough messages).
%
%    Class 3: better than 250 m radius
%    Class 2: better than 500 m radius
%    Class 1: better than 1500 m radius
%    Class 0: over 1500 m radius

% Shouldn't have real fixes which are less than 80 mins apart
minsep = 80/(60*24);   

% So as I understand this moronic scale ranked worst to best is: 
psrank = double(vec('ZBA0123G'));
posrank = [];

nheads = length(jday);
rej = logical(zeros(1,nheads));

satnam = satnam(:)';

for ss = unique(satnam)
   % Loop on satellites, finding all fixes with the same satellite.
   jj = strfind(satnam,ss);
   
   if length(jj)>1 && any(diff(jday(jj))<minsep)
      % Apparently same-pass fixes for this satellite

      if isempty(posrank)
	 % If haven't done it yet, rank the position codes
	 posrank = zeros(1,nheads);
	 for kk = 1:nheads
	    prank = find(psrank==loc_class(kk));
	    if ~isempty(prank)
	       posrank(kk) = prank;
	    end
	 end
      end
         
      prjj = posrank(jj);      
      for kk = find(diff(jday(jj))<minsep)
	 % For each pair of too-close-in-time fixes, rejected the one with
         % lower location class rank. If equal, arbitrarily reject the second fix
	 if prjj(kk)<prjj(kk+1)
	    rej(jj(kk)) = 1;
	 else
	    rej(jj(kk+1)) = 1;
	 end	    
      end   
   end
end


%---------------------------------------------------------------------------
