%==========================================================================
% TRUNCATE A LONG STRING AND RETURN THE LAST n characters, USEFUL FOR
% DISPLAYING LONG FILENAMES:
% Inputs:
%    strin = cell or string array: 
%            ex: {'hello', 'There'} or strvcat('hello', 'there')
%
%    strout = cell or string array: ex if lastn=3 then:
%             ex: {'...llo', '...ere'} or strvcat('...llo', '...ere')
%
%             the string sequence ... is added to emphasize the truncation 
%==========================================================================
function strout = strtrunc(strin, lastn)
%begin
    %input errors:
    strout = strin;
    if (isempty(strin)) return; end;
    if (lastn<=0)       return; end;
    
    %check for cell or strin array:
    
    if (iscell(strin))
        %cell array input: return cell array out
        n = length(strin);
        for j=1:n
            s1        = cell2mat(strin(j));
            m         = length(s1);
            strout(j) = strin(j);
            if (m>lastn) strout(j)={['...', s1(m-lastn+1:m)]}; end;
        end
    else
        %vertically cat string array input, return string output
        [rows,cols]=size(strin);
        strout     ='';
        for j=1:rows
            s1 = strtrim(strin(j,:));
            m  = length(s1);
            if (m>lastn) 
                strout=strvcat(strout, ['...', s1(m-lastn+1:m)]); 
            else
                strout=strvcat(strout, s1); 
            end;
        end
    end
    
    
    

%end
