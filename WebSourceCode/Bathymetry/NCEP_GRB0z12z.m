% NCEP_GRB0z12z: Extract time,lat,lon cube from NCEP GRIB-format 
% global-coverage year-files and write to Net-CDF file.
%
%    version 1 David Griffin Feb 1998  - for the 10m winds at 0z & 12Z
%    version 2 DG Feb 98  - also surface pressure
%    version 3 Scott Condie Sept 98 - make pressure at mean sea level 
%                                   - make compatible with MECO (ie lat,lon 2d)
%    version 4 DG Feb 99  - re-enable surface pressure as dop==2
%    version 5 DG Aug 01  - add pmean
%
%%   Usage example:
%area=[105 160 -45 -5];
%%   lonmin max latmin max
%date1=[1987 1 1 0 0 0];
%daten=[1996 12 31 0 0 0];
%%     year mo da h m s UTC
%
%
%%assumes the grib files off the CDs are in
%%dirGRB/at00z12z/, with the year added to the name of each file, eg
% cp /CDROM/data/at00z12z/ugrd.10m 1996ugrd.10m
%
%
%refyear = 1970;
%% the time vector output to the .nc file will be days from the beginning
%% of refyear.
% dou=1; dop=0;
%% means extract u,v, and not surface pressure
%areaname='Australia';
%% appears in title of file
%
%NCEP_GRB0z12z(area,date1,daten,dirGRB,dir_out,file_out,refyear,dou,dop,areaname,nctype)

function NCEP_GRB0z12z(area,date1,daten,dirGRB,dir_out,file_out,refyear,dou,dop,areaname,nctype)

dir_in=[dirGRB 'at00z12z/'];
time_interval = 0.5;

if (~dou & ~dop), error('Seems a little pointless: dou=0 & dop=0'), end

if (nargin<12)
  nctype='short';
end

nrecs=(julian(daten)-julian(date1))/time_interval + 1;
rectime = (0:nrecs-1)*time_interval; 
jrectime = rectime + julian(date1); 
grectime = gregorian(jrectime);
time_ref = [refyear 1 1 0 0 0];
rectimeout = jrectime - julian(time_ref);
time_ref_str = [num2str(refyear) '-01-01 0:0:0.0'];
fill=-32767;
miss=-32766;
wscfact=.01;
pscfact=1;
pado=100000;

% open netcdf file
f=netcdf([dir_out file_out],'clobber');
% define global attributes
f.title=['NCEP/NCAR Global Atmospheric Re-analyses v4/97 - ' areaname]
f.reference='Bulletin of the American Meteorological Society, vol 77, no 3, 1996';
f.conventions='COARDS';
if dou | dop==2
  f.history='Extraction from annual, global GRB files using NCEP_GRB0z12z.m - David Griffin, CSIRO';
end
if dop==1
  f.history='Extraction from annual, global GRB files using NCEP_GRB0z12z.m - David Griffin CSIRO. Pressure at mean sea level calculated from heights of the 500hPa and 1000hPa isobars using the same formula as the Reanalysis: P_msl = 10^5*exp(hgt1000/(1.5422885*(hgt500-hgt1000))) - '
end

yearpos=0;

for irec=1:nrecs
  year = grectime(irec,1);
  if year~=yearpos
%             at the start of processing each year, define the filenames
%             and read the grib file structure:
     if dou
       grfile=[dir_in,num2str(year),'ugrd.10m'];
       grfilev=[dir_in,num2str(year),'vgrd.10m'];
       posv=get_pos_ncep(grfilev);
     elseif dop==1
       grfile=[dir_in,num2str(year),'hgt.prs'];
     elseif dop==2
       grfile=[dir_in,num2str(year),'pres.sfc'];
     end
     pos=get_pos_ncep(grfile);
     yearpos=year;
  end
  i = (jrectime(irec) - julian([year 1 1 0 0 0]))/time_interval + 1;
  tic; 
  if irec==1
    if dou
      [u,info,lon,lat] = get_ncep(grfile, pos(i),[],1);
      [v,info,lon,lat] = get_ncep(grfilev, posv(i),[],1);
    end 
    if dop==1
      i = 6 * (i-1) + 1 
      [hgt1000,info,lon,lat] = get_ncep(grfile, pos(i),[],1);
      [hgt500,info,lon,lat] = get_ncep(grfile, pos(i+3),[],1);
    end 
    if dop==2
      [pressure,info,lon,lat] = get_ncep(grfile, pos(i),[],1);
    end
    eltr = toc; 
