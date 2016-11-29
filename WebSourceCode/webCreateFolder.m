%===============================================================================
% DELETES AN EXISTING FOLDER AND CONTENTS, THEN RE-CREATES A NEW FOLDER WITH SAME
% NAME. IF FOLDER DOES NOT EXIST, IT SIMPLY CREATES ONE.
%
% Inputs
%      folder = 
%===============================================================================
function  bool = webCreateFolder(folder)  %superceded and eliminated
%begin
    %HULL ID REQUIRED FOR FOLDER NAME:
    bool = true;
      
    %CHECK IF FOLDER ALREADY EXISTS:
    if (exist(folder, 'dir')==7) return; end;

    %IF NOT THEN CREATE IT:
    try
        mkdir(folder);
    catch
        fprintf('  ERROR: Unable to create new folder: %s \n', folder);
        bool = false;
        return;
    end
    
    bool = true;
%end