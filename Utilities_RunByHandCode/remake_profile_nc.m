%recreate netcdf files for selected floats
%adapt to suit the need!

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

kk = [5905446];
ipath = ARGO_SYS_PARAM.iridium_path;
% for ii = 745:length(THE_ARGO_FLOAT_DB)
for ii = 1%7:length(kk)
    disp(ii)
    [fpp,dbdat]=getargo(kk(ii));
%     [fpp,dbdat] = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);

% if any([dbdat.flbb,dbdat.flbb2,dbdat.irr, dbdat.irr2, ...
%             dbdat.pH])
        %change the path temporarily:
        ARGO_SYS_PARAM.iridium_path = [ipath 'iridium_processed/' ...
            num2str(dbdat.wmo_id) '/']; %%% To rebuild from original log and msg files
%     if dbdat.maker == 4 %4 is Navis
        for j = 1%23:32%1:length(fpp)+dbdat.np0%71:78%1:
            clear pmeta
            close all
            [ii j]
%             if ~isempty(fpp(j).lat)
%                 try
                    pmeta.wmo_id = dbdat.wmo_id;
                    pn = '000';
                    pns = num2str(j);
                    pn(end-length(pns)+1:end) = pns;
                    pmeta.ftp_fname = [dbdat.argos_hex_id '.' pn '.msg'];
                    fn = dirc([ARGO_SYS_PARAM.iridium_path pmeta.ftp_fname]);
                    pmeta.ftptime = julian(datevec(fn{4}));
                    
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

                    if isempty(fn)
                       disp('file not found')
                        continue
                    end
                    
%                     for bb = 1:size(fn,1)
%                         pmeta.ftp_fname{bb} = fn{bb,1};
%                         pmeta.ftptime(bb) = julian(datevec(fn{bb,4}));
%                     end
                    opts.rtmode = 0; %don't send BUFR files etc
                    opts.redo = 1;
                    try
%                         process_iridium_apf11(pmeta,dbdat,opts) 
%                      process_iridium(pmeta,dbdat) 
                     
                    catch
                        continue
                    end
                      argoprofile_nc(dbdat,fpp(j)) 
                     
%                     argoprofile_Bfile_nc(dbdat,fpp(j))
                    %copy to export
% system(['cp ' ARGO_SYS_PARAM.root_dir '/netcdf/' num2str(dbdat.wmo_id) '/BR' num2str(dbdat.wmo_id) '_' pn '.nc /home/argo/ArgoRT/export'])
                    % or could run argoprofile_nc here too
%                 catch
%                     bad = [bad;ii,j];
%                 end
            end
%         end
%     end
end