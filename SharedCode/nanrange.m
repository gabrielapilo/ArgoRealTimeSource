function [ range_array ] = nanrange(x)

% NANRANGE   Finds min and max values, ignoring NaNs.
%====================================================================
%NANRANGE   1.2  8/18/92
%
%  function [ range_array ] = nanrange(x)
%
%  This finds the minimum and maximum values of a vector or matrix,
%  ignoring NaNs, and returns them in a vector of length 2.
%
%  EXAMPLE:  range_array = nanrange(x);
%
%  CALLER:   general purpose
%  CALLEE:   none
%
%  AUTHOR: Jim Mansbridge 5/6/92
%=======================================================================

%       @(#)nanrange.m   1  1.2
%
%-----------------------------------------------------------------------

if nargin ~= 1
   help nanrange
   return
end

non_nans = find(~isnan(x));
[m, n] = size(x);

if m == 1 | n == 1
   min_val = min(x(non_nans));
   max_val = max(x(non_nans));
else
   min_val = min(min(x(non_nans)));
   max_val = max(max(x(non_nans)));
end

range_array = [ min_val max_val ];
