% extract Iridium data - checks the delivery directories and, if there is
% new data, processes it before sending strip_argos_msg

global  ARGO_SYS_PARAM
global   ARGO_ID_CROSSREF THE_ARGO_FLOAT_DB

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
if isempty(ARGO_ID_CROSSREF)
    getdbase(0);
end

clear X nn Hull dive id valid sbdm sbds stat
% System tuning parameters (could be shifted to ARGO_SYS_PARAM ?)
% Too_Old_Days = 11;         % Realtime: no interested beyond 10 and a bit days.
jnow = julian(clock);      % Local time - now

% eval(['cd ' ARGO_SYS_PARAM.solo2_path]);
% idatapath = [ARGO_SYS_PARAM.solo2_path 'mail'];
eval(['cd ' ARGO_SYS_PARAM.root_dir]);
solo2_path = [ARGO_SYS_PARAM.root_dir 'solo2_data/'];
idatapath = [solo2_path];

% list all .eml files
a=dirc([idatapath '*_*.eml']);
b=dirc([idatapath '*_*.sbd']);
[m,n]=size(a);
if m == 0
    return
end

crash2=0;
sbdm=[];


% isfloat=0;

% we need to step through all received SBD messages to group by iridium id,
% then process in a group. They cannot be processed until they are
% identified and grouped...

