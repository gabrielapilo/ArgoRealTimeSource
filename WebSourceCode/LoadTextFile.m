%===========================================================
% LOADS A GIVEN TEXT FILE, RETURNS AS A VERTICALLY CATENATED
% LINES OF STRINGS
%===========================================================
function [str] = LoadTextFile(filename)
%begin
    %check that a filename is supplied:
    str = '';
    if (isempty(filename)) return; end;
 
    %attempt to open the file
    try
        fid = fopen(filename, 'rt');
        if (fid == -1) disp('LoadTextFile():: Unable to open text file for writing'); disp(filename); return; end;
    catch
        disp('LoadTextFile():: Invalid Filename, check the destination filename')
        disp(filename);
        return;
    end
    
    %load the file each line:
    while (~feof(fid))
        s   = fgets(fid);
        if (feof(fid)) break; end;
        str = strvcat(str, s);
    end
    
    %close the file
    fclose(fid);
%end