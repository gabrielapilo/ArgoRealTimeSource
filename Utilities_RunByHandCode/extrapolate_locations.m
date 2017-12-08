%  function [latarr,lonarr]=extrapolate_locations(dbdat)
%
%  this script takes a float structure and fills forward looking missing 
%  positions by extrapolation. if the latest positions are missing, 
%  it extrapolates from the current
%  location and previous locations and adds them to the mat structure. It
%  then generates the tesac and netcdf files for the float for delivery to
%  the GDACs and GTS.

 function [latarr,lonarr]=extrapolate_locations(dbdat)

 global ARGO_SYS_PARAM
 
 latarr=[];
 lonarr=[];
 needpos=[];
 startlat=[];
 startlon=[];
 startjday=[];
 endjday=[];

 kk=0;
 l=0;
 
[fpp]=getargo(dbdat.wmo_id);

j=[];

if length(fpp)>1 
    for i=length(fpp)-1:-1:1
        if ~isnan(fpp(i).lat)
            j=i;
            break
        end
    end
end

%  since by definition we are extrapolating latest locations, this is not needed


for jj=j-10:j
    l=l+1;
    if ~isempty(fpp(jj).jday)
        startjday(l)=fpp(jj).jday(1);
        startlat(l)=fpp(jj).lat(1);
        startlon(l)=fpp(jj).lon(1);
    else
        startjday(l)=NaN;
        startlat(l)=NaN;
        startlon(l)=NaN;
    end        
end


for jj=j+1:length(fpp)
    kk=kk+1
    needpos(kk)=jj;
    endjday(kk)=fpp(jj).jday(1);
    %         endlat(kk)=fpp(jj).lat(1);
    %         endlon(kk)=fpp(jj).lon(1);
end

ig = ~isnan(startjday);

latarr=interp1([startjday(ig)],[startlat(ig)],[endjday],[],'extrap')
lonarr=interp1([startjday(ig)],[startlon(ig)],[endjday],[],'extrap')
    
    
% now regenerate and save mat files:

    for g=1:length(needpos)
        fpp(needpos(g)).lat = latarr(g);
        fpp(needpos(g)).lon = lonarr(g);
        fpp(needpos(g)).position_accuracy='8';
        fpp(needpos(g)).pos_qc=8;
    end
    float = fpp;
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)]

    save(fnm,'float','-v6');

% now re-generate netcdf files:

    for g=1:length(needpos)
        if ~isempty(fpp(needpos(g)).jday)
            argoprofile_nc(dbdat,fpp(needpos(g)));
            write_tesac(dbdat,fpp(needpos(g)));
            web_profile_plot(fpp(needpos(g)),dbdat);
        end
    end
    web_float_summary(fpp,dbdat,1);
    locationplots(fpp);
% done!
end

