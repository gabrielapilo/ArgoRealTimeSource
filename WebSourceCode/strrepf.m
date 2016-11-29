%========================================================================
%STRING REPLACE FUNCTION, BUT DEALS WITH NULL INPUT STRINGS:
%========================================================================
function str2 = strrepf(str1, oldstr, newstr)
%begin
    str2 = '';
    if (isempty(str1)) return; end;
    if (~ischar(str1)) return; end;
    str2 = strrep(str1, oldstr, newstr);
%end