%========================================================================
% BREAK UP A STRING INTO MULTIPLE LINE USING WHITESPACE SEPARATOR, MULTIPLE
% WHITESPACES ARE TREATED AS A SINGLE WHITESPACE
% Ex:
%    "hello there   this"  -> "hello"
%                             "there"
%                             "this"
%========================================================================
function str2 = strbreak(str1)
%begin
    %initialize:
    str2 = '';
    str1 = strtrim(str1);
    if (isempty(str1)) return; end;
    
    %reads max of 15 components:
    [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15] = strread(str1, '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', 'delimiter', ' ');

    if (~isempty(s1))  str2=strvcat(str2,cell2mat(s1));  end;
    if (~isempty(s2))  str2=strvcat(str2,cell2mat(s2));  end;
    if (~isempty(s3))  str2=strvcat(str2,cell2mat(s3));  end;
    if (~isempty(s4))  str2=strvcat(str2,cell2mat(s4));  end;
    if (~isempty(s5))  str2=strvcat(str2,cell2mat(s5));  end;
    if (~isempty(s6))  str2=strvcat(str2,cell2mat(s6));  end;
    if (~isempty(s7))  str2=strvcat(str2,cell2mat(s7));  end;
    if (~isempty(s8))  str2=strvcat(str2,cell2mat(s8));  end;
    if (~isempty(s9))  str2=strvcat(str2,cell2mat(s9));  end;
    if (~isempty(s10)) str2=strvcat(str2,cell2mat(s10)); end;
    if (~isempty(s11)) str2=strvcat(str2,cell2mat(s11)); end;
    if (~isempty(s12)) str2=strvcat(str2,cell2mat(s12)); end;
    if (~isempty(s13)) str2=strvcat(str2,cell2mat(s13)); end;
    if (~isempty(s14)) str2=strvcat(str2,cell2mat(s14)); end;
    if (~isempty(s15)) str2=strvcat(str2,cell2mat(s15)); end;
    
%end