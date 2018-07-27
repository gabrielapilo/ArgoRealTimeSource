% Collect Trajectory data from one cycle for an Argos Apex float (APF8,9),
% and analyse accumulated time-series for float to deterine/update all values
% needed for trajectory files.
%
% NOTE: "clock offset" is not considered here because none of the times are
%   provided by the float. The drift of the float clock may be incidentally
%   estimated while calculating TET but is not otherwise used.
%
% NOTE: Park values are recorded depending differently depending on whether
%    they are samples or averages. Associated times vary depending on float
%    setup. This needs to be determined for each float and somehow introduced
%    here.
%
% INPUTS
%   rawdat, heads, b1tim, pmeta:   components of the Argos message.
%   dbdat:     our tech database record for this float
%   fpp:       struct array of decoded profile data for this float
%   not_last:  1=just extract vars for this cycle but do NOT review the whole
%              float series.  [default 0]
%
% OUTPUTS
%   traj:   see just below
%   traj_mc_order:  The event MEASUREMENT_CODEs appropriate to this float,
%                   and in the order required for their placement in the
%                   Rtraj file.
%
% Jeff Dunn Nov 2013, May 2014
%
% CALLS:  median  polyfit  julian  hist
%         find_best_msg  calc_TST  trim_LMT  calc_TET
%
% CALLED BY: process_profile
%
% LIMITATIONS:  presently not coded for:
%   - profile-on-descent floats
%   - floats which report an alternate value for TST, DTET
%   - setting JULD_QC values (because of confusion - see QUERIES)
%
% USAGE: [traj,traj_mc_order] = load_traj_apex_argos(rawdat,heads,b1tim,pmeta,dbdat,fpp,not_last);

function [traj,traj_mc_order] = load_traj_apex_argos(rawdat,heads,b1tim,pmeta,dbdat,fpp,not_last)

global ARGO_SYS_PARAM

% The traj struct array stores rawdat and heads fields from the Argos
% download, and the computed timing parameters. These have the sub-fields:
% - juld : The julian time. Var is not put in N_M arrays if this is empty,
%          and is placed as fillvalue (with status=9) if this is NaN.
% - stat : Value for STATUS field in N_M and N_C arrays (ref table 19)
% - adj  : 0=use JULD_ADJUSTED only if CLOCK_OFFSET determined.  1=JULD_ADJUSTED always
% - qc   : Not yet implemented. Would contain value for JULD_QC

traj = [];
traj_mc_order = [];

if nargin<7 || isempty(not_last)
    not_last = 0;
end

if dbdat.maker~=1
    % only dealing with Apex floats for now
    return
end

np = pmeta.pnum;
if isempty(np) || np<1 || np>999
    % Cannot do anything without a sensible profile number
    disp('LOAD_TRAJ_APEX_ARGOS: no reasonable profile number - returning')
    return
end

% Open new or existing trajectory workfile
tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(pmeta.wmo_id)];
if exist([tfnm '.mat'],'file')
    load(tfnm,'traj','traj_mc_order');
else
    % Standard Argos order:
    % DST DET PST PET DDET DPST DAST AST AET TST FMT FLT LLT LMT TET
    %   I think FLT, LLT are not stored in N_M - instead of fixes are with MC=703
    % I don't think FST (MC=150) is a goer for Argos Apex
    
    % Presently park_av can be a variable with 2 values (average of first and
    % second 4.5 day periods of the Park.) This is not MC=301 but is MC=296.
    % Megan S suggested MC=290 but that is for individual samples.
    
    traj.clockoffset = [];
end

% This overwrites the same variable extracted from the existing file, because
% I have changed my mind about the correct order for these floats
traj_mc_order = [99 100 200 250 290 296 300 400 450 550 500 600 700 702 703 ...
    704 800 903];

