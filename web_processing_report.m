% WEB_PROCESSING_REPORT  Create web page for recent processing reports.
%
% INPUT:  
%  fnm  - [optional] processing records filename, if non-standard
%  new_clr   [optional] 1=>set new=0, so that records reported now will not
%            be reported again until they are revised.   [default 1]
%  miss_alert  0/1 switch off/on alert email for overdue floats
%              [default according to system parameters]
%  fdate    [optional] 1=use file date rather than today's for name and title
%           of the proc records page. May use when reprocessing.
%
% OUTPUT Files:
%     WWW/processing/reportYY_DDD.html  (copied to status_latest.html)
%     WWW/processing/status_all.html
%
% AUTHOR: Jeff Dunn CMAR/BoM  Oct 2006
%
% CALLED BY:  Argo main program. Can be used standalone
% 
% USAGE: web_processing_report(fnm,new_clr,miss_alert,fdate)

function web_processing_report(fnm,new_clr,miss_alert,fdate)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if nargin<1 | isempty(fnm)
   fnm = [ARGO_SYS_PARAM.root_dir 'Argo_proc_records'];
end
load(fnm,'PROC_RECORDS','ftp_details');
prec = PROC_RECORDS;

if nargin<2 | isempty(new_clr)
   new_clr = 1;
end
if nargin<3 | isempty(miss_alert)
   miss_alert = ARGO_SYS_PARAM.miss_alert;
end
if nargin<4 | isempty(fdate)
   fdate = 0;
end

% Unload some key data from the records
for ii = 1:length(prec)
   pwmo(ii) = prec(ii).wmo_id;
   if isempty(prec(ii).jday_ascent_end)
       [fpp,dbdat]=getargo(pwmo(ii));
       if(~isempty(fpp))
           if(~isempty(fpp(end).jday))
               prec(ii).jday_ascent_end=fpp(end).jday(1);
           else
               for bb=length(fpp):-1:2
                   if(~isempty(fpp(bb).jday_ascent_end))
                       prec(ii).jday_ascent_end=fpp(bb).jday_ascent_end;
                       break
                   end
               end
           end
       end
   end
   %check it again to make sure something sensible is present:
   if isempty(prec(ii).jday_ascent_end)
       prec(ii).jday_ascent_end = NaN;
   end
   jday(ii) = prec(ii).jday_ascent_end;
   new(ii) = prec(ii).new;
end

% Get the present date, and also convert to day-of-year, to make filename
if fdate==1
   dvec = gregorian(ftp_details(1).ftptime);
   j0 = julian(dvec);

else
   dvec = datevec(now);
   j0 = julian(dvec)-(10/24);

end
yr = rem(dvec(1),100);
d_o_y = datenum(0,dvec(2),dvec(3));

[tmp,iwmo] = sort(pwmo);


%---------------- Create page reporting today's processing

fnm2 = sprintf('%sprocessing/report%0.2d_%d.html',ARGO_SYS_PARAM.web_dir,yr,d_o_y);
if exist(fnm2,'file')
   logerr(3,['Overwriting pre-existing report page ' fnm2]);
end
fid = fopen(fnm2,'w');

fprintf(fid,'<html>\n<body>\n');
fprintf(fid,'<body text="#000000" bgcolor="#88AAFF">\n');

fprintf(fid,'<title>Processing Reports for Day %d</title>\n\n',d_o_y);


% -- The navigation bar at top of page:
fprintf(fid,'<table align="center" width="80%%" bgcolor="#ccccff"><tr>\n');
fprintf(fid,'<td><a href="../index.html">Back to Aus Argo</a></td>\n');
fprintf(fid,'<td><a href="status_all.html">Reports for all floats</a></td>\n');
if d_o_y>1
   fprintf(fid,'<td><a href="report%0.2d_%d.html">Previous Day</a></td>\n',yr,d_o_y-1);
else
   fprintf(fid,'<td><a href="report%0.2d_%d.html">Previous Day</a></td>\n',yr-1,365);
end
fprintf(fid,'<td><a href="report%0.2d_%d.html">Next Day</a></td>\n',yr,d_o_y+1);
fprintf(fid,'</tr></table>\n<br>\n');
                                               

