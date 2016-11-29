% GET_ALT_XY_NRT: Return altimeter (height anomaly) data, interpolated in space 
%  and time from Madeleine's gridded datasets (one file per day) at given 
%  locations and times. 
%
% TEMPORAL COVERAGE:  dset 1:  - discontinued and removed
%                     dset 2: Jan 2003 -  continuing as at Nov 2004
%                     dset 3: 21 Feb 2003 - continuing as at Nov 2004
% INPUT
%  x,y  - vector or matrices of locations
%  tim  - Unix time of required data; eg greg2time([2001 12 31 0 0 0]).
%         Either single or one for every location.
%  dset 2= usgodae/altim/map/amsa/
%       3= USNRT/mapped/   [default]
%
% OUTPUT
%  alt  - alt at x,y,t locations (nan where no data available)
%
% Jeff Dunn  CSIRO CMR 10/11/04 
% 
% USAGE: alt = get_alt_xy_nrt(x,y,tim,dset);

function alt = get_alt_xy_nrt(x,y,tim,dset)
 
if nargin<4 | isempty(dset)
   dset = 3;
end

alt = repmat(nan,size(x));

% Get a directory listing; decode filenames to times;
vnm = {'map_h','h_oi','GSLA'};
dnm{1} = platform_path('chish','oez2/cahill/topex/map/hi_res/');
dnm{2} = platform_path('chish','oez2/cahill/usgodae/altim/map/amsa/');
dnm{3} = platform_path('reg','reg2/altim/USNRT/mapped/');

if dset==2
   dirl = dir([dnm{dset} '200*.mat']);
   fmt{2} = '%4d%2d%2d';
else
   dirl = dir([dnm{dset} 'GSLA_*.nc']);
   fmt{3} = 'GSLA_%4d%2d%2d';
end
if isempty(dirl)
   error(['No files in ' dnm{dset}]);
end

nfl = length(dirl);
for ii = 1:nfl      
   if dirl(ii).bytes > 0
      dats = sscanf(dirl(ii).name,fmt{dset});
      if length(dats)~=3
	 ftim(ii) = nan;
      else 
	 ftim(ii) = greg2time([dats(:)' 0 0 0]);
      end
   else
      ftim(ii) = nan;
   end
end

if dset==2
   load([dnm{2} 'latlon'],'-mat','lon','lat');
   lon = lon(1,:)';
   lat = lat(:,1);
else
   lon = getnc([dnm{3} dirl(1).name],'lon');
   lat = getnc([dnm{3} dirl(1).name],'lat');
end

if max(size(tim)) == 1
   ii = find(tim==ftim);
else
   ii = [];
end
   
if ~isempty(ii)
   if dset==2
      hh = loadonly([dnm{dset} dirl(ii).name],vnm{dset}); 	 
   else
      hh = getnc([dnm{dset} dirl(ii).name],vnm{dset});
   end      
   alt = interp2(lon,lat,hh,x,y);

else         
   if size(tim) ~= size(x)
      tim = repmat(tim(1),size(x));
   end

   kk = find(x>min(lon) & x<max(lon) & y>min(lat) & y<max(lat));

   for ii = 1:(nfl-1)
      jj = kk(find(tim(kk)>=ftim(ii) & tim(kk)<ftim(ii+1)));

      if isempty(jj)
	 % skip this
      else
	 if dset==2
	    hh = loadonly([dnm{dset} dirl(ii).name],vnm{dset}); 	 
	    ha = loadonly([dnm{dset} dirl(ii+1).name],vnm{dset}); 
	 elseif dset==3
	    hh = getnc([dnm{dset} dirl(ii).name],vnm{dset});
	    ha = getnc([dnm{dset} dirl(ii+1).name],vnm{dset});
	 end
	 hh = cat(3,hh,ha);
	 
	 tjj = tim(jj)-ftim(ii);
	 tdif = ftim(ii+1)-ftim(ii);
	 
	 alt(jj) = interp3(lon,lat,[0 tdif],hh,x(jj),y(jj),tjj);
      end
   end
end

%---------------------------------------------------------------------------
