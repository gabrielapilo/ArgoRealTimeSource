% TRAJECTORY_IRIDIUM_NC  Create and load a netCDF Argo trajectory file for
% iridium floats
%
% INPUT: dbdat - master database record for this float
%        fpp   - struct array containing the profiles for this float
%        [traj]  - struct array containing trajectory info   
%        [traj_mc_order]  - vector of MC codes in the right order for this float type
%
% changed to read traj metadata file if traj and traj_mc_order are not
% specified.  These are now optional. 
%
% Based on trajectory_nc.m: Author:  Jeff Dunn CSIRO/BoM  Aug 2006, Oct 2012
% Created for iridium files: Bec Cowley, September, 2015
%
% CALLS:  netCDF toolbox functions, julian
%
% USAGE: trajectory_iridium_nc(dbdat,fpp,traj,traj_mc_order)

function trajectory_iridium_nc(dbdat,fpp,traj)

global ARGO_SYS_PARAM

if nargin<3
    tfnm = [ARGO_SYS_PARAM.root_dir 'trajfiles/T' num2str(dbdat.wmo_id)];
    load(tfnm,'traj');
end

np = min([length(fpp) length(traj)]);

% Count cycles for which we have data (ie ignore missing cycles)
%for iridium, we might be missing entire log files, but the subsequent one
%might contain the surface info for this cycle. In both the case of a totally
%missing log file and a log file with missing information, 
% the missing fields will be filled with NaN in juld.

gotcyc = NaN*ones(1,np+1); %allow for profile zero
%look for profile zero information:
if ~isempty(traj(1).on_deployment);
    fv = traj(1).on_deployment;
    flds = fieldnames(fv);
    filledfld = zeros(1,length(flds));
    for jj = 1:length(flds)-1
        filledfld(jj) = ~isempty(fv.(flds{jj}));
    end
    if sum(filledfld) > 0
        gotcyc(1) = 0;
    end
end
nn = 2;
for ii = 1:np
    %now continue on with regular profiles 1-end
    fv = traj(ii);
    flds = fieldnames(fv);
    filledfld = zeros(1,length(flds));
    for jj = 2:length(flds)-1 %don't include the clock offset field
        filledfld(jj) = ~isempty(fv.(flds{jj}));
    end
    if sum(filledfld) > 0
        gotcyc(nn) = ii;
    end
    nn = nn+1;
end

% now remove cycles we don't have ANY data for:
gotcyc(isnan(gotcyc)) = [];

if isempty(gotcyc)
   logerr(2,['TRAJECTORY_NC:  No usable cycles, so no file made (WMO '...
	     num2str(dbdat.wmo_id) ')']);
   return
end

% Only P, T, S and conductivity are stored in Core-Argo traj files - all
% other parameters are in the B-files. 
% Parameters defined in User Manual Ref table 3
pars = {'PRES','TEMP','PSAL'};
% if ~isfield(fpp,'p_park_av') && ~isfield(fpp,'park_p')    %palace floats
% without park averages - fill with empty data!
%    % What about surface measurements??
%    params = [];
% else
params = [1 2];
if isfield(fpp,'park_s') || isfield(fpp,'s_park_av')
    params = [params 3];
end
% end

% ## LOTS MORE TO FILL IN HERE :
%
% ## also THIS IS WHERE WE NEED TO SEPARATE B-Argo STUFF

parknm = {'park_p','park_t','park_s'};
pkavnm = {'p_park_av','t_park_av','s_park_av'};
surfnm = {'surf_Oxy_pressure','surf_t','surf_s'};
parmnm = {'pressure','temperature','salinity'};

fname = [ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) '/' num2str(dbdat.wmo_id) '_Rtraj.nc'];
dirn = [ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) ];

if ~exist(dirn,'dir')
    system(['mkdir ' dirn]);
end

%____________________________________________________________________
% Edit the code starting from here to use matlab netcdf toolbox
hist=[];
dc='';
if exist(fname,'file') == 2
    try
        hist=ncreadatt(fname,'/','history');
        dc=ncread(fname,'DATE_CREATION');
    end
    %get rid of the existing file:
    eval(['!rm ' fname])
