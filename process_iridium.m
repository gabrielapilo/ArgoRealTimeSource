%  process_iridium function
%
% This function does all decoding for one profile and returns the float
% structure to the main which is embedded in strip_argos_msg.
%
% INPUT
%       filenam - filename of the profile to be processed - this contains all
%           relevant information as to profile number and float id.
%   pmeta  - struct with download metadata
%   dbdat  - database record for this float
%   opts  - [optional] options, a structure containing any of the following 
%           fields:
%     .rtmode - [default from SYS PARAM] 0=delayed-mode reprocessing 
%     .savewk - [default from SYS_PARAM]]  
%               0=do not save intermediate work files
%               1=save file per float (overwrite previous)
%               2=save file per profile   
%     .redo   - {default .redo=[]} processing stages to redo. Eg .redo=1 means
%               force reworking stage 1 for every suitable profile
%               encountered. Can have .redo=1 or =2 or =[1 2]%
% OUTPUT  
%   profiles appended to float mat-files; 
%   processing reports, 
%   GTS message, netcdf files,
%   web pages updated and plots generated.
%
% Author: Jeff Dunn CMAR/BoM Aug 2006
%
% CALLED BY:  strip_argos_msg
%
% USAGE: process_iridium(pmeta,dbdat,opts)
%
% From dbdat we obtain:
% np0 - correction to float number due to "profiles" counted after
%       deployment but while still in the cardboard box
% subtype - Webb format number
% oxy     - does it have oxygen?
% ice     - does it have ice detection?
% tmiss   - does it have transmissiometer?

% subtypes are presently: 
%  pre-Apex   = 0
%  Apex1      = 1
%  Apex early Korea = 2
%  Apex Indian = 4
%  Apex Korea = 10
%  Apex2      = 11
%  Apex2ice Korea = 20
%  Apex2 SBE DO Korea = 22
%  Apex2ice   = 28   
%  Apex2oxyice= 31   
%  Apex2oxy   = 32   
%  Apex2oxyTmiss = 35
%  Apex2SBEoxy Indian = 38
%  ApexOptode Korea = 40
%  Apex2var Park T,P = 43
%  Apex2var Park T,P + ice detection = 44
%  ApexAPF9a   = 1001
%  ApexAPF9aOptode = 1002
%  ApexAPF9aIce = 1003
%  ApexIridium = 1004 - with and without ice (decode_iridium)
%  ApexSurfaceT Indian = 1005
%  ApexIridiumO2 = 1006  (decode_iridium) with and without flbb sensor
%  ApexIridiumSBEOxy = 1007  (decode_iridium)
%  ApexIridiumSBEOxy = 1008 - with flbb
%  ApexAPF9Indian = 1010
%  ApexAPF9 with an extra point = 1011
%  ApexAPF9 format (oxygen, 1002) with extra point = 1012
%  ApexAPF9 with engineering data at end of data = 1014
%  Solo Polynya floats = 1015
%  Seabird Navis Vanilla float = 1016
%  Seabird Navis Optical Oxygen = 1017
%  MRV Solo II Vanilla = 1018
%  Webb APF11 = 1019
%  Webb ApexAPF9OxyFLBB (no CDOM, Anderaa optode) = 1020
%  Webb ApexAPF9Oxy (Indian floats, Anderaa optode) = 1022
%  Webb ApexAPF11 latest firmware = 1023
%  Seabird Navis Optical Oxygen with CDOM, ECO puck, CROVER and FLBB and O2T reported in volts= 1026
%  Seabird Navis Optical Oxygen with FLBB and SUNAand O2T reported in volts = 1027 
%  Seabird Navis Optical Oxygen  with flbb2 and O2T reported in volts = 1028
%  Seabird Navis Optical Oxygen  with flbb2, irradiance with PAR, pH and O2T reported in volts = 1029
%  Apex Suna (early model) Oxygen with Nitrates only - Peter Thompson float = 1030
%  
%
% usage:  process_iridium(pmeta,dbdat,opts)

function process_iridium(pmeta,dbdat,opts)

global ARGO_SYS_PARAM
global PREC_FNM PROC_REC_WMO PROC_RECORDS
global ARGO_REPORT ARGO_RPT_FID
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO

[ dbdat.argos_id dbdat.wmo_id ]
idatapath = ARGO_SYS_PARAM.iridium_path;

if ~isempty(strfind('expected',dbdat.status))
     logerr(4,['Expected float ' num2str(pmeta.wmo_id) ' reported'])
     return
end
    
if isempty(THE_ARGO_BIO_CAL_DB)
    getBiocaldbase
end
bc=[];

fn=pmeta.ftp_fname;
jnow=julian(clock);      % Local time - now
if nargin<3
    opts = [];
end

if ~isfield(opts,'rtmode') || isempty(opts.rtmode)
    opts.rtmode = ARGO_SYS_PARAM.rtmode;
end
if ~isfield(opts,'savewk') || isempty(opts.savewk)
    opts.savewk = ARGO_SYS_PARAM.save_work_files;
end
if ~isfield(opts,'redo')
    opts.redo = [];
end
if ~isfield(opts,'nocrc')
    opts.nocrc = 0;
end

fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
ss=strfind(fn,'.');
np=str2num(fn(ss(1)+1:ss(2)-1));
if(np==0);return;end

stage = 1;
pro = new_profile_struct(dbdat);
cal_rep = zeros(1,6);


if ~exist([fnm '.mat'],'file')
    logerr(3,[fnm ' not found - opening new float file']);
    float = pro;           %new_profile_struct(dbdat);
    %   pro = new_profile_struct(dbdat);
else
    
    load(fnm,'float');
    
    stage = unique([stage opts.redo]);
    ss=strfind(fn,'.');
    np=str2num(fn(ss(1)+1:ss(2)-1));
    if(length(float)<np);
        float(np)=new_profile_struct(dbdat);
    end
    
    if(isempty(float(np).proc_stage))
        float(np).proc_stage=1;
    end
    if float(np).rework==1
        % Leave stage=1, but now clear the rework flag (only want to
        % reprocess it once, not on every subsequent run!)
        float(np).rework = 0;
        %these are irrelevant for iridium since you need to copy the
        %profile file back ot the upper irectory to reprocess so it's
        %always a deliberate move...
        %      elseif float(np).proc_stage==1
        %         stage = 2;
        %      else
        %         % Already fully handled this profile, so do no more.
        %         stage = [];
    end
end

if dbdat.subtype==1029
    p=[];
    t=[];
    s=[];
    O2phase = [];
    T_volts = [];
    Fsig = [];
    Bbsig700 = [];
    Bbsig532 =[];
    irr380 = [];
    irr412 = [];
    irr490 = [];
    irrPAR =[];
    if dbdat.pH
        pH = [];
        pHT = [];
        Tilt = [];
        Tilt_sd=[];
    end
    
end
   
if ~isempty(stage)
    % --- Find the processing record for this float
    
    nprec = find(PROC_REC_WMO==dbdat.wmo_id);
    if isempty(nprec)
        logerr(3,['Creating new processing record as none found for float ' ...
            num2str(dbdat.wmo_id)]);
        nprec = length(PROC_REC_WMO) + 1;
        PROC_REC_WMO(nprec) = dbdat.wmo_id;
        if isempty(PROC_RECORDS)
            % This only ever happens when initialising a new processing system
            PROC_RECORDS = new_proc_rec_struct(dbdat,np);
        else
            PROC_RECORDS(nprec) = new_proc_rec_struct(dbdat,np);
        end
    end
    
    if any(stage==2)
        % Add to record from earlier processing stages
        prec = PROC_RECORDS(nprec);
    else
        % New profile, so get a record set to initial state:
        %  - IDs and profile number loaded
        %  - .new = 1
        %  - .*_count = 99
        %  - proc_status and stage_ecnt zeroed
        prec = new_proc_rec_struct(dbdat,np);
    end
    
    % .new tells the daily report program that this record has been updated.
    % (That program clears the flagged after generating the report page.)
    prec.new = 1;
end


% now begin real processing of the data - do not do this in a subroutine as
% was done for 'decode_webb'

if any(stage==1)
    % --- Decode the profile
    %   (but wait until we have looked at date/pos data below, before
    %    further work on the profile data)
    
    % Set status to "stage 1 has failed", until we have succeeded!
    prec.proc_status(1) = -1;
    
    %trust the profile number reported by the float - but check for rollover later!
    pro.profile_number=np;
    
    %     for 5905023, 5905194, 5905197, 5905198 BGC floats only, initiate mission swapping based on pn:
    if isfield(ARGO_SYS_PARAM,'processor')
        if ~isempty(strmatch('CSIRO',ARGO_SYS_PARAM.processor))
            if dbdat.wmo_id==5905023 | dbdat.wmo_id==5905194 | dbdat.wmo_id==5905197 ...
                    | dbdat.wmo_id==5905395 | dbdat.wmo_id == 5905396 ...
                    | dbdat.wmo_id == 5905397
                if np > 8
                    swap_missions(np,dbdat.argos_hex_id, dbdat.wmo_id);
                end
            end
        end
    end
    pro.position_accuracy= repmat('G',1,length(pro.lat));
    pro.SN=dbdat.maker_id;
    ff=0;
    
    try
        fclose(fid)
    end
    
    
    cullMissions_iridium(dbdat,[idatapath fn]);
    
%     %before we begin, let's read in the data for biofloats (data only).
%     %Use this rather than reading in the line-by-line data
%     if dbdat.subtype >= 1026 & dbdat.subtype <= 1029
%         biodat = bio_navis_parse(dbdat.maker_id,np,0);
%     end
    
    %open the message file for reading.
    fid=fopen([idatapath fn]);
    c = textscan(fid,'%s','delimiter','\n');
    fclose(fid)
    c = c{:};
    j=0;

    %first lines are park data:
    ii = find(strncmp('ParkPt',c,6));
    if isempty(ii)
        ii = find(strncmp('ParkObs:',c,8));
    end        
    for a = 1:length(ii)
        gg = c{ii(a)};
        j=j+1;
