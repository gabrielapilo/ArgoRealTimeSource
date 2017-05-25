% function [csum]=fletchcsum(linestr)
% csum is the low-order byte (uint8) of the Fletcher-16 checksum computed
% nibble-wise on linestr (line string of hex digits). 
function [csum]=fletchcsum(linestr)
% Compute line checksum
csum=0;
for j=1:length(linestr)
    csum=csum+hex2dec(linestr(j));
end
csum=mod(csum,255);