end
%new file
%create the schema for this file:
schema = build_traj_schema_nc(fname,gotcyc,params);

%write the schema to the netcdf file (it will be empty of data at this
%stage).
ncwriteschema(schema.Filename,schema);

[st,today_str]=system(['date -u +%Y%m%d%H%M%S']);
today_str=today_str(1:14);
if isempty(str2num(dc))
    dc=today_str;
end

%get some strings prepared
[st,dn]=system(['date -u +%Y-%m-%d-%H:%M:%S']);

dn(11:11)='T';
if isempty(hist)
    dn(20:29)='Z creation';
else
    hist(end+1)=';';
    dn(20:27)='Z update';
end
dnt=[hist dn];
ncwriteatt(schema.Filename,'/','history',dnt);


% ---------now add data

%can get the information we need from dbdat
% sensdb = getadditionalinfo(dbdat.wmo_id);
mission=get_Argos_config_params(dbdat.wmo_id);

%________________________________________________________
%General information about the trajectory file
% Fill the fields
bb = num2str(dbdat.wmo_id);
ncwrite(fname,'PLATFORM_NUMBER',bb,1)

ncwrite(fname,'DATA_CENTRE',ARGO_SYS_PARAM.datacentre(:),1)

ncwrite(fname,'DATE_UPDATE',today_str);
if ~isempty(strfind(dbdat.owner,'COOE'))
    ncwrite(fname,'PROJECT_NAME','Cooperative Ocean Observing Exp');
else
    ncwrite(fname,'PROJECT_NAME',ARGO_SYS_PARAM.Proj);
end

ncwrite(fname,'PI_NAME',dbdat.PI);

ncwrite(fname,'WMO_INST_TYPE',dbdat.wmo_inst_type);
ncwrite(fname,'POSITIONING_SYSTEM','GPS');
ncwrite(fname,'DATA_TYPE','Argo trajectory');
ncwrite(fname,'FORMAT_VERSION','3.1');
ncwrite(fname,'HANDBOOK_VERSION',' 3.1');
ncwrite(fname,'REFERENCE_DATE_TIME','19500101000000');
ncwrite(fname,'DATE_CREATION',dc);

for ii = 1:length(params)
    ncwrite(fname,'TRAJECTORY_PARAMETERS',pars{params(ii)}(:),[1 ii]);
end

ncwrite(fname,'DATA_STATE_INDICATOR','2B');

%________________________________________________________
%General information about the float continued
% Some of this section is done in generic_fields_nc_updated
switch dbdat.maker
    case 1
        if dbdat.subtype==0
            ncwrite(fname,'PLATFORM_TYPE','PALACE');
        else
            ncwrite(fname,'PLATFORM_TYPE','APEX');
        end
    case 2
        ncwrite(fname,'PLATFORM_TYPE','PROVOR-MT');
    case 3
        ncwrite(fname,'PLATFORM_TYPE','SOLO-W');
    case 4
        ncwrite(fname,'PLATFORM_TYPE','NAVIS_A');
    case 5
        ncwrite(fname,'PLATFORM_TYPE','S2A');
end

aa = num2str(dbdat.maker_id);
ncwrite(fname,'FLOAT_SERIAL_NO',aa);

aa = mission.data{29};
if isempty(aa)
    aa='n/a';
end
if length(aa) > 32 %limited to string 32
    aa = aa(1:32);
end
ncwrite(fname,'FIRMWARE_VERSION',aa);