%         if strmatch('ParkPts',gg);ll=12;dd=53;end
%         if strmatch('ParkObs',gg);ll=9;dd=32;end
        if dbdat.subtype==1017 
            pro.park_date(j,1:6)=datevec(gg(15:34));
            pro.park_jday(j)=julian(pro.park_date(j,1:6));
            pd=sscanf(gg(56:end),'%f');
            pro.park_p(j)=pd(1);
            pro.park_t(j)=pd(2);
            if(length(gg)>71);pro.park_s(j)=pd(3);end
            if(length(gg)>78);pro.park_O2phase(j)=pd(4);end
            if(length(gg)>85);pro.parkT_SBEO2(j)=pd(5);end
        elseif dbdat.subtype==1026 | dbdat.subtype==1027 ...
                | dbdat.subtype==1028 | dbdat.subtype==1029 | ...
                dbdat.subtype == 1031
            pro.park_date(j,1:6)=datevec(gg(9:31));
            pro.park_jday(j)=julian(pro.park_date(j,1:6));
            pd=sscanf(gg(32:end),'%f');
            pro.park_p(j)=pd(1);
            pro.park_t(j)=pd(2);
            if(length(pd)>2);pro.park_s(j)=pd(3);end
            if(length(pd)>3);pro.park_O2phase(j)=pd(4);end
            if(length(pd)>4);pro.parkT_volts(j)=pd(5);end
            if(length(pd)>5);pro.park_pHvolts(j)=pd(6);end
            if(length(pd)>6);pro.park_pHT(j)=pd(7);end
            
        else
            pro.park_date(j,1:6)=datevec(gg(12:32));
            pro.park_jday(j)=julian(pro.park_date(j,1:6));
            pd=sscanf(gg(53:end),'%f');
            pro.park_p(j)=pd(1);
            pro.park_t(j)=pd(2);
            if(length(gg)>68);pro.park_s(j)=pd(3);end
            if(length(gg)>76) & length(pd)>3; pro.park_SBEOxyfreq(j)=pd(4);end
        end
    end
    if(~isempty(pro.park_s))
        pro.park_s=change(pro.park_s,'==',0,NaN);
    end
    if(isfield(pro,'park_SBEOxyfreq'))
        if(~isempty(pro.park_SBEOxyfreq))
            pro.park_SBEOxyfreq=change(pro.park_SBEOxyfreq,'==',0,NaN);
        end
    end
    
    %the next line is the profile end time: check you have the
    %right line, then check that the date is sensible
    ii = find(strncmp('$ Profile',c,9));
    if ~isempty(ii) && ii <= length(c)   % note - this appears to be identical for all formats
        gg = c{ii};
        jday_ascent_end= julian(datevec(gg(36:end)));
        jdays = jday_ascent_end;
        dt_min = [1997 1 1 0 0 0];
        dt_max = [datestr(now+3,31)];
        kk=strfind(dt_max,'-');
        dt_max(kk)=' ';
        kk=strfind(dt_max,':');
        
        dt_max=[str2num(dt_max(1:4)) 12 31 23 59 59];
        dt_maxj=julian(dt_max);
        dt_minj=julian(dt_min);
        
        head=gregorian(jdays);
        if any(head(1:6)<dt_min) || any(head(1:6)>dt_max)
            logerr(2,['Implausible date/time components: ' num2str(head(1:6))]);
            jdays = NaN;
        elseif jdays<dt_minj || jdays>dt_maxj
            logerr(2,['Implausible date/time components: ' num2str(head(1:6))]);
            jdays = NaN;
        end
        gdhed = find(~isnan(jdays));
        if isempty(gdhed)
            logerr(1,'No usable date info');
            return
        end
    else
        logerr(3,['bad ascent end ' num2str(pmeta.wmo_id)]);
    end
  
    l=0;
    ii = find(strncmp('$ Discrete',c,10));
    if ~isempty(ii) 
        gg = c{ii};
        p_samples=str2num(gg(20:end));
        ii = ii+1;
        for k=1:p_samples
            ii = ii+1;
            if ii > length(c)
                break
            end
            gg=c{ii};
            j=j+1;
            parkd=sscanf(gg,'%f');
            if dbdat.oxy            %dbdat.subtype==1006  | dbdat.subtype==1007  | dbdat.subtype==1008 | dbdat.subtype==1020 % this is the oxygen profile area:
                if k==1
                    pro.park_p(j)=parkd(1);
                    pro.park_t(j)=parkd(2);
                    pro.park_s(j)=parkd(3);
                    if dbdat.subtype==1007
                        pro.park_SBEOxyfreq(j)=parkd(4);
                    elseif dbdat.subtype==1008
                        pro.park_SBEOxyfreq(j)=parkd(4);
                        pro.parkFsig(j) = parkd(5);  % CHLa raw counts
                        pro.parkBbsig(j) = parkd(6);
                        pro.parkTsig(j) = parkd(7);
                    elseif dbdat.subtype==1017
                        pro.park_O2phase(j) =   parkd(4);
                        pro.parkT_SBEO2(j) =    parkd(5);
                    elseif dbdat.subtype==1022 | dbdat.subtype==1030  % ========= added by uday ===========
                        pro.parkToptode(j) = parkd(4);
                        pro.park_Tphase(j) = parkd(5);
                        pro.park_Rphase(j) = parkd(6);
                        if dbdat.flbb
                            pro.parkFsig(j) = parkd(7);
                            pro.parkBbsig(j) = parkd(8);
                            pro.parkTsig(j) = parkd(9);
                        end			% ========= end of modification =========
                    elseif dbdat.subtype==1026
                        if parkd(4)>=99.
                            pro.park_O2phase(j)=NaN;
                        else
                            pro.park_O2phase(j) = parkd(4);
                        end
                        pro.parkT_volts(j) =  parkd(5);
                        pro.parkFsig(j) = parkd(6);  % CHLa raw counts
                        pro.parkBbsig(j) = parkd(7);
                        pro.parkCdsig(j) = parkd(8);  %CDOM raw counts
                        pro.park_irr412(j) = parkd(9);
                        pro.park_irr443(j) = parkd(10);
                        pro.park_irr490(j) = parkd(11);
                        pro.park_irr555(j) = parkd(12);
                        pro.park_rad412(j) = parkd(13);
                        pro.park_rad443(j) = parkd(14);
                        pro.park_rad490(j) = parkd(15);
                        pro.park_rad555(j) = parkd(16);
                        pro.park_ecoBbsig470(j)  =parkd(17);
                        pro.park_ecoBbsig532(j)  =parkd(18);
                        pro.park_ecoBbsig700(j)  =parkd(19); %backscatters from the eco sensor - counts
                        pro.parkTmcounts(j) = parkd(20);
                        pro.parkBeamC(j)  = parkd(21);
                    elseif dbdat.subtype==1028
                        if parkd(4)>=99.
                            pro.park_O2phase(j)=NaN;
                        else
                            pro.park_O2phase(j) = parkd(4);
                        end
                        pro.parkT_volts(j) =  parkd(5);
                        pro.parkFsig(j) = parkd(6);
                        pro.parkBbsig(j) = parkd(7);
                        pro.parkBbsig532(j) = parkd(8);
                    elseif dbdat.subtype==1027 % parkd(4) is placeholder for no3
                        if parkd(4)>=99.
                            pro.park_O2phase(j)=NaN;
                        else
                            pro.park_O2phase(j) = parkd(4);
                        end
                        pro.parkT_volts(j) =  parkd(6);
                        pro.parkFsig(j) = parkd(7);
                        pro.parkBbsig(j) = parkd(8);  % 532nm version
                        pro.parkBbsig532(j) = parkd(9);  % 700nm version
                    elseif dbdat.subtype==1029
                        if parkd(4)>=99.
                            pro.park_O2phase(j)=NaN;
                        else
                            pro.park_O2phase(j) = parkd(4);
                        end
                        pro.parkT_volts(j) =  parkd(5);
                        pro.parkFsig(j) = parkd(6);
                        pro.parkBbsig(j) = parkd(7);
                        pro.parkBbsig532(j) = parkd(8);
                        pro.park_irr380(j) = parkd(9);
                        pro.park_irr412(j) = parkd(10);
                        pro.park_irr490(j) = parkd(11);
                        pro.park_irrPAR(j) = parkd(12);
                        if dbdat.pH
                            pro.park_pHvolts(j)=parkd(13);
                            pro.park_pHT(j)=parkd(14);
                            pro.park_Tilt(j)=parkd(15);
                        end
                    elseif dbdat.subtype==1031 
                        pro.park_O2phase(j)=parkd(5);
                        pro.parkT_volts(j) =  parkd(6);
                        pro.parkFsig(j) = parkd(7);
                        pro.parkBbsig(j) = parkd(8);
                        pro.parkBbsig532(j) = parkd(9);
                        pro.park_irr412(j) = parkd(11);
                        pro.park_irr443(j) = parkd(11);
                        pro.park_irr490(j) = parkd(12);
                        pro.park_irr555(j) = parkd(13);
                        pro.park_rad412(j) = parkd(14);
                        pro.park_rad443(j) = parkd(15);
                        pro.park_rad490(j) = parkd(16);
                        pro.park_rad555(j) = parkd(17);
                        pro.park_tilt(j) = parkd(18);
                    else
                        pro.park_Bphase(j)=parkd(4);
                        pro.parkToptode(j)=parkd(5);
                        if dbdat.flbb
                            pro.parkFsig(j) = parkd(6);
                            pro.parkBbsig(j) = parkd(7);
                            if dbdat.subtype == 1006
                                pro.parkCdsig(j) = parkd(8);
                                pro.parkTsig(j) = parkd(9);
                            else
                                pro.parkTsig(j) = parkd(8);
                            end
                        end
                    end
                else
                    if dbdat.subtype==1006 | dbdat.subtype == 1020
                        pro.p_oxygen(k-1)=parkd(1);
                        pro.t_oxygen(k-1)=parkd(2);
                        pro.s_oxygen(k-1)=parkd(3);
                        pro.Bphase_raw(k-1)=parkd(4);
                        pro.oxyT_raw(k-1)=parkd(5);
                        if dbdat.flbb
                            pro.Fsig(k-1) = parkd(6);
                            pro.Bbsig(k-1) = parkd(7);
                            if dbdat.subtype == 1006
                                pro.Cdsig(k-1) = parkd(8);
                                pro.Tsig(k-1) = parkd(9);
                            else
                                pro.Tsig(k-1) = parkd(8);
                            end
                        end
                    elseif dbdat.subtype== 1022  % added by uday
                        pro.p_oxygen(k-1)=parkd(1);
                        pro.t_oxygen(k-1)=parkd(2);
                        pro.s_oxygen(k-1)=parkd(3);
                        pro.oxyT_raw(k-1)=parkd(4);
                        pro.Tphase_raw(k-1)=parkd(5);
                        pro.Rphase_raw(k-1)=parkd(6);
                        if dbdat.flbb
                            pro.Fsig(k-1) = parkd(7);
                            pro.Bbsig(k-1) = parkd(8);
                            pro.Tsig(k-1) = parkd(9);
                        end
                    elseif dbdat.subtype== 1030  % Peter Thompson's float
                        pro.p_oxygen(k-1)=parkd(1);
                        pro.t_oxygen(k-1)=parkd(2);
                        pro.s_oxygen(k-1)=parkd(3);
                        pro.oxyT_raw(k-1)=parkd(4);
                        pro.Tphase_raw(k-1)=parkd(5);
                        pro.Rphase_raw(k-1)=parkd(6);
                        pro.no3_raw(k-1)=parkd(7);
                    elseif dbdat.subtype==1008
                        j=k-1;
                        %                         l=l+1;
                        pro.p_oxygen(j)=parkd(1);
                        pro.t_oxygen(j)=parkd(2);
                        pro.s_oxygen(j)=parkd(3);
                        pro.SBEOxyfreq(j)=parkd(4);
                        pro.Fsig(j) = parkd(5);
                        pro.Bbsig(j) = parkd(6);
                        pro.Tsig(j) = parkd(7);
                    elseif dbdat.subtype==1007
                        %low res samples before CP starts:
                        l=l+1;
                        pro.p_raw(l)=parkd(1);
                        pro.t_raw(l)=parkd(2);
                        pro.s_raw(l)=parkd(3);
                        pro.SBEOxyfreq_raw(l)=parkd(4);
                    elseif dbdat.subtype==1017
                        j=k-1;
                        pro.p_oxygen(k-1)=parkd(1);
                        pro.t_oxygen(k-1)=parkd(2);
                        pro.s_oxygen(k-1)=parkd(3);
                        pro.O2phase_raw(k-1)=parkd(4);
                        pro.oxyT_raw(k-1)=parkd(5);
                    elseif dbdat.subtype==1029 %- subsampled data as well as CP data - concatenate!
                        p(k-1)=parkd(1);
                        t(k-1)=parkd(2);
                        s(k-1)=parkd(3);
                        O2phase(k-1) = parkd(4);
                        T_volts(k-1) =  parkd(5);
                        Fsig(k-1) = parkd(6);  % CHLa raw counts
                        Bbsig700(k-1) = parkd(7);
                        Bbsig532(k-1) = parkd(8);  %CDOM raw counts
                        irr380(k-1) = parkd(9);
                        irr412(k-1) = parkd(10);
                        irr490(k-1) = parkd(11);
                        irrPAR(k-1) = parkd(12);
                        if dbdat.pH
                            pH(k-1) = parkd(13);
                            pHT(k-1) = parkd(14);
                            Tilt(k-1) = parkd(15);
                            Tilt_sd(k-1)=NaN;
                        end
                    elseif dbdat.subtype==1028 %- don't measure discrete samples except for one park value
