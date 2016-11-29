%======================================================
%RETURNS TRUE IF THE VECTOR x IS A DATE THUS:
% x = [2010  2  25  6  42  3]  (may have multiple rows)
%      yyyy  mm dd  hh mm ss
%======================================================
function bool = isdate(x)
%begin
    bool = false;
    if (isempty(x)) return; end;
    [nr,nc] = size(x);
    if (nc~=6) return; end;
    x = x(1,:);
    
    %year: month day
    if ((x(1)<1990) || (x(1)>2020)) return; end;
    if ((x(1)   <1) || (x(2)  >12)) return; end;
    if ((x(1)   <1) || (x(3)  >31)) return; end;
    bool = true;
%end

