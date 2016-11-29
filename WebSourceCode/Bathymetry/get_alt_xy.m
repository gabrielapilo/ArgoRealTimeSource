% GET_ALT_XY: Return altimeter data (interpolated in space and time from
%  AVISO 1/4 deg, 10 day, gridded dataset) at given locations and times. 
%
% SEE ALSO   get_alt_xy_nrt.m  for access to locally mapped fields
%
% TEMPORAL COVERAGE:  1992? - Feb 2002
% 
% INPUT
%  x,y  - vector or matrices of locations
%  tim  - Unix time of required data; eg greg2time([2001 12 31 0 0 0]).
%         Either single or one for every location.
%  thr  - [optional] Maximum % error threshold - applied to the "quadratic
%         mapping error". If omitted, no restriction applied. (Applied after
%         also interpolating error fields to the x-y locations, rather than
%         using this to screen the original gridded altimeter fields prior
%         to interp "alt" values.)
%  opt  - Dataset to use. As at 24/3/04 we have
%       1  tp-ers:  10-day, .25 deg, 80.12 to 179.88 E, -80.88S to 14.88N.
%          1992 to late 2001
%       2  tp_ers_msla_global: 7-day Global (81S-81N) 1 deg lon, lat 1 deg
%          at Eq, to ~.14 deg at 81S/N.  1992 - Feb 2004   [DEFAULT]
%       3  tp_ers_msla_aus: 7-day 1/3 deg 80-180E,  lat 1/3 deg at Eq, 
%          ~.05 deg at 82S, range 82S to 14.74N.   1992 - Feb 2004
%       4  tp_ers_msla_south_indian: 7-day 1/3 deg 0-165E, lat .31 @ 20S to
%          .17 @ 60S. 1992 - Feb 2004 
%       5  tp_ers_msla_south_pacific: 7-day 1/3 deg 0-165E, lat .31 @ 20S to
%          .17 @ 60S. 22/10/1992 - 28/1/2004 
% OUTPUT
%  alt  - alt at x,y,t locations (nan where no data available)
%  dset - datasets used (0=no data within 10 days, 1=Topex only, 2=T/P+ERS)
%         (lesser dataset of the 2 straddling timeslices)
%         ***22/2/06 Temporarily disabled***
%  err  - raw error fields (as a %) (max of the 2 straddling timeslices)
%
% Jeff Dunn  CSIRO CMR 5/4/02  
%
% MODS:  22/2/06 New files do not have variable Alt_flag, so reading it is
%        now disabled.
%
% USAGE: [alt,dset,aerr] = get_alt_xy(x,y,tim,thr,opt);

function [alt,dset,aerr] = get_alt_xy(x,y,tim,thr,opt)

% Mods: 24/3/04  Allow for datasets 2-4

if nargin<5 | isempty(opt)
   opt = 2;
end

if nargin<4
   thr = [];
end
geterr = (nargout>2 | ~isempty(thr));

if max(size(tim))==1
   tim = repmat(tim,size(x));
end

% Create output variables and set up loop control
alt = repmat(nan,size(x));
aerr = repmat(nan,size(x));
%dset = zeros(size(x));
dset = repmat(nan,size(x));

apth = platform_path('argo','altdata/com_alt/tp-ers-msla/');
switch opt
  case 1
    % Get Neil's (AVISO?) 10-day, .25-degree gridded dataset, 80.12 to 179.88 E,
    % -80.88S to 14.88N.  [Jan 2002]  10 day interval
    infl = [apth 'tp-ers'];
    tim0 = greg2time([1992 10 22 0 0 0]);
    ming = .26;
    nda = 10;
  case 2
    %  Global ~1 degree: 1 deg lon; lat 1 deg at Eq, to ~.14 deg at 81S/N.
    % [Mar 2004]  7 day interval
    infl = [apth 'tp_ers_msla_global'];
    tim0 = greg2time([1992 10 14 0 0 0]);
    ming = 1.1;
    nda = 7;
  case 3
    %  ~1/3 deg Aus: 1/3 deg 80 - 180E,  lat 1/3 deg at Eq, ~.05 deg at 82S,
    %  range 82S to 14.74N  [Mar 2004]  7 day interval
    infl = [apth 'tp_ers_msla_aus'];
    tim0 = greg2time([1992 10 14 0 0 0]);
    ming = .34;
    nda = 7;
  case 4
    %  ~1/3 deg South Indian: 1/3 deg 0 - 165E,  lat .31 @ 20S to .17 @ 60S.
    %  [Mar 2004]  7 day interval
    infl = [apth 'tp_ers_msla_south_indian'];
    tim0 = greg2time([1992 10 14 0 0 0]);
    ming = .34;
    nda = 7;
  case 5
    %  ~1/3 deg South Pacific: 125-300E, 60S-14.74N, lat .33 @ Eq - .17 @ 60S.
    %  [Dec 2004]  7 day interval
    infl = [apth 'tp_ers_msla_south_pacific'];
    tim0 = greg2time([1992 10 14 0 0 0]);
    ming = .34;
    nda = 7;
  otherwise
    error(['Do not know option ' num2str(opt)]);
end

% 22/2/06 This missing from some files, so disable read to prevent crash
%  aflg = getnc(infl,'Alt_flag');

lo = getnc(infl,'lon');
la = getnc(infl,'lat');
atim = getnc(infl,'time');
atim = atim+tim0;
ntim = length(atim);
atim(end) = atim(end)+.0001;   %little fudge in case requested date falls on
                               %the last day of data. 

for ii = 1:(ntim-1)
   jj = find(tim>=atim(ii) & tim<atim(ii+1));

   if ~isempty(jj)
      % Extract a minimum rectangle and interpolate height and error values
      ix = find(lo>(min(x(jj))-ming) & lo<max(x(jj))+ming);
      iy = find(la>(min(y(jj))-ming) & la<max(y(jj))+ming);

      if length(ix)>1 & length(iy)>1
	 % then we must be inside the region covered, and so can do a 3D interp.
	 hgt = getnc(infl,'height',[ii iy(1) ix(1)],[ii+1 iy(end) ix(end)]);
	 tjj = tim(jj)-atim(ii);
	 alt(jj) = interp3(lo(ix),la(iy),[0 nda],shiftdim(hgt,1),x(jj),y(jj),tjj);

	 %dset(jj) = repmat(min(aflg([ii ii+1])),size(jj));

	 if geterr
	    err = getnc(infl,'mapping_error',[ii iy(1) ix(1)],[ii+1 iy(end) ix(end)]);
	    err = squeeze(max(shiftdim(err,1),[],3));
	    aerr(jj) = interp2(lo(ix),la(iy),err,x(jj),y(jj));
	 end
      end
   end
end
   
% If screening, nan results where interpolated errors to high
% We screen after interpolation because if we screened initially to put nans 
% in the gridded fields, then each nan infects all interpolation between it
% and its 8 neighbours - which is pretty severe!

if ~isempty(thr)
   jj = find(aerr>thr);
   alt(jj) = repmat(nan,size(jj));
end

%---------------------------------------------------------------------------
