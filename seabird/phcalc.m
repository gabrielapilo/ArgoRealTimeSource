% function [phfree,phtot]=phcalc(Vrs, Press, Temp, Salt, DFETCoef)
function [phfree,phtot]=phcalc(Vrs, Press, Temp, Salt, DFETCoef)
%%%%%%%%%  this version is modified per Yui comments in two places
%%%%%%%%  lnKhso4fac - press/10 to get to bars
%%%%%%%%
    R = 8.31451;
    F = 96485;
    Tk = 273.15 + Temp;
    ln10 = log(10);
    
    % converted to  mol/kg H20 per YUI by *(1 + 0.00106 * Salt)
    IonS = 19.924 .* Salt ./ (1000 - 1.005 * Salt);
    %
    %  changed to match Yui%s equations
    Stotal = (0.14 / 96.062) .* (Salt / 1.80655) .* (1 + 0.00106 .* Salt);
    Cltotal = 0.99889 / 35.453 .* Salt / 1.80655 .* (1 + 0.00106 .* Salt);
    %  bisulfate dissociation constant at T, S  from Dickson
    %   I corrected to IonS per yui
    Khso4 = exp(-4276.1 ./ Tk + 141.328 - 23.093 .* log(Tk) + (-13856 ./ Tk + 324.57 - 47.986 .* log(Tk)) .* IonS .^ 0.5 + (35474 ./ Tk - 771.54 + 114.723 .* log(Tk)) .* IonS - 2698 ./ Tk .* IonS .^ 1.5 + 1776 ./ Tk .* IonS .^ 2 + log(1 - 0.001005 .* Salt));
    
%   Debug.Print Khso4
    % bisulfate dissociation constant from Khoo et al.
%   Khso4 = 10 ^ -(647.59 / Tk - 6.3451 + 0.019085 * Tk - 0.5208 * IonS ^ 0.5)
%   Debug.Print Khso4
%   End
    
    deltaVHSO4 = -18.03 + 0.0466 .* Temp + 0.000316 .* Temp .^ 2;
    KappaHSO4 = (-4.53 + 0.09 .* Temp) / 1000;
    %%%%%%%  per Yui Press changed from dbar to bar here by / 10
    lnKhso4fac = (-deltaVHSO4 + 0.5 .* KappaHSO4 .* (Press / 10)) .* (Press / 10) ./ (R * 10 .* Tk);
    %  bisulfate association constant at T, S, P
    Khso4TPS = Khso4 .* exp(lnKhso4fac);
    
    %  gamma +/- HCl at T, S from Khoo
    %  Debye Huckel constant A
    ADH = (0.00000343 .* Temp .^ 2 + 0.00067524 .* Temp + 0.49172143);
  %  Debug.Print ADH
    log10gammaHCl = -ADH .* sqrt(IonS) ./ (1 + 1.394 .* sqrt(IonS)) + (0.08885 - 0.000111 .* Temp) .* IonS;
    % Millero
    deltaVHcl = 17.85 + 0.1044 .* Temp - 0.001316 .* Temp .^ 2;
    
    ThermoPress = -deltaVHcl .* 0.0242 ./ (23061 * 1.01) .* Press ./ 10;
%%%%%%%%%%%%% per Yui comment original line modified so ThermoPress (in units of volts is added to E0 not to log10gammaHCL
%   log10gammaHCLtP = log10gammaHCl + ThermoPress
    log10gammaHCLtP = log10gammaHCl;
    
    %  Sensor constant
    
%    Debug.Print "loggamma  ", log10gammaHCl, "  ", log10gammaHCLtP
    
    E0T = DFETCoef(1) + DFETCoef(2) * Temp;
    pcoef = 0;
    % compute Pressure coefficient as polynomial in pressure (dbar)
    for j = 3:length(DFETCoef)
        pcoef = pcoef + DFETCoef(j) * Press .^ (j - 2);
    end

    E0TP = E0T + pcoef;
%    Debug.Print Press, Temp, Vrs, PCoef, E0T, E0TP
%    Debug.Print Press, lnp
%    Debug.Print "E0 ", E0T, " Pcoef ", Pcoef
    
%%%%%%%%%%% Per Yui Comment, ThermoPress added into Vrs -E0TP term
%    pHinsituFree = (Vrs - E0TP) / (R * Tk / F * ln10) + log(Cltotal) / ln10 + 2 * log10gammaHCLtP
    phfree = (Vrs - E0TP - ThermoPress) ./ (R .* Tk ./ F * ln10) + log(Cltotal) ./ ln10 + 2 * log10gammaHCLtP;
    
    phtot = phfree - log10(1 + Stotal ./ Khso4TPS);
    
 %   Debug.Print "pH   ", pHinsituFree
end


