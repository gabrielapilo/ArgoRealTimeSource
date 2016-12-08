% rerun_grey_listed
% program to rerun a grey listed float either after grey listing or after
% removal from the grey list.
%
%  this requires the dbdat structure as well as the starting and
%  ending profile numbers. It then goes and generates the right argos
%  download to use and reprocesses all intervening profiles.
%
% usage: rerun_grey_listed(dbdat,startprof,endprof)

function retrieve_grey_listed(dbdat,startprof,endprof)

[fpp,dbdat]=getargo(dbdat.wmo_id);

for j=startprof:endprof
    if ~isempty(fpp(j))
        rejectpoints(dbdat.wmo_id,j,{'s' 't' 'p'},0,2500,1)
%         rejectpoints(dbdat.wmo_id,j,{'s' },0,2500,1)
    end
end
