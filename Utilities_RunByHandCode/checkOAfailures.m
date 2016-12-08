figure(1);clf
for i=max(j-2,1):min(j+10,length(fpp))
    plot(fpp(i).t_raw,fpp(i).p_calibrate)
    hold on
    axis ij
end
i=j
plot(fpp(i).t_raw,fpp(i).p_calibrate,'ko')
vo=qc_apply(fpp(j).t_raw,fpp(j).t_qc);
vp=qc_apply(fpp(j).p_calibrate,fpp(j).s_qc);
plot(vo,vp,'g')
title('Temperature')
grid

% for j=1:3:length(fpp)
figure(2);clf
for i=max(j-10,1):min(j+5,length(fpp))
    for k=1:length(fpp)
        if fpp(k).profile_number == i
            pn=k;
        end
    end
    plot(fpp(pn).s_raw,fpp(pn).p_calibrate,'b')
    vo=qc_apply(fpp(pn).s_calibrate,fpp(pn).s_qc);
    vp=qc_apply(fpp(pn).p_calibrate,fpp(pn).s_qc);
    plot(vo,vp,'-.')
    hold on
    axis ij
end
i=j
for k=1:length(fpp)
    if fpp(k).profile_number == i
        pn=k;
    end
end
plot(fpp(pn).s_calibrate,fpp(pn).p_calibrate,'k')
vo=qc_apply(fpp(pn).s_calibrate,fpp(pn).s_qc);
vp=qc_apply(fpp(pn).p_calibrate,fpp(pn).s_qc);
plot(vo,vp,'ro')
grid on
title('PSAL')
 
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