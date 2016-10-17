%==============================================================================
% READ THE FIRST 6 BYTES OF THE sbd FILE RETURNING:
% -----------------------------------------------------------------------------
% X     = b(1)           -is the character "X"
% nn    = 256*b(2)+b(3)  -is the length of the message - 7 in bytes
% Hull  = 256*b(4)+b(5)  -is the serial number of the solo2 float ex: 7070
% dd    = 256*b(6)+b(7)  -is the dive number -1:startup, 0:test dive, >1 profile
% id    = b(8)           -is the packet id counter 0-255
% valid = true/false;    -verifies the integrity of the packet
% Vito Dirita - 2013
%==============================================================================
function [X, nn, Hull, dive, id, valid] = solo2_GetHeader(sbdfile)
%begin
     %outputs:
     X     = [];
     nn    = [];
     Hull  = [];
     dive  = [];
     id    = [];
     valid = true;
     
     %open the file:
     try fid = fopen(sbdfile, 'rb'); catch; return; end;
     b = fread(fid, 460);
     n = length(b);
     fclose(fid);
     if (n < 7) return; end;
     
     %header, extract more if necessary:
     X    = char(b(1));       %"X"
     nn   = 256*b(2) + b(3);  %message length
     Hull = 256*b(4) + b(5);  %hull id
     dive = 256*b(6) + b(7);  %dive number
     id   = b(8);             %packet id counter
     
     %verify the size of the packet:
     if (n      ~= nn+7) valid = false;  end;  %packet length
     if (b(1)   ~=   88) valid = false;  end;  %first char='X'  
     if (b(end) ~=   62) valid = false;  end;  %last  char='>'
                                               %checksum here...
     
end

