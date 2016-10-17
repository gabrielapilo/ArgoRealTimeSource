% QC_APPLY  Set QC-flagged values to NaN 
%
% USAGE: vo = qc_apply(vv,qc);

function vo = qc_apply(vv,qc);

vo = vv;
if length(qc)==length(vo)
   ii = find(qc>2 & qc~=5);
   vo(ii) = NaN;
end

%-----------------------------------------------------------------------------