%   assume the grid is constant, find lat and lon limits:
    lon=lon';
    lonsout=find(lon>=area(1) & lon<=area(2));
    lonsout=flipdim(lonsout,1);
    latsout=find(lat>=area(3) & lat<=area(4));
    latsout=flipdim(latsout,1);
%             ^NB so lat increases with j  
    nlonsout=length(lonsout); nlons=length(lon);
    nlatsout=length(latsout); nlats=length(lat);
    lonout=lon(lonsout);
    latout=lat(latsout);
    [latgrid longrid] = meshgrid(latout,lonout);

%        write .nc file header
%   define dimensions
    f('lon')=nlonsout;
    f('lat')=nlatsout;
    f('time')=0;
%   define coordinate variables
    f{'time'}=ncdouble('time');
    f{'lat'}=ncfloat('lat','lon');
    f{'lon'}=ncfloat('lat','lon');

%   define data variables
    if dou
      if (strcmp(nctype,'short'))
        f{'u'}=ncshort('time','lat','lon');
        f{'v'}=ncshort('time','lat','lon');
      elseif (strcmp(nctype,'float'))
        f{'u'}=ncfloat('time','lat','lon');
        f{'v'}=ncfloat('time','lat','lon');
      else
        error('requested nctype not supported')
      end
    end
    if dop
      if (strcmp(nctype,'short'))
        f{'pressure'}=ncshort('time','lat','lon');
      elseif (strcmp(nctype,'float'))
        f{'pressure'}=ncfloat('time','lat','lon');
      end
      f{'pmean'}=ncfloat('lat','lon');
    end

%   define coordinate attributes
    f{'time'}.coordinate_type='time';
    if strcmp(info.production_info,'6hr fcst:')
      tzstr = ' -6.00'
    elseif strcmp(info.production_info,'0hr fcst:')
      tzstr = ' 0.00'
    else
      error(['unrecognized info.production_info: ', info.production_info])
    end
    f{'time'}.units=['days since ' time_ref_str tzstr];
    f{'time'}.sampling='regular';
    f{'time'}.minimum= num2str(rectimeout(1));
    f{'time'}.maximum= num2str(rectimeout(nrecs));
    f{'time'}.interval= num2str(time_interval);
    f{'time'}.first_date= [num2str(grectime(1,:)) tzstr];
    f{'time'}.last_date= [num2str(grectime(nrecs,:)) tzstr];
    f{'time'}.subcell= 'point';

    f{'lat'}.coordinate_type='latitude';
    f{'lat'}.units='degrees_north';
    if dop==1
      f{'lat'}.grid='regular';
    else
      f{'lat'}.grid='Gaussian';
    end
    f{'lat'}.minimum= num2str(latout(1));
    f{'lat'}.maximum= num2str(latout(nlatsout));
    f{'lat'}.mean_interval= num2str((latout(nlatsout)-latout(1))/(nlatsout-1));

    f{'lon'}.coordinate_type='longitude';
    f{'lon'}.units='degrees_east';
    if dop==1
      f{'lat'}.grid='regular';
    else
      f{'lat'}.grid='Gaussian';
    end
    f{'lon'}.minimum= num2str(lonout(1));
    f{'lon'}.maximum= num2str(lonout(nlonsout));
    f{'lon'}.interval= num2str((lonout(nlonsout)-lonout(1))/(nlonsout-1));

