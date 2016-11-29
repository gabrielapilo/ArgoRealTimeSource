% DSET_NAME  Return dataset name(s) corresponding to dataset codes (or if
%  no argument given, list all codes and names).
%
% USAGE: dnms = dset_name(dsets);

function dnms = dset_name(dsets)

fnm = platform_path('fips','eez_data/software/matlab/dset_names');
load(fnm)

if nargin<1 | isempty(dsets)
   for ii = 1:length(dset_names)
      if ~isempty(dset_names{ii})
	 disp([num2str(ii)  '   ' dset_names{ii}]);
      end
   end
   dnms = [];
else
   dnms = dset_names(dsets);
end
