%   [file]=find_argos_download(wmo_id,pn)
%
%   This function is designed to scan the argos_downloads directory and find
%   the correct argos download to process a given profile from a given float.
%   It works by doing a grep of what it 'guesses' is the right download and
%   then working forward until it sees two successive downloads with the
%   same number of lines for that float. It then uses the second. This
%   might take time but should save in the end. The downside is that a
%   download needs to be present and UNCOMPRESSED before it will work.   AT
%
%   usage:  [file]=find_argos_download(wmo_id,pn)
%       where:    file is the filename returned - can be array if you supply an
%                       array of pn's
%                 wmo_id is the ientifier for a flaot and
%                 pn is the profile number you're after.

function filenm = find_argos_download(wmo_id,pn)

% MODS: 23/9/13 Protect against empty matfiles and other faults. Presently
%               coded for only one pn at a time.  JRD
%       08/06/2016 Include if statement to allow for empty profiles

global ARGO_SYS_PARAM
global   ARGO_ID_CROSSREF THE_ARGO_FLOAT_DB
if isempty(ARGO_SYS_PARAM)
    set_argo_sys_params;
end
if isempty(ARGO_ID_CROSSREF)
    getdbase(0);
end
%warning off all

filenm='NOTFOUND';

argosid = ARGO_ID_CROSSREF(find(ARGO_ID_CROSSREF(:,1)==wmo_id),2);

% [fpp,dbdat]=getargo(wmo_id);
load([ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) '.mat']);
fpp=float;

if pn==length(fpp)+1
    fpp(pn).jday=fpp(pn-1).jday(1)+10;
    
    %  elseif (isempty(fpp(pn).jday));
    %     file='NOTFOUND';
    %     i=0;
    %     while isempty(fpp(pn).jday) & i <= length(fpp)
    %         i=i+1;
    %         fpp(pn).jday=fpp(pn-i).jday+10;
    %     end
    %     return;
end
if isempty(float) %|| isempty(float(pn).jday)
    % No data for this float
    return
end


for ii=1:length(pn)
    found(ii)=0;
    if isempty(fpp(pn(ii)).jday)
        break
    end
    greg=gregorian(fpp(pn(ii)).jday(1));      % median jday could be more robust?? JRD
    dg=datenum(greg);
    d1=datenum(greg(1),1,1);
    if(greg(1)>2007)
        doybck = 2;
        doyfwd = 5;
    else
        % Until start of 2007 the date in the ftp download filename was about 7
        % days prior to the actually download date. That is, file 06_023 would
        % have data from, say, 21 to 30th Jan. So to find a download for a
        % given profile we need to start looking in files with a date 7 days
        % earlier.   JRD
        % This is Ok for the first part, but it wasn't included in the
        % second loop. Update to look from 1 = doy-doybck:doy+doyfwd.
        % RC, June, 2016.
        doybck = 7;
        doyfwd = 6;
    end
    doy=floor(dg-d1)-doybck;
    yy=num2str(greg(1));
    if (doy<1)
        doy=365+doy;
        greg(1)=greg(1)-1;
        yy=num2str(greg(1));
    end
    if (doy>365)                              % Leap years?  JRD
        doy=365-doy;
        greg(1)=greg(1)+1;
        yy=num2str(greg(1));
    end
    i2=0;
    l=[];
    numlines=[];
    st=1;
    numtries=0;
    while st~=0 && numtries<10
        numtries=numtries+1;
        startf= [ARGO_SYS_PARAM.argos_downloads 'argos' yy(3:4) '_' sprintf('%3.3d',doy) '.log'];
        [st,heads]=system(['grep ' num2str(argosid) ' ' startf]);
        if st~=0
            doy=doy+1;
            if (doy<1)
                doy=365+doy;
                yy=num2str(greg(1)-1);
                greg(1)=greg(1)-1;
            end
            if (doy>365)
                doy=1;
                yy=num2str(greg(1)+1);
                greg(1)=greg(1)+1;
            end
            if(numtries>=10)
                ok=0;
                break
            end
        end
        kk=findstr('02039',heads);
        if(isempty(kk))
            ok=0;
        else
            dkk=diff(kk);
            if(isempty(dkk))
                j=kk(1);
            else
                j=kk(find(dkk==max(dkk)));
            end
            if j(1)>1
                heads(1:j(1)-1)=[];
            end
            space=strfind(heads,' ');
            if length(space)>1 && length(heads)>(space(2)+20)
                n1 = str2num(heads(space(2)+[12:15]));
                n2 = str2num(heads(space(2)+[17:18]));
                n3 = str2num(heads(space(2)+[20:21]));
                if ~isempty(n1) && ~isempty(n2) && ~isempty(n3) && n1>1998 && n2<13
                    checkdate = fpp(pn(ii)).jday(1)-julian([n1,n2,n3,1,1,1]);
                    if (abs(checkdate)>100)
                        filenm=startf;
                    elseif(abs(checkdate)>4);
                        doy=floor(doy+checkdate)-3;
                    else
                        filenm=startf;
                    end
                else
                    doy=doy+1;
                    if (doy>365)
                        doy=365-doy;
                        greg(1)=greg(1)+1;
                        yy=num2str(greg(1));
                    end
                end
            end
            y2 = yy;
            for i=doy-doybck:doy+doyfwd
                if(found(ii));break;end
                if i>365
                    i=i-365;
                    y2=num2str(greg(1)+1);
                end
                startf= [ARGO_SYS_PARAM.argos_downloads 'argos' y2(3:4) '_' sprintf('%3.3d',i) '.log'];
                [st2,ftptime]=system(['grep UTC ' startf]);
                if isempty(ftptime) || isempty(strmatch('UTC',ftptime))
                    ftpdate=dg+2;
                else
                    ftpdate=datenum([str2num(ftptime(11:14)),str2num(ftptime(8:9)),str2num(ftptime(5:6)),str2num(ftptime(16:17)),str2num(ftptime(19:20)),0]);
                end
                if((ftpdate-dg)<ARGO_SYS_PARAM.run_time)
                    
                    
                else
                    [st,heads]=system(['grep ' num2str(argosid) ' ' startf]);
                    if(st==0)
                        kk=findstr('02039',heads);
                        dkk=diff(kk);
                        if(isempty(dkk))
                            j=kk(1);
                        else
                            j=kk(find(dkk==max(dkk)));
                        end
                        if(j(1)>1)
                            heads(1:j(1)-1)=[];
                        end
                        space=strfind(heads,' ');
                        if length(space)>1 && length(heads)>(space(2)+20)
                            checkdate=fpp(pn(ii)).jday(1)-julian([str2num(heads(space(2)+[12:15])),str2num(heads(space(2)+[17:18])),...
                                str2num(heads(space(2)+[20:21])),1,1,1]);
                            if abs(checkdate)<4
                                i2=i2+1;
                                numlines(i2)=length(kk);
                                stf(i2,:)=startf;
                                if(i2>=2 & numlines(i2)>=numlines(i2-1))
                                    filenm=startf;
                                    found(ii)=1;
                                    break
                                end
                                
                            end
                        end
                    end
                end
            end
        end
    end
end


return
