% FINDSPIKE  Argo prescribed spike tests (tests 9 & 10)
%
% Presently algorithm straight from 'addQC.m'
%
% INPUT:  vv  - a profile of T or S
%         p   - corresponding pressures
%         var - 't' or 's'
%  
% OUTPUT:  b1  - index to spikes by test 9
%          b2  - index to spikes by test 10  (obsolete and useless)
%
% CSIRO/BoM Aug 2006
%
% USAGE: [b1,b2] = findspike(vv,p,var);

function [b1,b2] = findspike(vv,p,var)

b1 = []; b2 = [];

lv = length(vv);

% Test9
% testv is distance of v(n) outside the range of values v(n+1) and v(n-1). 
% If -ve, v(n) is inside the range of those adjacent points.

if lv>=3
   jj = 2:(lv-1);

   testv = abs(vv(jj) - (vv(jj+1)+vv(jj-1))/2) - abs((vv(jj+1)-vv(jj-1))/2);
   
   if strfind(lower(var),'t')   
      b1 = find((p(jj)<500 & testv>6) | (p(jj)>=500 & testv>2)) + 1;
   elseif strfind(lower(var),'s')
      b1 = find((p(jj)<500 & testv>.9) | (p(jj)>=500 & testv>.3)) + 1;
   elseif strfind(lower(var),'o')
      b1 = find((p(jj)<500 & testv>50) | (p(jj)>=500 & testv>25)) + 1; 
   end

   if nargout>=2
      % Test 10. Argo Quality Control Manual V2.1 (Nov 30, 2005) states
      % that this test is obsolete (fair enough - it was rubbish!)
      dd = diff(vv);
   if strfind(lower(var),'t')   
       if dd(1)>1;   b2 = 1;   end
       if -dd(end)>1; b2 = [b2 lv]; end
   else
      kk=find(p>1500);
      ll=find(-dd(kk)>.1);
      if(~isempty(ll)); b2=kk(ll); end
%      if dd(1)>.1;   b2 = 1;   end
      if -dd(end)>1; b2 = [b2 lv]; end
   end

   end
end

return
%---------------------------------------------------------------------------
