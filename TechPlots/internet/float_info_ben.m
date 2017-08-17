function [ status , typepres , bgc , typefloat , batterytype , last_date,  hull] = float_info_ben( nbfloat , document , floatnum , floatbatt , typebatt )

%% Comments
%
% This function permits to get several informations on the float type:
%
% Input:  * nbfloat  : number of the float under styudy (char).
%         * document : matfile under study.
%         * floatnum : List extracted from the argomaster spreadsheet with
%         the list of all float numbers.
%         * floatbatt: List extracted from the argomaster_sensorinfo with
%         the list of all float numbers.
%         * typebatt : List extracted from the argomaster_sensorinfo with
%         the list of all batteries used by each float.
%
% Output: * status     : status of the float (dead or alive).
%         * typepres   : type of pressure sensor used (Druck, Ametek...)
%         * bgc        : type of sensor used (oxygen, ice...)
%         * typefloat  : type of the float (APEX, Sea Bird...)
%         * batterytype: type of battery of the float (Lithium,alkaline...)
%         * last_date  : last report date of the float


%% Initialization
% Initialization of each parameter:
status = nan;
typrepres = nan;
bgc = nan;
typefloat = '';
batterytype=nan;
last_date = '';

% Go to the file with argomaster spreadsheet.
cd \\fstas2-hba\CSIRO\CMAR\Project1\argo\ArgoRT\spreadsheet


%% Argomaster spreadsheet

% Focus on the information from the line of the float under study.
index = find(floatnum == str2num(nbfloat)) + 2;
rowdet = strcat('A',num2str(index),':AE',num2str(index)) ;
[numinfo , textinfo ] = xlsread ('argomaster.csv',rowdet) ;

% Extract from this line several informations.
status = textinfo(2) ;
typepres = textinfo(end-1) ;
bgc = textinfo(end-2) ;


%% Argomaster sensor info spreasheet

% Focus on the information from the line of the float under study
index2 = find(floatbatt == str2num(nbfloat));
batterytype = typebatt(index2).battery;


%% Matfile document

document = load(document) ;

% resfloat : type of float
% resfloat = 1 : APEX
% resfloat = 2 : PROVOR
% resfloat = 3 : SOLO
% resfloat = 4 : Sea Bird
% resfloat = 5 : Sololl

if isfield(document.float , 'maker')

    resfloat = document.float.maker ;
    if resfloat == 1
        typefloat = 'APEX';
    end
    if resfloat == 2
        typefloat = 'PROVOR';
    end
    if resfloat == 3 | resfloat == 5
        typefloat = 'SOLO';
    end
    if resfloat == 4 
        typefloat = 'Sea Bird';
    end

else
    resfloat = nan ;
end



% Last report date:

if length(document.float) > 0
    if isfield(document.float , 'datetime_vec')
        if length(document.float(end).datetime_vec) == 6
            last_report = document.float(end).datetime_vec(end,:);
            last_report = last_report(1:3);
            last_date = mat2str(last_report);
            last_date = last_date(2 : end - 1);
            last_date = strrep(last_date,' ',' / ');
        end
    end
end

cd Y:\ArgoRT\briat\internet



end

