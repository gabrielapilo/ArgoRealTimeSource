% compute GDAC/GTS delays
%
%  This  routine compares the creation date of the tesacs in the textfiles
%  directory with the julian date of the comparable profile from the netcdf
%  directory.  The resulting delay is tabled for each float that reports in a given
%  month.

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
  
aic=ARGO_ID_CROSSREF;
% mm=input('month of interest:')
mm=7
% yy=input('year of interest:')
yy=2012
fid=fopen(['GTSdelaysAugust2012.txt'],'w');
for i=1:length(aic)
    wmoid=aic(i,1)
    tdir=[ARGO_SYS_PARAM.root_dir '/textfiles/' num2str(wmoid) '/*.tesac'];
    ndir=[ARGO_SYS_PARAM.root_dir '/netcdf/' num2str(wmoid) '/'];
    [fpp,dbdat]=getargo(wmoid);
    a=dirc(tdir);
    [m,n]=size(a);
    pn=[];
    
    for j=1:m
        dashy=strfind(a{j,1},'_');
        dott=strfind(a{j,1},'.');
        
        pn(j)=str2num(a{j,1}(dashy+1:dott-1));
    end
    for j=1:length(fpp)
        if ~isempty(fpp(j).jday)
            daten=gregorian(fpp(j).jday(1));
            if (yy==daten(1) & mm==daten(2))
                pp=j;
                kk=find(pn==pp);
                if ~isempty(kk)
                    sdate=a{kk,4};
                    mon=month(sdate);
                    dom=day(sdate);
                    yyyy=year(sdate);
                    hr=hour(sdate);
                    minu=minute(sdate);
                    jjul=julian([yyyy mon dom hr minu 0])-(10/24);
                    delay=jjul-fpp(j).jday(1);
                    fprintf(fid,'%i %i %12.3f %12.3f %4.2f\n',wmoid,j,fpp(j).jday(1),jjul,delay*24);
                end
            end
        end
    end
end
fclose(fid)                   
                
            
    