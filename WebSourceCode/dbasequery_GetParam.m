%=================================================================
%RETURNS THE FIELD VALUES ASSOCIATED WITH FIELDNAME AS VECTOR:
%  Ex: dbase.float(1).profilepistonpos: 15.2
%
%  fieldname='profilepistonpos'
%  fieldval = [15.2, ...]
%=================================================================
function fieldval = dbasequery_GetParam(dbase, fieldname)
%begin
    %look for specific field name:
    fieldval = [];
    try n = length(dbase.float); catch; return; end;
    if (n==0) return; end;
    if (isfield(dbase.float(1), fieldname)==0) return; end;
        
    
    %get all values into vector
    try
        for j=1:n 
            u = getfield(dbase.float(j), fieldname); 
            if (isempty(u)) continue; end;
            if (isdate(u))    x(j) = {sprintf('%02d/%02d/%04d', u(1,3), u(1,2), u(1,1))}; continue; end;
            if (isnumeric(u)) x(j) = u(1);                                                continue; end;
            if (ischar(u))    x(j) = {u};                                                 continue; end;
        end;     
    catch
        return;
    end
    
    try fieldval = x; catch; fieldval=[]; end;
%end


