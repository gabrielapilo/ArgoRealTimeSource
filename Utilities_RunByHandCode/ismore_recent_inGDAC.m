% [isin] = ismore_recent_inGDAC(wmo_id,file_mode) - scriopt to check dates of file creation and see if
% our file submissions are going through successfully. it also uses
% isingdac to see if the file exists at all and puts missing files in an
% appropriate place depending on whether it's a D file of an R file that's
% missing.
%
% input:
%       wmo_id = identifier of the float to be checked
%       file mode = 'D' or 'R' - delayed mode or real-time
%
% returns:
%       isin = 1 if it is at the GDAC and the GDAC version is the most recent
%            = 2 if it is at the GDAC and the GDAC version is older
%            = 3 if it is not at the GDAC at all
  
function ismore_recent_inGDAC(wmo_id, file_mode)


global ARGO_SYS_PARAM;


if file_mode == 'D'
    filepath=['/home/argo/data/dmode/4gilson_final/' num2str(wmo_id) '/profiles/D*.nc'];
    gdacfilepath=['/home/argo/ArgoDM/cron_jobs/gdac_mirror/csiro/' num2str(wmo_id) '/profiles/D*.nc'];
else
    filepath=[ARGO_SYS_PARAM.folder_ncdf num2str(wmo_id) '/R*.nc'];
    gdacfilepath=['/home/argo/ArgoDM/cron_jobs/gdac_mirror/csiro/' num2str(wmo_id) '/profiles/R*.nc'];
end

a=dirc(filepath);
b=dirc(gdacfilepath);
[m,n]=size(a);
for i=1:m
    isin=0;
    kk=strmatch(a{i,1},b(:,1));
    if (~isempty(kk))
        j1=datenum(a{i,4});
        j2=datenum(b{kk,4})+0.5;
        if j2>=j1
            isin=1;  % gdac version is newer
        else
            isin=2;  % our version is newer
        end
    else
       if file_mode == 'R'
           dr=isingdac([filepath(1:length(filepath)-5) a{i,1}]);
           if dr == 2
               isin=1;
           else
               isin=3;
           end
       else
           isin=3;
       end
    end
    if isin==1
    elseif isin==2
        system(['cp ' filepath(1:length(filepath)-5) a{i,1} ' ' ARGO_SYS_PARAM.root_dir file_mode 'newerfiles']);
    elseif isin==3
        system(['cp ' filepath(1:length(filepath)-5) a{i,1} ' ' ARGO_SYS_PARAM.root_dir file_mode 'missingfiles']);
    end
        
    
end

    
    
    
