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

function web_select_float_tech

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
    fpth = [ARGO_SYS_PARAM.www_root 'tech\'];
else
    fpth = [ARGO_SYS_PARAM.www_root 'tech/'];
end

idstr = {'WMO','ARGOS'};

for mm = 1:2
    [tmp,ij] = sort(ARGO_ID_CROSSREF(:,mm));
    
    fnm = [ARGO_SYS_PARAM.web_dir '/tech/index_' idstr{mm} '.html'];
    fid = fopen(fnm,'w');
    
    fprintf(fid,'<!document/>\n');
    fprintf(fid,'<html>\n');
    fprintf(fid,'<head>\n');
    fprintf(fid,'<meta charset="utf-8" />\n');
    fprintf(fid,'<script src="miseenpage.js"></script>\n');
    fprintf(fid,'<link rel="stylesheet" href="texte.css"/>\n');
    fprintf(fid,'<link rel="shortcut icon" href="img/favicone.png" />\n');
    fprintf(fid,'<title>Float status</title>\n');
    fprintf(fid,'</head>\n');
    fprintf(fid,'<body >\n');
    fprintf(fid,'<header>\n');
    fprintf(fid,'<img src="./img/bande.png" alt="Logo CSIRO - ARGO - ENSTA">\n');
    fprintf(fid,'</header>\n');
    fprintf(fid,'<article>\n');
    fprintf(fid,'<p>\n');
    
     fprintf(fid,'<caption><b>ARGO REAL_TIME PROCESSING: yellow floats are "dead", green floats are probably dead.</b></caption>\n\n');
 fprintf(fid,'<table align="center" width="80%%"><tr>\n');
   fprintf(fid,'Select float by %s\n\n',idstr{mm});
   fprintf(fid,'<td><a href="index_%s.html">Select by %s</a></td>\n',...
	   idstr{3-mm},idstr{3-mm});
   fprintf(fid,'<td><a href="index_detail.html">Float detailed index</a></td>\n');
    fprintf(fid,'</p>\n');
   fprintf(fid,'</tr></table>\n<br><br>\n');

   fprintf(fid,'<table>\n');
    
    nn = 0;
    for ii = ij(:)'
        nn = nn+1;
        if nn==1
            fprintf(fid,'<tr>');
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
        
        fprintf(fid,'%s<A href="%s%d/overview.html">%d</td>\n',tdstr,fpth,idw,id2);
        
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

eval(['!chmod -f ugo+r ' ARGO_SYS_PARAM.web_dir '/tech/*']);

%-------------------------------------------------------------------------
