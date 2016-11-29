%==========================================================
%  ATTEMPT TO FIND STRING str IN THE POPUP MENU OBJECT:
%  For example: if menuobj = 'Temperature'
%                            'Salinity'
%                            'Pressure'
%                  str = 'Salinity' or 'Sal' (ie keyword)
%  RETURNS Index=2
%==========================================================
function Index = strfindpopupmenu(menuobj, str)
%begin
    Index = 1;
    
    try
        menuentries = get(menuobj, 'String');
    catch
        disp('strfindpopupmenu()::  ERROR popup menu object not found');
        return;
    end
    
    %scan each entry and match to str:
    [rows,cols]=size(menuentries);
    for j=1:rows
        s = menuentries(j,:);
        k = strfind(s, str);
        if (length(k)==1) Index=j; return; end;
    end

%end