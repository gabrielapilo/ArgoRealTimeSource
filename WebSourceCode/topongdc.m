% TOPONGDC:   Extract heights from topo_ngdc datafile, for given lats&lons.
% INPUT:
%    lat - matrix of lats
%    lon - matrix of longs, 0-360deg
%    fname - optional - name of terrainbase file
%
% OUTPUT:
%    deps - in metres, +ve upwards (so actually heights, not depths).
%
% Jeff Dunn 26/5/97
% 22/5/98  Sped up by reading in topo file chunks
%  5/3/08  Catch bad lats, lons; convert longitude West to 0-360.
%
% USAGE: [deps] = topongdc(lats,lons,fname)

function [deps] = topongdc(lats,lons,fname)

persistent warn_once

ncmex('setopts',0);


% Changed from 6.2 to 8.2 on 8/1/2003
if nargin<3 | isempty(fname)
   fname = platform_path('nfstas01-hba','netcdf-data/topo_ngdc_8.2.nc');
end

deps = repmat(NaN,size(lats));
idx = 1:prod(size(lats));

ierrcnt = 0;
rcode = 0;
rcode = -1;
while rcode<0
   [fid,rcode] = ncmex('ncopen',fname,'nowrite');
   if rcode<0
      ierrcnt = ierrcnt+1;
      if ierrcnt>50
	 error('Aborting in TOPONGDC - flaky connection to bathy file');
      else
	 pause(1);
      end
   end
end

flat = ncmex('varget',fid,'lat',[0],[6336]);

jj = find(lats<flat(1) | lats>flat(6336) | isnan(lats) | isnan(lons));
if ~isempty(jj) && isempty(warn_once)   
   disp(['TOPONGDC (GET_BATH): ' num2str(length(jj),8) ' lats out of range']);
   idx(jj) = [];
   warn_once = 1;
end

if any(lons<0)
   kk = find(lons<0);
   lons(kk) = lons(kk)+360;
end

% 17/3/05 Without properly tracking down the problem, avoid an indexing
% overflow just by avoiding lon=360.
jj = find(lons>=360);
if ~isempty(jj)
   lons(jj) = 359.99;
end

% NOTE: varget uses 'C' style indexing from 0

lorec = floor(lons(idx).*30);

rlt0 = -72.006;
nlt = 6336;
rad = pi/180;
alpha = rad/30; 
beta= tan(rad*(45.+rlt0/2.));

larec = floor(-.5 + (log(tan(rad*(45+lats(idx)./2))/beta))/alpha);

% Reading one netcdf element at a time is slow, so if more than a few points
% required, build a mesh of chunks and read in and extract from any chunks 
% containing required points.

chsz = 500;
if length(idx)>100
  [lach,loch] = meshgrid(min(larec):chsz:max(larec),min(lorec):chsz:max(lorec));
  for ii=1:prod(size(lach))
    jj = find( larec>=lach(ii) & larec<(lach(ii)+chsz) ...
 	     & lorec>=loch(ii) & lorec<(loch(ii)+chsz) );
    if ~isempty(jj)
       if (lach(ii)-1+chsz) > 6336
	  chs1 = 6336-lach(ii);
       else
	  chs1 = chsz;
       end
       if (loch(ii)-1+chsz) > 10800
	  chs2 = 10800-loch(ii);
       else
	  chs2 = chsz;
       end
       dch = ncmex('varget',fid,'height',[lach(ii) loch(ii)],[chs1 chs2]);
       latmp = larec(jj)-lach(ii)+1;
       lotmp = lorec(jj)-loch(ii)+1;
       chidx = (chs2*(latmp-1))+lotmp;
       deps(idx(jj)) = dch(chidx);
    end
  end  
else
  for jj = 1:length(idx)
    deps(idx(jj)) = ncmex('varget1',fid,'height',[larec(jj) lorec(jj)]);
  end  
end

ncmex('ncclose',fid);

% ------------ End of topongdc.m -------------------
