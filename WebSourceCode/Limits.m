%==========================================================
%hard limits on input x
%==========================================================
function y = Limits(x, lower, upper)
%begin
     y = [];
     if (isempty(x)) return; end;
     y = x;
     if (x<lower) y=lower; return; end;
     if (x>upper) y=upper; return; end;
%end