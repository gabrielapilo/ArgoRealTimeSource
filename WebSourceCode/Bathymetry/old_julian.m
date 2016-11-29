
function KDAY=julian(ID,IMO,IYR)


% function KDAY=julian(ID,IMO,IYR)
% converted from Fortran version- Werner 9/29/95
% KDAY FCN ***** KDAYS JULY 6 1977 ******
% ***************************************
% CONVERT GREGORIAN DATE TO JULIAN DAY
% USES LAST 4 DIGITS OF JULIAN DAY. ADD 2440000 TO GET
% FULL JULIAN DAY.
%
% JULY 12 1975
%
      IY = IYR - 68;
      if (2-IMO) < 0
         M = IMO - 3;
      else
         M = IMO + 9;
         IY = IY - 1;
      end
      KDAY = fix((1461*IY)/4+(153*M+2)/5 + ID - 84);

%     Full Julian Day
%      KDAY=KDAY+2440000;

