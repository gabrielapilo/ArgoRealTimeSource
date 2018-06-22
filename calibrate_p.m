% CALIBRATE_P   Calibrate pressure 
%
% INPUT  fpp - struct array of profiles for one float.
%        ll  - profile to calibrate [default - the last one]
%
% OUTPUT fpp - with p_calibrate field loaded, and for Webb floats,
%              the .surfpres_used and .surfpres_qc fields loaded.
%
% AUTHOR: Jeff Dunn  CMAR/BoM Oct 2006
%
% MOD: JRD 17/5/2013  Allow for non-surfacing Iridium floats
%
% USAGE: fpp = calibrate_p(fpp,ll);

function fpp = calibrate_p(fpp,ll)

if nargin<2 | isempty(ll)
   ll = length(fpp);
elseif ll>length(fpp)
   logerr(2,'CALIBRATE_P:  ll > length(fpp)');
   ll = length(fpp);
end

if fpp(ll).maker==2
   % --- Martec Provor float   
   %DEV: presumably this is correct??
   if fpp(ll).subtype==4 % Provor CTS3 floats autocorrect
       fpp(ll).p_calibrate = fpp(ll).p_raw;
       if isfield(fpp,'p_desc_raw')
           fpp(ll).p_desc_calibrate = fpp(ll).p_desc_raw;
       end
   else
       fpp(ll).p_calibrate = fpp(ll).p_raw - fpp(ll).pres_offset;
   end
elseif fpp(ll).maker==3 | fpp(ll).maker==5
    %do nothing - pressure adjusted on board
   fpp(ll).p_calibrate = fpp(ll).p_raw;
else
   % --- Webb float
   %   .surfpres_qc will end up set to the value of pqc
   %   pqc can have values:
   %     2 - previous Iridium profile did not surface so using last good value
   %     1 - temporary value indicates large diff to previous surf P
   %     0 - good 
   %    -1 - decide surf P is bad, after detecting a large diff to previous P
   %    -2 - previous profile missed or did not surface, therefore suspect surf P
   %    -3 - surf P > 100
   %
   %  If pqc<0 then correct P with:
   %    - a weighted mean of up to 5 previous good values (if any available)
   %      (the number and weights of values is just a first guess - JRD)  
   %    - no correction, if no previous good values      
      
   
   pqc = 0;
   
   if fpp(ll).subtype==1004 && ll>1 && ~isempty(fpp(ll-1).position_accuracy) && ...
            strcmp(fpp(ll-1).position_accuracy,'8')
      % Iridium and previous profile location interpolated, implying it did not
      % surface, so reported surfpres will actually be below surface. We should
      % then use the SP reported on the first non-surfacing profile since that
      % relates to the preceding surfacing profile.  It appears that 
      % ice-detecting floats will recognise this and set surfpres to last good 
      % value, so the code below is only needed other floats.    JRD 17/5/2013
      lastgd = [];
      for ij = 1:ll-2
          if ~isempty(fpp(ij+1).surfpres_qc)
	 if strcmp(fpp(ij).position_accuracy,'G') && fpp(ij+1).surfpres_qc==0
	    lastgd = ij+1;
     end
          end
      end

      if ~isempty(lastgd)
	 newval = fpp(lastgd).surfpres_used;
	 pqc = 2;
	 logerr(3,'CALIBRATE_P: Previous prof did not surface - using last good SP');
      else
	 pqc = -2;
	 logerr(3,['CALIBRATE_P: Previous prof did not surface and no good' ...
		   ' previous SP']);
    
       end
      
   elseif isempty(fpp(ll).surfpres) || fpp(ll).surfpres(1) > 10 || isnan(fpp(ll).surfpres(1))
      pqc = -3;
      logerr(3,['CALIBRATE_P: Bad surf P: ' num2str(fpp(ll).surfpres)]); 
      % use surface pressure from last valid transmission:
      if(ll>1)
          if(~isnan(fpp(ll-1).surfpres_used) & ~isempty(fpp(ll-1).surfpres_used))
              pqc=1;
              fpp(ll).surfpres_used = fpp(ll-1).surfpres_used;
          end
      end
   elseif ll>1  
      if isempty(fpp(ll-1).jday) | abs(fpp(ll).jday(1)-fpp(ll-1).jday(1)) > 15 | ...
	     fpp(ll).profile_number-fpp(ll-1).profile_number > 1
	 % Previous profile was missed - maybe got stuck at depth - so 
	 % its surfpres would be bad
	 pqc = -2;
	 logerr(3,'CALIBRATE_P: Missed previous profile - assume bad surf P');
      end
   end
   

   if pqc~=0 && pqc~=2
      % Bad or suspect value. 
      % Collect the previous 5 values (if available)
      n0 = min([6 ll]) - 1;
      pstat = nan(1,n0);
      psurf = nan(1,n0);
      for ii = 1:n0
	 if isempty(fpp(ll-ii).surfpres_used)
	    pstat(ii) = -1;
	 else
	    psurf(ii) = fpp(ll-ii).surfpres_used;
	    pstat(ii) = fpp(ll-ii).surfpres_qc;
	 end
      end

      ngd = find(pstat==0);
      if ~isempty(ngd)
	 % If there are some previous good values, calculate a mean of these,
	 % but weighted towards the most recent values.
	 jw = n0+1-ngd;
	 newval = sum(psurf(ngd).*jw)./sum(jw);
      else
	 % No recent good values - so must apply zero correction
	 newval = 0;
      end
      
      if pqc==1
	 if isempty(ngd)
	    pqc = 1;
	    logerr(3,['CALIBRATE_P: Surf P > 10 diff to previous value - ' ...
		      'and no recent good values to compare. Flag as Bad, ' ...
		      ' but CHECK as may be first GOOD value!']);	    
	 elseif abs(fpp(ll).surfpres - newval) < 10
	    % Difference between present and mean values is small, so maybe
	    % previous value was the bad one??
	    pqc = 0;
	    logerr(3,['CALIBRATE_P: Surf P > 10 diff to previous value - ' ...
		      ' Good compared to previous good values']);
	 else
	    pqc = -1;
	    logerr(3,['CALIBRATE_P: Surf P > 10 diff to previous value - ' ...
		   ' Bad compared to previous good values']);
	 end
      end      
   end

   if pqc~=0
      fpp(ll).surfpres_used = newval;
      fpp(ll).surfpres_qc = pqc;
   else
      fpp(ll).surfpres_used = fpp(ll).surfpres(end);
      fpp(ll).surfpres_qc = 0;
   end      
   
   fpp(ll).p_calibrate = fpp(ll).p_raw - fpp(ll).surfpres_used;
end

%---------------------------------------------------------------------------
