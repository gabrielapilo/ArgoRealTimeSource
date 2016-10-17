% CALC_TST  Compute TST according to argo_DAC_cookbook_V1.4, Annex B, sec 6.2.
%
% Note: Cookbook uses units of hr:min:sec per year for clock offset
%
%    Jeff Dunn  CSIRO  Sept 2013
%
% INPUT  juld   - block 1 julian days
%        nb     - msg numbers corresp to juld
%
% OUTPUT  TST  - single TST value
%         stat - 0=good,  2=dodgy
%
% Teledyne method is to know rep rate and number of blocks and compute back
%
% Recommended method is to get all B1 times and message numbers, difference
% all combinations to find the most-common value for BTD (Block
% Duration = RepRate*(Max num blocks)), then compute back.
%
% How does this compare to a linear regression through all Tn/Bn pairs, maybe
% with some iterative outlier trimming??? - see calc_TST_JD.m
%
% USAGE: [TST,calstat] = calc_TST(juld,nb,rawdat,dbdat);

function [TST,calstat] = calc_TST(juld,nb,rawdat,dbdat)

calstat = 0;
   
nb1 = length(nb);

TST = nan(1,max(cumsum(1:(nb1-2))));
btd = nan(1,max(cumsum(1:(nb1-2))));

% This calc will struggle if we have values from two or more cycles. Could 
% handle by working with only consecutive pairs. The pair straddling the 
% cycles will be a huge outlier, but all others should agree. Then need to
% decide for which cycle to determine TST. This issue is averted when we have
% first screened with a realistic jdayrng

% sub-method X
% This calculation will amplify errors where point separation is smaller, so
% avoid using adjacent points by indexing from (ii+2).
nn = 0;
for ii = 1:(nb1-1)
   for kk = (ii+2):nb1
      nn = nn+1;
      btd(nn) = (juld(kk)-juld(ii))./(nb(kk)-nb(ii));
      TST(nn) = juld(ii) - ((nb(ii)-1).*btd(nn));
   end
end

% sub-method Y
% If assume values are either precise or wrong, and we are only wanting to
% establish the reprate, then using only adjacent pairs will either give us
% the right or a wrong value. Eg if straddling 2 cycles then this would show
% up as just one anomalous value. We can then easily reject the outlier and,
% optionally, then use other methods to refine the answer. This method suits
% small samples. However this would work poorly if instead all values had
% some level of error, since small separation magnifies errors.  



if (nargin>=4 && ~isempty(rawdat) && isfield(rawdat,'maxblk') && ...
    rawdat.maxblk>0 && ~isempty(dbdat) && ~isempty(dbdat.reprate) && ...
    dbdat.reprate>0)
   
   btd = round(btd/rawdat.maxblk);
   rr = unique(btd);
   cnts = zeros(1,length(rr));
   for ii = 1:length(rr)
      cnts(ii) = sum(btd==rr(ii));
   end
   imax = max(cnts);
   if rr(imax)==dbdat.reprate 
      % These agree with database and maxblk, so can reject outliers 
      jj = (btd~=dbdat.reprate);
      TST(jj) = [];
   else
      % Few agree with dbdat.reprate
      calstat = 2;
   end
end

% Loop while we have outliers and more than 20 values remaining
minscr = 2/1440;    % 2 minutes is close enough [check this assumption]
while nn>20
   jj = abs(TST-median(TST)) > max([3.5*std(TST) minscr]);
   if any(jj)
      TST(jj) = [];
      nn = length(TST);
   else
      nn = 0;
   end
end

TST = median(TST);

%------------------------------------------------------------------------
