% NCEP_GRBdaily: Extract time,lat,lon cube from NCEP GRIB-format 
% global-coverage year-files and write to Net-CDF file.
%
%    version 1 David Griffin Feb 1998
%    1.1 Dec 99 added land mask, other fluxes, and changed VARIABLE NAMES - DG
%    1.2 Jan 00 made reading of other fluxes an option
%    1.3 Jan 03 pass dirGRB instead of dir_in, and hardwire time_interval=1
%
%%   Usage example:
%area=[105 160 -45 -5];
%%   lonmin max latmin max
%areaname='Australia';
%% appears in title of file
%date1=[1987 1 1 0 0 0];
%daten=[1996 12 31 0 0 0];
%%     year mo da h m s UTC
%   To do: enable time-averaging
%
%
%%assumes the grib files off the CDs are in
%%dirGRB/daily/, with the year added to the name of each file, eg
%%mv uflx.sfc 1993uflx.sfc
%
%
%refyear = 1980;
%% the time vector output to the .nc file will be days from the beginning
%% of refyear.
%old:NCEP_GRBdaily(area,date1,daten,time_interval,dir_in,dir_out,file_out,refyear,areaname,others)
%now:NCEP_GRBdaily(area,date1,daten,dirGRB,dir_out,file_out,refyear,areaname,others)

function NCEP_GRBdaily(area,date1,daten,dirGRB,dir_out,file_out,refyear,areaname,others)

dir_in=[dirGRB 'daily/']; % used to be passed instead of dirGRB
time_interval=1;          % used to be passed

if nargin<10
  others=0;
end

nrecs=(julian(daten)-julian(date1))/time_interval + 1;
rectime = (0:nrecs-1)*time_interval; 
jrectime = rectime + julian(date1); 
grectime = gregorian(jrectime);
time_ref = [refyear 1 1 0 0 0];
time_ref_str = [num2str(refyear) '-01-01 0:0:0.0'];
rectimeout = jrectime - julian(time_ref);

fill = -32767;
miss = -32766;
scf = .0005;
scf_h = 0.1;
scf_w = 0.0005;

% open netcdf file
f=netcdf([dir_out file_out],'clobber');
% define global attributes
f.title=['NCEP/NCAR Global Atmospheric Re-analyses v4/97 - ' areaname]
f.reference='Bulletin of the American Meteorological Society, vol 77, no 3, 1996'
f.conventions='COARDS (approximately)'
f.history='extraction from (TOVS-corrected) annual, global GRB files using NCEP_GRBdaily.m - David Griffin, CSIRO'

flxsign = -1
% the NCEP CD's have +ve fluxes upward. ROMS and oceanographers
% use +ve fluxes downward.
if flxsign ~= -1; error('check the .positive attributes'); end


for irec=1:nrecs
  year = grectime(irec,1);
  i = jrectime(irec) - julian([year 1 1 0 0 0]) + 1;
  disp([file_out ' ' num2str(gregorian(jrectime(irec)))])
  [uflx,info,lon,lat] = get_ncep([dir_in,num2str(year),'uflx.sfc'], i); 
  [vflx] = get_ncep([dir_in,num2str(year),'vflx.sfc'], i);
  if others 
  [dswrf] = get_ncep([dir_in,num2str(year),'dswrf.sfc'], i); 
  [nswrs] = get_ncep([dir_in,num2str(year),'nswrs.sfc'], i); 
  [nlwrs] = get_ncep([dir_in,num2str(year),'nlwrs.sfc'], i); 
  [lhtfl] = get_ncep([dir_in,num2str(year),'lhtfl.sfc'], i); 
  [shtfl] = get_ncep([dir_in,num2str(year),'shtfl.sfc'], i); 
  [xprate] = get_ncep([dir_in,num2str(year),'xprate.sfc'], i); 
  end
  if (irec==1)
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
    f{'sustr'}=ncshort('time','lat','lon');
    f{'svstr'}=ncshort('time','lat','lon');
    if others
    f{'swrad'}=ncshort('time','lat','lon');
    f{'shflux'}=ncshort('time','lat','lon');
    f{'swflux'}=ncshort('time','lat','lon');
    end
    f{'land'}=ncshort('lat','lon');

%   define coordinate attributes
    f{'time'}.quantity='time';
    if strcmp(info.production_info,'0-24hr ave:')
      tzstr = ' -12.00'
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
    f{'time'}.subcell= 'cell';

    f{'lat'}.quantity='latitude';
    f{'lat'}.units='degrees_north';
    f{'lat'}.grid='Gaussian';
    f{'lat'}.minimum= num2str(latout(1));
    f{'lat'}.maximum= num2str(latout(nlatsout));
    f{'lat'}.mean_interval= num2str((latout(nlatsout)-latout(1))/(nlatsout-1));

    f{'lon'}.coordinate_type='longitude';
    f{'lon'}.units='degrees_east';
    f{'lon'}.grid='regular';
    f{'lon'}.minimum= num2str(lonout(1));
    f{'lon'}.maximum= num2str(lonout(nlonsout));
    f{'lon'}.interval= num2str((lonout(nlonsout)-lonout(1))/(nlonsout-1));

