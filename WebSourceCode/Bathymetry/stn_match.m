% STN_MATCH  Find matching station & dset in two lists.
%
% USAGE: [i1,i2] = stn_match(sn1,ds1,sn2,ds2);

function [i1,i2] = stn_match(sn1,ds1,sn2,ds2)

i1 = [];
i2 = [];
dss = unique(ds1);
for id = dss(:)'
   k1 = find(ds1==id);
   k2 = find(ds2==id);
   if ~isempty(k1) & ~isempty(k2)
      [tmp,j1,j2] = intersect(sn1(k1),sn2(k2));
      i1 = [i1; k1(j1)];
      i2 = [i2; k2(j2)];
   end
end
