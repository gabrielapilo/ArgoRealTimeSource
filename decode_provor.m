% DECODE_PROVOR  reads block data from Provor float Argos transmissions and
%            decode.
%
% INPUT  prof - decimal profile (in blocks and lines) from STRIP_ARGOS_MSG
%        dbdat- details for this float from the float master database
%        pos - the header structure containing the current profile
%        date/time
%
% OUTPUT pro  - structure containing profile and tech data
%
% Jeff Dunn CMAR/BoM  July 2006
%
% USAGE: pro = decode_provor(prof,dbdat,pos)

%  subtype 1 = CSIRO early Provor floats (17440)
%  subtype 2 = CSIRO second gen floats (34889)
%  subtype 3 = 
%  subtype 4 = CTS-3 Martec format
%  subtype 5 = Indian FSI floats
%  subtype 6 = Korean float - sn MT-092 and MT-93

function fp = decode_provor(prof,dbdat,pos)

fp = [];
pro = new_profile_struct(dbdat);

[nblk,nbyt] = size(prof);
if(dbdat.subtype==4)
    if nbyt~=31
        logerr(1,['DECODE_PROVOR: Message length ' num2str(nbyt) ...
            ', expect 31, float type ' num2str(dbdat.subtype)]);
%         fp=pro;
        return
    end
elseif(dbdat.subtype==2 | dbdat.subtype==3  | dbdat.subtype==1 | dbdat.subtype==6)
    if nbyt~=32
        logerr(1,['DECODE_PROVOR: Message length ' num2str(nbyt) ...
            ', expect 32, float type ' num2str(dbdat.subtype)]);
%         fp=pro;
        return
    end
end


% Note that CRC checking has been done before this routine

% Reduce to uint8 (bytes) and then to bits. We work on either copy of the
% first message, depending on whether or not the required number is a whole
% byte.

bytpro = uint8(prof);
bitpro = zeros(nblk,nbyt*8,'uint8');
for kk = 1:nblk
    if  dbdat.subtype==4
        for ii = 1:31
            jj = ((ii-1)*8) + (1:8);
            bitpro(kk,jj) = fliplr(bitget(bytpro(kk,ii),1:8));
        end
        %note - for this subtype, you need to rearrange the data into
        %sensible order and eliminate duplicates - do this in find_best_message!
    else
        for ii = 1:32
            jj = ((ii-1)*8) + (1:8);
            bitpro(kk,jj) = fliplr(bitget(bytpro(kk,ii),1:8));
        end
    end
end

% Working from PROVOR Argos Formats  Version 1.6 Sec 2.5 Technical Message,
% and checking agreement with 'processprovorV3.m'. It seems we do not have
% the ARGOS ID byte, bit 1 is at start of CRC.

if bytpro(1,2)~=1 & dbdat.subtype==2
    logerr(1,'DECODE_PROVOR: First block num not 1');
    return
end

pro.wmo_id = dbdat.wmo_id;

