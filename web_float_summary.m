% WEB_FLOAT_SUMMARY  Build OR extend a summary file for a given float.
%
% INPUT: float  - struct array for the floatwebb
%        dbdat  - database struct for the float
%        rebuild- 1=rebuild whole file  0=only add new profiles [def 0]
%   Files:
%        WWW/floats/WMO/floatsummary.html  - read if extending, not rebuilding.
%        WWW/templates/floatsummary_head.html  - if rebuilding
%
% OUTPUT: 
%   File: [temporary]  WWW/floats/WMO/new_summary.html
%          on completion, renamed to  floatsummary.html
%
% CALLED BY:  main program, or standalone
%
% AUTHOR: Jeff Dunn CMAR/BoM  Oct 2006
%
% USAGE: web_float_summary(float,dbdat,rebuild);

function web_float_summary(float,dbdat,rebuild)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_SENSOR_DB

s=getadditionalinfo(dbdat.wmo_id);

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if nargin<3 || isempty(rebuild)
   rebuild = 0;
end

fwmo = int2str(dbdat.wmo_id);

if ispc
fdir = [ARGO_SYS_PARAM.web_dir 'floats\' fwmo];
if ~exist(fdir,'dir'); system(['mkdir ' fdir '; chmod -f ugo+rx ' fdir]); end
file1 = [fdir '\floatsummary.html'];
file2 = [fdir '\new_summary.html'];
else
fdir = [ARGO_SYS_PARAM.web_dir 'floats/' fwmo];
if ~exist(fdir,'dir'); system(['mkdir ' fdir '; chmod -f ugo+rx ' fdir]); end
file1 = [fdir '/floatsummary.html'];
file2 = [fdir '/new_summary.html'];
end


if ~exist(fdir,'dir')
   logerr(4,['Creating new directory ' fdir]);
   st = system(['mkdir ' fdir]);
   if st~=0
      logerr(2,['Failed creating new directory ' fdir]);
      return
   end
   st = system(['chmod -f ugo+rx ' fdir]);
end

if ~rebuild && ~exist(file1,'file')
   logerr(4,['Cannot extend ' file1 ' because it is missing. Will rebuild!']);
   rebuild = 1;
end


if rebuild
   % Start with the standard first section of these files
  
if ispc
   file4 = [ARGO_SYS_PARAM.web_dir 'templates\floatsummary_head.html'];
   st = system(['cp ' file4 ' ' file2 ]);
else
   file4 = [ARGO_SYS_PARAM.web_dir 'templates/floatsummary_head.html'];
   st = system(['cp ' file4 ' ' file2 '; chmod -f ugo+r ' file2]);
end
   
   if st~=0
      logerr(2,['Failed to copy floatsummary.html to new file ' file2]);
      return
   end

   fid2 = fopen(file2,'a');
   
   % Write the float-specific header info, and the column headings row
   % of the table.   
   
   fprintf(fid2,'\n<title>%s-%d-%d</title>\n\n',fwmo,dbdat.argos_id,dbdat.maker_id);
   
   if dbdat.maker==1
      if dbdat.subtype==0
	 makstr = ' Webb R1-SBE';
      elseif dbdat.RBR
     makstr = ' Webb APEX-RBR';
      else
	 makstr = ' Webb APEX-SBE';
      end
   elseif dbdat.maker==3 | dbdat.maker==5
       if dbdat.subtype==1018
           makstr = ' MRV SoloII';
       else
           makstr = ' Solo';
       end
   elseif dbdat.maker==4
     makstr = ' Seabird NAVIS';
   elseif dbdat.maker==2
     makstr = ' PROVOR';
   end
   makstr = [upper(dbdat.owner) makstr];
   telecomms=s.UplinkSystem;
   fprintf(fid2,'<h1><center>%s Float %s<br>\n',makstr,num2str(dbdat.maker_id));
   fprintf(fid2,'%s ID %d - WMO %s</center></h1>\n',telecomms,dbdat.argos_id,fwmo);
   a=['<td><a href="' ARGO_SYS_PARAM.web_pages num2str(dbdat.maker_id),'/Hull_',num2str(dbdat.maker_id),'.html"> Technical Pages</a></td>\n'];
   fprintf(fid2,a);
   if(~isempty(float))
       fprintf(fid2,'\n<p>Click the Profile Number to View the Raw Data.\n');
       fprintf(fid2,'See time-series plots at bottom of this page.\n');
   else
       fprintf(fid2,'\n<p>THIS FLOAT HAS NOT YET REPORTED A PROFILE\n');
   end

   fprintf(fid2,'\n<table border="1" cols="13" nosave="">\n');

   fprintf(fid2,'<tr><td>Profile</td> <td>Lat. N</td> <td>Lon. E</td>\n');
   fprintf(fid2,'<td>Date</td> <td>Month</td> <td>Year</td>\n');
   fprintf(fid2,'<td>Hour</td> <td>P<sub>max</sub></td>\n');
   fprintf(fid2,'<td>P<sub>min</sub></td> <td>N<sub>point</sub></td>\n');
   fprintf(fid2,'<td>Battery</td> <td>C<sub>ratio</sub></td> ');
   fprintf(fid2,'<td>C<sub>ratio</sub>Calc</td></tr>\n\n');
   
   % Build table starting from profile 1
   prnum = 1;
else
   fid1 = fopen(file1, 'r');
   fid2 = fopen(file2, 'w');

   % If extending, not rebuilding, copy input to output until reach the 
   % Last-Profile marker, which is just before the end of the table. 
   prnum = 0;
   while prnum==0 && ~feof(fid1)
      cc = fgetl(fid1);
      ii = strfind(cc,'<!--LAST');
      if isempty(ii)
	 fprintf(fid2,'%s\n',cc);
      else
	 prnum = sscanf(cc(ii+(8:11)),'%d');
      end
   end
   prnum = prnum+1;
   fclose(fid1);
end


% Generate a table row for each required profile:
% Note: sometimes  float(prnum).profile number ~= prnum 

str=[];
if(~isempty(float))
    
for kk = prnum:length(float)
 
   fprintf(fid2,'<tr>\n<td><A href="profile_%d.html">%d</A></td>\n',...
	   float(kk).profile_number,float(kk).profile_number);

   % First load values into temporary vars so can put in missing-value- 
   % markers where necessary.   
   if ~isempty(float(kk).lat) & ~isempty(float(kk).datetime_vec)
%      str{1} = sprintf('%6.3f',-float(kk).lat(1));
      str{1} = sprintf('%6.3f',float(kk).lat(1));
      str{2} = sprintf('%6.3f',float(kk).lon(1));
      str{3} = sprintf('%d',float(kk).datetime_vec(1,3));
      str{4} = sprintf('%d',float(kk).datetime_vec(1,2));
      str{5} = sprintf('%d',float(kk).datetime_vec(1,1));
      str{6} = sprintf('%5.2f',float(kk).datetime_vec(1,4) + ...
          float(kk).datetime_vec(1,5)/60.0);
   else   
      for ii = 1:6
          str{ii} = '- -';
      end
   end
   
   if ~isempty(float(kk).p_calibrate)
       str{7} = sprintf('%6.1f',max(float(kk).p_calibrate));
       str{8} = sprintf('%6.1f',min(float(kk).p_calibrate));
       str{9} = sprintf('%d',length(float(kk).p_raw));
       str{10} = sprintf('%4.1f',float(kk).voltage);
       str{11} = sprintf('%8.4f',float(kk).c_ratio);
       str{12} = sprintf('%8.4f',float(kk).c_ratio_calc);
   else
       for ii = 7:12
           str{ii} = '- -';
       end
   end
	    
   fprintf(fid2,'<td>%s</td> <td>%s</td> <td>%s</td>\n',str{1:3});
   fprintf(fid2,'<td>%s</td> <td>%s</td> <td>%s</td>\n',str{4:6});
   fprintf(fid2,'<td>%s</td> <td>%s</td> <td>%s</td>\n',str{7:9});
   fprintf(fid2,'<td>%s</td> <td>%s</td> <td>%s</td></tr>\n\n',str{10:12});
end


% Write out Last Profile marker, and close table and file.
fprintf(fid2,'<!--LAST %d  -->\n</table>\n\n',length(float));

end

fprintf(fid2,'<p><a href=#top>top</a>\n');

fprintf(fid2,'<hr>\n<h2 id="plots">Plots</h2>\n');
fprintf(fid2,'<p>Click to see full plot in new browser\n\n');
fprintf(fid2,'<p>\n\n');

if(~isempty(float))
if(ispc | ~ARGO_SYS_PARAM.gif)

    fprintf(fid2,'<a href="ts_%s.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="ts_%s.tif" border="1"></a>\n\n',fwmo);
    
    fprintf(fid2,'<a href="loc_%s.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="loc_%s.tif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="T_%s.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="T_%s.tif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="T_%s_waterfall.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="T_%s_waterfall.tif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="S_%s.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="S_%s.tif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="S_%s_waterfall.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="S_%s_waterfall.tif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="PD_%s.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="PD_%s.tif" border="1"></a>\n\n',fwmo);
    
    fprintf(fid2,'<a href="PD_%s_waterfall.tif" target="blank">',fwmo);
    fprintf(fid2,'<img src="PD_%s_waterfall.tif" border="1"></a>\n\n',fwmo);
    if isfield(float,'oxy_raw')
        fprintf(fid2,'<a href="O2_%s.tif" target="blank">',fwmo);
        fprintf(fid2,'<img src="O2_%s.tif" border="1"></a>\n\n',fwmo);
        
        fprintf(fid2,'<a href="O2_%s_waterfall.tif" target="blank">',fwmo);
        fprintf(fid2,'<img src="O2_%s_waterfall.tif" border="1"></a>\n\n',fwmo);
    end

else
    
    fprintf(fid2,'<a href="ts_%s.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="ts_%s.gif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="loc_%s.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="loc_%s.gif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="T_%s.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="T_%s.gif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="T_%s_waterfall.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="T_%s_waterfall.gif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="S_%s.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="S_%s.gif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="S_%s_waterfall.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="S_%s_waterfall.gif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="PD_%s.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="PD_%s.gif" border="1"></a>\n\n',fwmo);

    fprintf(fid2,'<a href="PD_%s_waterfall.gif" target="blank">',fwmo);
    fprintf(fid2,'<img src="PD_%s_waterfall.gif" border="1"></a>\n\n',fwmo);

    if isfield(float,'oxy_raw')
        fprintf(fid2,'<a href="O2_%s.gif" target="blank">',fwmo);
        fprintf(fid2,'<img src="O2_%s.gif" border="1"></a>\n\n',fwmo);
        
        fprintf(fid2,'<a href="O2_%s_waterfall.gif" target="blank">',fwmo);
        fprintf(fid2,'<img src="O2_%s_waterfall.gif" border="1"></a>\n\n',fwmo);
    end
end    
end

fprintf(fid2,'<p><font size=1>Updated on %s</font>\n',date);
fprintf(fid2,'</html>\n');
fclose(fid2);

st = system(['chmod -f ugo+r ' file2]);
st = system(['mv -f ' file2 ' ' file1]);

% now regenerate tech web pages:
 if(~isempty(float)); webUpdatePages(dbdat.wmo_id);end


%-------------------------------------------------------------------------
