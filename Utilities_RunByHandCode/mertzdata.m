
a=length(float)

for i=1:a
    vv=['float' num2str(i) '=float(' num2str(i) ');']
    eval(vv)
    v2=sprintf('%s%3.3i%s%s%i%s','save(''/home/argo/ArgoRT/7900331_',i,...
        '.mat.new'',','''float',i,''',''-v6''',')');
    eval(v2)
    fn=['float',num2str(i)];
    pno=sprintf('%3.3i',i);
    system(['cat /home/argo/ArgoRT/tom.txt | mail -s" data for profile ' fn ' "  -a "/home/argo/ArgoRT/7900331_',...
        pno,'.mat.new" rebecca.cowley@csiro.au esmee.vanwijk@csiro.au esmee_van@aurora.aad.gov.au steve.rintoul@aurora.aad.gov.au'])
end
