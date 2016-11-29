%=============================================
%CONVERT LONG DATE STRING TO DATE/TIME
% EX: '20080728233200'
%
% Returns charDateTime: '28/07/2008  Time: 23:32.00'
%=============================================
function charDateTime = LongDateToDateTime(str)
%begin
    %verify input:
    charDateTime = '-';
    if (isempty(str))    return; end;

    %remove whitespaces:
    str = strtrim(str);
    if (isempty(str))    return; end;
    if (length(str)~=14) return; end;
    
    s1 = [str(7:8),  '/', str(5:6),   '/', str(1:4)  ];
    s2 = [str(9:10), ':', str(11:12), ':', str(13:14)];
    charDateTime = [s1, '  Time: ', s2];
%end


