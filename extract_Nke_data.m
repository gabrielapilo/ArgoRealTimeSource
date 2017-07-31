% extract Iridium data communicated by NKE floats - checks the delivery directories and, if there is
% new data, processes it before sending strip_argos_msg
% Modified from extract SOLO floats from CSIRO
% Author Udaya Bhaskar for Arovor-I NKE instrumentation type floats, June 2017
global  ARGO_SYS_PARAM
global   ARGO_ID_CROSSREF THE_ARGO_FLOAT_DB

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
if isempty(ARGO_ID_CROSSREF)
    getdbase(0);
end

clear X dive sbdm sbds stat
% System tuning parameters (could be shifted to ARGO_SYS_PARAM ?)
% Too_Old_Days = 11;         % Realtime: no interested beyond 10 and a bit days.
jnow = julian(clock);      % Local time - now

% eval(['cd ' ARGO_SYS_PARAM.solo2_path]);
% idatapath = [ARGO_SYS_PARAM.solo2_path 'mail'];
eval(['cd ' ARGO_SYS_PARAM.root_dir]);
nke_path = [ARGO_SYS_PARAM.root_dir 'Nke_data/'];
idatapath = [nke_path];

% list all .eml files
a=dirc([idatapath '*_*.eml']);
b=dirc([idatapath '*_*.sbd']);
[m,n]=size(a)

crash2=0;
sbdm=[];
ctdasc = [];
ctddes = [];
ctddrf = [];
desproflag = 0;

% isfloat=0;

% we need to step through all received SBD messages to group by iridium id,
% then process in a group. They cannot be processed until they are
% identified and grouped...