% -- First table - List the ftp file details (if any)

ftptm = [];
if exist('ftp_details','var') && ~isempty(ftp_details)
   fprintf(fid,'<br>\n<table align="center" border="1" cols="4">\n');
   fprintf(fid,'<caption><b>Most recent FTP Downloads</b></caption>\n');

   fprintf(fid,'<tr><th>#</th> <th>UTC Time</th> <th>Num Lines</th>');
   fprintf(fid,'<th>Num Prof</th>\n');
   
   for ii = 1:length(ftp_details)
      fd = ftp_details(ii);
      if ~isempty(fd) && ~isempty(fd.ftptime) && ~isnan(fd.ftptime)	 
	 ftptm(ii) = fd.ftptime;
	 fprintf(fid,'<tr><td>%d</td><td>%s</td><td>%d</td><td>%d</td>\n',...
		 ii,datestr(gregorian(fd.ftptime)),fd.nlines,fd.nprofiles);
      end
   end
   fprintf(fid,'</table>\n\n<br>\n<br>\n');
end
   
	 
	 
% -- 2nd table - reports for profiles new today (in WMO number order)

fprintf(fid,'WMO links go to floatsummary page, Pnum links to individual');
fprintf(fid,' profile pages.\n');

fprintf(fid,'\n<table align="center" border="1" cols="10">\n');

fprintf(fid,'<caption><b>New arrivals Day %d</b></caption>\n',d_o_y);

fprintf(fid,'<tr><th>WMO</th> <th>P num</th> <th>Stage</th> <th>Proc Status</th>\n');
fprintf(fid,'<th>ftp download</th> <th colspan=5>Report counts</th><tr>\n');

fprintf(fid,'<tr><td> </td> <td> </td> <td> </td>  <td> </td>  <td> </td>\n');
fprintf(fid,'<th>L1</th> <th>L2</th> <th>L3</th> <th>L4</th>\n');
fprintf(fid,'<th>L5</th></tr>\n\n');


for jj = find(new(iwmo)==1)   
   pr = prec(iwmo(jj));
   fpth = [ARGO_SYS_PARAM.www_root 'floats/' int2str(pr.wmo_id)];

   fprintf(fid,'<tr><td><A href="%s/floatsummary.html">%d</td>\n',fpth,pr.wmo_id);
   if pr.proc_stage==0
      fprintf(fid,'<td> - </td> <td> 0 </td> <td>Waiting 18hrs</td>\n');
   else
      fprintf(fid,'<td><A href="%s/profile_%d.html">%d</td>\n',fpth,...
	      pr.profile_number,pr.profile_number);
      fprintf(fid,'<td> %d </td>\n',pr.proc_stage);      
      if pr.proc_status==-1
	 fprintf(fid,'<td><font color="#ff0000">*Failed*</font></td>\n');
      else
	 fprintf(fid,'<td>ok</td>\n');
      end
   end
   delt = 99;
   if ~isempty(ftptm) && ~isempty(pr.ftptime)
      [delt,kk] = min(abs(ftptm-pr.ftptime));
   end      
   if delt<.1
      fprintf(fid,'<td>#%d</td>\n',kk);
   else
      fprintf(fid,'<td> ? </td>\n');
   end
      
   for ii = 1:3
      if pr.stage_ecnt(1,ii) > 0
	 fprintf(fid,'<td><font color="#ff0000">%d</font></td>\n',...
		 pr.stage_ecnt(1,ii));
      else
	 fprintf(fid,'<td> 0 </td>\n');
      end
   end
   fprintf(fid,'<td>%d</td> <td>%d</td> </tr>\n',pr.stage_ecnt(1,4:5));
end
fprintf(fid,'</table>\n\n<br>\n');



% -- 3rd table - overdue floats (in overdue time order)

fprintf(fid,'WMO links go to floatsummary page');

fprintf(fid,'\n<table align="center" border="1" cols="9">\n');

fprintf(fid,'<caption><b>Floats Overdue or expected soon</b></caption>\n');

fprintf(fid,'<tr><th>Days since Last</th> <th>WMO</th> <th>P num</th>\n');
fprintf(fid,'<th>Proc Status</th>\n <th colspan=5>Last report counts</th><tr> \n');

