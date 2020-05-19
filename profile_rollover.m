% Profile_rollover test:  test whether the profile has done more than 255
% profiles or if the profile number is otherwise unreasonable before
% accidently overwriting earlier profileswith a dodgy cycle number
%
% INPUT: dbdat - master database record for this float
%        fp    - new profile after decoded
%        float - the float structure from the mat file
%
% Author:  Ann Thresher CSIRO  Nov 2008
% 
% CALLS:  netCDF toolbox,  (loadfield - in this file)
%
% USAGE: [np] = profile_rollover(fp,float)

function [np] = profile_rollover(fp,float,dbdat)

old_np=length(float);
np=fp.profile_number;

j1950 = julian([1950 1 1 0 0 0]);

jul0 = julian(0,1,0);


% First - make sure you have profile 1 since the rollover depends on this location:

if(isempty(float(1).jday))
    startjday=julian([str2num(dbdat.launchdate(1:4)) str2num(dbdat.launchdate(5:6)) str2num(dbdat.launchdate(7:8)) ...
        str2num(dbdat.launchdate(9:10)) str2num(dbdat.launchdate(11:12)) str2num(dbdat.launchdate(13:14))])
    finalprof=float(end).profile_number+1;
else
    startjday=float(1).jday(1);
    finalprof=float(end).profile_number;
end

ilast = length(float);
% make sure we don't have an empty jday in the last profile
if isempty(float(end).jday)
    %find the next filled one
    for a = ilast:-1:np+1
        if ~isempty(float(a).jday)
            finalprof = float(a).profile_number;
            ilast = a;
            break
        end
    end
end
% then, look for missing profiles or profiles with unreasonable numbers:

%if (np > old_np + 2 & ~isempty(fp.jday))  % be generous
if (np < old_np) & ~isempty(float(ilast).jday)
    est_prof_interval=abs(float(ilast).jday(1)-startjday)/finalprof;
    new_prof_interval=abs(fp.jday(1)-startjday)/max(1,np-1);
    if new_prof_interval==0;return;end  %this is a true first profile 
    if(isapprox(new_prof_interval,est_prof_interval,2))
        %profile number is consistent with interval between profiles
        return
    else
        %could be problem profile number -
        logerr(3,['Odd profile number: ' num2str(np) ' ' datestr((float(ilast).jday(1))-jul0)]);
        % and could be rollover
    end
%     return % finished because np is greater than old np so not rollover...
elseif (np < old_np) & isempty(float(ilast).jday) % older profile has no data information
    logerr(3,['Assumed that profile number ' num2str(np) ' is correct, no information from oldest profile']);
    return % assume profile number is consistent, wait for more information next time float surfaces
elseif(np >= old_np)
    return
end

% now rollover possibilities:
prof_num=[];
float_date=[];

for i=1:length(float)
    if(~isempty(float(i)) & ~ isempty(float(i).jday))
        prof_num(i)=float(i).profile_number;
        float_date(i)=float(i).jday(1);
    end
end

prof_num(i+1)=np;
float_date(i+1)=fp.jday(1);

[sort_day,ind]=sort(float_date);
sort_pn=prof_num(ind);
tt=diff(sort_pn);

kk=find(tt<0);
if(~isempty(kk))  % shouldn't happen unless there's a problem profile
    % number in the latest profile since all other profiles
    % should be in order... and length(kk) should be 1
    % unless previous processing has gone wrong...

    if(tt(kk) < -512)
        np=np+512;
        return
    elseif(tt(kk) >=-511 & tt(kk) < -20 )   % & kk == old_np)  % almost certainly rollover - could
        % use est_prof_interval here to double
        % check it makes sense?
        np=np+256;
        return
    else
        logerr(3,['possible error in profile numbers: old=' num2str(old_np) ' new=' num2str(np)]);
    end

end

return
