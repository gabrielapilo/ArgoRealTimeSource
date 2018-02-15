% QC_TESTS Apply the prescribed QC tests for realtime Argo profiles.
%
%  Reference: Argo quality control manual Version 2.1 (30/11/2006)
%
%  NOTE: Do not transmit profile if fails tests 2 3 4cp  or 13. For all other
%        failures, can transmit profiles, but with bad parts flagged.
%
% INPUT 
%  dbdat - master database record for this float
%  fpin  - float struct array
%  ipf   - [optional] index to profiles to QC (default: QC all profiles)
%
% OUTPUT 
%  fpp   - fpin, but with QC record fields updated. 
%
% Author:  Jeff Dunn CSIRO/BoM  Aug 2006
%
%  Devolved from QCtestV2.m (Ann Thresher ?)
%
% USAGE: fpp = qc_tests(dbdat,fpin,ipf)

function fpp = qc_tests(dbdat,fpin,ipf)

if nargin<3 || isempty(ipf)
   ipf = 1:length(fpin);
end
clear fp
fpp = fpin;

% Note: Flags are set according to Ref Table 2 and sec 2.1 of the manual. 
% The flag value is not allowed to be reduced - eg if already set to 4, must 
% not override to 3. This is implemented in the algorithms below.

% Work through each required profile

for ii = ipf(:)'
   fp = fpp(ii);
   
   % Initialise QC variables where needed:
   %  0 = no QC done
   %  1 = good value
   %  9 = missing value
   % first, get trap for missing profiles:
   
   if isempty(fp.p_raw) & isempty(fp.s_raw) & isempty(fp.t_raw)
        logerr(3,['FLOAT WITH NO DATA...:' num2str(dbdat.wmo_id) ' np=' num2str(fp.profile_number)]);
if isfield(fp,'p_oxygen') & ~isempty(fp.p_oxygen)
    
else
        return