if(dbdat.subtype==1)

    pro.desc_sttime       = double(bytpro(1,3))*.1;
    pro.n_valve_acts_surf = bytpro(1,4);
    pro.first_stab_time   = double(bytpro(1,5))*.1;
    pro.n_valve_acts_desc = bin2num(bitpro(1,41:44));
    pro.n_pump_acts_desc  = bin2num(bitpro(1,45:48));
    pro.desc_endtime      = double(bytpro(1,7))*.1;
    pro.n_repositions     = bytpro(1,8);
    pro.resurf_endtime    = double(bytpro(1,9))*.1;
    pro.n_pump_acts_asc   = bytpro(1,10);
    pro.n_pump_acts_surf  = bytpro(1,11);
    pro.float_time_hour   = bin2num(bitpro(1,89:93));
    pro.float_time_min    = bin2num(bitpro(1,94:99));
    pro.float_time_sec    = bin2num(bitpro(1,100:105));
    pro.pres_offset       = bin2num(bitpro(1,106:115))*.1 ;  %- 5.12;
    pro.internal_vacuum   = bin2num(bitpro(1,116:121))*5 + 700;
    pro.n_asc_blks        = bin2num(bitpro(1,122:129));
    pro.n_asc_samps       = bin2num(bitpro(1,130:137));
    pro.n_drift_blks      = bin2num(bitpro(1,138:145));
    pro.drift_samp_period  = bin2num(bitpro(1,146:153));
    pro.n_drift_samps     = bin2num(bitpro(1,154:161));
    pro.date_1st_driftsamp= bin2num(bitpro(1,162:172));
    pro.time_1st_driftsamp= bin2num(bitpro(1,173:180))*.1;
    pro.sevenV_batvolt    = bin2num(bitpro(1,181:186))*.1 + 4.;
    pro.fourteenV_batvolt = bin2num(bitpro(1,187:193))*.1 + 8.;
    pro.asc_prof_num      = bin2num(bitpro(1,194:201)) + dbdat.np0;

    tbits = bitpro(1,202:217);
    sbits = bitpro(1,218:232);
    pbits = bitpro(1,233:247);

    % Construct index for all the bits in a block, for each property
    jt = []; js = []; jp = [];
    for ii = 17:46:201
        jt = [jt ii+(0:15)];
        js = [js (ii+16)+(0:14)];
        jp = [jp (ii+16+15)+(0:14)];
    end

    for iblk = 2:nblk
        tbits = [tbits bitpro(iblk,jt)];
        sbits = [sbits bitpro(iblk,js)];
        pbits = [pbits bitpro(iblk,jp)];
    end

    t    = bin2num(tbits,16)*.001 - 5;
    s    = bin2num(sbits,15)*.001 + 25;
    p    = bin2num(pbits,15)*.1;

    jj = pro.n_asc_samps;
    try
    while jj>0 && p(jj)==3000 && t(jj)==0 && s(jj)==25
        jj = jj-1;
    end
    catch
        jj=0;
    end
    pro.n_asc_samps = jj;

    pro.t_raw = t(1:jj)';
    pro.s_raw = s(1:jj)';
    pro.p_raw = p(1:jj)';

    % These Provor-only fields need to be copied to the equivalent generic
    % fields (have kept the Provor-only versions because we did so in the
    % past  -jrd)
    pro.surfpres = pro.pres_offset;
    pro.profile_number = pro.asc_prof_num;
    pro.voltage = pro.fourteenV_batvolt;
    fp = pro;

elseif(dbdat.subtype==2)

    pro.desc_sttime       = double(bytpro(1,3))*.1;
    pro.n_valve_acts_surf = bytpro(1,4);
    pro.first_stab_time   = double(bytpro(1,5))*.1;
    pro.n_valve_acts_desc = bin2num(bitpro(1,41:44));
    pro.n_pump_acts_desc  = bin2num(bitpro(1,45:48));
    pro.desc_endtime      = double(bytpro(1,7))*.1;
    pro.n_repositions     = bytpro(1,8);
    pro.resurf_endtime    = double(bytpro(1,9))*.1;
    pro.n_pump_acts_asc   = bytpro(1,10);
    pro.n_pump_acts_surf  = bytpro(1,11);
    pro.float_time_hour   = bytpro(1,12);  % bin2num(bitpro(1,89:93));
    pro.float_time_min    = bytpro(1,13);  % bin2num(bitpro(1,94:99));
    pro.float_time_sec    = bytpro(1,14);  % bin2num(bitpro(1,100:105));
    pro.pres_offset       = bin2num(bitpro(1,113:122))*.1;   % - 5.12;
    pro.internal_vacuum   = bin2num(bitpro(1,123:128))*5 + 700;
    pro.n_asc_blks        = bytpro(1,17);  % bin2num(bitpro(1,122:129));
    pro.n_asc_samps       = bytpro(1,18);  % bin2num(bitpro(1,130:137));
    pro.n_drift_blks      = bytpro(1,19);  % bin2num(bitpro(1,138:145));
    pro.drift_samp_period  = bytpro(1,20); % bin2num(bitpro(1,146:153));
    pro.n_drift_samps     = bytpro(1,21);  %bin2num(bitpro(1,161:171));
    pro.date_1st_driftsamp= bin2num(bitpro(1,169:179));
    pro.time_1st_driftsamp= bin2num(bitpro(1,180:187))*.1;
    pro.sevenV_batvolt    = bin2num(bitpro(1,188:193))*.1 + 4.;
    pro.fourteenV_batvolt = bin2num(bitpro(1,194:200))*.1 + 8.;
    pro.asc_prof_num      = bin2num(bitpro(1,201:208)) + dbdat.np0;

    tbits = bitpro(1,209:224);
    sbits = bitpro(1,225:240);
    pbits = bitpro(1,241:256);

    % Construct index for all the bits in a block, for each property
    jt = []; js = []; jp = [];
    for ii = 17:48:256
        jt = [jt ii+(0:15)];
        js = [js (ii+16)+(0:15)];
        jp = [jp (ii+16+16)+(0:15)];
    end
    n_ascentblocks = floor((double(pro.n_asc_samps) - 1)/5);
    for iblk = 2:n_ascentblocks+2
        tbits = [tbits bitpro(iblk,jt)];
        sbits = [sbits bitpro(iblk,js)];
        pbits = [pbits bitpro(iblk,jp)];
    end

    t    = bin2num(tbits,16)*.001 - 5;
    s    = bin2num(sbits,16)*.001 + 25;
    p    = bin2num(pbits,16)*.1;

    elim=[];
    i=0;
    for jj=1:length(p)

        if (p(jj)>=2900 | p(jj)==0) && t(jj)==-5 && s(jj)==25
            i=i+1;
            elim(i)=jj;
        end
    end
    t(elim)=[];
    p(elim)=[];
    s(elim)=[];
    jj=length(p);
    pro.n_asc_samps = jj;

    pro.t_raw = t(1:jj)';
    pro.s_raw = s(1:jj)';
    pro.p_raw = p(1:jj)';

    % need to decode drift samples (if present)

    if(pro.n_drift_samps>0)
        for iblk=n_ascentblocks+2:nblk
            tbits = [tbits bitpro(iblk,jt)];
            sbits = [sbits bitpro(iblk,js)];
            pbits = [pbits bitpro(iblk,jp)];
        end
        t_d   = bin2num(tbits,16)*.001 - 5;
        s_d   = bin2num(sbits,16)*.001 + 25;
        p_d   = bin2num(pbits,16)*.1;
    end


    % These Provor-only fields need to be copied to the equivalent generic
    % fields (have kept the Provor-only versions because we did so in the
    % past  -jrd)
    pro.surfpres = pro.pres_offset;
    pro.profile_number = pro.asc_prof_num;
    pro.voltage = pro.fourteenV_batvolt;
    fp = pro;

