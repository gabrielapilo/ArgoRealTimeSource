% FLTS: 0528
% function [oxtable] = OCRc4sefloatBGCpHCSIRO(profnum)
% OCRc4ses float data files and saves result in csv for plotting
% Dan Quittman 
% Copyright 2015 Sea-Bird Electronics
% Includes tilt for CSIRO 528

function [oxtable] = bio_navis_parse(floatid, profnum, doPrint)
global ARGO_SYS_PARAM

format long g

% DS: add a common base date
bdate = datenum(1950,01,01, 00,00,00);
% /DS

load(sprintf([ARGO_SYS_PARAM.root_dir 'spreadsheet/biofloat_coeffs/coefs_f%04u.mat'],floatid));
srcfile=sprintf([ARGO_SYS_PARAM.iridium_path '/iridium_processed/5905023/%04d.%03d.msg'],floatid,profnum);

% Read in datafiles
fid = fopen(srcfile, 'r');
if fid < 0
    disp('No file found for bio_navis_parse code')
    oxtable = [];
    return
end

cpendstr='Resm';
cpbegin = 0;
spotbegin = 0;
cpend = 0;
spotend = 0;
line = 1;
%dtable=NaN(1000,16);
dtable=NaN(1000,23);
while ~feof(fid)
    tline = fgetl(fid);
   if(strcmp(tline, '<EOT>'))
      break;
   end % <EOT>
    goodline = 0;
    % scan for 1st temp,salinity,ox line, ignore all else
    if ~isempty(tline)
        if (~isempty(findstr(tline,'(Park Sample)')))
            spotbegin = 1;
            %continue;
        end;
        if strfind(tline,'ser1:')
            cpbegin = 1;
            continue;
        end;
        if strfind(tline,'terminated:')
			darray=sscanf(tline,'$ Profile %*f terminated: %*3c %20c');
			dstr=sprintf('%s',darray);
			dnum=datenum(dstr);        
        end;
        if (~isempty(strfind(tline,cpendstr)))
            cpend = 1;
        end;
        if (~isempty(strfind(tline,'Sbe41cpSerNo')))
            spotend = 1;
            continue; % DS: added
        end;
        if ((cpbegin == 1) && (cpend == 0))
            if (~strncmp(tline,'0000000000000000',10))
                if (csummatch(tline))
                    %Grab bits
                    tn=length(tline);
                    [fmtstr,bits]=bitstofmtstr(tline(tn-3:tn-2),'noswap');
                    rawline=sscanf(tline,fmtstr);                    
                    n=length(rawline);
                    rawline(n+1)=nan;
                    goodline = 1;
                end
            end
            if (goodline == 1)
                dtable(line,1)=hextop(rawline(1));
                dtable(line,2)=hextot(rawline(2));
                dtable(line,3)=hextos(rawline(3));                                                               
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
                if (bits(6)) ecofl=isum+1; isum=isum+1; else ecofl=n+1; end
                if (bits(6)) ecobb=isum+1; isum=isum+1; else ecobb=n+1; end
                if (bits(6)) ecocd=isum+1; isum=isum+1; else ecocd=n+1; end                        
                if (bits(6)) econbin=isum+1; isum=isum+1; else econbin=n+1; end                                        
                if (bits(7)) tilt=isum+1; isum=isum+1; else tilt=n+1; end
                if (bits(7)) tiltsd=isum+1; isum=isum+1; else tiltsd=n+1; end
                if (bits(8)) phv=isum+1; isum=isum+1; else phv=n+1; end
                if (bits(8)) pht=isum+1; isum=isum+1; else pht=n+1; end
                if (bits(8)) phnbin=isum+1; isum=isum+1; else phnbin=n+1; end
                
            
                dtable(line,4)=(rawline(oxph)/100000.0)-10.0;
                dtable(line,5)=(rawline(oxt)/1000000.0)-1.0;
                dtable(line,6)=(rawline(mcfl)-500);
                dtable(line,7)=(rawline(mcbb)-500);
                dtable(line,8)=(rawline(mccd)-500);
                dtable(line,9)=(rawline(ocri1)*1024 + 2013265920); 
                dtable(line,10)=(rawline(ocri2)*1024 + 2013265920);
                dtable(line,11)=(rawline(ocri3)*1024 + 2013265920);
                dtable(line,12)=(rawline(ocri4)*1024 + 2013265920); 
                dtable(line,13)=(rawline(phv)/1000000.0 - 2.5);
                dtable(line,14)=hextot(rawline(pht));                 
                dtable(line,15)=(rawline(tilt)/10.0); 
                dtable(line,16)=(rawline(tiltsd)/100.0);
                
                dtable(line,17)=rawline(4);  % nbins PTS
                dtable(line,18)=rawline(oxnbin);  % nbins O2
                dtable(line,19)=rawline(mcnbin); % nbins MCOMS
                dtable(line,20)=rawline(ocrinbin); % nbins OCR504I
                dtable(line,21)=rawline(phnbin); % nbins pH
               % DS: 0 = discrete values, 1 = profile values
               dtable(line,22) = 1;
               % DS: add date for ease of db
               dtable(line,23) = dnum-bdate;
               %add crover data
               dtable(line,24) = rawline(crv)-200; % C Rover data
               dtable(line,25) = (rawline(crvc)/1000.0)-10.0;
               %add radiance data
                dtable(line,26)=(rawline(ocrr1)*1024 + 2013265920); 
                dtable(line,27)=(rawline(ocrr2)*1024 + 2013265920);
                dtable(line,28)=(rawline(ocrr3)*1024 + 2013265920);
                dtable(line,29)=(rawline(ocrr4)*1024 + 2013265920); 
            end
        end
        if ((spotbegin == 1) && (spotend == 0))
            rawline = sscanf(tline,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
            if (isnan(rawline(1)) == 0)
                goodline = 1;
            end
            if (goodline == 1)
                for i=1:15
                    dtable(line,i)=rawline(i);
                end                           
                %Untransform Radiometer data
                for i=9:12
                    dtable(line,i)=dtable(line,i)*1024+2013265920;
                end                
               % DS: 0 = discrete values, 1 = profile values
               dtable(line,22) = 0; % data type
               % DS: add date for ease of db
               dtable(line,23) = dnum-bdate;
 
            end
        end
    end;
    if (goodline == 1)
        line=line+1;
    end
end
line=line-1;
fclose(fid);

%Parse it
%Column
%1      2      3      4      5      6     7     8   
%Press  Temp   Sal    O2Phs  O2Temp FL    BB    BB2

%9      10     11     12     13     14    15    16
%OCR1   OCR2   OCR3   OCR4   phV    phT   tilt  tiltsdv

%17     18     19      20     21   
%nbPTS  nbO2   nbMCOMS nbOCR  nbpH 
TO2 = optox_tempvolts(dtable(1:line,5),tcf);   % Oxygen sensor temp
TPH = dtable(1:line,14);
phT = TPH;
T90 = dtable(1:line,2);   % CTD temp
T68 = T90 * 1.00024;

Press = dtable(1:line,1);
Salt = dtable(1:line,3);     % CTD salinity (PSU)
PSAL = Salt;
ox = optoxnew([dtable(1:line,4)/39.4570707,TO2],cf);
%ox = optoxnew([dtable(1:line,4)/39.4570707,T90],cf);
phV = dtable(1:line,13);

% Coefficients for transforming ml(NTP)/l to umol/kg
mgml = 1.42903;
umolmg = 1/(31.9988/1e3);
umolml = mgml * umolmg;
salc = optox_salc([TO2,dtable(1:line,3)]);
pcorr = optox_pcorr(TO2,dtable(1:line,1),0.011);
%salc = optox_salc([T90,dtable(1:line,3)]);
%pcorr = optox_pcorr(T90,dtable(1:line,1),0.011);

% ml/l * umol/ml = umol/l. umol/l * l/kg (1/density) = umol/kg
oxmol = ox * umolml ./ (sw_dens(dtable(1:line,3),T68,dtable(1:line,1))/1000);
% mL/L conversion maybe should be done at zero pressure - Winklers are
%oxmol = ox * umolml ./ (sw_dens(dtable(1:line,3),T68,0.0*dtable(1:line,1))/1000);

% Now create matrix of relevant data OXTABLE
%Column
%1            2        3        4        5         6        7
%O2(ml/l unc) O2(ml/l) O2Temp   CTDTemp  CTD Depth CTD Sal  O2(umol/kg)

%8       9    10     11      12      13       14
%FL      BB   BB2    OCRc1   OCRc2   OCRc3    OCRc4   

%15       16       17      18       19       20       21
%FLraw    BBraw    BB2raw  OCRc1raw OCRc2raw OCRc3raw OCRc4raw

%22     23    24       25        26      27       
%phV    phT   pHinsitu pHtot25C  tilt    tiltsdv  

%28         29        30          31        32       33
%nBinsPTS   nBinsO2   nBinsMCOMS  nBinsOCR  nBinspH  O2phase

%34         35      36      37      38      39          40
%Oxyvolts  FSig     BbSig   CdSig   Crover  croverc   rad1
%                   BB700   BB532

%41         42      43      44      
%rad2       rad3    rad4    date

% Compute MCOMS calibrated data using supplied coefs
FLraw=dtable(1:line,6); FL=sf(1)*(FLraw-dc(1));
BBraw=dtable(1:line,7);
%BB=sf(2)*(BBraw-dc(2));
for j=1:length(BBraw)
    [betasw(j), beta90sw(j), bsw(j)] = betasw_ZHH2009(mcomms_wl(2), ...
      T90(j), mcomms_theta, PSAL(j));
end
BB = 2*pi()*mcomms_chi*((BBraw-dc(2))*sf(2) - betasw');
BB2raw=dtable(1:line,8);
%BB2=sf(3)*(BB2raw-dc(3));
for j=1:length(BB2raw)
    [betasw(j), beta90sw(j), bsw(j)] = betasw_ZHH2009(mcomms_wl(3), ...
      T90(j), mcomms_theta, PSAL(j));
end
BB2 = 2*pi()*mcomms_chi*((BB2raw-dc(3))*sf(3) - betasw');

% Compute OCR504 data
OCRc1raw=dtable(1:line,9);  OCRc1abs=imi(1)*a1i(1)*(OCRc1raw-a0i(1));
OCRc1=OCRc1abs-min(OCRc1abs); % zero-offset for later log plots
OCRc2raw=dtable(1:line,10); OCRc2=imi(2)*a1i(2)*(OCRc2raw-a0i(2));
OCRc3raw=dtable(1:line,11); OCRc3=imi(3)*a1i(3)*(OCRc3raw-a0i(3));
OCRc4raw=dtable(1:line,12); OCRc4=imi(4)*a1i(4)*(OCRc4raw-a0i(4));

%
tiltd=dtable(1:line,15); 
tiltsd=dtable(1:line,16); 

% Compute pH using Ken Johnson supplied functions
[phfree,phtot]=phcalc(phV,Press,TPH,Salt,phcf);
% Odd behavior when converting surface values - off by 0.003?
phtot25=labph(phtot,TPH,Press);
oxtable = [ox, ox.*salc.*pcorr, TO2, T90, dtable(1:line,1), dtable(1:line,3), oxmol.*salc.*pcorr,...  
          FL, BB, BB2,          OCRc1,    OCRc2,    OCRc3,    OCRc4,...
          FLraw, BBraw, BB2raw, OCRc1raw, OCRc2raw, OCRc3raw, OCRc4raw,...
          phV, TPH, phtot, phtot25, tiltd, tiltsd,...          
          dtable(1:line,17),dtable(1:line,18),dtable(1:line,19),dtable(1:line,20),dtable(1:line,21),...
          dtable(1:line,4:8),dtable(1:line,24:29)];
ncol = length(oxtable(1,:));
nrow = length(oxtable(:,1));
dvec = ones(nrow,1) * dnum; % Add date column - repeating
oxtable(:,ncol+1) = dvec;
%Write 'em out to 'csv
if(doPrint)
   fid = fopen(sprintf('../csv/%04d.%03d.csv',floatid,profnum),'w');
   fprintf(fid,'%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g\n',oxtable');
   fclose(fid);

% DS: added write rawdata
   fid = fopen(sprintf('../csv/%04d.%03d.rawdata.csv', floatid, profnum), 'w');

   nvars = size(dtable,2);
   rawfmt = '%f';
   for n = [2:nvars]
      rawfmt = sprintf('%s,%%f',rawfmt);
   end % n
   rawfmt = sprintf('%s\\n',rawfmt);
   fprintf(fid,rawfmt,dtable(1:line,:)');
   fclose(fid);
% /DS

   n=length(oxtable(:,1));
   % Processed Data - output CSV, strip Park sample, and sort by pressure
   ptable=sortrows([oxtable(2:n,5),oxtable(2:n,4),oxtable(2:n,6),oxtable(2:n,28),...  % PTS
       oxtable(2:n,8),oxtable(2:n,9),oxtable(2:n,10),oxtable(2:n,30),oxtable(2:n,7),oxtable(2:n,3),oxtable(2:n,29),... % MCOMSO2
      oxtable(2:n,11),oxtable(2:n,12),oxtable(2:n,13),oxtable(2:n,14),oxtable(2:n,31),... % OCR504
      oxtable(2:n,22),oxtable(2:n,23),oxtable(2:n,24),oxtable(2:n,25),oxtable(2:n,32),... % pHVrs,TVolts,pHinsitu,pH25
      oxtable(2:n,26),oxtable(2:n,27), ...  %tilt
      oxtable(2:n,33)-bdate],1);  % date
   fid = fopen(sprintf('../csv/%04d.%03d.export.csv',floatid,profnum),'w');
   fprintf(fid,['Pressure (dbar),Temperature (deg C),Salinity (PSU),nBins PTS,'...
      'CHL (ug/l),BB700 (m-1 sr-1),BB532(m-1 sr-1),nBins MCOMS,'...
      '[O2] (umol/kg),O2 Temp (deg C),nbinsO2,'...
      'OCR504ch1,OCR504ch2,OCR504ch3,OCR504ch4,nBinsOCR504,'...
      'pHVrs (Volts),pHT (degC),pHinsitu,pHtot25C,nbinspH,'...    
      'tilt(deg),tilt StdDev,DateNum\n']);

   fprintf(fid,['%0.1f,%0.4f,%0.3f,%d,'... %PTSn
      '%0.3g,%0.4g,%0.4g,%d,'...         %MCOMS
      '%0.2f,%0.4f,%d,'...               %O2
      '%0.4g,%0.4g,%0.4g,%0.4g,%d,'...   %OCR504
      '%0.6f,%0.3f,%0.3f,%0.3f,%d,'...   %pH
      '%0.1f,%0.1f,%f\n'],ptable');          %tilt % datenum
   fclose(fid);
end % if doPrint
