% GETCHUNK: Extract a 3D chunk of a netCDF file map
% INPUT:
%    property - property name (eg 'salinity' or just 's')
%  Optional....
%    deps    - depths (in +ve m, sorted, no duplicates) of levels to extract
%    region  - [w e s n] boundaries of maps to extract
%    pth     - path to netCDF map file (including trailing slash)              
%    fname   - input file name component, if not 'cars2000'. Full name is built as
%              follows:    filename = [fullproperty '_' fname '.nc']
%                eg: property='s', fname='v1'  then filename='salinity_v1.nc'
%    opt       1= [default] return lat/lon for x,y
%              2= return grid indices (ix,iy) for x,y
%              -1 or -2: as above, but return empty args for all except mn,x,y
%  Only with special files:
%    fll       0= [default] values only where mapped - not below seafloor
%              1= values extrapolated to the coast at all depths
%
% OUTPUT:   Matlab 5   (Note: depth is the right-hand index)
%    mn     - [nlat,nlon,ndep] mean field (1/2 degree grid in [100 180 -50 0])
% Optional....
%    an     - [nlat,nlon,ndep] complex annual harmonics, [] if none available
%    sa     - [nlat,nlon,ndep] complex semiannual harmonics, "  "  "   " 
%    rq     - [nlat,nlon,ndep] data source radius (km)
%    dets   - [ndep,det_len] mapping details text strings
%                opt = 1                         opt = 2    [see 'opt' above])
%    x      - [nlat,nlon] longitudes         [nlon] map grid coords
%    y      - [nlat,nlon] latitudes          [nlat] map grid coords
%
% * If ONLY ONE DEPTH specified, 3D outputs collapse to 2D.
% * Matlab Version 4:  Output dimensions are [ndep,ngrid]
%
% Copyright (C) J R Dunn, CSIRO Marine Research
% $Id: getchunk.m,v 1.13 2006/04/20 05:31:54 dun216 Exp dun216 $
%
% Eg:  [mn,a1,a2,a3,a4,x,y]= getchunk('t',[0 10 20 50],[90 100 -40 0],[],[],-1,1);
% 
% USAGE: [mn,an,sa,rq,dets,x,y] = getchunk(property,deps,region,pth,fname,opt,fll)

function [mn,an,sa,rq,dets,x,y] = getchunk(property,deps,region,pth,fname,opt,fll)

if nargin<7 | isempty(fll)
   fll = 0;
end

if nargin<6 | isempty(opt)
  opt = 1;
end
  
if nargin<5 
   fname = [];
end
if nargin<4
   pth = [];
end

cdfile = clname(property,pth,fname);
  
if nargin<3; region=[]; end


getan = 0; an = [];
getsa = 0; sa = [];

% Check existence of any requested data

[fid,rcode] = ncmex('ncopen',[cdfile '.nc'],'nowrite');
if rcode==-1 | fid==-1
  error(['Cant open file ' cdfile]);
end

% Must allow for non-contiguous vector of depths

depths = round(getnc(cdfile,'depth'));
if nargin<2 | isempty(deps)
   deps = depths;