elseif(dbdat.subtype==3)

    pro.desc_sttime       = double(bytpro(2,3))*.1;
    pro.n_valve_acts_surf = bytpro(2,4);
    pro.first_stab_time   = double(bytpro(2,5))*.1;
    pro.n_valve_acts_desc = bin2num(bitpro(2,41:44));
    pro.n_pump_acts_desc  = bin2num(bitpro(2,45:48));
    pro.desc_endtime      = double(bytpro(2,7))*.1;
    pro.n_repositions     = bytpro(2,8);
    pro.resurf_endtime    = double(bytpro(2,9))*.1;
    pro.n_pump_acts_asc   = bytpro(2,10);
    pro.n_pump_acts_surf  = bytpro(2,11);
    pro.float_time_hour   = bytpro(2,12);  % bin2num(bitpro(1,89:93));
    pro.float_time_min    = bytpro(2,13);  % bin2num(bitpro(1,94:99));
    pro.float_time_sec    = bytpro(2,14);  % bin2num(bitpro(1,100:105));
    pro.pres_offset       = bin2num(bitpro(2,113:122))*.1 - 51.2;
    pro.internal_vacuum   = bin2num(bitpro(2,123:128))*5 + 700;
    pro.n_asc_blks        = bytpro(2,17);  % bin2num(bitpro(1,122:129));
    pro.n_asc_samps       = bytpro(2,18);  % bin2num(bitpro(1,130:137));
    %     pro.n_drift_blks      = bytpro(2,19);  % bin2num(bitpro(1,138:145));
    %     pro.drift_samp_period  = bytpro(2,20); % bin2num(bitpro(1,146:153));
    %     pro.n_drift_samps     = bytpro(2,21);  %bin2num(bitpro(1,161:171));
    %     pro.date_1st_driftsamp= bin2num(bitpro(2,169:179));
    %     pro.time_1st_driftsamp= bin2num(bitpro(2,180:187))*.1;
    pro.sevenV_batvolt    = bin2num(bitpro(2,188:193))*.1 + 4.;
    pro.fourteenV_batvolt = bin2num(bitpro(2,194:200))*.1 + 8.;
    pro.asc_prof_num      = bin2num(bitpro(2,201:208)) + dbdat.np0;

    %     tbits = bitpro(1,)                % bitpro(1,209:224);
    %     sbits =                 % bitpro(1,225:240);
    %     pbits =                 % bitpro(1,241:256);

    tbits=[];sbits=[];pbits=[];


    % Construct index for all the bits in a block, for each property
    jt = []; js = []; jp = [];
    for ii = 17:48:256
        jt = [jt ii+(0:15)];
        js = [js (ii+16)+(0:15)];
        jp = [jp (ii+16+16)+(0:15)];
    end
    n_ascentblocks = floor((double(pro.n_asc_samps) - 1)/5);
    for iblk = 3:n_ascentblocks+1
        tbits = [tbits bitpro(iblk,jt)];
        sbits = [sbits bitpro(iblk,js)];
        pbits = [pbits bitpro(iblk,jp)];
    end
    tbits = [tbits bitpro(1,jt)];
    sbits = [sbits bitpro(1,js)];
    pbits = [pbits bitpro(1,jp)];


    t    = bin2num(tbits,16)*.001 - 5;
    s    = bin2num(sbits,16)*.001 + 25;
    p    = bin2num(pbits,16)*.1;

    elim=[];
    i=0;
    for jj=1:length(p)

        if ((p(jj)>=2900 | p(jj)==0) && (t(jj)==0 | t(jj)==-5) && s(jj)==25)...
                | (t(jj)==0 | t(jj)==-5) && s(jj)==25
            i=i+1;
            elim(i)=jj;
        end
    end
    t(elim)=[];
    p(elim)=[];
    s(elim)=[];
    jj=length(p);

    pro.n_asc_samps = jj;

    pro.t_raw = t(1:jj)';
    pro.s_raw = s(1:jj)';
    pro.p_raw = p(1:jj)';

    % need to decode drift samples (if present)

    if(pro.n_drift_samps>0)
        for iblk=n_ascentblocks+2:nblk
            tbits = [tbits bitpro(iblk,jt)];
            sbits = [sbits bitpro(iblk,js)];
            pbits = [pbits bitpro(iblk,jp)];
        end
        t_d   = bin2num(tbits,16)*.001 - 5;
        s_d   = bin2num(sbits,16)*.001 + 25;
        p_d   = bin2num(pbits,16)*.1;
    end


    % These Provor-only fields need to be copied to the equivalent generic
    % fields (have kept the Provor-only versions because we did so in the
    % past  -jrd)
    pro.surfpres = pro.pres_offset;
    pro.profile_number = pro.asc_prof_num;
    pro.voltage = pro.fourteenV_batvolt;
    fp = pro;

