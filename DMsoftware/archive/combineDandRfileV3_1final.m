%Ok lets do this the quick way
function combineDandRfileV3_1final(list)
    % Set up some variables
    % list contains one or more wmo_ids for combination with the R files
    set_argo_sys_params
    global ARGO_SYS_PARAM
    global ARGO_ID_CROSSREF
    if isempty(ARGO_ID_CROSSREF)
        getdbase(-1);
    end

    % According to Ann's code we need to check for parallel files - 
    % one D and one R, then grab D contents and insert into new R file.  
    % R file must be version 3.1 AND must have similar contents to D file 
    % or it needs to be checked.
    Dpath=['/home/argo/data/dmode/4/'];  % wmo_id/profiles/*
    Rpath=['/home/argo/ArgoRT/netcdf/'];
    DpathOutput=[Dpath 'v31_testing/'];
    fid=fopen('checktheseforDMconversion.txt','w');
%     length(ARGO_ID_CROSSREF)
%     list = find(ARGO_ID_CROSSREF(:,1) == 7900333);
    for iFloat = 1:length(list)  %401:length(ARGO_ID_CROSSREF)
        try
            [fpp,dbdat]=getargo(list(iFloat));
            display(sprintf('Converting float %i (%i/%i)', dbdat.wmo_id, iFloat, length(ARGO_ID_CROSSREF)));
            if ~isempty(fpp)
               dd=sprintf('%s%i', DpathOutput, dbdat.wmo_id)
               if ~exist(dd,'dir')
                   system(['mkdir ' sprintf('%s%i', DpathOutput, dbdat.wmo_id)]);
               end
                for iFile = 1:length(fpp)
                    iFile=iFile
                    fD = sprintf('%s%i/profiles/D%i_%03i.nc', Dpath, dbdat.wmo_id,...
                                                              dbdat.wmo_id, fpp(iFile).profile_number);
                    if exist(fD,'file')
                        %If there is a D-File copy it over
                        fR = sprintf('%s%i/R%i_%03i.nc', Rpath, dbdat.wmo_id,...
                                                         dbdat.wmo_id, fpp(iFile).profile_number);
                        fDO = sprintf('%s%i/D%i_%03i.nc', DpathOutput, dbdat.wmo_id,...
                                                           dbdat.wmo_id, fpp(iFile).profile_number);
                        system(['cp ' fR ' ' fDO]);  

                        cont = 1;
                        try
                            ncRfile = netcdf.open(fDO, 'WRITE');
                        catch 
                            fprintf(fid,'%s\n',['File format bad in netcdf: ' fDO]);
                            cont = 0;
                        end

                        try
                            ncDfile = netcdf.open(fD, 'NOWRITE');
                        catch
                            fprintf(fid,'%s\n',['File format bad in 4Gilson: ' fDO]);
                            cont = 0;
                        end

                        if cont
                            varId = netcdf.inqVarID(ncRfile,'PRES');
                            pR= netcdf.getVar(ncRfile, varId); 
                            varId = netcdf.inqVarID(ncDfile,'PRES');
                            pD= netcdf.getVar(ncDfile, varId); 
                            varId = netcdf.inqVarID(ncRfile,'TEMP');
                            tR= netcdf.getVar(ncRfile, varId); 
                            varId = netcdf.inqVarID(ncDfile,'TEMP');
                            tD= netcdf.getVar(ncDfile, varId); 
                            varId = netcdf.inqVarID(ncRfile,'PSAL');
                            sR= netcdf.getVar(ncRfile, varId); 
                            varId = netcdf.inqVarID(ncDfile,'PSAL');
                            sD= netcdf.getVar(ncDfile, varId); 

                            try
                                varId = netcdf.inqVarID(ncDfile,'DOXY');
                                sD= netcdf.getVar(ncDfile, varId);      
                                %fprintf(fid,'%s\n',['DOXY in primary: ' fDO]);
                                doxy = 1;
                            catch
                                doxy = 0;
                            end

                            dropOne = 0;
                            if any(size(pR) ~= size(pD)) | any(size(sR) ~= size(sD)) | any(size(tR) ~= size(tD))
                                %fprintf(fid,'%s\n',['Field length not equal: ' fDO]);
                                dropOne = 1;
                                pD = pD(1:end-1,:);
                                sD = sD(1:end-1,:);
                                tD = tD(1:end-1,:);
                            end

%                             if (any(pR(:,1)-pD(:,1)) | any (sR(:,1)-sD(:,1)) | any (tR(:,1)-tD(:,1))) % a raw field changed in DM
%                                 if ~doxy
%                                     fprintf(fid,'%s\n',['Edited raw field: ' fDO]);
%                                 end
%                             else   % go and fill the old R with the new D fields:
                                getAndSetNetCdfField(ncDfile, ncRfile, 'DATA_MODE', 0);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'DATA_STATE_INDICATOR', 0);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'DATE_UPDATE', 0);
                                getAndSetProfQC(ncDfile, ncRfile, 'PROFILE_PRES_QC', 'PRES_ADJUSTED',dropOne);
                                getAndSetProfQC(ncDfile, ncRfile, 'PROFILE_TEMP_QC', 'TEMP_ADJUSTED',dropOne);
                                getAndSetProfQC(ncDfile, ncRfile, 'PROFILE_PSAL_QC', 'PSAL_ADJUSTED',dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PRES_ADJUSTED', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'TEMP_ADJUSTED', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PSAL_ADJUSTED', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PRES_ADJUSTED_QC', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'TEMP_ADJUSTED_QC', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PSAL_ADJUSTED_QC', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PRES_ADJUSTED_ERROR', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'TEMP_ADJUSTED_ERROR', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PSAL_ADJUSTED_ERROR', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PRES_QC', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'TEMP_QC', dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'PSAL_QC', dropOne);  
                                getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_COMMENT',0);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_EQUATION',0);
                                getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_COEFFICIENT',0);  
           %                     getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_DATE',0);  

                                try
                                    getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_DATE',0);                                 
                                catch
                                    varId = netcdf.inqVarID(ncDfile,'DATE_UPDATE');
                                    value = netcdf.getVar(ncDfile, varId); 

                                    varId = netcdf.inqVarID(ncRfile,'SCIENTIFIC_CALIB_DATE');
                                    valueR =  netcdf.getVar(ncRfile, varId);
                                    for iV = 1:size(valueR,2)
                                        valueR(:,iV) =  value;
                                    end
                                    netcdf.putVar(ncRfile, varId, valueR);
                                end


                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_INSTITUTION');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_STEP');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_SOFTWARE');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_REFERENCE');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_DATE');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_ACTION');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_PARAMETER');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_START_PRES');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_STOP_PRES');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_PREVIOUS_VALUE');
                                getAndSetNetCdfHistoryField(ncDfile, ncRfile, 'HISTORY_QCTEST');
                            %end

                            netcdf.close(ncDfile);
                            netcdf.close(ncRfile);
                        end
                    end
                end
            end
        end
    end
fclose(fid);
    
    
function getAndSetNetCdfField(getFile, setFile, field, dropOne)
    varId = netcdf.inqVarID(getFile,field);
    value = netcdf.getVar(getFile, varId); 
    if dropOne == 1
        value = value(1:end-1,:);
    end
        
    varId = netcdf.inqVarID(setFile,field);
    netcdf.putVar(setFile, varId, value);
    
function getAndSetProfQC(getFile, setFile, field, variable, dropOne)
    varId = netcdf.inqVarID(getFile,field);
    value = netcdf.getVar(getFile, varId); 
    
    varId = netcdf.inqVarID(getFile, [variable '_QC']);
    qcp = netcdf.getVar(getFile, varId);
    if dropOne
        qcp=qcp(1:length(qcp)-1);
    end
    
    status = overall_qcflag(qcp);
    
    varId = netcdf.inqVarID(setFile,field);
    netcdf.putVar(setFile, varId, status);

    
function status = overall_qcflag(qcp)

if ~isstr(qcp)
   qcp = num2str(qcp(:))';
end

bd = sum(qcp=='3' | qcp=='4' | qcp=='6' | qcp=='7');
nn = sum(qcp~='9');

if any(qcp=='0')
   % No QC performed!
   status = ' ';
elseif nn==0   
   % An empty profile, either no values or all missing values 
   status='F';      
else
   badd = bd/nn;
   if badd == 0
      status = 'A';
   elseif badd <= .25
      status = 'B';
   elseif badd <= .5
      status = 'C';
   elseif badd <= .75
      status = 'D';
   elseif badd < 1
      status = 'E';
   else
      status = 'F';
   end
end

return
    
    


function getAndSetNetCdfHistoryField(getFile, setFile, field)
    varId = netcdf.inqVarID(getFile,field);
    valueD = netcdf.getVar(getFile, varId); 
    varId = netcdf.inqVarID(setFile,field);
    valueR = netcdf.getVar(setFile, varId); 
        
    [m,n,o]=size(valueD);
    valueR(1:m,1:n,1:o) = valueD;
    netcdf.putVar(setFile, varId, zeros(1,ndims(valueR)),size(valueR), valueR);