end
   end

   
   if  ~isempty(fp.p_raw)
      fp.p_qc = ones(size(fp.p_raw),'uint16');
      jj = find(isnan(fp.p_raw));
      fp.p_qc(jj) = 9;
   end
   if  ~isempty(fp.t_raw)
      fp.t_qc = ones(size(fp.t_raw),'uint16');
      jj = find(isnan(fp.t_raw));
      fp.t_qc(jj) = 9;
   end
   if  ~isempty(fp.s_raw)
      fp.s_qc = ones(size(fp.s_raw),'uint16');
      jj = find(isnan(fp.s_raw));
      fp.s_qc(jj) = 9;
   end
   if isfield(fp,'cndc_raw')
      if  ~isempty(fp.cndc_raw)
	 fp.cndc_qc = ones(size(fp.cndc_raw),'uint16');
	 jj = find(isnan(fp.cndc_raw));
	 fp.cndc_qc(jj) = 9;
      end
   end
   if isfield(fp,'oxy_raw')
      if  ~isempty(fp.oxy_raw)
	 fp.oxy_qc = ones(size(fp.oxy_raw),'uint16');
	 jj = find(isnan(fp.oxy_raw));
	 fp.oxy_qc(jj) = 9;
      end
   end
   if isfield(fp,'oxyT_raw')
      if  ~isempty(fp.oxyT_raw)
	 fp.oxyT_qc = ones(size(fp.oxyT_raw),'uint16');
	 jj = find(isnan(fp.oxyT_raw));
	 fp.oxyT_qc(jj) = 9;
      end
   end
   if isfield(fp,'tm_counts')
      if ~isempty(fp.tm_counts)
	 fp.tm_qc = zeros(size(fp.tm_counts),'uint16');
	 jj = find(isnan(fp.tm_counts));
	 fp.tm_qc(jj) = 9;
      end
   end
   if isfield(fp,'CP_raw')
      if ~isempty(fp.CP_raw)
	 fp.CP_qc = zeros(size(fp.CP_raw),'uint16');
	 jj = find(isnan(fp.CP_raw));
	 fp.CP_qc(jj) = 9;
      end
   end
   if isfield(fp,'CHLa_raw')
      if ~isempty(fp.CHLa_raw)
	 fp.CHLa_qc = zeros(size(fp.CHLa_raw),'uint16');
	 jj = find(isnan(fp.CHLa_raw));
	 fp.CHLa_qc(jj) = 9;
      end
   end
   if isfield(fp,'BBP700_raw')
      if ~isempty(fp.BBP700_raw)
	 fp.BBP700_qc = zeros(size(fp.BBP700_raw),'uint16');
	 jj = find(isnan(fp.BBP700_raw));
	 fp.BBP700_qc(jj) = 9;
      end
   end
   if isfield(fp,'CDOM_raw')
      if ~isempty(fp.CDOM_raw)
	 fp.CDOM_qc = zeros(size(fp.CDOM_raw),'uint16');
	 jj = find(isnan(fp.CDOM_raw));
	 fp.CDOM_qc(jj) = 9;
      end
   end
   if isfield(fp,'FLBBoxy_raw')
      if ~isempty(fp.FLBBoxy_raw)
	 fp.FLBBoxy_qc = ones(size(fp.FLBBoxy_raw),'uint16');
	 jj = find(isnan(fp.FLBBoxy_raw));
	 fp.FLBBoxy_qc(jj) = 9;
      end
   end
   if isfield(fp,'p_oxygen')
       if  ~isempty(fp.p_oxygen)
           fp.p_oxygen_qc = ones(size(fp.p_oxygen),'uint16');
           jj = find(isnan(fp.p_oxygen));
           fp.p_oxygen_qc(jj) = 9;
       end
   end
   if isfield(fp,'t_oxygen')
       if  ~isempty(fp.t_oxygen)
           fp.t_oxygen_qc = ones(size(fp.t_oxygen),'uint16');
           jj = find(isnan(fp.t_oxygen));
           fp.t_oxygen_qc(jj) = 9;
       end
   end
   if isfield(fp,'s_oxygen')
       if  ~isempty(fp.s_oxygen)
           fp.s_oxygen_qc = ones(size(fp.s_oxygen),'uint16');
           jj = find(isnan(fp.s_oxygen));
           fp.s_oxygen_qc(jj) = 9;
       end
   end
   
   %set all tests to zeros before starting
   fp.testsperformed = zeros(1,19);
   fp.testsfailed = zeros(1,19);

   nlev = length(fp.p_raw);
   if isfield(fp,'p_oxygen')
       nlev2=length(fp.p_oxygen);
   end
      
   
   %test19 done first: Deepest pressure > 10% max p
   fp.testsperformed(19) = 1;
   jj=find(fp.p_raw>dbdat.profpres+(dbdat.profpres*.1));

   if ~isempty(jj)
      newv = repmat(4,1,length(jj));
      fp.p_qc(jj) = max([fp.p_qc(jj); newv]);
      fp.t_qc(jj) = max([fp.t_qc(jj); newv]);
      fp.s_qc(jj) = max([fp.s_qc(jj); newv]);
      fp.p_calibrate(jj)=NaN;
      fp.testsfailed(19) = 1;      

   end
      
   
   % Test1:  Platform Identification
   % Because of the way we check our platforms, this will always be OK
   fp.testsperformed(1) = 1;


   % Test2: Impossible Date Test:
   % we have done this test earlier
   fp.testsperformed(2) = 1;
   [gtime]=gregorian(fp.jday(end));
