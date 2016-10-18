function [gtime]=gregorian(julian)
% GREGORIAN  Converts Julian day numbers to corresponding Gregorian calendar dates
%       Formally, Julian days start and end at noon.
%       In this convention, Julian day 2440000 begins at 
%       1200 hours, May 23, 1968.
%
%     Usage: [gtime]=gregorian(julian) 
%
%        julian... input decimal Julian day number
%
%        gtime is a six component Gregorian time vector
%          i.e.   gtime=[yyyy mo da hr mi sec]
%                 gtime=[1989 12  6  7 23 23.356]
% 
%        yr........ year (e.g., 1979)
%        mo........ month (1-12)
%        d........ corresponding Gregorian day (1-31)
%        h........ decimal hours
%

%     Hacked by Jim Mansbridge because Rich Signell's original m-file
%     had wanted to start days at midnight, i.e., with Julian day
%     2440000 beginning at 0000 hours, May 23, 1968.  Note that Rich's
%     suggested hack doesn't work and I fixed it myself.

      julian=julian+5.e-9;    % kludge to prevent roundoff error on seconds

%      if you want Julian Days to start at noon...
    julian = julian + 0.5;

      secs=rem(julian,1)*24*3600;

      j = floor(julian) - 1721119;
      in = 4*j -1;
      y = floor(in/146097);
      j = in - 146097*y;
      in = floor(j/4);
      in = 4*in +3;
      j = floor(in/1461);
      d = floor(((in - 1461*j) +4)/4);
      in = 5*d -3;
      m = floor(in/153);
      d = floor(((in - 153*m) +5)/5);
      y = y*100 +j;
      mo=m-9;
      yr=y+1;
      i=(m<10);
      mo(i)=m(i)+3;
      yr(i)=y(i);
      [hour,min,sec]=s2hms(secs);
      gtime=[yr(:) mo(:) d(:) hour(:) min(:) sec(:)];
