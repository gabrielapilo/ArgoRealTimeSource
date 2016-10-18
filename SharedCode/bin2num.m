% BIN2NUM  Convert vector of 0 and 1 to decimal  
%     (differs from BIN2DEC which works from string binary)
%
% INPUT  bb    [N n_bits] rows contain only 0 or 1, each represents a
%              binary number
%        nbit  length of each number where bb is shape [1 N*nbit]
%
% OUTPUT dd  [N 1]  
%
% JRD CMAR July 2006
%
% USAGE: dd = bin2num(bb,nbit)

function dd = bin2num(bb,nbit)

if nargin<2 || isempty(nbit)
   [N,nbit] = size(bb);
else
   [nn,mm] = size(bb);
   if nn>1 || rem(mm,nbit)~=0
      logerr(2,['Error in inputs to bin2num. size(bb) = ' num2str([nn mm])]);
      dd = [];
   else
      N = round(mm/nbit);
      bb = reshape(bb,[nbit N])';
   end
end

twos = pow2(nbit-1:-1:0);
dd = sum(double(bb) .* twos(ones(N,1),:),2);

return
%----------------------------------------------------------------------------
