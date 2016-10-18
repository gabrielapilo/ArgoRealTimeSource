function [hour,min,sec]=s2hms(secs)
% S2HMS      converts seconds to integer hour,minute,seconds
%
sec=round(secs);
hour=floor(sec/3600);
min=floor(rem(sec,3600)/60);
sec=round(rem(sec,60));
