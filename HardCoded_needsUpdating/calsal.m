% CALSAL_CLIM  Calibrate salinity in raw (near-realtime) Argo float, and load
%         variables 's_calibrate', 'cndc_raw', 'cndc_qc', 'cndc_calibrate'
%
% INPUT  
%  float - struct array of profiles for one float. It is assumed that 
%          profiles have already been QCed.
%  ical  - index to those to be calibrated [if not supplied, will calibrate
%          all profiles after the last with a non-empty 'c_ratio' field
% OUTPUT
%   nfloat - copy of 'float', but with 's_calibrate' and all conductivity 
%            profile variables loaded.
%   cal_report    6 diagnostic values for the last profile calibrated
%         1 - "theta" (min theta of near-bottom values)
%         2 - num profile potential T values in cal range
%         3 - num reference CTDs used 
%         4 - range of c_ratio estimates [large value (>.0005?) may indicate
%             problems in profile data]
%            5,6 supplied if can calculate a calibration
%         5 - correction as applied to S value at top of cal range
%         6 - threshold: median STD(S) [plus measure of local spatial 
%             variability in clim S estimates at theta?]
%
%  NOTE:  Calculate calibration from temporary QC-ed variables, so that only
%         'good' data is used, but go back to original data when loading the
%         new profile variables (to preserve all values, irrespective of QC)
%
% AUTHOR: Jeff Dunn  CMAR Oct 2007
%         Devolved from calsal.m  Aug 2006
%
% USAGE: [nfloat,cal_report] = calsal_clim(float,ical);

function [nfloat,cal_report] = calsal_clim(float,ical)

% The CTD reference set variables are loaded once and retained thereafter 
persistent CalFilNam CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax

global ARGO_SYS_PARAM

cal_report = zeros(1,6);
dbdat=getdbase(float(end).wmo_id);
    
if isempty(CalFilNam)
   % First time here for this Matlab session, so load the CTD reference set. 
   % This name could be in sys_params file, but for now hardcode it.

      CalFilNam = ARGO_SYS_PARAM.CalFilNam 

   if ~exist([CalFilNam '.nc'],'file')
      logerr(2,['CALSAL_CLIM: cannot see T/S climatology file ' CalFilNam '.nc']);
      CalFilNam = [];
      nfloat = float;
      return
   end
   
   % Could load grid coords here, but for now rely on knowing the grid:
   CalY = getnc(CalFilNam,'lat');
   CalX = getnc(CalFilNam,'lon');
   CalY0 = CalY(1); 
   Calinc = 1/abs(diff(CalX([1 2])));
   CalPotTLev = getnc(CalFilNam,'T_level');
   CalPLmin = min(CalPotTLev);
   CalPLmax = max(CalPotTLev);   
end

cal_report = zeros(1,6);
npro = length(float);

if nargin<2 || isempty(ical)
   % If no specifed profiles to calibrate, work out which ones need it
   pr1 = 1;
   if ~isfield(float,'c_ratio')
      % If structure lacks a 'c_ratio' field then it certainly has not been 
      % calibrated.
      float(1).c_ratio = [];
      float(1).c_ratio_calc = [];
   else
      % Find first uncalibrated profile (ie with an empty 'c_ratio')
      while pr1<=npro && ~isempty(float(pr1).c_ratio)
	 pr1 = pr1+1;
      end
      if pr1>npro
	 logerr(3,['CALSAL: WMO ' num2str(float(1).wmo_id) ...
		   ' - No uncalibrated profiles for this float']);
      end
   end
   ical = pr1:npro;

elseif any(ical>npro)
   % User-specifed profiles, but some of these don't exist!
   ii = find(ical<=npro);
   ical = ical(ii);   
   logerr(3,['CALSAL: WMO ' num2str(float(1).wmo_id) ...
	     ' - some specifed profiles not found in "float"']);
end


% Do not work on any empty profiles, partly because they crash sw_ routines.
bad = zeros(size(ical));
for kk = 1:length(ical)         %ical(:)'
   fp = float(ical(kk));
   bad(kk) = isempty(fp.s_raw) || isempty(fp.t_raw) || isempty(fp.p_raw);
end
ical(find(bad)) = [];

   if(isempty(ical))
       nfloat=float;
      return
   end
for kk = ical(:)'
   fp = float(kk);
   
   % Report is provided for only the last profile processed (usually only
   % do one at a time anyway.)
   cal_report = zeros(1,6);
   
   % Note: because we have already done QC, we can apply QC to have spike-free 
   % profile with monotonicly decreasing pressure
   ss = qc_apply(fp.s_raw,fp.s_qc);
   tt = qc_apply(fp.t_raw,fp.t_qc);
   pp = qc_apply(fp.p_raw,fp.p_qc);
   pcal = qc_apply(fp.p_calibrate,fp.p_qc);
   
   cndr  = sw_cndr(ss,tt,pp);    
   pot = sw_ptmp(ss,tt,pcal,0.);
   
   % This obs-selection method is strange. In fact, I do not know why we don't 
   % just use elements 1 to 3! For now, have stuck with a theta range of .6,
   % but to the pressure criterion "pp>900" I have added "pp>(max(pp)-220"
   % (which will normally select the 3 bottom obs.)
   %
   % Profiles with large T inversions (eg at high latitudes) may have min
   % theta in near-surface waters. We want to choose a theta range that 
   % span a few of the deepest measurements, so set theta to min of bottom
   % values (elements 1 to N, since profiles stores from bottom up.)
   
   potrng = .6;
   theta = min(pot(1:min(length(pot),10)));
   if theta<CalPLmin
      theta = CalPLmin;
   elseif  theta>(CalPLmax-potrng)
      theta = CalPLmax-potrng;
   end
   
   icval = find(pot<(theta+potrng) & pp>900 & pp>max(pp)-220);

   cal_report(1) = theta;
   cal_report(2) = length(icval);
   

 
   %turn off calibration for 1901121 because of deep spikes in data:
   %and for 5901707 because it is in a bad area for calibrating.
if(fp.wmo_id==1901121 | fp.wmo_id==1901324 | fp.wmo_id==1901321 | fp.wmo_id==5901707 |fp.wmo_id==5901706 )
    calibrate=0;
    %and turn off calibration for these floats because they are in salty
    %water that's triggering calibration wihtout valid cause:
elseif fp.lat < -65
    calibrate=0;
elseif dbdat.RBR   % turn off calibration for these because they're experimental
    calibrate=0;
else 
    if(isempty(fp.surfpres))
   calibrate = (~isempty(icval) && ...
		fp.lat(1)>CalY0 && fp.lat(1)<CalY(end) && fp.lon(1)<360);
    else
   calibrate = (fp.surfpres(1)<100 && ~isempty(icval) && ...
		fp.lat(1)>CalY0 && fp.lat(1)<CalY(end) && fp.lon(1)<360);
    end
end

   if calibrate
      % First interp theta levels
      icl = interp1(CalPotTLev,1:length(CalPotTLev),pot(icval));
      iclf = floor(icl);
      iclm = icl-iclf;
      ilvs = min(iclf):ceil(max(icl));
	 
      % Extract 4 nearest TS clim profiles
      icx = floor(1 + fp.lon(1)*Calinc);
      icy = floor(1 + (fp.lat(1)-CalY0)*Calinc);

      climS = getnc(CalFilNam,'mean',[-1 icy icx],[-1 icy+1 icx+1]);

      % Spatial interp to location for each T level
      avclS(ilvs) = nan;
      for ij = ilvs
	 isgd = ~isnan(climS(ij,:,:));
	 if all(isgd(:))
	    avclS(ij) = interp2(CalX([icx icx+1]),CalY([icy icy+1]),...
				squeeze(climS(ij,:,:)),fp.lon(1),fp.lat(1));
	 end
      end
      
      % Get range of S values in the middle theta level used (to be used
      % later to adjust the need-to-calibrate threshold)
      srep = climS(round(mean(ilvs)),:,:);
      srng = max(srep(:))-min(srep(:));
      if isnan(srng); srng = 0; end
      
      % Now interp between theta levels
      dclimS = diff(avclS);
      calS = avclS(iclf) + dclimS(iclf).*iclm;
      if any(isnan(calS))
	 % If NaNs in climS prevent interpolation, try substituting with
	 % nearest value. [Arguably should not do this ??]
	 miss = isnan(calS);
	 calS(miss) = avclS(round(icl(miss)));
      end
      
      if any(isnan(calS))
	 % Lost some values due to NaNs. Try just nearest grid point (ie no
	 % spatial interp) to maybe retrieve some values.
	 icx = 1 + round(fp.lon(1)*Calinc);
	 icy = 1 + round((fp.lat(1) - CalY0)*Calinc);

	 climS = getnc(CalFilNam,'mean',[-1 icy icx],[-1 icy icx])';
	 dclimS = diff(climS);
	 calS2 = climS(iclf) + dclimS(iclf).*iclm;
	 if any(isnan(calS2))
	    miss = isnan(calS2);
	    calS2(miss) = climS(round(icl(miss)));
	 end
	    
	 extra = (isnan(calS) & ~isnan(calS2));
	 if any(extra)
	    calS(extra) = calS2(extra);
	 end
      end	    
      cal_report(3) = sum(~isnan(calS));
   
      calibrate = (cal_report(3)>0);
   end
      
   if calibrate
      jcal = find(~isnan(calS));
      calS = calS(jcal);
      im = icval(jcal);
      
      % If we used all neighbouring T/S clim profiles then median stats would
      % mainly choose from the variability in the clim. Assuming using single
      % *accurate* clim profile then we probably should just compare with
      % single (deepest) Argo value. However, keep median stats for now, using
      % it to allow for small-scale errors in individual Argo measurements. 
      % This rationale is definitely open to review!
      
      fp.deltaS = median(calS-ss(im));
      
      tmp = sw_cndr(calS,tt(im),pp(im))./cndr(im);
      cal_report(4) = max(tmp)-min(tmp);

      fp.c_ratio_calc = median(tmp(~isnan(tmp)));
      fp.c_ratio = fp.c_ratio_calc;
      
      stmp = sw_salt(cndr*fp.c_ratio,tt,pcal);
      
      climSD = getnc(CalFilNam,'sd',[-1 icy icx],[-1 icy icx])';
      dclimS = diff(climSD);
      calSD = climSD(iclf) + dclimS(iclf).*iclm;
      calSD = mean(calSD(~isnan(calSD)));
      
      % If correction is small relative to variability then do NOT apply the 
      % calibration. 
      %   Try inflating data SD by adding a measure of local spatial 
      % variability in T/S clim. Very open to debate!
      if round(Calinc)==1
	 calSD = calSD + (srng/2);
      else
	 calSD = calSD + srng;
      end
      if mean(ss(im)-stmp(im))<=calSD
	 % Decide that calibration not needed (except to take account of
	 % pressure correction)
	 fp.c_ratio = 1;
      end
      cal_report(5:6) = [mean(ss(im)-stmp(im)) calSD];
	    
   elseif kk>1 && ~isempty(float(kk-1).c_ratio)
      % We can use the calibration derived for the previous profile
      % (although that may be just 1, allocated when that previous one 
      % couldn't be calibrated.)  
      fp.c_ratio = float(kk-1).c_ratio;
      fp.deltaS = float(kk-1).deltaS;
      
   else 
      % Can't calibrate, and no previous value to use.
      fp.c_ratio = 1.;
      fp.deltaS = [];
   end

   % Now apply calibration to unscreened profiles, to retain values despite
   % QC flagging.
   cndr  = sw_cndr(fp.s_raw,fp.t_raw,fp.p_raw);    
   fp.cndc_raw  = cndr*sw_c3515;
   fp.cndc_calibrate  = cndr*fp.c_ratio*sw_c3515;
   fp.s_calibrate = sw_salt(cndr*fp.c_ratio,fp.t_raw,fp.p_calibrate);

   % Creating the cndc_qc variable is messy! Conductivity should be flagged
   % bad if S or T is bad, or if it they are good but cndc still comes out
   % as NaN.    Presently no prescribed treatment of this (I think).
   
   if ~isempty(fp.cndc_raw) && (~isfield(fp,'cndc_qc') || isempty(fp.cndc_qc))
      fp.cndc_qc = fp.s_qc;
      sbad = ismember(fp.s_qc,[3 4 6 7 8 9]);
      tbad = ismember(fp.t_qc,[3 4 6 7 8 9]);
      jj = find(tbad & ~sbad);
      fp.cndc_qc(jj) = fp.t_qc(jj);
      
      cbad = ismember(fp.cndc_qc,[3 4 6 7 8 9]);      
      jj = find(~cbad & isnan(fp.cndc_raw));      
      fp.cndc_qc(jj) = 9;
   end
   
   % We have made a new s_calibrate, which is not Thermal Lag corrected, so
   % clear the TL flag (it would be 0 anyway, unless we are repeating steps)
   fp.TL_cal_done = 0;
   
   % trap for missing T or P that still has S yet results in nan S in
   % calibrated variable
   gg=find(isnan(fp.s_calibrate) & fp.s_qc~=9);
   if ~isempty(gg)
       fp.s_qc(gg)=4;
   end
   

   % Load this profile back into float array
   float(kk) = fp;
end

nfloat = float;

%---------------------------------------------------------------------------
