% FINDSPIKE  Argo prescribed spike tests (test 9)
%
% INPUT:  vv  - a profile of T or S
%         p   - corresponding pressures
%         var - 't' or 's'
%  
% OUTPUT:  b1  - index to spikes by test 9
%
% CSIRO/BoM Aug 2006, updated Dec 2017.
%
% USAGE: b1 = findspike(vv,p,var);

function b1 = findspike(vv,p,var)

b1 = [];

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
    
end

return
%---------------------------------------------------------------------------
