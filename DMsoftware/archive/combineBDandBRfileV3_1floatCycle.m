%Ok lets do this the quick way
function combineBDandBRfileV3_1floatCycle(iFloat, cycles)
    % Set up some variables
    % list contains one or more wmo_ids for combination with the R files
    set_argo_sys_params
    global ARGO_SYS_PARAM
    global ARGO_ID_CROSSREF
    if isempty(ARGO_ID_CROSSREF)
        getdbase(-1);
    end
    varList = {'DOXY'};
    varListLength = 1;

    % According to Ann's code we need to check for parallel files - 
    % one D and one R, then grab D contents and insert into new R file.  
    % R file must be version 3.1 AND must have similar contents to D file 
    % or it needs to be checked.
    Dpath=['/home/argo/data/dmode/4/'];  % wmo_id/profiles/*
    Rpath=['/home/argo/ArgoRT/netcdf/'];
    DpathOutput=[Dpath 'v31_testing/'];
     
    try
        %Get the Argo Float information 
        [fpp,dbdat]=getargo(list(iFloat));
        display(sprintf('Converting float %i (%i/%i)', dbdat.wmo_id, iFloat, length(ARGO_ID_CROSSREF)));
        
        %Don't continue if we have nothing
        if ~isempty(fpp)
            %Build the output path and create if it doesn't exist
            dd=sprintf('%s%i', DpathOutput, dbdat.wmo_id)
            if ~exist(dd,'dir')
                system(['mkdir ' sprintf('%s%i', DpathOutput, dbdat.wmo_id)]);
            end
           
            %Loop through each file in fpp and check it is in list of cycles
            for iFile = 1:length(fpp)
            	if any(fpp(iFile).profile_number == cycles)
                    iFile=iFile
                    fD = sprintf('%s%i/profiles/BD%i_%03i.nc', Dpath, dbdat.wmo_id,...
                                                              dbdat.wmo_id, fpp(iFile).profile_number);
                    
                    %If the old D-file exists copy it 
                    if exist(fD,'file')
                    	%If there is a D-File copy it over
                        fDO = sprintf('%s%i/BD%i_%03i.nc', DpathOutput, dbdat.wmo_id,...
                                                               dbdat.wmo_id, fpp(iFile).profile_number);
                        system(['cp ' fR ' ' fDO]);  
                        try
                            ncDfile = netcdf.open(fD, 'NOWRITE');
                        catch
                            fprintf(fid,'%s\n',['File format bad in 4Gilson: ' fDO]);
                            cont = 0;
                        end

                        % Now check the R file
                        fR = sprintf('%s%i/BR%i_%03i.nc', Rpath, dbdat.wmo_id,...
                                 dbdat.wmo_id, fpp(iFile).profile_number);
                        cont = 1;
                        try
                            ncRfile = netcdf.open(fDO, 'WRITE');
                        catch 
                            fprintf(fid,'%s\n',['File format bad in netcdf: ' fDO]);
                            cont = 0;
                        end

                        %Ok if both files are properly formated lets copy the variables
                        if cont
                            for iVar = 1:varListLength
                                varId = netcdf.inqVarID(ncRfile,varList{iVar});
                                tR= netcdf.getVar(ncRfile, varId); 
                             
                                varId = netcdf.inqVarID(ncDfile,varList{iVar});
                                tD= netcdf.getVar(ncDfile, varId); 
                            
                                if any(size(pR) ~= size(pD))
                                    disp(sprintf('Difference in raw field of %s at cycle %i ', varList{iVar}, fpp(iFile).profile_number));
                                end
                                dropOne = 0;
                                getAndSetProfQC(ncDfile, ncRfile, sprintf('PROFILE_%S_QC',varList{iVar}), sprintf('%S_ADJUSTED',varList{iVar}),dropOne));

                                getAndSetNetCdfField(ncDfile, ncRfile, sprintf('%S_ADJUSTED',varList{iVar}), dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, sprintf('%S_ADJUSTED_QC',varList{iVar}), dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, sprintf('%S_ADJUSTED_ERROR',varList{iVar}), dropOne);
                                getAndSetNetCdfField(ncDfile, ncRfile, sprintf('%S_QC',varList{iVar}), dropOne);
                            end
                            
                            % go and fill the old R with the new D fields:
                            getAndSetNetCdfField(ncDfile, ncRfile, 'DATA_MODE', 0);
                            getAndSetNetCdfField(ncDfile, ncRfile, 'DATA_STATE_INDICATOR', 0);
                            getAndSetNetCdfField(ncDfile, ncRfile, 'DATE_UPDATE', 0);
                            
                            getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_COMMENT',0);
                            getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_EQUATION',0);
                            getAndSetNetCdfField(ncDfile, ncRfile, 'SCIENTIFIC_CALIB_COEFFICIENT',0);  

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
                        end
                        
                        try
                            netcdf.close(ncDfile);
                        end
                        try
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
