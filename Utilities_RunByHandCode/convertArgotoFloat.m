%convertArgo_desc.mat to float structure
%  
% take the /home/argo/ArgoDM/cron_jobs/gdac_mirror/argo_desc.mat file and turn it into the
% Indian float structures, including all available metadata!!! (but not
% technical data).  though it could be modified to convert the technical
% files as well if they exist.
%
% usage:  convertArgotoFloat
% Note: countrycode must be set before you run this : 9=india

%convertArgotoFloat

global ARGO_SYS_PARAM ARGO_ID_CROSSREF
set_argo_sys_params

load /home/argo/ArgoDM/cron_jobs/gdac_mirror/argo_desc.mat;
load /home/argo/ArgoRT/IndianArgoRT/newfloatstr.mat
load /home/argo/ArgoRT/IndianArgoRT/newfloatstrO2_35.mat

if ispc
ARGO_SYS_PARAM.root_dir = 'D:\ArgoRT\KoreanArgoRT\'
else
ARGO_SYS_PARAM.root_dir = '/home/argo/ArgoRT/KoreanArgoRT/'
end

if(isempty(spreads))
    spreads=1
end

ll=find(data_centre_id==country_code);
%wmosCC=unique(wmo_id(ll));
wmosCC=wmos;

dc= [{'aoml'}
    {'bodc'}
    {'coriolis'} 
    {'csiro'}
    {'gts'}
    {'jma'}
    {'meds'}
    {'csio'}
    {'incois'}
    {'kma'}
    {'kordi'}]
data_path=['/home/argo/ArgoDM/cron_jobs/gdac_mirror/' dc{country_code}];
j1950 = julian([1950 1 1 0 0 0]);
jul0 = julian(0,1,0);

if(spreads)
    % initialize xls spreadsheet matrix:
 mspreadsheet{1,1}='column1';
 mspreadsheet{1,30}='endrow';
 mspreadsheet{1,2}='live';
 mspreadsheet{1,8}=' ';
 mspreadsheet{1,9}=' ';
 mspreadsheet{1,10}=' ';
 mspreadsheet{1,11}='Incois';
 mspreadsheet{1,12}='846';
 mspreadsheet{1,13}='SBE-41';
 mspreadsheet{1,14}=' ';
 mspreadsheet{1,15}=' ';
 mspreadsheet{1,16}=' ';
 mspreadsheet{1,17}=' ';
 mspreadsheet{1,19}='9.37';
 mspreadsheet{1,20}='6.94';
 mspreadsheet{1,21}='8.06';
 mspreadsheet{1,23}='15';
 mspreadsheet{1,26}='0';
% mspreadsheet{1,27}='webb'
 mspreadsheet{1,28}='4';
 mspreadsheet{1,29}=' ';
end

