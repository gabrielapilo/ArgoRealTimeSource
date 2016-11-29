% DSET_DUP_PREF  return default preferred datasets for duplicate removal, in
%    the required cell-array for GET_ALL_CSL
%
% INPUT:  
%   dsets  vector of dataset codes   (see DSET_NAME for meanings of codes)
%   var    the property code  
%   dset1  dataset code - the single dataset whose casts are being thinned
%          (if omit then dupref has a cell for each dataset in dsets.)
% OUTPUT:  
%  if no dset1, cell array, one cell per dataset code, containing vector of
%          codes of datasets whose duplicates are preferred to this dataset.
%  if dset1, dupref is just a vector.
%
% Jeff Dunn  15/10/04 
%
% USAGE: dupref = dset_dup_pref(dsets,var,dset1);

function dupref = dset_dup_pref(dsets,var,dset1)

if nargin<3
   dset1 = [];
end

% Note: an empty cell for a dataset means it is a primary dataset - its data
%  is preferred to all others (or it could mean there are no other datasets 
%  which could have copies of the data in this one.) 

% NOTE: still need to work out prefs for WOD01 minor subsets (25-28)

defs{199} = [];

if var==1
   defs{10} = [7 8 9 13 17 19 20 21:28];
   defs{14} = [7 8 9 11 13 19 20 21:28 35];
   defs{17} = [7 8 9 11 12 13 19 20 21:28];
   defs{18} = [7 8 9 11 12 13 17 19 20 21:28];
   defs{19} = [7 9 13 21:28];
   defs{20} = [7 8 9 11 12 13 19 21:28];
   defs{21} = [7 9 11 13];
   defs{22} = [7 9 11 13 21 72];
   defs{23} = 11;
   defs{24} = [7 9 11 13];
   defs{28} = [8 17];
   defs{35} = [7 9 13 19 21:24];
   defs{72} = [7 9 13 19 21];
elseif var==2
   defs{10} = [7 9 13 19 21:27];
   defs{19} = [7 9 13 21:28];
   defs{21} = [7 9 11 13];
   defs{22} = [7 9 11 13 21];
   defs{23} = 11;
   defs{24} = [7 9 11 13];
   defs{35} = [7 9 13 19 21:24];
   defs{72} = [7 9 13 19 21];
elseif var==3
   defs{10} = [7 9 13 19 21:27];
   defs{19} = [7 9 13 21:28];
   defs{21} = [7 9 13 22];
   defs{22} = [7 9 13];
   defs{24} = [7 9 13];
   defs{72} = [7 9 13 19 21];
else
   defs{10} = [7 9 13 19 21:27];
   defs{19} = [7 9 13 21:28];
   defs{21} = [7 9 13];
   defs{24} = [7 9 13];
   if var==6
      % No longer automatically include 71 when extracting dset 7, so now
      % need to explicitly remove dset 71 dups from dset 22.
      defs{22} = [7 9 13 21 71];
      defs{71} = [];
   else
      defs{22} = [7 9 13 21];      
   end
   defs{72} = [7 9 13 19];
end
   
nds = length(dsets);

if isempty(dset1)
   for ii = 1:nds
      kk = ismember(dsets,defs{dsets(ii)});
      dupref{ii} = dsets(kk);
   end
else
   kk = ismember(dsets,defs{dset1});
   dupref = dsets(kk);
end

%-------------------------------------------------------------------------
