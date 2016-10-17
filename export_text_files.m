% exporttextfiles - reads the mat files and generates a text file for 
%   archiving in ./textfiles/R590?????
if ispc
fnmp = [ARGO_SYS_PARAM.root_dir 'textfiles\' int2str(float(np).wmo_id) '\p' int2str(float(np).wmo_id) '_' ...
       int2str(float(np).profile_number) '.dat'];
fnmc = [ARGO_SYS_PARAM.root_dir 'textfiles\' int2str(float(np).wmo_id) '\c' int2str(float(np).wmo_id) '_' ...
       int2str(float(np).profile_number) '.dat'];   
else
fnmp = [ARGO_SYS_PARAM.root_dir 'textfiles/' int2str(float(np).wmo_id) '/p' int2str(float(np).wmo_id) '_' ...
       int2str(float(np).profile_number) '.dat'];
fnmc = [ARGO_SYS_PARAM.root_dir 'textfiles/' int2str(float(np).wmo_id) '/c' int2str(float(np).wmo_id) '_' ...
       int2str(float(np).profile_number) '.dat'];
end

fidp=fopen(fnmp,'w');
fidc=fopen(fnmc,'w');

if fidp<1
   logerr(3,['EXPORT_TEXT_FILES: Could not open file ' fnmp]);
   if ispc
       system(['mkdir ' ARGO_SYS_PARAM.root_dir 'textfiles\' int2str(float(np).wmo_id) ]);
   else
       system(['mkdir ' ARGO_SYS_PARAM.root_dir 'textfiles/' int2str(float(np).wmo_id) ]);
   end
   fidp=fopen(fnmp,'w');
   fidc=fopen(fnmc,'w');
end

if fidc<1
   logerr(1,['EXPORT_TEXT_FILES:Second try - Could not open file ' fnmc]);
   return
end

   fprintf(fidp,'N\n');
   fprintf(fidc,'N\n');


for i=1:length(float(np).lat)
     g=gregorian(float(np).jday(i));
     refjuld=julian([g(1) 1 1 0 0 0]);
     dofy=g(1)+(float(np).jday(i)-refjuld)/365;

     fprintf(fidp,'%i    %10.5f     %5.2f     %6.2f     %0.4d %0.2d %0.2d %0.2d %0.2d %0.2d  %s\n',...
	     dbdat.argos_id,dofy,float(np).lon(i),float(np).lat(i),g,float(np).position_accuracy(i));

     fprintf(fidc,'%i    %10.5f     %5.2f     %6.2f     %0.4d %0.2d %0.2d %0.2d %0.2d %0.2d  %s\n',...
	     dbdat.argos_id,dofy,float(np).lon(i),float(np).lat(i),g,float(np).position_accuracy(i));

end

   fprintf(fidp,'P\n');
   fprintf(fidc,'P\n');
sp=float(np).surfpres+5.;

      if dbdat.maker==2   %provor float - srfc_termination is blank...
   fprintf(fidp,'%i  %i    %i    %i     %7.3f  %9.3f   %7.3f\n',...
 float(np).SN,float(np).profile_number,float(np).npoints,float(np).sfc_termination,float(np).voltage,sp,float(np).p_internal);
   fprintf(fidc,'%i  %i    %i    %i      %7.3f  %9.3f   %7.3f\n',...
 float(np).SN,float(np).profile_number,float(np).npoints,float(np).sfc_termination,float(np).voltage,sp,float(np).p_internal);
      else   
          try
   fprintf(fidp,'%i  %i    %i    %i     %7.3f  %9.3f   %7.3f\n',...
 float(np).SN,float(np).profile_number,float(np).npoints,str2num(float(np).sfc_termination),float(np).voltage,sp,float(np).p_internal);
   fprintf(fidc,'%i  %i    %i    %i      %7.3f  %9.3f   %7.3f\n',...
 float(np).SN,float(np).profile_number,float(np).npoints,str2num(float(np).sfc_termination),float(np).voltage,sp,float(np).p_internal);
          end
      end

for i=1:length(float(np).t_raw)
    if(dbdat.tmiss)
     fprintf(fidp,'%0.4d       %7.3f      %7.3f       %10.3f       %10.3f       %10.3f\n',...
i,float(np).t_raw(i),float(np).s_raw(i),float(np).p_raw(i),float(np).oxy_raw(i),float(np).tm_counts(i));
     fprintf(fidc,'%0.4d        %7.3f      %7.3f       %10.3f        %10.3f        %10.3f\n',...
i,float(np).t_raw(i),float(np).s_calibrate(i),float(np).p_calibrate(i),float(np).oxy_raw(i),float(np).tm_counts(i));
    elseif(dbdat.oxy & dbdat.subtype~=1006)
            fprintf(fidp,'%0.4d       %7.3f      %7.3f       %10.3f      %10.3f\n',...
i,float(np).t_raw(i),float(np).s_raw(i),float(np).p_raw(i),float(np).oxy_raw(i));
     fprintf(fidc,'%0.4d        %7.3f      %7.3f       %10.3f       %10.3f\n',...
i,float(np).t_raw(i),float(np).s_calibrate(i),float(np).p_calibrate(i),float(np).oxy_raw(i));
    else       
     fprintf(fidp,'%0.4d       %7.3f      %7.3f       %10.3f\n',...
i,float(np).t_raw(i),float(np).s_raw(i),float(np).p_raw(i));
     fprintf(fidc,'%0.4d        %7.3f      %7.3f       %10.3f\n',...
i,float(np).t_raw(i),float(np).s_calibrate(i),float(np).p_calibrate(i));
    end
end
if(dbdat.subtype==1006)
    for i=1:length(float(np).p_oxygen)
            fprintf(fidp,'%0.4d       %7.3f      %7.3f       %10.3f      %10.3f\n',...
i,float(np).t_oxygen(i),float(np).s_oxygen(i),float(np).p_oxygen(i),float(np).oxy_raw(i));
%      fprintf(fidc,'%0.4d        %7.3f      %7.3f       %10.3f       %10.3f\n',...
% i,float(np).t_raw(i),float(np).s_calibrate(i),float(np).p_calibrate(i),float(np).oxy_raw(i));
    end
end

fclose(fidp);
fclose(fidc);