%                         pro.p_oxygen(k-1)=parkd(1);
%                         pro.t_oxygen(k-1)=parkd(2);
%                         pro.s_oxygen(k-1)=parkd(3);
%                         pro.park_O2phase(k-1) = parkd(4);
%                         pro.parkT_volts(k-1) =  parkd(5);
%                         pro.parkFsig(k-1) = parkd(6);
%                         pro.parkBbsig532(k-1) = parkd(7);
%                         pro.parkBbsig = parkd(8);
                    elseif dbdat.subtype==1027 | dbdat.subtype == 1031  % parkd(4) is placeholder for no3
%  don't measure anything except p, t, s and no3 discretely..
                        pro.p_oxygen(k-1)=parkd(1);
                        pro.t_oxygen(k-1)=parkd(2);
                        pro.s_oxygen(k-1)=parkd(3);
                        pro.no3_raw(k-1) = parkd(4);
%                         pro.parkT_volts(k-1) =  parkd(6);
%                         pro.parkFsig(k-1) = parkd(7);
%                         pro.parkBbsig532(k-1) = parkd(8);  % 532nm version
%                         pro.parkBbsig(k-1) = parkd(9);  % 700nm version
                        
                    end
                end
                
            elseif dbdat.subtype==1009
                if k==1
                    pro.park_p(j)=parkd(1);
                    pro.park_t(j)=parkd(2);
                    pro.park_s(j)=parkd(3);
                else
                    l=l+1;
                    pro.p_raw(l)=parkd(1);
                    pro.t_raw(l)=parkd(2);
                    pro.s_raw(l)=parkd(3);
                end
            else
                pro.park_p(j)=parkd(1);
                pro.park_t(j)=parkd(2);
                pro.park_s(j)=parkd(3);
                
            end
            
        end
        if dbdat.subtype==1006  % this is the oxygen profile area:
            pro.n_Oxysamples=length(pro.p_oxygen);
        elseif dbdat.subtype==1007    % note - there will only be one sample for oxygen for these floats
            pro.n_Oxysamples=length(pro.SBEOxyfreq_raw);
        elseif dbdat.subtype==1008
            pro.n_Oxysamples=length(pro.p_oxygen);
        elseif dbdat.subtype==1017
            pro.n_Oxysamples=length(pro.O2phase_raw);
        elseif dbdat.subtype==1020  % this is the oxygen profile area:
            pro.n_Oxysamples=length(pro.p_oxygen);
        elseif dbdat.subtype==1022 | dbdat.subtype==1030 % this is the oxygen profile area: added by uday
            pro.n_Oxysamples=length(pro.p_oxygen);
        elseif dbdat.subtype==1027 | dbdat.subtype == 1031
            pro.n_Oxysamples=length(pro.p_oxygen);
        end
        pro.n_parkaverages=length(pro.park_p);
        
    end
    jj = [];
    ii = ii+1;
    if ii <= length(c)
    gg=c{ii};  %number of profile samples
    pro.npoints=0;
        % just in case this is an under ice profile, store the date/time info now
        % and it can be overwritten later...
        jj=strfind(gg,'NBin');
        if(~isempty(jj))
            gregdate=gg(3:22);
            dd=datestr(datenum(gregdate),31);
            pro.datetime_vec= [str2num(dd(1:4)) str2num(dd(6:7)) str2num(dd(9:10)) str2num(dd(12:13)) str2num(dd(15:16)) str2num(dd(18:19))];
            pro.jday=jdays;
            pro.jday_ascent_end=jdays;
            pro.npoints=str2num(gg(jj+5:end-1));
        else %use the data from the park termination as time
            pro.datetime_vec=head;
            pro.jday=jdays;
            pro.jday_ascent_end=jdays;
        end
    end
    
    %data for the profile, get the range first
    istart = [];iend = [];
    ii = find(strncmp('#',c,1));
    if ~isempty(ii) && length(ii) > 1
        istart = ii(1)+1;
        iend = ii(2) -1;
    elseif isempty(ii)
        %no data
        pro.npoints = 0;
    else
        istart = ii(1)+1;
        iend = length(c); %assume message is short and no GPS fixes etc at end
    end
    
    if ~isempty(istart)
        j=pro.npoints+1;
        for ii = istart:iend
            gg = c{ii};
            try
                %check the whole string is convertible, else, go to the
                %next string
                h = hex2dec(gg);
                if isempty(h) %blank line
                    continue
                end
                j = j-1; %put everything in backwards
            catch
                continue
            end
            pro.p_raw(j)=hex2dec(gg(1:4))/10.;
            pro.t_raw(j)=hex2dec(gg(5:8))/1000.;
            if pro.t_raw(j) > 62.535
                pro.t_raw(j) = pro.t_raw(j) - 65.536;
            end
            
            pro.s_raw(j)=hex2dec(gg(9:12))/1000.;
            
            if dbdat.subtype==1007  | dbdat.subtype==1008
                if (length(gg)<18)                 % JRD 13/4/12
                    %                     disp(['JEFF DIAGNOSTIC: ' num2str(j)])
                    pro.SBEOxyfreq_raw(j)=NaN;
                    pro.nsamps(j)=NaN;
                else
                    pro.SBEOxyfreq_raw(j)=hex2dec(gg(13:16));
                    pro.nsamps(j)=hex2dec(gg(17:18));
                end
            elseif  dbdat.subtype==1027 | dbdat.subtype==1028  %suna float with flbb2 sensor:
                % or separate bio float with oxygen and flbb2 only - formats
                % same
                rawline = sscanf(gg,'%04x%04x%04x%02x%06x%06x%02x%06x%06x%06x%02x');
                if (rawline(1) ~= 0.000)
                    goodline = 1;
                end
                if rawline(5)==16777215
                    rawline(5)=0;
                end