elseif(dbdat.subtype==4)

    % we need to calculate profile number:
    juld_launch   = julian([str2num(dbdat.launchdate(1:4)) str2num(dbdat.launchdate(5:6)) str2num(dbdat.launchdate(7:8)) ...
        str2num(dbdat.launchdate(9:10)) str2num(dbdat.launchdate(11:12)) str2num(dbdat.launchdate(13:14))]) ;
    juld_now      = julian(pos(1,:));
    if dbdat.parktime==0;dbdat.parktime=10;end
    pro.profile_number=round((juld_now-juld_launch)/(round(dbdat.parktime+.5)))+1;
    %note - these are more complicated becuase it uses the relative values,
    %not absolute...
    
    % need to check which type of block this is...
    [m,n]=size(bitpro);
    j=0;
    
    for jj=1:m
        c=bin2num(bitpro(jj,1:4));
        
        switch c
            
%           technical information - block 000
            case 0
                pro.desc_sttime       = bin2num(bitpro(jj,21:28))*.1;
                pro.n_valve_acts_surf = bin2num(bitpro(jj,29:35));
                pro.first_stab_time   = bin2num(bitpro(jj,36:43))*.1;
                pro.first_stab_p      = bin2num(bitpro(jj,44:51));
                pro.n_valve_acts_desc = bin2num(bitpro(jj,52:55));
                pro.n_pump_acts_desc  = bin2num(bitpro(jj,56:59));
                pro.desc_endtime      = bin2num(bitpro(jj,60:67))*.1;
                pro.n_repositions     = bin2num(bitpro(jj,68:71));
                pro.resurf_endtime    = bin2num(bitpro(jj,72:79))*.1;
                pro.n_pump_acts_asc   = bin2num(bitpro(jj,80:84));
                
                pro.n_desc_blks    = bin2num(bitpro(jj,85:89));
                pro.n_drift_blks      = bin2num(bitpro(jj,90:94));
                pro.n_asc_blks        = bin2num(bitpro(jj,95:99));
                pro.n_desc_slices_shallow = bin2num(bitpro(jj,100:106));
                pro.n_desc_slices_deep = bin2num(bitpro(jj,107:114));
                pro.n_asc_slices_shallow = bin2num(bitpro(jj,115:121));
                pro.n_asc_slices_deep = bin2num(bitpro(jj,122:129));
                pro.n_drift_samps     = bin2num(bitpro(jj,130:137));
                pro.float_time_hour   = bin2num(bitpro(jj,138:142));  % bin2num(bitpro(jj,89:93));
                pro.float_time_min    = bin2num(bitpro(jj,143:148));  % bin2num(bitpro(jj,94:99));
                pro.float_time_sec    = bin2num(bitpro(jj,149:154));  % bin2num(bitpro(jj,100:105));
                pro.pres_offset       = calc_surf_p(bitpro(jj,155:160));   %- 51.2;
                pro.internal_vacuum   = bin2num(bitpro(jj,161:163))*5 + 725;
                pro.max_desc_park_p        = bin2num(bitpro(jj,164:171))*10.;
                pro.asc_start_time    = bin2num(bitpro(jj,172:179))*.1;
                pro.n_entrance_drift_descent = bin2num(bitpro(jj,180:182));
                pro.min_park_p        = bin2num(bitpro(jj,183:190))*10.;
                pro.max_park_p        = bin2num(bitpro(jj,191:198))*10.;
                g=bitpro(jj,199);
                if (g)
                    pro.grounded       = 'Y';
                else
                    pro.grounded      = 'N';
                end
                pro.n_valve_acts_desc_prof = bin2num(bitpro(jj,200:203));
                pro.n_pump_acts_desc_prof  = bin2num(bitpro(jj,204:207));
                pro.max_prof_p        = bin2num(bitpro(jj,208:215));
                pro.n_repositions_standby = bin2num(bitpro(jj,216:218));
                pro.batvolt_drop_atPmax_pumpon = bin2num(bitpro(jj,219:223));
                pro.desc_sttime_to_prof  = bin2num(bitpro(jj,224:231))*.1;
                pro.desc_endtime_to_prof = bin2num(bitpro(jj,232:239));
                pro.RTC_state        = bitpro(jj,240);
                pro.n_entrance_prof_target = bin2num(bitpro(jj,241:243));

                %     pro.n_asc_samps       = bin2num(bitpro(2,18))  % bin2num(bitpro(1,130:137));
                %      pro.sevenV_batvolt    = bin2num(bitpro(2,188:193))*.1 + 4.;
                %      pro.fourteenV_batvolt = bin2num(bitpro(2,194:200))*.1 + 8.;
                %      pro.asc_prof_num      = bin2num(bitpro(2,201:208)) + dbdat.np0;
                %     tbits = bitpro(1,)                % bitpro(1,209:224);
                %     sbits =                 % bitpro(1,225:240);
                %     pbits =                 % bitpro(1,241:256);
                
            % Park information, block 0101:
                
            case 5
                
                pro.first_park_samp_date = bin2num(bitpro(jj,21:26));
                pro.first_park_samp_time = bin2num(bitpro(jj,27:31))/60;
                
                pro.park_p(1)            = bin2num(bitpro(jj,32:42));
                pro.park_t(1)            = (bin2num(bitpro(jj,43:57))*.001)-2.;
                pro.park_s(1)            = (bin2num(bitpro(jj,58:72))*.001)+10.;
                
                i=73;
                jk=1;
                
                while i < 231
                    try
                        jk=jk+1;
                        if(bitpro(jj,i))
                            pro.park_p(jk)=calc_p(bitpro(jj,i+[1:6]),pro.park_p(jk-1));
                            i=i+7;
                        else
                            pro.park_p(jk) = bin2num(bitpro(jj,i+[1:11]));
                            i=i+12;
                        end
                        if(bitpro(jj,i))
                            pro.park_t(jk)=calc_t(bitpro(jj,i+[1:10]),pro.park_t(jk-1));
                            i=i+11;
                        else
                            pro.park_t(jk) = (bin2num(bitpro(jj,i+[1:15]))*.001)-2.;
                            i=i+16;
                        end
                        
                        if(bitpro(jj,i))
                            pro.park_s(jk)=calc_s(bitpro(jj,i+[1:8]),pro.park_s(jk-1));
                            i=i+9;
                        else
                            pro.park_s(jk) = (bin2num(bitpro(jj,i+[1:15]))*.001)+10.;
                            i=i+16;
                        end
                        if pro.park_t(jk)<=-1.95
                            pro.park_t(jk)=[];
                            pro.park_p(jk)=[];
                            pro.park_s(jk)=[];
                            jk=jk-1;
                            % break
                        end

                    end
                end
                
              % CTD descending profile information - block 0100    
                % now for the observation data:
                
            case 4
                [m,n]=size(bitpro);
                
                for k=jj
                    k=k;
                    
                    j=j+1;
                    pro.profile_desc_samp_date(j)= bin2num(bitpro(k,21:29));
                    ps=pro.profile_desc_samp_date(j);
                    jhold=j;
                    pro.p_desc_raw(j)            = bin2num(bitpro(k,30:40));
                    pro.t_desc_raw(j)            = (bin2num(bitpro(k,41:55))*.001)-2.;
                    pro.s_desc_raw(j)            = (bin2num(bitpro(k,56:70))*.001)+10.;
                    if pro.t_desc_raw(j)<=-1.95
                        pro.p_desc_raw(j)=[];
                        pro.t_desc_raw(j)=[];
                        pro.s_desc_raw(j)=[];
                        j=j-1;
                    end
                    i=71;
                    while i < 224
                        j=j+1;
                        if(bitpro(k,i))
                            pro.p_desc_raw(j) = calc_desc_p(bitpro(k,i+[1:6]),pro.p_desc_raw(j-1));
                            i=i+7;
                        else
                            pro.p_desc_raw(j) = bin2num(bitpro(k,i+[1:11]));
                            i=i+12;
                        end
                        if pro.p_desc_raw(j)==0 & (i+16+16)>256
                            pro.p_desc_raw(j)=[];
                            j=j-1;
                            break
                        end
                        if(bitpro(k,i))
                            pro.t_desc_raw(j)=calc_desc_t(bitpro(k,i+[1:10]),pro.t_desc_raw(j-1));
                            i=i+11;
                        else
                            pro.t_desc_raw(j) = calc_desc_t2(bitpro(k,i+[1:15]));
                            i=i+16;
                        end

                        if(bitpro(k,i))
                            pro.s_desc_raw(j)=calc_desc_s(bitpro(k,i+[1:8]),pro.s_desc_raw(j-1));
                            i=i+9;
                        else
                            pro.s_desc_raw(j) = (bin2num(bitpro(k,i+[1:15]))*.001)+10.;
                            i=i+16;
                        end
                        
                         if pro.t_desc_raw(j)<=-1.95
                            pro.p_desc_raw(j)=[];
                            pro.t_desc_raw(j)=[];
                            pro.s_desc_raw(j)=[];
                            j=j-1;
