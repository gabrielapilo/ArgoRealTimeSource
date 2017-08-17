function [deltaV,Vo]=float_compress(s,t,p,Wg,ga,al)
%
%
% calculates the displacement required by a profiling float 
% to reach surface from pressure p.
% INPUTS:   s,t,p - ctd profile
%           Wg    - float weight in grams
%           ga    - float compressibility (ga = d/dp ln(V/Vo) per decibar)
%           al    - float thermal expansibility (al = d/dT ln (V/Vo) per degC)

% based on equation supplied in a memo from Dana Swift, UW, Seattle as well as
% a program supplied by Russ Davis, SIO.

% check
nz = length(p);
if length(s) ~= nz, error('s  and p must be same size'),end
if length(t) ~= nz, error('t  and p must be same size'),end

dens = sw_dens(s,t,p) ;

% volume at this pressure if nuetrally ballasted:
Vo = Wg./dens*1e3;

% change in volume if float moved to the surface 
deltaV = Vo.*( dens/dens(1) - 1 - ga*(p - p(1)) - al*(t(1) - t));

return 


