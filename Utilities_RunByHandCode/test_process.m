% TEST_PROCESS  Run decoding of Argo profile, and produce a test report
%
% INPUT
%   rawdat - decimal form of repeated tranmissions for one profile
%   heads  - decimal form of ARGOS tranmission headers for one profile
%   pmeta  - message meta data for profile
%   dbdat  - database record for this float
%
% OUTPUT  
%
% Author: Jeff Dunn CMAR/BoM Nov 2006
%
% CALLED BY:  edit_workfile
%
% USAGE:  rawdat = test_process(rawdat,heads,b1tim,pmeta,dbdat);

function  rawdat = test_process(rawdat,heads,b1tim,pmeta,dbdat)

% System tuning parameters (could be shifted to ARGO_SYS_PARAM ?)
Too_Old_Days = 10;         % Realtime: no interested beyond 10 and a bit days. 
First_Load_Time = .75;     % Do first decode/load after 18 hrs (.75 days)
Final_Load_Time = 3;       % Do final decode/load after 3 days


if isfield(heads,'qc') && any(heads.qc~=0)
   ii = find(heads.qc==0);
   head = heads.dat(ii,:);
else
   head = heads.dat;
end

if isfield(b1tim,'qc') && any(b1tim.qc~=0)
   ii = find(b1tim.qc==0);
   b1tdat = b1tim.dat(ii,:);
else
   b1tdat = b1tim.dat;
end
ftptime = pmeta.ftptime;


jdays = julian(head(:,1:6));

