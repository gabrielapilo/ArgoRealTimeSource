% FLTS: 0392, 0393
% function [oxtable] = DS_parsefloatBOSS(floatid, profnum, doPrint)
% Parses float data files and saves result in csv for plotting
% Dan Quittman 
% Copyright 2014 Sea-Bird Electronics
%
% LAST UPDATE:
%  05/08/15: DS: modified for local local bioARGO use
%
% DS: note: no need to check for implied compressesion as only zero data is
% duplicated that way.
% RC: adapt to RT processing, pass in profile and add bio information, pass
% back the profile.

function [pro] = DS_parsefloatBOSS(floatid, profnum, doPrint,pro)
global ARGO_SYS_PARAM

format long g

% DS: add a common base date
bdate = datenum(1950,01,01, 00,00,00);
% /DS

load(sprintf([ARGO_SYS_PARAM.root_dir 'spreadsheet/biofloat_coeffs/coefs_f%04u.mat'],floatid));
srcfile=sprintf([ARGO_SYS_PARAM.iridium_path '/iridium_processed/' num2str(pro.wmo_id) '/%04d.%03d.msg'],floatid,profnum);

% Read in datafiles
fid = fopen(srcfile, 'r');
cpendstr='Resm';
cpbegin = 0;
spotbegin = 0;
cpend = 0;
spotend = 0;
line = 1;
dtable=NaN(1000,28);
while ~feof(fid)
    tline = fgetl(fid);
    goodline = 0;
    % scan for 1st temp,salinity,ox line, ignore all else
    if ~isempty(tline)
        if (~isempty(findstr(tline,'(Park Sample)')))
            spotbegin = 1;
            %continue;
        end;
        if strfind(tline,'ser1:')
            % time to read hex data starting on next line
            cpbegin = 1;
            continue;
        end;
        if strfind(tline,'terminated:')
			   darray=sscanf(tline,'$ Profile %*f terminated: %*3c %20c');
			   dstr=sprintf('%s',darray);
			   dnum=datenum(dstr);        
        end;
        if (~isempty(strfind(tline,cpendstr)) | ~isempty(strfind(tline,'<EOT>')))
            % no more hex data to be read
            cpend = 1;
            continue; % DS: added
        end;
        if (~isempty(strfind(tline,'Sbe41cpSerNo')))
            % no more discrete data to be read
            spotend = 1;
            continue; % DS: added
        end;
        if ((cpbegin == 1) && (cpend == 0))
            %rawline = sscanf(tline,'%04x%04x%04x%02x%06x%06x%02x%06x%06x%06x%02x');            
            if (~strncmp(tline,'0000000000000000',10))