%   define data attributes
    f{'sustr'}.coordinates='time, lat, lon';
    f{'sustr'}.long_name='surface u-momentum stress';
    f{'sustr'}.units='Newton meter-2';
    f{'sustr'}.field='surface u-momentum stress, scalar, series';
    f{'sustr'}.positive='downward momentum flux, eastward component';
    f{'sustr'}.source=['NCEP Reanalysis 24h ave ' num2str(flxsign) '*UFLX'];
    f{'sustr'}.FillValue_ = fill;
    f{'sustr'}.missing_value = miss;
    f{'sustr'}.scale_factor = scf;
    f{'sustr'}.add_offset = 0;

    f{'svstr'}.coordinates='time, lat, lon';
    f{'svstr'}.long_name='surface v-momentum stress';
    f{'svstr'}.units='Newton meter-2';
    f{'svstr'}.field='surface v-momentum stress, scalar, series';
    f{'svstr'}.positive='downward momentum flux, northward component';
    f{'svstr'}.source=['NCEP Reanalysis 24h ave ' num2str(flxsign) '*VFLX'];
    f{'svstr'}.FillValue_ = fill;
    f{'svstr'}.missing_value = miss;
    f{'svstr'}.scale_factor = scf;
    f{'svstr'}.add_offset = 0;

    if others
    f{'swrad'}.coordinates='time, lat, lon';
    f{'swrad'}.long_name='solar shortwave radiation';
    f{'swrad'}.units='Watts meter-2';
    f{'swrad'}.field='shortwave radiation, scalar, series';
    f{'swrad'}.positive='downward flux, heating';
    f{'swrad'}.negative='upward flux, cooling';
    f{'swrad'}.source='NCEP Reanalysis 24h ave DSWRF';
    f{'swrad'}.FillValue_ = fill;
    f{'swrad'}.missing_value = miss;
    f{'swrad'}.scale_factor = scf_h;
    f{'swrad'}.add_offset = 0;

    f{'shflux'}.coordinates='time, lat, lon';
    f{'shflux'}.long_name='surface net heat flux';
    f{'shflux'}.units='Watts meter-2';
    f{'shflux'}.field='surface heat flux, scalar, series';
    f{'shflux'}.positive='downward flux, heating';
    f{'shflux'}.negative='upward flux, cooling';
    f{'shflux'}.source=['NCEP Reanalysis 24h ave ' num2str(flxsign) '*(NSWRS+NLWRS+LHTFL+SHTFL)'];
    f{'shflux'}.FillValue_ = fill;
    f{'shflux'}.missing_value = miss;
    f{'shflux'}.scale_factor = scf_h;
    f{'shflux'}.add_offset = 0;

    f{'swflux'}.coordinates='time, lat, lon';
    f{'swflux'}.long_name='surface freshwater flux (E-P)';
    f{'swflux'}.units='centimeter day-1';
    f{'swflux'}.field='surface freshwater flux, scalar, series';
    f{'swflux'}.positive='net evaporation';
    f{'swflux'}.negative='net precipitation';
    f{'swflux'}.source='NCEP Reanalysis 24h ave (LHTFL/2.5E6-XPRATE)*8640';
    f{'swflux'}.FillValue_ = fill;
    f{'swflux'}.missing_value = miss;
    f{'swflux'}.scale_factor = scf_w;
    f{'swflux'}.add_offset = 0;
    end

    f{'land'}.coordinates='lat, lon';
    f{'land'}.long_name='land mask (0=water, 1=land)';

    f{'lon'}(:,:)=longrid';
    f{'lat'}(:,:)=latgrid';
    f{'time'}(1:nrecs)=rectimeout;

    [landmask] = get_ncep([dirGRB 'fixed/land.sfc'], 1); 
    f{'land'}(:,:) = permute(landmask(lonsout,latsout),[2,1]);
  end

  fout = flxsign*uflx(lonsout,latsout);
  fout = scalefill('sustr',fout,miss,scf);
  f{'sustr'}(irec,:,:)=permute(fout,[2,1]);

  fout = flxsign*vflx(lonsout,latsout);
  fout = scalefill('svstr',fout,miss,scf);
  f{'svstr'}(irec,:,:)=permute(fout,[2,1]);

  if others

  fout = dswrf(lonsout,latsout);
  fout = scalefill('swrad',fout,miss,scf_h);
  f{'swrad'}(irec,:,:)=permute(fout,[2,1]);

  fout = flxsign*(nswrs(lonsout,latsout)+nlwrs(lonsout,latsout)...
                 +lhtfl(lonsout,latsout)+shtfl(lonsout,latsout));
  fout = scalefill('shflux',fout,miss,scf_h);
  f{'shflux'}(irec,:,:)=permute(fout,[2,1]);

  fout = (lhtfl(lonsout,latsout)/2.5e6-xprate(lonsout,latsout))*8640;
  fout = scalefill('swflux',fout,miss,scf_w);
  f{'swflux'}(irec,:,:)=permute(fout,[2,1]);

  end

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
if max(abs(vv(:))) > 32765*0.9 | max(abs(vv(:))) < 32765/100
  rng = ado+([-1 1]*32765*scf);
  disp([var ' data range :' num2str([min(real(raw(:))) max(real(raw(:)))]) ...
	  ', max usable range: ' num2str(rng)]);
  if max(abs(vv(:))) > 32765  ovflo = 1;
%    warning(['Overflow after scaling in ' var]);
    error(['Overflow after scaling in ' var]);
    ii = find(vv>32765);
    if ~isempty(ii); vv(ii) = repmat(32765,size(ii)); end
    ii = find(vv<-32765);
    if ~isempty(ii); vv(ii) = repmat(-32765,size(ii)); end    
  end
end

ii = find(isnan(raw));
vv(ii) = repmat(miss,size(ii));

return
