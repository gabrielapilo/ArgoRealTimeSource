%====================================================================
%RETURNS ALL HULL IDs OF FLOATS / DEPLOYED ONLY IE WITH WMO ID
%====================================================================
function AllHullIDs = dbaseGetAllHullIDs()
    
global ARGO_ID_CROSSREF
    
%begin
    %LOAD DATABASE SUMMARY INTO MEMORY TO GET ALL HULL IDs:
    AllHullIDs = [];

    if isempty(ARGO_ID_CROSSREF)
        getdbase(-1);
    end
   
%    load('Setup.mat');
%     try n=length(ARGO_ID_CROSSREF); catch; return; end;
    
%     for i=1:n 
        AllHullIDs = ARGO_ID_CROSSREF(:,5); 
%     end;

    AllHullIDs = sort (AllHullIDs);
%end