%                             break
                        end
                   end
                    ll=find(pro.profile_desc_samp_date==ps)
                    if length(ll)==2
                        pro.p_desc_raw(ll(2):end)=[];
                        pro.t_desc_raw(ll(2):end)=[];
                        pro.s_desc_raw(ll(2):end)=[];
                        pro.profile_desc_samp_date(ll(2):end)=[];
                        j=jhold-1;
                    end
                end

    % CTD profile information - block 0110
    % now for the observation data:
                
            case 6
                
                [m,n]=size(bitpro);
                
                for k=jj
                    k=k;
                    
                    j=j+1;
                    pro.profile_samp_date(j) = bin2num(bitpro(k,21:29));
                    pro.p_raw(j)            = bin2num(bitpro(k,30:40));
                    pro.t_raw(j)            = (bin2num(bitpro(k,41:55))*.001)-2.;
                    pro.s_raw(j)            = (bin2num(bitpro(k,56:70))*.001)+10.;
                    if pro.t_raw(j)<=-1.95
                        pro.p_raw(j) = []
                        pro.t_raw(j) = []
                        pro.s_raw(j) = []
                        j=j-1;
                    end
                    i=71;
                    while i < 224
                        j=j+1;
                        if(bitpro(k,i))
                            if j<=1 
                               j=0
                               pro.p_raw = []
                               pro.t_raw = []
                               pro.s_raw = []
                               break; 
                            end 
                            pro.p_raw(j) = calc_p(bitpro(k,i+[1:6]),pro.p_raw(j-1));
                            i=i+7;
                        else
                            pro.p_raw(j) = bin2num(bitpro(k,i+[1:11]));
                            i=i+12;
                        end
                        if pro.p_raw(j)==0 & (i+16+16)>257
                            pro.p_raw(j)=[];
                            j=j-1;
                            break
                        end
                        if(bitpro(k,i))
                            pro.t_raw(j)=calc_t(bitpro(k,i+[1:10]),pro.t_raw(j-1));
                            i=i+11;
                        else
                            pro.t_raw(j) = calc_t2(bitpro(k,i+[1:15]));
                            i=i+16;
                        end
                        
                        if(bitpro(k,i))
                            if i+9<=257 
                            pro.s_raw(j)=calc_s(bitpro(k,i+[1:8]),pro.s_raw(j-1));
                            i=i+9;
                            else 
                             pro.s_raw(j) = 10.0; 
                            end
                        else
                            if i+16<=257 
                            pro.s_raw(j) = (bin2num(bitpro(k,i+[1:15]))*.001)+10.;
                            i=i+16;
                            else 
                            pro.s_raw(j) = 10.0; 
                            end
                        end
                        if pro.t_raw(j)<=-1.95 | pro.s_raw(j) == 10.0 
                            pro.p_raw(j) = []
                            pro.t_raw(j) = []
                            pro.s_raw(j) = []                            
                            j=j-1;
                            %                             break
                        end

                    end
                end
        end %%%switch
    end
 
  [ppp,ib,ic]=unique(pro.p_raw);
  ttt = pro.t_raw(ib);
  sss = pro.s_raw(ib);
  for nn = 1:length(ppp)
      in = find(pro.p_raw == ppp(nn));
      for i = 1:length(in)
          if  pro.t_raw(in(i))~=-2 & pro.t_raw(in(i)) ~= 0 % & pro.t_raw(in(i)) ~= 0
              ttt(nn) = pro.t_raw(in(i));
              sss(nn) = pro.s_raw(in(i));
              break
          end
      end
  end
  pro.p_raw = ppp;
  pro.t_raw = ttt;
  pro.s_raw = sss;
 
        pro.n_asc_samps=length(pro.p_raw);
        [pp,ind]=sort(pro.p_raw,'descend');
        pro.p_raw=pp;
        pro.s_raw=pro.s_raw(ind);
        pro.t_raw=pro.t_raw(ind);
                  
        if isfield(pro,'p_desc_raw')  & ~isempty(pro.p_desc_raw)

  [ppp,ib,ic]=unique(pro.p_desc_raw);
  ttt = pro.t_desc_raw(ib);
  sss = pro.s_desc_raw(ib);
  for nn = 1:length(ppp)
      in = find(pro.p_desc_raw == ppp(nn));
      for i = 1:length(in)
          if  pro.t_desc_raw(in(i))~=-2 & pro.t_desc_raw(in(i)) ~= 0 % & pro.t_desc_raw(in(i)) ~= 0
              ttt(nn) = pro.t_desc_raw(in(i));
              sss(nn) = pro.s_desc_raw(in(i));
              break
          end
      end
  end
  pro.p_desc_raw =  ppp ;
  pro.t_desc_raw =  ttt ;
  pro.s_desc_raw =  sss  ;

            [pp,ind]=sort(pro.p_desc_raw,'descend');
            pro.p_desc_raw=pp;
            pro.s_desc_raw=pro.s_desc_raw(ind);
            pro.t_desc_raw=pro.t_desc_raw(ind);
            %      pro.profile_desc_samp_date=pro.profile_desc_samp_date(ind); %52 57
            kk=find(pro.p_desc_raw==0 & pro.t_desc_raw==0) ;
            if ~isempty(kk)
                %      pro.profile_desc_samp_date(kk)=[];
                pro.p_desc_raw(kk)=[];
                pro.s_desc_raw(kk)=[];
                pro.t_desc_raw(kk)=[];
            end
        end

        fp=pro;

