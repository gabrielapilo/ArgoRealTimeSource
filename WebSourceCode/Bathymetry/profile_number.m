% 	CSIRO profile numbers (cpn)
% 	~~~~~~~~~~~~~~~~~~~~~
% This is a unique profile number for all locally held hydrographic data of a 
% given generation. However, when a new version of NODC data or French data is
% incorporated, the profile number assignments will change (since they are just
% consecutively numbered.) 
% 
% WOD98 data
%     Integer, 4 lefthand digits are WMO square number, 5 righthand digits are 
%     consecutive numbering in that square. 
%     Example: 331400100 is profile 100 in WMO 3314. 
%     These numbers uniquely identify the casts. Where some cast exists in 
%     multiple files, such as nutrients and temperature in separate files, then
%     that data will have the same csiro_profile_no. 
%
%     Note that NODC now intend to preserve the OCL number from one generation
%     of WOD to the next, so we may soon start using those numbers.
%
% CSIRO data
%     VccccSSS
%    where
%      V    = vessel: 1=Franklin(FR)  2=Southern Surveyor(SS)  3=Aurora(AU)
%                     4=Sprightly(G9)  5=Soela(AS)  9=other&coastal
% 	        *** 8 is reserved for all other data sources ***
%      cccc = 4 digit cruise
%      SSS  = station number within cruise
%    ie:
%       cpn = V*10000000 + cr*1000 + station;
%
% CRC data
%     As above, that is:
%     VccccSSS
%    where
%      V    = vessel;  3=Aurora  9=other
%      cccc = cruise, see below for cruises acquired directly from CRC, as 
% 	    opposed to residing in CMR archives
% 	  9391 9404 9407 9501 9601 9604 9701 9706 9807 9901 9706 0051
%      SSS  = station number within cruise
%    ie:
%       cpn = V*10000000 + cr*1000 + station;
%
% NIWA data
%     Generate profile ID from 3 of the 4 cruise ID digits, and station
%     number:
%         cruise([1 3 4])*10000 + stn
%     This allows for the station numbers which exceed 1000, and still
%     keeps the total number 1 digit less than CSIRO profile numbers.
%
%     Two "lost" cruises were obtained, and required constructed cruise IDs:
% 	allocate cruise id 101 to hc73h  
% 			   102 to hc74j
%     The cpn's for these cruises then went from 1010501 to 1020624
%
% OTHER data sources
%      8xnnnnnn
%         where 8=other data sources  
%           and x = 0 : French data CD of 2001
%                   1 : IOTA (CSIRO's  Indian Ocean Thermal Archive)  
%    French data
%         cpn = 80000000 + consecutive acquisition number;
%    IOTA data
%         cpn = 81000000 + consecutive acquisition number;
   
% ===========================================================================

help profile_number
