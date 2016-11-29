% GETMAP: Load maps to Matlab from netCDF file
%
% INPUT: property - unambiguous name (eg 'si' for "silicate")
%        depth   - depth (in m) of map to extract (or level index if
%                  not on depth levels)
%  Optional....   (use [] if not required)
%        fpath   - fpath to netCDF map file
%        fname   - file name component, to build full name as follows:
%                  filename = [fullproperty '_' fname '.nc']
%                  {Only required if not accessing standard CARS}
%        fill    - 1=value at all depths everywhere, not just above bottom
%        vars    - specify variables to return:
%                  1=mn  2=an  3=sa  4=Xg  5=Yg  6=rq  7=details  8=nq  9=SD 
%                  10=rmsmr  11=rmsr  12=bcnt  13=swgt  14=grid-index  
%                  15=grid-depth   18=map_error
%        regn    - [w e s n] limits of required region
%
% OUTPUT:  All optional....
%         mn      - mean field
%         an      - complex annual harmonics
%         sa      - complex semiannual harmonics
%         Xg,Yg   - lon and lat coords of grid
%         rq      - data source radius (km) for mapping each grid point, OR
%                   where -ve, is number of data points used 
%         details - mapping details text string
%         nq      - number of data used in mapping each point
%         SD      - locally-weighted standard deviation of data
%         rmsmr   - locally-weighted RMS of residuals wrt mean field
%         rmsr    - locally-weighted RMS of residuals wrt mean and seasonal cyc
%         bcnt    - number of data in bin (cell) surrounding grid point 
%         swgt    - sum-of-weights from loess mapping
% OR:
%         as above, but in order specified in input argument "vars"
%
% Copyright (C) J R Dunn, CSIRO Marine Research  1999-2000
%
% USAGE: [mn,an,sa,Xg,Yg,rq,details,nq,SD,rmsmr,rmsr,bcnt,swgt] = ...
%                   getmap(property,depth,fpath,fname,fll,vars,regn)
%    OR for example
%        [mn,x,y] = getmap('t',10,[],[],[],[1 4 5],[150 160 -40 -20]);

function varargout = getmap(property,depth,fpath,fname,fll,vars,regn)

% MODS
%    - Added new output arguments Xg Yg    (4/6/98)
%    - Changed filename construction       (4/6/98)
%    - spec depth instead of depth index   (30/8/00)
%    - handles non-gridded (high-res) maps  (6/12/00)
%    - use clname instead of having filename code here (1/6/01)
%    - allow extraction of a subregion of a map (20/6/01)
%    - handle non-isobaric maps  (2/6/04)
%    - now ann & semi-ann can go to different depths (3/1/06)
%    - add swgt retrieval  (20/1/06)
%
% $Id: getmap.m,v 1.16 2006/04/21 06:48:01 dun216 Exp dun216 $
   
ncquiet;
varnm = {'mean','annual','semi_an','Xg','Yg','radius_q','map_details','nq',...
	'std_dev','RMSspatialresid','RMSresid','bin_count','sumofwgts',...
	'grid_index','grid_dep','','','map_error'};
Xg = []; Yg = [];

if isempty(depth)
   depth = 0;
end
if nargin<3
  fpath = [];
end
if nargin<4
  fname = [];
end
if nargin<5 | isempty(fll)
  fll = 0;
end
if nargin<6 | isempty(vars)
   vars = 1:nargout;
end
if nargin<7
  regn = [];
end

nout = min([length(vars) nargout]);
varargout{nout} = [];

[ncfile,ncf] = clname(property,fpath,fname);

% For non-gridded files, 'grin' relates vector of values to the reconstructed
% grid.  If a region is specified, 'igr' indexes the required region points
% in the vector and 'grin' is sorted to index the same points in the 
% reconstructed grid. ix & iy index the required region grid in the total grid. 

grin = ncf{'grid_index'}(:);
gridded = isempty(grin);

[Xg,Yg] = getXgYg(ncf,Xg,Yg);
Xsize = size(Xg);
ix = []; iy = [];

if ~isempty(regn)
   ix = find(Xg(1,:)>=regn(1) & Xg(1,:)<=regn(2));
   iy = find(Yg(:,1)>=regn(3) & Yg(:,1)<=regn(4));
   if isempty(iy) | isempty(ix)
      disp('GETMAP - specified region is entirely outside domain if maps')
      return
   end
   if ~gridded
      igr = find(Xg(grin)>=regn(1) & Xg(grin)<=regn(2) & Yg(grin)>=regn(3) ...
		 & Yg(grin)<=regn(4));
      grin = grin(igr);
   end
   Xg = Xg(iy,ix);
   Yg = Yg(iy,ix);   
elseif ~gridded
   igr = 1:length(grin);
end

getall = (~gridded | isempty(regn));

deps = ncf{'depth'}(:);
if isempty(deps)
   srfs = ncf{'level'}(:);
   if isempty(srfs)
      % Old isopycnal coord var
      srfs = ncf{'surfaces'}(:);
   end
   if isempty(srfs)   
      error([ncfile ' does not seem right! No depth or level variables'])
   else
      level = round(depth);
      if level<1 | level>length(srfs)
	 level = [];
      end
   end
