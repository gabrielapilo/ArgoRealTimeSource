% WRITE_TESAC  Generate an ASCII file containing a TESAC message for one
%     profile.
%
% INPUT: dbdat - database recrod for this float
%        fp    - profile structure 
%
% OUTPUT to file  R{wmo_id}_{prof_num}.tesac
%
% CALLED BY: process_profile
%
% Jeff Dunn CMAR/BoM Aug 2006
%
% USAGE: write_tesac(dbdat,fp)

function write_tesac(dbdat,fp)

global ARGO_SYS_PARAM

if(isnan(fp.lat(1))) | strcmp('evil',dbdat.status) | strcmp('hold',dbdat.status)
    return
end

% Get the profile measurements passed by the QC process
ss = qc_apply(fp.s_calibrate,fp.s_qc);
tt = qc_apply(fp.t_raw,fp.t_qc);
pp = qc_apply(fp.p_calibrate,fp.p_qc);

if all(isnan(pp) | (isnan(ss) & isnan(tt)))
    logerr(3,['WRITE_TESAC: No useful values in profile ' ...
        num2str([fp.wmo_id fp.profile_number]) ', so no TESAC generated.']);
    return
end
pnum = fp.profile_number;
pno=sprintf('%3.3i',pnum);

if ispc
    fnm = [ARGO_SYS_PARAM.root_dir 'tesac\R' int2str(fp.wmo_id) '_' ...
        pno '.tesac'];
    floatdirnm = [ARGO_SYS_PARAM.root_dir 'textfiles\' int2str(fp.wmo_id) '\' ];
    if strmatch(ARGO_SYS_PARAM.datacentre,'KO');
        KMAtesacdir = [ARGO_SYS_PARAM.root_dir 'tesac_kma\' ];
    end
else
    fnm = [ARGO_SYS_PARAM.root_dir 'tesac/R' int2str(fp.wmo_id) '_' ...
        pno '.tesac'];
    floatdirnm = [ARGO_SYS_PARAM.root_dir 'textfiles/' int2str(fp.wmo_id) '/' ];
    if strmatch(ARGO_SYS_PARAM.datacentre,'KO');
        KMAtesacdir = [ARGO_SYS_PARAM.root_dir 'tesac_kma/' ];
    end
end

fid = fopen(fnm,'w');
if fid<1
    logerr(1,['WRITE_TESAC: Could not open file ' fnm]);
    return
end

% Section 1 - Time and position. Time must be of first fix, not ascent_end
% (so that it matches the position.)

% changed to use ascent end in accordance with new rules and definitions: 
%  AT  Nov 2010

% datvec = fp.datetime_vec(1,:);
%find the first occurrence of a good position
order = [1,2,0,5,8];
[~,ia,~] = intersect(fp.pos_qc,order);

datvec = gregorian(fp.jday_ascent_end);
if(isempty(datvec));datvec = fp.datetime_vec(ia,:);end
yrdig = rem(datvec(1),10);  % last digit of year

if fp.lon(ia)>0 & fp.lon(ia)<=180
    if fp.lat(ia)>0
        hflg = '1';
    else
        hflg = '3';
    end
else
    if fp.lon(ia)>180; fp.lon(ia) = 360-fp.lon(ia); end
    if fp.lon(ia)<0;   fp.lon(ia) = abs(fp.lon(ia)); end
    if fp.lat(ia)>0
        hflg = '7';
    else
        hflg = '5';
    end
end
lon=fp.lon(ia);
if (dbdat.iridium) %add iridium tesac generation here..

    fprintf(fid,'SOF');

    % now for the A2 code
    lat=fp.lat(ia);
    lon=fp.lon(ia);
    if lon>180 & lon<=360; lon=-(360-lon); end

    if lat<-60
        code='J';
    elseif lon>=-35 && lon<=70 && lat>=-60 && lat<=30
        code='A';
    elseif lon>=70 && lon <= 180 && lat>=5 && lat<90
        code='B';
    elseif lon>=-120 && lon<=-35 && lat>=-60 && lat<=5
        code='C';
    elseif lon>-180 && lon<=-35 && lat>=5 && lat<90
        code='D';
    elseif ((lon>=70 && lon<=180) || (lon>=-180 && lon<=-120)) && lat>=-60 && lat<=5
        code='E';
    elseif ((lon>0 && lon<=70) || (lon>=-35 && lon<0)) && lat>=30 && lat<=90
        code='F';
    else
        code='J';                              %J
    end
    fprintf(fid,'%s',code);

    % the ii code and CCCC, note space is for the space before the time
    fprintf(fid,'02 AMMC ');

    % YYGGgg
    %     c=fix(clock);
if ispc
%     dn=datestr(now,31);  % or use dn=datestr(datenum(now-(8/24),31)) (adjust for utc time difference)
    dstring=datestr(datenum(now-(8/24),31));%'2016-07-15 09:15:55'
    dstatus=0
else
    [dstatus,dstring]=system(['date -u']);
end
%     fprintf(fid,'%2.2d%2.2d%2.2d',str2num(dstring(10:11)),str2num(dstring(13:14)),str2num(dstring(16:17)));
    fprintf(fid,'%2.2d%2.2d%2.2d',str2num(dstring(9:10)),str2num(dstring(12:13)),str2num(dstring(15:16)));

    % now for the RRA, RRB, RRC business
    % make a time integer not just a string
%     cur_time=str2num(sprintf('%2.2d%2.2d%2.2d',str2num(dstring(10:11)),st
%     r2num(dstring(13:14)),str2num(dstring(16:17))));
   cur_time=str2num(sprintf('%2.2d%2.2d%2.2d',str2num(dstring(9:10)),str2num(dstring(12:13)),str2num(dstring(15:16))));
    % if to check for the current time vs the send_time flag
    if ARGO_SYS_PARAM.send_time == cur_time
        % up the send_char character
        ARGO_SYS_PARAM.send_char=ARGO_SYS_PARAM.send_char+1;
        if ARGO_SYS_PARAM.send_char>88
            ARGO_SYS_PARAM.send_char=88;
        end
    else
        % re initialise the send_char param and reset the send_time
        ARGO_SYS_PARAM.send_char=64;
        ARGO_SYS_PARAM.send_time = cur_time;
    end
    % print the RRA
    if ARGO_SYS_PARAM.send_char>64
        fprintf(fid,' RR%s\n',char(ARGO_SYS_PARAM.send_char));
    else
        fprintf(fid,'\n');
    end
else
    fprintf(fid,'ZCZC\n');

end

fprintf(fid,'KKYY %0.2d%0.2d%0.1d %0.2d%0.2d/ %c%0.5d %0.6d\n',datvec([3 2]),...
    yrdig,datvec([4 5]),hflg,round(abs(fp.lat(ia))*1000),round(abs(lon)*1000));

% Section 2   - profile data
% Preceded by '888<k1><k2> IIIXX ' where:
%   <k1>  (table 2262)  7=standard depths  8=inflexion points
%   <k2>  (table 2263)  Salinity sensor accuray  2= <.02 PSU
%   III   Instrument (table 1770)
%   XX    Recorder  (table 4770)   60=Argos, Upcast  64=Iridium, Upcast

k1k2 = '72';
if (dbdat.iridium)
    XX = '64';
else
    XX = '60';
end

if dbdat.wmo_inst_type=='864'
    
fprintf(fid,'888%s %s%s ',k1k2,'999',XX);

else
    fprintf(fid,'888%s %s%s ',k1k2,dbdat.wmo_inst_type,XX);
end

% T,S written as 1/100th C or PSU, depth as metres. 3 sets of values per line
% We loop, accumulating an output string 'ostr', writing it to file when we
% have the required 3 sets of values.

if any(tt<0)
    % -ve T handled by adding 50 (would be +5000 after scaling)
    ij = find(tt<0);
    tt(ij) = abs(tt(ij)) + 50;
end
tt = round(tt*100);
ss = round(ss*100);
dd = round(sw_dpth(pp,fp.lat(1)));

ii = 1;
ostr = '';

if dbdat.iridium
    gtest=find(dd>=300);
    if (gtest>0)
        dind=gtest(1:2:end);
        d=gtest(end)+1:length(dd);
        dind(length(dind)+1:length(dind)+length(d))=d;
    else
        dind=1:length(dd);
    end
else
    dind=1:length(dd);
end

for ll = length(dind):-1:1
    kk=dind(ll);
    % if all data NaNs, skip triplet completely!    9/4/08
    if ~isnan(dd(kk)) & (~isnan(tt(kk)) | ~isnan(ss(kk)))
        if isnan(dd(kk))
            ostr = [ostr '2//// '];
        else
            ostr = [ostr num2str(dd(kk),'2%0.4d') ' '];
        end
        if isnan(tt(kk))
            ostr = [ostr '3//// '];
        else
            ostr = [ostr num2str(tt(kk),'3%0.4d') ' '];
        end
        if isnan(ss(kk))
            ostr = [ostr '4//// '];
        else
            ostr = [ostr num2str(ss(kk),'4%0.4d') ' '];
        end
        if ii==3
            fprintf(fid,'%s\n',ostr);
            ostr = '';
            ii = 1;
        else
            ii = ii+1;
        end
    else
        logerr(3,['WRITE_TESAC: Missing triplet ' ...
            num2str([fp.wmo_id fp.profile_number kk]) ', Gap removed from TESAC.']);
    end
end
% Write any last values (an incomplete line)
if ~isempty(ostr)
    fprintf(fid,'%s\n',ostr);
end

% Sections 3,4 - not used


% Section 5
% Finish with WMO ID and 'NNNN'. The earliest WMO IDs are preficed by '99999'
% and later ones by 'Q'

wstr = num2str(fp.wmo_id);
if length(wstr)==5
    fprintf(fid,'99999%s=',wstr);
    if (~dbdat.iridium); fprintf(fid,'\nNNNN',wstr); end
else
    fprintf(fid,'Q%s=',wstr);
    if (~dbdat.iridium); fprintf(fid,'\nNNNN\n',wstr); end
end

fclose(fid);

%try
%   system(['cp ' fnm ' ' floatdirnm]);
%catch
%   system(['mkdir ' floatdirnm]);
%   system(['cp ' fnm ' ' floatdirnm]);
%end

if ~exist(floatdirnm)
    system(['mkdir ' floatdirnm]);
end
system(['cp ' fnm ' ' floatdirnm]);

if strmatch(ARGO_SYS_PARAM.datacentre,'KO');
    system(['cp ' fnm ' ' KMAtesacdir]);    
end

%----------------------------------------------------------------------------
