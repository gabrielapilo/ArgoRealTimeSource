%recreate netcdf files for selected floats
%adapt to suit the need!
new = 0;
if new
rdir = '/home/argo/ArgoRT/netcdf/';
ddir = '/home/argo/data/dmode/newSoftwareTest/';
global ARGO_SYS_PARAM
global THE_ARGO_BIO_CAL_DB  ARGO_BIO_CAL_WMO
if isempty(ARGO_SYS_PARAM)
    set_argo_sys_params;
end
getdbase(-1)
getBiocaldbase

kk = [1901329
    1901338
    1901339
    5903629
    5903630
    5903649
    5903660
    5903678
    5903679
    5903955
    5904218
    5904882
    1901347
    1901348
    5904923
    5904924
    5905022
    5905023
    5905165
    5905167];

for ii = 19:length(kk)
    disp(ii)
    [float,dbdat]=getargo(kk(ii));
    bc=find(ARGO_BIO_CAL_WMO==dbdat.wmo_id);
    bcal=THE_ARGO_BIO_CAL_DB(bc);
    bcoef=bcal_extract(bcal,700);
    for p = 1:length(float)
        pro = float(p);
        %now we need to convert Raw FLBB data to true chlorophyll and
        %backscatter:  added by Uday
        % modified by AT to use new bio cal sheets: Aug 2015
        
        if(dbdat.flbb)  % & dbdat.subtype==1022)            
            %         % ==== for Backscattering conversion
            bcoef=bcal_extract(bcal,700);
            if ~isempty(pro.parkBbsig)
                pro.parkBBP700=convertBbsig(pro.parkBbsig,pro.park_t,pro.park_s,700,bcoef);
            end
            if ~isempty(pro.Bbsig)
                if isfield(pro,'t_oxygen') & (length(pro.t_oxygen)==length(pro.Bbsig))
                    pro.BBP700_raw=convertBbsig(pro.Bbsig,pro.t_oxygen,pro.s_oxygen,700,bcoef);
                elseif length(pro.Bbsig)==length(pro.p_raw)
                    pro.BBP700_raw=convertBbsig(pro.Bbsig,pro.t_raw,pro.s_raw,700,bcoef);
                end
            end
        end
        % ========= end of addition by uday ===========
        if dbdat.flbb2  % these sensors also measure bb at two different wavelengths (532 added)
            
            bcoef=bcal_extract(bcal,532);
            if ~isempty(pro.parkBbsig532)  % note - need to add indicator for which
                %             wavelength so the script takes the correct cal coeffs!
                pro.parkBBP532=convertBbsig(pro.parkBbsig532,pro.park_t,pro.park_s,532,bcoef);
            end
            if ~isempty(pro.Bbsig532)
                pro.BBP532_raw=convertBbsig(pro.Bbsig532,pro.t_raw,pro.s_raw,532,bcoef);
            end
        end
        
        if dbdat.eco   %these sensors measure bb at 3 different wavelengths,
            %         and CAN be on a float that already has a 700nm version on an FLBB.
            %           gets complicated!  use isfield in pro to determine what to
            %           process!
            
            bcoef=bcal_extract(bcal,470.2);
            if ~isempty(pro.park_ecoBbsig470)  % note - need to add indicator for which
                %             wavelength so the script takes the correct cal coeffs!
                pro.park_ecoBBP470_raw=convertBbsig(pro.park_ecoBbsig470,pro.park_t,pro.park_s,470,bcoef);
            end
            if ~isempty(pro.ecoBbsig470)
                pro.ecoBBP470_raw=convertBbsig(pro.ecoBbsig470,pro.t_raw,pro.s_raw,470,bcoef);
            end
            
            bcoef=bcal_extract(bcal,532.2);
            if ~isempty(pro.park_ecoBbsig532)  % note - need to add indicator for which
                %             wavelength so the script takes the correct cal coeffs!
                pro.park_ecoBBP532_raw=convertBbsig(pro.park_ecoBbsig532,pro.park_t,pro.park_s,532,bcoef);
            end
            if ~isempty(pro.ecoBbsig532)
                pro.ecoBBP532_raw=convertBbsig(pro.ecoBbsig532,pro.t_raw,pro.s_raw,532,bcoef);
            end
            
            bcoef=bcal_extract(bcal,700.2);
            if ~isempty(pro.park_ecoBbsig700)  % note - need to add indicator for which
                %             wavelength so the script takes the correct cal coeffs!
                pro.park_ecoBBP700_raw=convertBbsig(pro.park_ecoBbsig700,pro.park_t,pro.park_s,700,bcoef);
            end
            if ~isempty(pro.ecoBbsig700)
                park=0;
                pro.ecoBBP700_raw=convertBbsig(pro.ecoBbsig700,pro.t_raw,pro.s_raw,700,bcoef);
            end
        end
        %save the pro back to the float structure and save the new values to the R and D mode netcdf
        %profile files. Don't need to fully re-make these files
        %BR file:
        try
            argoprofile_Bfile_nc(dbdat,pro);
        catch
            float(p) = pro;
            float = qc_tests(dbdat,float,p);
            pro = float(p);
            argoprofile_Bfile_nc(dbdat,pro);
        end            
        pn = '000';
        pns = num2str(p);
        pn(end-length(pns)+1:end) = pns;
        float(p) = pro;
        fnm = [ddir num2str(dbdat.wmo_id) '/DFILES/BD'  num2str(dbdat.wmo_id) '_' pn '.nc'];
        rfnm = [rdir num2str(dbdat.wmo_id) '/BR'  num2str(dbdat.wmo_id) '_' pn '.nc'];
        %now just copy over the fields to the D mode file:
        flds = {'BBP700','BETA_BACKSCATTERING700','BBP532','BETA_BACKSCATTERING532',...
            'BBP700_2','BETA_BACKSCATTERING700_2','BBP470','BETA_BACKSCATTERING470'};
        for jj = 1:length(flds)
            try
                dat = ncread(rfnm,flds{jj});
                ncwrite(fnm,flds{jj},dat);
            catch
                disp(['No field ' flds{jj} ' for float ' num2str(dbdat.wmo_id)])
            end
        end
        %copy for export.
        system(['cp ' fnm ' /home/argo/ArgoRT/export/'])
    end
    %now save the updated mat file
    save(['/home/argo/ArgoRT/matfiles/float' num2str(kk(ii)) '.mat'],'float','-v6');