%    format long g
%    whos gtime
%    gtime=gtime
%    fp.jday(end)
   
   if ~isempty(gtime)
       [mno,dm,mm]=names_of_months(gtime(1,2));
       if(gtime(1,1)<1998 | gtime(1,2)<1 | gtime(1,2)>12 | gtime(1,3)<1 | ...
               gtime(1,3)>dm | gtime(1,4)<0 | gtime(1,4)>24 | gtime(1,5)<0 | gtime(1,5)>59)
           if(gtime(1,2) ~= 2 & gtime(1,3) ~=29 & rem(gtime(1,1),4) ~=0) %check for feb 29 in leap years
               fp.testsfailed(2) = 1;
               fp.jday_qc = 3;
           end
       end
   else
       fp.testsfailed(2) = 1;
       fp.jday_qc = 3;
   end
   % Test3: Impossible Location Test:
   % We have done this test earlier
   fp.testsperformed(3) = 1;
   if(fp.lat(1)<-90 | fp.lat(1) > 90 | fp.lon(1)<0 | fp.lon(1) > 360)
      fp.testsfailed(3) = 1;
      if fp.pos_qc ~= 8 %interpolated
          fp.pos_qc = 3;
      end
   end 
   if(isnan(fp.lat(1)))
       fp.pos_qc = 9;
   end

   % Test4: Position on Land Test:
   % We have done this test earlier
    fp.testsperformed(4) = 0;
    if any(~isnan(fp.lat))
        fp.testsperformed(4) = 1;
        %use a small window
        [maxdeps,mindeps] = get_ocean_depth(fp.lat,fp.lon,0.03);
        deps = [maxdeps;mindeps];
        if isnan(nansum(deps))
            %outside the ranges of the topography files
            fp.testsperformed(4) = 0;
        else
            
            %index the locations that have both min and max depths < 0
            jj = nansum(deps<0) > 1;
            if any(jj)
                fp.testsfailed(4)=1;
                if fp.pos_qc ~= 8
                    fp.pos_qc=4; %update to every jj later
                    %                 fp.pos_qc(jj)=4;
                end
            end
        end
    end
   % Test5: Impossible Speed Test:
   % Test speed between profiles. If apparently wrong, try some variant
   % tests and maybe remove our present 1st fix if it appears wrong. Could
   % test more combinations of previous profiles and fix numbers, but 
   % probably best to just eyeball any cases where this test fails.
   
   fp.testsperformed(5) = 1;
      
   % Find last good profile (this may also be used later)
   lstp = ii-1;
   while lstp>1 && (isempty(fpp(lstp).lat) || all(isnan(fpp(lstp).lat)) || isempty(fpp(lstp).jday))
      lstp = lstp-1;
   end

  
   if lstp<1 || isempty(fpp(lstp).lat) || all(isnan(fpp(lstp).lat)) 
      % Could not find an earlier good position
      lstp = [];
   elseif isnan(fp.lat(1)) | isempty(fpp(lstp).jday)
      % Cannot do test without positions
   else
      % We did find a previous profile with a valid position, so test
      % speed between last fix, last profile and present fix1
      ll = length(fpp(lstp).lat);
      distance = sw_dist([fpp(lstp).lat(ll) fp.lat(1)],...
			 [fpp(lstp).lon(ll) fp.lon(1)],'km')*1000;
         if isempty(fp.jday)
             jd=fp.jday_location;
         else
             jd=fp.jday(1);
         end
         try
      timediff = abs(fpp(lstp).jday(ll)-jd)*86400;
         catch
      timediff = abs(fpp(lstp).jday(1)-jd)*86400;
         end
      speed = distance/timediff;

      if speed>3 & ll>1
	 % try present fix1 vs penultimate fix of last profile
	 distance = sw_dist([fpp(lstp).lat(ll-1) fp.lat(1)],...
			    [fpp(lstp).lon(ll-1) fp.lon(1)],'km')*1000;
	 timediff = abs(fpp(lstp).jday(ll-1)-fp.jday(1))*86400;
	 speed = distance/timediff;

	 if speed>3 & length(fp.lat)>1
	    % try last fix, last profile  vs  present fix2
	    distance = sw_dist([fpp(lstp).lat(ll) fp.lat(2)],...
			       [fpp(lstp).lon(ll) fp.lon(2)],'km')*1000;
	    timediff = abs(fpp(lstp).jday(ll-1)-fp.jday(2))*86400;
	    speed = distance/timediff;

	    if speed<3
	       % Now good speed indicates present first fix is wrong, so remove
	       logerr(3,'QC_TESTS: Fix(1) rejected by speed wrt last profile');
	       fp.jday(1) = [];
	       fp.lat(1) = [];
	       fp.lon(1) = [];
	       fp.datetime_vec(1,:) = [];
	       fp.position_accuracy(1) = [];
	    end
	 end
      end
      
      if speed>3
	 fp.testsfailed(5) = 1;
      end
   end


   % Test6: Global Range Test:
   fp.testsperformed(6) = 1;

   jj = find(fp.t_raw<=-3.5 | fp.t_raw>40.);
   kk = find(fp.s_raw<2.0 | fp.s_raw>41.);
   if ~isempty(jj)
      newv = repmat(4,1,length(jj));
      fp.t_qc(jj) = max([fp.t_qc(jj); newv]);
      fp.testsfailed(6) = 1;
   end
   if ~isempty(kk)
      newv = repmat(4,1,length(kk));
      fp.s_qc(kk) = max([fp.s_qc(kk); newv]);
      fp.testsfailed(6) = 1;
   end
  
   
   if dbdat.oxy
       jj = find(fp.oxy_raw<=-0.5 | fp.oxy_raw>600.);
       if ~isempty(jj)
           newv = repmat(4,1,length(jj));
           fp.oxy_qc(jj) = max([fp.oxy_qc(jj); newv]);
           fp.testsfailed(6) = 1;
       end
       if isfield(fp,'s_oxygen')
           jj = find(fp.t_oxygen<=-3.5 | fp.t_oxygen>40.);
           kk = find(fp.s_oxygen<2.0 | fp.s_oxygen>41.);
           if ~isempty(jj)
               newv = repmat(4,1,length(jj));
               fp.t_oxygen_qc(jj) = max([fp.t_oxygen_qc(jj); newv]);
               fp.testsfailed(6) = 1;
           end
           if ~isempty(kk)
               newv = repmat(4,1,length(kk));
               fp.s_oxygen_qc(kk) = max([fp.s_oxygen_qc(kk); newv]);
               fp.testsfailed(6) = 1;
           end
       end
           
       if isfield(fp,'FLBBoxy_raw')
           jj = find(fp.FLBBoxy_raw<=-0.5 | fp.FLBBoxy_raw>600.);
           if ~isempty(jj)
               newv = repmat(4,1,length(jj));
               fp.FLBBoxy_qc(jj) = max([fp.FLBBoxy_qc(jj); newv]);
               fp.testsfailed(6) = 1;
           end
       end
   end
   % Test7: Regional Parameter Test
   % we won't do this one?


   % Test8: Pressure Increasing Test
   fp.testsperformed(8) = 1;
   
   gg = find(~isnan(fp.p_calibrate));
   if any(diff(fp.p_calibrate(gg))==0)
       fp.testsfailed(8) = 1;
       jj=(diff(fp.p_calibrate(gg))==0);
       newv = repmat(4,1,length(find(jj)));
       if(~isempty(newv))
           fp.p_qc(jj)=max([fp.p_qc(jj); newv]);
           fp.t_qc(jj)=max([fp.t_qc(jj); newv]);
           fp.s_qc(jj)=max([fp.s_qc(jj); newv]);
       end
   end