% Check dates
dt_min = [1997 1 1 0 0 0];
dt_max = [2010 12 31 23 59 59]; 
for jj = 1:size(head,1)
   if any(head(jj,1:6)<dt_min) || any(head(jj,1:6)>dt_max)
      disp(['Implausible date/time components: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;
   elseif jdays(jj)>ftptime || jdays(jj)<(ftptime-Too_Old_Days)
      disp(['Implausible dates: ' num2str(head(jj,1:6))]);
      jdays(jj) = NaN;
   end
end
   
gdhed = find(~isnan(jdays));
if isempty(gdhed)
   disp('No usable date info');
   return
end

jday1 = min(jdays(gdhed));

if ftptime-jday1<First_Load_Time
   disp('Profile downloaded too soon after first fix - should not process');   
end


% Decode the new profile
[prof,fbm_rep,rawdat] = find_best_msg(rawdat,dbdat.maker);

ll = 1:length(fbm_rep);
fprintf(1,'FBM: ');
fprintf(1,' %d=%d ',[ll; fbm_rep]);
fprintf(1,'\n');

if isempty(prof)
   report_bad_prof(rawdat);
   fp = [];
else
   if dbdat.maker==2
      fp = decode_provor(prof,dbdat);
   else
      fp = decode_webb(prof,dbdat);
   end
end
   

if any(diff(jdays(gdhed))<0)
   % fixes are often out of order. If so, we reorder them. That is, after
   % this step, jday(1),lats(1) etc ARE the first fix after surfacing. 
   disp('ARGOS fixes put in chrono order.');
   [tmp,ij] = sort(jdays(gdhed));
   gdhed = gdhed(ij);
end

if any(diff(jdays(gdhed))==0)
   % Awkward to have same-time fixes (but it seems to happen?)
   disp('ARGOS fixes at identical time');
end
   
% Check Argos location & time info (and for range -180<=lons<=180 )
% Also find deepest point within a +/- .25degree range, and reject if 
% not offshore (ie a very lenient test)
lats = head(gdhed,7);  
lons = head(gdhed,8);  
goodfixes = gdhed;
if any(lons>180 & lons<360)
   ii = find(lons>180 & lons<360);
   lons(ii) = lons(ii)-360;
end
deps = get_ocean_depth(lats,lons);      
kk = find(isnan(lats) | isnan(lons) | lats<-90 | lats>90 ...
	  | lons<-180 | lons>360 | deps<0);
if ~isempty(kk)
   disp('Implausible locations');
   goodfixes(kk) = [];
   lats(kk) = nan;
   lons(kk) = nan;
   if isempty(goodfixes)
      disp('No good location fixes!');
   end
end

fp.jday = jdays(gdhed);
fp.lat = lats(gdhed);
fp.lon = lons(gdhed);

if ~isempty(goodfixes)
   % Check speeds. Simple diagonal distance, lat corrected, converted
   % to metres. Force a minimum of 120 sec for delT, because (I guess)
   % different satellites might be near-simulataneous fixes, but with 
   % different small positioning biases. A small delT makes this look
   % like a large spped diff. Limiting delT also prevents divide-by-0.
   lats = head(goodfixes,7);  
   lons = head(goodfixes,8);  
   lcor = cos(mean(lats)*(pi/180));
   
   delT = diff(fp.jday(goodfixes))*86400;   % Converts from days to seconds
   kk = find(delT<120);
   delT(kk) = 120;
   dist = sqrt(diff(lats).^2 + (diff(lons)*lcor).^2)*111119;
   speed = dist ./ delT;
   if any(speed > 3)
      disp('Unresolved excessive speeds between fixes');
   end

      
   % Estimate the time at which the float surfaced (and list what 
   % happens)
   jae = calc_ascent_end(b1tdat,rawdat.maxblk,dbdat,fp,1);
end

fp.ftp_download_jday(1) = pmeta.ftptime;

if ~isempty(fp) 
   profile_plot(fp);
end
   
   
return

%-----------------------------------------------------------------------------
% PROFILE_PLOT  Plot a single profile, and disp associated header data
%
function profile_plot(fp)

jul0 = julian(0,1,1);

fprintf(1,'Float %d   Profile %d   Download %s\n',...
	fp.wmo_id,fp.profile_number,datestr(fp.ftp_download_jday(1)-jul0));
fprintf(1,'N_Fixes %d     N_Gd_Pos  %d\n',length(fp.jday),length(~isnan(fp.lat)));

   
pnames = {'P raw','T raw','S raw','Oxy','OxyT','Tmiss'};
for jj = 1:6
   vv = [];
   switch jj
     case 1
       vv = fp.p_raw;
     case 2
       vv = fp.t_raw;
     case 3
       vv = fp.s_raw;
     case 4
       if isfield(fp,'oxy_raw')
	  vv = fp.oxy_raw;
       end
     case 5
       if isfield(fp,'oxyT_raw')
	  vv = fp.oxyT_raw;
       end
     case 6
       if isfield(fp,'tm_counts')
	  vv = fp.tm_counts;
       end
   end

   if ~isempty(vv)
      fprintf(1,'%s  N=%d  Min=%7.3f Max=%7.3f  Mean=%7.3f\n',...
	      pnames{jj},length(~isnan(vv)),min(vv),max(vv),mean(vv));
   end
end   



labels = {'RAW  Temperature ^oC','RAW  Salinity psu'};

H = figure(10);
clf;

% Want to keep NaNs where missing profiles or gaps in profiles. Better to see
% gaps rather than interpolate through them and be deluded.

pp = fp.p_raw;

for var = 1:2
   if var==1
      axes('position',[.1 .08 .8 .4])
      vr = fp.t_raw;
   else
      axes('position',[.1 .52 .8 .4])
      vr = fp.s_raw;
   end

   if ~isempty(pp) && ~isempty(vr)
      plot(vr,pp,'k-');
      hold on;
      plot(vr,pp,'rx','markersize',3);
      ax = axis;
      axis ij
      ax(4) = pp(1)+50;
      yinc = (ax(3)-ax(4))/20;
      xy0 = [ax(1)+(ax(2)-ax(1))/20 ax(4)+yinc]; 
   end
   title(labels{var});
end


%----------------------------------------------------------------------
