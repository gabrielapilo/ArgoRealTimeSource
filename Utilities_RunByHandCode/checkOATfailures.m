 clf
 for i=max(j-2,1):min(j+2,length(fpp))
plot(fpp(i).t_raw,fpp(i).p_calibrate)
hold on
axis ij
 end
 i=j
 plot(fpp(i).t_raw,fpp(i).p_calibrate,'r')


% for j=1:3:length(fpp)
clf
for i=max(j-2,1):min(j+2,length(fpp))
    i=i
    for k=1:length(fpp)
        if fpp(k).profile_number == i
            pn=k;
        end
    end
    vo=qc_apply(fpp(pn).t_raw,fpp(pn).t_qc);
    vp=qc_apply(fpp(pn).p_calibrate,fpp(pn).t_qc);
    plot(vo,vp,'b')
    hold on
    axis ij
end
i=j
for k=1:length(fpp)
    if fpp(k).profile_number == i
        pn=k;
    end
end
plot(fpp(pn).t_raw,fpp(pn).p_calibrate,'r')
vo=qc_apply(fpp(pn).t_raw,fpp(pn).t_qc);
vp=qc_apply(fpp(pn).p_calibrate,fpp(pn).t_qc);
plot(vo,vp,'g')
grid on
 
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