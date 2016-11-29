%==============================================================================
% SAVE MULTILINE STRING INTO TEXT FILE, OVERWRITES THE FILE
% mode = 'wt' to create a new file, 'at' append to existing file.
%==============================================================================
function bool = SaveTextFile(filename, str, mode)
%begin
    %return false by default:
    bool = false;
    
    %open the file stream:
    try
       fid = fopen(filename, mode);
       if (fid == -1) fprintf('Error: Unable to Open File %s \n', filename);  return; end;
    catch
        fprintf('Error: Unable to Open File %s \n', filename);
        return;
    end
    
    %write multiple lines of text:
    bool      = true;
    [nrows,m] = size(str);
    if (nrows==0) fclose(fid); return; end;
    
    %write line by line with newline character:
    for j=1:nrows
        line = deblank(str(j,:));
        fprintf(fid, '%s \n', line);
    end;
    
    fclose(fid);
    %fprintf(' \n');
    return;
%end