%                 if rawline(5)>=99.
%                     pro.O2phase_raw(j)=NaN;
%                 else
                    pro.O2phase_raw(j)=(rawline(5)/100000.0)-10.0;
%                 end
                pro.t_oxygen_volts(j)=(rawline(6)/1000000.0)-1.0;
                pro.Fsig(j)=(rawline(8)-500);
                pro.Bbsig(j)=(rawline(9)-500); 
                pro.Bbsig532(j)=(rawline(10)-500);
                pro.nsamps(j)=rawline(4);

            
            elseif dbdat.subtype == 1031 %bio float with irrad, isus
                lt=length(gg);
                [fmtstr,bits]=SBEbitstofmtstr(gg(lt-3:lt-2));
                rawline=sscanf(gg,fmtstr);

                n=length(rawline);
                rawline(n+1)=nan;
                isum = 4;
                if (bits(1)) oxph=isum+1; isum=isum+1; else oxph=n+1; end
                if (bits(1)) oxt=isum+1; isum=isum+1; else oxt=n+1; end
                if (bits(1)) oxnbin=isum+1; isum=isum+1; else oxnbin=n+1; end
                if (bits(2)) mcfl=isum+1; isum=isum+1; else mcfl=n+1; end
                if (bits(2)) mcbb=isum+1; isum=isum+1; else mcbb=n+1; end
                if (bits(2)) mccd=isum+1; isum=isum+1; else mccd=n+1; end
                if (bits(2)) mcnbin=isum+1; isum=isum+1; else mcnbin=n+1; end
                if (bits(3)) crv=isum+1; isum=isum+1; else crv=n+1; end
                if (bits(3)) crvc=isum+1; isum=isum+1; else crvc=n+1; end
                if (bits(3)) crvnbin=isum+1; isum=isum+1; else crvnbin=n+1; end
                if (bits(4)) ocri1=isum+1; isum=isum+1; else ocri1=n+1; end
                if (bits(4)) ocri2=isum+1; isum=isum+1; else ocri2=n+1; end
                if (bits(4)) ocri3=isum+1; isum=isum+1; else ocri3=n+1; end
                if (bits(4)) ocri4=isum+1; isum=isum+1; else ocri4=n+1; end
                if (bits(4)) ocrinbin=isum+1; isum=isum+1; else ocrinbin=n+1; end
                if (bits(5)) ocrr1=isum+1; isum=isum+1; else ocrr1=n+1; end
                if (bits(5)) ocrr2=isum+1; isum=isum+1; else ocrr2=n+1; end
                if (bits(5)) ocrr3=isum+1; isum=isum+1; else ocrr3=n+1; end
                if (bits(5)) ocrr4=isum+1; isum=isum+1; else ocrr4=n+1; end
                if (bits(5)) ocrrnbin=isum+1; isum=isum+1; else ocrrnbin=n+1; end
                if (bits(6)) ecobb1=isum+1; isum=isum+1; else ecobb1=n+1; end
                if (bits(6)) ecobb2=isum+1; isum=isum+1; else ecobb2=n+1; end
                if (bits(6)) ecobb3=isum+1; isum=isum+1; else ecobb3=n+1; end                        
                if (bits(6)) econbin=isum+1; isum=isum+1; else econbin=n+1; end                        
                if (bits(7)) tilt=isum+1; isum=isum+1; else tilt=n+1; end
                if (bits(7)) tiltsd=isum+1; isum=isum+1; else tiltsd=n+1; end                        
            
%                 if rawline(oxph)>=99.
%                     pro.O2phase_raw(j)=NaN;
%                 else
                    pro.O2phase_raw(j)=(rawline(oxph)/100000.0)-10.0;
%                 end
                pro.t_oxygen_volts(j)=(rawline(oxt)/1000000.0)-1.0;
                
                pro.Fsig(j)=(rawline(mcfl)-500); % FLTNU data
                pro.Bbsig(j)=(rawline(mcbb)-500);
                pro.Bbsig532(j)=(rawline(mccd)-500);
                
              
                pro.irr412(j)=(rawline(ocri1)*1024 + 2013265920); % upward and downwelling radiances
                pro.irr443(j)=(rawline(ocri2)*1024 + 2013265920); 
                pro.irr490(j)=(rawline(ocri3)*1024 + 2013265920); 
                pro.irr555(j)=(rawline(ocri4)*1024 + 2013265920); 
                pro.rad412(j)=(rawline(ocrr1)*1024 + 2013265920); 
                pro.rad443(j)=(rawline(ocrr2)*1024 + 2013265920); 
                pro.rad490(j)=(rawline(ocrr3)*1024 + 2013265920); 
                pro.rad555(j)=(rawline(ocrr4)*1024 + 2013265920); 
                pro.Tilt(j)=(rawline(tilt)/10.0);
                pro.Tilt_sd(j)=(rawline(tiltsd)/100.0);
                
                pro.nsamps(j)=rawline(4);
            elseif dbdat.subtype==1026  % bio optical float with irradiance and fltnu sensor
                % these are self describing with the end bits telling you
                % what variables have been measured in a particular line -
                % and this can change at any point in the profile!
                
                % also note that I've chosen to ignore the checksum - if
                % there is data, we will decode it and worry about quality
                % later
                
                lt=length(gg);
                [fmtstr,bits]=SBEbitstofmtstr(gg(lt-3:lt-2));
                rawline=sscanf(gg,fmtstr);

                n=length(rawline);
                rawline(n+1)=nan;
                isum = 4;
                if (bits(1)) oxph=isum+1; isum=isum+1; else oxph=n+1; end
                if (bits(1)) oxt=isum+1; isum=isum+1; else oxt=n+1; end
                if (bits(1)) oxnbin=isum+1; isum=isum+1; else oxnbin=n+1; end
                if (bits(2)) mcfl=isum+1; isum=isum+1; else mcfl=n+1; end
                if (bits(2)) mcbb=isum+1; isum=isum+1; else mcbb=n+1; end
                if (bits(2)) mccd=isum+1; isum=isum+1; else mccd=n+1; end
                if (bits(2)) mcnbin=isum+1; isum=isum+1; else mcnbin=n+1; end
                if (bits(3)) crv=isum+1; isum=isum+1; else crv=n+1; end
                if (bits(3)) crvc=isum+1; isum=isum+1; else crvc=n+1; end
                if (bits(3)) crvnbin=isum+1; isum=isum+1; else crvnbin=n+1; end
                if (bits(4)) ocri1=isum+1; isum=isum+1; else ocri1=n+1; end
                if (bits(4)) ocri2=isum+1; isum=isum+1; else ocri2=n+1; end
                if (bits(4)) ocri3=isum+1; isum=isum+1; else ocri3=n+1; end
                if (bits(4)) ocri4=isum+1; isum=isum+1; else ocri4=n+1; end
                if (bits(4)) ocrinbin=isum+1; isum=isum+1; else ocrinbin=n+1; end
                if (bits(5)) ocrr1=isum+1; isum=isum+1; else ocrr1=n+1; end
                if (bits(5)) ocrr2=isum+1; isum=isum+1; else ocrr2=n+1; end
                if (bits(5)) ocrr3=isum+1; isum=isum+1; else ocrr3=n+1; end
                if (bits(5)) ocrr4=isum+1; isum=isum+1; else ocrr4=n+1; end
                if (bits(5)) ocrrnbin=isum+1; isum=isum+1; else ocrrnbin=n+1; end
                if (bits(6)) ecobb1=isum+1; isum=isum+1; else ecobb1=n+1; end
                if (bits(6)) ecobb2=isum+1; isum=isum+1; else ecobb2=n+1; end
                if (bits(6)) ecobb3=isum+1; isum=isum+1; else ecobb3=n+1; end                        
                if (bits(6)) econbin=isum+1; isum=isum+1; else econbin=n+1; end                        
            
%                 if rawline(oxph)>=99.
%                     pro.O2phase_raw(j)=NaN;
%                 else
                    pro.O2phase_raw(j)=(rawline(oxph)/100000.0)-10.0;
%                 end
                pro.t_oxygen_volts(j)=(rawline(oxt)/1000000.0)-1.0;
                
                pro.Fsig(j)=(rawline(mcfl)-500); % FLTNU data
                pro.Cdsig(j)=(rawline(mccd)-500); 
                pro.Bbsig(j)=(rawline(mcbb)-500);
                
                pro.tm_counts(j)=(rawline(crv)-200); % C Rover data
                pro.BeamC(j)=(rawline(crvc)/1000.0)-10.0;
                
                pro.irr412(j)=(rawline(ocri1)*1024 + 2013265920); % upward and downwelling radiances
                pro.irr443(j)=(rawline(ocri2)*1024 + 2013265920); 
                pro.irr490(j)=(rawline(ocri3)*1024 + 2013265920); 
                pro.irr555(j)=(rawline(ocri4)*1024 + 2013265920); 
                pro.rad412(j)=(rawline(ocrr1)*1024 + 2013265920); 
                pro.rad443(j)=(rawline(ocrr2)*1024 + 2013265920); 
                pro.rad490(j)=(rawline(ocrr3)*1024 + 2013265920); 
                pro.rad555(j)=(rawline(ocrr4)*1024 + 2013265920); 
                
                pro.ecoBbsig470(j)=(rawline(ecobb1)-500); %eco puck data - 3 BB values
                pro.ecoBbsig532(j)=(rawline(ecobb2)-500); 
                pro.ecoBbsig700(j)=(rawline(ecobb3)-500); 

                pro.nsamps(j)=rawline(4);

            elseif dbdat.subtype==1029
                % these are self describing with the end bits telling you
                % what variables have been measured in a particular line -
                % and this can change at any point in the profile!
                
                % also note that I've chosen to ignore the checksum - if
                % there is data, we will decode it and worry about quality
                % later
                
                lt=length(gg);
