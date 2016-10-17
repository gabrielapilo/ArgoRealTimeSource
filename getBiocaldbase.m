
% GETBIOCALDBASE  On first call for a session, all float CALIBRATION details are
%   loaded from the master cal database into a global variable struct array. 
%
% INPUT - nil
%
% OUTPUT 
%  global var THE_ARGO_BIO_CAL_DB - structure of oxygen calibration details for all 
%  oxygen floats - note - only oxygen sensors reporting Bphase are present
%  in this file
%
% File INPUT:  Reads  /argomaster_O2cal.csv  which is a csv dump of
%              sheet 4 of argomaster.xls  (? maybe ?)
%
% CALLED BY:  metadata_nc.m
%
% SEE ALSO:  getdbase.m
%
% NOTE: If we can decide that this is a numeric-only spreadsheet then a
%       simpler approach can be used (maybe even using "xlsread") rather
%       than reading all fields as text then decoding to numbers.      
%
% Author:  Jeff Dunn CMAR/BoM Oct 2006
%
% MODS:   Date -  Comment -  Author
% modified from getO2caldbase  July 2015 - AT
%
% USAGE: getcaldbase;

function getBiocaldbase

global ARGO_SYS_PARAM
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

% Give the new database struct array a nice short name "T" while we are 
% building it, then store it in the nice long name as befits a global variable.

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
if ispc
fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet\argomaster_BIOcal.csv'];
else
fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet/argomaster_BIOcal.csv'];    
end

if ~exist(fnm,'file')
   error(['Cannot find database file ' fnm]);
end
fid = fopen(fnm,'r');
tmpdb = textscan(fid,'%s','delimiter',',');  %,'bufsize',10000);
tmpdb = tmpdb{1};

ientry = 0;
ifld = 1;

while ifld<length(tmpdb)
   ifld = ifld+1;
   if ~isempty(tmpdb{ifld})
      fld = lower(tmpdb{ifld});

      if ~isempty(strfind(fld,'11111'))
	 % This field is the start-of-row marker - ie start of new float
	 ncol = 0;        % reset the column count
	 ientry = ientry+1;
	 T(ientry).complete = 1;
      end
   end

   if ientry>0
       % (if ientry==0 then we are still in the header rows)
       ncol = ncol+1;
       if isempty(tmpdb{ifld}) % && ncol<=27
%            T(ientry).complete = 0;
           fld = '';
       end
      
   switch ncol
       case 1
          % Just the start of line marker
       case 2
           T(ientry).wmo_id = str2num(fld);
           dbdat=getdbase(str2num(fld));
           if isempty(dbdat)
               dbdat.flbb=0;
               dbdat.tmiss=0;
               dbdat.suna=0;
           end
       case 3
           % Webb serial number - irrelevant
       case 4
               T(ientry).TM_snum = str2num(fld);
       case 5
               T(ientry).TMdark = str2num(fld);
       case 6
               T(ientry).TMair = str2num(fld);
       case 7
               T(ientry).TMref = str2num(fld);
       case 8
               T(ientry).FLBB700sn = str2num(fld);
       case 9
               T(ientry).FLBB700dc = str2num(fld);
       case 10
               T(ientry).FLBB700scale = str2num(fld);
       case 11
               T(ientry).FLBBCHLdc = str2num(fld);
       case 12
               T(ientry).FLBBCHLscale = str2num(fld);
       case 13 
               T(ientry).BBP700angle = str2num(fld);
       case 14
               T(ientry).BBP700Chi = str2num(fld);
       case 15
               T(ientry).CDOMdc = str2num(fld);
       case 16
               T(ientry).CDOMscale = str2num(fld);
       case 17
               T(ientry).FLBB532dc = str2num(fld);
       case 18
               T(ientry).FLBB532scale = str2num(fld);
       case 19
               T(ientry).BBP532angle = str2num(fld);
       case 20
               T(ientry).BBP532Chi = str2num(fld);
       case 21
               T(ientry).FLBB470dc = str2num(fld);
       case 22
               T(ientry).FLBB470scale = str2num(fld);
       case 23
               T(ientry).BBP470angle = str2num(fld);
       case 24
               T(ientry).BBP470Chi = str2num(fld);
       case 25
               T(ientry).EcoFLBB700sn = str2num(fld);
       case 26
               T(ientry).EcoFLBB700dc = str2num(fld);
       case 27
               T(ientry).EcoFLBB700scale = str2num(fld);
       case 28
               T(ientry).EcoFLBB700angle = str2num(fld);
       case 29
               T(ientry).EcoFLBB700Chi = str2num(fld);
       case 30
               T(ientry).EcoFLBB532dc = str2num(fld);
       case 31
               T(ientry).EcoFLBB532scale = str2num(fld);
       case 32
               T(ientry).EcoFLBB532angle = str2num(fld);
       case 33
               T(ientry).EcoFLBB532Chi = str2num(fld);
       case 34
               T(ientry).EcoFLBB470dc = str2num(fld);
       case 35
               T(ientry).EcoFLBB470scale = str2num(fld);
       case 36
               T(ientry).EcoFLBB470angle = str2num(fld);
       case 37
               T(ientry).EcoFLBB470Chi = str2num(fld);
       case 38
               T(ientry).SUNAsn = str2num(fld);
       case 39
               T(ientry).SUNAcals = str2num(fld);
       case 40
               T(ientry).pHsn = str2num(fld);           
       case 41
                T(ientry).pHk0 = str2num(fld);          
       case 42
                T(ientry).pHdelk0 = str2num(fld);          
        case 43
                T(ientry).pHk1 = str2num(fld);          
       case 44
                T(ientry).pHk2 = str2num(fld);          
       case 45
                T(ientry).pHk3 = str2num(fld);          
       case 46
                T(ientry).pHk4 = str2num(fld);          
       case 47
                T(ientry).pHk5 = str2num(fld);          
        case 48
                T(ientry).pHk6 = str2num(fld);          
     case 49
           % Check the end-of-row marker (not really necessary, but safer)
           if isempty(strfind(fld,'9999'))
               disp(['GETBioCALDBASE: No "99999" at col 40, row ' num2str(ientry)]);
           end
       otherwise
           % should not be any other fields
           
   end    % end of 'switch'
   end     % end of 'ientry>0  (ie have got past headers, started float rows)
end      % end of looping on every field read

% Create a WMO ID lookup table
ARGO_BIO_CAL_WMO = repmat(nan,ientry,1);
for ii = 1:ientry
   if ~isempty(T(ii).wmo_id)
      ARGO_BIO_CAL_WMO(ii) = T(ii).wmo_id;
   end
end

THE_ARGO_BIO_CAL_DB = T;

return
%----------------------------------------------------------------------------

 