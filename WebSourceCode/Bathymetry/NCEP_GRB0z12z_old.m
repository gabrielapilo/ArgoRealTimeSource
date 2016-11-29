% NCEP_GRB012extr: Extract time,lat,lon cube from NCEP GRIB-format 
% global-coverage year-files and write to Net-CDF file.
%
%    version 1 David Griffin Feb 1998  - for the 10m winds at 0z & 12Z
%    version 2 DG Feb 98  - also surface pressure
%
%%   Usage example:
%area=[105 160 -45 -5];
%%   lonmin max latmin max
%date1=[1987 1 1 0 0 0];
%daten=[1996 12 31 0 0 0];
%%     year mo da h m s UTC
%time_interval = 0.5;
%% ^ subsampling interval: use 0.5 to get twice-daily data, 1 for daily, etc.
%   To do: enable time-averaging
%
%
%dir_in='/home/eez_data/winds/ncep/GRB/at00z12z/';
%%assumes the grib files off the CDs are in
%%this directory, with the year added to the name of each file, eg
% cp /CDROM/data/at00z12z/ugrd.10m 1996ugrd.10m
%
%
%refyear = 1980;
%% the time vector output to the .nc file will be days from the beginning
%% of refyear.
% dou=1; dop=0;
%% means extract u,v10m, and not surface pressure
%areaname='Australia';
%% appears in title of file
%
%NCEP_GRB0z12z(area,date1,daten,time_interval,dir_in,dir_out,file_out,refyear,dou,dop,areaname,nctype)

function NCEP_GRB0z12z(area,date1,daten,time_interval,dir_in,dir_out,file_out,refyear,dou,dop,areaname,nctype)

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
f.history='extraction from annual, global GRB files using NCEP_GRBextr.m - David Griffin, CSIRO';


for irec=1:nrecs
  year = grectime(irec,1);
  i = (jrectime(irec) - julian([year 1 1 0 0 0]))/time_interval + 1;
  tic; 
  if dou
    [u10m,info,lon,lat] = get_ncep([dir_in,num2str(year),'ugrd.10m'], i,areaname);
    [v10m,info,lon,lat] = get_ncep([dir_in,num2str(year),'vgrd.10m'], i,areaname);
  end 
  if dop
    [sfcp,info,lon,lat] = get_ncep([dir_in,num2str(year),'pres.sfc'], i,areaname); 
  end 
  eltr = toc; 
  if irec==1
%   assume the grid is constant, find lat and lon limits:
    lon=lon';
    lonsout=find(lon>=area(1) & lon<=area(2));
    latsout=find(lat>=area(3) & lat<=area(4));
    latsout=flipdim(latsout,1);
%             ^NB so lat increases with j  
    nlonsout=length(lonsout);
    nlatsout=length(latsout);
    lonout=lon(lonsout);
    latout=lat(latsout);

%        write .nc file header
%   define dimensions
    f('lon')=nlonsout;
    f('lat')=nlatsout;
    f('time')=0;
%   define coordinate variables
    f{'time'}=ncdouble('time');
    f{'lat'}=ncfloat('lat');
    f{'lon'}=ncfloat('lon');

%   define data variables
    if dou
      if (strcmp(nctype,'short'))
        f{'u10m'}=ncshort('time','lat','lon');
        f{'v10m'}=ncshort('time','lat','lon');
      elseif (strcmp(nctype,'float'))
        f{'u10m'}=ncfloat('time','lat','lon');
        f{'v10m'}=ncfloat('time','lat','lon');
      else
        error('requested nctype not supported')
      end
    end
    if dop
      if (strcmp(nctype,'short'))
        f{'sfcp'}=ncshort('time','lat','lon');
      elseif (strcmp(nctype,'float'))
        f{'sfcp'}=ncfloat('time','lat','lon');
      end
    end

%   define coordinate attributes
    f{'time'}.quantity='time';
    if strcmp(info.production_info,'6hr fcst:')
      tzstr = ' -6.00'
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

    f{'lat'}.quantity='latitude';
    f{'lat'}.units='degrees_north';
    f{'lat'}.grid='Gaussian';
    f{'lat'}.minimum= num2str(latout(1));
    f{'lat'}.maximum= num2str(latout(nlatsout));
    f{'lat'}.mean_interval= num2str((latout(nlatsout)-latout(1))/(nlatsout-1));

    f{'lon'}.quantity='longitude';
    f{'lon'}.units='degrees_east';
    f{'lon'}.grid='regular';
    f{'lon'}.minimum= num2str(lonout(1));
    f{'lon'}.maximum= num2str(lonout(nlonsout));
    f{'lon'}.interval= num2str((lonout(nlonsout)-lonout(1))/(nlonsout-1));

%   define data attributes
    if dou
      f{'u10m'}.coordinates='time, lat, lon';
      f{'u10m'}.long_name='zonal wind velocity';
      f{'u10m'}.units='m/s';

      f{'v10m'}.coordinates='time, lat, lon';
      f{'v10m'}.long_name='meridional wind velocity';
      f{'v10m'}.units='m/s';

      if (strcmp(nctype,'short'))
        f{'u10m'}.scale_factor = wscfact;
        f{'u10m'}.add_offset = 0;
        f{'u10m'}.FillValue_=ncshort(fill);
        f{'u10m'}.missing_value =ncshort(miss);

        f{'v10m'}.scale_factor = wscfact;
        f{'v10m'}.add_offset = 0;
        f{'v10m'}.FillValue_=ncshort(fill);
        f{'v10m'}.missing_value =ncshort(miss);
      end
    end
    if dop
      f{'sfcp'}.coordinates='time, lat, lon';
      f{'sfcp'}.long_name='surface pressure';
      f{'sfcp'}.units='Pa';
      if (strcmp(nctype,'short'))
        f{'sfcp'}.scale_factor = pscfact;
        f{'sfcp'}.add_offset = pado;
        f{'sfcp'}.FillValue_=ncshort(fill);
        f{'sfcp'}.missing_value=ncshort(miss);
      end
    end
    f{'lon'}(:)=lonout;
    f{'lat'}(:)=latout;
    f{'time'}(1:nrecs)=rectimeout;
  end
  tic; 
  if dou
    if (strcmp(nctype,'short'))
      u10mout = scalefill('U10M',u10m(lonsout,latsout),miss,wscfact);
      v10mout = scalefill('V10M',v10m(lonsout,latsout),miss,wscfact);
      f{'u10m'}(irec,:,:)=permute(u10mout,[2,1]);
      f{'v10m'}(irec,:,:)=permute(v10mout,[2,1]);
    else
      f{'u10m'}(irec,:,:)=permute(u10m(lonsout,latsout),[2,1]);
      f{'v10m'}(irec,:,:)=permute(v10m(lonsout,latsout),[2,1]);
    end
  end
  if dop
    if (strcmp(nctype,'short'))
      sfcpout = sfcp(lonsout,latsout);
      sfcpout = scalefill('SFCP',sfcp(lonsout,latsout),miss,pscfact,pado);
      f{'sfcp'}(irec,:,:)=permute(sfcpout,[2,1]);
    else
      f{'sfcp'}(irec,:,:)=permute(sfcp(lonsout,latsout),[2,1]);
    end
  end
  elt2=toc;
  disp([file_out ' ' num2str(eltr) ' '  num2str(elt2)  '  ' julstr(jrectime(irec))])
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