elseif dbdat.subtype==6
        % we need to calculate profile number:
    juld_launch   = julian([str2num(dbdat.launchdate(1:4)) str2num(dbdat.launchdate(5:6)) str2num(dbdat.launchdate(7:8)) ...
         str2num(dbdat.launchdate(9:10)) str2num(dbdat.launchdate(11:12)) str2num(dbdat.launchdate(13:14))]) ;
    juld_now      = julian(pos(1,:));
    pro.profile_number=round((juld_now-juld_launch)/(round(dbdat.parktime+.5)))+1;

    
    
    tbits=[];sbits=[];pbits=[];


    % Construct index for all the bits in a block, for each property
    jt = []; js = []; jp = [];
    for ii = 17:48:256
        jt = [jt ii+(0:15)];
        js = [js (ii+16)+(0:15)];
        jp = [jp (ii+16+16)+(0:15)];
    end
    n_ascentblocks = floor((double(pro.n_asc_samps) - 1)/5);
    for iblk = 3:n_ascentblocks+1
        tbits = [tbits bitpro(iblk,jt)];
        sbits = [sbits bitpro(iblk,js)];
        pbits = [pbits bitpro(iblk,jp)];
    end

    t    = bin2num(tbits,16)*.001 - 5;
    s    = bin2num(sbits,16)*.001 + 25;
    p    = bin2num(pbits,16)*.1;



