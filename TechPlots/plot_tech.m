%% Determine the different data from different floats
function plot_tech(float,dbdat)
%taken from Ben's run_all.m and adjusted to automate into RT system.
% RC August 2017

global ARGO_SYS_PARAM;

clear hidden indice document
%% Determination of the problem for everyone

[floatnum , floatbatt , typebatt] = increase_speed() ;

% Treatment of each file from the matlab file
if length(float) > 0
    close all
    plot_float ( float ,dbdat , floatnum , floatbatt , typebatt )
end


