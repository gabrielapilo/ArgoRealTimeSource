%recreate netcdf files for selected floats
%adapt to suit the need!

clear all

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO
% getBiocaldbase
if isempty(ARGO_SYS_PARAM)
    set_argo_sys_params;
end
% global ARGO_ID_CROSSREF PREC_FNM
getdbase(-1)
% PREC_FNM = [ARGO_SYS_PARAM.root_dir 'Argo_proc_records'];

kk = [7900396 7900397 7900398 7900602 7900603 7900604 7900605 7900606 7900607 7900608];
ipath = ARGO_SYS_PARAM.iridium_path;

% Loops in floats:
for ii = 1:length(kk)
    
    disp(ii)
    [fpp,dbdat]=getargo(kk(ii));
    
    %     [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    % if any([dbdat.flbb,dbdat.flbb2,dbdat.irr, dbdat.irr2, ...
    %             dbdat.pH])

    % Path to files
    ARGO_SYS_PARAM.iridium_path = [ipath 'iridium_processed/' ...
        num2str(dbdat.wmo_id) '/']; % To rebuild from original, processed log and msg files
    %
    % Path to files
    %         ARGO_SYS_PARAM.iridium_path = [ipath]; % To rebuild from original,non-processed log and msg files, iridium_data
    
    % Loops in profiles
    for j = 1:length(fpp);
        
        %           for j = 81%2:10;
        clear pmeta
        close all
        [ii j]
        
        %             if ~isempty(fpp(j).lat)
        %                 try
        pmeta.wmo_id = dbdat.wmo_id;
        pn = '000';
        pns = num2str(j);
        pn(end-length(pns)+1:end) = pns; % profile number
        
        %
        %                     %% Uncomment for NAVIS and APF9
        %                     pmeta.ftp_fname = [num2str(dbdat.argos_id) '.' pn '.msg'];
        pmeta.ftp_fname = [num2str(dbdat.argos_id,'%04.f') '.' pn '.msg'];
        fn = dirc([ARGO_SYS_PARAM.iridium_path pmeta.ftp_fname]);
        pmeta.ftptime = julian(datevec(fn{4}));
        %
        
        % % %                     % uncomment for APF11 floats
        %                     fn = dirc([ARGO_SYS_PARAM.iridium_path 'f*.' pn '.*science_log.csv']);
        %                     if isempty(fn)
        %                      fn = dirc([ARGO_SYS_PARAM.iridium_path 'f*.' pn '.*system_log.txt']);
        %                     end
        %                     if isempty(fn)
        %                      fn = dirc([ARGO_SYS_PARAM.iridium_path '*.' pn '.*science_log.csv']);
        %                     end
        %                     if isempty(fn)
        %                      fn = dirc([ARGO_SYS_PARAM.iridium_path '*.' pn '.*system_log.txt']);
        %                     end
        %                     if isempty(fn)
        %                        disp('file not found')
        % %                         continue
        %                     end
        %                     for bb = 1:size(fn,1)
        %                         pmeta.ftp_fname{bb} = fn{bb,1};
        %                         pmeta.ftptime(bb) = julian(datevec(fn{bb,4}));
        %                     end
        %
        
        opts.rtmode = 0; %don't send BUFR files etc
        opts.redo = 1;
        
        %                     try
        
        % When running process_iridium_apf11, comment out lines
        % 842 to 850 (the bit that writes reprocessing back to file)
        % You can also comment out the plotting scripts:
        % web_float_summary; time_section_plot; waterfallplots; locationplots; tsplots;
        
        %                      process_iridium_apf11(pmeta,dbdat,opts) % FOR APF11s
        
        
        process_iridium(pmeta,dbdat) % FOR APF9s and NAVIS            %%%%% <<-----
        
        %                     catch
        %                         continue
    end
    
end

%%
% If you run process_iridium, no need to run argoprofile_nc
fpp(j).p_calibrate = []; % Make p_calibrate empty to re-do qc_tests
argoprofile_nc(dbdat,fpp(j))  %%%%% <<-----
%copy to export
system(['cp ' ARGO_SYS_PARAM.root_dir 'netcdf/' num2str(dbdat.wmo_id) '/R' num2str(dbdat.wmo_id) '_' pn '.nc /home/argo/ArgoRT/export'])


%                     argoprofile_Bfile_nc(dbdat,fpp(j))
%copy to export
%                     system(['cp ' ARGO_SYS_PARAM.root_dir '/netcdf/' num2str(dbdat.wmo_id) '/BR' num2str(dbdat.wmo_id) '_' pn '.nc /home/argo/ArgoRT/export'])
% or could run argoprofile_nc here too
%                 catch
%                     bad = [bad;ii,j];
%                 end
% end % end loop in profile <<<<<<<<<------
%         end
%     end
% end % end loop in floats <<<<<<<<<,-------