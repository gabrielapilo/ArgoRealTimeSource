% function BOM_retrieve_Iridium
% INPUT 
%   - requires ARGO_SYS_PARAM.processor, ARGO_SYS_PARAM.ftp.ftp
%   ARGO_SYS_PARAM.ftp.name,ARGO_SYS_PARAM.ftp.pswd be set in 
%   SET_ARGO_SYS_PARAMS.m
%   - Does nothing if the ARGO_SYS_PARAM.processor field does not exist or
%   is not set to 'CSIRO' or 'BOM'
%
% OUTPUTS
%   - Copies iridium msg, log, isus files from local directory to remote
%   FTP (from CSIRO)
%   - Copies files from FTP to local directory (from BOM)
% 
%
% Author: Rebecca Cowley, CSIRO, October, 2016
%  
% CALLS: ftp (matlab built-in) 
%
%
% USAGE: BOM_retrieve_Iridium(fn)

function BOM_retrieve_Iridium(fn)

% MODS:  many not recorded
%  6/5/2014 JRD Extract extra data for traj V3 files
%   fn = file to copy
%   Updated 1 Feb, 2017 to only copy file passed in for CSIRO users.


global ARGO_SYS_PARAM

if isfield(ARGO_SYS_PARAM,'processor')
    % Check for the data processor information - set in set_argo_sys_params.m
    if ~isempty(strfind(ARGO_SYS_PARAM.processor,'CSIRO'))
        if nargin <1
            %don't try and copy files without a file name for CSIRO.
            return
        end
        % CSIRO copies the data to the FTP
        ftp_conn = ftp(ARGO_SYS_PARAM.ftp.ftp,ARGO_SYS_PARAM.ftp.name,ARGO_SYS_PARAM.ftp.pswd);
        cd(ftp_conn,'iridium_data');
        mput(ftp_conn,fn);
        close(ftp_conn);
%     elseif ~isempty(strfind(ARGO_SYS_PARAM.processor,'BOM'))        
%         %BOM are retrieving the data from the FTP
%         ftp_conn = ftp(ARGO_SYS_PARAM.ftp.ftp,ARGO_SYS_PARAM.ftp.name,ARGO_SYS_PARAM.ftp.pswd);
%         fils = dir(ftp_conn,'/iridium_data/*');
%         
%         %now go get the other iridiums
%         eval(['cd ' ARGO_SYS_PARAM.iridium_path]);
%         cd(ftp_conn,'iridium_data');
%         mget(ftp_conn,'*');
%         
%         %now that they have all the data downloaded, delete them. Copies in
%         %stampdated files if needed
%         for aa = 1:length(fils)
%             delete(ftp_conn,fils(aa).name);
%         end
%         close(ftp_conn);
    end
end
% do nothing if you are not BOM or CSIRO.

end