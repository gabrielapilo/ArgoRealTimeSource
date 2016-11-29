%==========================================================
%REMOVES THE PATH FROM FILENAME
%==========================================================
function filename = stripfilepath(fullfilename)
%begin
    %check input
    filename = '';
    if (isempty(fullfilename)) return; end;
    [path,name,ext,versn] = fileparts(fullfilename);
    filename = [name, ext];
%end