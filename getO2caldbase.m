% GETO2CALDBASE  On first call for a session, all float CALIBRATION details are
%   loaded from the master cal database into a global variable struct array. 
%
% INPUT - nil
%
% OUTPUT 
%  global var THE_ARGO_O2_CAL_DB - structure of oxygen calibration details for all 
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
% July 2015 - modified to remove non-O2 cal coeffs which have been moved to
% a different spreadsheet.  AT
%
% USAGE: getcaldbase;

function getO2caldbase

global ARGO_SYS_PARAM
global THE_ARGO_O2_CAL_DB  ARGO_O2_CAL_WMO

% Give the new database struct array a nice short name "T" while we are 
% building it, then store it in the nice long name as befits a global variable.

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet/argomaster_O2cal.csv'];
if ~exist(fnm,'file')
   error(['Cannot find database file ' fnm]);
end
fid = fopen(fnm,'r');
tmpdb = textscan(fid,'%s','delimiter',',');  %,'bufsize',10000);
tmpdb = tmpdb{1};
SBE63=0;
SBEO2=0;
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
      if isempty(tmpdb{ifld}) && ncol<=32
	 T(ientry).complete = 0;
	 fld = '';
      end
      
 switch ncol
	case 1
	  % Just the start of line marker
	case 2
%         if ientry>=60
%             fld=fld
%         end
      T(ientry).model_no = fld;
	case 3
	  T(ientry).wmo_id = str2num(fld);
      dbdat=getdbase(str2num(fld));
      if isempty(dbdat)
          dbdat.flbb=0;
          dbdat.tmiss=0;
          dbdat.suna=0;
      end
      
	case 4
	  % Webb serial number - irrelevant
	case 5
        T(ientry).O2_snum = str2num(fld);
      if ~isempty(strfind(T(ientry).model_no,'sbe')) | ~isempty(strfind(T(ientry).model_no,'ido'))
          if isempty(strfind(T(ientry).model_no,'63'))
              SBEO2=1;
              SBE63=0;
          else 
              SBEO2=0;
              SBE63=1;
          end
      else
          SBEO2=0;
          SBE63=0;
      end
	case 6
      T(ientry).a0 = str2num(fld);
	case 7
      T(ientry).a1 = str2num(fld);
	case 8
      T(ientry).a2 = str2num(fld);
	case 9
	  T(ientry).a3 = str2num(fld);
	case 10
	  T(ientry).a4 = str2num(fld);
	case 11
	  T(ientry).a5 = str2num(fld);
	case 12
	  T(ientry).a6 = str2num(fld);
	case 13
%         ientry=ientry;
%         if dbdat.flbb
%             if SBEO2
%                 T(ientry).a7 = 2.00907;
%             end
%         else
            T(ientry).a7 = str2num(fld);
%         end
	case 14        
        T(ientry).a8 = str2num(fld);
    case 15
        if SBE63
            T(ientry).T0 = str2num(fld);
        else
            T(ientry).a9 = str2num(fld);
        end
     case 16
         if SBE63
             T(ientry).T1 = str2num(fld);
         else
             T(ientry).a10 = str2num(fld);
         end
     case 17
         if SBE63
             T(ientry).T2 = str2num(fld);
         else
             T(ientry).a11 = str2num (fld);
         end
     case 18
         if SBE63
             T(ientry).T3 = str2num(fld);
         else
             T(ientry).a12 = str2num(fld);
         end
     case 19
         T(ientry).a13 = str2num(fld);
     case 20
         T(ientry).a14 = str2num(fld);
     case 21
          T(ientry).a15 = str2num(fld);
 	case 22
        T(ientry).a16 = str2num(fld);
     case 23
         T(ientry).a17 = str2num(fld);
     case 24
         T(ientry).a18 = str2num(fld);
     case 25
         T(ientry).a19 = str2num(fld);
     case 26
         T(ientry).a20 = str2num(fld);
 	case 27
	  T(ientry).a21 = str2num(fld); % FoilCoefA -13
	case 28
	  T(ientry).a22 = str2num(fld); % FoilCoefB -0
	case 29
	  T(ientry).a23 = str2num(fld); % FoilCoefB -1
	case 30
	  T(ientry).a24 = str2num(fld); % FoilCoefB -2
	case 31
	  T(ientry).a25 = str2num(fld); % FoilCoefB -3
	case 32
	  T(ientry).a26 = str2num(fld); % FoilCoefB -4
	case 33
	  T(ientry).a27 = str2num(fld); % FoilCoefB -5
	case 34
	  T(ientry).a28 = str2num(fld); % FoilCoefB -6
	case 35
	  T(ientry).a29 = str2num(fld); % ConcCoef -0
	case 36
	  T(ientry).a30 = str2num(fld); % ConcCoef -1
	case 37
         % Check the end-of-row marker (not really necessary, but safer)
	  if isempty(strfind(fld,'9999'))
	     disp(['GETO2CALDBASE: No "99999" at col 27, row ' num2str(ientry)]);
	  end
	otherwise
	  % should not be any other fields
	  
      end    % end of 'switch'
   end     % end of 'ientry>0  (ie have got past headers, started float rows)
end      % end of looping on every field read


% Create a WMO ID lookup table
ARGO_O2_CAL_WMO = repmat(nan,ientry,1);
for ii = 1:ientry
   if ~isempty(T(ii).wmo_id)
      ARGO_O2_CAL_WMO(ii) = T(ii).wmo_id;
   end
end

THE_ARGO_O2_CAL_DB = T;

return

%----------------------------------------------------------------------------