% These Provor-only fields need to be copied to the equivalent generic
% fields (have kept the Provor-only versions because we did so in the
% past  -jrd)
end

pro.surfpres = pro.pres_offset;
% pro.profile_number = pro.asc_prof_num;
pro.voltage = [];    %pro.fourteenV_batvolt;

pro.profile_samp_date(end+1:length(pro.p_raw))=0;
[pp,ind]=sort(pro.p_raw,'descend');
 pro.p_raw=pp;
 pro.s_raw=pro.s_raw(ind);
 pro.t_raw=pro.t_raw(ind);
 pro.profile_samp_date=pro.profile_samp_date(ind);
 kk=find(pro.p_raw==0 & pro.t_raw==0);
 if ~isempty(kk)
     pro.p_raw(kk)=[];
     pro.s_raw(kk)=[];
     pro.t_raw(kk)=[];
     pro.profile_samp_date(kk)=[];
 end

 fp = pro;

return

end
%--------------------------------------------------------------------
    function p = calc_p(bina,p1)

        bb=bin2num(bina);
%         if bb>bin2dec('011111')
%             bb=bb-bin2dec('111111');
%         end

        p=p1-bb;
   end
 %--------------------------------------------------------------------
    function p = calc_desc_p(bina,p1)

        bb=bin2num(bina);
