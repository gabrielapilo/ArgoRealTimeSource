%   qc = pressure qc (start as all '1') (see sample data below)
%   pp = pressure DECREASING (change signs if you want to use pressure INCREASING)

%   find pressure inversions:
    kk=find(diff(pp)>0);
    
   for jj=1:length(kk)
       for l=kk(jj)-1:kk(jj)+1
        if(pp(l+1)-pp(l-1)<0)
            test2=abs(pp(l)-(pp(l+1)+pp(l-1))/2) - (pp(l+1)-pp(l-1)/2);
            if test2>0 
                qc(l)=4;
            end
        end
       end
   end
%[modified_qc pres current_qc]   
data=[
      1   1979      1
      1   1899      1
      1   1800      1
      1   1700      1
      1   1599      1
      1   1499      1
      1   1399      1
      1   1299      1
      1   1200      1
      1   1100      1
      1    999      1
      1    899      1
      1    799      1
      1    700      1
      1    649      1
      1    599      1
      1    550      1
      1    500      1
      1    480      1
      1    459      1
      1    439      1
      1    419      1
      1    399      1
      1    380      1
      1    359      1
      1    350      1
      1    339      1
      1    329      1
      1    319      1
      1    309      1
      1    299      1
      1    289      1
      1    280      1
      1    270      1
      1    260      1
      1    249      1
      1    239      1
      4    639      4
      1    220      1
      1    210      1
      1    200      1
      1    189      1
      1    179      1
      1    169      1
      1    159      1
      1    149      1
      4    139      1
      4     39      1
      1    119      4
      1    109      4
      1     99      4
      1     94      4
      1     89      4
      1     85      4
      1     79      4
      1     75      4
      1     70      4
      1     64      4
      1     60      4
      1     55      4
      1     50      4
      1     45      4
      1     40      4
      1     35      1
      1     29      1
      1     25      1
      1     19      1
      1     14      1
      1      9      1
      1      6      1
      1      4      1