%    if any(diff(fp.p_calibrate(gg))>=0)
%       % non-monotonic p, reject all but last of any block of non-decreasing
%       % datapoints.
%       fp.testsfailed(8) = 1;
%      
%       bb = [];
%       lp = fp.p_calibrate(gg(1));
%       for jj = 2:length(gg)
%          if fp.p_calibrate(gg(jj)) < lp
%             lp = fp.p_calibrate(gg(jj));
%          else
%             bb = [bb gg(jj)];
%          end
%       end
%       newv = repmat(4,1,length(bb));
%       fp.s_qc(bb) = max([fp.s_qc(bb); newv]);
%       fp.t_qc(bb) = max([fp.t_qc(bb); newv]);
%       fp.p_qc(bb) = max([fp.p_qc(bb); newv]);
%    end
% 
% modified to use new (unapproved) code that does a much better job... AT
% 16/10/2008

%new process from here:

bb=[];
kk=find(diff(fp.p_calibrate)>0);

if length(kk)>0 
    for jj=1:length(kk)
       for l=kk(jj):kk(jj)+1    %max(2,kk(jj)):min(length(fp.p_calibrate)-2,kk(jj)+1)
           if l>=length(fp.p_calibrate)-1
               bb=[bb min(length(fp.p_calibrate),l+1)];
           elseif l==1 
               if fp.p_calibrate(l)< fp.p_calibrate(l+2)
                bb=[bb l];               
               else
                   bb=[bb l+1];
               end      
           elseif(fp.p_calibrate(l)>=fp.p_calibrate(l-1) | fp.p_calibrate(l)<= fp.p_calibrate(l+2))
               bb=[bb l];
           end
       end
   end
      newv = repmat(4,1,length(bb));
      fp.s_qc(bb) = max([fp.s_qc(bb); newv]);
      fp.t_qc(bb) = max([fp.t_qc(bb); newv]);
      fp.p_qc(bb) = max([fp.p_qc(bb); newv]);
