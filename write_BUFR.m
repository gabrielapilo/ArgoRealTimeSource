% WRITE_BUFR.m  	create bufr tesac messages and forward them to the exportBUFR
%				directory
%
% INPUT 
%  dbdat - master database record for this float
%  fp   - float struct array containing ONLY the profiles to be added.
%
% OUTPUT 
%  .bin file for transfer to CMSS, also backed up to textfiles 
%
% Author:  Chris Down CSIRO/BoM  Oct 2009
%
%  Devolved from matlabnetcdf scripts (Ann Thresher ?)
% 
% CALLS:  ArgoNetCDFp2BUFR_v2.pl perl script
%
% USAGE: write_BUFR(dbdat,fp)
%

function [outcome] = write_BUFR(dbdat,fp)

global ARGO_SYS_PARAM
outcome = 0;

%position information
%find the first occurrence of a good position
order = [1,2,0,5,8,9];
[~,ia,~] = intersect(fp.pos_qc,order);

if(fp.pos_qc(ia(1)) == 9) | strcmp('evil',dbdat.status) | strcmp('hold',dbdat.status)
    return
end

nin = length(fp);

ndir = [ARGO_SYS_PARAM.root_dir 'netcdf/' int2str(dbdat.wmo_id)];
if ~exist(ndir,'dir')
   [st,ww] = system(['mkdir ' ndir]);
   if st~=0
      logerr(2,['Failed creating new directory ' ndir]);
      return
   end
end

if nin==1
   pnum = fp.profile_number;
   pno=sprintf('%3.3i',pnum);
   fname = [ndir '/R' int2str(dbdat.wmo_id) '_' pno '.nc'];
   biofname=[];
   if dbdat.oxy
    biofname = [ndir '/BR' int2str(dbdat.wmo_id) '_' pno '.nc'];
   end
else
   fname = [ndir '/' int2str(dbdat.wmo_id) '_prof.nc'];
end



% system call to the ArgoNetCDFp2BUFR_v2.pl perl script for making BUFR files
% command: perl ArgoNetCDFp2BUFR_v2.pl outfile                  infile
%									    fname   '/R' int2str(dbdat.wmo_id) '_' pno '.nc'

% build outfile - T_IOPx01_C_AMMC_YYYYMMDDHHMMSS_R5901111_016.bufr
outstr=['T_IOP'];

% long and lat position to letter code
lat=fp.lat(ia(1));
lon=fp.lon(ia(1));
if lon>180 & lon<=360; lon=-(360-lon); end

if lat >= 0
	if lon<=0 & lon>-90; code='A'; end  	% A
	if lon<=-90 & lon>=-180; code='B'; end	% B
	if lon>0 & lon<=90; code='D'; end		% D
	if lon>90 & lon<=180; code='C'; end		% C
elseif lat<0 
	if lon<=0 & lon>-90; code='I'; end  	% I
	if lon<=-90 & lon>=-180; code='J'; end	% J
	if lon>0 & lon<=90; code='L'; end		% L
	if lon>90 & lon<=180; code='K'; end		% K
end

% add the code to the string
outstr=[outstr code];

% add the next bit
outstr=[outstr '01_C_AMMC_'];

% time fix for less than ten
% c=fix(clock);
 [st,ts]=system(['date -u +%Y%m%d%H%M%S']);
 
% yyyy=str2num(ts(1:4));
% yyyy=int2str(c(1));
% if (c(2) < 10)
%     mm=['0' int2str(c(2))]; 
% else
%     mm=c(2); 
% end
% if (c(3) < 10)
%     dd=['0' int2str(c(3))]; 
% else
%     dd=c(3); 
% end
% if (c(4) < 10)
%     hh=['0' int2str(c(4))]; 
% else
%     hh=c(4); 
% end
% if (c(5) < 10)
%     mmin=['0' int2str(c(5))]; 
% else
%     mmin=c(5); 
% end
% if (c(6) < 10)
%     ss=['0' int2str(c(6))]; 
% else
%     ss=c(6); 
% end


% dddd=sprintf('%2.2d',c(2),c(3),c(4),c(5),c(6))
% dddd=ts(5:end);
% add the time bit
outstr=[outstr ts(1:14)];    %yyyy dddd];

% determine pno
pnum = fp.profile_number;
pno=sprintf('%3.3i',pnum);

% and the rest wmoid and pno
outstr=[outstr '_R' int2str(dbdat.wmo_id) '_' pno '.bin'];

% old outfile 
%outfile=[ARGO_SYS_PARAM.BUFR_delivery_path 'R' int2str(dbdat.wmo_id) '_' pno '_bufr']

outfile=[ARGO_SYS_PARAM.BUFR_delivery_path outstr]
if ~isempty(biofname)   
[status,ww] = system(['perl ' ARGO_SYS_PARAM.root_dir 'src/ArgoNetCDFp2BUFR_v3.1.pl ' outfile ' ' fname ' ' biofname]);
else
    [status,ww] = system(['perl ' ARGO_SYS_PARAM.root_dir 'src/ArgoNetCDFp2BUFR_v3.1.pl ' outfile ' ' fname]);
end
if status~=0
   logerr(3,['Creation of ' outfile ' from ' fname ' failed:' ww]);
else
    outcome = 1;
end

% text file directory
textfiledirnm = [ARGO_SYS_PARAM.root_dir 'textfiles/' int2str(dbdat.wmo_id) '/' ];

% copy the files to the text file backup
if ~exist(textfiledirnm)
    system(['mkdir ' textfiledirnm]);
end
system(['cp ' outfile ' ' textfiledirnm]);

% copy the files to the export_BUFR directory 
% (not needed as created in exportBUFR and this copies to exportBUFR)
%system(['cp ' outfile ' ' ARGO_SYS_PARAM.BUFR_delivery_path]);

% deliver the bufr to CMSS
% (not needed as export_argo.m calls this after the exportIridium call)
%system(['./src/write_BUFR_nc']);
