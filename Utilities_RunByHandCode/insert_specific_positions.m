%  function insert_specific_positions(wmo_id,pn,newlat,newlon)
%
%  this script takes a float structure and checks to see if locations from
%  previous profiles are missing. if so, it interpolates from teh current
%  location and previous locations and adds them to the mat structure. It
%  then generates the tesac and netcdf files for the float for delivery to
%  the GDACs and GTS.

 function insert_specific_positions(wmo_id,pn,newlat,newlon)

 global ARGO_SYS_PARAM
 
  pn2=pn;
 [fpp,dbdat]=getargo(wmo_id);
 for j=1:length(fpp)
     if fpp(j).profile_number == pn2
         pn=j;
     end
 end
 
 fpp(pn).lat=newlat;
 if newlon<1
     newlon=360+newlon;
 end
 
 fpp(pn).lon=newlon;
 kk=pn;
 fpp(pn).position_accuracy='8';
 fpp(pn).pos_qc=8;
 
 float = fpp;
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id)]

    save(fnm,'float','-v6');

% now re-generate netcdf files:

    for g=1:length(kk)
        if ~isempty(fpp(kk(g)).jday)
            argoprofile_nc(dbdat,fpp(kk(g)));
            write_tesac(dbdat,fpp(kk(g)));
            web_profile_plot(fpp(kk(g)),dbdat);
        end
    end
    web_float_summary(fpp,dbdat,1);
    locationplots(fpp);
% done!
end

