%% Determine the different data from different floats

clear all 
if ispc
    matdir = '\\fstas2-hba\CSIRO\CMAR\Project1\argo\ArgoRT\matfiles\';
    mfiledir = '\\fstas2-hba\CSIRO\CMAR\Project1\argo\ArgoRT\briat\float_status\';
else
    matdir = '/home/argo/ArgoRT/matfiles/';
    mfiledir = '/home/argo/ArgoRT/briat/float_status/';
end

%Go to the file with data
cd(matdir)

% Create a list with every data (for which float)
liste=dir('*');

% Treatment of this list in order to get only the relevant items
% Type : float#####.mat

indice = 1;

while indice <= length(liste)
    
    document = liste(indice).name ;
    
    if isdir(document)
        liste(indice) = [] ;
    else
        hidden = strfind(document,'.') ;
        if hidden(1) == 1 | isdir(document) | length(strfind(document,'aux')) | length(strfind(document,'mt')) | length(strfind(document,'old')) | length(strfind(document,'badDOXY')) | length(strfind(document,'zip')) | length(strfind(document,'orig')) | length(strfind(document,'badPosns')) | length(strfind(document,'fixoxy')) | length(strfind(document,'aux')) | length(strfind(document,'missingdata')) |  length(strfind(document,'txt')) |  length(strfind(document,'Template')) | length(strfind(document,'new')) | length(strfind(document,'Tech'))
            liste(indice) =[] ;
        else
            indice = indice + 1 ;
        end
    end
    
end


% Return to the file of treatment
% CHANGE THE PATH HERE
cd(mfiledir)

clear hidden indice document
%% Determination of the problem for everyone

lglist = length(liste) ;

% Ben's computer
%[floatnum , floatbatt , typebatt] = increase_speed_ben() ;

% Bec's computer
[floatnum , floatbatt , typebatt] = increase_speed() ;


for indice = 772:lglist
    % Treatment of each file from the matlab file
    namefolder = liste(indice).name ;
    nbfloat = strtok(flip(strtok(flip(namefolder),'t')),'.') ;
    document = strcat(matdir,namefolder) ;
    %strat('Progress : ', num2str(indice / lglist * 100) , '%')c
    indice
    if length(document) > 0
        close all
        figure
        plot_float ( nbfloat , document , floatnum , floatbatt , typebatt )
        cd ../internet/
        
        close all
        figure
        plot_parameters_float ( nbfloat , document , floatnum , floatbatt , typebatt )
        cd ../float_status/
    end
    
end

close all
clear document indice lglist namefolder nbfloat