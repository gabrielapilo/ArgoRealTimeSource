% GET_BATH  Get ocean depth at given locations, using a range of datasets.
%
% INPUTS
%  lon,lat  Locations at which depth is required
%  dset   vector of datasets in order
%         1=Terrainbase  2=NGDCv8.2  3=AusBath15   4=AGSO98  5=AGSO2002
%         6=GEBCO'03
%         Default:  [5 2]
%         See www.marine.csiro.au/eez_data/doc/bathy.html 
%  rpt    [Optional]  1 => save loaded AusBath15 to global variable, to make
%         subsequent calls faster. Default 0.
% OUTPUTS
%  deps   depths (m), -ve downwards, NaN where no value.
%
% SUPERCEDES  get_bath15, agso_bath_xy
%
% Jeff Dunn   CSIRO Marine Research   8/1/2003 - 6/4/06
%
% SEE ALSO   get_bath_agso.m   (to get AGSO 2002 at full resolution)
%
% USAGE: deps = get_bath(lon,lat,dset,rpt)

function deps = get_bath(x,y,dset,rpt)

% Mods: 9/5/03 Pre-check for presence of datasets, and resort to others
%       if some are missing.

ncquiet;
   
if nargin<3 | isempty(dset)
   dset = [5 2 3 1];
   % Added [3 1] in case the files for 5 and/or 2 cannot be found
end

igd = 0;
dtmp = [];
fnms{1} = [];
for ii = dset(:)'
   switch ii
     case 1
       fnm = platform_path('fips','eez_data/bath/terrainbase.mat');
       aa = exist(fnm,'file');
     case 2
       fnm = platform_path('reg','netcdf-data/topo_ngdc_8.2.nc');
       aa = exist(fnm,'file');
     case 3
       fnm = platform_path('fips','eez_data/bath/ausbath15.mat');
       aa = exist(fnm,'file');
       if ~aa
	  fnm = platform_path('cascade','dunn/bath/ausbath15.mat');
	  aa = exist(fnm,'file');
       end
     case 4
       fnm = platform_path('reg','netcdf-data/bath_agso_98.nc');
       aa = exist(fnm,'file');       
     case 5
       fnm = platform_path('reg','netcdf-data/bath_agso_2002.nc');
       aa = exist(fnm,'file');
     case 6
       fnm = platform_path('reg','netcdf-data/gebco_2003.nc');
       aa = exist(fnm,'file');
   end
   if aa>0
      igd = igd+1;
      dtmp(igd) = ii;
      fnms{igd} = fnm;
   else
      disp(['GET_BATH: dataset ' num2str(ii) ' not used because gone missing.'])
   end
end
if igd==0
   disp('GET_BATH: Cannot find any of the bathy files - no depths returned.')
   return
end
dset = dtmp;

if nargin<4 | isempty(rpt)
   rpt = 0;
end

deps = repmat(nan,size(x));

ii = 1:prod(size(x));

ids = 1;
while ~isempty(ii) & ids<=igd
   switch dset(ids)
     case 1
       % Terrainbase
       deps(ii) = topo(y(ii),x(ii),fnms{ids});
       ii = [];
     
     case 2
       % NGDC
       deps(ii) = topongdc(y(ii),x(ii),fnms{ids});
       ii = ii(find(y(ii)<-72 | y(ii)>72));
     
     case 3
       % AusBath15
       jj = find(x(ii)>=109 & x(ii)<=156 & y(ii)>=-45 & y(ii)<=-1);

       if ~isempty(jj)
	  ji = ii(jj);
	  if ~exist('AusBath15','var')
	     global AusBath15
	     load(fnms{ids});
	  end
	  
	  xx = 1+((x(ji)-109)*15);
	  yy = 1+((-1-y(ji))*15);
	  deps(ji) = interp2(AusBath15,xx,yy,'*linear');
	  ii(jj) = [];
	  if rpt ~= 1
	     clear global AusBath15
	  end
       end

     case {4,5,6}
       % AGSO 98 and AGSO 2002 and GEBCO 2003
       lo = getnc(fnms{ids},'lon');
       la = getnc(fnms{ids},'lat');

       jj = find(x(ii)>=min(lo) & x(ii)<=max(lo) & y(ii)>=min(la) & y(ii)<=max(la));
       ji = ii(jj);

       if ~isempty(ji)
	  % Broaden region slightly (by .1 degree) so extracted chunk encloses
	  % all points
	  ix = find(lo>=min(x(ji))-.1 & lo<=max(x(ji))+.1);
	  iy = find(la>=min(y(ji))-.1 & la<=max(y(ji))+.1);

	  % If a large region required, break it into chunks to avoid causing
	  % a crash due to memory overload.
	  if length(iy)*length(ix) > 250000
	     chsz = 500;
	     ixch = min(ix):chsz:max(ix)+chsz;
	     if ixch(end)>length(lo); ixch(end)=length(lo); end
	     iych = min(iy):chsz:max(iy)+chsz;
	     if iych(end)>length(la); iych(end)=length(la); end

	     for kx = 1:(length(ixch)-1)
		loc = lo(ixch(kx):ixch(kx+1));
		for ky = 1:(length(iych)-1)
		   lac = la(iych(ky):iych(ky+1));
		   ki = find(x(ji)>=min(loc) & x(ji)<max(loc) & y(ji)>=min(lac) & y(ji)<max(lac));
		   if ~isempty(ki)
		      kj = ji(ki);
		      ji(ki) = [];
		      dg = getnc(fnms{ids},'height',[iych(ky) ixch(kx)],[iych(ky+1) ixch(kx+1)]);
		      if length(loc)==1	  
			 % Degenerate case where only want points on boundary of dataset
			 deps(kj) = interp1(lac,dg,y(kj));
		      elseif length(lac)==1	  
			 % Ditto
			 deps(kj) = interp1(loc,dg,x(kj));
		      else
			 [xc,yc] = meshgrid(loc,lac);
			 deps(kj) = interp2(xc,yc,dg,x(kj),y(kj));
		      end
		   end
		end
	     end
	     
	  else
	     % Small region - don't need to break into chunks
	     dg = getnc(fnms{ids},'height',[iy(1) ix(1)],[iy(end) ix(end)]);
	     [lo,la] = meshgrid(lo(ix),la(iy));
	     if length(ix)==1	  
		% Degenerate case where only want points on boundary of dataset
		deps(ji) = interp1(la,dg,y(ji));
	     elseif length(iy)==1	  
		% Ditto
		deps(ji) = interp1(lo,dg,x(ji));
	     else
		deps(ji) = interp2(lo,la,dg,x(ji),y(ji));
	     end
	     
	  end

	  % Remove from the list only points for which we have obtained data.
	  ll = find(~isnan(deps(ii(jj))));
	  ii(jj(ll)) = [];
	  
	  clear jj ji lo la dg xc yc
       end
       
     otherwise
       disp(['GET_BATH: Do not understand dataset ' num2str(dset(ids))]);
   end   
   ids = ids+1;
end
   
%---------------------------------------------------------------------------