end
%need to export using /home/argo/ArgoRT/src/DMsoftware/writeDMQCnewBD
else
    %% Fixes
% 1901329
%         1901338
%         1901339
%         5903629
%         5903630
%         5903649
%         5903660
%         
%         5903679
%         
%         5904218
%         5904882
%         1901347
%   5904923  5905023 5905167
%         5903678 %selected profiles - see rejections
% 1901348 %all        5905165 %All

kk = [  5904924 %from p=27:183 Just copy over
        5905022 %all BD files 1:243  Just copy over    
        5903955]; %selected profiles - see rejections Just copy over
    ddir = '/home/argo/data/dmode/newSoftwareTest/';
    rdir = '/home/argo/ArgoRT/netcdf/';
    
    for ii = 3%:length(kk)
        [float,dbdat]=getargo(kk(ii));
        
        for p = 1:length(float)
            pn = '000';
            pns = num2str(p);
            pn(end-length(pns)+1:end) = pns;
            fnm = [ddir num2str(kk(ii)) '/DFILES/BD'  num2str(kk(ii)) '_' pn '.nc'];
            rfnm = [rdir num2str(dbdat.wmo_id) '/BR'  num2str(dbdat.wmo_id) '_' pn '.nc'];
            pro = float(p);
            argoprofile_Bfile_nc(dbdat,pro);
            if exist(fnm,'file') == 2
                dat = ncread(fnm,'BBP700');
                datq = ncread(fnm,'BBP700_QC');
                ij = ~isnan(dat);
                
%                 if isempty(str2num(datq(ij))) && sum(sum(ij)) > 0
                    %now just copy over the fields to the D mode file:
                    flds = {'BBP700','BETA_BACKSCATTERING700','BBP532','BETA_BACKSCATTERING532',...
                        'BBP700_2','BETA_BACKSCATTERING700_2','BBP470','BETA_BACKSCATTERING470'};
                    
                    for jj = 1:length(flds)
                        try
                            dat = ncread(rfnm,flds{jj});
                            ncwrite(fnm,flds{jj},dat);
                            dat = ncread(rfnm,[flds{jj} '_QC']);
                            ncwrite(fnm,[flds{jj} '_QC'],dat);
                        catch
                            disp(['No field ' flds{jj} ' for float ' num2str(dbdat.wmo_id)])
                        end
                     end
                    %copy for export.
                    system(['cp ' fnm ' /home/argo/ArgoRT/exporttest/'])
                    
%                 end
            else
                    %copy for export.
                    system(['cp ' rfnm ' /home/argo/ArgoRT/exporttest/'])
            end
        end
    end
    
end
