% SCALEGET: Get data from netcdf object. Only necessary for scaled integer
%           data. Convert missing_value and FillValue_ to NaNs, and scales
%           manually (because autoscaling doesn't work in Matlab 7.)
%
% INPUT: 
%    ncf  - open netcdf file object
%    varn - netcdf variable name
%    i1,i2,i3  - [optional] indices for each dimension (exactly the right
%                number for the variable). Default to all of variable.
%
% Author:   Jeff Dunn   CSIRO Marine Research   17/8/98, 18/5/06
%
% USAGE:  vv = scaleget(ncf,varn,i1,i2,i3)

function vv = scaleget(ncf,varn,varargin)

fill = ncf{varn}.FillValue_(:);
miss = ncf{varn}.missing_value(:);
scf = ncf{varn}.scale_factor(:);
ado = ncf{varn}.add_offset(:);

% Extract data WITHOUT scaling so that can detect flag values.
% We look only for exact equality to the flag values because assume are only
% checking integer data.

ii = [];
if nargin<3 | isempty(varargin{1})
   vv = ncf{varn}(:);
else
   vv = ncf{varn}(varargin{:});
end

if ~isempty(fill)
  ii = find(vv==fill);
  % Avoid checking twice if missing and fill values are the same
  if ~isempty(miss)
    if miss==fill, miss = []; end
  end
end

if ~isempty(miss) 
  i2 = find(vv==miss);
  ii = [ii(:); i2(:)];
end

if isempty(ado)
   ado = 0;
end
if ~isempty(scf)
   vv = (vv*scf) + ado;
end

if ~isempty(ii)
  vv(ii) = repmat(NaN,size(ii));
end

% ----Pre May 06
% Now extract data again WITH scaling, and overwrite any locations which held
% flag values.
%
%vv = ncf{varn,1}(:);
%if ~isempty(ii)
%  vv(ii) = repmat(NaN,size(ii));
%end

%----------------------------------------------------------------------

