%===========================================================================
% LOADS THE DATABASE FOR A GIVEN WMO-ID FROM THE ArgoRT DATABASE 
% Works only if the float is deployed with valid wmo-id
%
% Description:   Loads the given database from the ArgoRT folder found
%                in '//nfstas01-hba/argo/ArgoRT/'
%
% Author:        V. Dirita
%
% Revisions:     01/04/2010:  Created.
% 
% Returns:       dbase.argoMaster    - metafile information
%                dbase.float(1..n)   - array of structures with profile 1..n
%
% Related Files: 
%============================================================================
function dbase = dbaseLoadFromArgoRT(wmoID,float)
%begin
    global FOLDER_HTML  FOLDER_DBASE  FOLDER_CONFIG
    global ARGO_SYS_PARAM
    
    %no input specified:
    dbase = [];
    if (isempty(wmoID))    return; end;
    if (~isnumeric(wmoID)) return; end;

    %change the root path from PC:
    ARGO_SYS_PARAM.root_dir = FOLDER_DBASE; %'//nfstas01-hba/argo/ArgoRT/';

    %load the argoMaster components:
    dbase.argoMaster = getdbase(wmoID);

    %load the matfiles: V.float(j) single element
    dbase.float=getargo(wmoID);
    return;


