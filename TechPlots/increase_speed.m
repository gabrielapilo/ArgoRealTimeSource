function [ floatnum , floatbatt , typebatt ] = increase_speed( )
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

global ARGO_SYS_PARAM;

% Considering the Argomaster spreadsheet.
fmt = repmat('%s',1,31);
fid = fopen([ARGO_SYS_PARAM.root_dir '/spreadsheet/argomaster.csv']);
numinfo = textscan(fid,fmt,'delimiter',',','headerlines',2);
fclose(fid);

% % Extract the list of the float numbers from the spreadsheet.
% [numinfo , textinfo ]  = xlsread ('argomaster.csv') ;
 floatnum = numinfo {7} ;
 floatnum = str2num(char(floatnum)) ;


% Considering the Argomaster sensor info spreadsheet.
% [numbatt , textbatt ]  = xlsread ('argomaster_sensorinfo.csv') ;
fmt = repmat('%s',1,42);
fid = fopen([ARGO_SYS_PARAM.root_dir '/spreadsheet/argomaster_sensorinfo.csv']);
numbatt = textscan(fid,fmt,'delimiter',',','headerlines',2);
fclose(fid);

% Extract the list of WMO_id from the sensor file
floatbatt = str2num(char(numbatt{2})) ;

% Extract the type of battery of the floats
typebatt = numbatt {end-1} ;
typebatt = cell2struct ( typebatt , 'battery' , 2) ;

end