%                 if lt<90
%                     lt=lt
%                 end
                [fmtstr,bits]=SBEbitstofmtstr(gg(lt-3:lt-2),'noswap');
                rawline=sscanf(gg,fmtstr);

                n=length(rawline);
                rawline(n+1)=nan;
                isum = 4;
                if (bits(1)) oxph=isum+1; isum=isum+1; else oxph=n+1; end
                if (bits(1)) oxt=isum+1; isum=isum+1; else oxt=n+1; end
                if (bits(1)) oxnbin=isum+1; isum=isum+1; else oxnbin=n+1; end
                if (bits(2)) mcfl=isum+1; isum=isum+1; else mcfl=n+1; end
                if (bits(2)) mcbb=isum+1; isum=isum+1; else mcbb=n+1; end
                if (bits(2)) mcbb2=isum+1; isum=isum+1; else mcbb2=n+1; end
                if (bits(2)) mcnbin=isum+1; isum=isum+1; else mcnbin=n+1; end
                if (bits(3)) crv=isum+1; isum=isum+1; else crv=n+1; end
                if (bits(3)) crvc=isum+1; isum=isum+1; else crvc=n+1; end
                if (bits(3)) crvnbin=isum+1; isum=isum+1; else crvnbin=n+1; end
                if (bits(4)) ocri1=isum+1; isum=isum+1; else ocri1=n+1; end
                if (bits(4)) ocri2=isum+1; isum=isum+1; else ocri2=n+1; end
                if (bits(4)) ocri3=isum+1; isum=isum+1; else ocri3=n+1; end
                if (bits(4)) ocri4=isum+1; isum=isum+1; else ocri4=n+1; end
                if (bits(4)) ocrinbin=isum+1; isum=isum+1; else ocrinbin=n+1; end
                if (bits(7)) tilt=isum+1; isum=isum+1; else tilt=n+1; end
                if (bits(7)) tiltsd=isum+1; isum=isum+1; else tiltsd=n+1; end                        
                if (bits(8)) pHv=isum+1; isum=isum+1; else pHv=n+1; end
                if (bits(8)) pHt=isum+1; isum=isum+1; else pHt=n+1; end
                if (bits(8)) pHbin=isum+1; isum=isum+1; else pHbin=n+1; end                        
            
%                 if rawline(oxph)>=99.
%                     pro.O2phase_raw(j)=NaN;
%                 else
                pro.O2phase_raw(j)=(rawline(oxph)/100000.0)-10.0;
