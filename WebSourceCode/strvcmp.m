%======================================================================
% ATTEMPT TO MATCH STRING str in LIST strlst CREATED AS A
% VERTICAL CATENATED STRING.
%
%ex:  strlst = 'hello'
%              'there'
%
%     str = 'there'
%     returns row=2
%  SAME AS strcmp but vertical list comparison, returns first one found
%======================================================================
function row = strvcmp(strlst, str)
%begin
    row = [];
    if (isempty(strlst)) return; end;
    if (isempty(str))    return; end;
    [rows,cols]=size(strlst);
    
    for r=1:rows
        if (strfind(strlst(r,:),str)) row=r; break; end;
    end
    
%end