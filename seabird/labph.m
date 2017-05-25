%  deltapH = pH25 - pHinsituT,P untuned 

function ph25tot=phlabcalc(pHinsituTotal, T, P)    
    ph25tot = pHinsituTotal - (0.015 * (25.0 - T));
end
