% ISINGDAC Determine whether given files exist as R or D files, or not at
%     all, at the GDAC
%
% INPUT:
% fnms:   filename or cell array of filenames (which can include paths) eg:  
%          '5901163_011'
%      or {'netcdf/5900853/profiles/R5900853_001.nc', .. etc .. }
%
% OUTPUT    vector corresponding to input files
% dstat:  0 = file not in GDAC
%         1 = R file in GDAC
%         2 = D file in GDAC
%         -1 = badly structured file name?
%
% JRD 23/10/09  
% 
% USAGE: dstat = isingdac(fnms);

function dstat = isingdac(fnms)

persistent file_type profile_number wmo_id file_name

if isempty(file_type)
   disp('Loading GDAC list')
%    load /home/argo/data/argo_cdf/argo_desc data_centre_id profile_number file_type wmo_id
   load /home/argo/ArgoDM/cron_jobs/gdac_mirror/argo_desc data_centre_id profile_number file_type wmo_id file_name;
   
   iii = (data_centre_id==4);
   wmo_id = wmo_id(iii);
   profile_number = profile_number(iii);
   file_type = file_type(iii);
   file_name = file_name(iii);
   clear data_centre_id ii
end

if ~isempty(fnms) & ~iscell(fnms)
   fnms = cellstr(fnms);
end
nn = length(fnms);
   
dstat = zeros(nn,1);

for ii = 1:nn
   % Strip down the file name to WMOid and PN
   ftmp = deblank(fnms{ii});   
   if ispc
       kk = strfind(ftmp,'\');
   else
       kk = strfind(ftmp,'/');
   end
   if ~isempty(kk)
      ftmp = ftmp((kk(end)+1):end);
   end
   kk = strfind(ftmp,'.nc');
   if ~isempty(kk)
      ftmp = ftmp(1:(kk(end)-1));
   end
   kk = strfind(ftmp,'_');
   if length(kk)~=1
      dstat(ii)  = -1;
   else
      if isempty(str2num(ftmp(1)))
          if isempty(str2num(ftmp(2)))
              wmoid = str2num(ftmp(3:(kk-1)));
          else
              wmoid = str2num(ftmp(2:(kk-1)));
          end
      else
          wmoid = str2num(ftmp(1:(kk-1)));
      end
      pn = str2num(ftmp((kk+1):end));
      if isempty(wmoid) | isempty(pn)
          dstat(ii) = -1;
      else
          jj = find(wmo_id==wmoid & profile_number==pn);
          if ~isempty(jj)
              lenfile=length(fnms{nn});
              for g=1:length(jj)
                  kl=length(file_name{jj(g)});
                  if lenfile==kl
                      break
                  end
              end
              dstat(ii) = file_type(jj(g));
          end
      end
   end
end

%-----------------------------------------------------
	 
   
