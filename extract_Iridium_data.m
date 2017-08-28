% extract Iridium data - checks the delivery directories and, if there is
% new data, processes it before sending strip_argos_msg

global  ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

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
% list all .msg and .log files
a=dirc([idatapath '*.*.log']);
b=dirc([idatapath '*.*.msg']);
a=[a 
    b];
[m,n]=size(a);

% check for log/msg file corruption
% method: check each set of files .msg the .log for file size equal zero
%         then check for missing files

% check for zero sized files
for j=1:m
    if (a{j,5} == 0)
        % mail out error
        mail_out_iridium_log_error([a{j,1}],2)
    end
end

% re-list as we may have lost some
a=dirc([idatapath '*.*.log']);
b=dirc([idatapath '*.*.msg']);
crash2=0;

%Bec did this (22 Oct, 2010)
bb = char(b{:,1});
bb = bb(:,1:end-3);
aa = char(a{:,1});
aa = aa(:,1:end-3);
[nn,ia,ib] = intersect(aa,bb,'rows');

for i = 1:size(aa,1)
    if ismember(aa(i,:),nn,'rows') == 0
        % find_rudics_file will only look for files on server if processor
        % is CSIRO.
        found=find_rudics_file(a{i,1});
        if ~found
            mail_out_iridium_log_error([a{i,1}],1);
        else
            %need to transfer to ftp (only works if CSIRO is processor)
            BOM_retrieve_Iridium
        end
    end
end
for i = 1:size(bb,1)
    if ismember(bb(i,:),nn,'rows') == 0
        % find_rudics_file will only look for files on server if processor
        % is CSIRO.
        found=find_rudics_file(b{i,1});
        if ~found
            mail_out_iridium_log_error([b{i,1}],1);
        else
            %need to transfer to ftp (only works if CSIRO is processor)
            BOM_retrieve_Iridium
        end
    end
end

%reload directories which might now have missing files retrieved:
a=dirc([idatapath '*.*.log']);
b=dirc([idatapath '*.*.msg']);
crash2=0;

%Bec did this (22 Oct, 2010)
bb = char(b{:,1});
bb = bb(:,1:end-3);
aa = char(a{:,1});
aa = aa(:,1:end-3);
[nn,ia,ib] = intersect(aa,bb,'rows');


% a=[a
%     b]

% [m,n]=size(a);

% for each file in the list look for a match, if no match send message
% loop through all files
% for i=1:m
% 	% match flag
%     setmatch=0;

% 	% loop through a second time
%     for j=1:m
% 		% if the iterators are NOT the same
% 		if (i ~= j)
% 			% compare the two file names
%         	if strmatch(a{i,1}(1:length(a{i,1})-3),a{j,1}(1:length(a{j,1})-3))
% 				% if a match, i.e. two files a .msg and a .log, set flag
%             	setmatch=1;
%         	end
% 		end
%     end

% 	% if flag is not set, i.e. no two files, send error and move file
%     if (~setmatch)
%         % mail out error
%         if (strmatch('msg',a{j,3}))
%         else
%             mail_out_iridium_log_error([a{j,1}],1)
%             system(['cp -f ' a{i,1} ' ' ARGO_SYS_PARAM.iridium_path '/iridium_bad_files'])
%         end
%     end

% end

% re-list only .msg files
a=dirc([idatapath '*.msg']);

[m,n]=size(a);

% for j=1:m REMOVE THIS AND KEEP ZERO LENGTH FILES IN PROCESSING.
%     if (a{j,5} == 0)
%         % mail out error
%         a(j,:)=[];
%         m=m-1;
%         break
%     end
% end

% isfloat=0;


if(m>0)
    for i=1:m
        isfloat=0;
        
        if(a{i,6})  %is this a directory?
            
        else  %first check whether this float is in the spreadsheet:
            a{i,1}
            ftptime = julian(datevec(a{i,4}));
            argosid = str2num(a{i,1}(1:4));
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
            else
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
                if ispc
                    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles\float' num2str(dbdat.wmo_id)];
                else
                    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
                end
                
                try
                    crash=0;
                    % process iridium - where all the magic happens!!
                    if(~isempty(strmatch(dbdat.status,'live')) | ~isempty(strmatch(dbdat.status,'suspect')))
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
                    mail_out_iridium_log_error([a{i,1}],3);
                    crash=1;
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
                        if ispc
                            if (exist([ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)])~=7)
                                system(['mkdir ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                            end
                            file2=[a{i,1}(1:length(a{i,1})-3) 'log'];
                            if ~exist(a{i,1},'file') | ~exist(file2,'file')
                                try
                                    system(['cp -f ' a{i,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                                    system(['cp -f ' a{i,1}(1:length(a{i,1})-3) 'log ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                                end
                            elseif(~crash)
                                system(['mv -f ' a{i,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                                system(['mv -f ' a{i,1}(1:length(a{i,1})-3) '* ' ARGO_SYS_PARAM.iridium_path  'iridium_processed\' num2str(dbdat.wmo_id)]);
                            end
                            
                        else
                            if (exist([ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)])~=7)
                                system(['mkdir ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                            end
                            file2=[a{i,1}(1:length(a{i,1})-3) 'log'];
                            if ~exist(a{i,1},'file') | ~exist(file2,'file')
                                try
                                    system(['cp -f ' a{i,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                                    system(['cp -f ' a{i,1}(1:length(a{i,1})-3) 'log ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                                end
                            elseif(~crash)
                                system(['mv -f ' a{i,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                                system(['mv -f ' a{i,1}(1:length(a{i,1})-3) '* ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                            end
                        end
                        % code for copy the data within CSIRO
%                         CSIRO_copy_iridium_data
                    end
                    
                end
            end
        end
        
    end
    
end

% now process any solo II data that's arrived in the last 6 hours:
% extract_Solo2_data
