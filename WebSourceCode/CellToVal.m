%========================================================================================
% CONVERTS CELL VALUE TO NUMERIC, 
% HANDLES EXCEPTIONS SUCH AS NaN, EMPTY FIELDS, RETURNS CELL STRINGS AS CHARACTER STRINGS
%========================================================================================
function x = CellToVal(c)
%begin
    x = [];
    if (isempty(c)) return; end;
    
    try
        %convert to either character or number:
        x = cell2mat(c);
    catch
        x = NaN;
        return;
    end

%end


