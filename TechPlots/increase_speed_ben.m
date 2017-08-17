function [floatnum , floatbatt , typebatt] = increase_speed_ben()
% This function permits to increase the speed of the program by reading the
% Argomaster sensor info spreadsheet only one and getting information about
% the argomaster spreadsheet.
%
% Output: * floatnum : List extracted from the argomaster spreadsheet with
%         the list of all float numbers.
%         * floatbatt: List extracted from the argomaster_sensorinfo with
%         the list of all float numbers.
%         * typebatt : List extracted from the argomaster_sensorinfo with
%         the list of all batteries used by each float.


% Considering the Argomaster spreadsheet.
cd \\fstas2-hba\CSIRO\CMAR\Project1\argo\ArgoRT\spreadsheet

% Extract the list of the float numbers from the spreadsheet.
[numinfo , textinfo ]  = xlsread ('argomaster.csv') ;
floatnum = numinfo ( 1:end , 5 ) ;
floatnum = [ floatnum ] ;


% Considering the Argomaster sensor info spreadsheet.
[numbatt , textbatt ]  = xlsread ('argomaster_sensorinfo.csv') ;

% Extract the list of WMO_id from the sensor file
floatbatt = numbatt( :  , 1) ;

% Extract the type of battery of the floats
typebatt = textbatt ( 2:end , 41) ;
typebatt = cell2struct ( typebatt , 'battery' , 2) ;

cd \\fstas2-hba\CSIRO\CMAR\Project1\argo\ArgoRT\briat\float_status\

end
