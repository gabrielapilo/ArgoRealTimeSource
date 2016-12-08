%split_argos_downloads
%
% this script requests a file name and then reads and splits the file into
% individual profile sections.  This will be used to split the 'lost' flaot
% data into parseable bits fo strip_argos_msg can recover the data.  

filen=input('enter the file name to be split:','s')


fid=fopen(filen,'r');
daten_old=[];
gg=fgetl(fid);
j=219;
fid2=fopen(['33370_' num2str(j) '.txt'],'w')

while gg~=-1

    if isempty(strmatch('    ',gg)) & length(gg)>23
        daten_new=datenum(gg(25:34));
        if isempty(daten_old)
            daten_old=daten_new;
        end
    else
        try
            dn=[];
            dn=datenum(gg(7:16));
        end
        if ~isempty(dn) & isempty(strfind(gg,'033370'))
            daten_new=dn;
        end
    end
    
    if (daten_new-daten_old)<3
        fprintf(fid2,'%s\n',gg);
    else
        daten_old=daten_new
        fclose(fid2);
        j=j+1
        fid2=fopen(['33370_' num2str(j) '.txt'],'w')
        fprintf(fid2,'%s\n',gg);
    end
    
    gg=fgetl(fid);
end
