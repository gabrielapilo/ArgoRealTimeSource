%================================================
% CONVERT 16 BIT TO SIGNED INTEGERS
%================================================
function y = signed16(x)
%begin
    y=[];
    if (x>=32768) y=x-65536; end;
end

