% CHECK_PROFILE  Apply simple checks on new profile 
%
%DEV  First thing to add to this is a lenient T/S outlier check
%
% INPUT: 
%  fp     - profile structure
%
% Jeff Dunn  CMAR/BoM  Aug 2006
%
% USAGE: check_profile(fp);

function check_profile(fp)

rhed = ['CHECK_PROFILE: WMO ' num2str(fp.wmo_id)];

vv = qc_apply(fp.s_calibrate,fp.s_qc);
if any(vv<32 | vv>37)
   logerr(3,[rhed ', S profile range: ' num2str([min(vv) max(vv)])]);
end

vv = qc_apply(fp.t_raw,fp.t_qc);
if any(vv<-3 | vv>35) | (fp.lat(1)>-35 & any(vv<-1))
   logerr(3,[rhed ', T profile range: ' num2str([min(vv) max(vv)])]);
end

if fp.surfpres>100
   logerr(3,[rhed ', Surface Pressure: ' num2str(fp.surfpres)]);
end

return
%---------------------------------------------------------------------------
