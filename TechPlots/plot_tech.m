%% Determine the different data from different floats
function plot_tech(wmoid)
%taken from Ben's run_all.m and adjusted to automate into RT system.
% RC August 2017

global ARGO_SYS_PARAM;

clear hidden indice document
%% Determination of the problem for everyone

[floatnum , floatbatt , typebatt] = increase_speed() ;

% Treatment of each file from the matlab file
matdir = [ARGO_SYS_PARAM.root_dir 'matfiles/'];
nbfloat = num2str(wmoid);
document = strcat(matdir,'float',nbfloat,'.mat') ;
document = load(document);
if length(document) > 0
    close all
    plot_float ( nbfloat , document , floatnum , floatbatt , typebatt )
end


