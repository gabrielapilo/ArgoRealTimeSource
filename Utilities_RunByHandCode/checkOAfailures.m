%edit here:
[fpp,dbdat] = getargo(5905190);  %float
j = 102;
; %profile number
win = 20; %plot window of adjacent profiles
%%

figure(1);clf
for i=max(j-win,1):min(j+win,length(fpp))
    plot(fpp(i).t_raw,fpp(i).p_calibrate,'b-')
    hold on
    axis ij
end
i=j
plot(fpp(i).t_raw,fpp(i).p_calibrate,'k-', 'linewidth',2)
vo=qc_apply(fpp(j).t_raw,fpp(j).t_qc);
vp=qc_apply(fpp(j).p_calibrate,fpp(j).p_qc);
plot(vo,vp,'g','linewidth',2)
title('Temperature')
grid

% for j=1:3:length(fpp)
figure(2);clf
for i=max(j-win,1):min(j+win,length(fpp))
    plot(fpp(i).s_raw,fpp(i).p_calibrate,'b')
    vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
    vp=qc_apply(fpp(i).p_calibrate,fpp(i).p_qc);
    hgoodall=plot(vo,vp,'r-');
    hold on
    axis ij
end
i=j
h1=plot(fpp(i).s_raw,fpp(i).p_calibrate,'k-','linewidth',2);
vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
vp=qc_apply(fpp(i).p_calibrate,fpp(i).p_qc);
hgood1=plot(vo,vp,'g','linewidth',2);
grid on
title('PSAL')
hleglines= [hgoodall(1),h1(1),hgood1(1)];
hleg = legend(hleglines,{'Good','This cycle', 'This cycle good'},'Location','southeast');

 

% for j=1:3:length(fpp)
figure(3);clf
for i=max(j-win,1):min(j+win,length(fpp))
    plot(fpp(i).s_raw,fpp(i).t_raw,'b')
    vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
    vp=qc_apply(fpp(i).t_raw,fpp(i).t_qc);
    hgoodall=plot(vo,vp,'r-');
    hold on
end
i=j
h1=plot(fpp(i).s_raw,fpp(i).t_raw,'k-','linewidth',2);
vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
vp=qc_apply(fpp(i).t_raw,fpp(i).t_qc);
hgood1=plot(vo,vp,'g','linewidth',2);
grid on
title('T/S')
hleglines= [hgoodall(1),h1(1),hgood1(1)];
hleg = legend(hleglines,{'Good','This cycle', 'This cycle good'},'Location','southeast');

figure(2)
%  end
%  
% [fpp(i).p_calibrate' double(fpp(i).p_qc)' fpp(i).t_raw' double(fpp(i).t_qc)' fpp(i).s_calibrate' double(fpp(i).s_qc)']
% 
% clf
%  for i=max(j-2,1):min(j+2,length(fpp))
% plot(fpp(i).cndc_raw,fpp(i).p_calibrate)
% hold on
% axis ij
%  end
%  i=j
%  plot(fpp(i).cndc_raw,fpp(i).p_calibrate,'r')
%  
 
% rejectpoints(5903955,273,{'s'},280,473)