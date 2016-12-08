% VIEW_PROFILES  List or plot profiles selected from one float.  
%
% INPUT: wmo - WMO id
%    reads matfile for this float
%
% OUTPUT - generates plots and/or listings
%
% AUTHOR: Jeff Dunn CMAR/BoM  Nov 2006
%
% CALLED BY:  standalone use only
% 
% USAGE: view_profs(wmo)

function view_profs(wmo)

global ARGO_SYS_PARAM

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo)];
if ~exist([fnm '.mat'],'file')
   error(['Cannot find ' fnm '.mat'])
end

[fpp,dbdat] = getargo(wmo);

npp = length(fpp);
np = npp-1;

disp(['There are ' num2str(npp) ' profiles']);
disp('Commands are not case sensitive.  Examples: ')
disp('  p7 - Plot profile 7')
disp('  L7 - List profile 7')
disp('  p  - plot next profile. If no previous, then plot last in file')
disp('  L  - list   "     "        "       "       "        "   ')
disp('  q  - quit')

cmd = lower(input(' : ','s'));

while ~strcmp(cmd,'q')
   if isempty(cmd)
      disp('No command given - doing nothing!')
      cmd = '?';      
   elseif length(cmd)>1
      np = eval(cmd(2:end));
      if np>npp
	 disp(['Only ' num2str(npp) ' profiles in file']);
	 np = npp;
      end
   else
      if np<npp
	 np = np+1;
      end
   end
   fp = fpp(np);
   
   pn = fp.profile_number;
   disp([num2str(np) 'th profile has profile_number ' num2str(pn)]);
   
   if strcmp(cmd(1),'p')
   
      labels = {'Temperature ^oC','Salinity psu'};
      figure(10);
      clf;
      orient tall;

      % Want to keep NaNs where missing profiles or gaps in profiles. Better to see
      % gaps rather than interpolate through them and be deluded.
      % Also, P has been screened, so no need to test for inversions.
      
      for var = 1:2      
	 if var==1
	    axes('position',[.1 .08 .8 .4])
	    vr = fp.t_raw;
	    vq = qc_apply(vr,fp.t_qc);
	 else
	    axes('position',[.1 .52 .8 .4])
	    vr = fp.s_raw;
	    vq = qc_apply(vr,fp.s_qc);
	 end

	 pp = qc_apply(fp.p_calibrate,fp.p_qc);

	 plot(vq,pp,'k-');
	 hold on;
	 ax = axis;
	 axis ij
	 ax(4) = pp(1)+50;
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
	 end
	 plot(vq,pp,'go','markersize',3);
	 axis(ax);
	 
	 if var==2
	    if ~isempty(fp.c_ratio) & fp.c_ratio~=1
	       vc = qc_apply(fp.s_calibrate,fp.s_qc);
	       text(xy0(1),xy0(2),['c ratio ' num2str(fp.c_ratio)],'color','b');
	       plot(vc,pp,'bx--');
	    else
	       text(xy0(1),xy0(2),'No cal applied','color','b');
	    end	 
	 end
      end
      
   elseif strcmp(cmd(1),'?')
      % dud command - do nothing
      
   elseif isempty(fp.p_raw)
      disp('Empty profiles')
      
   else
      
      vv = [fp.p_calibrate(:) double(fp.p_qc(:)) ...
	    fp.t_raw(:) double(fp.t_qc(:)) ...
	    fp.s_raw(:) double(fp.s_qc(:))];
      fstr = '%6.1f %1d  %5.2f %1d  %5.2f %1d';
      vstr = ' Pcal QC  Traw QC  Sraw QC'; 
      if fp.c_ratio~=1
	 vv = [vv fp.s_calibrate(:)];
	 fstr = [fstr '  %5.2f'];
	 vstr = [vstr '   Scal'];
      end
      if dbdat.oxy && ~isempty(fp.oxy_raw)
	 vv = [vv fp.oxy_raw(:) fp.oxyT_raw(:)];
	 fstr = [fstr '  %5.1f  %5.1f'];
	 vstr = [vstr '   Oxy    OxyT'];
      end
      if dbdat.tmiss && ~isempty(fp.tm_counts)
	 vv = [vv fp.tm_counts(:)];
	 fstr = [fstr '  %5d'];
	 vstr = [vstr '  Tmiss'];
      end      
      fprintf(1,[vstr '\n']);
      fprintf(1,[fstr '\n'],flipud(vv)');   
   end
   
   cmd = lower(input(' : ','s'));
end


%----------------------------------------------------------------------
