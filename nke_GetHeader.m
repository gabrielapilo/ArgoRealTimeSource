%==============================================================================
% READ THE FIRST 2 BYTES OF THE sbd FILE RETURNING:
% -----------------------------------------------------------------------------
% X     = b(1)           -is the packet type 0,1,2,3,4,5,6,7,13,14
% dive    = 256*b(2)+b(3)  -is the cycle number -1:startup, 0:test dive, >1 profile
% 
% AUTHOR: Udaya Bhaskar - June 2017 
%==============================================================================
function [X, dive] = nke_GetHeader(sbdfile)
%begin
     %outputs:
     X     = [];
     dive  = [];
     
     %open the file:
     try fid = fopen(sbdfile, 'rb'); catch; return; end;
     b = fread(fid);
     n = length(b);
     fclose(fid);
     if (n < 100) return; end;
     
     % extract the packet type information
     X    = b(1);       %"X"
     dive = 256*b(2) + b(3);  %cycle number
     
end

