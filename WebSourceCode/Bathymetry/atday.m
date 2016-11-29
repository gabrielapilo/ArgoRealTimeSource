% ATDAY:  Evaluate a mean field and temporal harmonics at a given day-of-year
%
% INPUT: doy - scalar or vector day-of-year
%        mn  - mean, scalar or same-size as doy, or any shape if doy is scalar
%        an  - complex annual coeffs, same size as mn
%        sa  - [optional] complex semi-annual coeffs, same size as mn
%
% OUTPUT: val - value at day-of-year
%
% Jeff Dunn CSIRO Marine Research   Last mod: 16/7/99
%
% USAGE:  val = atday(doy,mn,an,sa);

function val = atday(doy,mn,an,sa)

if nargin==0
  disp('val = atday(doy,mn,an,sa)');
  return
end

ii = find(isnan(an));
if ~isempty(ii)
  an(ii) = zeros(size(ii));
end

val = mn + real(an.*exp(-i*2*pi/366*doy));

if nargin==4 & ~isempty(sa)
  ii = find(isnan(sa));
  if ~isempty(ii)
    sa(ii) = zeros(size(ii));
  end
  val = val + real(sa.*exp(-i*4*pi/366*doy));
end