end


   % Test9: Spike Test
   % testv is distance of v(n) outside the range of values v(n+1) and v(n-1).
   % If -ve, v(n) is inside the range of those adjacent points.
   fp.testsperformed(9) = 1;

   bdt = findspike(fp.t_raw,fp.p_raw,'t');
   if ~isempty(bdt)
      newv = repmat(3,1,length(bdt));
      fp.t_qc(bdt) = max([fp.t_qc(bdt); newv]);
      fp.testsfailed(9) = 1;
   end

   bds = findspike(fp.s_raw,fp.p_raw,'s');
   if ~isempty(bds)
      newv = repmat(3,1,length(bds));
      fp.s_qc(bds) = max([fp.s_qc(bds); newv]);
      fp.testsfailed(9) = 1;
   end
   if dbdat.oxy
       if length(fp.oxy_raw)~=length(fp.p_raw)
           po=fp.p_oxygen;
       else
           po=fp.p_raw;
       end

       bdo = findspike(fp.oxy_raw,po,'o');
       if ~isempty(bdo)
           newv = repmat(3,1,length(bdo));
           fp.oxy_qc(bdo) = max([fp.oxy_qc(bdo); newv]);
           fp.testsfailed(9) = 1;
       end
       if isfield(fp,'FLBBoxy_raw')
           po=fp.p_oxygen;
           bdo = findspike(fp.FLBBoxy_raw,po,'o');
           if ~isempty(bdo)
               newv = repmat(3,1,length(bdo));
               fp.FLBBoxy_qc(bdo) = max([fp.FLBBoxy_qc(bdo); newv]);
               fp.testsfailed(9) = 1;
           end
       end
         
   end

   % eliminate bottom spikes for this float only!!! Note  -test is rubbish
   %  generally
    if(fp.wmo_id==1901121)

       [bdt,bbt] = findspike(fp.t_raw,fp.p_raw,'t');
       if ~isempty(bbt)
          newv = repmat(4,1,length(bbt));
          fp.t_qc(bbt) = max([fp.t_qc(bbt); newv]);
          fp.testsfailed(9) = 1;
       end

       [bds,bbs] = findspike(fp.s_raw,fp.p_raw,'s');
       if ~isempty(bbs)
          newv = repmat(4,1,length(bbs));
          fp.s_qc(bbs) = max([fp.s_qc(bbs); newv]);
          fp.testsfailed(9) = 1;
       end
       
    end

   % Test10: Top and Bottom Spike Test
   % Argo Quality Control Manual V2.1 (Nov 30, 2005) states
   % that this test is obsolete

   
   % Test11: Gradient Test
   if nlev>=3
       fp.testsperformed(11) = 1;
       
       jj = 2:(nlev-1);
       
       testv = abs(fp.t_raw(jj) - (fp.t_raw(jj+1)+fp.t_raw(jj-1))/2);
       kk = find(testv>9 | (fp.p_raw(jj)>500 & testv>3));
       if ~isempty(kk)
           newv = repmat(3,1,length(kk));
           fp.t_qc(kk+1) = max([fp.t_qc(kk+1); newv]);
           fp.testsfailed(11) = 1;
       end
       
       testv = abs(fp.s_raw(jj) - (fp.s_raw(jj+1)+fp.s_raw(jj-1))/2);
       kk = find(testv>1.5 | (fp.p_raw(jj)>500 & testv>0.5));
       if ~isempty(kk)
           newv = repmat(3,1,length(kk));
           fp.s_qc(kk+1) = max([fp.s_qc(kk+1); newv]);
           fp.testsfailed(11) = 1;
       end
       
       if dbdat.oxy
           if length(fp.oxy_raw)~=length(fp.p_raw)
               jjo=2:length(fp.oxy_raw)-1;
               po=fp.p_oxygen;
           else
               jjo=jj;
               po=fp.p_raw;
           end
           testv = abs(fp.oxy_raw(jjo) - (fp.oxy_raw(jjo+1)+fp.oxy_raw(jjo-1))/2);
           kk = find(testv>50 | (po(jjo)>500 & testv>25));
           if ~isempty(kk)
               newv = repmat(3,1,length(kk));
               fp.oxy_qc(kk+1) = max([fp.oxy_qc(kk+1); newv]);
               fp.testsfailed(11) = 1;
           end
           if isfield(fp,'FLBBoxy_raw')
               if length(fp.FLBBoxy_raw)>2
                   jjo=2:length(fp.FLBBoxy_raw)-1;
                   po=fp.p_oxygen;
                   testv = abs(fp.FLBBoxy_raw(jjo) - (fp.FLBBoxy_raw(jjo+1)+fp.FLBBoxy_raw(jjo-1))/2);
                   kk = find(testv>50 | (po(jjo)>500 & testv>25));
                   if ~isempty(kk)
                       newv = repmat(3,1,length(kk));
                       fp.FLBBoxy_qc(kk+1) = max([fp.FLBBoxy_qc(kk+1); newv]);
                       fp.testsfailed(11) = 1;
                   end
               end
           end
       end
   end
   
   
   % Test12: Digit Rollover Test
   fp.testsperformed(12) = 1;
   
   jj = find(diff(fp.t_raw)>10.);
   kk = find(diff(fp.s_raw)>5.);
   
   if ~isempty(jj)
       newv = repmat(4,1,length(jj));
       fp.t_qc(jj+1) = max([fp.t_qc(jj+1); newv]);
       fp.testsfailed(12) = 1;
   end
   if ~isempty(kk)
       newv = repmat(4,1,length(kk));
       fp.s_qc(kk+1) = max([fp.s_qc(kk+1); newv]);
       fp.testsfailed(12) = 1;
   end
   
   
   % Test13: Stuck Value Test
   fp.testsperformed(13) = 1;
   
   if ~isempty(fp.s_raw) && all(fp.s_raw==fp.s_raw(1))
       newv = repmat(4,1,nlev);
       fp.s_qc(1:nlev) = max([fp.s_qc(1:nlev); newv]);
       fp.testsfailed(13) = 1;
   end
   if ~isempty(fp.t_raw) && all(fp.t_raw==fp.t_raw(1))
       newv = repmat(4,1,nlev);
       fp.t_qc(1:nlev) = max([fp.t_qc(1:nlev); newv]);
      fp.testsfailed(13) = 1;
   end
   if dbdat.oxy
       if ~isempty(fp.oxy_raw) && all(fp.oxy_raw==fp.oxy_raw(1))
           if isfield(fp,'p_oxygen')
               nv=nlev2;
           else
               nv=nlev;
           end
           newv = repmat(4,1,nv);
           fp.oxy_qc(1:nv) = max([fp.oxy_qc(1:nv); newv]);
           fp.testsfailed(13) = 1;
       end
       if isfield(fp,'FLBBoxy_raw') & ~isempty(fp.FLBBoxy_raw) & length(fp.FLBBoxy_raw)>2
           if ~isempty(fp.FLBBoxy_raw) && all(fp.FLBBoxy_raw==fp.FLBBoxy_raw(1))
               newv = repmat(4,1,nlev2);
               fp.FLBBoxy_qc(1:nlev2) = max([fp.FLBBoxy_qc(1:nlev2); newv]);
               fp.testsfailed(13) = 1;
           end
       end
   end

   % Test14: Density Inversion Test
   fp.testsperformed(14) = 1;