%ds_disp(tline)
                if (csummatch(tline))
                    %Grab bits
                    tn=length(tline);
                    [fmtstr,bits]=bitstofmtstr(tline(tn-3:tn-2));
                    rawline=sscanf(tline,fmtstr);                    
                    n=length(rawline);
                    rawline(n+1)=nan;
                    goodline = 1;
                end
            end
            if (goodline == 1)
                dtable(line,1)=hextop(rawline(1)); % P
                dtable(line,2)=hextot(rawline(2)); % T
                dtable(line,3)=hextos(rawline(3)); % S                                                           
                isum = 4;
                if (bits(1)) oxph=isum+1; isum=isum+1; else oxph=n+1; end
                if (bits(1)) oxt=isum+1; isum=isum+1; else oxt=n+1; end
                if (bits(1)) oxnbin=isum+1; isum=isum+1; else oxnbin=n+1; end
                if (bits(2)) mcfl=isum+1; isum=isum+1; else mcfl=n+1; end
                if (bits(2)) mcbb=isum+1; isum=isum+1; else mcbb=n+1; end
                if (bits(2)) mccd=isum+1; isum=isum+1; else mccd=n+1; end
                if (bits(2)) mcnbin=isum+1; isum=isum+1; else mcnbin=n+1; end
                if (bits(3)) crv=isum+1; isum=isum+1; else crv=n+1; end
                if (bits(3)) crvc=isum+1; isum=isum+1; else crvc=n+1; end
                if (bits(3)) crvnbin=isum+1; isum=isum+1; else crvnbin=n+1; end
                if (bits(4)) ocri1=isum+1; isum=isum+1; else ocri1=n+1; end
                if (bits(4)) ocri2=isum+1; isum=isum+1; else ocri2=n+1; end
                if (bits(4)) ocri3=isum+1; isum=isum+1; else ocri3=n+1; end
                if (bits(4)) ocri4=isum+1; isum=isum+1; else ocri4=n+1; end
                if (bits(4)) ocrinbin=isum+1; isum=isum+1; else ocrinbin=n+1; end
                if (bits(5)) ocrr1=isum+1; isum=isum+1; else ocrr1=n+1; end
                if (bits(5)) ocrr2=isum+1; isum=isum+1; else ocrr2=n+1; end
                if (bits(5)) ocrr3=isum+1; isum=isum+1; else ocrr3=n+1; end
                if (bits(5)) ocrr4=isum+1; isum=isum+1; else ocrr4=n+1; end
                if (bits(5)) ocrrnbin=isum+1; isum=isum+1; else ocrrnbin=n+1; end
                if (bits(6)) ecobb1=isum+1; isum=isum+1; else ecobb1=n+1; end
                if (bits(6)) ecobb2=isum+1; isum=isum+1; else ecobb2=n+1; end
                if (bits(6)) ecobb3=isum+1; isum=isum+1; else ecobb3=n+1; end                        
                if (bits(6)) econbin=isum+1; isum=isum+1; else econbin=n+1; end                        
            
                dtable(line,4)=(rawline(oxph)/100000.0)-10.0; % O2 Phase
                dtable(line,5)=(rawline(oxt)/1000000.0)-1.0; % O2 Volts
                dtable(line,6)=(rawline(mcfl)-500); % FL
                dtable(line,7)=(rawline(mcbb)-500); % BB700
                dtable(line,8)=(rawline(mccd)-500); % CDOM
                dtable(line,9)=(rawline(ocri1)*1024 + 2013265920); % ED412
                dtable(line,10)=(rawline(ocri2)*1024 + 2013265920); % ED443
                dtable(line,11)=(rawline(ocri3)*1024 + 2013265920); % ED490
                dtable(line,12)=(rawline(ocri4)*1024 + 2013265920); % ED555
                dtable(line,13)=(rawline(ocrr1)*1024 + 2013265920); % LU412
                dtable(line,14)=(rawline(ocrr2)*1024 + 2013265920); % LU443
                dtable(line,15)=(rawline(ocrr3)*1024 + 2013265920); % LU490
                dtable(line,16)=(rawline(ocrr4)*1024 + 2013265920); % LU555
                dtable(line,17)=(rawline(ecobb1)-500); % BB470
                dtable(line,18)=(rawline(ecobb2)-500); % BB532
                dtable(line,19)=(rawline(ecobb3)-500); % BB700
                dtable(line,20)=(rawline(crv)-200); % % CP650 counts
                dtable(line,21)=(rawline(crvc)/1000.0)-10.0; % CP650 ???
                dtable(line,22)=rawline(4);  % nbins PTS
                dtable(line,23)=rawline(oxnbin);  % nbins O2
                dtable(line,24)=rawline(mcnbin); % nbins MCOMS
                dtable(line,25)=rawline(econbin); % nbins ECO
                dtable(line,26)=rawline(ocrinbin); % nbins OCR504I
                dtable(line,27)=rawline(ocrrnbin); % nbins OCR504R
                dtable(line,28)=rawline(crvnbin); % nbins CRV2K
               % DS: 0 = discrete values, 1 = profile values
               dtable(line,29) = 1;
               % DS: add date for ease of db
               dtable(line,30) = dnum-bdate;
            end
        end
        if ((spotbegin == 1) && (spotend == 0))
            % read discrete data
            rawline = sscanf(tline,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
            if (isnan(rawline(1)) == 0)
                goodline = 1;
            end
            if (goodline == 1)
                for i=1:19
                    dtable(line,i)=rawline(i);
                end                
                %Untransform Radiometer data
                for i=9:16
                    dtable(line,i)=dtable(line,i)*1024+2013265920;
                end                
               % DS: 0 = discrete values, 1 = profile values
               dtable(line,29) = 0; % data type
               % DS: add date for ease of db
               dtable(line,30) = dnum-bdate;
            end
        end
    end;
    if (goodline == 1)
        line=line+1;
    end
end
line=line-1;
fclose(fid);

% DS: remember to sort on depth before use

%Parse it
%Column
%1           2        3        4        5      6   7   8 
%Pressure    Temp(C)  Salinity O2Phase  O2Temp Fl  Bb  Cd 

%9    10   11   12   13   14    15   16   17    18    19
%Irr1 Irr2 Irr3 Irr4 Rad1 Rad2  Rad3 Rad4 EcBB1 EcBB2 EcBB3

%20      21
%CRVcnts CRVBeamC

%22      23      24        25      26       27       28
%nbinPTS nbinO2  nbinMCOMS nbinECO nbinOCRI nbinOCRR nbinCRV

TO2 = optox_tempvolts(dtable(1:line,5),tcf);   % Oxygen sensor temp
T90 = dtable(1:line,2);   % CTD temp
PSAL = dtable(1:line,3); % CTD Salt
ox = optoxnew([dtable(1:line,4)/39.4570707,TO2],cf);
%ox = optoxnew([dtable(1:line,4)/39.4570707,T90],cf);

% Coefficients for transforming ml(NTP)/l to umol/kg
mgml = 1.42903;
umolmg = 1/(31.9988/1e3);
umolml = mgml * umolmg;
salc = optox_salc([TO2,dtable(1:line,3)]);
pcorr = optox_pcorr(TO2,dtable(1:line,1),0.011);
%salc = optox_salc([T90,dtable(1:line,3)]);
%pcorr = optox_pcorr(T90,dtable(1:line,1),0.011);

% ml/l * umol/ml = umol/l. umol/l * l/kg (1/density) = umol/kg
oxmol = ox * umolml ./ (sw_dens(dtable(1:line,3),T90,dtable(1:line,1))/1000);
% Now create matrix of relevant data
%Column
%1            2        3        4        5         6        7
%O2(ml/l unc) O2(ml/l) O2Temp   CTDTemp  CTD Depth CTD Sal  02(umol/kg)

%8        9        10        11       12       13       
%FL       BB       CD        ECOBB1   ECOBB2   ECOBB3

%14       15       16        17       18       19      20      21
%Ed412    Ed444    Ed490     Ed555    LU412    LU444   LU490   LU555

%22       23       24        25       26       27       
%FLraw    BBraw    CDraw     ECOBB1raw ECOBB2raw ECOBB3raw    

%28       29        30       31       32       33       34       35       
%Ed412raw Ed444raw  Ed490raw Ed555raw LU412raw LU444raw LU490raw LU555raw 

%36       37  
%CRVcnts  CRVBeamC

%38       39       40        41       42       43       44       45
%nBinPTS  nBinO2   nBinMCOMS nBinECO  nBinOCRI nBinOCRR nBinCRV  Date

% Compute MCOMS calibrated data using supplied coefs
FLraw=dtable(1:line,6); FL=sf(1)*(FLraw-dc(1));
% DS: added *2*pi*chi as Dan's calc just provides beta.
BBraw=dtable(1:line,7);
% DS: added *2*pi*chi as Dan's calc just provides beta.
for j=1:length(BBraw)
    [betasw(j), beta90sw(j), bsw(j)] = betasw_ZHH2009(mcomms_wl(2), ...
      T90(j), mcomms_theta, PSAL(j));
end
%BB=sf(2)*(BBraw-dc(2))*pi()*chi;
BB = 2*pi()*mcomms_chi*((BBraw-dc(2))*sf(2) - betasw');
CDraw=dtable(1:line,8); CD=sf(3)*(CDraw-dc(3));

% Compute ECO calibrated data using supplied coefs
% DS: added *2*pi*chi as Dan's calc just provides beta.
ECOBB1raw=dtable(1:line,17);
%ECOBB1=ecosf(1)*(ECOBB1raw-ecodc(1))*2*pi()*ecochi;
clear betasw;
clear beta90sw;
clear bsw
for j=1:length(ECOBB1raw)
    [betasw(j), beta90sw(j), bsw(j)] = betasw_ZHH2009(eco_wl(1), ...
      T90(j), mcomms_theta, PSAL(j));
end
ECOBB1 = 2*pi()*eco_chi*((ECOBB1raw-ecodc(1))*ecosf(1) - betasw');
ECOBB2raw=dtable(1:line,18);
%ECOBB2=ecosf(2)*(ECOBB2raw-ecodc(2))*2*pi()*ecochi;
for j=1:length(ECOBB2raw)
    [betasw(j), beta90sw(j), bsw(j)] = betasw_ZHH2009(eco_wl(2), ...
      T90(j), mcomms_theta, PSAL(j));
end
ECOBB2 = 2*pi()*eco_chi*((ECOBB2raw-ecodc(2))*ecosf(2) - betasw');
ECOBB3raw=dtable(1:line,19);
%ECOBB3=ecosf(3)*(ECOBB3raw-ecodc(3))*2*pi()*ecochi;
for j=1:length(ECOBB2raw)
    [betasw(j), beta90sw(j), bsw(j)] = betasw_ZHH2009(eco_wl(3), ...
      T90(j), mcomms_theta, PSAL(j));
end
ECOBB3 = 2*pi()*eco_chi*((ECOBB3raw-ecodc(3))*ecosf(3) - betasw');


% Compute OCR504I values using supplied coefs
% zero-offset for later log plots
Ed412raw=dtable(1:line,9);  Ed412abs=imi(1)*a1i(1)*(Ed412raw-a0i(1));Ed412=Ed412abs-min(Ed412abs); 
Ed444raw=dtable(1:line,10);  Ed444abs=imi(2)*a1i(2)*(Ed444raw-a0i(2));Ed444=Ed444abs-min(Ed444abs); 
Ed490raw=dtable(1:line,11);  Ed490abs=imi(3)*a1i(3)*(Ed490raw-a0i(3));Ed490=Ed490abs-min(Ed490abs); 
Ed555raw=dtable(1:line,12);  Ed555abs=imi(4)*a1i(4)*(Ed555raw-a0i(4));Ed555=Ed555abs-min(Ed555abs); 
%Ed412raw=dtable(1:line,9);  Ed412=imi(1)*a1i(1)*(Ed412raw-a0i(1));
%myEdi = DS_transformOCR(...
%   [dtable(1:line,9) dtable(1:line,10) dtable(1:line,11) dtable(1:line,12)], ...
%   imi,  ...
%   a0i,  ...
%   a1i, ...
%   false);

% Compute OCR504R values using supplied coefs
%LU412raw=dtable(1:line,13);  LU412abs=imr(1)*a1r(1)*(LU412raw-a0r(1));
% DS: [2015-09-03] Dan had use the **i coeffs below instead of the **r ones, a
%     simple copy-paste typo
LU412raw=dtable(1:line,13);  LU412abs=imr(1)*a1r(1)*(LU412raw-a0r(1));LU412=LU412abs-min(LU412abs); 
LU444raw=dtable(1:line,14);  LU444abs=imr(2)*a1r(2)*(LU444raw-a0r(2));LU444=LU444abs-min(LU444abs); 
LU490raw=dtable(1:line,15);  LU490abs=imr(3)*a1r(3)*(LU490raw-a0r(3));LU490=LU490abs-min(LU490abs); 
LU555raw=dtable(1:line,16);  LU555abs=imr(4)*a1r(4)*(LU555raw-a0r(4));LU555=LU555abs-min(LU555abs); 
%myEdr = DS_transformOCR(...
%   [dtable(1:line,13) dtable(1:line,14) dtable(1:line,15) dtable(1:line,16)], ...
%   imr,  ...
%   a0r,  ...
%   a1r, ...
%   false);

CRVcnts=dtable(1:line,20);
CRVbeamC=dtable(1:line,21);

oxtable = [ox, ox.*salc.*pcorr, TO2, T90, dtable(1:line,1), dtable(1:line,3), oxmol.*salc.*pcorr, ...
           FL,       BB,       CD,       ECOBB1,    ECOBB2,    ECOBB3, ...
           Ed412,    Ed444,    Ed490,    Ed555,    LU412,    LU444,    LU490,    LU555, ...
           FLraw,    BBraw,    CDraw,    ECOBB1raw, ECOBB2raw, ECOBB3raw, ...
           Ed412raw, Ed444raw, Ed490raw, Ed555raw, LU412raw, LU444raw, LU490raw, LU555raw, ...
           CRVcnts,  CRVbeamC, ...
           dtable(1:line,22),dtable(1:line,23),dtable(1:line,24), ...
           dtable(1:line,25),dtable(1:line,26),dtable(1:line,27),dtable(1:line,28)];
ncol = length(oxtable(1,:));
nrow = length(oxtable(:,1));
dvec = ones(nrow,1) * dnum; % Add date column - repeating
oxtable(:,ncol+1) = dvec;
%Write 'em out to 'csv
if(doPrint)
   fid = fopen(sprintf('../csv/%04d.%03d.csv',floatid,profnum),'w');
   fprintf(fid,'%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',oxtable');
   fclose (fid);

% DS: added write rawdata
   fid = fopen(sprintf('../csv/%04d.%03d.rawdata.csv', floatid, profnum), 'w');

   nvals = size(dtable,2);
   rawfmt = '%f';
   for n = [2:nvals]
      rawfmt = sprintf('%s,%%f',rawfmt);
   end % n 
   rawfmt = sprintf('%s\\n',rawfmt);
   %fprintf(fid,'%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n', dtable(1:line,:)');
   %fprintf(fid,'%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',dtable(1:line,:)');
   fprintf(fid,rawfmt,dtable(1:line,:)');
   fclose(fid);
% /DS

   % Processed Data - output CSV, strip park sample, and sort by pressure
   n=length(oxtable(:,1));
   ptable=sortrows([oxtable(2:n,5) oxtable(2:n,4) oxtable(2:n,6) oxtable(2:n,38),...       % PTS
    oxtable(2:n,8) oxtable(2:n,9) oxtable(2:n,10) oxtable(2:n,40),...                   % MCOMS
    oxtable(2:n,11) oxtable(2:n,12) oxtable(2:n,13) oxtable(2:n,41),...                 % ECO
    oxtable(2:n,7) oxtable(2:n,39),...                                                  % O2
    oxtable(2:n,14) oxtable(2:n,15) oxtable(2:n,16) oxtable(2:n,17) oxtable(2:n,42),... % OCRI
    oxtable(2:n,18) oxtable(2:n,19) oxtable(2:n,20) oxtable(2:n,21) oxtable(2:n,43),... % OCRR
    oxtable(2:n,36), oxtable(2:n,37), oxtable(2:n,44),...                                 % CRV
    oxtable(2:n,45)-bdate],1);                                                                % Date
   fid = fopen(sprintf('../csv/%04d.%03d.export.csv',floatid,profnum),'w');
   fprintf(fid,['Pressure (dbar),Temperature (deg C),Salinity (PSU),nBins PTS,'...
    'MCOMS CHL (ug/l), MCOMS Bb700 (m-1 sr-1),MCOMS CDOM (ppb QSDE),nBins MCOMS,'...
    'ECO BB470 (m-1 sr-1), ECO BB530 (m-1 sr-1),ECO BB700 (m-1 sr-1),nBins ECO,'...
    'DOxygen (umol/kg),nBins O2,'...
    'Ed412, Ed444, Ed490, Ed555, nBins OCR504I,LU412, LU444, LU490, LU555,nBins OCR504R,'...
    'CRV2K counts, CRV Beam C, nBins CRV2K,'...
    'DateNum\n']);
   fprintf(fid,'%0.1f,%0.3f,%0.3f,%d,%0.5g,%0.5g,%0.5g,%d,%0.5g,%0.5g,%0.5g,%d,%0.2f,%d,%0.5g,%0.5g,%0.5g,%0.5g,%d,%0.5g,%0.5g,%0.5g,%0.5g,%d,%d,%0.6g,%d,%f\n',ptable');
   fclose(fid);
end