%                 end
                pro.t_oxygen_volts(j)=(rawline(oxt)/1000000.0)-1.0;
                
                pro.Fsig(j)=(rawline(mcfl)-500); % FLTNU data
                pro.Bbsig(j)=(rawline(mcbb)-500);
                pro.Bbsig532(j)=(rawline(mcbb2)-500);
 
                pro.irr380(j)=(rawline(ocri2)*1024 + 2013265920);                              
                pro.irr412(j)=(rawline(ocri1)*1024 + 2013265920); % upward and downwelling radiances
                pro.irr490(j)=(rawline(ocri3)*1024 + 2013265920); 
                pro.irrPAR(j)=(rawline(ocri4)*1024 + 2013265920); 
                
                if dbdat.pH
                    pro.pHvolts(j)=(rawline(pHv)/1000000.0 - 2.5); %eco puck data - 3 BB values
                    pro.pHT(j)=(rawline(pHt)/1000.);
                    if pro.pHT(j)>61440
                        pro.pHT=(rawline(pHt)-65536)/1000.;
                    end
                    
                    pro.Tilt(j)=(rawline(tilt)/10.0);
                    pro.Tilt_sd(j)=(rawline(tiltsd)/100.0);
                end
                pro.nsamps(j)=rawline(4);
           
            else
                if(length(gg)<14)
                    pro.nsamps(j)=NaN;
                else
                    pro.nsamps(j)=hex2dec(gg(13:14));
                end
            end
        end
    end
 
    
    yy=find(pro.p_raw==0 & pro.t_raw==0 & pro.s_raw==0);
    if ~isempty(yy)
       pro=remove_emptydata(pro,yy); 
    end
    
    % now need to concatenate subsampled with CP sampled data for 1029
    % subtype
    if dbdat.subtype==1029
        pro.p_raw=[p pro.p_raw];
        pro.s_raw=[s pro.s_raw];
        pro.t_raw=[t pro.t_raw];
        pro.O2phase_raw=[O2phase pro.O2phase_raw];
        pro.t_oxygen_volts=[T_volts pro.t_oxygen_volts];
        pro.Fsig=[Fsig pro.Fsig];
        pro.Bbsig532=[Bbsig532 pro.Bbsig532];
        pro.Bbsig=[Bbsig700 pro.Bbsig];
        
        pro.irr380=[irr380  pro.irr380];
        pro.irr412=[irr412 pro.irr412];
        pro.irr490=[irr490 pro.irr490];
        pro.irrPAR=[irrPAR pro.irrPAR];
        if dbdat.pH
            pro.pHvolts=[pH pro.pHvolts];
            pro.pHT=[pHT pro.pHT];
            
            pro.Tilt=[Tilt pro.Tilt];
            pro.Tilt_sd=[Tilt_sd pro.Tilt_sd];
        end
    end
     
    pro.npoints=length(pro.p_raw);
    
    %     if(gg~=-1)  %under ice profile that doesn't have location information...
    %             if(isempty(strfind(gg,'GPS fix failed')) && isempty(strfind(gg,'GPS fix not available')));
    %
    %                 %now get position information from GPS:
    %                 kk=strfind(gg,'in ');
    %                 k2=strfind(gg,' seconds');
    %                 pro.GPSfixtime=gg(kk+3:k2-1);
    %                 gg=fgetl(fid);
    %                 gg=fgetl(fid);     %lat and long
    %                 pro.lat=sscanf(gg(15:21),'%f');
    %                 pro.lon=sscanf(gg(5:14),'%f');
    %                 if pro.lon<0; pro.lon=360+pro.lon; end
    %                 location_date=[str2num(gg(29:32)) str2num(gg(23:24)) str2num(gg(26:27)) ...
    %                     str2num(gg(34:35)) str2num(gg(36:37)) str2num(gg(38:39))];
    %                 pro.datetime_vec(1,1:6)=location_date;
    %                 pro.jday_location=julian(location_date);
    %                 pro.GPSsatellites=str2num(gg(40:end));
    %                 pro.jday=jdays;
    %                 pro.jday_ascent_end=jdays;
    %                 gg=fgetl(fid);
    ii = find(strncmp('# Ice evasion initiated',c,23));
    if ~isempty(ii)
        pro.icedetection=1;
        % decode depth
        % flag this message = 1
    end
    ii = find(strncmp('# Ice-cap',c,9));
    if ~isempty(ii)
        pro.icedetection=1;
    end
    ii = find(strncmp('# Leads or break-up of surface ice',c,34));
    if ~isempty(ii)
        %                 flag this message 3
        pro.icedetection=1;
    end
    
    %technical information for direct recording (no calculations)
    str = {'IceMLMedianT','IceMLSample','ActiveBallastAdjustments',...
        'AirBladderPressure',...
        'BuoyancyPumpOnTime',...
        'CurrentPistonPosition','DeepProfilePistonPosition',...
        'GpsFixTime','ParkPistonPosition','ParkBuoyancyPosition',...
        'RtcSkew',...
        'Sbe41cpStatus','SurfacePistonPosition',...
        'SurfaceBuoyancyPosition'};
    str2 = {'iceMLMedianT','iceMLSamples','n_parkbuoyancy_adj',...
        'airbladderpres',...
        'pumpmotortime',...
        'maxpistonpos','profilepistonpos',...
        'GPSfixtime','parkpistonpos','parkpistonpos',...
        'RTCskew',...
        'SBE41status','pistonpos',...
        'pistonpos'};
    
    for a = 1:length(str)
        ii = find(strncmp(str{a},c,length(str{a})));
        if ~isempty(ii)
            %             for b = 1:length(ii)
            %sometimes more than one report of tech data, but will
            %                 probably break everything if we collect all, so just
            %                 first one for now? Should be the same data each time?
            gg = c{ii(1)};
            ll=strfind(gg,'=');
            pro.(str2{a})=str2num(gg(ll+1:end));
            %             end
        end
    end
    
    %some of the tech info that requires calculation:
    %currents
    str = {'AirPumpAmps','BuoyancyPumpAmps','QuiescentAmps',...
        'Sbe41cpAmps'};
    str2 = {'airpumpcurrent','buoyancypumpcurrent','parkbatterycurrent',...
        'SBEpumpcurrent'};
    for a = 1:length(str)
        ii = find(strncmp(str{a},c,length(str{a})));
        if ~isempty(ii)
            gg = c{ii(1)};
            ll=strfind(gg,'=');
            if dbdat.maker == 4
                pro.(str2{a})= calc_current_navis(str2num(gg(ll+1:end)));
            else
                pro.(str2{a})=(str2num(gg(ll+1:end)) * 4.052) - 3.606;
            end
        end
    end
    %volts
    str = {'AirPumpVolts','BuoyancyPumpVolts','QuiescentVolts',...
        'Sbe41cpVolts'};
    str2 = {'airpumpvoltage','buoyancypumpvoltage','parkbatteryvoltage',...
        'SBEpumpvoltage'};
    for a = 1:length(str)
        ii = find(strncmp(str{a},c,length(str{a})));
        if ~isempty(ii)
            gg = c{ii(1)};
            ll=strfind(gg,'=');
            if dbdat.maker == 4
                pro.(str2{a})=calc_volt_navis(str2num(gg(ll+1:end)));
            else
                pro.(str2{a})=calc_volt9a(str2num(gg(ll+1:end)));
            end
        end
    end
    %we are not decoding these yet:
    %             elseif strmatch('Apf9i',gg)
    %             elseif strmatch('FloatId',gg)
    %             elseif strmatch('ParkDescentP',gg)
    %             elseif strmatch('ParkObs',gg)
    %             elseif strmatch('ProfileId',gg)
    %             elseif strmatch('ObsIndex',gg)
    
    %Others:
    ii = find(strncmp('status',c,6));
    if ~isempty(ii)
        gg = c{ii(1)};
        ll=strfind(gg,'=');
        l2=strfind(gg(ll+1:end),'x');
        pro.sfc_termination=[dec2hex(str2num(gg(ll+1:ll+l2-1))) dec2hex(str2num(gg(ll+l2+1:end)))];
    end
    ii = find(strncmp('SurfacePressure',c,15));
    if ~isempty(ii)
        gg = c{ii(1)};
        ll=strfind(gg,'=');
        pro.surfpres =str2num(gg(ll+1:end));
        pro.surfpres_qc=0;
        pro.surfpres_used=pro.surfpres;
    end
    ii = find(strncmp('Vacuum',c,6));
    if ~isempty(ii)
        gg = c{ii(1)};
        ll=strfind(gg,'=');
        if dbdat.maker == 4
            pro.p_internal = str2num(gg(ll+1:end))*0.2878 - 29.8571;
        else
            pro.p_internal=(0.293 * str2num(gg(ll+1:end)) - 29.767);
        end
    end
    ii = find(strncmp('# GPS fix',c,9));
    if ~isempty(ii)
        for ff = 1:length(ii)
            gg = c{ii(ff)};
            %now get position information from GPS:
            kk=strfind(gg,'in ');
            k2=strfind(gg,' seconds');
            gl=gg(kk+3:k2-1);
            if ff==1
                pro.GPSfixtime=gl;
            else
                pro.GPSfixtime(ff,1:k2-kk-3)=gl;
            end
            
            if ii(ff)+2 > length(c)
                break
            end
            gg=c{ii(ff)+2};     %lat and long
            if dbdat.maker==4  % == 1016 | dbdat.subtype == 1017
                pro.lat(ff)=sscanf(gg(15:23),'%f');
                pro.lon(ff)=sscanf(gg(5:14),'%f');
            else
                pro.lat(ff)=sscanf(gg(14:21),'%f');
                pro.lon(ff)=sscanf(gg(5:14),'%f');
            end
            if pro.lon(ff)<0; pro.lon(ff)=360+pro.lon(ff); end
            if dbdat.maker == 4  %subtype == 1016 | dbdat.subtype == 1017
                location_date=[str2num(gg(31:34)) str2num(gg(25:26)) str2num(gg(28:29)) ...
                    str2num(gg(36:37)) str2num(gg(38:39)) str2num(gg(40:41))];
                pro.datetime_vec(ff,1:6)=location_date;
                pro.jday_location(ff)=julian(location_date);
                pro.GPSsatellites(ff)=str2num(gg(42:end));
            else
                location_date=[str2num(gg(29:32)) str2num(gg(23:24)) str2num(gg(26:27)) ...
                    str2num(gg(34:35)) str2num(gg(36:37)) str2num(gg(38:39))];
                pro.datetime_vec(ff,1:6)=location_date;
                pro.jday_location(ff)=julian(location_date);
                try
                    pro.GPSsatellites(ff)=str2num(gg(40:end));
                catch
                    pro.GPSsatellites(ff)= NaN;
                end
            end
            
            % Tests if location_date is acceptable; if not, uses profile date
                J1 = julian([1997 1 1 0 0 0]);
                J2 = julian(str2num(datestr(now,'yyyy mm dd HH MM SS')));
                ibad = julian(location_date) < J1 | julian(location_date) > J2;
                if any(ibad)
                    location_date = gregorian(jdays);
                    pro.datetime_vec(ff,1:6)=location_date;
                    pro.jday_location(ff)=julian(location_date);
                end
                
            pro.jday=jdays;
            pro.jday_ascent_end=jdays;
        end
        pro.pos_qc = zeros(1,length(pro.lat),'uint8');
    end
        
    % after finish loading profile, check for rollover and
    % assign fp to fpp(np)
    if(length(float)>3 & ~isempty(pro.jday))
        np=profile_rollover(pro,float,dbdat);
    end
    %check previous profile has location information, could be
    %extracted from this log file
    if length(float) > 1
        if isnan(float(np-1).lat)
            % open and parse file
            fid=fopen([pmeta.ftp_fname(1:end-3) 'log'],'r');
            if fid > 0
                [tdata] = textscan(fid,'%s','Delimiter','|');
                fclose(fid);
                %get the previous profile surface time information:
                igps = find(cellfun(@isempty,strfind(tdata{1},'Fix:')) == 0);
                if ~isempty(igps)
                    for igg = 1:length(igps)
                        %Assume the format will remain constant:  lon     lat mm/dd/yyyy hhmmss nsat
                        fmt = 'mm/dd/yyyy HHMMSS';
                        dt = regexp(tdata{1}{igps(igg)},'\d+/\d+/\d+ [0-9]*','match');
                        if ~isempty(dt)
                            ll = regexp(tdata{1}{igps(igg)},'[-0-9]+\.[0-9]+','match');
                            float(np-1).lat(igg)=str2num(ll{2});
                            float(np-1).lon(igg)=str2num(ll{1});
                            ns = regexp(tdata{1}{igps(igg)},'[0-9]*','match');
                            ns = str2num(ns{end});
                            float(np-1).GPSsatellites(igg)=ns;
                            gl = regexp(tdata{1}{igps(igg)-2},'\w*[0-9](?=.seconds)','match');
                            float(np-1).GPSfixtime(igg)=str2num(gl{:});
                            ldt=datenum(dt{:},fmt);
                            location_date = [str2num(datestr(ldt,'yyyy')),str2num(datestr(ldt,'mm')) ...
                                ,str2num(datestr(ldt,'dd')),str2num(datestr(ldt,'HH')),str2num(datestr(ldt,'MM')),...
                                str2num(datestr(ldt,'SS'))];
                            float(np-1).datetime_vec(igg,1:6)=location_date;
                            float(np-1).jday_location(igg)=julian(location_date);
                        end
                    end
                end
                %this information goes in the current profile
                if isempty(pro.jday)
                    %next best guess is in the log file:
                    iendp = find(cellfun(@isempty,strfind(tdata{1},'Sbe41cpBinAverage')) == 0);
                    if ~isempty(iendp)
                        t_date = datenum(tdata{1}{iendp}(2:21),'mmm dd yyyy HH:MM:SS');
                        jdays =  [str2num(datestr(t_date,'yyyy')),str2num(datestr(t_date,'mm')) ...
                            ,str2num(datestr(t_date,'dd')),str2num(datestr(t_date,'HH')),str2num(datestr(t_date,'MM')),...
                            str2num(datestr(t_date,'SS'))];
                        pro.jday=julian(jdays);
                        pro.jday_ascent_end=julian(jdays);
                    end
                end
            end
        end
    end
    
    %check this information here:
    if ~isempty(pro.lat) & ~isempty(pro.lon)
        [maxdeps,mindeps] = get_ocean_depth(pro.lat,pro.lon,0.03);
        deps = nanmin(mindeps);
    else
        deps = NaN;
    end
    if isempty(pro.lat) | isempty(pro.lon) | isnan(deps) || deps < 0;
        logerr(2,'Implausible locations');
        goodfixes = [];
        pro.lat = NaN;
        pro.lon = NaN;
        pro.pos_qc = 9;
        if isempty(goodfixes)
            logerr(2,'No good location fixes!');
        end
    end
    
    %this is where we should now be doing the position interpolation if
    %needed.
    %                 % check for missing profile locations from ice floats and
    % add to the affected profiles:
    try
        [float,pro,gennc]=interpolate_locations(dbdat,float,pro);
    catch
        logerr(5,['Interpolate_locations.m fails for profile ' num2str(pro.profile_number)])
    end
   
    %         else
    %             logerr(2,'no locations');
    %             goodfixes = [];
    %             pro.lat = nan;
    %             pro.lon = nan;
    %             if isempty(goodfixes)
    %                 logerr(2,'No good location fixes!');
    %             end
    %             pro.sfc_termination=0;
    
    
    % now we need to convert RAW oxygen values to true oxygen:
    if(dbdat.oxy & (dbdat.subtype==1006 | dbdat.subtype==1020))
        for ii=1:pro.n_Oxysamples
            bp=pro.Bphase_raw(ii);
            if dbdat.oxysens_snum>1300 & ARGO_SYS_PARAM.datacentre=='CS'
                T=pro.t_oxygen(ii);
            else
                T=pro.oxyT_raw(ii);
            end
            if isnan(pro.lat)
                pro.oxy_raw(ii) = convertBphase(bp,T,pro.s_oxygen(ii),pro.wmo_id, ...
                    pro.p_oxygen(ii),dbdat.launch_lat);
            else
                pro.oxy_raw(ii) = convertBphase(bp,T,pro.s_oxygen(ii),pro.wmo_id, ...
                    pro.p_oxygen(ii),pro.lat(1));
            end
        end
        for ii=1:length(pro.park_Bphase)
            if dbdat.oxysens_snum>1300 & ARGO_SYS_PARAM.datacentre=='CS'
                T=pro.park_t(ii);
            else
                T=pro.parkToptode(ii);
            end
            if isnan(pro.lat)
                pro.parkO2(ii)=convertBphase(pro.park_Bphase(ii),pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                    pro.park_p(ii),dbdat.launch_lat);
            else
                if pro.park_Bphase(ii)==0
                    pro.parkO2(ii)=NaN;
                else
                    pro.parkO2(ii)=convertBphase(pro.park_Bphase(ii),pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                        pro.park_p(ii),pro.lat(1));
                end
            end
        end
        
    end
    if(dbdat.oxy & (dbdat.subtype==1007 | dbdat.subtype==1008))
        for ii=1:pro.n_parkaverages  % park data
            bp=pro.park_SBEOxyfreq(ii);
            if pro.park_p(ii) > 2
                pro.parkO2(ii) = convertSBEOxyfreq(bp,pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                    pro.park_p(ii),pro.lat(1));
            end
        end
        for ii=1:length(pro.p_raw)  % profile data
            if(pro.p_raw(ii)>2)
                pro.oxy_raw(ii)=convertSBEOxyfreq(pro.SBEOxyfreq_raw(ii),pro.t_raw(ii),pro.s_raw(ii),pro.wmo_id, ...
                    pro.p_raw(ii),pro.lat(1));
            else
                pro.oxy_raw(ii)=NaN;
            end
        end
        if isfield(pro,'p_oxygen')
            for ii=1:length(pro.p_oxygen)  % profile data
                if(pro.p_oxygen(ii)>2)
                    pro.FLBBoxy_raw(ii)=convertSBEOxyfreq(pro.SBEOxyfreq(ii),pro.t_oxygen(ii),...
                        pro.s_oxygen(ii),pro.wmo_id,pro.p_oxygen(ii),pro.lat(1));
                else
                    pro.FLBBoxy_raw(ii)=NaN;
                end
            end
        end
    end
    if(dbdat.oxy & dbdat.subtype==1017) % 
        for ii=1:pro.n_parkaverages  % park data
            bp=pro.park_O2phase(ii);
            pro.parkO2(ii)=convertSBE63Oxy(bp,pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                pro.park_p(ii),pro.lat(1));
        end
        for ii=1:length(pro.p_oxygen)
            bp=pro.O2phase_raw(ii);
            pro.oxy_raw(ii)=convertSBE63Oxy(bp,pro.t_oxygen(ii),pro.s_oxygen(ii),pro.wmo_id, ...
                pro.p_oxygen(ii),pro.lat(1));
        end
    end
    if dbdat.oxy & (dbdat.subtype==1026 | dbdat.subtype==1027 | dbdat.subtype==1028| dbdat.subtype==1029| dbdat.subtype==1030| dbdat.subtype==1031)
        %Seabird bio geochemical floats with SBE63 Optode:
        for ii=1:pro.n_parkaverages  % park data
            % first convert T volts to T90
            pro.parkToptode(ii)=convertSBE63Tv(pro.parkT_volts(ii),pro.wmo_id);
            
            bp=pro.park_O2phase(ii);
            pro.parkO2(ii)=convertSBE63Oxy(bp,pro.parkToptode(ii),pro.park_s(ii),pro.wmo_id, ...
                pro.park_p(ii),pro.lat(1));
        end
        for ii=1:length(pro.p_raw)
