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

function fpp = qc_tests(dbdat,fpin,ipf,posonly)
global ARGO_SYS_PARAM

if nargin<3 || isempty(ipf)
    ipf = 1:length(fpin);
end

if nargin < 4
    posonly = 0;
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
        elseif ~isempty(fp.lat) & posonly
            
        else
            continue
        end
    end
    
    if ~isfield(fp,'pos_qc')
        fp.pos_qc = zeros(1,length(fp.lat),'uint8');
        fpp(ii).pos_qc = fp.pos_qc;
    end
    
    if isempty(fp.pos_qc)
        fp.pos_qc = zeros(1,length(fp.lat),'uint8');
    end
    if length(fp.pos_qc) ~= length(fp.lat)
        fp.pos_qc = zeros(1,length(fp.lat),'uint8');
    end
    if ~posonly
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
        fnaux = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id) 'aux.mat'];
        if exist(fnaux,'file') == 2
            %load the aux file for iridium, find the deep profile pressure.
            %Name varies for different float types.
            load(fnaux);
            flds = fieldnames(floatTech.Mission);
            jj = find(cellfun(@isempty,strfind(flds,'Pressure'))==0);
            kk = find(cellfun(@isempty,strfind(flds,'Deep'))==0);
            jj = intersect(jj,kk);
            configpress = floatTech.Mission(ii).(flds{jj(end)});
        else
            configpress = dbdat.profpres;
        end
        jj=find(fp.p_raw>configpress+(configpress*.1));
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
    end
    
    % Test2: Impossible Date Test:
    fp.testsperformed(2) = 1;
    %check date is between
    j1 = julian([1997 1 1 0 0 0]);
    d =datestr(now,'yyyy mm dd HH MM SS');
    j2 = julian(str2num(d));
    
    ibad = fp.jday< j1 | fp.jday > j2;
    if any(ibad)
        fp.testsfailed(2) = 1;
        fp.jday_qc(ibad) = 3;
    end
    
    %position tests, first flag all as ones, then missing locations
    jj = isnan(fp.lat);
    if any(jj)
        fp.pos_qc(jj) = 9;
    end
    
    % Test3: Impossible Location Test:
    % We have done this test earlier
    fp.testsperformed(3) = 1;
    jj = (fp.lat<-90 | fp.lat > 90 | fp.lon<0 | fp.lon > 360);
    if any(jj)
        if fp.pos_qc ~= 8 %interpolated
            fp.testsfailed(3) = 1;
            fp.pos_qc(jj) = 4;
        end
    end
    jj = isnan(fp.lat);
    if any(jj)
        fp.pos_qc(jj) = 9;
    end
    
    % Test4: Position on Land Test:
    % perform on all locations and keep the first occurrence of a good
    % location as the profile location
    fp.testsperformed(4) = 0;
    if any(~isnan(fp.lat))
        fp.testsperformed(4) = 1;
        %use a small window
        [maxdeps,mindeps] = get_ocean_depth(fp.lat,fp.lon,0.03);
        deps = [maxdeps;mindeps];
        if isempty(deps)
            %outside the ranges of the topography files
            fp.testsperformed(4) = 0;
        else
            
            %index the locations that have both min and max depths < 0
            jj = sum(deps<0) > 1;
            if any(jj)
                fp.testsfailed(4)=1;
                if fp.pos_qc ~= 8
                    fp.pos_qc(jj)=4;
                end
            end
        end
    end
    
    % Test5: Impossible Speed Test:
    % Do not use for Argos floats, use test 20 instead.
    % Test speed between profiles. If apparently wrong, try some variant
    % tests and maybe remove our present 1st fix if it appears wrong. Could
    % test more combinations of previous profiles and fix numbers, but
    % probably best to just eyeball any cases where this test fails.
    %only look at previous profile, don't go backwards to others.
    
    fp.testsperformed(5) = 0; %can't perform if positions in current/previous not available.
    
    if ii > 1 & dbdat.iridium == 1
        if isempty(fpp(ii-1).lat) || all(isnan(fpp(ii-1).lat))
            % Could not find an earlier good position
        elseif all(isnan(fp.lat)) | isempty(fpp(ii-1).jday)
            % Cannot do test without positions
        elseif fp.pos_qc == 8
            %interpolated, lets not bother testing here
        else
            %we will perform the test
            fp.testsperformed(5) = 1;
            %get last good location fix
            igood = find(fpp(ii-1).pos_qc < 3 | fpp(ii-1).pos_qc == 8);
            ig = find(fp.pos_qc ~= 9);%don't look at missing values, but look at all, even if failed already
            if ~isempty(igood) & ~isempty(ig) %need both values to continue
                distance = sw_dist([fpp(ii-1).lat(igood) fp.lat(ig)],...
                    [fpp(ii-1).lon(igood) fp.lon(ig)],'km')*1000;
                try
                    jd=[fpp(ii-1).jday_location(igood) fp.jday_location(ig)];
                catch
                    jd=[fpp(ii-1).jday fp.jday_location(ig)];
                end
                ind = (length(fp.lat(ig)) + length(fpp(ii-1).lat(igood))) - length(fp.lat(ig));
                timediff = abs(diff(jd))*86400;
                speed = distance./timediff;
                speed = speed(ind:end); %just limit to this profile
                
                if any(speed>3)
                    ibad = find(speed > 3);
                    fp.testsfailed(5) = 1; %it failed for one of these positions.
                    fp.pos_qc(ibad) = 4;
                end
            end
        end
    end
    
    %Now set the pos_qc flags that have passed the tests to 1
    if any(fp.testsperformed(2:5) == 1) %we have performed at least one of the tests on positions
        jj = fp.pos_qc == 0;
        fp.pos_qc(jj) = 1;
    end
    
    % Test15: Grey List Test
        %load up the grey list
        glist = load_greylist;
        ib = find(glist.wmo_id == dbdat.wmo_id);
        fp.testsperformed(15) = 1;
        
        if ~isempty(ib) %float is on the greylist
            %check the date range:
            if datenum(gregorian(fp.jday(1))) > min(glist.start(ib)) & ...
                    datenum(gregorian(fp.jday(1))) < max(glist.end(ib))
                
                fp.testsfailed(15) = 1;
                vv=1:length(fp.p_raw);
                im = find(cellfun(@isempty,strfind(glist.var(ib),'PSAL'))==0);
                ij = find(cellfun(@isempty,strfind(glist.var(ib),'TEMP'))==0);
                ik = find(cellfun(@isempty,strfind(glist.var(ib),'PRES'))==0);
                if strcmp(dbdat.status,'evil')
                    fp.p_qc(vv) = 4;
                    fp.s_qc(vv) = 4;
                    fp.t_qc(vv) = 4;
                else
                    if ~isempty(im) %psal
                        newv = repmat(glist.flag(ib(im)),1,length(vv));
                        fp.s_qc(vv) = max([fp.s_qc(vv); newv]);
                        vvs = qc_apply(fp.s_raw,fp.s_qc);
                    end
                    if ~isempty(ij) %temp
                        newv = repmat(glist.flag(ib(ij)),1,length(vv));
                        fp.t_qc(vv) = max([fp.t_qc(vv); newv]);
                        vvt = qc_apply(fp.t_raw,fp.t_qc);
                        fp.s_qc(vv) = max([fp.s_qc(vv); newv]);
                        vvs = qc_apply(fp.s_raw,fp.s_qc);
                        if ~isempty(im) %temp and psal
                            fp.p_qc(vv) = max([fp.p_qc(vv); newv]);
                            pii = qc_apply(fp.p_calibrate,fp.p_qc);
                        end
                    end
                    if ~isempty(ik) %pres
                        newv = repmat(glist.flag(ib(ik)),1,length(vv));
                        fp.p_qc(vv) = max([fp.p_qc(vv); newv]);
                        pii = qc_apply(fp.p_calibrate,fp.p_qc);
                        fp.s_qc(vv) = max([fp.s_qc(vv); newv]);
                        vvs = qc_apply(fp.s_raw,fp.s_qc);
                    end
                end
            end
        end
        
    if ~posonly
        % Test6: Global Range Test:
        fp.testsperformed(6) = 1;
        
        ip = find(fp.p_raw < -5);
        ip2 = find(fp.p_raw >= -5 & fp.p_raw <= -2.4); % QC manual v3.5 (2021)
        jj = find(fp.t_raw<=-2.5 | fp.t_raw>40.);
        kk = find(fp.s_raw<2.0 | fp.s_raw>41.);
        if ~isempty(ip)
            newv = repmat(4,1,length(ip));
            fp.p_qc(ip) = max([fp.p_qc(ip); newv]);
            fp.t_qc(ip) = max([fp.t_qc(ip); newv]); % QC manual v3.5 (2021)
            fp.s_qc(ip) = max([fp.s_qc(ip); newv]); % QC manual v3.5 (2021)
            fp.testsfailed(6) = 1;
        end
        if ~isempty(ip2)
            newv = repmat(3,1,length(ip2));
            fp.p_qc(ip2) = max([fp.p_qc(ip2); newv]);
            fp.t_qc(ip2) = max([fp.t_qc(ip2); newv]);
            fp.s_qc(ip2) = max([fp.s_qc(ip2); newv]);
            fp.testsfailed(6) = 1;
        end
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
        
        %new process from here: Might need some updating at some stage, seems
        %a bit clunky.
        
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
            newv = repmat(4,1,length(bdt));
            fp.t_qc(bdt) = max([fp.t_qc(bdt); newv]);
            fp.s_qc(bdt) = max([fp.s_qc(bdt); newv]);
            fp.testsfailed(9) = 1;
        end
        
        bds = findspike(fp.s_raw,fp.p_raw,'s');
        if ~isempty(bds)
            newv = repmat(4,1,length(bds));
            fp.s_qc(bds) = max([fp.s_qc(bds); newv]);
            fp.testsfailed(9) = 1;
        end
        if dbdat.oxy
            if length(fp.oxy_raw)~=length(fp.p_raw) | isempty(fp.oxy_raw)
                po=fp.p_oxygen;
            else
                po=fp.p_raw;
            end
            
            bdo = findspike(fp.oxy_raw,po,'o');
            if ~isempty(bdo)
                newv = repmat(4,1,length(bdo));
                fp.oxy_qc(bdo) = max([fp.oxy_qc(bdo); newv]);
                fp.testsfailed(9) = 1;
            end
            if isfield(fp,'oxyT_raw')
                bdo = findspike(fp.oxyT_raw,po,'t');
                if ~isempty(bdo)
                    newv = repmat(4,1,length(bdo));
                    fp.oxyT_qc(bdo) = max([fp.oxyT_qc(bdo); newv]);
                    fp.testsfailed(9) = 1;
                end
            end
            if isfield(fp,'t_oxygen')
                bdo = findspike(fp.t_oxygen,po,'t');
                if ~isempty(bdo)
                    newv = repmat(4,1,length(bdo));
                    fp.t_oxygen_qc(bdo) = max([fp.t_oxygen_qc(bdo); newv]);
                    fp.testsfailed(9) = 1;
                end
            end
            
            if isfield(fp,'FLBBoxy_raw')
                po=fp.p_oxygen;
                bdo = findspike(fp.FLBBoxy_raw,po,'o');
                if ~isempty(bdo)
                    newv = repmat(4,1,length(bdo));
                    fp.FLBBoxy_qc(bdo) = max([fp.FLBBoxy_qc(bdo); newv]);
                    fp.testsfailed(9) = 1;
                end
            end
            
            
        end
        
        % Test10: Top and Bottom Spike Test
        % Argo Quality Control Manual V2.1 (Nov 30, 2005) states
        % that this test is obsolete
        
                % Test25: MEDian with a Distance test (MEDD test) - Argo QC Manualv3.3
        ck_gsw = exist('gsw_SAAR.m'); % checks if gsw_v3.06 is installed
        if ck_gsw > 0;
                
        fp.testsperformed(25) = 1;
        
        % removes negative pressures
        PRES_positive = fp.p_raw;
        PRES_positive(PRES_positive < 0 | PRES_positive > 11000) = nan;
        
        % Looks for position with highest QC flag
        order = [1,2,0,5,8,9,3,4,7]; 
        [~,ia,~] = intersect(fp.pos_qc,order,'stable');
        
        if ~isempty(ia);
            [SA, in_ocean] = gsw_SA_from_SP(fp.s_raw, PRES_positive, fp.lon(ia(1)), fp.lat(ia(1))); % needs updated GSW (v 3.06)
            CT = gsw_CT_from_t(SA, fp.t_raw, fp.p_raw);
            DENS = gsw_rho(SA, CT, 0);
            [SPIKE_T,SPIKE_S,BO_T,BO_S,... % logical arrays with "1" when spikes are identified
            TEMP_med,TEMP_medm,TEMP_medp,...
            PSAL_med,PSAL_medm,PSAL_medp,...
            DENS_med,DENS_medm,DENS_medp] = ...
                QTRT_spike_check_MEDD_main(fp.p_raw,fp.t_raw,fp.s_raw,DENS,fp.lat(ia(1)));
          
            % Applies QC4 to data points with spikes
            fp.t_qc(SPIKE_T' == 1) = 4;
            fp.s_qc(SPIKE_S' == 1) = 4;
            
            if any(SPIKE_T) | any(SPIKE_S);
                fp.testsfailed(25) = 1;
            end
        else
            display(['No position in ' num2str(float(1).wmo_id) '_' num2str(prof) ...
                ' - could not apply MEDD test'])
        end
           
        else % If can't do the MEDD test because gsw_v3.06 is missing, does QC test# 11
            
            logerr(3,'No gibbs seawater package v3.06 - cannot apply MEDD test; applying QC test #11 instead')
            
            if nlev>=3 %nlev is the number of p_raw values
            fp.testsperformed(11) = 1;
            
            jj = 2:(nlev-1);
            
            testv = abs(fp.t_raw(jj) - (fp.t_raw(jj+1)+fp.t_raw(jj-1))/2);
            kk = find(testv>9 | (fp.p_raw(jj)>500 & testv>3));
            if ~isempty(kk)
                newv = repmat(4,1,length(kk));
                fp.t_qc(kk+1) = max([fp.t_qc(kk+1); newv]);
                fp.s_qc(kk+1) = max([fp.s_qc(kk+1); newv]);
                fp.testsfailed(11) = 1;
            end
            
            testv = abs(fp.s_raw(jj) - (fp.s_raw(jj+1)+fp.s_raw(jj-1))/2);
            kk = find(testv>1.5 | (fp.p_raw(jj)>500 & testv>0.5));
            if ~isempty(kk)
                newv = repmat(4,1,length(kk));
                fp.s_qc(kk+1) = max([fp.s_qc(kk+1); newv]);
                fp.testsfailed(11) = 1;
            end
            end
        end
        
        % Test11: Gradient Test
        % Argo Quality Contro Manual for CTD and Traj Data V3.3 (Jan 2020)
        % made this test obsolete for T and S, but I kept it active for
        % BGC variables (GSP)
        if nlev>=3 %nlev is the number of p_raw values
            fp.testsperformed(11) = 1;
            
            jj = 2:(nlev-1);
            
%             testv = abs(fp.t_raw(jj) - (fp.t_raw(jj+1)+fp.t_raw(jj-1))/2);
%             kk = find(testv>9 | (fp.p_raw(jj)>500 & testv>3));
%             if ~isempty(kk)
%                 newv = repmat(4,1,length(kk));
%                 fp.t_qc(kk+1) = max([fp.t_qc(kk+1); newv]);
%                 fp.s_qc(kk+1) = max([fp.s_qc(kk+1); newv]);
%                 fp.testsfailed(11) = 1;
%             end
%             
%             testv = abs(fp.s_raw(jj) - (fp.s_raw(jj+1)+fp.s_raw(jj-1))/2);
%             kk = find(testv>1.5 | (fp.p_raw(jj)>500 & testv>0.5));
%             if ~isempty(kk)
%                 newv = repmat(4,1,length(kk));
%                 fp.s_qc(kk+1) = max([fp.s_qc(kk+1); newv]);
%                 fp.testsfailed(11) = 1;
%             end
            
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
                    newv = repmat(4,1,length(kk));
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
                            newv = repmat(4,1,length(kk));
                            fp.FLBBoxy_qc(kk+1) = max([fp.FLBBoxy_qc(kk+1); newv]);
                            fp.testsfailed(11) = 1;
                        end
                    end
                end
            end
        end
        
        
        % Test12: Digit Rollover Test
        
        if ~isempty(fp.t_raw)
            jj = find(diff(fp.t_raw)>10.);
            
            fp.testsperformed(12) = 1;
            if ~isempty(jj)
                newv = repmat(4,1,length(jj));
                fp.t_qc(jj+1) = max([fp.t_qc(jj+1); newv]);
                fp.testsfailed(12) = 1;
            end
        end
        
        if ~isempty(fp.s_raw)
            fp.testsperformed(12) = 1;
            kk = find(diff(fp.s_raw)>5.);
            if ~isempty(kk)
                newv = repmat(4,1,length(kk));
                fp.s_qc(kk+1) = max([fp.s_qc(kk+1); newv]);
                fp.testsfailed(12) = 1;
            end
        end
        if isfield(fp,'oxyT_raw')
            if ~isempty(fp.oxyT_raw)
                jj = find(diff(fp.oxyT_raw)>10.);
                
                fp.testsperformed(12) = 1;
                if ~isempty(jj)
                    %all other values in the profile to be set to flag 3
                    fp.oxyT_qc = repmat(3,1,length(fp.oxyT_raw));
                    %failed values set to flag 4
                    newv = repmat(4,1,length(jj));
                    fp.oxyT_qc(jj+1) = max([fp.oxyT_qc(jj+1); newv]);
                    fp.testsfailed(12) = 1;
                end
            end
        end
        if isfield(fp,'t_oxygen')
            if ~isempty(fp.t_oxygen)
                jj = find(diff(fp.t_oxygen)>10.);
                
                fp.testsperformed(12) = 1;
                if ~isempty(jj)
                    newv = repmat(4,1,length(jj));
                    fp.t_oxygen_qc(jj+1) = max([fp.t_oxygen_qc(jj+1); newv]);
                    fp.testsfailed(12) = 1;
                end
            end
        end
        
        % Test13: Stuck Value Test
        flds = {'s_raw','t_raw','oxy_raw','FLBBoxy_raw','t_oxygen','oxyT_raw'};
        fldsq = {'s_qc','t_qc','oxy_qc','FLBBoxy_qc','t_oxygen_qc','oxyT_qc'};
        for a = 1:length(flds)
            if isfield(fp,flds{a})
                if ~isempty(fp.(flds{a})) && all(fp.(flds{a})==fp.(flds{a})(1))
                    fp.testsperformed(13) = 1;
                    newv = repmat(4,1,length(fp.(flds{a})));
                    fp.(fldsq{a}) = max([fp.s_qc; newv]);
                    fp.testsfailed(13) = 1;
                end
            end
        end
        
        % Test14: Density Inversion Test
        % new test from ADMT12: density calculated relative to neighboring points,
        % not surface reference level...:
        if ~isempty(fp.p_calibrate) & ~isnan(fp.p_calibrate)
            if length(fp.p_calibrate) > 1
                fp.testsperformed(14) = 1;
                
                %new test here to compare
                %array of mid-points for pressure surface
                psurf = diff(fp.p_calibrate)/2+fp.p_calibrate(1:end-1);
                %array1 of density on the psurf
                den1 = sw_pden(fp.s_raw(2:end),fp.t_raw(2:end),fp.p_calibrate(2:end),psurf);
                %array 2 of density on the psurf
                den2 = sw_pden(fp.s_raw(1:end-1),fp.t_raw(1:end-1),fp.p_calibrate(1:end-1),psurf);
                
                %difference between the two density arrays
                %bottom up and top down
                difd1 = den1 - den2;
                difd2 = den2 - den1;
                
                %find errors outside +/-0.03
                err = find(difd1 > 0.03 | difd2 < -0.03);
                
                if (~isempty(err))
                    % Have to reject values
                    newv = repmat(4,1,length(err));
                    fp.t_qc(err) = max([fp.t_qc(err); newv]);
                    fp.s_qc(err) = max([fp.s_qc(err); newv]);
                    fp.testsfailed(14) = 1;
                end
            end
        end
        
        
        
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
            
            %apply this test to deep profiles only
            if(~isempty(maxp))
                
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
                            fp.testsfailed(16) = 1;
                            newv = repmat(3,1,nlev);
                            fp.t_qc(1:nlev) = max([fp.t_qc(1:nlev); newv]);
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
        % Find last good profile
        lstp = ii-1;
        while lstp>1 && (isempty(fpp(lstp).lat) || all(isnan(fpp(lstp).lat)) || isempty(fpp(lstp).jday))
            lstp = lstp-1;
        end
        
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
        if max(fp.p_raw) < configpress*.95
            fp.grounded = 'Y';
        else
            fp.grounded = 'N';
        end
        
        %secondary profile tests - check these tests.
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


    end
    %copy the profile back to the main structure
    fpp(ii) = fp;
end

%-------------------------------------------------------------------------
