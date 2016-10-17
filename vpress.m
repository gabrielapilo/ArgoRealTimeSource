function [vapor_press] = vpress(S,T)

% vpress   Vapor pressure of sea water
%=========================================================================
% vpress Version 1.0 8/30/2004
%          Author: Roberta C. Hamme (Scripps Inst of Oceanography)
%
% USAGE:  vapor_press = vpress(S,T)
%
% DESCRIPTION:
%    Vapor press of sea water
%
% INPUT:  (if S and T are not singular they must have same dimensions)
%   S = salinity    [PSS]
%   T = temperature [degree C]
%
% OUTPUT:
%   vapor_press = vapor pressure of seawater  [atm] 
% 
% AUTHOR:  Roberta Hamme (rhamme@ucsd.edu)
%
% REFERENCE:
%   Vapor pressure of pure water: D. Ambrose and I.J. Lawrenson
%    "The vapour pressure of water"
%    Journal of Chemical Thermodynamics, v.4, p. 755-671.
%   Correction for seawater: Frank J. Millero and Wing H. Leung
%    "The thermodynamics of seawater at one atmosphere"
%    American Journal of Science, v. 276, p. 1035-1077.
%
% DISCLAIMER:
%    This software is provided "as is" without warranty of any kind.  
%=========================================================================

% CALLER: general purpose
% CALLEE: none

%----------------------
% Check input parameters
%----------------------
if nargin ~=2
   error('vpress.m: Must pass 2 parameters')
end %if

% CHECK S,T dimensions and verify consistent
[ms,ns] = size(S);
[mt,nt] = size(T);
% Check that T&S have the same shape or are singular
if ((ms~=mt) | (ns~=nt)) & (ms+ns>2) & (mt+nt>2)
   error('vpress: S & T must have same dimensions or be singular')
end %if

%------
% BEGIN
%------

%Calculate temperature in Kelvin and modified temperature for Chebyshev polynomial
temp_K = T+273.15;
temp_mod = (2*temp_K-(648+273))/(648-273);

%Calculate value of Chebyshev polynomial
Chebyshev = (2794.0144/2)+(1430.6181*(temp_mod))+(-18.2465*(2*temp_mod.^2-1))+(7.6875*(4*temp_mod.^3-3*temp_mod))+(-0.0328*(8*temp_mod.^4-8*temp_mod.^2+1))+(0.2728*(16*temp_mod.^5-20*temp_mod.^3+5*temp_mod))+(0.1371*(32*temp_mod.^6-48*temp_mod.^4+18*temp_mod.^2-1))+(0.0629*(64*temp_mod.^7-112*temp_mod.^5+56*temp_mod.^3-7*temp_mod))+(0.0261*(128*temp_mod.^8-256*temp_mod.^6+160*temp_mod.^4-32*temp_mod.^2+1))+(0.02*(256*temp_mod.^9-576*temp_mod.^7+432*temp_mod.^5-120*temp_mod.^3+9*temp_mod))+(0.0117*(512*temp_mod.^10-1280*temp_mod.^8+1120*temp_mod.^6-400*temp_mod.^4+50*temp_mod.^2-1))+(0.0067*(1024*temp_mod.^11-2816*temp_mod.^9+2816*temp_mod.^7-1232*temp_mod.^5+220*temp_mod.^3-11*temp_mod));

%Vapor pressure of pure water in kiloPascals and mm of Hg
vapor_0sal_kPa = 10.^(Chebyshev./temp_K);
vapor_0sal_mmHg = vapor_0sal_kPa*1000*0.00750062;

%Correct vapor pressure for salinity
vapor_press =(vapor_0sal_mmHg+(S.*(-0.0023311+(-0.00014799*T)+(-0.00000752*T.^2)+(-0.000000055185*T.^3)))+S.^1.5.*(-0.00001132+(-0.0000087086*T)+(0.00000074936*T.^2)+(-0.000000026327*T.^3)))*0.001315789;