function [ markcolor ] = flag_battery( liststudied )
%
% This function permits to characterize if a failure is due to a battery
% problem of voltage.
% 
% Input: list of battery voltage from a float.
%
% Output:  * Battery ok             (voltage > 12.5)      : green.
%          * Battery critical       (10 < voltage < 12.5) : orange.
%          * Battery very critical  (voltage < 10)        : red.

markcolor = [0 0 1];
    
if length(liststudied)>0

    if liststudied(end) < 12.5
        if liststudied(end) < 10
            markcolor = [1 0 0];
        else
            markcolor = [1 .5 0];
        end
    else
        markcolor = [0 0.498 0];
    end
end   
    
end