%________________________________________________________
%N_Measurement dimension variable group
% Launch position and date in N_MEASUREMENT (but I think not in N_CYCLE)
j1950 = julian([1950 1 1 0 0 0]);
iNM = 1;
tmp = sscanf(dbdat.launchdate,'%4d%2d%2d%2d%2d%2d');
%take away the j1950! Not included in the Argos version!!
jday = julian(tmp(:)') - j1950;
ncwrite(fname,'JULD',jday,iNM);
ncwrite(fname,'JULD_STATUS','0',iNM);
ncwrite(fname,'LATITUDE',dbdat.launch_lat,iNM);
%make sure longitude is +/-180, not 0-360 as stored in mat files:
if dbdat.launch_lon > 180
    dbdat.launch_lon = -1*(360-dbdat.launch_lon);
end
ncwrite(fname,'LONGITUDE',dbdat.launch_lon,iNM);
ncwrite(fname,'JULD_QC','1',iNM);
ncwrite(fname,'POSITION_QC','1',iNM);
%  Set to 1 if/when position is checked,  otherwise 0. I assume they have
%  been checked
ncwrite(fname,'CYCLE_NUMBER',-1,iNM);
ncwrite(fname,'MEASUREMENT_CODE',0,iNM);
% 'POSITION_ACCURACY'   - leave as FillValue
% 'SATELLITE_NAME'   - leave as FillValue

% UTC time
ncwrite(fname,'DATE_UPDATE',today_str(:));


% For mandatory cycle timing fields, must use fillvalue in N_CYCLE and
% N_MEASUREMENT fields if times cannot even be estimated.

% User Manual pp25
% "If the float experiences an event but the time is not able to be
% determined, then most variables are set to fill value and a *_STATUS = '9'
% is used in both the N_MEASUREMENT and N_CYCLE arrays. This indicates that
% it might be possible to estimate in the future and acts as a placeholder.
%
% If a float does not experience an event, then the fill values are used for
% all N_CYCLE variables. These non-events do not get a placeholder in the
% N_MEASUREMENT arrays."

%______________________________________________________
% ----------------- N_CYCLE dimension fields
nvnm = {'DESCENT_START','FIRST_STABILIZATION','DESCENT_END','PARK_START',...
    'PARK_END','DEEP_DESCENT_END','DEEP_PARK_START','DEEP_ASCENT_START',...
    'ASCENT_START','ASCENT_END','TRANSMISSION_START','FIRST_MESSAGE',...
    'FIRST_LOCATION','LAST_LOCATION','LAST_MESSAGE','TRANSMISSION_END'};
tvnm = {'DST','FST','DET','PST',...
    'PET','DDET','DPST','DAST',...
    'AST','AET','TST','FMT',...
    'FLT','LLT','LMT','TET'};
rpp = NaN*ones(length(gotcyc),1);
ii = 0;
load([ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id) 'aux.mat'])
disp(['Writing N_CYCLE stuff ' num2str(dbdat.wmo_id)])

