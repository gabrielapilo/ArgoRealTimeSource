% extract phy data (Solo Polynya data) - checks the delivery directories and, if there is
% new data, processes it before ending strip_argos_msg

global  ARGO_SYS_PARAM

% System tuning parameters (could be shifted to ARGO_SYS_PARAM ?)
Too_Old_Days = 11;         % Realtime: no interested beyond 10 and a bit days. 
jnow = julian(clock);      % Local time - now

eval(['cd ' ARGO_SYS_PARAM.iridium_path]);
idatapath = ARGO_SYS_PARAM.iridium_path;

% list all .phy (Polynya) files
a=dirc([idatapath '*.phy']);
[m,n]=size(a);
if m == 0
    return
end
% no error checking except for xero size files - we rely on the data transfer to be correct until
% shown otherwise!

for j=1:m
    if (a{j,5} == 0)
        % mail out error
a(j,:)=[];
m=m-1;
break
    end
end

if(m>0)
    for i=1:m
        isfloat=0;

        if(a{i,6})  %is this a directory?

        else  %first check whether this float is in the spreadsheet:
            a{i,1}
            ftptime = julian(datevec(a{i,4}));
            argosid = str2num(a{i,1}(1:4));
            if length(num2str(argosid))~=4
                % Bad ID num
                argosid = -1;
                logerr(0,'');
                dbdat = [];
            elseif ~any(argosidlist==argosid)
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

                dbdat = getdbase(pmeta.wmo_id);
                logerr(0,num2str(pmeta.wmo_id));
                isfloat=1;
            end

            %get the float structure for this float:

            if isfloat
                fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];

%                 try
                    crash=0;
                    % process phyfiles - where all the magic happens!!
                    if(~isempty(strmatch(dbdat.status,'live')) | ~isempty(strmatch(dbdat.status,'suspect')) | opts.redo)
                        process_phyfiles(pmeta,dbdat,opts)
                    elseif(~isempty(strmatch(dbdat.status,'expected')))
                        logerr(3,['? New float, phy ID=' num2str(argosid)]);
                        nprec = find(PROC_REC_WMO==dbdat.wmo_id);
                        if isempty(nprec)
                            logerr(3,['Creating new processing record as none found for float ' ...
                                num2str(dbdat.wmo_id)]);
                            nprec = length(PROC_REC_WMO) + 1;
                            PROC_RECORDS(nprec) = new_proc_rec_struct(dbdat,1);
                        end
                        isfloat=0;
                    end
%                 catch
%                     isfloat=0;
% %                     mail_out_iridium_log_error([a{i,1}],4);
%                     crash=1;
%                 end
                    
                if isfloat
                    %after processing, move the files from the delivery directory into the
                    %individual directories:
                    ss=strfind(a{i,1},'.');
	
                    if(~isempty(dbdat))
                        if (exist([ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)])~=7)
                            system(['mkdir ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                        end
                        if(~crash)
                            system(['mv -f ' a{i,1} ' ' ARGO_SYS_PARAM.iridium_path  'iridium_processed/' num2str(dbdat.wmo_id)]);
                        end
					% code for copy the data within CSIRO
 					CSIRO_copy_phy_data
                    end

                end
            end
        end

    end
end
