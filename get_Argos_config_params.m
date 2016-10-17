% argos=get_Argos_config_params(dbdat)
%
% this script makes it easier to modify and add to various configuration
% parameters for the Argos versions of the floats.  this is based on
% getdbase
%
% the first row is the common name used in other tables; the second row is the 
%  official metadata parameter name.
%
% usage: mission = get_Argos_config_params(wmoid)

function mission = get_Argos_config_params(wmoid)

global ARGO_ID_CROSSREF
global ARGO_SYS_PARAM

kk=find(ARGO_ID_CROSSREF(:,1)==wmoid);

% filen='/home/argo/ArgoRT/spreadsheet/Argos_config_params.csv';
if ispc
filen=[ARGO_SYS_PARAM.root_dir 'spreadsheet\Argos_config_params.csv'];
else
filen=[ARGO_SYS_PARAM.root_dir 'spreadsheet/Argos_config_params.csv'];
end

if ~exist(filen,'file')
    error(['Cannot find database file ' fnm]);
end
      
   fid = fopen(filen,'r');
   tmpdb = textscan(fid,'%s','delimiter',',') ;  %,'bufsize',10000);
   tmpdb = tmpdb{1};
   
   
   ientry = 0;
   ifld = 1;
   ncol=0;
   while ifld<length(tmpdb)
       ifld = ifld+1;
%        if ~isempty(tmpdb{ifld})
%            
%            fld = tmpdb{ifld};
%            
%            if ~isempty(strfind(fld,'column1'))
%                % This field is the start-of-row marker - ie start of new float
%                ncol = 0;        % reset the column count
%                ientry = ientry+1;
%            end
%        end
fld = tmpdb{ifld};
       if ientry==0
           % get the configuration parameter names - this simplifies
           % filling the metadata mission section
           
           while isempty(strfind(fld,'start')) & isempty(strfind(fld,'official'))  %second row with config names
               ncol=ncol+1;
               param_name{ncol}=tmpdb{ifld};
               ifld=ifld+1;
               fld=tmpdb{ifld};
           end
           ncol=0;
           ifld=ifld+1;
            
           while isempty(strfind(fld,'column1'))
               ncol=ncol+1;
               config_name{ncol}=tmpdb{ifld};
               ifld=ifld+1;
               fld=tmpdb{ifld};
           end

       end
           
       if ientry>0 & isempty(strfind(fld,'column1'))
           % (if ientry==0 then we are still in the header rows)
           ncol = ncol+1;
           if ~isempty(tmpdb{ifld})
               config_data{ientry,ncol}=tmpdb{ifld};
           end
       else
           ncol = 0;
           ientry = ientry+1;
       end
   end
   mission.param=param_name;
   mission.config=config_name;
   mission.data=config_data(kk,:);
   fclose(fid)
