%calc_argo_expiry
% this script is meant to look at flaots and eliminate all older than 8
% years to calculate a percentage fleet for any given time period.

% load ('/home/argo/ArgoDM/cron_jobs/gdac_mirror/argo_descr.mat'):
% kk=find(lat>=-90 & lat<=0 & lon>=90 & lon<=180);
numlive15=0;
numlive16=0;
numlive17=0;
numlivenow=0;

wmoid=unique(wmo_id(kk));
nn=str2num(datestr(now,'yyyy'));

for i=1:length(wmoid)
    ll=find(wmo_id==wmoid(i));
    yy=str2num(datestr(min(serial_date(ll)),'yyyy'));
    yyn=str2num(datestr(max(serial_date(ll)),'yyyy'));
    if yy>=nn-8 & nn-yyn<1 %number still going in 2015-6
        numlive15=numlive15+1;
    end
    if yy>=nn-7  & nn-yyn<1 % number still going 2016-7
        numlive16=numlive16+1;
    end
    if yy>nn-6  & nn-yyn<1  %number still going in 2017-8
        numlive17=numlive17+1;
    end
    yyn=str2num(datestr(max(serial_date(ll)),'yyyy'));
    if nn-yyn<1
        numlivenow=numlivenow+1;
    end
end

