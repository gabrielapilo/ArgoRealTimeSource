% display_inversions
% This program reads the text file output from assess_density_test_global
% and plots the profiles so you can identify the severity fo the density
% inversions.


close('all')   %start afresh...

area = ([{'N_Atlantic'} {'S_Atlantic'}  {'Indian_Ocean'}  {'N_Pacific'} {'S_Pacific'}  {'Southern_Ocean'} {'Tasman_Sea'}])
for i=1 %:7
%     filef=['/home/argo/ArgoRT/DfileHighmaxdensity' area{i} '.txt'];
%         filef=['/home/argo/ArgoRT/gdacdensityfailures' area{i} '.txt'];

        fid=fopen(filef)
        k=0
        a=textscan(fid,'%f,%f,%f,%s');
        f=a{4};
        lat=a{1};
        lon=a{2};
        
        for j=1:length(f)
            file=f{j};
            if(j>1)
                plot(lon(j-1),lat(j-1),'rx')
            end
            unders=strfind(file,'_');
            pn=str2num(file(unders+1:unders+3));
            s1=sprintf('%3.3i',pn-1);
            s3=sprintf('%3.3i',pn+1);
            file1=[file(1:unders) s1 file(unders+4:end)];
            file3=[file(1:unders) s3 file(unders+4:end)];
            fid2=fopen(file,'r');
            pcal=getnc(file,'PRES_ADJUSTED');
            pcqc=getnc(file,'PRES_ADJUSTED_QC');
            pcqc=str2num(pcqc);
            pcal=qc_apply(pcal,pcqc);
            vt=getnc(file,'TEMP_ADJUSTED');
            vtqc=str2num(getnc(file,'TEMP_ADJUSTED_QC'));
            vt=qc_apply(vt,vtqc);
            vs=getnc(file,'PSAL_ADJUSTED');
            vsqc=str2num(getnc(file,'PSAL_ADJUSTED_QC'));
            vs=qc_apply(vs,vsqc);
            pt = sw_ptmp(vs,vt,pcal,0);
            vv = sw_pden(vs,pt,pcal,0)-1000;
            
            dd=diff(vv);
            dd=[0
                dd];
            figure(1)
            clf
            set(gca,'Position',[0.13 0.11 0.775 0.815])
            plot(vv,pcal,'r-')
            hold on
            axis ij
            title ('density ')
            figure(2)
            
            clf
            set(gcf,'PaperPosition',[0.25 2.5 8 6]);
            sal1=getnc(file1,'PSAL');
            t1=getnc(file1,'TEMP');
            sal3=getnc(file3,'PSAL');
            t3=getnc(file3,'TEMP');
            hold on
            plot(sal1,t1,'b-');
            plot(sal3,t3,'g-')
            plot(vs,vt,'r-');
            title('t/s')
            %         axis ij
            [pcal vt vs dd ]
            range(dd)
            figure(3)
            plot(lon(j),lat(j),'bx')
            hold on
            gebco
            axis([min(lon) max(lon) min(lat) max(lat)])
            file=file
%             file=fgetl(fid);
        end
end
    fclose(fid);