%    density = sw_pden(fp.s_raw,fp.t_raw,fp.p_calibrate,0);
%    dd = diff(density);
% 
%    jj = find(dd>0.04);
%    if (~isempty(jj) & fp.s_qc(jj)<=2 & fp.t_qc(jj)<=2)
%       % Have to reject value at both levels involved
%       kk = unique([jj; jj+1]);
%       newv = repmat(4,1,length(kk));
%       fp.t_qc(kk) = max([fp.t_qc(kk); newv]);
%       fp.s_qc(kk) = max([fp.s_qc(kk); newv]);
%       fp.testsfailed(14) = 1;
%    end

% new test from ADMT12: density calculated relative to neighboring points,
% not surface reference level...:

       difdd=0;
       for iij=1:length(fp.p_calibrate)-1
          difdd(iij)=0;
           
           density = sw_pden(fp.s_raw(iij:iij+1),fp.t_raw(iij:iij+1),fp.p_calibrate(iij:iij+1), ...
               (fp.p_calibrate(iij)+fp.p_calibrate(iij+1))/2);
           difdd(iij)=diff(density);
           
       end
       
       jj = find(difdd>0.03);
       jf=[];
       for i=1:length(jj)
           jk=[max(jj(i)-1,1);jj(i);min(length(difdd),jj(i)+1)];
           jk=unique(jk);
           jl=find(difdd(jk)==min(difdd(jk)));
           jf=[jf jj(i) jk(jl)];
       end
      
      for iij=length(fp.p_calibrate):-1:2
          difdd(iij)=0;
           
           density = sw_pden(fp.s_raw(iij:-1:iij-1),fp.t_raw(iij:-1:iij-1),fp.p_calibrate(iij:-1:iij-1), ...
               (fp.p_calibrate(iij)+fp.p_calibrate(iij-1))/2);
           difdd(iij)=diff(density);
           
       end
       
       jj = find(difdd<-0.03);

       for i=1:length(jj)
           jk=[max(jj(i)-1,1);jj(i);min(length(difdd),jj(i)+1)];
           jk=unique(jk);
           jl=find(difdd(jk)==min(difdd(jk)));
           jf=[jf jj(i) jk(jl)];
       end
      
       
       if (~isempty(jf))
           % Have to reject value at both levels involved
           newv = repmat(3,1,length(jf));
           fp.t_qc(jf) = max([fp.t_qc(jf); newv]);
           fp.s_qc(jf) = max([fp.s_qc(jf); newv]);
           fp.testsfailed(14) = 1;
       end

   % Test15: Grey List Test
   %load up the grey list
   glist = load_greylist;
   ib = find(glist.wmo_id == dbdat.wmo_id);
   fp.testsperformed(15) = 0;
   
   if ~isempty(ib) %float is on the greylist
       %check the date range:
       if datenum(gregorian(fp.jday(1))) > min(glist.start(ib)) & ...
               datenum(gregorian(fp.jday(1))) < max(glist.end(ib))
           
           fp.testsperformed(15) = 1;
           fp.testsfailed(15) = 1;
           vv=1:length(fp.p_raw);
           newv = repmat(3,1,length(vv));
           %        if(dbdat.wmo_id==7900325 |... %greylisted for PSAL,suspect
           %                dbdat.wmo_id==5903700 | ... %greylisted for PSAL,suspect
           %                dbdat.wmo_id==1901320 | dbdat.wmo_id==5901659 | ... %greylisted for PSAL,suspect
           %                dbdat.wmo_id==5901683|... %greylist for short time psal. Not suspect now
           %                dbdat.wmo_id==5903640) %greylisted for PSAL, suspect
           im = find(cellfun(@isempty,strfind(glist.var(ib),'PSAL'))==0);
           ij = find(cellfun(@isempty,strfind(glist.var(ib),'TEMP'))==0);
           ik = find(cellfun(@isempty,strfind(glist.var(ib),'PRES'))==0);
           if ~isempty(im) & isempty(ij) & isempty(ik) %psal only
               fp.s_qc(vv) = max([fp.s_qc(vv); newv]);
               vvs = qc_apply(fp.s_raw,fp.s_qc);
           else
               if strcmp(dbdat.status,'evil')
                   fp.p_qc(vv) = 4;
                   fp.s_qc(vv) = 4;
                   fp.t_qc(vv) = 4;
               else
                   fp.s_qc(vv) = max([fp.s_qc(vv); newv]);
                   fp.p_qc(vv) = max([fp.p_qc(vv); newv]);
                   fp.t_qc(vv) = max([fp.t_qc(vv); newv]);
                   %                fp.p_qc(vv) = 3;
                   %                fp.s_qc(vv) = 3;
                   %                fp.t_qc(vv) = 3;
               end
               pii = qc_apply(fp.p_calibrate,fp.p_qc);
               vvt = qc_apply(fp.t_raw,fp.t_qc);
               vvs = qc_apply(fp.s_raw,fp.s_qc);
           end
       end
   end
       
    
   % Actually we don't do this test. We could set a value according to
   % the database 'status' field - ie if .status=='suss' ...


   % Test16: Gross Salinity or Temperature Sensor Drift
   %DEV previously this was applied to s_calibrate, but this test looks for
   % exactly the type of signal that we think we removed by calibrating,
   % so for it to make senses at all (and it seems like a reasonable test) we
   % should test 's_raw'.
   
   % Note: failure of this test only attracts a 'probably bad'(3) flag.

   if ii>1
      % ie we have a previous profile, so we can do this test... 
      fp.testsperformed(16) = 1;

      % Reckon is better to skip this test than go back many profiles, so
      % just see if either of the last 2 profiles is deep enough. JRD 8/06
      ll = ii-1;
      pii = qc_apply(fp.p_calibrate,fp.p_qc);
	    vvt = qc_apply(fp.t_raw,fp.t_qc);
	    vvs = qc_apply(fp.s_raw,fp.s_qc);
        kk=find(~isnan(pii) &  ~isnan(vvt) & ~isnan(vvs));
      pll = qc_apply(fpp(ll).p_calibrate,fpp(ll).p_qc);
	    vv = qc_apply(fpp(ll).s_raw,fpp(ll).s_qc);
	    ddsp = nanmean(vv);
      maxp = min([max(pii(kk)) max(pll)]);

