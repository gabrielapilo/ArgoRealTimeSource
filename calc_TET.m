% CALC_TET  Compute TET and estimate clock drift according to
%     argo_DAC_cookbook_V1.4, Annex B.
%     See sec 1.2.4 for use and recording of clock offset
%     Cookbook uses units of hr:min:sec per year for clock offset
%
% Variations to method:
%   - instead of linear fit to points on conv hull, use slope of "dominant"
%     conv hull segment. "dominant" is combination of longest, most central,
%     smallest drift. Single segment is more robust for small series and avoids some
%     pathologies in larger series. However many very large series display
%     a gentle change of drift, in which case the standard method gives a better
%     fit to the whole series. In these cases, taking a weighted combination of the two best
%     hull segments equals the skill of standard method but a) the
%     improvement is small and b) it can cause problems unless manually
%     selected. Could apply new method only where <130 data, say, but still
%     some beneficial cases in longer series.         
%
%    Jeff Dunn  CSIRO  Sept 2013
%
% INPUT  dbdat - float metadata database record
%        LMT   - vector of LMT values
%
% OUTPUT  TET  - [nn 2] TET values, standard and Dunn
%         clkoffset - [1 2] apparent clock drift, standard and Dunn [decimal minutes per year]
%         tstat - Report: length(gd) clkoffset mpy(1) mpyav s1 s2

function [TET,clkoffset,tstat] = calc_TET(cyctim,LMT,pfnm)

% Hard-coded switch for plotting
plot_it = 1;
mpyav = nan;

clkoffset = [nan nan];
LMT = LMT(:);

%% This is not yet used... will want to check new value against it
%if isfield(dbdat,'clock_offset')
%   clockoffset = dbdat.clock_offset;
%end

% Special treatment is required for Deep Profile First floats, and a few
% other floats that have varying cycle times. Below is for all other floats.

% Cookbook says to use treatment 1 if less than 33 cycles.

ncyc = length(LMT);
icyc = (1:ncyc)';
TET = nan(ncyc,2);
LMTrv = LMT - (icyc-1)*cyctim;   % each cycle LMT normalized to LMT(1)

% Cases of stray late LMT would blow out the alg1 TET and skew the alg2 clock 
% offset. In both cases the TET would be very different to the LMT for most
% cycles, which is probably the best way to detect it because it can be
% disguised by clock drift. 
% 
% Apart from bad LMT cases, if there is no clock offset LMT-LMT(1) will have 
% a highly skewed distribution - all values approach but do not exceed the
% cycletime. We want to exclude any that somehow exceed the cycletime envelope. 
% We could improve the LMT estimate fit by excluding a portion of the lefthand
% values but clock drift means we can only do that when we have a drift
% estimate. 


% LMT tend to approach TET over a period (or set of cycles), then start
% approaching again from maximum time offset. Hence, LMT is near to TET only 
% periodically. Fitting to the convex envelope works if we have several of
% these sets, so we only attempt if enough (33) cycles. It can work ok for
% low numbers if we keep only the envelope associated with max values for
% each set by ignoring the first and last 20% of cycles. However, it can
% still be a poor estimate (eg 1901123 when it had 39 cycles.) However the 
% algorithm is pretty robust and wee just have to accept some dodgy RT calc
% for low-cycle floats.

gd = find(~isnan(LMT));

if length(gd)<33
   % Algorithm 1, Cookbook 5.3.1. no known clock offset. 
   TET1 = max(LMTrv(gd));
   TET(:,1) = TET1 + (icyc-1)*cyctim;

