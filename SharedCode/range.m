function [ range_array ] = range(x)

% RANGE   Finds min and max values (for matlab5 NaNs are ignored).
%====================================================================
%RANGE   1.2  8/18/92
%
%  function [ range_array ] = range(x)
%
%  This finds the minimum and maximum values of a vector or matrix, and
%  returns them in a vector of length 2.  For matlab5 NaNs are ignored.
%
%  EXAMPLE:  range_array = range(x);
%
%  CALLER:   general purpose
%  CALLEE:   none
%
%  AUTHOR: Jim Mansbridge 5/6/92
%=======================================================================

%       @(#)range.m   1  1.2
%
%-----------------------------------------------------------------------

if nargin ~= 1
   help range
   return
end

range_array = [ min(x(:)) max(x(:)) ];
