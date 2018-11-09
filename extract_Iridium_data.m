% extract Iridium data - checks the delivery directories and, if there is
% new data, processes it before sending strip_argos_msg

global  ARGO_SYS_PARAM
global PROC_REC_WMO PROC_RECORDS

% System tuning parameters (could be shifted to ARGO_SYS_PARAM ?)
Too_Old_Days = 11;         % Realtime: no interested beyond 10 and a bit days. 
jnow = julian(clock);      % Local time - now

eval(['cd ' ARGO_SYS_PARAM.iridium_path]);
idatapath = ARGO_SYS_PARAM.iridium_path;


if ispc
system(['mv -f *.000.* ' ARGO_SYS_PARAM.iridium_path 'iridium_processed\000files'])
else
system(['mv -f *.000.* ' ARGO_SYS_PARAM.iridium_path 'iridium_processed/000files'])   
end

% list all reported
allfn=dirc([idatapath '*.*g']);

%Find missing and largest files
found = zeros(1,size(allfn,1));
for ii = 1:size(allfn,1)
    % for CSIRO processor only, look for the largest files
    if isfield(ARGO_SYS_PARAM,'processor')
        % Check for the data processor information - set in set_argo_sys_params.m
        if ~isempty(strfind(ARGO_SYS_PARAM.processor,'CSIRO'))
            [ps,nn,ext] = fileparts([idatapath allfn{ii,1}]);
            found(ii)=find_largest_file(nn);
        end
    end
end

%reload directories which might now have missing files retrieved:
logfn=dirc([idatapath '*.*.log']);
msgfn=dirc([idatapath '*.*.msg']);

%now mail out missing files messages
bb = char(msgfn{:,1});
bb = bb(:,1:end-3);
aa = char(logfn{:,1});
aa = aa(:,1:end-3);
[nn,ia,ib] = intersect(aa,bb,'rows');

if length(nn) ~= max([length(aa),length(bb)])
    [nfils,infl] = max([size(aa,1), size(bb,1)]);
    for ii = 1:nfils
        if ~ismember(aa(ii,:),nn,'rows')
            mail_out_iridium_log_error([aa(ii,:) 'log'],1);
        end
        if ~ismember(bb(ii,:),nn,'rows')
            mail_out_iridium_log_error([bb(ii,:) 'msg'],1);
        end
    end
end

[m,n]=size(msgfn);

% Now start decoding each pair
if(m>0)
    for ii=1:m
        isfloat=0;
        
        if(msgfn{ii,6})  %is this a directory?
            
        else  %first check whether this float is in the spreadsheet:
            msgfn{ii,1}
            ftptime = julian(datevec(msgfn{ii,4}));
            argosid = str2num(msgfn{ii,1}(1:4));
            if ~any(argosidlist==argosid)
                % Not a float we know or want
                logerr(0,'');
                dbdat = [];
                % If flist supplied then this is simply one of the floats we are
                % not interested in. Otherwise, it is not known to our database,
                % so either a corrupted id or the database is out of date.
                if isempty(flist)
                    logerr(3,['? New float, Argos ID=' num2str(argosid)]);
                end
                %                 return
            else
                % Set details for the next profile
                pmeta.wmo_id = idcrossref(argosid,2,1);
                pmeta.ftptime = ftptime;
                pmeta.ftp_fname = msgfn{ii,1};
                if length(pmeta.wmo_id)>1
                    pmeta.wmo_id=pmeta.wmo_id(2);  % assume you want the live version and punt if this isn't true
                end
                
                dbdat = getdbase(pmeta.wmo_id);
                logerr(0,num2str(pmeta.wmo_id));
                isfloat=1;
            end
            
            %get the float structure for this float:
            
            if isfloat
                if ispc
                    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles\float' num2str(dbdat.wmo_id)];
                else
                    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
                end
                
                try
                    crash=0;
                    % process iridium - where all the magic happens!!
                    if ~isempty(strmatch(dbdat.status,'live')) | ~isempty(strmatch(dbdat.status,'suspect'))...
                         | ~isempty(strmatch(dbdat.status,'hold'))
                        process_iridium(pmeta,dbdat,opts)
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
                        process_iridium(pmeta,dbdat,opts)
                    end
                catch Me
                    logerr(5,['error in decoding float - ' num2str(dbdat.wmo_id) ' file ' pmeta.ftp_fname])
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
                        if ispc
                            if (exist([ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)],'file')~=7)
                                system(['mkdir ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                            end
                            file2=[msgfn{ii,1}(1:length(msgfn{ii,1})-3) 'log'];
                            if ~exist(msgfn{ii,1},'file') | ~exist(file2,'file')
                                try
                                    system(['cp -f ' msgfn{ii,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                                    system(['cp -f ' msgfn{ii,1}(1:length(msgfn{ii,1})-3) 'log ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                                end
                            elseif(~crash)
                                system(['mv -f ' msgfn{ii,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                                system(['mv -f ' msgfn{ii,1}(1:length(msgfn{ii,1})-3) '* ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                            end
                            
                        else
                            if (exist([ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)],'file')~=7)
                                system(['mkdir ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                            end
                            file2=[msgfn{ii,1}(1:length(msgfn{ii,1})-3) 'log'];
                            if ~exist(msgfn{ii,1},'file') | ~exist(file2,'file')
                                try
                                    system(['cp -f ' msgfn{ii,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                                    system(['cp -f ' msgfn{ii,1}(1:length(msgfn{ii,1})-3) 'log ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                                end
                            elseif(~crash)
                                system(['mv -f ' msgfn{ii,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                                system(['mv -f ' msgfn{ii,1}(1:length(msgfn{ii,1})-3) '* ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                            end
                        end
                    end
                    
                end
            end
        end
        
    end
    
end

% now process any solo II data that's arrived in the last 6 hours:
% extract_Solo2_data
