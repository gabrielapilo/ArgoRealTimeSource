% function [checkmatch]=csummatch(linestr)
% Computes Fletcher-16 checksum of line, compares against last byte
function [match]=csummatch(linestr)
% Compute line checksum
n=length(linestr);
% Get checksum as written as last 2 chars of linestr
b=hex2dec(linestr(n-1:n));
a=fletchcsum(linestr(1:n-2));
match=(a==b);