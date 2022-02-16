% extract APF11 data - checks the delivery directories and, if there is
% new data, processes it before returning to strip_argos_msg

global  ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global PREC_FNM PROC_REC_WMO PROC_RECORDS

%these bits make it easier to run stand-alone:
if ~exist('argosidlist','var')
    argosidlist = ARGO_ID_CROSSREF(:,2);
end
if ~exist('opts','var')
    opts.redo=0
end

if ~exist ('PREC_FNM','var') | isempty(PREC_FNM)
    PREC_FNM = [ARGO_SYS_PARAM.root_dir 'Argo_proc_records'];
end

% System tuning parameters (could be shifted to ARGO_SYS_PARAM ?)
Too_Old_Days = 11;         % Realtime: no interested beyond 10 and a bit days.
jnow = julian(clock);      % Local time - now

eval(['cd ' ARGO_SYS_PARAM.iridium_path]);
idatapath = ARGO_SYS_PARAM.iridium_path;


system(['mv -f *.000.* ' ARGO_SYS_PARAM.iridium_path 'iridium_processed/apf11000files']);
% list all .msg and .log files
% system(['dos2unix ' idatapath  '*']);
a=dir([idatapath '*.*.*.science_log.csv']);
b=dir([idatapath '*.*.*.vitals_log.csv']);
c=dir([idatapath '*.*.*.system_log.txt']);
%get the unique file names here
d = [a;b;c];
nms = [];fnms=[];pn = [];
for j = 1:length(d)
    nm = regexp(d(j).name,'[f\.-]','split');
    fnm = regexp(d(j).name,'[\.-]','split');
    if ~isempty(nm{1})
        nms{j} = nm{1};
        pn{j} = nm{3};
    else
        nms{j} = nm{2};
        pn{j} = nm{3};
    end
    if ~isempty(fnm{1})
        fnms{j} = fnm{1};
    else
        fnms{j} = fnm{2};
    end
end
[ufloats,iuu,iu] = unique(nms,'stable');
[ufloatsf] = unique(fnms,'stable');
if isempty(ufloats) %no APF11 profiles to process
    return
end

for i=1:length(ufloats)
    % check for number multiple profiles reported:
    
    % First check if this float is going through new system
    newfloat = 0;
    newsystem_fl = load([ARGO_SYS_PARAM.root_dir 'src/newsystem.txt']);
    if ~isempty(find(str2num(ufloats{i}) == newsystem_fl))
        logerr(3,['Float ' ufloats{i} ' is going through the new system (removing file from iridium_data)']);
        unix(['rm -f ' ARGO_SYS_PARAM.iridium_path 'f' (ufloats{i}) '.*'])
        newfloat = 1;
    end
    
    if newfloat
        newfloat = 0;
        continue
    end
                    
    isfloat=0;
    np = unique(pn(iu==i));
    for j = 1:length(np)
        a=dir([idatapath ufloatsf{i} '*.' np{j} '.*science_log.csv']);
        if isempty(a)
            a=dir([idatapath ufloatsf{i} '*.' np{j} '*system_log.txt']);
        end
        
        %first check whether this float is in the spreadsheet:
        disp(ufloatsf{i})
        for bb = 1:size(a,1)
            ftptime(bb) = julian(datevec(a(bb).datenum));
        end
        currenttime=julian(clock);
        hr=1/24;
        argosid = str2num(ufloats{i});
        if ~any(argosidlist==argosid)
            % Not a float we know or want
            logerr(0,'');
            dbdat = [];
            % If flist supplied then this is simply one of the floats we are
            % not interested in. Otherwise, it is not known to our database,
            % so either a corrupted id or the database is out of date.
            if isempty(flist)
               logerr(3,['? New float, Argos ID=' ufloats{i}]);
            end
            isfloat = 0;
        elseif currenttime-ftptime(1)>=hr     % check whether this is more than 1 hour old - if so, then safe to process:
            clear pmeta
            % Set details for the next profile
            pmeta.wmo_id = idcrossref(argosid,2,1);
            for bb = 1:size(a,1)
                pmeta.ftptime(bb) = ftptime(bb);
                pmeta.ftp_fname{bb} = a(bb).name;
            end
            if length(pmeta.wmo_id)>1
                pmeta.wmo_id=pmeta.wmo_id(2);  % assume you want the live version and punt if this isn't true
            end
            
            dbdat = getdbase(pmeta.wmo_id);
            logerr(0,num2str(pmeta.wmo_id));
            isfloat=1;
        end
        
        %get the float structure for this float:
        
        if isfloat
            fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
            
            try
                crash=0;
                % process iridium - where all the magic happens!!
                if ~isempty(strmatch(dbdat.status,'live')) | ~isempty(strmatch(dbdat.status,'suspect')) ...
                        | ~isempty(strmatch(dbdat.status,'hold')) | ~isempty(strmatch(dbdat.status,'shelf'))
                    process_iridium_apf11(pmeta,dbdat,opts);
                elseif(~isempty(strmatch(dbdat.status,'expected')))
                    logerr(3,['? New float, Iridium ID=' num2str(argosid)]);
                    nprec = find(PROC_REC_WMO==dbdat.wmo_id);
                    if isempty(nprec)
                        logerr(3,['Creating new processing record as none found for float ' ...
                            num2str(dbdat.wmo_id)]);
                        nprec = length(PROC_REC_WMO) + 1;
                        PROC_RECORDS(nprec) = new_proc_rec_struct(dbdat,1);
                    end
                    isfloat=0;
                elseif ~isempty(strmatch(dbdat.status,'dead')) | ~isempty(strmatch(dbdat.status,'exhausted'))
                    mail_out_dead_float(dbdat.wmo_id);
                    process_iridium_apf11(pmeta,dbdat,opts)
                end
            catch Me
                logerr(5,['error in decoding float - ' num2str(dbdat.wmo_id) ' file ' char(pmeta.ftp_fname)])
                logerr(5,['Message: ' Me.message ])
                for jk = 1:length(Me.stack)
                    logerr(5,Me.stack(jk).file)
                    logerr(5,['Line: ' num2str(Me.stack(jk).line)])
                end
                isfloat=0;
                mail_out_iridium_log_error([msgfn{ii,1}],3);
                crash=1;
            end
            
            if isfloat
                %after processing, move the files from the delivery directory into the
                %individual directories:
                
                if(~isempty(dbdat))
                    if (exist([ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)])~=7)
                        system(['mkdir ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                    end
                    dot=strfind(a.name,'.');
                    fn=a.name(1:dot(2));
                    try
                        system(['mv -f ' fn '* ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                    end
                end
            end
        end
    end
end