else
   level = find(deps==round(depth));
end

if isempty(level)
   error(['There is no map for depth ' num2str(depth) ' in file ' ncfile]);
end


d1max = length(ncf('depth_ann'));
if d1max==0
   % Old 2nd depth coord
   d1max = length(ncf('depth_timefit'));
   if d1max > 0
      d2max = d1max;
   end
else
   d2max = length(ncf('depth_semiann'));   
end

for kk = 1:nout
   iv = vars(kk);
   switch iv
     case {2,11}
       if level > d1max
	  varargout{kk} = [];
	  tmp = [];
       elseif iv==2
	  rpart = scget(ncf,'an_cos',level,iy,ix,getall);
	  ipart = scget(ncf,'an_sin',level,iy,ix,getall);   
	  tmp = rpart + i*ipart;
       else
	  tmp = scget(ncf,varnm{iv},level,iy,ix,getall);
       end
       
     case 3
       if level > d2max
	  varargout{kk} = [];
	  tmp = [];
       else
	  rpart = scget(ncf,'sa_cos',level,iy,ix,getall);
	  ipart = scget(ncf,'sa_sin',level,iy,ix,getall);
	  tmp = rpart + i*ipart;
       end
       
     case {1,6,8,9,10,12,13,15,18}
       if iv==15
	  tmp = scget(ncf,varnm{iv},[],iy,ix,getall);
       else
	  tmp = scget(ncf,varnm{iv},level,iy,ix,getall);
       end
       
     case 7
       varargout{kk} = ncf{varnm{iv}}(:,level)';
       
     case 4
       varargout{kk} = Xg;
       
     case 5
       varargout{kk} = Yg;

     case 14
       varargout{kk} = grin;

   end
   if any([1:3 6 8:13 15 18]==iv)
      if ~gridded & ~isempty(tmp)
	 tmp2 = repmat(nan,Xsize);
	 tmp2(grin) = tmp(igr);
	 if isempty(regn)
	    varargout{kk} = tmp2;
	 else
	    varargout{kk} = tmp2(iy,ix);
	 end
      else
	 varargout{kk} = tmp;
      end
   end
end



if ~fll
   % If no "grid_dep" var then cannot "unfill" the fields.
   gdp = ncf{'grid_dep'}(:);
   fll = isempty(gdp);
end

if ~fll      
   % If grid_dep is not setup or initialised, gdp will be empty or
   % fill-valued or zero valued.
   if any(gdp(:)>-32766) & ~all(gdp(:)==0)
      if ~gridded
	 tmp = repmat(nan,Xsize);
	 tmp(grin) = gdp(igr);
	 gdp = tmp;
      end
      if ~isempty(regn)
	 gdp = gdp(iy,ix);
      end
      rr = find(gdp<level);
      ij = find(ismember(vars,[1 2 3]));
      for kk = ij(:)'
	 if (vars(kk)==1 | level<=d1max | (vars(kk)==3 & level<=d2max)) ...
		      & ~isempty(varargout{kk})
	    varargout{kk}(rr) = repmat(NaN,size(rr));
	 end
      end
   end
end

close(ncf);

% --------------------------------------------------------------------
function [X,Y] = getXgYg(ncf,Xg,Yg)
   
   if isempty(Xg)	  
      X = ncf{'lon'}(:);
      Y = ncf{'lat'}(:);
      if min(size(X))==1
	 [X,Y] = meshgrid(X,Y);
      end
   else
      X = Xg;
      Y = Yg;
   end
   return
   
% --------------------------------------------------------------------
function vv = scget(ncf,varn,level,iy,ix,getall)

fill = ncf{varn}.FillValue_(:);
miss = ncf{varn}.missing_value(:);

% Extract data WITHOUT scaling so that can detect flag values.
% We look only for exact equality to the flag values because assume are only
% checking integer data.

ii = [];
if isempty(level)
   if getall
      vv = ncf{varn}(:,:);
   else
      vv = ncf{varn}(iy,ix);
   end
else
   if getall
      vv = ncf{varn}(level,:,:);
   else
      vv = ncf{varn}(level,iy,ix);
   end
end

if isempty(vv)
   return
end

if ~isempty(fill)
  ii = find(vv==fill);
  % Avoid checking twice if missing and fill values are the same
  if ~isempty(miss)
    if miss==fill, miss = []; end
  end
end

if ~isempty(miss) 
  i2 = find(vv==miss);
  ii = [ii(:); i2(:)];
end

% Now scale data, and overwrite any locations which held flag values.

adof = ncf{varn}.add_offset(:);
if isempty(adof)
   adof = 0;
end
scf = ncf{varn}.scale_factor(:);
if isempty(scf)
   scf = 1;
end

vv = (vv*scf) + adof;

if ~isempty(ii)
  vv(ii) = repmat(NaN,size(ii));
end

% ------------ End of getmap -----------------------------------------
