% GET_SST_XYT  Interpolate data to given times and locations from the 2004
%   4km Stitched SST Archive. Note: only actually interpolates for 15-day 
%   composites as these are at 6-day spacing. 10-day composites are at 2-day
%   spacing, and all the rest at 1-day, so we just take nearest time slice
%   for all of these.
%
% NOTE:  Uses Matlab interp functions which give a Nan if any adjacent 
%        input value is Nan, so data recovery rates can be poor for
%        small-window composites.
%
%  See also GET_SST, which returns SST dataset grid in given region, and
%  GET_SST_XY, which interpolates in space but evaluates all points at just
%  one time value.
%
% INPUT
%  x,y  - vector or matrices of locations
%  tim  - Unix time for each location (can use greg2time)
%  itper- single code for composite time-window size:
%        1=1   2=3  3=6day  4=10day  5=15day
%
% OUTPUT
%  sst  - SST at x,y locations (nan where no data available)
%
% SEE ALSO: ~ridgway/matlab/altim/get_sstPW_xyt.m  for access to "Patchwork"
%
% SEE http://www.marine.csiro.au/remotesensing/oceancurrents/  OR
%     http://www.marine.csiro.au/eez_data/doc/sst_datasets.html
%
% Jeff Dunn  CSIRO CMR 10/6/04 
%
% USAGE: sst = get_sst_xyt(x,y,tim,itper)

function sst = get_sst_xyt(x,y,tim,itper)

sst = repmat(nan,size(x));

t70 = greg2time([1970 1 1 0 0 0]);
tperiod = [1 3 6 10 15];

tper = tperiod(itper);

fnm = platform_path('rsj','imgjj/sensor/avhrr/sstcr04/yearfiles/');
fnm = [fnm 'SSTcomp' num2str(tper) 'd_Aasia_'];

la = getnc([fnm '1994'],'lat');
lo = getnc([fnm '1994'],'lon');

kk = find(x>min(lo) & x<max(lo) & y>min(la) & y<max(la));

% x spacing .042 degree, y .036 degree, y stored in descending order!
nlo = length(lo);
ix = 1+(x-min(lo))./.042;
nla = length(la);
iy = nla+1-((y-min(la))./.036);

stim = t70 + [8674.5 8675.5 8677 8680 8681.5];
etim = t70 + [12216.5 12215.5 12214 12212 12209.5];
    

for iyr = 1993:2003
   if iyr == 1993
      t0 = stim(itper);
   else
      t0 = greg2time([iyr 1 1 0 0 0]);
   end
   if iyr == 2003
      t1 = etim(itper);
   else
      t1 = greg2time([iyr+1 1 1 0 0 0]);
   end

   jj = find(tim(kk)>=t0 & tim(kk)<t1);

   if ~isempty(jj)
      kj = kk(jj);

      ftim = getnc([fnm num2str(iyr)],'time');
      ntim = length(ftim);
      tdel = ftim(2)-ftim(1);
      
      if tper == 15 
	 % 15 day window composites at 6 day spacings: interpolate time

	 itm = 1+((tim(kj)-(ftim(1)+t70))./tdel);

	 for ll = floor(min(itm)):ceil(max(itm))
	    mm = find(itm>=ll & itm<ll+1);
	    if ~isempty(mm)
	       kjm = kj(mm);
	       ys = iy(kjm);
	       xs = ix(kjm);
	       x0 = floor(min(xs));
	       y0 = floor(min(ys));
	       x1 = min([nlo ceil(max(ix(kjm)))]);
	       y1 = min([nla ceil(max(iy(kjm)))]);
	       crn1 = [ll y0 x0];
	       crn2 = [ll+1 y1 x1];

	       if ll==0 & iyr==1993
		  % Cannot do anything here - no previous data
	       elseif ll==ntim & iyr==2003
		  % Cannot do anything here - beyond end of data
	       else
		  if ll==0
		     % Times in gap between this and preceding file
		     tmp = getnc([fnm num2str(iyr-1)],'time');
		     nn = length(tmp);
		     crn1(1) = nn;
		     crn2(1) = nn;
		     ssin = getnc([fnm num2str(iyr-1)],'sst',crn1,crn2);
		     crn1(1) = 1;
		     crn2(1) = 1;
		     ssin = cat(3,ssin,getnc([fnm num2str(iyr)],'sst',crn1,crn2));
		  elseif ll==ntim
		     % Times in gap between this and following file
		     crn1(1) = ntim;
		     crn2(1) = ntim;
		     ssin = getnc([fnm num2str(iyr)],'sst',crn1,crn2);
		     crn1(1) = 1;
		     crn2(1) = 1;
		     ssin = cat(3,ssin,getnc([fnm num2str(iyr+1)],'sst',crn1,crn2));
		  else
		     ssin = getnc([fnm num2str(iyr)],'sst',crn1,crn2);
		  end
		  ssin = shiftdim(ssin,2);
		  sst(kjm) = interp3(ssin,1+rem(itm(mm),1),1+xs-x0,1+ys-y0);
	       end
	    end	       
	 end
	 
      else
	 % 1 or 2 day spaced estimates - just select nearest time slice.
	 
	 itm = 1+round((tim(kj)-(ftim(1)+t70))./tdel);
	 ii = find(itm>ntim);
	 itm(ii) = ntim;
	 ii = find(itm<1);
	 itm(ii) = 1;
	 
	 for ll = min(itm):max(itm)
	    mm = find(itm==ll);
	    if ~isempty(mm)
	       kjm = kj(mm);
	       ys = iy(kjm);
	       xs = ix(kjm);
	       x0 = max([1 floor(min(xs))]);
	       y0 = max([1 floor(min(ys))]);
	       x1 = min([nlo ceil(max(ix(kjm)))]);
	       y1 = min([nla ceil(max(iy(kjm)))]);
	       crn1 = [ll y0 x0];
	       crn2 = [ll y1 x1];

	       ssin = getnc([fnm num2str(iyr)],'sst',crn1,crn2);

	       sst(kjm) = interp2(ssin,1+xs-x0,1+ys-y0);
	    end
	 end
      end
      
      kk(jj) = [];
   end
end      

%---------------------------------------------------------------------------
