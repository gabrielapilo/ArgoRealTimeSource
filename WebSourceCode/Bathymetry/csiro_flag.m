%  CSIRO cast quality flag
%
% This is an integer data quality flag, applying to an entire profile (so 
% there may be a difference between the flags for different properties of
% the same cast) or to individual measurements.
%
% The 1st digit is source QC flag (eg NODC screening), and the 2nd and 3rd 
% are CSIRO flags.
%
% For all digits, 0 = good data 
%
% So, only use cast if csiro_flag = 0
%
% Meaning of local screening values
%  Second digit:
%       0  - passed all local screening tests
%       1  - bad position (on land as defined by GEBCO coastline, or NaN, or
%            lat=lon=0 .) What about missing time as well?
%       2  - duplicate; ie a second occurrence of data which is already in the
%            dataset
%       3  - bad data: no specific definition
%       4  - [now disused] CSIRO-sourced data, flagged in other dataset
%            to avoid duplicate use
%       5  - Data which may be correct, but extreme values may corrupt maps 
%            (examples are river outflow or within NZ fjords)
%       6  - Suspect data excluded from use (if were more certain would use '3')  
%       7  - used to temporarily cut out some data; no specific meaning
%       9  - empty cast
%
%  Third digit:
%       1  - significant dynamic instability
%       2  - whole cast rejeted, has extreme or too many bad values 
%
% Examples:
% 1) Original NODC flag=3, and local screening value=5, new cast_flag=53
% 2) csiro_flag = 100:   cast is ok by NODC and local checks, except for 
%    dynamic instability
%
% SEE ALSO:  show_flag.m
%
%   Jeff Dunn 1996-2005

help csiro_flag