%      if(~isempty(maxp))
%          while (maxp<500 && ll>2) | isnan(ddsp)
      if(~isempty(maxp))
        if maxp<500 | isnan(ddsp)
          while ll>2 
            ll = ll-1;
            pll = qc_apply(fpp(ll).p_calibrate,fpp(ll).p_qc);
            maxp = min([max(pii(kk)) max(pll)]);
            vv = qc_apply(fpp(ll).s_raw,fpp(ll).s_qc);
            ddsp = nanmean(vv);
          end
        end  

          if ~isempty(maxp) && maxp>500 && ~isnan(ddsp)
             jj = find(pii>=maxp-100 & pii<=maxp);
             kk = find(pll>=maxp-100 & pll<=maxp);

             if ~isempty(jj) && ~isempty(kk)
                vv = qc_apply(fp.t_raw,fp.t_qc);
                ddtm = nanmean(vv(jj));
                vv = qc_apply(fpp(ll).t_raw,fpp(ll).t_qc);
                ddtp = nanmean(vv(kk));
                vv = qc_apply(fp.s_raw,fp.s_qc);
                ddsm = nanmean(vv(jj));
                vv = qc_apply(fpp(ll).s_raw,fpp(ll).s_qc);
                ddsp = nanmean(vv(kk));

                if abs(ddtm-ddtp)>1.
                    if(fp.wmo_id==5901172)

                    else    
                       fp.testsfailed(16) = 1;	 
                       newv = repmat(3,1,nlev);
                       fp.t_qc(1:nlev) = max([fp.t_qc(1:nlev); newv]);
                    end
                end
                if abs(ddsm-ddsp)>0.5
                   fp.testsfailed(16) = 1;	 
                   newv = repmat(3,1,nlev);
                   fp.s_qc(1:nlev) = max([fp.s_qc(1:nlev); newv]);
                end
             end
          end
      end
   end

   % Test18: Frozen Profile test
   fp.testsperformed(18) = 1;
   latc=[];
   if length(fpp)>3
       lstp = ii-1;
       while lstp>1 && isempty(fpp(lstp).lat)
           lstp = lstp-1;
       end
       lstp2 = ii-1;
       if isnan(fp.lat(1))
           while isnan(fpp(lstp2).lat)
               lstp2 = lstp2-1;
           end
       end
       try
           latc=fpp(lstp2).lat(1);
       end
       if ~isempty(latc)
           if lstp<1 || isempty(fpp(lstp).lat)  || latc<-65
               % Could not find an earlier good position or too far south to be an
               % effective test
               lstp = [];
           else
               if(isempty(fp.p_raw))
                   avgt=[];
                   avglt=[];
               else
                   gg=1:50:fp.p_raw(1);
                   avgt=[];
                   avglt=[];
                   avgs=[];
                   avgls=[];
                   for i=1:length(gg)-1
                       kk=find(fp.p_raw>=gg(i) & fp.p_raw<=gg(i+1) & fp.t_raw<9999);
                       kklp=find(fpp(lstp).p_raw>=gg(i) & fpp(lstp).p_raw<=gg(i+1) & fpp(lstp).t_raw<9999);
                       avgt(i)=nanmean(fp.t_raw(kk));
                       avgs(i)=nanmean(fp.s_raw(kk));
                       avglt(i)=nanmean(fpp(lstp).t_raw(kklp));
                       avgls(i)=nanmean(fpp(lstp).s_raw(kklp));
                   end
               end
               if(~isempty(avgt))
                   dTemp=abs(avgt-avglt);
                   dPsal=abs(avgs-avgls);
                   mdT=nanmean(dTemp);
                   mdS=nanmean(dPsal);
                   [mmT]=range(dTemp);
                   [mmS]=range(dPsal);
                   
                   if(~isempty(mmT) & mmT(1)<0.0001 & mmT(2)<0.3 & mdT<0.01 )
                       fp.testsfailed(18)=1;
                       newv = repmat(3,1,length(fp.t_qc));
                       fp.t_qc=newv;
                   end
                   if(fp.wmo_id==5903264)
                   else
                       if(~isempty(mmS) & mmS(1)<0.001 & mmS(2)<0.3 & mdS<0.001)   % was 0.0004
                           fp.testsfailed(18)=1;
                           newv = repmat(3,1,length(fp.t_qc));
                           fp.s_qc=newv;
                       end
                   end
               end
           end
       end
   end
   % Test17: Visual QC test
   % we don't perform this test...
   

   % Grounded test - max pressure short of expected_depth-5% 
   if max(fp.p_raw) < dbdat.profpres*.95
      fp.grounded = 'Y';
   else
      fp.grounded = 'N';
   end
   if isfield(fp,'p_oxygen') & ~isempty(fp.p_oxygen)
       QC = qc_tests_Profile2(dbdat,fp.p_oxygen,fp.s_oxygen,fp.t_oxygen, ...
           fp.p_oxygen_qc,fp.s_oxygen_qc,fp.t_oxygen_qc);
       fp.p_oxygen_qc=QC.p;
       fp.t_oxygen_qc=QC.t;
       fp.s_oxygen_qc=QC.s;
   end
   if isfield(fp,'oxyT_raw')  %
       if isfield(fp,'p_oxygen') & ~isempty(fp.p_oxygen) & length(fp.p_oxygen)==length(fp.oxyT_raw)
       QC = qc_tests_Profile2(dbdat,fp.p_oxygen,fp.s_oxygen,fp.oxyT_raw, ...
           fp.p_oxygen_qc,fp.s_oxygen_qc,fp.oxyT_qc);
       elseif length(fp.p_raw)==length(fp.oxyT_raw)
       QC = qc_tests_Profile2(dbdat,fp.p_raw,fp.s_raw,fp.oxyT_raw, ...
           fp.p_qc,fp.s_qc,fp.oxyT_qc);
       end
%        fp.p_oxygen_qc=QC.p;
       fp.oxyT_qc=QC.t;
%        fp.s_oxygen_qc=QC.s;
   end
   fpp(ii).testsperformed=[];
   fpp(ii).testsfailed=[];
   fpp(ii).grounded=[];
   fpp(ii).pos_qc=[];
   
   fpp(ii) = fp;
end

%-------------------------------------------------------------------------
