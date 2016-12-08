
% set_argo_sys_params
% global THE_ARGO_FLOAT_DB
% global ARGO_SYS_PARAM
% getdbase(-1);
% AFDB=THE_ARGO_FLOAT_DB;


for i=1:length(AFDB)
    
%     if AFDB(i).oxy  ;  
%         [fpp,dbdat]=getargo(AFDB(i).wmo_id);
        i=i        
        
%         redesigned to tar and zip all netcdf archives from
%         oxygenflatos,as well as the matfiles from those floats

% matdat=['cp ' ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id) '.mat /home/argo/ArgoRT/holdmat']
% system(matdat);
% tardat=['tar -cBvf /home/ftp/pub/gronell/BOM/' num2str(dbdat.wmo_id) '.netcdf.tar ./netcdf/' num2str(dbdat.wmo_id) ]
% system(tardat);


% and now adapted to remove all plain older trajfiles from directories
% where the Rtraj file exists:

     fnm=['/home/argo/ArgoRT/netcdf/' num2str(AFDB(i).wmo_id) '/' num2str(AFDB(i).wmo_id) '_Rtraj.nc'];
     if exist(fnm,'file')
         try
             fnm2=['/home/argo/ArgoRT/netcdf/' num2str(AFDB(i).wmo_id) '/' num2str(AFDB(i).wmo_id) '_traj.nc'];
             system(['rm ' fnm2])
         end
     end
end
%         fmn=[ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(AFDB(i).wmo_id)]
%         pause
%  try       
%         system(['cp 'fnm ' /home/argo/ArgoRT/holdoxymats'])
%  end    
%     end
% end

% for j=386:length(fpp)
%     fpp(j).CHLa_raw=convertFsig(fpp(j).Fsig,dbdat.wmo_id);
%     fpp(j).BBP700_raw=convertBbsig(fpp(j).Bbsig,fpp(j),0);
% end
% 
% for j=386:length(fpp)
%     fpp=qc_tests(dbdat,fpp,j);
% end
% 
% float=fpp;
% 
% fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];
% save(fnm,'float','-v6');
