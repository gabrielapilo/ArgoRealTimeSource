% GETDBASE  On first call for a session, all float details are loaded from
%   the master database (massaging some fields in the process) into global 
%   variables.  If 'fnum' provided, extracts record for that float. 
%
% INPUT: fnum - WMO ID of float for which DB record required (not required 
%               if simply want to load global DB variables.)
%               fnum= -1  will force REloading of the database.
%
% OUTPUT: Sensor - structure of details for the specified float (empty if
%                 no fnum specified)
%
% File INPUT:  Reads  spreadsheet/argomaster.csv  which is a csv dump of
%              sheet 1 of argomaster.xls
%
% GLOBALS: If not already loaded this session, these global variables are
%          created:
%   THE_ARGO_FLOAT_DB - struct array of float details for every float
%   ARGO_ID_CROSSREF  - (nfloat X 3) array, rows comprising 
%         1) WMO ID    2) ARGOS ID   3) deployment num
%
% TO TEST:   for fn = [list of all float numbers...]
%                dbdat = getdbase(fn);
%            end
%
% Warnings:  Reports if 'Manufacturer' field is not as expected, or if
%   'endrow' flag is not in expected column. Both may arise if spreadsheet
%   is incomplete or if structure has been altered. 
%
% SEE ALSO:  idcrossref.m   getcaldbase.m
%
% Author:  Jeff Dunn CMAR/BoM Aug 2006
% modified by AT to supply additional sensor info - Sept 2010
% USAGE: Sensor = getadditionalinfo(fnum);

function Sensor = getadditionalinfo(fnum)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_SENSOR_DB  ARGO_ID_CROSSREF

if nargin<1 || isempty(fnum)
   fnum = 0;
elseif fnum==-1
   % this forces us to reload the database (might be useful one day)
   THE_ARGO_FLOAT_SENSOR_DB = [];
end

if isempty(THE_ARGO_FLOAT_SENSOR_DB)
    % Must be first call - so construct the database!
    % Give the new database struct array a nice short name "T" while we are
    % building it, then store it in the nice long name as befits a global variable.
    
    if isempty(ARGO_SYS_PARAM)
        set_argo_sys_params;
    end
    if ispc
        fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet\argomaster_sensorinfo.csv'];
    else
        fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet/argomaster_sensorinfo.csv'];
    end
    %  fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet/argomaster_sensorinfo.csv'];
    if ~exist(fnm,'file')
        error(['Cannot find database file ' fnm]);
    end

    fid = fopen(fnm,'r');
   %42 columns. Edit here if we need to add/remove columns
    tmpdb = textscan(fid,repmat('%s',1,42),'delimiter',',','headerlines',2);
    fclose(fid);

    for ientry = 1:length(tmpdb{1})

            T(ientry).Pressure.Name = 'Pressure';
            T(ientry).Temperature.Name = 'Temperature';
            T(ientry).Salinity.Name = 'Salinity';
            T(ientry).Oxygen.Name = 'Oxygen';
            T(ientry).Transmissometer.Name = 'Transmissometer';
            T(ientry).FLBB.Name = 'FLBB';
            T(ientry).Pressure.Symbol = 'P1';
            T(ientry).Temperature.Symbol = 'T1';
            T(ientry).Salinity.Symbol = 'S1';
            T(ientry).Oxygen.Symbol = 'Op01';
            T(ientry).Transmissometer.Symbol = 'WT1';
            T(ientry).FLBB.Symbol = 'FL1';
            T(ientry).Temperature.Units = 'degC';
            T(ientry).Salinity.Units = 'PSU';


       for ncol = 1:length(tmpdb)
            fld = lower(tmpdb{ncol}{ientry});
            fld2 = tmpdb{ncol}{ientry};

            switch ncol
                case 1
                    % Just the start of line marker
                case 2
                    T(ientry).wmo_id = str2num(fld);
                case 3
                    T(ientry).mfg_id = str2num(fld); % note - for NMDIS, we changed this to be fld.  no idea why?
                case 4
                    T(ientry).Deploymentorder = str2num(fld);
                case 5
                    T(ientry).CTD_mfg = fld2;
                    T(ientry).Temperature.Maker = fld2;
                    T(ientry).Salinity.Maker = fld2;
                case 6
                    T(ientry).CTDSerialNo = fld;
                    T(ientry).Temperature.SerialNo = fld;
                    T(ientry).Salinity.SerialNo = fld;
                case 7
                    T(ientry).Firmware_Revision = fld2;
                case 8
                    T(ientry).CTDtype = fld2;
                    T(ientry).Temperature.ModelNo = fld2;
                    T(ientry).Salinity.ModelNo = fld2;
                case 9
                    T(ientry).Pressure.mfg = fld2;
                case 10
                    T(ientry).Pressure.SerialNo = fld;
                case 11
                    T(ientry).Pressure.Units = fld;
                case 12
                    T(ientry).Oxygen.mfg = fld2;
                case 13
                    T(ientry).Oxygen.ModelNo = fld2;
                case 14
                    T(ientry).Oxygen.SerialNo = fld2;
                case 15
                    T(ientry).Oxygen.Units = fld;
                case 16
                    T(ientry).Transmissometer.mfg = fld2;
                case 17
                    T(ientry).Transmissometer.ModelNo = fld2;
                case 18
                    T(ientry).Transmissometer.SerialNo = fld;
                case 19
                    T(ientry).Transmissometer.Units = fld;
                case 20
                    T(ientry).FLBB.mfg = fld2;
                case 21
                    T(ientry).FLBB.ModelNo = fld2;
                case 22
                    T(ientry).FLBB.SerialNo = fld;
                case 23
                    T(ientry).FLBB.Units = fld;
                case 24
                    T(ientry).Eco.mfg = fld2;
                case 25
                    T(ientry).Eco.SerialNo = fld;
                case 26
                    T(ientry).Eco.ModelNo = fld2;
                case 27
                    T(ientry).SUNA.mfg = fld2;
                case 28
                    T(ientry).SUNA.SerialNo = fld;
                case 29
                    T(ientry).SUNA.ModelNo = fld2;
                case 30
                    T(ientry).Irr.mfg = fld2;
                case 31
                     T(ientry).Irr.SerialNo = fld;
                case 32
                    T(ientry).Irr.ModelNo = fld2;
                case 33
                    T(ientry).Rad.mfg = fld2;
                case 34
                    T(ientry).Rad.SerialNo = fld;
                case 35
                    T(ientry).Rad.ModelNo = fld2;
                case 36
                    T(ientry).pH.mfg = fld2;
                case 37
                    T(ientry).pH.SerialNo = fld;
                case 38
                    T(ientry).pH.ModelNo = fld2;  %fld;
                case 39
                    T(ientry).UplinkSystem = fld;
                case 40
                    T(ientry).UplinkSystemID = fld;
                case 41
                    T(ientry).Battery_Configuration = fld2;
                case 42
                    T(ientry).PTTFrequencyMHz = fld;
            end

        end
    end
end
Sensor = T;


if fnum>0
   ii = find(ARGO_ID_CROSSREF(:,1)==fnum);
   if isempty(ii)
      disp(['Error - cannot find float ' num2str(fnum) ' in the database']);
      Sensor = [];
      return
   end
   Sensor = Sensor(ii);
else
   Sensor = [];
end

return

%----------------------------------------------------------------------------
