%  function [latarr,lonarr]=interpolate_locations(dbdat)
%
%  this script takes a float structure and checks to see if locations from
%  previous profiles are missing. if so, it interpolates from teh current
%  location and previous locations and adds them to the mat structure. It
%  then generates the tesac and netcdf files for the float for delivery to
%  the GDACs and GTS.

 function [latarr,lonarr]=interpolate_locations(dbdat)

 global ARGO_SYS_PARAM
 
 latarr=[];
 lonarr=[];
 needpos=[];
 
[fpp]=getargo(dbdat.wmo_id);

j=[];
if isempty(fpp(end).lat)
%     return
end
if length(fpp)>1 & ~isnan(fpp(end).lat(1))
    for i=length(fpp)-1:-1:1
        if isnan(fpp(i).lat)  & ~isempty(fpp(i).wmo_id)
            j=i;
            
            break
        end
    end
elseif isnan(fpp(end).lat(1))
    return
elseif length(fpp)>1 % check for any nans within the processing that have been missed:
    for i=length(fpp)-3:-1:1
        if isnan(fpp(i).lat)
            j=i;
            break
        end
    end
else
    return
end
startlat=[];
if ~isempty(j)
    while j<length(fpp) & (isempty(fpp(j+1).lat) | isnan(fpp(j+1).lat)) 
        j=j+1;
    end
    endlat=fpp(j+1).lat(1);
    endlon=fpp(j+1).lon(1);
    endjday=fpp(j+1).jday(1);
    for k=j-1:-1:1
        if isempty(fpp(k).jday) | isempty(fpp(k).lat) | isempty(fpp(k).wmo_id)
        else
        if(~isnan(fpp(k).lat(1)) | (length(fpp(k).lat)>1 && ~isnan(fpp(k).lat(2))))
            ll=find(~isnan(fpp(k).lat))
            startlat=fpp(k).lat(ll(1));
            startlon=fpp(k).lon(ll(1));
            startjday=fpp(k).jday(ll(1));
            break
        end
        end
    end
    if isempty(startlat)
        startlat=dbdat.launch_lat;
        startlon=dbdat.launch_lon;
        startjday=julian([str2num(dbdat.launchdate(1:4)) str2num(dbdat.launchdate(5:6)) str2num(dbdat.launchdate(7:8)) ...
            str2num(dbdat.launchdate(9:10)) str2num(dbdat.launchdate(11:12)) str2num(dbdat.launchdate(13:14))])
        j=0;
        k=0;
    end
    kk=k+1:max(j,1);

    for g=1:length(kk)
        try
            if isempty(fpp(kk(g)).jday) % & ~isempty(fpp(kk(g)).p_raw)
                fpp(kk(g)).jday=(fpp(kk(g)+1).jday(1)+fpp(kk(g)-1).jday(1))/2;
            end
        end
        if ~isempty(fpp(kk(g)).jday)
            needpos(g)=fpp(kk(g)).jday(1);
        end

    end
else 
    return
end    
if ~isempty(needpos)
    latarr = interp1([startjday endjday],[startlat endlat],needpos);
    lonarr = interp1([startjday endjday],[startlon endlon],needpos);
    
% now regenerate and save mat files:

    for g=1:length(kk)
        fpp(kk(g)).lat = latarr(g);
        fpp(kk(g)).lon = lonarr(g);
        fpp(kk(g)).position_accuracy='8';
        fpp(kk(g)).pos_qc=8;
    end
    float = fpp;
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)]

    save(fnm,'float','-v6');

% now re-generate netcdf files:

    for g=1:length(kk)
        if ~isempty(fpp(kk(g)).jday) & ~isempty(fpp(kk(g)).wmo_id)
            argoprofile_nc(dbdat,fpp(kk(g)));
            write_tesac(dbdat,fpp(kk(g)));
            web_profile_plot(fpp(kk(g)),dbdat);
        end
    end
     web_float_summary(fpp,dbdat,1);
    locationplots(fpp);
% done!
end
return
