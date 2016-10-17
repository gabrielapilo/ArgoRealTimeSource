% inputArgoIMEI - gets the IMEIs for the argo floats that report by SBD so
% we can process them when we process the XBT SBDs
%
% this works with extract_SBD_data to determine which of the SBDs are Argo
% and which are XBT data.
%
% October 2012 - AT
%
% usage: inputArgoIMEI
% requires the file /home/argo/ArgoRT/spreadsheet/IridiumCommsIDs.csv
%  note - this needs to be updated with new numbers as they arrive


function [IMEI_dbdat,HullID] = inputArgoIMEI

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

   if isempty(ARGO_SYS_PARAM)
      set_argo_sys_params;
   end
   getdbase(-1);
   
   fnmI = [ARGO_SYS_PARAM.root_dir 'spreadsheet/IridiumCommsIDs.csv'];
   if ~exist(fnmI,'file')
      error(['Cannot find Iridium database file ' fnmI]);
   end
   
   
   fid = fopen(fnmI,'r');
   tmpdb = textscan(fid,'%s','delimiter',',');    %,'bufsize',10000);
   tmpdb = tmpdb{1};

   
   ientry = 0;
   ifld = 1;

   while ifld<length(tmpdb)
       ifld = ifld+1;
       if ~isempty(tmpdb{ifld})
           fld = lower(tmpdb{ifld});
 	 if ~isempty(strfind(fld,'column1'))
	    % This field is the start-of-row marker - ie start of new float
	    ncol = 0;        % reset the column count
	    ientry = ientry+1;
	 end
      end
       
       if ientry>0
           % (if ientry==0 then we are still in the header rows)
           ncol = ncol+1;

	 switch ncol
	   case 1
	     % Just the start of line marker
	   case 2 
	     HullID{ientry} = fld;
% 	   case 3
% 	     T(ientry).iccid = fld;
% 	   case 4
% 	     T(ientry).provider = fld;
% 	   case 5
% 	     T(ientry).misisdn = fld;
	   case 6
	     imei{ientry} = fld;
     end
       end
   end
   
   IMEI_dbdat = imei;
   return
   
   
   
   
   
   
   
   
   
     