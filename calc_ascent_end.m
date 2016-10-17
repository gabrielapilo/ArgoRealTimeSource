% CALC_ASCENT_END  Calculate Ascent End time - method differs according
%    to make of float.
%
% INPUT  b1t    - Block1 time info (b1tim.dat)
%        maxblk - number of blocks in profile message
%        dbdat  - db record for this float
%        fp     - profile structure
%        verbose - 1=dump descriptive stuff
%                  0=shut up   [default]
%
% OUTPUT jae  - estimate julian day ascent end time. 
%
% AUTHOR: Jeff Dunn  CMAR/BoM Oct 2006
%
% USAGE: jae = calc_ascent_end(b1t,maxblk,dbdat,fp,verbose);

function jae = calc_ascent_end(b1t,maxblk,dbdat,fp,verbose)

jae = [];

if nargin<5 || isempty(verbose)
   verbose = 0;
end

if dbdat.maker==1
   % Estimate the time at which the float surfaced (for Webb only)
   gd = find(all(~isnan(b1t')));
   if ~isempty(gd) && maxblk>0
      % First sort according to date
      jdb1 = julian(b1t(gd,2:7));
      [jdb1,isrt] = sort(jdb1);      
      nmsg = b1t(isrt,1);   % Message number since start of transmit 
      
      % Time since surfacing should be:
      % nmsg X (num blocks sent so far) X (reprate converted to days)
      % So estimate time_of_trans - time_since_surfacing:  
      % This can be wrong if bad times, msg nos, or maxblk (the last
      % results in a trend in estimates, linear with nmsg)
      st_ests = jdb1 - (nmsg-1)*maxblk*dbdat.reprate/86400;
	 
      jae = median(st_ests);
      % Revert to jday(1) if this estimates is impossibile, ie ascent time 
      % after first transmit time or more than a few hours before it.
      if jae > fp.jday(1) || jae < fp.jday(1)-.5
	 if max(st_ests)-min(st_ests) > .05
	    logerr(3,'Revert to earliest jday(1) - bad ascent_end estimate');
	    jae = fp.jday(1);
	 else
	    logerr(3,['Suss jday(1)? Conflicts with consistent ascent_end_time estimates']);
	 end
      end

      if verbose
	 fprintf(1,'JAE est: min=%10.2f  median=%10.2f  max=%10.2f  j1=%10.2f\n',... 
		 min(st_ests),median(st_ests),max(st_ests),fp.jday(1));
	 fprintf(1,'JAE median: %s       Jday(1): %s\n',...
		 datestr(gregorian(median(st_ests))),datestr(gregorian(fp.jday(1))));
	 fprintf(1,'\n Estimate   nmsg    B1 tim   (maxblk %d  reprate %d)\n',...
		 maxblk,dbdat.reprate);
	 for ii = 1:length(st_ests)	 
	    dv = gregorian(st_ests(ii));
	    fprintf(1,'%2d %2d:%2d     %3d    %2d %2d:%2d\n',...
		    dv(3:5),b1t(ii,[1 4 5 6]));
	 end   
      end
   end	    

else
   % Provor floats give us the AE, but as hours in a day. But is their clock
   % synch-ed with satellite UTC?? See how it goes....
   if isempty(fp.resurf_endtime) || isempty(fp.jday)
      % can't do much here then
   else
      % Julian days start at 12 noon - so this calc becomes a bit tricky.
      % We have to allow for 24hr wrap!
      jhrs = 24*rem(fp.jday(1)-.5,1);
      hdel = jhrs-fp.resurf_endtime;
      if hdel>0
	 if hdel>8
	    % Greater than 8 hours difference - seems implausible
	    logerr(3,['CALC_ASCENT_END: hdel=' num2str(hdel) ' - using jday(1)']);
	    jae = fp.jday(1);
	 else
	    jae = fp.jday(1)-hdel/24;
	 end
      elseif jhrs<3 & fp.resurf_endtime>21
         % Assume that surfaced before midnight, first fix after midnight
	 jae = fp.jday(1) - (hdel+24)/24;
      end
   
      if verbose
	 fprintf(1,'Provor: RESURF %3.1f  JDAY1 %3.1f\n',fp.resurf_endtime,jhrs);
	 fprintf(1,'JAE %s  JDAY1 %s\n',datestr(gregorian(jae)),...
		 datestr(gregorian(fp.jday(1))));
      end
   end
end

%----------------------------------------------------------------------------
