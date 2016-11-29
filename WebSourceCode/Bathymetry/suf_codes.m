%   Documentation for "suf" code for specifying hydro datasets
%   (as used in get_all_csl.  See also SUF_TO_PAR)
%
% The codes 1 to 9 identify the following datasets:
% 1)ctd  2)ctd2  3)bot  4)bot2  5)xbt  6)xbt2  7)CSIRO(CTD&Hyd)
% 8)CSIRO XBT archive  9)NIWA
%
% 1-6) are World Ocean Database 98 (WOD98) files
%
%  1,3,5  are NODC quality controlled (not very rigourous)
%  2,4,6  are from "data archaeology" projects, NODAR & GODAR, and this data
%  is of variable quality, especially some of the xbt2 data which is rubbish.
% 
%  1,2 are from CTDs, 3,4 are from Niskin & Nansen bottles, and 5,6 are XBT and
%  MBT and similar probes.
% 
% 7)  refers to all CSIRO data (except that which is in WOD98.) This also includes 
%  Aurora Australis Southern Ocean cruises.
%
% 8)  is the "clean" XBT dataset for the Australian region (90-145E, 70S to 
% Equator), prepared by Wijffels & Gronell. I'm not sure how public this is meant 
% to be, but we have access to it. It is meant to be totally complete and 
% extensively screened, and have all the temperature data that all the other 
% datasets contain. However, we have set it up so that you only get XBTs from this 
% dataset. If you select 5 and/or 6 as well as 8, you get 8) within the region 
% specified above, and 5 and/or 6 outside that region.
%
% 9) NIWA - the total hydrographic (CTD & bottle data) archives of the NZ 
% equivalent of CSIRO.
%
% So, to get all temperature data, including XBTs, might use codes 1:9.
% For only high accuracy T, or salinity, only sensible to use [1:4 7 9]. For 
% nutrients, only [3:4 7 9]. 
