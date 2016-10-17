% TSPLOTS  Create t/s plots for one float.
%  
% INPUT: fpp - struct array for the float
%
% OUTPUT:
%   Files   TS_WMO.tif
%
% AUTHOR: Rebecca Cowley CMAR March 2007 
%
% CALLED BY:  Argo main program. Can be used standalone
% 
% USAGE: tsplots(fpp)

function tsplots(fpp)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

fwmo = num2str(fpp(1).wmo_id);
if ispc
fpth = [ARGO_SYS_PARAM.web_dir 'floats\' fwmo '\'];
else
fpth = [ARGO_SYS_PARAM.web_dir 'floats/' fwmo '/'];
end

nprof = length(fpp);
if nprof>256
    cc=jet(floor((nprof/ceil(nprof/256))) +1);
else
    cc= jet(nprof);
end
H = figure(8);
clf
set(H,'PaperPosition',[0 0 4.5 3])      % Controls final image size
hold on

for j=1:nprof;
    if nprof>256
        k=floor(j/ceil(nprof/256))+1;
    else
        k=j;
    end
    s = qc_apply(fpp(j).s_calibrate,fpp(j).s_qc);
    p = qc_apply(fpp(j).p_calibrate,fpp(j).p_qc);
    t = qc_apply(fpp(j).t_raw,fpp(j).t_qc);

    if length(s) > 0 & ~all(isnan(s))
        pt = sw_ptmp(s,t,p,0.);
        figure(8),hold on
        c(j)=plot(s,pt,'.-');
        set(c(j),'Color',cc(k,:))
    end
end
    
xlabel('Salinity')
ylabel(texlabel('Potential Temperature ^oC'))
set(gca,'Fontsize',8)
title(['Argo ' fwmo ' T-S profiles'],'fontsize',10)

fnm = [fpth 'ts_' fwmo];
if(ispc)
    print('-dtiff',fnm);
else
    my_save_fig(fnm,'clobber')
end

system(['chmod -f 664 ' fpth '*if']);
 
return 
