%  function [latarr,lonarr]=interpolate_locations(dbdat)
%
%  this script takes a float structure and checks to see if locations from
%  previous profiles are missing. if so, it interpolates from teh current
%  location and previous locations and adds them to the mat structure. It
%  then generates the tesac and netcdf files for the float for delivery to
%  the GDACs and GTS.

function [float,pro,gn]=interpolate_locations(dbdat,float,pro)

global ARGO_SYS_PARAM

latarr=[];
lonarr=[];
needpos=[];

%assign all the data so far:
float(pro.profile_number) = pro;

%get all the nans in lat:
ii = find(cellfun(@any,cellfun(@isnan,{float.lat},'uniformoutput',0))==1);
ij = find(cellfun(@isempty,{float.lat}));
ik = sort([ii,ij]);
if isempty(ik)
    %no missing position info
    gn = 0;
    return
end

%clear out existing interpolations and re-do.
%first find non-reports and assign a temporary zero so all the following
%indexing works
im = find(cellfun(@any,cellfun(@isempty,{float.pos_qc},'Uniformoutput',0))==1);
if ~isempty(im)
    for g = 1:length(im)
        float(im(g)).pos_qc = 7;
    end
end
ipos = find(cellfun(@(x) x==0,{float.pos_qc},'Uniformoutput',1)==1);
ii = find(cellfun(@(x) x==8,{float.pos_qc},'Uniformoutput',1)==1);
ij = find(cellfun(@(x) x==9,{float.pos_qc},'Uniformoutput',1)==1);
ik = sort([ii ij]);
%keep the original values. If they are the same as the new ones, don't
%regenerate the netcdf files.
fpp = float;

for g = 1:length(ik)
    float(ik(g)).lat = NaN;
    float(ik(g)).lon = NaN;
    float(ik(g)).pos_qc = 9;
    float(ik(g)).position_accuracy=' ';
end
%look for different groups of missing postions:
iid = find(diff(ik)>1);
if isempty(iid)
    iid = length(ik);
else
    %more than one group
    iid = [iid,length(ik)];
end

st = 1;gn = [];gennc=[];
for a = 1:length(iid)
    ii = ik(st:iid(a));
    if ii(1) == 1
        %can't interpolate as the first position is missing. So use launch
        %lat/lon
        startlat=dbdat.launch_lat;
        startlon=dbdat.launch_lon;
        startjday=julian([str2num(dbdat.launchdate(1:4)) str2num(dbdat.launchdate(5:6)) str2num(dbdat.launchdate(7:8)) ...
            str2num(dbdat.launchdate(9:10)) str2num(dbdat.launchdate(11:12)) str2num(dbdat.launchdate(13:14))])
    else
        %use last postion fix
        ip = find(ii(1) - ipos > 0);
        %if there is no fix before this one, we need to abort here
        if isempty(ip)
            return
        end
        [~,ilast] = min(ii(1) - ipos(ip));
        first = ipos(ip(ilast));
        startlat=float(first).lat(end);
        startlon=float(first).lon(end);
        startjday = float(first).jday_location(end);
    end
    %use next postion fix
    ip = find(ii(1) - ipos < 0);
    %if there is no fix after this one, we need to abort here
    if isempty(ip)
        return
    end
    [~,ilast] = min(ipos(ip) - ii(end));
    last = ipos(ip(ilast));
    endlat = float(last).lat(1);
    endlon = float(last).lon(1);
    endjday = float(last).jday_location(1);
    
    %now need to calculate the approximate jdays for missing profiles, only
    %if the date is missing. For iridium floats, the date should be there.
    iempty = find(cellfun(@(x) isempty(x),{float(ii).jday},'Uniformoutput',1)==1);
    if ~isempty(iempty)
        float(ii(iempty)).jday = NaN;
    end
    needpos = [float(ii).jday];
    if any(isnan(needpos))
        %interpolate over missing date/times
        xq = ii(find(isnan(needpos)));
        vql = interp1([first,last],[startjday,endjday],xq);
        needpos(xq) = vql;
    end
    if ~isempty(needpos)
        %check for longitude that has gone over the 360 degrees:
        %first unwrap the longitude
        lld = abs(startlon-endlon);
        ld = abs(360-endlon+startlon);
        [~,jj] = min([lld, ld]);%smallest distance
        if jj == 2 % the float passed over the 360 degrees line
            if startlon < endlon %end longitude is bigger
                ll = endlon-360;
                lonarr = interp1([startjday endjday],[startlon ll],needpos);
                ij = lonarr < 0;
                lonarr(ij) = 360+lonarr(ij);
            else
                ll = startlon-360;
                lonarr = interp1([startjday endjday],[ll endlon],needpos);
                ij = lonarr < 0;
                lonarr(ij) = 360+lonarr(ij);
                
            end
        else
            %no cross over
            lonarr = interp1([startjday endjday],[startlon endlon],needpos);
        end
        latarr = interp1([startjday endjday],[startlat endlat],needpos);
        % now regenerate and save mat files:
        
        for g=1:length(ii)
            float(ii(g)).jday = needpos(g);
            float(ii(g)).lat = str2num(sprintf(('%5.3f'),latarr(g)));
            float(ii(g)).lon = str2num(sprintf(('%5.3f'),lonarr(g)));
            float(ii(g)).position_accuracy='8';
            float(ii(g)).pos_qc=8;
            %check for same values as already calculated:
            if float(ii(g)).jday == fpp(ii(g)).jday & abs(float(ii(g)).lat - fpp(ii(g)).lat) < 0.005 ...
                    & abs(float(ii(g)).lon - fpp(ii(g)).lon) < 0.005
            else
                gennc(g) = ii(g);
            end
        end
        % done!
    end
    st = iid(a)+1;
    gn = [gn,gennc];
end
%return pos_qc to missing for missing profiles
if ~isempty(im)
    for g = 1:length(im)
        float(im(g)).pos_qc = [];
    end
end

fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
save(fnm,'float','-v6');

%now assign the interpolated values back to pro.
pro = float(pro.profile_number);

return