% Floats which profile on ascent must provide
%  DST, DET, PET, DDET, AST, AET and all surface times (Cookbook 3.2)
% Those profiling on descent might have DST, DDET, DAST, DET, PET, AST, AET

% APF9a differences:
% 3.2.2.1 Some now transmit end of DOWNTIME and AST. Should be stored but not
%   replace normal Argos Apex calc of these vars. These cases are noted below.



% Could calc cycle time but our DB does not store the time components accurately enough
% cyctim = dbdat.parktime + dbdat.uptime;
% An approximation which should work in most cases
if dbdat.parktime>8 && dbdat.parktime<=10
    cyctim = 10.0;
elseif dbdat.parktime>=2 && dbdat.parktime<=3   % if these are iridiums, then
    %     this needs to come from the mission information.
    cyctim = 3.0;
else
    % Start with this guess - it will later be evident if it is wrong
    cyctim = 10.0;
end


% Load raw data for this cycle, from workfile variables
% First attempt to repair incomplete workfile vars
% This really should not be necessary but an old-style workfile might somehow
% come back from the dead.
if ~isfield(rawdat,'crc')
    disp('No CRC - calling find_best_msg')
    [tmp1,tmp2,rawdat] = find_best_msg(rawdat,dbdat);
    % Note: if find_best_msg fails there may still be no .crc field
end


% ---- Load data and parameters from this cycle

% Switched to getting this info from fpp - see below
%include a sort as sometimes the dates are out of order and this causes
%mismatches later in the netcdf file creation.
[traj(np).heads.juld,isort] = sort(julian(heads.dat(:,1:6)));
traj(np).heads.lat = heads.dat(isort,7);
traj(np).heads.lon = heads.dat(isort,8);
traj(np).heads.aclass = char(heads.dat(isort,9));
if isfield(heads,'qc')
    traj(np).heads.qcflags = heads.qc(isort);
else
    traj(np).heads.qcflags = ones(size(traj(np).heads.juld));
end

pos_qc = jamstec_position_test(traj(1:np));
traj(np).heads.qcflags = pos_qc;


% We need a robust way to reject "ghost" message times in RT
% A first step is to only use times assoc with good CRC.
% (Maybe should only do this in variable "temp", below?)
if isfield(rawdat,'juld')
    traj(np).raw.juld = rawdat.juld;
else
    % Should only happen if it was impossible to extract this info from the download
    if isfield(rawdat,'crc')
        traj(np).raw.juld = nan(size(rawdat.crc));
    else
        traj(np).raw.juld = [];
    end
end
if isfield(rawdat,'crc') && ~isempty(rawdat.crc)
    traj(np).raw.juld(rawdat.crc==0) = nan;
end

% First cut at LMT (704) for this cycle
traj(np).LMT.juld = max([max(traj(np).raw.juld) max(traj(np).heads.juld)]);
traj(np).LMT.stat = '4';
traj(np).LMT.adj = 0;



%---- Block 1 records and TST for this cycle

rok = ~isnan(traj(np).raw.juld);
jday_rng = median(traj(np).raw.juld(rok)) + [-.5 .5];
TST = nan;
Tstat = 0;

if isempty(b1tim.dat)
    nb = [];
else
    nb = b1tim.dat(:,1);
    jday1 = julian(b1tim.dat(:,2:7));
    jj = (nb<1 | nb>350 | jday1<jday_rng(1) | jday1>jday_rng(2) | isnan(jday1));
    if any(jj)
        % Trimming some unrealistic Block1 rep nums and outlier dates
        nb(jj) = nan;
    end
    
    if length(unique(nb))<length(nb)
        % Removing duplicate Block1 repnum records
        for jk = row(unique(nb))
            if sum(nb==jk)>1
                jj = find(nb==jk);
                nb(jj(2:end)) = nan;
            end
        end
    end
    
    if any(isnan(nb))
        cull = isnan(nb);
        b1tim.dat(cull,:) = [];
        jday1(cull) = [];
        nb(cull) = [];
    end