%             first convert T from volts to T90:
            pro.oxyT_raw(ii)=convertSBE63Tv(pro.t_oxygen_volts(ii),pro.wmo_id);

            bp=pro.O2phase_raw(ii);
            pro.oxy_raw(ii)=convertSBE63Oxy(bp,pro.oxyT_raw(ii),pro.s_raw(ii),pro.wmo_id, ...
                pro.p_raw(ii),pro.lat(1));
        end
    end
        
        
    % ======= added by uday =========
    % now we need to convert RAW oxygen values to true oxygen:
    if(dbdat.oxy & dbdat.subtype==1022)
        for ii=1:pro.n_Oxysamples
            bp=pro.Tphase_raw(ii);
            if isnan(pro.lat)
                pro.oxy_raw(ii) = convertTphase(bp,pro.t_oxygen(ii),pro.s_oxygen(ii),pro.wmo_id, ...
                    pro.p_oxygen(ii),dbdat.launch_lat);
            else
                pro.oxy_raw(ii) = convertTphase(bp,pro.t_oxygen(ii),pro.s_oxygen(ii),pro.wmo_id, ...
                    pro.p_oxygen(ii),pro.lat(1));
            end
        end
        for ii=1:length(pro.park_Tphase)
            if isnan(pro.lat)
                pro.parkO2(ii)=convertTphase(pro.park_Tphase(ii),pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                    pro.park_p(ii),dbdat.launch_lat);
            else
                if pro.park_Tphase(ii)==0
                    pro.parkO2(ii)=NaN;
                else
                    pro.parkO2(ii)=convertTphase(pro.park_Tphase(ii),pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                        pro.park_p(ii),pro.lat(1));
                end
            end
        end
    end
    if(dbdat.oxy & dbdat.subtype==1030) % note - one park O2 for Peter Thompson's floats 
%         AND it uses the Bphase code for conversion! 
        for ii=1:pro.n_Oxysamples
            bp=pro.Tphase_raw(ii);
            if isnan(pro.lat)
                pro.oxy_raw(ii) = convertBphase(bp,pro.t_oxygen(ii),pro.s_oxygen(ii),pro.wmo_id, ...
                    pro.p_oxygen(ii),dbdat.launch_lat);
            else
                pro.oxy_raw(ii) = convertBphase(bp,pro.t_oxygen(ii),pro.s_oxygen(ii),pro.wmo_id, ...
                    pro.p_oxygen(ii),pro.lat(1));
            end
        end
         for ii=1:length(pro.park_Tphase)
            if isnan(pro.lat)
                pro.parkO2(ii)=convertBphase(pro.park_Tphase(ii),pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                    pro.park_p(ii),dbdat.launch_lat);
            else
                if pro.park_Tphase(ii)==0
                    pro.parkO2(ii)=NaN;
                else
                    pro.parkO2(ii)=convertBphase(pro.park_Tphase(ii),pro.park_t(ii),pro.park_s(ii),pro.wmo_id, ...
                        pro.park_p(ii),pro.lat(1));
                end
            end
        end
   end
   
    %now we need to convert Raw FLBB data to true chlorophyll and
    %backscatter:  added by Uday
    % modified by AT to use new bio cal sheets: Aug 2015
    
    if(dbdat.flbb)  % & dbdat.subtype==1022)
        % ==== for Chlorophyll conversion
        if isempty(bc)
            bc=find(ARGO_BIO_CAL_WMO==dbdat.wmo_id);
        end
        bcal=THE_ARGO_BIO_CAL_DB(bc);
        
        if ~isempty(pro.parkFsig)
            pro.parkCHLa = convertFsig(pro.parkFsig,pro.wmo_id);
        end
        if ~isempty(pro.Fsig)
            pro.CHLa_raw = convertFsig(pro.Fsig,pro.wmo_id);
        end
        
        %         % ==== for Backscattering conversion
        bcoef=bcal_extract(bcal,700);
        if ~isempty(pro.parkBbsig)
            pro.parkBBP700=convertBbsig(pro.parkBbsig,pro.park_t,pro.park_s,700,bcoef);
        end
        if ~isempty(pro.Bbsig)
            if isfield(pro,'t_oxygen') & (length(pro.t_oxygen)==length(pro.Bbsig))
                pro.BBP700_raw=convertBbsig(pro.Bbsig,pro.t_oxygen,pro.s_oxygen,700,bcoef);
            elseif length(pro.Bbsig)==length(pro.p_raw)
                pro.BBP700_raw=convertBbsig(pro.Bbsig,pro.t_raw,pro.s_raw,700,bcoef);
            end
        end
        if isfield(pro,'Cdsig')
            if ~isempty(pro.parkCdsig)
                pro.parkCDOM=convertCdsig(pro.parkCdsig,pro.wmo_id);
            end
            if ~isempty(pro.Cdsig)
                pro.CDOM_raw=convertCdsig(pro.Cdsig,pro.wmo_id);
            end
            
        end
    end
    % ========= end of addition by uday ===========
    if dbdat.flbb2  % these sensors also measure bb at two different wavelengths (532 added)

        bcoef=bcal_extract(bcal,532);
        if ~isempty(pro.parkBbsig532)  % note - need to add indicator for which 
%             wavelength so the script takes the correct cal coeffs!     
            pro.parkBBP532=convertBbsig(pro.parkBbsig532,pro.park_t,pro.park_s,532,bcoef);
        end
        if ~isempty(pro.Bbsig532)
            pro.BBP532_raw=convertBbsig(pro.Bbsig532,pro.t_raw,pro.s_raw,532,bcoef);
        end       
   end
    
   if dbdat.eco   %these sensors measure bb at 3 different wavelengths,
       %         and CAN be on a float that already has a 700nm version on an FLBB.
       %           gets complicated!  use isfield in pro to determine what to
       %           process!
       
       bcoef=bcal_extract(bcal,470.2);
       if ~isempty(pro.park_ecoBbsig470)  % note - need to add indicator for which
           %             wavelength so the script takes the correct cal coeffs!
           pro.park_ecoBBP470_raw=convertBbsig(pro.park_ecoBbsig470,pro.park_t,pro.park_s,470,bcoef);
       end
       if ~isempty(pro.ecoBbsig470)
           pro.ecoBBP470_raw=convertBbsig(pro.ecoBbsig470,pro.t_raw,pro.s_raw,470,bcoef);
       end
       
       bcoef=bcal_extract(bcal,532.2);
       if ~isempty(pro.park_ecoBbsig532)  % note - need to add indicator for which
           %             wavelength so the script takes the correct cal coeffs!
           pro.park_ecoBBP532_raw=convertBbsig(pro.park_ecoBbsig532,pro.park_t,pro.park_s,532,bcoef);
       end
       if ~isempty(pro.ecoBbsig532)
           pro.ecoBBP532_raw=convertBbsig(pro.ecoBbsig532,pro.t_raw,pro.s_raw,532,bcoef);
       end
       
       bcoef=bcal_extract(bcal,700.2);
       if ~isempty(pro.park_ecoBbsig700)  % note - need to add indicator for which
           %             wavelength so the script takes the correct cal coeffs!
           pro.park_ecoBBP700_raw=convertBbsig(pro.park_ecoBbsig700,pro.park_t,pro.park_s,700,bcoef);
       end       
       if ~isempty(pro.ecoBbsig700)
           park=0;
           pro.ecoBBP700_raw=convertBbsig(pro.ecoBbsig700,pro.t_raw,pro.s_raw,700,bcoef);
       end
   end
    
   if dbdat.tmiss
       if ~isempty(pro.parkTmcounts)
           pro.parkCP_raw=convertTmiss(pro.parkTmcounts,pro.wmo_id);
       end
       if ~isempty(pro.tm_counts)
           pro.CP_raw=convertTmiss(pro.tm_counts,pro.wmo_id);
       end
       
   end

   
    %now open log file and read further technical data:
