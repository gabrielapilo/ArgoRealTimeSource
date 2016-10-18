function [z, i] = nanmin(x, y)
% NANMIN   Minimum value of matrix columns or two matrices, ignoring NaNs
%===================================================================
% NANMIN      $Revision: 1.3 $
%
% function [z, i] = nanmin(x, y)
%
% DESCRIPTION:
%    Minimum value of matrix columns or two matrices.  It is identical
%    to the built-in function MIN but is able to ignore NaNs.
% 
% INPUT:
%    x    = vector or matrix 
%    y    = vector or matrix of same order as x
%
% OUTPUT:
% If there is only one input argument:
%    z    = column-wise minimum of x.  If x a vector then y = min(x)
%           ignoring all NaNs.  Thus a min of actual data values.
%    i    = the row number of the minimum in each column of x.
% If there are two input arguments:
%    z    = a matrix the same size as X and Y with the largest elements
%           taken from X or Y. When complex, the magnitude MIN(ABS(X))
%           is used.  NaNs are ignored and if X and Y have a NaN in the
%           same position then Z will also have a NaN there.
%
% EXAMPLES:  x = [ 1  2  3;
%                 3 NaN 5];
%            z = nanmin(x)
%            z = 1  2  3
%
%            x = [ 1   2   3;
%                NaN  10 NaN;
%                 -2 NaN   7;
%                NaN NaN NaN];
%
%            y = [ 6 NaN -3;
%                NaN  -3  4;
%                  3 NaN  7;
%                NaN  -8  2];
%            z = nanmin(x, y)
%            z = 
%                  1     2    -3
%                NaN    -3     4
%                 -2   NaN     7
%                NaN    -8     2
%
% CALLER:   general purpose
% CALLEE:   none
%
% AUTHOR:   Jim Mansbridge
%==================================================================

% $Id: nanmin.m,v 1.3 1997/03/27 03:53:40 mansbrid Exp $
% 
%--------------------------------------------------------------------
  
if nargin == 1
 
  % Replace each Nan with the largest possible real before calling the
  % built-in function min.  Note that checks must be carried out for the
  % special cases when there are no NaNs or a column is filled with
  % Nans.  In the case where a column is filled with Nans we rely on the
  % fact that matlab is smart enough to be able to get exactly realmax
  % when it takes realmax*ones(size(ff_x)).
  
  ff_x = find(isnan(x));
  if length(ff_x) == 0
    [z, i] = min(x);
  else
    x(ff_x) = realmax*ones(size(ff_x));
    [z, i] = min(x);
    ff = find(z == realmax);
    if length(ff) ~= 0
      z(ff) = NaN*ones(size(ff));
      i(ff) = NaN*ones(size(ff));
    end
  end
    
elseif nargin == 2
  
  if sum(abs(size(x) - size(y))) ~= 0
    error('x and y must be the same size in nanmin(x, y)')
  end
  
  %Find the NaNs in X and Y.  Replace each NaN in X with the
  %corresponding element in Y; then reverse the roles.  Then call the
  %built in function MIN.  Note that if both matrices have a NaN in a
  %given position then X and Y still end up with a NaN in this position
  %and MIN will return a NaN in the position for the matrix of minimum
  %values.
  
  i_nanx = isnan(x);
  i_nany = isnan(y);
  x(i_nanx) = y(i_nanx);
  y(i_nany) = x(i_nany);
  z = min(x, y);
      
else
  error('nanmin must have 1 or 2 input arguments')
end
