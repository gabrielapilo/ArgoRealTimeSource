% remove empty data - eliminates zero data from iridium decoded data
%
%usage: pro=remove_emptydata(pro,yy)
% where yy is an index of the 'rows' to be removed from the structure 'pro'
%
% this script checks every field of the pro structure for equal length to
% the original pressure field, then removes the matching '0' fields and
% returns pro to the originating script.
%
% coded AT - August 2018 to handle Seabird floats but works for all
%

function p2=remove_emptydata(pro,yy)

namesfl=fieldnames(pro);
nn=length(pro.p_raw) ; %  the length we are looking for to decide what needs 
% to be removed

for i=1:length(namesfl)
    s=['ln=length(pro.' namesfl{i} ');'];
    eval(s);
    if ln==nn
        s2=['pro.' namesfl{i} '(yy)=[];'];
        eval(s2);
    end
end

p2=pro;

return