end

if ~isempty(nb)
    if any(diff(jday1)<=0)
        [jday1,ij] = sort(jday1);
        nb = nb(ij);
        b1tim.dat = b1tim.dat(ij,:);
        if sum(diff(nb)<0) >= 3  || length(nb) <= 3
            % Should not have repnum out of order, so something screwy
            Tstat = 3;
        end
    end
    
    if Tstat<3
        [TST,Tstat] = calc_TST(jday1,nb);
        
        % TST2 is a result of an alternative calculation and could be used to
        % detect and report dodgy conditions, and set a warning flag. However,
        % until we use either of those measures there is no point in computing it.
        % TST2 = calc_TST_JD(jday1,nb);
        % if abs(TST-TST2)>(2/1440) || TST<(traj(np).LMT.juld-.5) || TST>(traj(np).LMT.juld-.1)
        %	   % > 2 minute diff OR disagrees with LMT
        %	   Tstat = 2;
        % end
    end
end

% The local error flag Tstat is: 0=ok  2=dodgy  3=too bad to calc
% Could be used for diagnostics but not stored in Traj file at this stage
% TST=700  AET=600

traj(np).TST.juld = TST;
% AET = TST - 10 minutes
traj(np).AET.juld = TST - 10/1440;
if isnan(TST)
    traj(np).TST.stat = '9';
    traj(np).AET.stat = '9';
else
    traj(np).TST.stat = '3';
    traj(np).AET.stat = '3';
end
traj(np).TST.adj = 0;
traj(np).AET.adj = 0;


% Q: What fpp var contains this APF9a float-reported TST parameter??
%if ~isnan( <TST_fl> )
% Some Apex Argos floats directly report another measure of TST
% (TST_fl is MC=701, _stat=3)    Will not consider for now. If that
% is present then would also have DTET_fl (MC=501 and _stat=2)
%end


% DDET (400) : same as AST, fill below

% For some Apex floats there is a second estimate of AST (3.2.2.1.7.2)
% which is also meant to be recorded (MC=502, STATUS=3). Cross that
% bridge when we get to it.



if not_last
    % Do not want to process whole series yet? Unusual situation - we
    % might be rebuilding the whole traj file so no point in doing the
    % analysis until the last cycle.
    save(tfnm,'traj','traj_mc_order')
    return
end


% ----------- Now do analysis of whole timeseries -----------------
%
% What is the minimum timeseries length for this? For now, only do LMT
% screening if more than 10 cycles with data. TET code will return a result
% even if only 1 cycle.
%

% We repeat this every time a new cycle is loaded. Potentially different raw data
% is rejected each time by our outlier testing. This should start afresh each
% time, rather than carrying over. However, we want to use this outlyer
% screening as we derive all quantities during this run, and that includes
% updating previous per-cycle values that may be altered. How?  For now, use
% "temp" array for values which might be QC'ed during the analysis. An
% alternative would be to have rej flags associated with each heads/raw value
% in traj, and reset those to zero before each treatment.

