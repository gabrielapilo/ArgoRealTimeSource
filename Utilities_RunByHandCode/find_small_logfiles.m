% flick through all the log files to check size:
cd /home/argo/Iridium_Repository
fln = dir('f*');
fid2 = fopen('MaxLogFiles.txt','w');
fid3 = fopen('MaxLogFiles_check.txt','w');
for a = 416:length(fln)
    if fln(a).isdir == 0
        continue
    end
    mmm = 1;
   %check for the log files:
   logf = dirc([fln(a).name '/*.log']);
   if ~isempty(logf)
       %figure out the size of the last log file:
       if logf{end,5} < 50000
           disp([fln(a).name '/' logf{end,1}]);
           
           %small max log, check
           [mm,outp] = system(['grep "Limit is" ' fln(a).name '/' logf{end,1}(1:7) '*.log']);
           if mm == 0
               disp('Limit < 60 in log files')
               ii = strfind(outp,'Limit is');
               ij = strfind(outp,'bytes');
               if str2num(outp(ii(end)+9:ij(end)-1)) < 50000
                   mmm = 0;
               else
                   %max log is > 60
                   continue
               end
               
           end
           [m,outp] = system(['grep MaxLogKb ' fln(a).name '/' logf{end,1}(1:5) '*.*g']);
           if m == 0
               ii = strfind(outp,'MaxLog');
               ij = strfind(outp,')');
               disp(outp(ii(end):ij-1))
               if str2num(outp(ii(end)+9:ij(end)-1)) < 60
                   mmm = 0;
               else
                   %max log is > 60
                   continue
               end
           end
           if mm == 0 | mmm == 0
               fprintf(fid2,'%s\n', fln(a).name);
           else
               fprintf(fid3,'%s\n', fln(a).name);
           end
       end
   end
   
end
fclose(fid2);
fclose(fid3);
return
%% Now fix the max logs in the mission.cfg files