if(m>0)
    for i=1:m
        isfloat=0;
        
        if(a{i,6})  %is this a directory?
            
        elseif (strmatch('._',a{i,1}))  % is this a phantom mac file?
            
        else  %first gather the unique sbds in the directoy:
            dd3=strfind(a{i,1},'_');
            if(~isempty(dd3))
                sbds(i)=str2num(a{i,1}(1:dd3-1));
            end
            
        end
    end
    uni=unique(sbds);
    
    [imei,hullid] = inputArgoIMEI;
    
    for j=1:length(uni)
        sbd=num2str(uni(j))
        kk = strmatch(sbd,imei)
        if ~isempty(kk)
            % we have a match and it's one of our floats: note - we need to break it
            % up into different profiles
            argosid=hullid{kk};

            wm=find(ARGO_ID_CROSSREF(:,5)==str2num(argosid));
           
            wmoid=ARGO_ID_CROSSREF(wm,1);
            %             if ~any(argosidlist==argosid)
            %                 % Not a float we know or want
            %                 logerr(0,'');
            %                 dbdat = [];
            %                 % If flist supplied then this is simply one of the floats we are
            %                 % not interested in. Otherwise, it is not known to our database,
            %                 % so either a corrupted id or the database is out of date.
            %                 if isempty(flist)
            %                     logerr(3,['? New float, Argos ID=' num2str(argosid)]);
            %                 end
            %                 %                 return
            %             else
            %                 % Set details for the next profile
            %                 pmeta.wmo_id = idcrossref(argosid,2,1);
            %                 pmeta.ftptime = ftptime;
            %                 pmeta.ftp_fname = a{i,1};
            %
            %                 dbdat = getdbase(pmeta.wmo_id);
            %                 logerr(0,num2str(pmeta.wmo_id));
            isfloat=1;
            %             end
            
            %gather messages from one float here:
            
            c=dirc([idatapath sbd '_*.eml']);
            clear iridium_lat
            clear iridium_lon
            clear iridiumCEP
            clear msgno
            
            [mm,nn]=size(c)
            il=0;
            for ii=1:mm
                fid=fopen([idatapath c{ii,1}]);
                il=il+1;
                ib=0;
                gg=fgetl(fid);
                while ischar(gg)   %~=-1
                    if strmatch('Unit Location',gg)
                        ll=strfind(gg,' ');
                        try
                            iridium_lat(il)=str2num(gg(ll(4):ll(5)));
                            iridium_lon(il)=str2num(gg(ll(7):end));
                        catch
                            gg=fgetl(fid);
                            ll=strfind(gg,' ');
                            iridium_lat(il)=str2num(gg(1:ll(1)));
                            iridium_lon(il)=str2num(gg(ll(3):end));
                        end   
                        % need to change this to 360 degree globe:
                       
                    elseif strmatch('CEPradius',gg)
                        ll=strfind(gg,' ');
                        iridiumCEP(il)=str2num(gg(ll(2):end));
                    elseif strmatch('MOMSN',gg)
                        ll=strfind(gg,' ');
                        msgno(il)=str2num(gg(ll(1):end));
                    elseif strmatch('Time of Session',gg)
                        ll=strfind(gg,':');
                        usethis=1;
                        dn=datenum(gg(ll(1)+6:end));
                        if datenum(now)-dn<=ARGO_SYS_PARAM.run_time-0.25  % set up time screen 
                            %so make sure you have all the data before you
                            %process a profile: but make it shorter because
                            %most sbds should arrive within minutes of each
                            %other
                            usethis=0;
                        end
                        ds=str2num(datestr(dn,'yyyy mm dd HH MM SS'));
                        jday(il)=julian(ds);
                    elseif  ~isempty(strfind(gg,'Status'))
                        ll=strfind(gg,':');
                        ld=strfind(gg,'-');
                        if ~isempty(ld)
                            statt(il)=str2num(gg(ll(1)+1:ld-1));
                        end
                     end
                    gg=fgetl(fid);
                end
                
                    fclose(fid);
                    if usethis
                        system(['mv ' idatapath c{ii,1} ' ' idatapath 'processed/' num2str(wmoid)]);
                    end

                    % now decode the binary attachment to get the data:
                                    
                    sbdfile=([idatapath c{ii,1}(1:end-3) 'sbd']);
                    [X(il), nn(il), Hull(il), dive(il), id(il), valid(il)] = solo2_GetHeader(sbdfile);  %Vito's code
                    if(dive(il)>65500)  % overflow - pre-deployment data? no dive...
                        il=il-1;
                        system(['mv ' sbdfile ' ' idatapath 'processed/' num2str(wmoid)]);
                    elseif ~usethis
                        il=il-1;
                    elseif usethis
                        fid2=fopen(sbdfile,'rb');
                        ss=fread(fid2, 340);
                        sbdm(il,1:length(ss))=ss;
                        fclose(fid2);
                        system(['mv ' sbdfile ' ' idatapath 'processed/' num2str(wmoid)]);
                    end
            end
                 save(['sbdm' num2str(wmoid) '.mat'])   
            % steps:
            % first get the profile numbers and binary data of all sbd messages in
            % this session - done in dive and sbdm
            % 2 - sort by profile number and process one by one.
            % 3 - put directly into the float format structure which needs to hold
            % the binary as well (for future processing)
            % 4 - generate the profile files and plots, then move
            % onto the next profile.

            if isempty(sbdm)
                
            else 
                dd=unique(dive);
                
                for ddd=1:length(dd)
                    psal=[];
                    pres=[];
                    temp=[];
                    psalID=[];
                    tempID=[];
                    presID=[];
                    fl=[];
                    fldb=[ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmoid) 'auxS.mat']
                    if exist(fldb,'file')
                        load(fldb);
                        fl=floatTech;
                    end
                    fnm=[ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmoid) '.mat'] ;
                    if exist(fnm,'file')
                        float=[];
                        load(fnm);
                    end
                    dbdat=getdbase(wmoid);
                    flo=new_profile_struct(dbdat);
                    fl=new_tech_struct(dbdat);
                    
                    kkl=find(dive==dd(ddd));
                    addSolo2Iridium  %put the iridium data into a substructure of the tech structure.
                    fl.IridiumPosn =  tech;
                    for jjj=1:length(kkl)
                        
                        sb=sbdm(kkl(jjj),:);
                        if(sb(end)==0);  % try this and see what happens:
                            da=find(sb==62);
                            if ~isempty(da)
                                sb(da(end)+1:end)=[];
                            end
                        end
                        
                        %verify first and last bytes:
                        n2=length(sb);
                        if ((sb(1)~=88) || (sb(end)~=62)) continue; end;
                        d=9;
                        Indices = d;
                        while (true)
                            nn = sb(d+1)*256 + sb(d+2);
                            d  = d + nn;
                            if (d>n2-5) break; end;
                            if (sb(d-1) ~= 59)
                                seethis=sb(d-1)
                                sb=sb
                                break
                            end; % ';' character
                            Indices = [Indices; d];
                        end
                        
                        if ~isempty(Indices)
                            IDs = sb(Indices);
                            for ind=1:length(IDs)
                                d = Indices(ind);
                                nn = sb(d+1)*256 + sb(d+2);
                                sbl = sb(d:d+nn-1);
                                
                                switch IDs(ind)  % most converted from Vito's routines:
                                    
                                    case 0;
                                        fl.GPSEndFirstDive = decodeSolo2GPS(sbl);  %fprintf('   -GPS_BeforeLeavingSurface \n');     %ok
                                    case 1;
                                        fl.GPSEndSurface = decodeSolo2GPS(sbl);  %fprintf('   -GPS_BeforeLeavingSurface \n');     %ok
                                    case 2;
                                        fl.GPSEndProfile = decodeSolo2GPS(sbl);  %fprintf('   -GPS_EndOfProfiling \n');           %ok
                                    case 3;
                                        fl.GPSProfileAbort = decodeSolo2GPS(sbl);  %fprintf('   -GPS_EndOfMissionAbort \n');        %ok
                                    case 4;
                                        fl.GPSEndOfOperationQuit = decodeSolo2GPS(sbl);  %fprintf('   -GPS_EndOfOperationQuit \n');       %ok
                                    case 5;
                                        fl.GPSEndOfSelfTest = decodeSolo2GPS(sbl);  %fprintf('   -GPS_EndOfSelfTest \n');            %ok
                                    case 64;
                                        fl.FallRate = decodeSolo2RiseRate(sbl);  %fprintf('   -FallRate \n');                     %ok
                                    case 80;
                                        fl.RiseRate = decodeSolo2RiseRate(sbl);  %fprintf('   -RiseRate \n');                     %ok
                                    case 96;
                                        fl.PumpSeries = decodeSolo2PumpSeries(sbl);  %fprintf('   -Pump Series \n');                  %ok
                                    case 208;
                                        fl.MissionConfig = decodeSolo2Config(sbl);   %fprintf('   -Ascii dump of mission config \n'); %ok
                                    case 224;
                                        fl.TechE0 = decodeSolo2EngE0(sbl);  %fprintf('   -TechE0 \n');                       %ok
                                    case 226;
                                        fl.TechE2 = decodeSolo2EngE2(sbl);  %fprintf('   -TechE2 \n');
                                    case 227;
                                        fl.TechE3 = decodeSolo2EngE3(sbl);  %fprintf('   -TechE3 \n');
                                    case 229;
                                        fl.TechE5 = decodeSolo2EngE5(sbl);  %fprintf('   -TechE5 \n');
                                    case 240;
                                        fl.Mission = decodeSolo2Mission(sbl);  %fprintf('   -Argo \n');
                                    otherwise    %ok
                                        
                                        if(IDs(ind)<=63 & IDs(ind)>=48);  %Salinity
                                            decodeSoloS;
                                        end
                                        
                                        if(IDs(ind)<=31 & IDs(ind)>=16);  %Pressure
                                            decodeSoloP;
                                        end
                                        
                                        if(IDs(ind)<=47 & IDs(ind)>=32);  %Temperature
                                            decodeSoloT;
                                        end
                                end
                                
                            end
                            
                        end
                        % here is where we set the float mat file to the decoded
                        % data:
                    end
                    
                    if length(pres)~=length(temp) | length(pres)~= length(psal)
                        
                        whos  *ID pres psal temp
                        % this implies a missing block - pad the arrays to
                        % realign the data and use with missing values:
                        
                        %                         pts=[length(presID) length(tempID) length(psalID)];
                        
                    end
                    
                    % this is how we get things into the right place,
                 % regardless of whether we have all the data or not! - ??
                 
                 
                 arrP=[];arrT=[];arrS=[];
                 for vv=16:19;
                     p=find(presID==vv);
                     t=find(tempID==vv+16);
                     s=find(psalID==vv+32);
                     if ~isempty(p)
                         pp=length(arrP);
                         arrP(pp+1:pp+length(p))=pres(p);
                         try
                             arrT(pp+1:pp+length(p))=temp(t);
                         catch
                             arrT(pp+1:pp+length(p))=NaN;
                         end
                         try
                             arrS(pp+1:pp+length(p))=psal(s);
                         catch
                             arrS(pp+1:pp+length(p))=NaN;
                         end
                     end
                 end
                 
                 pres=arrP; temp=arrT; psal=arrS;
                 
                 %need to think this through - indices make sense?
                 %                         [pIDsort,pi]=sort(presID);
                 %                         [sIDsort,si]=sort(psalID);
                 %                         [tIDsort,ti]=sort(tempID);
                 %
                 %                         pres=pres(pi);
                 %                         psal=psal(si);
                 %                         temp=temp(ti);
                 %
                 %                         [psort,ip]=sort(pres);
                 irev = length(pres):-1:1;
                 
                 
                 flo.p_raw=pres(irev);
                 flo.t_raw=temp(irev);
                 flo.s_raw=psal(irev);
                 
                 
                 %fill the rest of the profile structure:
                 
                 flo.profile_number = dd(ddd);
                 
                 flo=fill_float_from_solo2(flo,fl,argosid);
                 % more bookkeeping:
                 
                 float(dd(ddd)+1)=flo;
                 np=dd(ddd)+1;
                 
                 float=calibrate_p(float,np);
                 
                 float=qc_tests(dbdat,float,np);
                 [float,cal_rept]=calsal(float,np);
                 
                 % now we need to save these to a matfile...  Do
                 % this each time so nothing is lost
                 
                 floatTech(np)=fl;
                 
                 save(fldb,'floatTech','-v6');
                 save(fnm,'float','-v6');
                 
                 % need to do the plots, too...
                 web_profile_plot(float(np),dbdat);
                 
%                  webUpdatePages(dbdat.wmo_id,float);
                 argoprofile_nc(dbdat,float(np));
                 
                 %                         AND need to do the nc files but not yet:
                 %                         argoprofile_nc(dbdat,float(np))
                 %                         techinfo_nc(dbdat,float,np-1)
                 if np==1
                     metadata_nc(dbdat,float)
                 end
                 
                 
                 techinfo_nc(dbdat,float,-1)
                 time_section_plot(float);
                 waterfallplots(float);
                 locationplots(float);
                 tsplots(float);
                 web_float_summary(float,dbdat,1);
                end
            end
        end
        
        % move files to archive directory according to wmo (not Hull) ID
        
        %done earlier as the files are read and decoded...
        
    end
end


            % QUESTION - WHERE IS THE DRIFT DATA FOUND? DECODED? STORED??
            % Answer - in E2 - park averages only!
            