for nn = gotcyc
%     disp(num2str(nn))
    % We don't include missing cycles, so should end up with ii=length(gotcyc)
    ii = ii+1;
    
    % If float cycle number starts from zero then this may need
    % correction, although normally cycle zero would be in in fpp(1), so
    % it will work out ok.
    %Not quite true for the APF9i floats: the profile 0 is not recorded in
    %fpp because no data collected. But have traj data associated with
    %profile 0.
    %Clock offset is defined as float RTC-UTC.
    if nn == 0
        ncwrite(fname,'CYCLE_NUMBER_INDEX',0,ii);
        pr0 = 1;
        if isempty(traj(1).clockoffset)
            %            jcor = j1950;
            ncwrite(fname,'DATA_MODE','R',ii);
        else
            % Clock correction to applying to times which are not already
            % intrinsically corrected.
            % The sense of this is incorrect according to ADMT user guide.
            % The argos version of this code might need updating - but have
            % to check!!
            %            jcor = j1950 + traj(1).clockoffset;
            % Also, for iridium, we have already corrected the values that
            % can be corrected. So dangerous to re-apply.
            
            ncwrite(fname,'CLOCK_OFFSET',traj(1).clockoffset,ii);
            ncwrite(fname,'DATA_MODE','A',ii);
        end
    else
        pr0 = 0;
        if ~isempty(fpp(nn).profile_number)
            ncwrite(fname,'CYCLE_NUMBER_INDEX',fpp(nn).profile_number,ii);
        else
            %the cycle number index should correspond to the nn value anyway
            ncwrite(fname,'CYCLE_NUMBER_INDEX',nn,ii);
        end
        if isempty(traj(nn).clockoffset)
            %            jcor = j1950;
            ncwrite(fname,'DATA_MODE','R',ii);
        else
            % Clock correction to applying to times which are not already
            % intrinsically corrected.
            %            jcor = j1950 + traj(nn).clockoffset;
            ncwrite(fname,'CLOCK_OFFSET',traj(nn).clockoffset,ii);
            ncwrite(fname,'DATA_MODE','A',ii);
        end
        if ~isempty(fpp(nn).surfpres_used)
            %pressures are adjusted, need to designate
            ncwrite(fname,'DATA_MODE','A',ii);
        end
    end
    % All codes are included in the file, even though some floats don't
    % experience them. In this case, fill value is used.
    %
    % Q: When do we leave _STATUS as fillvalue, and when do we use '9'?
    %
    %  Assuming STATUS here the same as JULD_STATUS in N_M arrays.
    
    %Fill in the N_CYCLE fields:
    if pr0 %this is the zero profile
        fv = traj(1).on_deployment;
    else
        fv = traj(nn);
    end
    for jj = 1:length(nvnm)
        nnm = nvnm{jj};
        tnm = tvnm{jj};
        if isfield(fv,tnm) && isfield(fv.(tnm),'juld') && ~isempty(fv.(tnm).juld)
            if ~isnan(fv.(tnm).juld(end))
                ncwrite(fname,['JULD_' nnm],fv.(tnm).juld(end)-j1950,ii);
            end
            if isfield(fv.(tnm),'stat')
                ncwrite(fname,['JULD_' nnm '_STATUS'],fv.(tnm).stat(end),ii)
            else
                ncwrite(fname,['JULD_' nnm '_STATUS'],fv.(tnm).juld_stat(end),ii)
            end  
        else %no field, put in 9 in status
                ncwrite(fname,['JULD_' nnm '_STATUS'],'9',ii)            
        end
    end
    
    if ~pr0
        %did the float ground?
        if ~isempty(fpp(nn).grounded)
            ncwrite(fname,'GROUNDED',fpp(nn).grounded,ii);
        end
        %get mission number:
        ncwrite(fname,'CONFIG_MISSION_NUMBER',floatTech.Mission(nn).mission_number,ii);
        
        % REPRESENTATIVE_PARK_PRESSURE is only used where values are averaged to
        % provide one value for whole park period (corresponds to MC=301)
        if isfield(traj(nn),'PTM') && isfield(traj(nn).PTM,'juld') && ~isempty(traj(nn).PTM.juld)
            fv = traj(nn).PTM;
            %Need a weighted mean to use status flag of '1', however, will
            %use median for now until I figure out a better way.
            pp = fv.pressure;
            pp = pp(~isnan(pp));
            rpp(nn) = median(pp);
            ncwrite(fname,'REPRESENTATIVE_PARK_PRESSURE',rpp(nn),ii);
            ncwrite(fname,'REPRESENTATIVE_PARK_PRESSURE_STATUS','1',ii);
        else
            rpp = [];
        end
    else %zero profile, assume it didn't ground!
        ncwrite(fname,'GROUNDED','N',ii);
    end
    
    % This probably only if adjustment determined in Delayed Mode?
    %nc{'CYCLE_NUMBER_INDEX_ADJUSTED'}(ii) = ?;
    
end





% ------------- N_MEASUREMENT dimension fields

% Manual references for M-CODEs:
% 290  3.4.1.1.2
% 296  3.4.1.1.2.3
% 297,298  3.4.2.6
% 299  - not yet used? "any single measurement" so could apply to a single
%    park measurement, but we expect a series of park measurements, hence use 290?
% 300  3.2.2.1.5.1
% 301  3.4.3