%     fclose(fid);
    fid=fopen([idatapath fn(1:ss(2)) 'log']);
    if fid<=0
        %         return
    else
        c = textscan(fid,'%s','delimiter','\n');
        fclose(fid)
        c = c{:};
        
        j=0;
        ii = find(cellfun(@isempty,strfind(c,'Descent()'))==0);
        for a = 1:length(ii)
            gg = c{ii(a)};
            ll=strfind(gg,'Descent()');
            if(~isempty(ll))
                j=j+1;
                ff=strfind(gg,'Pressure:');
                try
                    pro.descent_p(j)=str2num(gg(ff+9:end));
                    pro.descent_jday(j)=julian(datevec(gg(2:21)));
                end
            end
        end
        %this is picking up the second pump, or nothing at all - why?? RC
        ii = find(cellfun(@isempty,strfind(c,'Continuous profile started'))==0);
        for a = 1:length(ii)
            gg = c{ii(a)};
            ll=strfind(gg,'Continuous profile started');
            if(~isempty(ll))
                pro.jday_ascent_start=julian(datevec(gg(2:21)));
                if ii(a) + 2 <= length(c)
                    gg = c{ii(a)+2};
                    ff=strfind(gg,'Volts');
                    f2=strfind(gg,'sec,');
                    if(isempty(ff))
                        logerr(2,'error in reading voltage')
                    else
                        pro.voltage=(str2num(gg(f2+4:ff-1)));
                    end
                end
            end
            %       ll=strfind(gg,'Continuous profile stopped'); %- not needed
            %        because this information is in the profile msg file as
            %          well and already decoded.
            
            %        if(~isempty(ll))
            %             pro.jday_ascent_end=julian(datevec(gg(2:21)));
            %        end
        end        
    end
    float(np) = pro;
    prec.profile_number = float(np).profile_number;
    
    %still need to plot and further process float:
    if(pro.npoints>0)  %do we have data?!
        float = calibrate_p(float,np);
        
        % Apply prescribed QC tests to T,S,P. Need whole float array because
        % previous profiles used in some tests. Also check for grounded float.
        float = qc_tests(dbdat,float,np);
        
        % Calibrate conductivity, salinity...
        
        [float,cal_rep] = calsal(float,np);
        
        % Thermal lag calc presently applies to SBE-41 & 41CP sensors only, and
        % uses an estimate of ascent-rate. We may have to actually provide
        % ascent-rate estimates (via the database).
        %  turn off for now!!!  turned back on 25/11/2009 AT
        
        float(np) = thermal_lag_calc(dbdat,float(np));
    end
    
    % Build new profile netCDF file, and extend tech netCDF file
    % Clear counts so that these files are exported.
    if(length(float(np).p_raw)>0)
        argoprofile_nc(dbdat,float(np));
    end
    % now re-generate netcdf files that had interpolation done:
    if exist('gennc','var') == 1
        if any(gennc) > 0
            for g=1:length(gennc)
                if gennc(g) == np
                    continue
                end
                if gennc(g) > 0
                    if ~isempty(float(gennc(g)).jday) & ~isempty(float(gennc(g)).wmo_id)
                        argoprofile_nc(dbdat,float(gennc(g)));
                    end
                end
            end
        end
    end
    
    if(pro.npoints>0)  %do we have data?!
        
        % Range check (just to alert our personnel to investigate)
        check_profile(float(np));
        %don't send to GDAC for these tests:
        rejtests = [1 2 3 4];
        
        if any(float(np).testsfailed(rejtests))
            % Will not transmit this profile because of failing critical tests
            logerr(3,'Failed critical QC, so no BUFR msg sent!');
            prec.gts_count = 99;
        elseif opts.rtmode && ~strcmp('evil',dbdat.status) & ...
                ~strcmp('hold',dbdat.status)
            % If not reprocessing, and not a "suspect" float, create tesac file. Disabled, 2 July, 2018
%             write_tesac(dbdat,float(np));
            
            % BOM write BUFR call
            BOM_write_BUFR;
            if outcome == 1
                prec.gts_count = 0;
            else
                prec.gts_count = 99;
            end                
        end
        if strcmp('dead',dbdat.status) | strcmp('exhausted',dbdat.status)
            % dead float returned - send email to alert operator -
            mail_out_dead_float(dbdat.wmo_id);
        end
        
        %         export_text_files
        prec.prof_nc_count = 0;
    end
    
    if opts.rtmode
        techinfo_nc(dbdat,float,np);
        prec.tech_nc_count = 0;
    end
    if np==1
        metadata_nc(dbdat,float);
        web_select_float
        if ~isempty(strmatch('CSIRO',ARGO_SYS_PARAM.processor))
            web_select_float_tech % updates the tech index pages
            make_tech_webpage(pro.wmo_id); %makes first instance of the technical pages
        end
        prec.meta_nc_count = 0;
    end
    
    %now the trajectory files. Only for iridium Apex & Seabird at this stage.
    if dbdat.maker == 1 || dbdat.maker == 4
        %not the EM floats which have a 9999 subtype but still 9i
        %controllerboard.
        if dbdat.subtype ~= 9999
            %load the traj mat file:
            tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(pmeta.wmo_id)];
            if exist([tfnm '.mat'],'file')==2
                load(tfnm);
            else
                traj = [];
            end
            
            traj = load_traj_apex_iridium(traj,pmeta,np,dbdat,float);
            %save the updated traj file:
            save(tfnm,'traj');
            trajectory_iridium_nc(dbdat,float,traj);
        end
    end
    prec.traj_nc_count = 0;
    prec.proc_status(1) = 1;

    % Update float summary plots and web page
    prec.proc_status(2) = 1;
    
    try
        %plotting
        web_profile_plot(float(np),dbdat);
        web_float_summary(float,dbdat,1);
        time_section_plot(float);
        waterfallplots(float);
        locationplots(float);
        tsplots(float);
    catch Me
        logerr(5,['error in plotting routines - ' num2str(dbdat.wmo_id) ' profile ' num2str(float(np).profile_number)])
        logerr(5,['Message: ' Me.message ])
        for jk = 1:length(Me.stack)
            logerr(5,Me.stack(jk).file)
            logerr(5,['Line: ' num2str(Me.stack(jk).line)])
        end
    end
    
    logerr(5,['Successful stage 1, np=' num2str(float(np).profile_number)]);
else
    logerr(5,['Stage 1 complete but no good fixes, np=' ...
        num2str(float(np).profile_number)]);
end

float(np).cal_report = cal_rep;


% proc record update
prec.stage_ecnt(1,:) = ARGO_REPORT.ecnt;
%       float(np).fbm_report = fbm_rep;  only relevant for find_best_msg
float(np).stage_ecnt(1,:) = ARGO_REPORT.ecnt;
float(np).stage_jday(1) = jnow;
float(np).ftp_download_jday(1) = pmeta.ftptime;
if opts.rtmode
    float(np).stg1_desc = ['RT auto V' ARGO_SYS_PARAM.version];
else
    float(np).stg1_desc = ['reprocess V' ARGO_SYS_PARAM.version];
end
prec.jday_ascent_end = float(np).jday_ascent_end;
if ~isempty(float(np).jday) 
    if abs(float(np).jday_ascent_end-float(np).jday(1))>=.9
        float(np).jday_ascent_end=float(np).jday(1);
    end
end

% ---- Web page update and Save data (both stage 1 & 2)
if any(stage>0)
    float(np).proc_stage = max(stage);
    float(np).proc_status = prec.proc_status;
    % Write float array back to file
    save(fnm,'float','-v6');
end


if ~isempty(stage)
    % Write postprocessing rec back to file, so that these records are saved
    % even if the this program is interrupted.
    prec.ftptime = pmeta.ftptime;
    prec.proc_stage = max(stage);
    PROC_RECORDS(nprec) = prec;
    load(PREC_FNM,'ftp_details');
    save(PREC_FNM,'PROC_RECORDS','ftp_details','-v6');
end

return


%--------------------------------------------------------------------
%  (256*h1 + h2) converts 2 hex (4-bit) numbers to an unsigned byte.

    function bb = h2b(dd,sc)
        
        bb = (256*dd(1) + dd(2)).*sc;
        
        %--------------------------------------------------------------------
        function t = calc_temp(dd)
            
            t = (256*dd(1) + dd(2)).*.001;
            if t > 62.535
                t = t - 65.536;
            end
            
            %--------------------------------------------------------------------
            function v = calc_volt(dd)
                
                v = dd*.1 + .4;
                
                %--------------------------------------------------------------------
                function v = calc_volt9(dd)
                    
                    v = dd*.078 + .5;
                    %--------------------------------------------------------------------
                    %--------------------------------------------------------------------
                    function v = calc_volt9a(dd)
                        
                        v = dd*.077 + .486;
                        %--------------------------------------------------------------------
                        function v = calc_volt_navis(dd)
                            v = dd*0.004825 + 0.00197; 
                        %--------------------------------------------------------------------
                            
                            function cur = calc_current_navis(dd)
                                cur = (dd*1.1546 - 0.1454)/1000;
                                
