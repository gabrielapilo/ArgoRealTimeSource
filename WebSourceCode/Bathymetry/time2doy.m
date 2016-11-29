function [doy] = time2doy(time)
% Convert WOA94 time (decimal days since 1900) to day of year.
% function [doy] = time2doy(time)
%
% J Dunn 28/3/96

gtime = gregorian(time+2415020.5);

date0 = [NaN 1 1 0 0 0];
date0 = date0(ones([length(time) 1]),:);
date0(:,1) = gtime(:,1);
day0 = julian(date0);
doy = julian(gtime) - day0;

% Just get doy the same shape as time.
[r c] = size(time);
if r==1; doy = doy'; end