for i=1:length(wmosCC)
    
    % get metadata file and start to populate .csv file
    % get filenames from mat file
    % sort filenames for each float
    % for each file, populate float structure from nc files
        %  if no mat file, copy empty structure over
        %  fill structure from each profile in sequence
    % generate plots and web tables for floats
    if ispc
        metafile=[data_path '\' num2str(wmosCC(i)) '\' num2str(wmosCC(i)) '_meta.nc'];
    else
        metafile=[data_path '/' num2str(wmosCC(i)) '/' num2str(wmosCC(i)) '_meta.nc'];
    end
    
if(spreads)
    spreadsheet(i,:)=mspreadsheet;
    spreadsheet{i,3}=getnc(metafile,'LAUNCH_DATE')';
    spreadsheet{i,4}=num2str(getnc(metafile,'LAUNCH_LATITUDE'));
    spreadsheet{i,5}=num2str(getnc(metafile,'LAUNCH_LONGITUDE'));
    model=getnc(metafile,'PLATFORM_MODEL');
    if(strmatch('provor',lower(model)'))
        spreadsheet{i,27}='provor';
        spreadsheet{i,28}='1';
    else
        spreadsheet{i,27}='webb';
    end
    argosID=getnc(metafile,'PTT')';
    spreadsheet{i,6}=deblank(argosID);
    spreadsheet{i,7}=num2str(wmosCC(i));
    sbe_ser_no=getnc(metafile,'SENSOR_SERIAL_NO')';
    spreadsheet{i,14}=deblank(sbe_ser_no(:,1)');
    spreadsheet{i,18}=num2str(getnc(metafile,'TRANS_REPETITION'));
    spreadsheet{i,22}=num2str(getnc(metafile,'PARKING_PRESSURE'));
    spreadsheet{i,24}=num2str(getnc(metafile,'DEEPEST_PRESSURE'));
    deploy_plat=getnc(metafile,'DEPLOY_PLATFORM')';
    spreadsheet{i,25}=deblank(deploy_plat);
end
if ispc
    filetraj=[data_path '\' num2str(wmosCC(i)) '\' num2str(wmosCC(i)) '_traj.nc'];
else
    filetraj=[data_path '/' num2str(wmosCC(i)) '/' num2str(wmosCC(i)) '_traj.nc'];
end
    if(exist(filetraj))
        webbid=getnc(filetraj,'INST_REFERENCE');
        ff=strfind(webbid','SBE');
if(spreads)
    spreadsheet{i,8}=deblank(webbid(ff+3:end)');
end
        cyclenoT=getnc(filetraj,'CYCLE_NUMBER');
        juldT=getnc(filetraj,'JULD')+j1950;
        totallatT=getnc(filetraj,'LATITUDE');
        totallonT=getnc(filetraj,'LONGITUDE');
        posacc=getnc(filetraj,'POSITION_ACCURACY');
    end
    
    kk=find(wmo_id==wmosCC(i));
if ispc
    matfile=[ARGO_SYS_PARAM.root_dir 'matfiles\float' num2str(wmosCC(i)) '.mat'];
else
    matfile=[ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmosCC(i)) '.mat'];
end
    
    if(~exist(matfile))
        float=newfloatstr;
    else
        load (matfile)
    end
    startc=1;
    np=1;
    for j=1:length(kk)
if ispc
      fileprof=[data_path '\' num2str(wmosCC(i)) '\profiles\' file_name{kk(j)}]   
else
      fileprof=[data_path '/' num2str(wmosCC(i)) '/profiles/' file_name{kk(j)}]
end  
        %check for oxygen floats:
        if(j==1 | isempty(float(np).jday))
            try
                oxy=getnc(fileprof,'DOXY');
                if(~isempty(oxy))
                    float=newfloatstrO2_35;
                end
            end
        end          
       
        fn=file_name{kk(j)};
        np=str2num(fn(end-5:end-3));

        if(~exist(filetraj))
            %need to set lat and long from profile:
            cycleno=getnc(fileprof,'CYCLE_NUMBER');
            juld=getnc(fileprof,'JULD')+j1950;
            totallat=getnc(fileprof,'LATITUDE');
            totallon=getnc(fileprof,'LONGITUDE');
% can't determine this:            posacc=getnc(fileprof,'POSITION_ACCURACY');
        else
            cycleno=cyclenoT;
            juld=juldT;
            totallat=totallatT;
            totallon=totallonT;            
        end
        gg=find(cycleno==np);
        if(isempty(gg))
            cycleno=getnc(fileprof,'CYCLE_NUMBER');
            juld=getnc(fileprof,'JULD')+j1950;
            totallat=getnc(fileprof,'LATITUDE');
            totallon=getnc(fileprof,'LONGITUDE');
        end
        gg=find(cycleno==np);
        
        if(startc==1)  %first time through the float, check for cycle 0
            if(np<=0)
                %must offset for zero profiles becuase matlab won't accept a 0
                %index
                offs=1;
            else
                offs=0;
            end
            np=np+offs;
            startc=2;
        end
        float(np).profile_number=np-offs;
        float(np).wmo_id=wmosCC(i);
        float(np).lat(1:length(gg))=totallat(gg);
        float(np).lon(1:length(gg))=totallon(gg);
        float(np).jday(1:length(gg))=juld(gg);
    if(isempty(float(np).jday) | isnan(float(np).jday(1)))
        float(np).lat(1)=getnc(fileprof,'LATITUDE');
        float(np).lon(1)=getnc(fileprof,'LONGITUDE');
        float(np).jday(1)=getnc(fileprof,'JULD')+j1950;
    end
        float(np).position_accuracy(1:length(gg))=posacc(gg);
        float(np).SN=str2num(webbid(ff+3:end)');
    if(isempty(gg) | isnan(juld(gg(1))))
        float(np).datetime_vec=gregorian(getnc(fileprof,'JULD')+j1950);
    else
        float(np).datetime_vec=gregorian(juld(gg));
    end
        float(np).maker=1;
        float(np).subtype=4;
        temp=getnc(fileprof,'TEMP');
        temp=revordArray(temp);
        tempqc=str2num(getnc(fileprof,'TEMP_QC'));
        tempqc=revordArray(tempqc);
        sal=getnc(fileprof,'PSAL');
        sal=revordArray(sal);
        salqc=str2num(getnc(fileprof,'PSAL_QC'));
        salqc=revordArray(salqc);
        pres=getnc(fileprof,'PRES');
        pres=revordArray(pres);
        presqc=str2num(getnc(fileprof,'PRES_QC'));
        presqc=revordArray(presqc);
        
        float(np).npoints=length(temp);
        float(np).t_raw=temp;
        float(np).t_qc=tempqc;
        float(np).s_raw=sal;
        float(np).s_qc=salqc;
        float(np).p_raw=pres;
        float(np).p_qc=presqc;
        
        if(isfield(float(np),'oxy_raw'))
            oxy=getnc(fileprof,'DOXY');
            oxy=revordArray(oxy);
            oxy_qc=getnc(fileprof,'DOXY_QC');
            oxy_qc=revordArray(oxy_qc);
            float(np).oxy_raw=oxy;
            float(np).oxy_qc=oxy_qc;

            oxy_t=getnc(fileprof,'TEMP_DOXY');
            if(~isempty(oxy_t))
                oxy_t=revordArray(oxy_t);
                oxy_tqc=getnc(fileprof,'TEMP_DOXY_QC');
                oxy_tqc=revordArray(oxy_tqc);
                float(np).oxyT_raw=oxy_t;
                float(np).oxyT_qc=oxy_tqc;
            end
% not done yet: 
%             oxy_cal=getnc(fileprof,'DOXY_ADJUSTED');
%             if(~isempty(oxy_cal))
%                 oxy_cal=revordArray(oxy_cal);
%                 oxy_calqc=getnc(fileprof,'DOXY_ADJUSTED_QC');
%                 oxy_calqc=revordArray(oxy_calqc);
%             end
        end
        
        sal_cal=getnc(fileprof,'PSAL_ADJUSTED');
        if(~isempty(sal_cal))
            sal_cal=revordArray(sal_cal);
            sal_calqc=str2num(getnc(fileprof,'PSAL_ADJUSTED_QC'));
            sal_calqc=revordArray(sal_calqc);
            float(np).s_calibrate=sal_cal;
            if(~isempty(sal_calqc))
                float(np).s_qc=sal_calqc;
            end
        end
        p_cal=getnc(fileprof,'PRES_ADJUSTED');
        if(~isempty(p_cal))
            p_cal=revordArray(p_cal);
            p_calqc=str2num(getnc(fileprof,'PRES_ADJUSTED_QC'));
            p_calqc=revordArray(p_calqc);
            float(np).p_calibrate=p_cal;
            if(~isempty(p_calqc))
                float(np).p_qc=p_calqc;
            end
        end

        temp_cal=getnc(fileprof,'TEMP_ADJUSTED');
        if(~isempty(temp_cal))
            temp_cal=revordArray(temp_cal);
            temp_calqc=str2num(getnc(fileprof,'TEMP_ADJUSTED_QC'));
            temp_calqc=revordArray(temp_calqc);
            float(np).t_calibrate=temp_cal;
            if(~isempty(temp_calqc))
                float(np).t_qc=temp_calqc;
            end
        end
        
    end
    
    save  (matfile,'float');
end

if(spreads)
    %sort spreadsheet and fill launch order field:
    for b=1:length(spreadsheet)
        hh(b)=str2num(spreadsheet{b,3});
    end
    [ss,ind]=sort(hh);

    spreadsheetfinal=spreadsheet;

    for b=1:length(ind)
        spreadsheetfinal(b,:)=spreadsheet(ind(b),:);
    end

    %fill launch order field:
    for i=1:length(ind)
        spreadsheetfinal{i,10}=num2str(i);
    end

    %write spreadsheet to file
if ispc
    outfile='D:\ArgoRT\IndianArgoRT/prelimmaster.csv'
else
    outfile='/home/argo/ArgoRT/IndianArgoRT/prelimmaster.csv'
end

    
    fid=fopen(outfile,'w')
    for i=1:length(ind)
        for j=1:30
            kk=find(double(spreadsheetfinal{i,j})==0);
            if(~isempty(kk))
                spreadsheetfinal{i,j}(kk)=' ';
            end
        end
        fprintf(fid,'%s,',spreadsheetfinal{i,:});
        fprintf(fid,'\n');
    end
    fclose(fid)
end
%[status,message]=xlswrite('/home/argo/ArgoRT/IndianArgoRT/prelimmaster.csv',spreadsheetfinal);

    
