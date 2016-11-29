% DIMS  Improvement on ndims in that 1-D and empty objects are identified 
%           Jeff Dunn  CMR  11/2/99

function ndim = dims(A)

if isempty(A)
   ndim = 0;
else
   ndim = length(size(A));
   if ndim==2 & min(size(A))<2
      ndim = 1;
   end
end
