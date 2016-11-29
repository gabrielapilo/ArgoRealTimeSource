% MINJD: On machines where the mex minjd is invoked, it is much more efficient
%        than the Matlab 5 builtin function. On other machines, minjd is just
%        a wrapper for the Matlab "min".
%
% NOTE:  Returns a NaN for any column containing a NaN.
%
% USAGE: minA = minjd(A)     OR    [minA,indx] = minjd(A)

% This code is only as a fallback on machines on which I cannot compile minjd.c

function [ma,indx] = minjd(a)

if nargout==1
  ma = min(a);
else
  [ma,indx] = min(a);
end