%         if bb>bin2dec('011111')
%             bb=bb-bin2dec('111111');
%         end

        p=p1+bb;

   end
%--------------------------------------------------------------------
    function p = calc_surf_p(bina)

        bb=bin2num(bina);
        if bb>bin2dec('011111')
            bb=bb-64;
        end

        p=bb;
    end


%--------------------------------------------------------------------
    function s = calc_s(bina,s1)

        bb=bin2num(bina);
%         if bb>bin2dec('01111111')
%             bb=bb-bin2dec('11111111');
%         end

        s=s1+bb*.001-.025;
    end

%--------------------------------------------------------------------
    function t = calc_t(bina,t1)

        bb=bin2num(bina);
%         if bb>bin2dec('0111111111')
%             bb=bb-bin2dec('1111111111');
%         end

        t=t1+(bb*.001-0.1);
    end
%--------------------------------------------------------------------

    function t2 = calc_t2(bina)

        bb=bin2num(bina);
%         if bb>bin2dec('0111111111111111')
%             bb=bb-bin2dec('111111111111111')
%         end
        
        t2=bb*.001-2.;
    end
%--------------------------------------------------------------------
%--------------------------------------------------------------------
    function s = calc_desc_s(bina,s1)

        bb=bin2num(bina);
%         if bb>bin2dec('01111111')
%             bb=bb-bin2dec('11111111');
%         end

        s=s1-(bb*.001-.025);
    end

%--------------------------------------------------------------------
    function t = calc_desc_t(bina,t1)

        bb=bin2num(bina);
%         if bb>bin2dec('0111111111')
%             bb=bb-bin2dec('1111111111');
%         end

        t=t1-(bb*.001-0.1);
    end
%--------------------------------------------------------------------

    function t2 = calc_desc_t2(bina)

        bb=bin2num(bina);
%         if bb>bin2dec('0111111111111111')
%             bb=bb-bin2dec('111111111111111')
%         end
        
        t2=bb*.001-2.;
    end
%--------------------------------------------------------------------


