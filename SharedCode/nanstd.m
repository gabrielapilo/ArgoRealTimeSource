function y = nanstd(x,flag,dim)
%STD    Standard deviation, with NaNs ignored
%   For vectors, STD(X) returns the standard deviation. For matrices,
%   STD(X) is a row vector containing the standard deviation of each
%   column.  For N-D arrays, STD(X) is the standard deviation of the
%   elements along the first non-singleton dimension of X.
%
%   STD(X) normalizes by (N-1) where N is the sequence length.  This
%   makes STD(X).^2 the best unbiased estimate of the variance if X
%   is a sample from a normal distribution.
%
%   STD(X,1) normalizes by N and produces the second moment of the
%   sample about its mean.  STD(X,0) is the same as STD(X).
%
%   STD(X,FLAG,DIM) takes the standard deviation along the dimension
%   DIM of X.  When FLAG=0 STD normalizes by (N-1), otherwise STD
%   normalizes by N.
%
%   Example: If X = [4 -2 1
%                    9  5 7]
%     then std(X,0,1) is [ 3.5355 4.9497 4.2426] and std(X,0,2) is [3.0
%                                                                   2.0]
%
%   If x = [4  -2  1
%           9 NaN  7
%           3 NaN -2]
%   then nanstd(x, 0, 1) = [3.2146  NaN  4.5826],
%        nanstd(x, 0, 2) = [3.0000
%                           1.4142
%                           3.5355]
%        nanstd(x, 1, 1) = [2.6247  0  3.7417]
%        nanstd(x, 1, 2) = [2.4495
%                           1.0000
%                           2.5000]
%
%   See also COV, MEAN, MEDIAN, CORRCOEF.

%   J.N. Little 4-21-85
%   Revised 5-9-88 JNL, 3-11-94 BAJ, 5-26-95 dlc, 5-29-96 CMT.
%   Hacked by Jim Mansbridge to handle NaNs
%   Copyright (c) 1984-98 by The MathWorks, Inc.
%   $Revision: 1.4 $  $Date: 1999/09/14 00:43:07 $

if nargin<2, flag = 0; end
if nargin<3, 
  dim = min(find(size(x)~=1));
  if isempty(dim), dim = 1; end
end

% Avoid divide by zero.
if size(x,dim)==1, y = zeros(size(x)); return, end

% Find NaNs, replace them with zeros in X, and set up the array SS to contain
% the number of non-NaN values in each column. The latter is necessary for
% the later calculation of the mean and the subsequent standard deviation.

aa = ~isnan(x);
ff = find(aa == 0);
if ~isempty(ff) % replace NaNs by zeros
  x(ff) = zeros(size(ff));
  ss = sum(aa, dim);        % find the total number of non-nans in the column
  if flag
    fx = find(ss == 0);
  else
    fx = find(ss <= 1);
  end
  if ~isempty(fx)
    ss(fx) = repmat(NaN, size(fx));
  end
else
  ss = size(x,dim);
end

tile = ones(1,max(ndims(x),dim));
tile(dim) = size(x,dim);

xc = x - repmat(sum(x,dim)./ss,tile);  % Remove mean
if ~isempty(ff) % replace NaNs by zeros
  xc(ff) = zeros(size(ff));
end

if flag,
  y = sqrt(sum(conj(xc).*xc,dim)./ss);
else
  y = sqrt(sum(conj(xc).*xc,dim)./(ss-1));
end
