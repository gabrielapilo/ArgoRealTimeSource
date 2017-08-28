% WEB_SELECT_FLOAT  Re-build index pages for selection of float pages.
%
% INPUT:
%    Reads master spreadsheet (via GETDBASE) to get IDs of all floats
%
% AUTHOR: Jeff Dunn CMAR/BoM  Oct 2006
%
% CALLED BY:  nil  - manually invoked
%
% Note: This only needs to be used when:
%     a) a new float has been processed for the first time
%     b) the "status" of any float changes ("alive" to "dead" etc)  
%
% USAGE: web_select_float

function web_select_float

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
if isempty(THE_ARGO_FLOAT_DB)
   getdbase;
end
DB = THE_ARGO_FLOAT_DB;


% Create two pages - one ordered by WMO id, the other by ARGOS id.
if ispc
fpth = [ARGO_SYS_PARAM.www_root 'floats\'];
else
fpth = [ARGO_SYS_PARAM.www_root 'floats/'];
end

idstr = {'WMO','ARGOS'};

for mm = 1:2
   [tmp,ij] = sort(ARGO_ID_CROSSREF(:,mm));

   fnm = [ARGO_SYS_PARAM.web_dir 'select_floats_' idstr{mm} '.html'];
   fid = fopen(fnm,'w');
   
   fprintf(fid,'<html>\n<body>\n');
   fprintf(fid,'<body text="#000000" bgcolor="#88AAFF">\n');

   fprintf(fid,'<title>Select float by %s</title>\n\n',idstr{mm});

   % The navigation bar at top of page:
   fprintf(fid,'<table align="center" width="80%%" bgcolor="#ccccff"><tr>\n');
   fprintf(fid,'<td><a href="index.html">Back to Aus Argo</a></td>\n');
   fprintf(fid,'<td><a href="select_floats_%s.html">Select by %s</a></td>\n',...
	   idstr{3-mm},idstr{3-mm});
   fprintf(fid,'</tr></table>\n<br><br>\n');
   

   fprintf(fid,'<table border="1" align="center" width="95%%" cols="10"><tr>\n');
   fprintf(fid,'<caption><b>ARGO REAL_TIME PROCESSING: yellow floats are "dead", green floats are probably dead.</b></caption>\n\n');

   nn = 0;
   for ii = ij(:)'
      nn = nn+1;
      if nn==1
	 fprintf(fid,'<tr>\n'); 
      end
      
      if strfind(DB(ii).status,'exhausted') == 1
          tdstr = '<td bgcolor="5eff33">';
      elseif strfind(DB(ii).status,'dead') == 1
          tdstr = '<td bgcolor="ffff00">';
      else
          tdstr = '<td>';
      end
      
      idw = DB(ii).wmo_id;

      if mm==1
         id2=idw;
      else
	 id2 = DB(ii).argos_id;
      end
      
      fprintf(fid,'%s<A href="%s%d/floatsummary.html">%d</td>\n',tdstr,fpth,idw,id2);

      if nn==10
	 fprintf(fid,'</tr>\n');
	 nn = 0;	 
      end
   end
   fprintf(fid,'</table>\n<br>\n');
   
   fprintf(fid,'<p><font size=1>Updated on %s</font>\n',date);
   fprintf(fid,'</html>\n');
   fclose(fid);
end

eval(['!chmod -f ugo+r ' ARGO_SYS_PARAM.web_dir '*']);

%-------------------------------------------------------------------------
