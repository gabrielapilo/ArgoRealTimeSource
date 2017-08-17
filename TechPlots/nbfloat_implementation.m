function [] = nbfloat_implementation( input_file , new_number, outputfile )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

fid = fopen(input_file);
c = textscan(fid,'%s','delimiter','\n');
fclose(fid);
c = c{:};


for index = 1 : length(c)
    if length(strfind(char(c(index)),'nbfloat'))
        c(index) = strrep(c(index),'nbfloat', new_number );
    end
end

%write it out

fid = fopen([outputfile '.html'],'w');
for a = 1:length(c)
    fprintf(fid,'%s\n',c{a});
end
fclose(fid);

end

