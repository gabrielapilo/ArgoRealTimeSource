function y = nansum(x, dim)
% NANSUM    Sum of elements, same as in matlab 5 but ignoring NaNs
%===================================================================
%
% function y = nansum(x, dim)
%
% DESCRIPTION:
%    Sum of elements, same as in matlab 5 but ignoring NaNs.
%    For vectors, NANSUM(X) is the sum of the elements in X. For
%    matrices, NANSUM(X) is a row vector containing the sum along
%    each column.  For N-D arrays, NANSUM(X) is the sum of the
%    elements along the first non-singleton dimension of X.
% 
%    NANSUM(X,DIM) takes the sum along the dimension DIM of X. 
%
%    Note that if a whole column is filled with NaNs then when a
%    sum is done along that column a NaN will be returned.
%
% INPUT:
%    x    = array of any dimension
%    dims = dimension along which to take the sum
%
% OUTPUT:
%    y    =  a sum of actual data values, i.e., ignoring NaNs.
%
% EXAMPLES:
%           x = [ 1  2  3; 5 NaN 7];
%           y = nansum(x)
%           y = [6 2 10]
%
%           x = [ 1  NaN  3; 5 NaN 7];
%           y = nansum(x)
%           y = [6 NaN 10]
%
%           x = [ 1  NaN  3; 5 NaN 7];
%           y = nansum(x, 2)
%           y = [4; 12]
%
% CALLER:   general purpose
% CALLEE:   none
%
% AUTHOR:   Jim Mansbridge
%==================================================================

% $Id: nansum.m,v 1.3 1999/01/15 00:03:11 mansbrid Exp $
% Copyright J. V. Mansbridge, CSIRO, Thu Jan 14 17:52:47 EST 1999
  
if nargin == 0
  error('nansum expects either 1 or 2 arguments')
end

if nargin == 1
  aa = ~isnan(x);
  ff = find(aa == 0);
  if (length(ff) ~= 0) % replace NaNs by zeros
    x(ff) = zeros(size(ff));
  end
  ss = sum(aa);    % find the total number of non-nans in the column
  y = sum(x);      % calculate the sum
  ff = find(ss == 0);
  if (length(ff) ~= 0) % put NaNs where the sum came from a column of NaNs
    y(ff) = NaN*zeros(size(ff));
  end
elseif nargin == 2
  aa = ~isnan(x);
  ff = find(aa == 0);
  if (length(ff) ~= 0) % replace NaNs by zeros
    x(ff) = zeros(size(ff));
  end
  ss = sum(aa, dim);   % find the total number of non-nans in the column
  y = sum(x, dim);     % calculate the sum
  ff = find(ss == 0);
  if (length(ff) ~= 0) % put NaNs where the sum came from a column of NaNs
    y(ff) = NaN*zeros(size(ff));
  end
end

