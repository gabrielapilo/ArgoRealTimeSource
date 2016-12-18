% WEB_PROFILE_PLOT  Create web page for a single profile, and plots to be 
%   viewed in that page.
%
% INPUT: fp - struct for a single profile
%        db - structure for meta-database of float
%
% OUTPUT Files:
%     WWW/floats/WMO/profile_NN.html
%     WWW/floats/WMO/profile_NN.tif
%
% AUTHOR: Jeff Dunn CMAR/BoM  Oct 2006
%
% CALLED BY:  Argo main program. Can be used standalone
% 
% USAGE: web_profile_plot(fp,db)

function web_profile_plot(fp,db)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if isempty(fp) | isempty(fp.lat) | isempty(fp.p_raw)
   return
end

jul0 = julian(0,1,0);

fwmo = num2str(fp.wmo_id);
pn = fp.profile_number;

if ispc
    fdir = [ARGO_SYS_PARAM.web_dir 'floats\' fwmo];
    if ~exist(fdir,'dir'); system(['mkdir ' fdir '; chmod -f ugo+rx ' fdir]); end
    fnm =  [fdir '\profile_' num2str(pn)]
else
    fdir = [ARGO_SYS_PARAM.web_dir 'floats/' fwmo];
    if ~exist(fdir,'dir'); system(['mkdir ' fdir '; chmod -f ugo+rx ' fdir]); end
    fnm =  [fdir '/profile_' num2str(pn)]
end

% -------------  Create the single-profile web page

fid = fopen([fnm '.html'],'w');

fprintf(fid,'<html>\n<body>\n');
fprintf(fid,'<body text="#000000" bgcolor="#88AAFF">\n');

fprintf(fid,'<title>%s  PN=%d</title>\n\n',fwmo,pn);

% The navigation bar at top of page:
fprintf(fid,'<table align="center" width="80%%" bgcolor="#ccccff"><tr>\n');
fprintf(fid,'<td><a href="../../index.html">Back to Aus Argo</a></td>\n');
fprintf(fid,'<td><a href="floatsummary.html">Summary for this Float</a></td>\n');

a=['<td><a href="' ARGO_SYS_PARAM.web_pages num2str(db.maker_id),'/Hull_',num2str(db.maker_id),'.html"> Technical Pages</a></td>\n'];
fprintf(fid,a);

if pn>1
   fprintf(fid,'<td><a href="profile_%d.html">Previous</a></td>\n',pn-1);
end
fprintf(fid,'<td><a href="profile_%d.html">Next</a></td>\n',pn+1);
fprintf(fid,'</tr></table>\n');
                                               

fprintf(fid,'<h2>Float %s :  Profile %d</h2>\n',fwmo,pn);

% In populating tables, we first load values into temporary strings so 
% missing values can be found and replaced by appropriate markers.

% First table - general float info

fprintf(fid,'\n<table border="1" cols="9">\n');

fprintf(fid,'<tr><th>Dates</th> <th>Fixes</th>\n');
fprintf(fid,'<th>Lat. S</th> <th>Lon. E</th>\n');
fprintf(fid,'<th>Est Surfacing Time</th>\n');
fprintf(fid,'<th>First Fix Time</th>\n');
fprintf(fid,'<th>Battery</th> <th>C<sub>ratio</sub></th>\n');
fprintf(fid,'<th>C<sub>ratio</sub>Calc</th></tr>\n\n');
   
str{1} = sprintf('%d',length(fp.jday));
str{2} = sprintf('%d',length(~isnan(fp.lat)));
str{3} = sprintf('%6.3f',-fp.lat(1));
str{4} = sprintf('%6.3f',fp.lon(1));
str{5} = sprintf('%s',datestr(fp.jday_ascent_end-jul0));
str{6} = sprintf('%s',datestr(fp.jday(1)-jul0));
str{7} = sprintf('%4.1f',fp.voltage);
str{8} = sprintf('%8.4f',fp.c_ratio);
str{9} = sprintf('%8.4f',fp.c_ratio_calc);

for ii = 1:9
   if isempty(str{ii}); str{ii} = '- -'; end
end

fprintf(fid,'<tr><td>%s</td> <td>%s</td> <td>%s</td>\n',str{1:3});
fprintf(fid,'<td>%s</td> <td>%s</td> <td>%s</td>\n',str{4:6});
fprintf(fid,'<td>%s</td> <td>%s</td> <td>%s</td>\n</tr>\n\n',str{7:9});
fprintf(fid,'</table>\n\n<br>\n');


% Fourth table - processing stats - moved to second

fprintf(fid,'<br>\n<table border="1">\n');

fprintf(fid,'<caption><b>Processing Stats<b></caption>\n\n');

fprintf(fid,'<tr><th>Activity</th> <th>Reference</th>\n');
for ii = 1:6
   jj = (1:3) + ((ii-1)*3);
   fprintf(fid,'<th>%2d </th><th>%2d </th><th>%2d </th>\n',jj);
end
fprintf(fid,'<th>%d</th></tr>\n',19);

% - Message Decoding
if length(fp.fbm_report)==8
   fprintf(fid,'<tr><td><b>Decode</b></td><td>find_best_msg</td>\n');

   fprintf(fid,'<td>%d</td> <td>%d</td> <td>%d</td>\n',fp.fbm_report(1:3));
   fprintf(fid,'<td>%d</td> <td>%d</td> <td>%d</td>\n',fp.fbm_report(4:6));
   fprintf(fid,'<td>%d</td> <td>%d</td> </tr>\n',fp.fbm_report(7:8));
end

% - QC tests. "*" if test flagged as failed, blank otherwise. 
if ~isempty(fp.testsfailed)
   fprintf(fid,'<tr><td><b>QC</b></td><td>qc_test.m</td>\n');
   for ii = 1:19
      if fp.testsfailed(ii) ~= 0
	 fprintf(fid,'<td bgcolor="ff0000"> * </td>');
      else
	 fprintf(fid,'<td> - </td>');
      end      
   end
   fprintf(fid,'</tr>\n\n');
end

% - Calibration
if length(fp.cal_report)==6
   fprintf(fid,'<tr><td><b>Cal</b></td><td>calsal.m</td>\n');

   fprintf(fid,'<td>%5.1f</td> <td>%d</td> <td>%d</td>\n',fp.cal_report(1:3));
   fprintf(fid,'<td>%d</td> <td>%f</td> <td>%f</td></tr>\n',fp.cal_report(4:6));
end
fprintf(fid,'</table>\n\n');



fprintf(fid,'<br>\n');
if(ispc | ~ARGO_SYS_PARAM.gif)
    fprintf(fid,'<a href="profile_%d.tif" target="blank">',pn);
    %fprintf(fid,'<img src="profile_%d.tif" height="95%%" width="100%%"></a>\n',pn);
    fprintf(fid,'<img src="profile_%d.tif"></a>\n',pn);
else
    fprintf(fid,'<a href="profile_%d.gif" target="blank">',pn);
    %fprintf(fid,'<img src="profile_%d.gif" height="95%%" width="100%%"></a>\n',pn);
    fprintf(fid,'<img src="profile_%d.gif"></a>\n',pn);
end

% Fifth Table - Profile data summaries - moved to just after plots

fprintf(fid,'<br>\n<table border="1" cols="5">\n');

fprintf(fid,'<caption><b>Profile Data<b></caption>\n\n');

fprintf(fid,'<tr><th> </th> <th>N values</th>\n');
fprintf(fid,'<th>Min</th> <th>Max</th> <th>N Bad</th></tr>\n');
   
pnames = {'P cal','T raw','S cal','Oxy','OxyT','Tmiss'};
for jj = 1:6
   vv = [];
   switch jj
     case 1
       vv = fp.p_calibrate;
       vqc = fp.p_qc;
     case 2
       vv = fp.t_raw;
       vqc = fp.t_qc;
     case 3
       vv = fp.s_calibrate;
       vqc = fp.s_qc;
     case 4
       if isfield(fp,'oxy_raw')
	  vv = fp.oxy_raw;
	  vqc = fp.oxy_qc;
       end
     case 5
       if isfield(fp,'oxyT_raw')
	  vv = fp.oxyT_raw;
	  vqc = fp.oxyT_qc;
       end
     case 6
       if isfield(fp,'tm_counts')
	  vv = fp.tm_counts;
	  vqc = fp.tm_qc;
       end
   end

   if ~isempty(vv)
      fprintf(fid,'<tr><th>%s</th> <td>%d</td>\n',pnames{jj},length(~isnan(vv)));
      fprintf(fid,'<td>%10.2f</td> <td>%10.2f</td>\n',min(vv),max(vv));
      fprintf(fid,'<td>%d</td> <tr>\n',sum(vqc>2 & vqc~=5));
   end
end   
fprintf(fid,'</table>\n\n');

% Second table - processing description - moved to fourth after plots AT Dec
% 2010

fprintf(fid,'\n<br>\n<table border="1" width="85%%">\n');

fprintf(fid,'<caption><b>Processing Stages<b></caption>\n\n');
fprintf(fid,'<tr><th>Stage</th> <th>Comment</th> <th>Download</th></tr>\n');

str = {' - ','unknown',' - ','unknown'};
if ~isempty(fp.stg1_desc)
   str{1} = fp.stg1_desc;
end
if ~isempty(fp.stg2_desc)
   str{3} = fp.stg2_desc;
end
for ii = 1:2
   if fp.ftp_download_jday(ii)~=0      
      str{2*ii} = datestr(fp.ftp_download_jday(ii)-jul0);
   end
end
fprintf(fid,'<tr><td>1</td> <td>%s</td> <td>%s</td></tr>\n',str{1},str{2});
fprintf(fid,'<tr><td>2</td> <td>%s</td> <td>%s</td></tr>\n',str{3},str{4});
fprintf(fid,'</table>\n\n');


% Third table - processing stage stats - moved to 5th 

fprintf(fid,'\n<br>\n<table border="1" width="85%%">\n');

fprintf(fid,'<caption><b>Processing Stage Details<b> - see process');
fprintf(fid,'_profile.m</caption>\n\n');

fprintf(fid,'<tr><th>Stage</th> <th>Status</th> <th>Date (UTC)</th>\n');
fprintf(fid,'<th>L1</th> <th>L2</th> <th>L3</th> <th>L4</th>\n');
fprintf(fid,'<th>L5</th></tr>\n\n');
   
for jj = 1:2
if fp.proc_stage >= jj && ~isempty(fp.proc_status)
      fprintf(fid,'<tr> <td>%d</td> ',jj);
      if fp.proc_status(jj)==-1
	 fprintf(fid,'<td><font color="#ff0000">Failed</font></td>\n');
      else
	 fprintf(fid,'<td>ok</td>\n');
      end
      if fp.stage_jday(jj)==0
	 fprintf(fid,'<td>unknown</td>\n');
      else
	 fprintf(fid,'<td>%s</td>\n',datestr(fp.stage_jday(jj)-jul0));
      end
      for ii = 1:3
	 if fp.stage_ecnt(jj,ii) > 0
	    fprintf(fid,'<td><font color="#ff0000">%d</font></td>\n',...
		    fp.stage_ecnt(jj,ii));
	 else
	    fprintf(fid,'<td>%d</td>\n',fp.stage_ecnt(jj,ii));
	 end
      end
      fprintf(fid,'<td>%d</td> <td>%d</td> </tr>\n',fp.stage_ecnt(jj,4:5));
   end
end   
fprintf(fid,'</table>\n\n');


fprintf(fid,'\n<p><font size="2">Created %s</p>\n',date);
fprintf(fid,'</body>\n</html>');
fclose(fid);

% -------------- Generate the plot file
web_plot_generation(fp,db)
%----------------------------------------------------------------------
