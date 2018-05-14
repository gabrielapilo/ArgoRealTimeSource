% rerun_grey_listed
% program to rerun a grey listed float either after grey listing or after
% removal from the grey list.
%
%  this requires the dbdat structure as well as the starting and
%  ending profile numbers. It then goes and generates the right argos
%  download to use and reprocesses all intervening profiles.
%
% if 'retrieve is set to 1, then profiles are restored to quality 1.
%
% usage: rerun_grey_listed(dbdat,startprof,endprof,[retrieve])

function rerun_grey_listed(wmo_id, startprof,endprof,retrieve)

if nargin<=3
    retrieve=-1;
end
[fpp,dbdat]=getargo(wmo_id);

for j=startprof:endprof
    if ~isempty(fpp(j))
%         rejectpoints(dbdat.wmo_id,j,{'s' 't' 'p'},0,2500,retrieve)
         rejectpoints(dbdat.wmo_id,j,{'s' 't' 'p' },-2000,2500,retrieve)
    end
end