% M-CODE to variable name cross-ref
%Note I have added PTM, DSP and DNT as my own corresponding values for
%codes that aren't specified in the cookbook. The mat files list these
%codes.

vnms([100,150,190,200,250,290,300,301,400,450,500,501,550,600,700,701,702,703,704,800,903]) = ...
    [{'DST'} {'FST'} {'DSP'} {'DET'} {'PST'} {'PTM'} {'PET'} ...
    {''} {'DDET'} {'DPST'} {'AST'} {'DNT'} {'DAST'} ...
    {'AET'} {'TST'} {'TST2'} {'FMT'} {'ST'} {'LMT'} {'TET'} {''}];

jfillval_5 = 99999;
jfillval_6 = 999999;
posfillval = ' ';

arrs = {'juld','juld_stat', 'adj','juld_qc','lat','lon','pressure','temperature',...
    'salinity','pressureadj', 'pressureqc','temperatureqc','salinityqc', ...
    'temperatureadj','salinityadj', 'temperaturestat','pressurestat','salinitystat',...
    'traj_mc_order','cycn','juld_adj','juld_adj_stat','posqc','posacc','satnam'};

% Loop on profiles to be written to this file
disp(['Writing N_MEASUREMENT stuff ' num2str(dbdat.wmo_id)])

madd = iNM+1; 

for nn = gotcyc
%     disp(num2str(nn))
    %The traj_mc_order is not going to be true for every cycle because the
    %float may login multiple times, which means multiple values for ST
    %cannot appear all together, they must be distributed between the
    %FMT,LMT times. Also, some PTM messages may appear before DET.
    %

    %Could be an issue with the satellite times vs the float times: ie,
    %TST/FMT/LMT/TET are all satellite times and are not adjusted,
    %therefore don't appear in the 'JULD_adjusted' field. It is possible that
    %the JULD array will have time inversions, but JULD_ADJ should not. It
    %will, however, not have the satellite times included - they can only
    %be found in the JULD array.
 
    if nn == 0
        traj_mc_order = traj(1).on_deployment.traj_mc_order;
        traj_mc_index = traj(1).on_deployment.traj_mc_index;
        co = traj(1).clockoffset;
    else
        traj_mc_order = traj(nn).traj_mc_order;
        traj_mc_index = traj(nn).traj_mc_index;
        co = traj(nn).clockoffset;
    end
    if isempty(co)
        co = 0;
    end
    %Make arrays of the JULD, STATUS, QC, CYCLE, LAT, LON, PARAMS all
    %for writing
    [juld] = deal(repmat(jfillval_6,length(traj_mc_order),1));
    [adj,lat,lon,pressure,temperature,salinity, ...
        temperatureadj,salinityadj,pressureadj] ... %actual adjsted values
        = deal(repmat(jfillval_5,length(traj_mc_order),1));
    [pressureqc,temperatureqc,salinityqc,temperaturestat,pressurestat,salinitystat] ... 
        = deal(repmat(' ',1,length(traj_mc_order)));
    [juld_qc] = deal(repmat('0',1,length(traj_mc_order)));
        [temperature_adj,salinity_adj,pressureadj] ...%adjusted flags
            = deal(NaN*zeros(1,length(traj_mc_order)));
    %put 7 in here to identify fill values so we can operate on them, then
    %replace them with ' ' later
    [juld_stat] = deal(repmat('7',1,length(traj_mc_order)));
    [posqc,posacc] = deal(repmat(posfillval,1,length(traj_mc_order)));
%     satnam = repmat('{}',1,length(traj_mc_order));
    
    %record cycle number.MC already to go (traj_mc_order)
    cycn = repmat(nn,1,length(traj_mc_order));
    
    %cycle through using traj_mc_order
    %make adjustments to arrays based on adj value and status and MC
    %then write once.
    if nn == 0
        fv = traj(1).on_deployment;
    else
        fv = traj(nn);
    end
    
