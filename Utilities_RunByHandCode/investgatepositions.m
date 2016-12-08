% test_position_accuracy

% first, extrapolate to see what it looks like...

[fpp,dbdat]=getargo(5901156);

for i=1:length(fpp)
    [u,ll,jd]=unique(fpp(i).jday);
    if(~isempty(fpp(i).jday_ascent_end))
        newlat(i)=interp1(fpp(i).jday(ll),fpp(i).lat(ll),fpp(i).jday_ascent_end,'spline');
        newlon(i)=interp1(fpp(i).jday(ll),fpp(i).lon(ll),fpp(i).jday_ascent_end,'spline');
    end
end

clf
for i=1:length(fpp)
    clf
    if (~isnan(newlat(i)))
        [m,n]=size(fpp(i).lat);
        if(m==1)
            plot([newlon(i) fpp(i).lon],[newlat(i) fpp(i).lat])
            hold on
            plot([newlon(i) fpp(i).lon],[newlat(i) fpp(i).lat],'gx')
        else
            plot([newlon(i) fpp(i).lon'],[newlat(i) fpp(i).lat'])
            hold on
            plot([newlon(i) fpp(i).lon'],[newlat(i) fpp(i).lat'],'gx')
        end
        hold on
        plot(newlon(i),newlat(i),'rx')
        pause
    end
end

% test system with existing, known data:

for i=1:length(fpp)
    i=i
    clf
    [u,ll,jd]=unique(fpp(i).jday);
    if(~isempty(fpp(i).jday_ascent_end) & length(ll)>j+2)
        lg=[ll(1:j-1)' ll(j+1:end)'];
        comparisonlat(i)=interp1(fpp(i).jday(lg),fpp(i).lat(lg),fpp(i).jday(j),'spline');
        comparisonlon(i)=interp1(fpp(i).jday(lg),fpp(i).lon(lg),fpp(i).jday(j),'spline');
        difflat(i,j)=comparisonlat(i)-fpp(i).lat(j);
        difflon(i,j)=comparisonlon(i)-fpp(i).lon(j);
        [dist(i,j),dir(i,j)]=sw_dist([fpp(i).lat(ll(j)) difflat(i)],[fpp(i).lon(ll(j)) difflon(i)]);
        
        if (~isnan(newlat(i)))
            [m,n]=size(fpp(i).lat);
            if(m==1)
                plot([newlon(i) fpp(i).lon],[newlat(i) fpp(i).lat])
                hold on
                plot([newlon(i) fpp(i).lon],[newlat(i) fpp(i).lat],'gx')
            else
                plot([newlon(i) fpp(i).lon'],[newlat(i) fpp(i).lat'])
                hold on
                plot([newlon(i) fpp(i).lon'],[newlat(i) fpp(i).lat'],'gx')
            end
            hold on
            plot(newlon(i),newlat(i),'rx')
            plot(comparisonlon(i),comparisonlat(i),'cp')
            plot(fpp(i).lon(j),fpp(i).lat(j),'gp')
            pause
        end
        
    end
end

% Try mean fit of first 3 points only:

for i=1:length(fpp)
    [u,ll,jd]=unique(fpp(i).jday);
    if(size(fpp(i).jday)~=size(fpp(i).lon))
        jf=fpp(i).jday(ll)';
    else
        jf=fpp(i).jday(ll);
    end
    if(~isempty(fpp(i).jday_ascent_end))
        [p,S,mu]=polyfit(jf,fpp(i).lat(ll),1);
        polylat(i)=polyval(p,fpp(i).jday_ascent_end,[],mu);
        [p,S,mu]=polyfit(jf,fpp(i).lon(ll),1);
        polylon(i)=polyval(p,fpp(i).jday_ascent_end,[],mu);        
    end
end

for i=1:length(fpp)
    i=i
    clf
    [u,ll,jd]=unique(fpp(i).jday);
    if(size(fpp(i).jday)~=size(fpp(i).lon))
        jf=fpp(i).jday';
    else
        jf=fpp(i).jday;
    end
    if(~isempty(fpp(i).jday_ascent_end) & length(ll)>j+1)
        lg=[ll(1:j-1)' ll(j+1:end)'];
        [p,S,mu]=polyfit(jf(lg),fpp(i).lat(lg),1);
        comppolylat(i)=polyval(p,fpp(i).jday(j),[],mu);
        [p,S,mu]=polyfit(jf(lg),fpp(i).lon(lg),1);
        comppolylon(i)=polyval(p,fpp(i).jday(j),[],mu);        

%         difflat(i,j)=comparisonlat(i)-fpp(i).lat(j);
%         difflon(i,j)=comparisonlon(i)-fpp(i).lon(j);
%         [dist(i,j),dir(i,j)]=sw_dist([fpp(i).lat(ll(j)) difflat(i)],[fpp(i).lon(ll(j)) difflon(i)]);
        
        if (~isnan(newlat(i)))
            [m,n]=size(fpp(i).lat);
            if(m==1)
                plot([polylon(i) fpp(i).lon],[polylat(i) fpp(i).lat])
                hold on
                plot([polylon(i) fpp(i).lon],[polylat(i) fpp(i).lat],'gx')
            else
                plot([polylon(i) fpp(i).lon'],[polylat(i) fpp(i).lat'])
                hold on
                plot([polylon(i) fpp(i).lon'],[polylat(i) fpp(i).lat'],'gx')
            end
            hold on
            plot(polylon(i),polylat(i),'rx')
            plot(comppolylon(i),comppolylat(i),'cp')
            plot(fpp(i).lon(j),fpp(i).lat(j),'gp')
            pause
        end
        
    end
end





