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
a=dirc([idatapath '*.*.*.science_log.csv']);
b=dirc([idatapath '*.*.*.vitals_log.csv']);
c=dirc([idatapath '*.*.*.system_log.txt']);
d=[a 
    b
    c];
[m,n]=size(d);
% check for zero sized files

if m>0   % are there any apf 11data?
    for j=1:m
        if (d{j,5} == 0)
            % mail out error
            mail_out_iridium_log_error([a{j,1}],2);
        end
    end

    if ~isempty(c)
    cc = char(c{:,1});
    cc = cc(:,1:10);
    end
    if ~isempty(b)
    bb = char(b{:,1});
    bb = bb(:,1:10);
    end
    if ~isempty(a)
    aa = char(a{:,1});
    aa = aa(:,1:10);
    end
    
    if ~isempty(a) & ~isempty(b)
    [nn,ia,ib] = intersect(aa,bb,'rows');
    end
    if ~isempty(a) & ~isempty(c)
    [mm,ic,id] = intersect(aa,cc,'rows');
    end
    
    missingaa=0;
    missingbb=0;
    
    if ~isempty(a)
    for i = 1:size(aa,1)
        if ismember(aa(i,:),nn,'rows') == 0
            mail_out_iridium_log_error([a{i,1}],1);
            missingaa=1;
            %             system(['cp -f ' a{i,1} ' ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files']);
            try
                %                 system(['cp -f ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files/' aa(i,:) 'msg '...
                %                     ARGO_SYS_PARAM.iridium_path]);
            end
        end
    end
    end
    if ~isempty(b)
    for i = 1:size(bb,1)
        if ismember(bb(i,:),nn,'rows') == 0
            mail_out_iridium_log_error([b{i,1}],1);
            missingbb=1;
            %             system(['cp -f ' b{i,1} ' ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files']);
        end
        try
            %                 system(['cp -f ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files/' aa(i,:) 'log '...
            %                     ARGO_SYS_PARAM.iridium_path]);
        end
    end
    end
    if ~isempty(c)
    for i = 1:size(cc,1)
        if ismember(cc(i,:),mm,'rows') == 0
            mail_out_iridium_log_error([c{i,1}],1);
            %             system(['cp -f ' b{i,1} ' ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files']);
        end
        try
            %                 system(['cp -f ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files/' aa(i,:) 'log '...
            %                     ARGO_SYS_PARAM.iridium_path]);
        end
    end
    end
    [m,n]=size(a);
    
    if(m>0)
        for i=1:m
            isfloat=0;
            
            if(a{i,6})  %is this a directory?
                
            else  %first check whether this float is in the spreadsheet:
                a{i,1}
                ftptime = julian(datevec(a{i,4}));
%                 [st,ts]=system(['date -u +%Y%m%d%H%M%S']);
                currenttime=julian(clock);
                hr=1/24;
%                 hr=0.0001
%                 currenttime=julian([str2num(ts(1:4)) str2num(ts(5:6)) str2num(ts(7:8)) str2num(ts(9:10)) str2num(ts(11:12)) str2num(ts(13:14))]);
                argosid = str2num(a{i,1}(2:5));
                %             if length(num2str(argosid))>=4
                %                 % Bad ID num
                %                 argosid = -1;
                %                 logerr(0,'');
                %                 dbdat = [];
                %         else
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
                elseif currenttime-ftptime>=hr     % check whether this is more than 1 hour old - if so, then safe to process:
                    
                    % Set details for the next profile
                    pmeta.wmo_id = idcrossref(argosid,2,1);
                    pmeta.ftptime = ftptime;
                    pmeta.ftp_fname = a{i,1};
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
                    
                    %                 try
                    crash=0;
                    % process iridium - where all the magic happens!!
                    if ~isempty(strmatch(dbdat.status,'live')) | ~isempty(strmatch(dbdat.status,'suspect')) ...
                             | ~isempty(strmatch(dbdat.status,'hold'))
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
                                        
                    if isfloat
                        %after processing, move the files from the delivery directory into the
                        %individual directories:
                        ss=strfind(a{i,1},'.');
                        % try
                        %     system(['mv '  ARGO_SYS_PARAM.iridium_delivery_path a{i,1}(1:ss(2)) '* ' ARGO_SYS_PARAM.iridium_delivery_path  num2str(dbdat.maker_id)]);
                        % catch
                        %     system(['mv '  ARGO_SYS_PARAM.iridium_delivery_path a{i,1}(1:ss(2)) '* ' ARGO_SYS_PARAM.iridium_delivery_path 'f'  num2str(dbdat.maker_id)]);
                        % end
                        
                        
                        if(~isempty(dbdat))
                            if (exist([ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)])~=7)
                                system(['mkdir ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                            end
                            dot=strfind(a{i,1},'.');
                            fn=a{i,1}(1:dot(2));
                            if missingaa | missingbb
                                try
                                    system(['mv -f ' fn '* ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                                end
                            elseif(~crash)
                                system(['mv -f ' fn '* ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                            end
                            % code for copy the data within CSIRO
                            CSIRO_copy_apf11_iridium_data
                        end
                        
                    end
                end
            end
            
        end
    end
end
    
    