%   define data attributes
    if dou
      f{'u'}.coordinates='time, lat, lon';
      f{'u'}.long_name='zonal wind velocity at 10m';
      f{'u'}.units='m/s';

      f{'v'}.coordinates='time, lat, lon';
      f{'v'}.long_name='meridional wind velocity at 10m';
      f{'v'}.units='m/s';

      if (strcmp(nctype,'short'))
        f{'u'}.scale_factor = wscfact;
        f{'u'}.add_offset = 0;
        f{'u'}.FillValue_=ncshort(fill);
        f{'u'}.missing_value =ncshort(miss);

        f{'v'}.scale_factor = wscfact;
        f{'v'}.add_offset = 0;
        f{'v'}.FillValue_=ncshort(fill);
        f{'v'}.missing_value =ncshort(miss);
      end
    end
    if dop
      f{'pressure'}.coordinates='time, lat, lon';
      if dop==1
        f{'pressure'}.long_name='pressure at mean sea level';
        f{'pmean'}.long_name='time-mean pressure at mean sea level';
      elseif dop==2
        f{'pressure'}.long_name='pressure at the surface';
        f{'pmean'}.long_name='time-mean pressure at the surface';
      end
      f{'pressure'}.units='Pa';
      f{'pmean'}.units='Pa';
      if (strcmp(nctype,'short'))
        f{'pressure'}.scale_factor = pscfact;
        f{'pressure'}.add_offset = pado;
        f{'pressure'}.FillValue_=ncshort(fill);
        f{'pressure'}.missing_value=ncshort(miss);
      end
      f{'pmean'}.FillValue_=ncfloat(fill);
      f{'pmean'}.missing_value=ncfloat(miss);
    end
    f{'lon'}(:,:)=longrid';
    f{'lat'}(:,:)=latgrid';
    f{'time'}(1:nrecs)=rectimeout;
  else
    if 1   % works with matlab 6.5 (1 Dec 2002)
    if dou
      u = get_ncep_quick(grfile, pos(i),nlons,nlats);
      v = get_ncep_quick(grfilev, posv(i),nlons,nlats);
    end 
    if dop==1
      i = 6 * (i-1) + 1; 
      hgt1000 = get_ncep_quick(grfile, pos(i),nlons,nlats);
      hgt500 = get_ncep_quick(grfile, pos(i+3),nlons,nlats);
    end 
    if dop==2
      pressure = get_ncep_quick(grfile, pos(i),nlons,nlats);
    end
    else   % revert to slow way:
    if dou
      u = get_ncep(grfile, pos(i),[],1);
      v = get_ncep(grfilev, posv(i),[],1);
    end 
    if dop==1
      i = 6 * (i-1) + 1; 
      hgt1000 = get_ncep(grfile, pos(i),[],1);
      hgt500 = get_ncep(grfile, pos(i+3),[],1);
    end 
    if dop==2
      pressure = get_ncep(grfile, pos(i),[],1);
    end
    end
    eltr = toc; 
  end % if irec==1
  tic; 
  if dou
    if (strcmp(nctype,'short'))
      uout = scalefill('U',u(lonsout,latsout),miss,wscfact);
      vout = scalefill('V',v(lonsout,latsout),miss,wscfact);
      f{'u'}(irec,:,:)=permute(uout,[2,1]);
      f{'v'}(irec,:,:)=permute(vout,[2,1]);
    else
      f{'u'}(irec,:,:)=permute(u(lonsout,latsout),[2,1]);
      f{'v'}(irec,:,:)=permute(v(lonsout,latsout),[2,1]);
    end
  end
  if dop
    if dop==1
%     calculate pressure at mean sea level
      pressureout = 100000*exp(hgt1000(lonsout,latsout)./...
         (1.5422885*(hgt500(lonsout,latsout)-hgt1000(lonsout,latsout))));
    else
      pressureout = pressure(lonsout,latsout);
    end
    if irec==1
      sumpress = pressureout-pado;
    else
      sumpress = sumpress + (pressureout-pado);
    end
    if (strcmp(nctype,'short'))
      pressureout = scalefill('SFCP',pressureout,miss,pscfact,pado);
    end
    f{'pressure'}(irec,:,:)=permute(pressureout,[2,1]);
  end
  elt2=toc;
%  disp([file_out ' ' num2str(eltr) ' '  num2str(elt2)  '  '...
%   julstr(jrectime(irec))])
  disp([file_out ' ' num2str(eltr) ' '  num2str(elt2)  '  '...
   num2str(gregorian(jrectime(irec)))])
end
if dop
  f{'pmean'}(:,:)=permute(sumpress/nrecs+pado,[2,1]);
end

% need this to finish off cleanly

f=close(f);

% -----------------------------------------------------------------------
% SCALEFILL: Scale data to short, check for and correct overflows, insert
% missing value flags.
%
% Note: ovflo is set to 1 if there is an overflow.

function [vv,ovflo] = scalefill(var,raw,miss,scf,ado)

ovflo = 0;
if nargin<5; ado = 0; end

vv = round((raw-ado)/scf);
if max(abs(vv(:))) > 32765
  ovflo = 1;
  warning(['Overflow after scaling in ' var]);
  rng = ado+([-1 1]*32765*scf);
  disp(['Data range :' num2str([min(real(raw(:))) max(real(raw(:)))]) ...
	  ', max scaled range: ' num2str(rng)]);
  ii = find(vv>32765);
  if ~isempty(ii); vv(ii) = repmat(32765,size(ii)); end
  ii = find(vv<-32765);
  if ~isempty(ii); vv(ii) = repmat(-32765,size(ii)); end    
end

ii = find(isnan(raw));
vv(ii) = repmat(miss,size(ii));

return

