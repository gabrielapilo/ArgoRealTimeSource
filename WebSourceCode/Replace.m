%======================================================================
%LOOKS FOR THE CHARACTER STRING oldstr IN MULTILINE STRING ARRAY strin
%AND REPLACES SINGLE OCCURENCE WITH newstr
%BOTH INPUT AND OUTPUT STRING ARRAYS ARE VERTICALLY CATENATED STRINGS.
%
% For example: strin  = strvcat('Hello there', 'this is line 2');
%              oldstr = 'this'
%              newstr = 'HAT'
%              strout = strvcat('Hello there', 'HAT is line 2');
% Note that newstr can be empty, thus removing all occurences of oldstr
%======================================================================
function strout = Replace(strin, oldstr, newstr)
%begin

    %check for input errors:
    strout = strin;
    if (isempty(strin))  return; end;
    if (isempty(oldstr)) return; end;
    
    %input string must be single line, some errors found in netcdf files uk
    if (size(newstr,1)>1) newstr=newstr(1,:); end;
    
    %search for first occurence:
    [nrows,ncols] = size(strin);
    Index = strvcmp(strin, oldstr);
    if (isempty(Index)) return; end;
    
    %replace the line with the keyword to replace:
    if (isempty(newstr)) newstr='&nbsp;'; end;
    s1     = strin(Index,:);
    s1     = strrep(s1, oldstr, newstr);
    strout = strvcat(strin(1:Index-1,:), s1, strin(Index+1:nrows,:));
    
%end