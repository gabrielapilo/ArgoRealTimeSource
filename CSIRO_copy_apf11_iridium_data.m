% move files.
if isfield(ARGO_SYS_PARAM,'processor')
    
    eval(['cd ' ARGO_SYS_PARAM.iridium_path]);
    % Check for the data processor information - set in set_argo_sys_params.m
    if ~isempty(strfind(ARGO_SYS_PARAM.processor,'CSIRO'))        
        % now cleanup the original directories on rudics-server-hf:
        system(['mv ' ARGO_SYS_PARAM.rudics_server '/f' num2str(dbdat.maker_id) '/' fn '*.??? ' ...
            ARGO_SYS_PARAM.rudics_server '/f' num2str(dbdat.maker_id) '/backup'])
        
    end
end