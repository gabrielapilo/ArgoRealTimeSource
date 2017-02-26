%  function [latarr,lonarr]=interpolate_locations(dbdat)
%
%  this script takes a float structure and checks to see if locations from
%  previous profiles are missing. if so, it interpolates from teh current
%  location and previous locations and adds them to the mat structure. It
%  then generates the tesac and netcdf files for the float for delivery to
%  the GDACs and GTS.

function [latarr,lonarr]=interpolate_locations(dbdat,pro)

global ARGO_SYS_PARAM

latarr=[];
lonarr=[];
needpos=[];

%if this profile has a nan, we can't interp yet. In the case of
%re-processing, we need to esure we don't re-interp accross already guessed
%values. This will be an issue if we are reprocessing just one file with a
%missing position, without the bracketing files.
if isnan(pro.lat)
    return
end

[fpp]=getargo(dbdat.wmo_id);
%get all the nans in lat:
ii = find(cellfun(@any,cellfun(@isnan,{fpp.lat},'uniformoutput',0))==1);
ij = find(cellfun(@isempty,{fpp.lat}));
ii = sort([ii,ij]);
if isempty(ii)
    %no missing position info
    return
end

%look for different groups of missing postions:
iid = diff(ii);
if any(iid>1)
    %more than one group, shouldn't happen in RT, but flag if it does!
    logerr(4,'interpolate_locations found more than one set of missing positions. NEED TO INVESTIGATE!!')
    return
end

if ii(1) == 1
    %can't interpolate as the first position is missing. So use launch
    %lat/lon
    startlat=dbdat.launch_lat;
    startlon=dbdat.launch_lon;
    startjday=julian([str2num(dbdat.launchdate(1:4)) str2num(dbdat.launchdate(5:6)) str2num(dbdat.launchdate(7:8)) ...
        str2num(dbdat.launchdate(9:10)) str2num(dbdat.launchdate(11:12)) str2num(dbdat.launchdate(13:14))])
else
    %use last postion fix
    startlat=fpp(ii(1)-1).lat(end);
    startlon=fpp(ii(1)-1).lon(end);
    startjday = fpp(ii(1)-1).jday_location(end);
end
%use first postion fix of this profile
endlat = fpp(ii(end)+1).lat(1);
endlon = fpp(ii(end)+1).lon(1);
endjday = fpp(ii(end)+1).jday_location(1);

%now need to calculate the approximate jdays for missing profiles
xq = 1:length(ii)+2;
vql = interp1([xq(1),xq(end)],[startjday,endjday],xq);
needpos = vql(2:end-1);
    
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
        fpp(ii(g)).jday = needpos(g);
        fpp(ii(g)).lat = latarr(g);
        fpp(ii(g)).lon = lonarr(g);
        fpp(ii(g)).position_accuracy='8';
        fpp(ii(g)).pos_qc=8;
    end
    float = fpp;
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)]

    save(fnm,'float','-v6');

% now re-generate netcdf files:

    for g=1:length(ii)
        if ~isempty(fpp(ii(g)).jday) & ~isempty(fpp(ii(g)).wmo_id)
            argoprofile_nc(dbdat,fpp(ii(g)));
            write_tesac(dbdat,fpp(ii(g)));
            web_profile_plot(fpp(ii(g)),dbdat);
        end
    end
     web_float_summary(fpp,dbdat,1);
    locationplots(fpp);
% done!
end
return