fprintf(fid,'<tr><td> </td> <td> </td> <td> </td> <td> </td> \n');
fprintf(fid,'<th>L1</th> <th>L2</th> <th>L3</th> <th>L4</th>\n');
fprintf(fid,'<th>L5</th></tr>\n\n');

nmiss = 0;
mlist = [];

[tmp,ij] = sort(jday,'descend');

for jj = find(new(ij)==0 & (j0-jday(ij))>10.0)  
    
   pr = prec(ij(jj));
   [fpp,dbdat]=getargo(pwmo(ij(jj)));
%   dbdat = getdbase(pr.wmo_id);
   if ~isempty(strfind('dead evil expected exhausted',dbdat.status)) 
      % Don't do anything - we do not expect to see this float again
   else      
      fpth = [ARGO_SYS_PARAM.www_root 'floats/' int2str(pr.wmo_id)];
      fprintf(fid,'<tr><td>%8.1f</td>\n',j0-max(fpp(end).jday_ascent_end,pr.jday_ascent_end));
      fprintf(fid,'<td><A href="%s/floatsummary.html">%d</td>\n',fpth,pr.wmo_id);
      fprintf(fid,'<td><A href="%s/profile_%d.html">%d</td>\n',fpth,...
          pr.profile_number,pr.profile_number);

      if pr.proc_status(1) == -1
     fprintf(fid,'<td><font color="#ff0000">*Failed*</font></td>\n');
      elseif pr.proc_status(1) == 1
     fprintf(fid,'<td>ok</td>\n');
      else
     fprintf(fid,'<td>unknown</td>\n');
      end
   
      for ii = 1:3
	 if pr.stage_ecnt(1,ii) > 0
	    fprintf(fid,'<td><font color="#ff0000">%d</font></td>\n',...
		    pr.stage_ecnt(1,ii));
	 else
	    fprintf(fid,'<td> 0 </td>\n');
	 end
      end
      fprintf(fid,'<td>%d</td> <td>%d</td> </tr>\n',pr.stage_ecnt(1,4:5));
    if(isempty(fpp(end).jday_ascent_end));fpp(end).jday_ascent_end=pr.jday_ascent_end;end
      if (j0-(max(fpp(end).jday_ascent_end,pr.jday_ascent_end))) > 10.8
	 nmiss = nmiss+1;
	 mlist(nmiss,1:3) = [pr.wmo_id pr.argos_id dbdat.maker_id];
	 mlist(nmiss,4:5) = [(j0-max(fpp(end).jday_ascent_end,pr.jday_ascent_end)) pr.proc_status(1)+2];
      end
   end
end
fprintf(fid,'</table>\n\n<br>\n');

fprintf(fid,'\n<p><font size="2">Created %s</p>\n',date);
fprintf(fid,'</body>\n</html>');
fclose(fid);

% "status_latest.html" is a copy of this most recent file, and is linked to
% from other pages.
system(['cp -f ' fnm2 ' ' ARGO_SYS_PARAM.web_dir 'processing/status_latest.html']);


%-------- If required, send an email report on overdue floats

if nmiss>0 & miss_alert
   fnm4 = sprintf('%sprocessing/overdue_report.email',ARGO_SYS_PARAM.web_dir);
   fid = fopen(fnm4,'w');
   fprintf(fid,' Apparently overdue floats as at %s\n\n',date);
   fprintf(fid,'  WMO    ARGOS  WebbID    Days since Last    Previous Status\n\n');
   ststr = {'Failed','unknown','Success'};
   
   for ii = 1:nmiss
      fprintf(fid,'%8d%7d%6d    %8.1f                %s\n',mlist(ii,1:4),ststr{mlist(ii,5)});
   end
   fclose(fid);
   
mail_out_overdue_floats

end



%--------------- Create page of last processing reports of all floats

fnm3 = [ARGO_SYS_PARAM.web_dir 'processing/status_all.html'];
fid = fopen(fnm3,'w');

fprintf(fid,'<html>\n<body>\n');
fprintf(fid,'<body text="#000000" bgcolor="#88AAFF">\n');
fprintf(fid,'<title>Last Processing Reports for all floats</title>\n\n');

