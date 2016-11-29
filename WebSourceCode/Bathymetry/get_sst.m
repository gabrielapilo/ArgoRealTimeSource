% GET_SST  Get SST in a region at full resolution, for a single time or
%   time period, from any of the "NOO Decade of SST" datasets. Note that this
%   does NOT interpolate to the time - just uses the nearest composite(s).
%
%  See also GET_SST_XYT and GET_SST_XY
%
% INPUT
%  tim  - Unix time or time range (can use greg2time). Note: file times are
%         midday - ie day n.5 
%  itper- single code for composite time-window size:
%        1=1   2=3  3=6day  4=10day  5=15day
%  region - [w e s n]
%
% OUTPUT
%  sst  - SST  [time y x]
%  estim - estimate times  
%  x,y  - estimate locations
%
% SEE http://www.marine.csiro.au/eez_data/doc/sst_datasets.html   and 
%     http://www.marine.csiro.au/remotesensing/oceancurrents/
%
% Jeff Dunn  CSIRO CMR 15/6/04 
%
% USAGE: [sst,estim,x,y] = get_sst(tim,itper,region)

function [sst,estim,x,y] = get_sst(tim,itper,region)

% MODS: 13/12/04  Add "tnear" code to choose the nearest timeslice if asking 
% for a single time, but it straddles two years.

onetim = (length(tim)==1);
if onetim
   tim = [tim tim];
end

t70 = greg2time([1970 1 1 0 0 0]);
tperiod = [1 3 6 10 15];
tper = tperiod(itper);


fnm = platform_path('rsj','imgjj/sensor/avhrr/sstcr04/yearfiles/');
fnm = [fnm 'SSTcomp' num2str(tper) 'd_Aasia_'];

la = getnc([fnm '1994'],'lat');
lo = getnc([fnm '1994'],'lon');

ix = find(lo>=region(1) & lo<=region(2));
jx = [max([ix(1)-1 1]) min([ix(end)+1 length(lo)])];
iy = find(la>=region(3) & la<=region(4));
jy = [max([iy(1)-1 1]) min([iy(end)+1 length(la)])];

x = lo(jx(1):jx(2));
y = la(jy(1):jy(2));

stim = t70 + [8674.5 8675.5 8677 8680 8681.5];
etim = t70 + [12216.5 12215.5 12214 12212 12209.5];
    
sst = [];
estim = [];
tnear1 = [];

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

   if tim(1)<=t1 & tim(2)>=t0
      ftim = getnc([fnm num2str(iyr)],'time') + t70;
      if onetim
	 [tnear,kj] = min(abs(ftim-tim(1)));
      else
	 kj = find(ftim>=tim(1) & ftim<=tim(2));
      end
      if ~isempty(kj)
	 ssin = getnc([fnm num2str(iyr)],'sst',[kj(1) jy(1) jx(1)],...
				    [kj(end) jy(2) jx(2)]);
	 if onetim
	    % If just onetime might still select two slices if get one from
            % end of one year and another from start of next. Use this code
            % to choose closer timeslice.	    
	    if isempty(tnear1)
	       tnear1 = tnear;
	       sst = ssin;
	       estim = [estim; ftim(kj)];
	    elseif tnear<tnear1
	       sst = ssin;
	       estim = [estim; ftim(kj)];
	    end
	 else
	    if dims(ssin)==2
	       ssin = shiftdim(ssin,-1);
	    end
	    sst = cat(1,sst,ssin);
	    estim = [estim; ftim(kj)];
	 end
      end
   end      
end

%---------------------------------------------------------------------------
