% function [fmtstr,bits] = bitstofmtstr()
% Parses bitfield byte and returns sscanf-style format string
% bitstr is a string in hex-encoded chars, e.g. '8E'
function [fmtstr,bits] = bitstofmtstr(bitstr)
format long g
bits=bitget(hex2dec(bitstr),1:8);
fmtstr='%04x%04x%04x%02x';
fmts={'%06x%06x%02x','%06x%06x%06x%02x','%04x%06x%02x','%06x%06x%06x%06x%02x','%06x%06x%06x%06x%02x','%04x%04x%04x%02x','',''};
for i=1:8
    if (bits(i)==1)
        fmtstr=strcat(fmtstr,fmts{i});
    end
end
% Don't forget to snarf ending bitfield and CRC
fmtstr=strcat(fmtstr,'%*02x%*02x');
