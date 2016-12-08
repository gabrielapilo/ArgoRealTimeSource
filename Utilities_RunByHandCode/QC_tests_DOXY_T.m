% qcOT=QC_tests_DOXY_T(coreT,DT,dep)
% this is designed to compare Doxy T to the core CTD T and if the
% difference is greater than -.05, reject the doxy value.  
% this critical value may change after testing
%
% usage: qcOT=QC_tests_DOXY_T(coreT,DT,dep)
% where coreT=fp.t_oxygen (sampled with the oxygen profile by the primary ctd)
%  and DT=fp.oxyT_raw and dep=fpp_oxygen from core ctd, 
%  and output is a QC array for doxy T = fp.oxyT_qc
%
%
% author Ann Thresher, Jan 2016
%

function qcOT=QC_tests_DOXY_T(coreT,DT,dep)

qcOT=zeros(size(DT));

if length(coreT) ~= length(DT)
    return
end

df=abs(coreT-DT);
kk=find(df>0.9 & dep>10);

if ~isempty(kk)
    clf
    plot(coreT,'r-')
    hold on
    plot(DT,'b-')
    range(df)
   
    qcOT(kk)=3;
end

return