% Two navigation bars at top of page:
fprintf(fid,'<table align="center" width="80%%" bgcolor="#ccccff"><tr>\n');
fprintf(fid,'<td><a href="../index.html">Back to Aus Argo</a></td>\n');
fprintf(fid,'<td><a href="report%0.2d_%d.html">Reports for Today</a></td>\n', ...
	yr,d_o_y);
fprintf(fid,'</tr></table>\n');

fprintf(fid,'<table align="center" width="95%%" bgcolor="#ccccff">\n');
fprintf(fid,'<caption><b>Reports for N days ago</b></caption>\n <tr>');
dn = d_o_y;
yrn = yr;
for ii = 1:20
   dn = dn - 1;
   if dn<1
      dn = 365;
      yrn = yr-1;
   end
   fprintf(fid,'<td><a href="report%0.2d_%d.html">%d</a></td>\n',yrn,dn,ii);
end
fprintf(fid,'</tr></table>\n\n<br><br>\n');


% -- Table - reports for all floats (in WMO number order)

fprintf(fid,'<b>WMO</b> links go to floatsummary page, <b>Pnum</b> links');
fprintf(fid,' to individual profile pages.\n<br>\n');
fprintf(fid,'<p><b>Send count</b> = 99 indicates sending is complete.\n<br>\n');

fprintf(fid,'\n<p>  <table border="1" cols="13">\n');
fprintf(fid,'<caption><b>Last processing report - all floats</b></caption>\n');

fprintf(fid,'<tr><th>WMO</th> <th>Days Since</th><th>P num</th> \n');
fprintf(fid,'<th>Proc Status</th> <th colspan=5>Report counts</th> \n');
fprintf(fid,'<th></th> <th colspan=3>Send counts</th><tr> \n');

fprintf(fid,'<tr><td> </td> <td> </td> <td> </td> <td> </td> \n');
fprintf(fid,'<th>L1</th> <th>L2</th> <th>L3</th> <th>L4</th> <th>L5</th>\n');
fprintf(fid,'<th></th> <th>GTS</th><th>Prof</th><th>Traj</th></tr>\n\n');

for jj = iwmo   
   pr = prec(jj);
   fpth = [ARGO_SYS_PARAM.www_root 'floats/' int2str(pr.wmo_id)];

   fprintf(fid,'<tr><td><A href="%s/floatsummary.html">%d</td>\n',fpth,pr.wmo_id);
   fprintf(fid,'<td>%8.1f</td>',j0-max(prec(end).jday_ascent_end,pr.jday_ascent_end));
   fprintf(fid,'<td><A href="%s/profile_%d.html">%d</td>\n',fpth,...
	   pr.profile_number,pr.profile_number);
   if pr.proc_status==-1
      fprintf(fid,'<td><font color="#ff0000">*Failed*</font></td>\n');
   elseif pr.proc_status == 1
      fprintf(fid,'<td>ok</td>\n');
   else
      fprintf(fid,'<td>unknown</td>\n');
   end
   
   for ii = 1:3
      if pr.stage_ecnt(1,ii) > 0
	 fprintf(fid,'<td><font color="#ff0000">%d</font></td>\n',...
		 pr.stage_ecnt(1,ii));
      else
	 fprintf(fid,'<td> 0 </td>\n');
      end
   end
   fprintf(fid,'<td>%d</td> <td>%d</td> <td></td>\n',pr.stage_ecnt(1,4:5));
   fprintf(fid,'<td>%d</td> <td>%d</td> <td>%d</td> </tr>\n',...
	   pr.gts_count, pr.prof_nc_count, pr.traj_nc_count);
end
fprintf(fid,'</table>\n\n<br>\n');

fprintf(fid,'\n<p><font size="2">Created %s</p>\n',date);
fprintf(fid,'</body>\n</html>');
fclose(fid);


system(['chmod -f 664 ' ARGO_SYS_PARAM.web_dir 'processing/*']);

if new_clr
   % Clear the "new" flag so that those records are not new, now that we 
   % have reported them.
   for ii = find(new)
      PROC_RECORDS(ii).new = 0;
   end
    load(fnm,'ftp_details');
    save(fnm,'PROC_RECORDS','ftp_details','-v6');
end

%----------------------------------------------------------------------