%-----------------------------------------------------------------------
    for a = 1:length(traj_mc_order)
        mc = traj_mc_order(a);
        mind = traj_mc_index(a);
        
        %fill the arrays using vnms information:
        vnm = vnms{mc};
        
        if isfield(fv,vnm)
            if ~isempty(fv.(vnm)) && ~isempty(fv.(vnm).juld)
                fvv = fv.(vnm);
                %juld and status and adj information
                juld(a) = fvv.juld(mind)-j1950;
                try
                    juld_stat(a) = fvv.stat(mind);
                    adj(a) = fvv.adj(mind);
                catch
                    juld_stat(a) = fvv.juld_stat(mind);
                    adj(a) = fvv.juld_adj(mind);
                end
                if isfield(fvv,'qc') && ~isempty(fvv.qc)
                    juld_qc(a) = fvv.qc(mind);
                end
                %now parms:
                for ipar = params;
                    if isfield(fvv,parmnm{ipar})
                        tmp = fvv.(parmnm{ipar})(mind);
                        if ~isnan(tmp)
                            eval([parmnm{ipar} '(a) = tmp;'])
                            %put a zero flag in
                            eval([parmnm{ipar} 'qc(a) = ''0'';']);
                            %keep track of status and adj values
                            eval([parmnm{ipar} '_adj(a) = fvv.' parmnm{ipar} '_adj(mind);']);
                            eval([parmnm{ipar} 'stat(a) = fvv.' parmnm{ipar} '_stat(mind);']);
                            
                        end
                    end
                    
                end
                %don't forget lat/lon information
                if isfield(fvv,'lat')
                    if ~isnan(fvv.lat(mind))
                        lat(a) = fvv.lat(mind);
                    end
                    if ~isnan(fvv.lon(mind))
                        lon(a) = fvv.lon(mind);
                    end
                    %position quality information
                    if ~isnan(fvv.lon(mind)) & ~isnan(fvv.lat(mind))
                        if isfield(fvv,'qcflags') && ~isempty(fvv.qcflags)
                            posqc(a) = num2str(fvv.qcflags);
                        else
                            posqc(a) = '1'; %good
                        end
                    end
                    if isfield(fvv,'aclass')
                        posacc(a) = fvv.aclass;
                    end
                    if isfield(fvv,'satnam') && ~isempty(fvv.satnam)
                        satnam{a} = fvv.satnam;
                    end
                end
            end
        end
    end
    
    %add in the 301 code:
    ival = find(traj_mc_order == 301);
    if ~isempty(ival) & ~isempty(rpp)
        pressure(ival) = rpp(nn);
        pressureadj(ival) = 0;
        pressurestat(ival) = '3';
        pressureqc(ival) = '0';
    end
    
    %apply adjustments to pressure: 
    if nn > 0
        ival = pressureadj == 0;
        if ~isempty(fpp(nn).surfpres_used)
            % Don't know if this can/should apply for surface values, but
            % included for all pressure values
            pressureadj = pressure;
            pressureadj(ival) = pressure(ival) - fpp(nn).surfpres_used;
        end
    end
    
    %copy the salinity and temperature to adj arrays
    salinityadj = salinity;
    temperatureadj = temperature;
    
    %add the 903 code:
    ival = traj_mc_order == 903;
    if any(ival)
        if ~isempty(fpp(nn).surfpres_used) && ~isnan(fpp(nn).surfpres_used)
            pressure(ival) = fpp(nn).surfpres_used;
            pressurestat(ival) = '2';
            pressureadj(ival) = 0;
            pressureqc(ival) = '0';
        end
    end
    
    %remove adjustments to juld for clock drift based on adj and stat
    %values (ie, don't remove clock drift on satellite times)
    %stat = 2, value transmitted by float
    %stat = 3, value computed from float information (ie, adjusted for
    %clock drift)
    %stat = 4, value transmitted from satellite data
    %Manual is a bit confusing about whether to include the non-adjusted
    %data in 'adjusted' field, but found in DM user manual that the best
    %value should be included here, even if not adjusted.
    

    %make adjusted array (note that times are already adjusted for drift)
    juld_adj_stat = juld_stat;
    juld_adj = juld;
    ival = find(str2num(juld_stat') == 3 & adj == 1); %values have been adjusted, make non-adjusted values:
    juld(ival) = juld(ival) + co;
    juld_stat(ival) = '2';
    
    %clean up the juld_stat fill values and replace with 9:
    ival = strfind(juld_stat,'7');
    juld_stat(ival) = '9';
    ival = strfind(juld_adj_stat,'7');
    juld_adj_stat(ival) = '9';
    juld_qc(ival) = '9';
    %for juld_qc, if there is a '9' in juld_stat from the traj structure, need to have a '9' in
    %juld_qc too:
    ival = strfind(juld_adj_stat,'9');
    juld_qc(ival) = '9';
        
    %remove empty fields if they are not mandatory. Only mc divisible by
    %100 are mandatory.
    ival = rem(traj_mc_order,100) ~= 0 & ...
        juld' == jfillval_6 & pressure' == jfillval_5 & ...
        temperature' == jfillval_5 & salinity' == jfillval_5 & ...
        lat' == jfillval_5 & lon' == jfillval_5;
    for iar = arrs
        if exist(char(iar),'var') == 1
            eval([char(iar) '(ival) = [];'])
        end
    end
    
    %______________now write it out________________
    
    %JULD vars
    ncwrite(fname,'JULD',juld,madd);
    ncwrite(fname,'JULD_STATUS',juld_stat,madd)
    ncwrite(fname,'JULD_QC',juld_qc,madd);
    ncwrite(fname,'JULD_ADJUSTED',juld_adj,madd)
    ncwrite(fname,'JULD_ADJUSTED_STATUS',juld_adj_stat,madd)
    ncwrite(fname,'JULD_ADJUSTED_QC',juld_qc,madd); %use same qc for both adj and not adj

    %write the parms out
    for ipar = params
        eval(['ncwrite(fname,pars{ipar},' parmnm{ipar} ',madd);'])
        eval(['ncwrite(fname,[pars{ipar} ''_QC''],' [parmnm{ipar} 'qc'] ',madd);'])
        eval(['ncwrite(fname,[pars{ipar} ''_ADJUSTED''],' [parmnm{ipar} 'adj'] ',madd);'])
        eval(['ncwrite(fname,[pars{ipar} ''_ADJUSTED_QC''],' [parmnm{ipar} 'qc'] ',madd);'])
    end
                
    %write lat/lon information
    ncwrite(fname,'LATITUDE',lat,madd);
    %make sure longitude is +/-180, not 0-360 as stored in mat files:
    if any(lon > 180)
        ii = lon>180 & lon <= 360;
        lon(ii) = -1*(360-lon(ii));
    end
    ncwrite(fname,'LONGITUDE',lon,madd);
    
    %Position QC information - Iridium doesn't have this?, put in fill
    %values
    ncwrite(fname,'POSITION_QC',posqc,madd);
    ncwrite(fname,'POSITION_ACCURACY',posacc,madd);
    if exist('satnam','var') == 1
        %will probably fail if only one name present as I haven't
        %pre-allocated space for it.
        ncwrite(fname,'SATELLITE_NAME',satnam,madd);
    end
    
    %Cycle number and measurement codes
    ncwrite(fname,'CYCLE_NUMBER',cycn,madd);
    ncwrite(fname,'MEASUREMENT_CODE',traj_mc_order,madd);
    
    %increment indexing
    madd = madd + length(juld);
    
end       % Loop on every cycle


% History section:
% No history records added at this stage
%History records get added in DM QC.

%Delivery.
if ~strcmp('evil',dbdat.status) & ~strcmp('hold',dbdat.status)
    
    [status,ww] = system(['cp -f ' fname ' ' ARGO_SYS_PARAM.root_dir 'export']);
    if status~=0
        logerr(3,['Copy of ' fname ' to export/ failed:' ww]);
    end
end
%###

%-------------------------------------------------------------------------------
