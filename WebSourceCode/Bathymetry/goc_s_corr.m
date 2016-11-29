% GOC_S_CORR
%
% Find rainfall-index-derived correction to apply to Gulf of Carp salinity
% fields to adjust for interannual signal.
%
% INPUT:  time  - unix time (decimal days since 1900)
%
% OUTPUT: sadd  - correction to ADD to climatological salt field (everywhere,
%                 and at any depth.)
%
% Temporary code, 4/10/05  jrd
%
% USAGE: sadd = goc_s_corr(time);

function sadd = goc_s_corr(tim)

fnm = platform_path('cascade','dunn/eez_data/goc_s_corr');
load(fnm);
aa = interp1(rtim,r3wrm_norm,tim);

if isnan(aa)
   sadd = 0;
else
   sadd = -1.4 * aa;
end