% LMT errors:
% I observed apparent late-descending surface drifts (eg 5901700_147), exactly
% 0.5 days late. Had theories about it but actually this case vanished when
% workfile rebuilt.  Others cases are floats which:
% a) switch to different phases with different cycle timing
% b) have wrongly recorded cycle time (can be corrected after that is
%    determined). CALC_TET reports this condition.
% c) mix up different types of profiles: ie there are two or more standard
%    cycle times
%
% Repair/remove LMT outlyers, some of which are "ghost transmissions":
%        a) >2 days different to median LMT
%        b) >5 SD from best linear fit, OR
%        c) isolated by void of > 1 SD
% Could just reject bad LMT values but instead reject the original header or
% raw date/time which produced the LMT for that cycle, then recalc that LMT
% and look again at the whole series. (Hence we {rev}iew the LMT rather than
% {rej}ect it.

% If don't already have this fixed...
LMT = nan(1,length(traj));
for ii = 1:length(traj)
    if isempty(traj(ii).LMT) || isempty(traj(ii).LMT.juld) || traj(ii).LMT.juld==0
        traj(ii).LMT.juld = nan;
        traj(ii).LMT.stat = '9';
        traj(ii).LMT.adj = 0;
    end
    LMT(ii) = traj(ii).LMT.juld;
end

% The QC done here is not saved, but reworked every time because every new
% cycle may change the assessment of what is or is not an outlyer. So changes
% are made here to a temporary array.
temp = traj;

warned = 0;

rev = nan;
while ~isempty(rev)
    LMTrel = LMT - cyctim*(0:(length(LMT)-1));
    gd = find(~isnan(LMTrel));
    rev = [];
    if ~isempty(gd) && any(abs(LMTrel(gd)-median(LMTrel(gd))) > 2)
        % Crude test: more than 2 days off expected
        [mx,rev] = max(abs(LMTrel(gd)-median(LMTrel(gd))));
        if mx>(cyctim/2) && ~warned
            disp('** LOAD_TRAJ_APEX_ARGOS')
            disp(['** Possibly the wrong cycle decoded: ' num2str([pmeta.wmo_id rev])]);
            warned = 1;
        end
    elseif length(gd)>20
        % Fit a line through the normalised LMT
        clkfit = polyfit(gd,LMTrel(gd),1);
        % The departures from the fit line
        LMdel = LMTrel(gd) - (clkfit(2) + clkfit(1)*gd);
        [mxd,tmp] = max(abs(LMdel));
        
        if mxd>(5*std(LMdel)) && mxd>0.1    % 2.4 hours
            % Primary test: 5 SD outliers
            rev = tmp;
            
        elseif length(gd)>=33
            % Secondary test, not appropriate for small series. Less distant but
            % still isolated points (looking at high values only). This is more
            % reliably tested by assuming no clock drift - ie look at actual times
            % rather than relative to fitted trend, because trend is susceptible to
            % progressively changing scatter of points (as does happen).
            % Classic example:  WMO 5901687
            Lg = LMTrel(gd);
            [mxg,tmp] = max(Lg);
            [cnts,bins] = hist(Lg,min(Lg):std(Lg):mxg);
            if any(cnts==0)
                [~,imxb] = max(cnts);
                ij = find(cnts==0,1,'last');
                if ij > imxb
                    rev = tmp;
                end
            end
        end
    end
    
    if ~isempty(rev)
        rev = gd(rev);
        
        % reject the offending single head or raw date
        % We could just reject this LMT value but by instead taking a second
        % pick at this LMT we may get rid of a ghost and find a good value for this
        % cycle, and also improve other values derived for this cycle. If all
        % points are bad for this cycle then it will iterate until we have LMT=nan.
        lowerr = (LMTrel(rev) < median(LMTrel(gd)));
        temp(rev) = trim_LMT(temp(rev),lowerr);
        
        % Refine LMT for that cycle
        tmp = max([max(temp(rev).raw.juld) max(temp(rev).heads.juld)]);
        if isempty(tmp) || isnan(tmp)
            traj(rev).LMT.juld = nan;
            traj(rev).LMT.stat = '9';
        else
            traj(rev).LMT.juld = tmp;
            traj(rev).LMT.stat = '4';
        end
        LMT(rev) = traj(rev).LMT.juld;
    end
end

% TET for whole float series
pfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/t' num2str(pmeta.wmo_id)];

[TET,clkoffset,tstat] = calc_TET(cyctim,LMT,pfnm);

% For now just use the standard TET, not Dunn method
TET = TET(:,1);

% DET (200)   3.2.2.1.3
% "Not available with Apex, but can set to time of drift pressure overshoot,
% if it occurs." BUT I don't see where the ARGOS float gives us that information!!!
% Would have stat = '2';


% parklag required for PST, Cookbook 3.2.2.1.4.1
% Need to adapt here if park pressure can vary from cycle to cycle
pdep = [250 500 1000 1500 2000];
mdr  = [2.6 3.6 5.9  12.4 9.0];
[~,jj] = min(abs(pdep-dbdat.parkpres));    % Select nearest value
parklag = dbdat.parkpres./(mdr(jj)*864);   % converting cm/s to m/day


% DPDP required for PET, Cookbook 3.2.2.1.5
% If no DPDP is defined, DPDP=6hrs.
if isfield(dbdat,'DPDPtime') && ~isempty(dbdat.DPDPtime)
    DPDP = dbdat.DPDPtime;
else
    DPDP = .25;   % 6 hours
end

if isfield(dbdat,'uptime') && ~isempty(dbdat.uptime)
    UPTIME = dbdat.uptime/24;
else
    disp(['LOAD_TRAJ: Need UPTIME in DB for float ' num2str(dbdat.wmo_id)])
    UPTIME = 15/24;
end

% TET can change for any existing cycle with the addition of every
% new cycle, which then effects DST, PST, AST, PET etc, so might as well
% recalc all vars everytime.

for ii = 1:length(traj)
    if ~isempty(temp(ii).raw)
        rawgd = temp(ii).raw.juld;
        rawgd(isnan(rawgd)) = [];
    else
        rawgd = [];
    end
    if ~isempty(temp(ii).heads)
        jhead = temp(ii).heads.juld;
        jhead(isnan(jhead)) = [];
    else
        jhead = [];
    end
    
    % TET (800)
    traj(ii).TET.juld = TET(ii);
    if isempty(traj(ii).TET.juld) || isnan(traj(ii).TET.juld)
        traj(ii).TET.stat = '9';
        traj(ii).TET.adj = 0;
    else
        traj(ii).TET.stat = '1';
        traj(ii).TET.adj = 1;
    end
    
    % DST (100)
    % Iridium data shows that DST=TET for Apex, and we assume is same with
    % ARGOS.  Cookbook 3.2.2.1.2
    if ii>1
        traj(ii).DST.juld = TET(ii-1);
    else
        tmp = sscanf(dbdat.launchdate,'%4d%2d%2d%2d%2d%2d');
        traj(ii).DST.juld = julian(tmp');
    end
    if isempty(traj(ii).DST.juld) || isnan(traj(ii).DST.juld)
        traj(ii).DST.stat = '9';
        traj(ii).DST.adj = 0;
    else
        traj(ii).DST.stat = '1';
        traj(ii).DST.adj = 1;
    end
    
    % PST (250) Cookbook  3.2.2.1.4.1, .2
    traj(ii).PST.juld = traj(ii).DST.juld + parklag;
    if isempty(traj(ii).PST.juld) || isnan(traj(ii).PST.juld)
        traj(ii).PST.stat = '9';
        traj(ii).PST.adj = 0;
    else
        traj(ii).PST.stat = '1';
        traj(ii).PST.adj = 1;
    end
    
    % AST (500) Cookbook  3.2.2.1.7
    traj(ii).AST.juld = nan;
    if dbdat.parkpres==dbdat.profpres
        traj(ii).AST.juld = traj(ii).TET.juld - UPTIME;
        % JULD_QC ... see QUERIES
        %traj(ii).AST.qc = "good" (ie 1 ?);
    else
        if ~isempty(fpp(ii).p_raw) && ~isempty(traj(ii).AET)
            ProfMaxPres = fpp(ii).p_raw(1);
            if ~isempty(fpp(ii).p_calibrate) && ~isnan(fpp(ii).p_calibrate(1))
                ProfMaxPres = fpp(ii).p_calibrate(1);
            end
            
            if ~isnan(ProfMaxPres)
                % If we have a ProfMaxPres (ie 1st prof msg has been recvd)
                traj(ii).AST.juld = traj(ii).AET.juld - (ProfMaxPres*3600/(9.5*864));
                
                % traj(ii).AST.qc = "not so good" ??
                % Implies value of "2", but this is "not used in RT" (ref
                % table 2). So what can we do?
                
                if traj(ii).AST.juld<(traj(ii).TET.juld-UPTIME-DPDP) ...
                        || traj(ii).AST.juld>(traj(ii).TET.juld-UPTIME)
                    % This apparently should not happen... but is this an appropriate reaction?
                    traj(ii).AST.juld = nan;
                end
            end
        end
    end
    if isnan(traj(ii).AST.juld)
        traj(ii).AST.stat = '9';
        traj(ii).AST.adj = 0; %No value, so no estimate
    else
        traj(ii).AST.stat = '1';
        traj(ii).AST.adj = 1; %estimated, so goes into adjusted fields
    end
    
    % DDET (400) Same as AST
    traj(ii).DDET.juld = traj(ii).AST.juld;
    traj(ii).DDET.stat = traj(ii).AST.stat;
    traj(ii).DDET.adj = traj(ii).AST.adj;
    
    % PET (300)    Cookbook 3.2.2.1.5
    if dbdat.parkpres~=dbdat.profpres
        % However if parkpres = profpres then there is no PET value, and it is
        % not put in N_M arrays
        traj(ii).PET.juld = traj(ii).TET.juld - UPTIME - DPDP;
        if isempty(traj(ii).PET.juld) || isnan(traj(ii).PET.juld)
            traj(ii).PET.juld = nan;
            traj(ii).PET.stat = '9';
            traj(ii).PET.adj = 0;
        else
            traj(ii).PET.stat = '1';
            traj(ii).PET.adj = 1;
        end
    end
    
    % FMT (702)
    traj(ii).FMT.juld = min([min(rawgd) min(jhead)]);
    if isempty(traj(ii).FMT.juld) || isnan(traj(ii).FMT.juld)
        traj(ii).FMT.juld = nan;
        traj(ii).FMT.stat = '9';
    else
        traj(ii).FMT.stat = '4';
    end
    traj(ii).FMT.adj = 0;
    
    % FLT - first 703 measurement
    [~,jj] = min(jhead);
    if isempty(jj) || isnan(jhead(jj))
        traj(ii).FLT.juld = nan;
        traj(ii).FLT.stat = '9';
    else
        traj(ii).FLT.juld = jhead(jj);
        traj(ii).FLT.stat = '4';
    end
    traj(ii).FLT.adj = 0;
    
    % LLT - last 703 measurement
    [~,jj] = max(jhead);
    if isempty(jj) || isnan(jhead(jj))
        traj(ii).LLT.juld = nan;
        traj(ii).LLT.stat = '9';
    else
        traj(ii).LLT.juld = jhead(jj);
        traj(ii).LLT.stat = '4';
    end
    traj(ii).LLT.adj = 0;
    
end


save(tfnm,'traj','traj_mc_order')


%--------------------------------------------------------------
function trnp = trim_LMT(trnp,lowerr)

if lowerr
    % Rare situation of LMT being a low (ie too early) value. Rejecting max
    % component value will only make this worse - need to reject all values.
    % This will cause all derived variables to be NaN.
    % Hopefully will only arise from rare corrupted events.
    trnp.raw.juld(:) = nan;
    trnp.heads.juld(:) = nan;
else
    % Usual case - LMT too high (late), prob because of ghost value. We find
    % and clobber just the event time which gave us this LMT.
    [mr,ir] = max(trnp.raw.juld);
    [mh,ih] = max(trnp.heads.juld);
    if isnan(mh) || mr>mh
        trnp.raw.juld(ir) = nan;
    else
        trnp.heads.juld(ih) = nan;
    end
end

%--------------------------------------------------------------
