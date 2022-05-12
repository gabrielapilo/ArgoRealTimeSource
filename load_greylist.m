function [greylist ] = load_greylist
% Loads the greylist file 
%return a structure with WMO id, variable that is greylisted, date from,
%date to and flag
%Bec Cowley, May, 2017

global ARGO_SYS_PARAM

   glist = [ARGO_SYS_PARAM.root_dir 'spreadsheet/' lower(ARGO_SYS_PARAM.inst) '_greylist.csv'];
   
   %load the file:
   fid = fopen(glist);
   if fid == 0
       glist = [];
       return
   end
   
   c = textscan(fid,'%s','delimiter','\n');
   fclose(fid);
   
   c = c{:};
   
   for a = 2:length(c)
       str = textscan(c{a},'%f%s%f%f%f%s%s','delimiter',',');
       greylist.wmo_id(a) = str{1};
       greylist.var(a) = str{2};
       greylist.start(a) = datenum(num2str(str{3}),'yyyymmdd');
       if isnan(str{4})
           greylist.end(a) = datenum(date)+2;
       else
           greylist.end(a) = datenum(num2str(str{4}),'yyyymmdd');
       end
       greylist.flag(a) = str{5};
   end
end

