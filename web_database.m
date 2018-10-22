% WEB_DATABASE  Build web page of Argo master float spreadsheet
%
% INPUT:
%    Reads master spreadsheet (via GETDBASE)
%
% OUTPUT:
%    Page master_db.html
%
% AUTHOR: Jeff Dunn CMAR/BoM  Oct 2006
%
% CALLED BY:  nil  - manually invoked
%
% USAGE: web_database

function web_database

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

makestr = {'Webb','Provor','SOLO','Seabird','MRV'};

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
if isempty(THE_ARGO_FLOAT_DB)
   getdbase;
end


fnm = [ARGO_SYS_PARAM.web_dir 'master_db.html'];
fid = fopen(fnm,'w');
   
fprintf(fid,'<html>\n<body>\n');
fprintf(fid,'<body text="#000000" bgcolor="#99BBFF">\n');

fprintf(fid,'<title>Argo float master spreadsheet</title>\n\n');

% The navigation bar at top of page:
fprintf(fid,'<table align="center" width="80%%" bgcolor="#ccccff"><tr>\n');
fprintf(fid,'<td><a href="index.html">Back to Aus Argo</a></td>\n');
fprintf(fid,'<td><a href="processing/status_latest.html">');
fprintf(fid,'Last day`s processing</a></td>\n');
fprintf(fid,'</tr></table>\n<br><br>\n');
   

fprintf(fid,'<table border="1" align="center" width="100%%" cols="27" bgcolor="#ffffee"><tr>\n');

for jj = 1:length(THE_ARGO_FLOAT_DB)

   if mod(jj,40)==1
      write_headings(fid);
   end

   DB = THE_ARGO_FLOAT_DB(jj);
   if DB.maker == 6 %NKE Arvor floats - being processed elsewhere
       continue
   end
   if isempty(DB.wmo_id); DB.wmo_id=nan; end
   if isempty(DB.argos_id); DB.argos_id=nan; end
   if isempty(DB.status); DB.status=' - '; end
   if isempty(DB.launchdate); DB.launchdate = ' - '; end
   if isempty(DB.deploy_num); DB.deploy_num = nan; end
   if isempty(DB.owner); DB.owner = ' - '; end
   if isempty(DB.wmo_inst_type); DB.wmo_inst_type = ' - '; end
   if isempty(DB.ctd_sensor_type); DB.ctd_sensor_type = ' - '; end
   if isempty(DB.sbe_snum); DB.sbe_snum = nan; end
   if isempty(DB.controlboardnum); DB.controlboardnum = nan; end
   if isempty(DB.oxysens_snum); DB.oxysens_snum = nan; end
   if isempty(DB.psens_snum); DB.psens_snum = nan; end
   if isempty(DB.reprate); DB.reprate = nan; end
   if isempty(DB.parktime); DB.parktime = nan; end
   if isempty(DB.asctime); DB.asctime = nan; end
   if isempty(DB.surftime); DB.surftime = nan; end
   if isempty(DB.parkpres); DB.parkpres = nan; end
   if isempty(DB.uptime); DB.uptime = nan; end
   if isempty(DB.profpres); DB.profpres = nan; end
   if isempty(DB.launch_platform); DB.launch_platform = ' - '; end
   if isempty(DB.np0); DB.np0 = nan; end
   if isempty(DB.subtype); DB.subtype = nan; end

   if strcmp(DB.status,'dead')
      fprintf(fid,'<tr bgcolor="999999">\n');
   elseif strcmp(DB.status,'exhausted')
      fprintf(fid,'<tr bgcolor="5eff33">\n');
   elseif strcmp(DB.status,'evil')
      fprintf(fid,'<tr bgcolor="ff7777">\n');
   elseif strcmp(DB.status,'suspect')
      fprintf(fid,'<tr bgcolor="77bbff">\n');
   elseif strcmp(DB.status,'expected')
      fprintf(fid,'<tr bgcolor="ffff00">\n');
   elseif strcmp(DB.status,'unknown')
      fprintf(fid,'<tr bgcolor="00ffff">\n');
   else
      fprintf(fid,'<tr>\n');
   end

   fprintf(fid,'<td>%d</td><td>%d</td><td>%s</td>\n',...
	   DB.wmo_id,DB.argos_id,DB.status);
   fprintf(fid,'<td>%s</td><td>%8.4f</td><td>%8.4f</td>\n',...
	   DB.launchdate,DB.launch_lat,DB.launch_lon);
   fprintf(fid,'<td>%d</td><td>%d</td><td>%s</td>\n',...
	   DB.maker_id,DB.deploy_num,DB.owner);
   fprintf(fid,'<td>%s</td><td>%s</td><td>%d</td>\n',...
	   DB.wmo_inst_type ,DB.ctd_sensor_type ,DB.sbe_snum );
   fprintf(fid,'<td>%s</td><td>%d</td><td>%10d</td>\n',...
	   DB.controlboardnumstring ,DB.oxysens_snum ,DB.psens_snum );
   fprintf(fid,'<td>%5.1f</td><td>%5.2f</td><td>%5.2f</td>\n',...
	   DB.reprate ,DB.parktime ,DB.asctime );
   fprintf(fid,'<td>%5.2f</td><td>%d</td><td>%5.1f</td>\n',...
	   DB.surftime ,DB.parkpres ,DB.uptime );
   fprintf(fid,'<td>%d</td><td>%s</td><td>%d</td>\n',...
	   DB.profpres ,DB.launch_platform ,DB.np0 );
   tmp = '';
   if DB.ice; tmp = 'I'; end
   if DB.oxy; tmp = [tmp ' O']; end
   if DB.tmiss; tmp = [tmp ' T']; end   
   fprintf(fid,'<td>%s</td><td>%d</td><td>%s</td>\n<tr>\n\n',...
	   makestr{DB.maker} ,DB.subtype ,tmp);
end
   
fprintf(fid,'</table>\n<br>\n');
   
fprintf(fid,'<p><font size=1>Updated on %s</font>\n',date);
fprintf(fid,'</html>\n');
fclose(fid);

eval(['!chmod -f ugo+r ' fnm]);

%-------------------------------------------------------------------------
function write_headings(fid)

fprintf(fid,'<tr><th>WMO</th><th>Argos</th><th>Status</th>\n');
fprintf(fid,'<th>launch date</th><th>launch lat</th><th>launch lon</th>\n');
fprintf(fid,'<th>maker id</th><th>deploy_num</th><th>owner</th>\n');
fprintf(fid,'<th>wmo inst</th><th>ctd sensor</th><th>SBE snum</th>\n');
fprintf(fid,'<th>c board snum</th><th>O sens snum</th><th>P sens snum</th>\n');
fprintf(fid,'<th>RepRate</th><th>park time</th><th>asc time</th>\n');
fprintf(fid,'<th>surf time</th><th>park P</th><th>up time</th>\n');
fprintf(fid,'<th>prof P</th><th>launch platform</th><th>np0</th>\n');
fprintf(fid,'<th>Maker</th><th>subtype</th><th>Sensors</th></tr>\n</tr>\n\n');

return
%-------------------------------------------------------------------------
