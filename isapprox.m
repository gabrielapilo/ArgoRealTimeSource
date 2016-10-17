% function isapprox - checks whether the input is within tolerance
%  of a target:
%
% usage     ok  =  isapprox(datum,target,tolerance)
%
% where     datum  =  the number to be checked
%           target  =  what you are approximating
%           tolerance  =  how close you wish to be to the target to satisfy
%                            'approximation'
%           ok  =  1 if within tolerance, 0 if not, and -1 if one or more
%                            inputs are not numbers
%
% NOTE: all must be numbers
%  AT: Nov 2008

function ok=isapprox(datum,target,tolerance)

if(~isnumeric([datum target tolerance]))
    ok=-1;
    error(['all inputs must be numeric ' ])
else
    if(abs(datum-target)<=tolerance)
        ok=1;
    else
        ok=0;
    end
end
return
