% AUSBATH_REGION  Extract a chunk of AUsBath15 bathymetry
%
%  reg - [w e s n] region
%
%  deps - -ve downwards
%
% USAGE: [deps,x,y] = ausbath_region(reg)

function [deps,x,y] = ausbath_region(reg)

fnm = platform_path('fips','eez_data/bath/ausbath15');
load(fnm);

AusBath15 = flipud(AusBath15);

ix = find(x_bath>=reg(1) & x_bath<=reg(2));
iy = find(y_bath>=reg(3) & y_bath<=reg(4));

if isempty(ix) | isempty(iy)
   disp([7 'This region is outside of that covered by AusBath15 (109-156E,' ...
	    ' 45-1S)']);
   return
end  

deps = AusBath15(iy,ix);
x = x_bath(ix);
y = y_bath(iy);

return

%---------------------------------------------------------------------------
