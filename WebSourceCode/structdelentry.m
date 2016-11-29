%==========================================================
% DELETE ENTRY Index FROM THE ARRAY OF STRUCTURES IN S1
% RETURNED IN S2
%==========================================================
function S2 = structdelentry(S1, Index)
%begin
    %check for input errors:
    S2 =[];
    if (isempty(S1))    return; end;
    if (isempty(Index)) return; end;
    
    %check input index value:
    n = length(S1);
    if ((Index>n) || (Index<=0)) return; end;
    
    %copy to output skipping the structure at Index:
    for j=1:n
        if (j==Index) continue; end;
        disp(S1(j));
        S2 = [S2, S1(j)];
    end

%end