% web_plot_generation
%
% this has been cut from web_profile_plot so we can just regenerate the
% plots without touching the web pages/tables.

function web_plot_generation(fp,db)


global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if isempty(fp) | isempty(fp.lat)
   return
end

fwmo = num2str(fp.wmo_id);
pn = fp.profile_number;

if ispc
    fdir = [ARGO_SYS_PARAM.web_dir 'floats\' fwmo];
    if ~exist(fdir,'dir'); system(['mkdir ' fdir '; chmod -f ugo+rx ' fdir]); end
    fnm =  [fdir '\profile_' num2str(pn)]
else
    fdir = [ARGO_SYS_PARAM.web_dir 'floats/' fwmo];
    if ~exist(fdir,'dir'); system(['mkdir ' fdir '; chmod -f ugo+rx ' fdir]); end
    fnm =  [fdir '/profile_' num2str(pn)];
end


% -------------- Generate the plot file

labels = {'Temperature ^oC','Salinity psu'};

H = figure('Position',[10,100,900,700]);
clf;

%oxygen floats:
if isfield(fp,'oxy_raw')
     axes('position',[.08 .08 .25 .9])
      vr = fp.oxy_raw;
      vq = qc_apply(vr,fp.oxy_qc);
      if db.subtype==1006 | db.subtype==1020 |  db.subtype==1030 % this has its own p t and s scales
          pp = fp.p_oxygen;  %no qc for this variable
      else
          pp = qc_apply(fp.p_calibrate,fp.p_qc);
      end
   nk=find(isnan(pp));
   if(length(nk)==length(fp.p_calibrate))
       pp=fp.p_calibrate;
   end
      
   if ~isempty(pp) && ~isempty(vr)
       kk=find(~isnan(vq));
       if(isempty(kk))
           plot(vr,pp,'r-')
       else
          plot(vq,pp,'k-');
       end
          hold on;
          ax = axis;
          axis ij
          if(~isnan(pp(1)))
              ax(4) = pp(1)+50;
          end
          yinc = (ax(3)-ax(4))/20;
          xy0 = [ax(1)+(ax(2)-ax(1))/20 ax(4)+yinc]; 
          if sum(isnan(vq))~=sum(isnan(vr))
         % Some QC carried out, having got sensible axis limits from the clean 
         % plot, clobber it with dirty profile and overlay clean profile again,
         % to leave the dirty bits sticking out from behind the clean profile.
             hold off;
             plot(vr,pp,'rx--');      
             hold on;
             plot(vq,pp,'k-');
             text(xy0(1),xy0(2)+yinc,'red = bad','color','r');
          else
              plot(vr,pp,'rx--');      
              hold on;          
              ax = axis;
              text(xy0(1),xy0(2)+yinc,'red = bad','color','r');
          end
          aa=plot(vq,pp,'go','markersize',3);
          axis(ax)
          axis ij
        text(xy0(1),xy0(2)-1750,'oxygen')
   end
end

% Want to keep NaNs where missing profiles or gaps in profiles. Better to see
% gaps rather than interpolate through them and be deluded.
% Also, P has been screened, so no need to test for inversions.   

for var = 1:2
    if var==1
        if isfield(fp,'oxy_raw')
            axes('position',[.4 .08 .25 .9])
        else
            axes('position',[.08 .08 .4 .9])
        end
        vr = fp.t_raw;
        vq = qc_apply(vr,fp.t_qc);
    else
        if isfield(fp,'oxy_raw')
            axes('position',[.7 .08 .25 .9])
        else
            axes('position',[.52 .08 .4 .9])
        end
        %      axes('position',[.1 .52 .8 .4])
        vr = fp.s_raw;
        vq = qc_apply(vr,fp.s_qc);
    end
    
    pp = qc_apply(fp.p_calibrate,fp.p_qc);
    nk=find(isnan(pp));
    if(length(nk)==length(fp.p_calibrate))
        pp=fp.p_calibrate;
    end
    
    if ~isempty(pp) && ~isempty(vr)
        kk=find(~isnan(vq));
        if(isempty(kk))
            plot(vr,pp,'r-')
        else
            plot(vq,pp,'k-');
        end
        hold on;
        ax = axis;
        axis ij
        if(~isnan(pp(1)))
            ax(4) = pp(1)+50;
        end
        yinc = (ax(3)-ax(4))/20;
        xy0 = [ax(1)+(ax(2)-ax(1))/20 ax(4)+yinc];
        
        if sum(isnan(vq))~=sum(isnan(vr))
            % Some QC carried out, having got sensible axis limits from the clean
            % plot, clobber it with dirty profile and overlay clean profile again,
            % to leave the dirty bits sticking out from behind the clean profile.
            hold off;
            plot(vr,pp,'rx--');
            hold on;
            plot(vq,pp,'k-');
            text(xy0(1),xy0(2)+yinc,'red = bad','color','r');
        else
            plot(vr,pp,'rx--');
            hold on;
            ax = axis;
            text(xy0(1),xy0(2)+yinc,'red = bad','color','r');
        end
        aa= plot(vq,pp,'go','markersize',3);
        axis(ax);
        axis ij
        
        if var==2
            text(xy0(1),xy0(2)-1750,'salinity')
            if ~isempty(fp.c_ratio) && fp.c_ratio~=1
                vc = qc_apply(fp.s_calibrate,fp.s_qc);
                text(xy0(1),xy0(2),['c ratio ' num2str(fp.c_ratio)],'color','b');
                plot(vc,pp,'bx--');
            else
                text(xy0(1),xy0(2),'No cal applied','color','b');
            end
        else
            text(xy0(1),xy0(2)-1750,'temperature')
        end
        %ylabel('Depth - m')
        %xlabel(labels{var},'fontsize',12)
    end
end

axis ij
drawnow


if(ispc)
    print('-dtiff',fnm);
else
    my_save_fig([fnm],'clobber');
end

system(['chmod -f 664 ' fnm '*']);


