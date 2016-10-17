% function [fmtstr,bits] = bitstofmtstr(bitstr[,swapmode])
% Parses bitfield byte and returns sscanf-style format string
% bitstr is a string in hex-encoded chars, e.g. '8E'

% The new 41CP appends binned serial data a string of hexadecimal numbers:
% 04D84C9F88D5172B28D41947050400029C00032700024E033D0A0026FE0302003901FF5902034401FEBD24                                                  091C
% ppppttttssssnnwwwwwwvvvvvvmmyyyyyyxxxxxxzzzzzzqqrrrrttttttffjjjjjjbbbbbbaaaaaaccccccjjjjjjbbbbbbaaaaaaccccccddhhhhiiiikkkkooffffffuuuunneegg
% The string above includes the, optional, samples per pressure bin and is in the following order:
% 1.	pressure
% 2.	temperature
% 3.	salinity
% 4.	optical oxygen
% 5.	MCOMS
% 6.	C-Rover
% 7.	OCR-504 #1
% 8.	OCR-504 #2
% 9.	ECO
% 10.	average tilt and standard deviation of tilt
% 11.	pH voltage and temperature

% Bitfield and checksum

% 0xbbcc	
% bb	bitfield
%8 7 pH and optionally second thermistor
%7 6 tilt
%6 5 serial device 6 (ECO)
%5 4 serial device 5 (OCR-504 #2)
%4 3 serial device 4 (OCR-504 #1)
%3 2 serial device 3 (C-Rover)
%2 1 serial device 2 (MCOMS)
%1 0 serial device 1 (SBE 63)
% cc	C0 of Fletcher-16 checksum


function [fmtstr,bits] = bitstofmtstr(bitstr,varargin)
format long g
bits=bitget(hex2dec(bitstr),1:8);
%              PTS
fmtstr='%04x%04x%04x%02x';
%         SBE63             MCOMS             CRV2K            OCR504I                OCR504R               ECO            tilt        pHV/phT
fmts={'%06x%06x%02x','%06x%06x%06x%02x','%04x%06x%02x','%06x%06x%06x%06x%02x','%06x%06x%06x%06x%02x','%04x%04x%04x%02x','%02x%02x','%06x%04x%02x'};
for i=1:6
    if (bits(i)==1)
        fmtstr=strcat(fmtstr,fmts{i});
    end
end

if ((nargin >= 2) && strcmp(varargin{1},'noswap'))
    fmtstr=strcat(fmtstr,fmts{7});
    fmtstr=strcat(fmtstr,fmts{8});
else
    % Bitfields 7 and 8 pH and tilt are different order in bitfield vs. HEX -
    % see TRAC #686 - but ONLY for SOME builds of 41N FW!
    if (bits(7)==1)
        fmtstr=strcat(fmtstr,fmts{8});
    end
    
    if (bits(8)==1)
        fmtstr=strcat(fmtstr,fmts{7});
    end
end
% Don't forget to snarf ending bitfield and CRC
fmtstr=strcat(fmtstr,'%*02x%*02x');