else
   % Algorithm 2, Cookbook 5.3.2. Have, or need to test for, clock offset. 

   % 1. Compute convex envelope of LMT (and trim to just the max-side
   % envelope, since it starts off completely encircling the set of points.)
   kk = gd(convhull(gd,LMTrv(gd)));   
   kl = find(kk==max(gd));
   if mean(LMTrv(kk(1:kl))) > mean(LMTrv(kk(kl:end)))
      % Then the first half of the envelope is along the maximum value (RH)
      % side, which is what we want 
      kk((kl+1):end) = [];
   else
      % The second half is on the maximum value side. Flip the index so it is
      % also in ascending order
      kk = kk(kl:end);
      kk = flipud(kk(:));
   end

   % ... Dunn adaptation ............
   % 
   % Drop first and last hull points if there is another which is also close
   % to the end of the series (because these are just the hull wrapping around incomplete
   % sets of cycles.)
   mxgd = max(gd);
   if sum(kk<(mxgd*0.1)) >= 2
      [~,ik] = min(kk);
      kk(ik) = [];
   end
   if sum(kk>(mxgd*0.9)) >= 2 
      [~,ik] = max(kk);
      kk(ik) = [];
   end

   
   % ... Dunn method ............
   % 
   % Compute drift for each hull segment
   for jk = 1:(length(kk)-1)
      kks = kk([jk jk+1]);
      mnk(jk) = mean(kks);
      lngk(jk) = diff(kks);
      grad(jk) = diff(LMTrv(kks))./lngk(jk);
   end
   
   % Weight according to nearness to middle of series
   haf = min(gd) + (mxgd-min(gd))./2;
   w1 = 1 - abs(haf-mnk)./haf;
      
   % Weight according to length of hull section
   w2 = lngk./max(lngk);
   
   % Weight according to slope. Cap at 30mpy
   alpha = 1440*365.25/cyctim;
   mpy = grad*alpha;    % gradient as +ve minutes per year
   tmp = mpy;
   tmp(abs(mpy)>30) = 30;
   w3 = 1 - abs(tmp/30);
   
   % Select "best" segment 
   [wmx,jbest] = max(w1+w2+w3);
   TET(:,2) = mean(LMTrv(kk)) + grad(jbest)*icyc;

   clkoffset(2) = mpy(jbest);
   
   % 5,6 Adjust the fit so that no good LMT exceed that line, compute TETs using
   % adjustment slope as a clock offset
   adj = max(LMTrv(kk)-TET(kk,2));
   TET(:,2) = TET(:,2)+adj;
   
   % Just diagnostics - weighted average of two best segments often matches
   % standard method better, but can go wrong, so at this stage we don't use it.
   if length(w1)>1  
      [~,iw] = sort(w1+w2,'descend');
      sw = w1.*w2;
      mpyav = alpha*sum(grad(iw(1:2)).*sw(iw(1:2)))./sum(sw(iw(1:2)));
      %disp(num2str(mpyav));
   elseif length(w1)==1  
      mpyav = mpy(1);
   else
      mpyav = nan;
   end   
   % End Dunn method ...............
   
   
   % Standard method ...............
   %
   % 2. Set a point on the convex envelope for each cycle
   % JRD: Bad LMT values seem more likely when data is patchy - ie near gaps in
   % LMT record. If we calc Tce just for cycles with an LMT then we will not
   % be adding values around the bad isolated ones, which reduces the chance
   % of those effecting the line fit. Should I implement this?  
   Tce = interp1(kk,LMTrv(kk),icyc);
   
   % 3,4. Ignoring the first and last 1/5 of points, get linear fit
   jj = vec(floor(ncyc*0.2):ceil(ncyc*0.8));
   if sum(~isnan(Tce(jj)))<20
      % If removing any dud values leaves too few for polyfit then relax the
      % exclude-ends limits      
      jj = vec(floor(ncyc*0.1):ceil(ncyc*0.9));
   end
   jj(isnan(Tce(jj))) = [];
   
   pp = polyfit(jj,Tce(jj),1);

   TET(:,1) = pp(2) + pp(1).*icyc;
   
   % 5,6 Adjust the fit so that no good LMT exceed that line, compute TETs using
   % adjustment slope as a clock offset
   adj = max(LMTrv(kk)-TET(kk,1));
   if adj>0
      TET(:,1) = TET(:,1)+adj;
   end

   % JD See if clock correction suggests bad CYCLE TIME. ANDRO found most
   % real offsets were in range +/- 10 mins, and -2.30 to +0.30 for newer
   % floats.   ***** Was this per year or per cycle ??
   if abs(pp(1)) > 20/1440
      % A clock offset of more than 20 mins per cycle
      disp(['Is CYCLE TIME correct: nominally ' num2str(cyctim*24) ...
	    ' hours but looks like ' num2str((cyctim+pp(1))*24) ' hours?']);
   end
   % Convert apparent clock offset to minutes/year
   clkoffset(1) = pp(1)*1440*365.25/cyctim;
   

   if plot_it
      clf
      disp(['Clock drift: ' num2str(clkoffset) ' minutes/year'])
      L0 =  min(LMTrv);
      plot(1440*(LMTrv-L0),icyc,'+')
      hold on
      plot(1440*(TET(:,1)-L0),icyc,'co')
      plot(1440*(TET(:,2)-L0),icyc,'mx')
      lgnd = {'LMT (ref LMT(1))','TETstd','TETdunn'};
      if length(gd)<ncyc
	 % Excluded outliers
	 ii = icyc;
	 ii(gd) = [];	 
	 plot(1440*(LMTrv(ii)-L0),ii,'r*')
	 lgnd{4} = 'excluded LMT';
      end
      legend(lgnd,'location','best');
      xlabel('Minutes')
      ylabel('Cycle Number')
      title(pfnm);
      print('-djpeg',pfnm)
   end
end
   

% Now make TET absolute time rather than relative.
% Where we have excluded any aberrant LMT from the TET calc, we should now
% replace the TET with those LMT values which are later than the TET. 
for jj = 1:2
   % just for reporting, count where LMT is near-coincident with TET
   coinc(jj) = sum(abs(LMTrv(gd)-TET(gd,jj)) < 2/1440);

   TET(:,jj) = TET(:,jj) + (icyc-1)*cyctim;

   ii = LMT>TET(:,jj);
   TET(ii,jj) = LMT(ii);
end

% ... Reporting during development phase
% Count near-coincident point
tstat = [length(gd) clkoffset mpyav coinc]; 

return

%---------------------------------------------------------------------------