if(m>0) % 1
    for i=1:m % 2
        isfloat=0;
        
        if(a{i,6}) %3  %is this a directory?
            
        elseif (strmatch('._',a{i,1}))  % is this a phantom mac file?
            
        else  %first gather the unique sbds in the directoy:
            dd3=strfind(a{i,1},'_');
            if(~isempty(dd3))
                sbds(i)=str2num(a{i,1}(1:dd3-1));
            end
            
        end %3end
    end % 2end
    uni=unique(sbds);
    
    [imei,hullid] = inputArgoIMEI;
    
    for j=1:length(uni) % 4
        sbd=num2str(uni(j))
        kk = strmatch(sbd,imei)
        if ~isempty(kk) % 5
            % we have a match and it's one of our floats: note - we need to break it
            % up into different profiles
            argosid=hullid{kk};

            wm=find(ARGO_ID_CROSSREF(:,5)==str2num(argosid));
           
            wmoid=ARGO_ID_CROSSREF(wm,1);

            isfloat=1;
            
            %gather messages from one float here:
            
            c=dirc([idatapath sbd '_*.eml']);
            clear iridium_lat
            clear iridium_lon
            clear iridiumCEP
            clear msgno
            
            [mm,nn]=size(c)
            il=0;
            for ii=1:mm % 6
                fid=fopen([idatapath c{ii,1}]);
                il=il+1;
                ib=0;
                gg=fgetl(fid);
                while ischar(gg) %7   %~=-1
                    if strmatch('Unit Location',gg) %8
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
                     end % 8end
                    gg=fgetl(fid);
                end %7end
                
                    fclose(fid);
                    if usethis
                        system(['mv ' idatapath c{ii,1} ' ' idatapath 'processed/' num2str(wmoid)]);
                    end

                    % now decode the binary attachment to get the data:
                                    
                    sbdfile=([idatapath c{ii,1}(1:end-3) 'sbd']);
                    [X(il), dive(il)] = nke_GetHeader(sbdfile);  %Uday's code
                    if(dive(il)>65500)  % overflow - pre-deployment data? no dive...
                        il=il-1;
                        system(['mv ' sbdfile ' ' idatapath 'processed/' num2str(wmoid)]);
                    elseif ~usethis
                        il=il-1;
                    elseif usethis
                        fid2=fopen(sbdfile,'rb');
                        ss=fread(fid2);
                        sbdm(il,1:length(ss))=ss;
                        fclose(fid2);
                        system(['mv ' sbdfile ' ' idatapath 'processed/' num2str(wmoid)]);
                    end
            end % 6end
                 save(['sbdm' num2str(wmoid) '.mat'])   
            % steps:
            % first get the profile numbers and binary data of all sbd messages in
            % this session - done in dive and sbdm
            % 2 - sort by profile number and process one by one.
            % 3 - put directly into the float format structure which needs to hold
            % the binary as well (for future processing)
            % 4 - generate the profile files and plots, then move
            % onto the next profile.

            if isempty(sbdm) % 9
                
            else 
                dd=unique(dive);
                
                for ddd=1:length(dd) %10
                   % to store ascending P,T,S
                    ascpsal=[];
                    ascpres=[];
                    asctemp=[];
                   % to store descending P,T,S
                    despsal=[];
                    despres=[];
                    destemp=[];
                   % to store drifting P,T,S
                    drfpsal=[];
                    drfpres=[];
                    drftemp=[];

                    %psalID=[];
                    %tempID=[];
                    %presID=[];
                    fl=[];
                    fldb=[ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmoid) 'auxNke.mat']
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
                    fl=new_tech_struct_nke(dbdat); % for adding the new struct variable to the mat file
                    
                    kkl=find(dive==dd(ddd));
                    addNke2Iridium  %put the Nke SBD iridium data into a substructure of the tech structure.
                    fl.IridiumPosn =  tech;
                    for jjj=1:length(kkl) %11
                        
                        sb=sbdm(kkl(jjj),:);
                        
                        %verify first byte to know the type of packet in each of the messages:
                        n2=length(sb);
                        %if(n2 == 300)
                         byt = 1;
                        for(blk=1:1:(n2/100)) %12
                            IDs = sb(byt:(byt+99));
                            %for ind=1:length(IDs) %13
                                
                                switch IDs(1) %14  % To obtain data corresponding to different packet types
                                    
                                    case 0;
                                         if((IDs(2)*256 + IDs(3)) == 0 && (IDs(7)*256 + IDs(8)) == 0);
                                         else
                                            fl.TechPkt1Info = decodeNkeTechPkt1Typ0(IDs);
                                         end  
                                    case 1;
                                        decodeNkeDCTDPktTyp1; % to decode Descending CTD packets 
                                        tmpdes = [despres(1,:);destemp(1,:);despsal(1,:);despres(2,:);destemp(2,:);despsal(2,:)];
                                        ctddes = [ctddes,tmpdes];
                                        desproflag = 1; 
                                    case 2;
                                        decodeNkeSCTDPktTyp2; % to decode drifting CTD packets
                                        tmpdrf = [drfpres(1,:);drftemp(1,:);drfpsal(1,:);drfpres(2,:);drftemp(2,:);drfpsal(2,:)];
                                        ctddrf = [ctddrf,tmpdrf];
                                    case 3;
                                        decodeNkeACTDPktTyp3; % to decode Ascending CTD packets
                                        tmpasc = [ascpres(1,:);asctemp(1,:);ascpsal(1,:);ascpres(2,:);asctemp(2,:);ascpsal(2,:)];
                                        ctdasc = [ctdasc,tmpasc];
                                    case 4;
                                        fl.TechPkt2Info = decodeNkeTechPkt2Typ4(IDs);  
                                    case 5;
                                        fl.ParamN1PktInfo = decodeNkeParamN1PktTyp5(IDs);  
                                    case 6;
                                        fl.HydraulicPktInfo = decodeNkeHydraulicPktTyp6(IDs);  
                                    case 7;
                                        fl.ParamN2PktInfo = decodeNkeParamN2PktTyp7(IDs); 
                                end %14end
                            %end %13end
                            byt = byt+100; 
                        end %12end
                      end %11end
                 ctdasc
                 
                 %flo.p_raw=pres; %(irev);
                 %flo.t_raw=temp; %(irev);
                 %flo.s_raw=psal; %(irev);
                 flo.p_raw =  ctdasc(1,:);
                 flo.t_raw =  ctdasc(2,:);
                 flo.s_raw =  ctdasc(3,:);
                 
                 %fill the rest of the profile structure:
                 
                 flo.profile_number = dd(ddd);
                 
                 flo=fill_float_from_nke(flo,fl,argosid);
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
                 write_tesac(dbdat,float(np));
                 BOM_write_BUFR;
                % To clear the processed profile data
                 ctdasc=[];
                 ctddes=[];
                 ctddrf=[];
                %end % 11end
            end % 10end
                 X = [];
                 dive = [];
        end % 9end
        
        % move files to archive directory according to wmo (not Hull) ID
        
        %done earlier as the files are read and decoded...
       end %end5
    end %end4
%ctdasc = [];
%ctddes = [];
%ctddrf = [];    
end %end1
