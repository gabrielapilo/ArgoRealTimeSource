% GETCALDBASE  On first call for a session, all float CALIBRATION details are
%   loaded from the master cal database into a global variable struct array. 
%
% INPUT - nil
%
% OUTPUT 
%  global var THE_ARGO_CAL_DB - structure of calibration details for all 
%  floats
%
% File INPUT:  Reads  /argomaster_cal.csv  which is a csv dump of
%              sheet 2 of argomaster.xls  (? maybe ?)
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
%
% USAGE: getcaldbase;

function getcaldbase

global ARGO_SYS_PARAM
global THE_ARGO_CAL_DB  ARGO_CAL_WMO

% Give the new database struct array a nice short name "T" while we are 
% building it, then store it in the nice long name as befits a global variable.

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
fnm = [ARGO_SYS_PARAM.root_dir 'spreadsheet/argomaster_cal.csv'];
if ~exist(fnm,'file')
   error(['Cannot find database file ' fnm]);
end

fid = fopen(fnm,'r');
tmpdb = textscan(fid,'%s','delimiter',',');   %,'bufsize',10000);
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
      if isempty(tmpdb{ifld}) && ncol<=32
	 T(ientry).complete = 0;
	 fld = '';
      end
      
      switch ncol
	case 1
	  % Just the start of line marker
	case 2 
	  T(ientry).wmo_id = str2num(fld);
	case 3
	  T(ientry).sbe_snum = str2num(fld);
	case 4
	  T(ientry).cond_acc = str2num(fld);
	case 5
	  T(ientry).cond_res = str2num(fld);
	case 6
	  T(ientry).temp_acc = str2num(fld);
	case 7
	  T(ientry).temp_res = str2num(fld);
	case 8
	  T(ientry).pres_acc = str2num(fld);
	case 9
	  T(ientry).pres_res = str2num(fld);
	case 10
	  T(ientry).PA0 = str2num(fld);
	case 11
	  T(ientry).PA1 = str2num(fld);
	case 12
	  T(ientry).PA2 = str2num(fld);
	case 13
	  T(ientry).PTCA0 = str2num(fld);
	case 14
	  T(ientry).PTCA1 = str2num(fld);
	case 15
	  T(ientry).PTCA2 = str2num(fld);
	case 16
	  T(ientry).PTCB0 = str2num(fld);
	case 17
	  T(ientry).PTCB1 = str2num(fld);
	case 18
	  T(ientry).PTCB2 = str2num(fld);
	case 19
	  T(ientry).PTHA0 = str2num(fld);
	case 20
	  T(ientry).PTHA1 = str2num(fld);
	case 21
	  T(ientry).PTHA2 = str2num(fld);
	case 22
	  T(ientry).TA0 = str2num(fld);
	case 23
	  T(ientry).TA1 = str2num(fld);
	case 24
	  T(ientry).TA2 = str2num(fld);
	case 25
	  T(ientry).TA3 = str2num(fld);
	case 26
	  T(ientry).G = str2num(fld);
	case 27
	  T(ientry).H = str2num(fld);
	case 28
	  T(ientry).I = str2num(fld);
	case 29
	  T(ientry).J = str2num(fld);
	case 30
	  T(ientry).CPCOR = str2num(fld);
	case 31
	  T(ientry).CTCOR = str2num(fld);
	case 32
	  T(ientry).WBOTC = str2num(fld);
	case 33
	  % Check the end-of-row marker (not really necessary, but safer)
	  if isempty(strfind(fld,'9999'))
	     disp(['GETCALDBASE: No "99999" at col 33, row ' num2str(ientry)]);
	  end
	otherwise
	  % should not be any other fields
	  
      end    % end of 'switch'
   end     % end of 'ientry>0  (ie have got past headers, started float rows)
end      % end of looping on every field read


% Create a WMO ID lookup table
ARGO_CAL_WMO = repmat(nan,ientry,1);
for ii = 1:ientry
   if ~isempty(T(ii).wmo_id)
      ARGO_CAL_WMO(ii) = T(ii).wmo_id;
   end
end

THE_ARGO_CAL_DB = T;

return

%----------------------------------------------------------------------------
