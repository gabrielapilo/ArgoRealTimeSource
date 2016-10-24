%email Vito when they are moved!!!
% system(['cat ' idatapath '/iridiumarrival.txt | mail -s"new profile from Iridium float ' num2str(dbdat.maker_id) '" ' ARGO_SYS_PARAM.overdue_operator_addrs]);

% move files for BOM.
if isfield(ARGO_SYS_PARAM,'processor')
    
    eval(['cd ' ARGO_SYS_PARAM.iridium_path]);
    % Check for the data processor information - set in set_argo_sys_params.m
    if ~isempty(strfind(ARGO_SYS_PARAM.processor,'CSIRO'))
        
        ts = ftp(ARGO_SYS_PARAM.ftp.ftp,ARGO_SYS_PARAM.ftp.name,ARGO_SYS_PARAM.ftp.pswd);
        cd(ts,'iridium_data');
        mput(ts,[ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id) '/'  fn '*'])
        close(ts);
        
        % now cleanup the original directories on rudics-server-hf:
        system(['mv ' ARGO_SYS_PARAM.rudics_server '/f' num2str(dbdat.maker_id) '/' fn '* ' ...
            ARGO_SYS_PARAM.rudics_server '/f' num2str(dbdat.maker_id) '/backup'])
        
    end
end