else
   deps = round(deps(:)');
end
ndep = length(deps);

[tmp,idin,idout] = intersect(depths,deps);
if length(idout)<ndep
   jj = 1:ndep;
   jj(idout) = [];
   disp([7 'These depths are not present in this file: ' num2str(deps(jj))]);
end
dep1 = idin(1);
depn = idin(end);
idin = 1+idin-(dep1);

if nargout > 1 & opt>=0
  % Find out at what depths these variables exist  
  varid = ncmex('ncvarid',fid,'an_cos');
  if varid == -1
     disp('No temporal info.');
  else     
     dtid = ncmex('ncdimid',fid,'depth_ann');
     pre06 = (dtid<=0);
     if pre06
	dtid = ncmex('ncdimid',fid,'depth_timefit');
     end
     [name,dtmax] = ncmex('ncdiminq',fid,dtid);
     [tmp,itin,ito1] = intersect(depths(1:dtmax),deps);
     if ~isempty(itin)
	tep1 = itin(1);
	tepn = itin(end);
	itin = 1+itin-(tep1);
	getan = 1;
	varid = ncmex('ncvarid',fid,'sa_cos');
	if nargout > 2 & varid ~= -1
	   if pre06
	      getsa = 1;
	      tep2 = tep1;
	      tepn2 = tepn;
	      ito2 = ito1;
	      itin2 = itin;	      
	   else
	      dtid = ncmex('ncdimid',fid,'depth_semiann');
	      [name,dmax2] = ncmex('ncdiminq',fid,dtid);		 
	      [tmp,itin2,ito2] = intersect(depths(1:dmax2),deps);
	      if ~isempty(itin2)
		 tep2 = itin2(1);
		 tepn2 = itin2(end);
		 itin2 = 1+itin2-(tep2);
		 getsa = 1;
	      end
	   end
	end
     end
  end
else
  rq = [];
  dets = [];
end

if ~fll
   varid = ncmex('ncvarid',fid,'grid_dep');
   if varid < 0
      fll = 1;
   end
end

ncmex('ncclose',fid);



Xg = getnc(cdfile,'lon');
Yg = getnc(cdfile,'lat');
if min(size(Xg))==1
   [Xg,Yg] = meshgrid(Xg,Yg);
end


% ----------------------------------------------------------------------
% Note that we permute order of outputs for compatibility with earlier version
% of this script (which is a pain in the bum).

if isempty(region)
   x1 = 1; y1 = 1;
   x2 = length(Xg(1,:));
   y2 = length(Yg(:,1));
else
   % Note that even for rotated grids this will find the minimum 
   % grid-rectangular area enclosing all of 'region'
   [iy,ix] = find(Yg>=region(3)& Yg<=region(4)& Xg>=region(1)& Xg<=region(2));
   y1 = min(iy); y2 = max(iy);
   x1 = min(ix); x2 = max(ix);
end

ny = 1+y2-y1;
nx = 1+x2-x1;
  

% getnc outputs are 3D unless the depth dimension is scalar.
% Get mean and shape it. DIMS is a function at the end of this file

tmp = getnc(cdfile,'mean',[dep1 y1 x1],[depn y2 x2],-1,-2,2,0,0);
if dims(tmp)==1
   mn = reshape(tmp,[ny nx]);
elseif dims(tmp)==2
   mn = tmp';
else
   mn = repmat(nan,[ny nx ndep]);
   mn(:,:,idout) = permute(tmp(:,:,idin),[2 1 3]);
end

if ~fll
   gdp = getnc(cdfile,'grid_dep',[y1 x1],[y2 x2],-1,-2,2,0,0)';   
   kk = find(gdp==0);
   gdp(kk) = -1;
   kk = find(gdp>0);
   gdp(kk) = depths(gdp(kk));
   for ii = 1:ndep
      rr = find(gdp<deps(ii));
      if ~isempty(rr)
	 tmp = mn(:,:,ii);
	 tmp(rr) = repmat(NaN,size(rr));
	 mn(:,:,ii) = tmp;
      end
   end
end
mn = squeeze(mn);

if getan
   vcos = getnc(cdfile,'an_cos',[tep1 y1 x1],[tepn y2 x2],-1,-2,2,0,0);
   vsin = getnc(cdfile,'an_sin',[tep1 y1 x1],[tepn y2 x2],-1,-2,2,0,0);
   if dims(vcos)==1
      an = reshape(vcos+vsin.*i,[ny nx]);
   elseif dims(vcos)==2
      an = vcos' + vsin'.*i;
   else
      an = repmat(nan+i*nan,[ny nx ndep]);
      %an(:,:,ito1) = permute(vcos(:,:,itin)+vsin(:,:,itin).*i,[2 1 3]);
      an = permute(vcos(:,:,itin)+vsin(:,:,itin).*i,[2 1 3]);
   end  
   if ~fll
      rr = find(isnan(mn(:,:,ito1)));
      an(rr) = NaN;
   end
   an = squeeze(an);
end

if getsa
   vcos = getnc(cdfile,'sa_cos',[tep2 y1 x1],[tepn2 y2 x2],-1,-2,2,0,0);
   vsin = getnc(cdfile,'sa_sin',[tep2 y1 x1],[tepn2 y2 x2],-1,-2,2,0,0);
   if dims(vcos)==1
      sa = reshape(vcos+vsin.*i,[ny nx]);
   elseif dims(vcos)==2
      sa = vcos' + vsin'.*i;
   else
      sa = repmat(nan+i*nan,[ny nx ndep]);
      %sa(:,:,ito2) = permute(vcos(:,:,itin2)+vsin(:,:,itin2).*i,[2 1 3]);
      sa = permute(vcos(:,:,itin2)+vsin(:,:,itin2).*i,[2 1 3]);
   end  
   if ~fll
      rr = find(isnan(mn(:,:,ito2)));
      sa(rr) = NaN;
   end
   sa = squeeze(sa);
end

if nargout>3 & opt>=0
  varid = ncmex('ncvarid',fid,'radius_q');
  if varid == -1
     rq = zeros(size(mn));
  else
     tmp = getnc(cdfile,'radius_q',[dep1 y1 x1],[depn y2 x2],-1,-2,2,0,0);
     if dims(tmp)==1
	rq = reshape(tmp,[ny nx]);
     elseif dims(tmp)==2
	rq = tmp';
     else
	rq = repmat(nan,[ny nx ndep]);
	rq(:,:,idout) = permute(tmp(:,:,idin),[2 1 3]);
     end
     rq = squeeze(rq);
  end
end
  

if nargout>4 & opt>=0
   dets = repmat(' ',[ndep 1]);
   dtid = ncmex('ncdimid',fid,'detail_string');
   if dtid > 0
      [name,dtmp] = ncmex('ncdiminq',fid,dtid);
      if dtmp > 0
	 tmp = getnc(cdfile,'map_details',[-1 dep1],[1 depn],-1,-2);
	 if dims(tmp)==1
	    tmp = tmp';
	 end
	 nx = size(tmp,2);
	 dets = repmat(' ',[ndep nx]);
	 dets(idout,:) = squeeze(tmp(idin,:));
      end
   end
end

if nargout > 5
   if abs(opt)==2
      y = y1:y2;
      x = x1:x2;
   else
      x = Xg(y1:y2,x1:x2);
      y = Yg(y1:y2,x1:x2);
   end
end

% --------------------------------------------------------------
