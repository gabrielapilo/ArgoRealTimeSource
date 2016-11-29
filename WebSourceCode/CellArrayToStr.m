%=================================================================================
% CONVERT A CELL ARRAY TO VERTICALLY CATENATED STRINGS: /EMPTY COLUMNS ARE SKIPPED
% For Example: A=
%
%    'No:'          ' '    ' '    ' '    'Serial'    'Profile'    'Profile'    
%    ' '            ' '    ' '    ' '    'Number'    'Number '    'Length ' 
%    ' '            ' '    ' '    ' '    'CPU   '    ' '          ' '       
%    ' '            ' '    ' '    ' '    ' '         ' '          ' '        
%    ' '            ' '    ' '    ' '    ' '         ' '          ' '         
%    ' '            '-'    '-'    '-'    '------'    '-------'    '-------'  
%    '   1'          []     []     []    ' 862'      ' 17'        ' 52'        
%    '   2'          []     []     []    ' 862'      ' 31'        '255'  
%
% Returns: str=
% Columns are vertically aligned with appropriate number of whitespaces
%==============================================================================
function str = CellArrayToStr(A)
%begin
    %check input:
    str = '';
    if (isempty(A)) return; end;
    [rows, cols] = size(A);
    
    %single cell input/no input:
    if ((rows==0) || (cols==0)) return; end;
    if ((rows==1) || (cols==1)) str = cell2mat(A); return; end;
    
    %columnwise string formatting:
    for col=1:cols
        s   = catvert(A(:,col));
        str = cathoriz(str, s);
    end

%end





%===============================================
%VERTICAL CATENTATION OF COLUMN VECTOR OF CELLS:
%===============================================
function s = catvert(cellvect)
%begin
    n = length(cellvect);
    s = '';
    if (n==0) return; end;
    
    for j=1:n
        s1 = cell2mat(cellvect(j));
        if (isempty(s1)) s1=' '; end;
        s  = strvcat(s, s1);
    end  
%end





%=================================================
%HORIZONTAL CATENATION OF TWO V-STRINGS, SAME ROWS
%=================================================
function s3 = cathoriz(s2,s1)
%begin
    %empty or single input:
    s3 = '';
    if (isempty(s2)) s3=s1; return; end;
    if (isempty(s1)) s3=s2; return; end;
    [rows1,~] = size(s1);
    [rows2,~] = size(s2);
    if (rows1~=rows2) disp('error'); return; end;
    
    for j=1:rows1
        s  = [s2(j,:), ' ', s1(j,:)];
        s3 = strvcat(s3, s);
    end
    

%end











