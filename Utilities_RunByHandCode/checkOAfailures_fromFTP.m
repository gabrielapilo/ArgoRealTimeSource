%edit here:
win = 20; %plot window of adjacent profiles
fns = ('*201708*.csv');
download = 1;
%% retrieve the warning CSV files from ifremer
if download
cd /home/argo/ArgoRT/OAwarnings
f = ftp('ftp.ifremer.fr');
cd(f,'ifremer/argo/etc/ObjectiveAnalysisWarning/csiro');
mget(f,fns);
close(f);
end
%% load the files and put into a list to cycle through
[wmo,pn,parm,sd,ed,fl1,fl2] = deal([]);
cl = dir(['/home/argo/ArgoRT/OAwarnings/' fns]);
for a = 1:length(cl)
    fid = fopen(['/home/argo/ArgoRT/OAwarnings/' cl(a).name]);
    dat = textscan(fid,'%s%f%f%s%s%s%s%f%f%u%u\n','delimiter',',','headerlines',1);
    fclose(fid);
    wmo = [wmo;dat{2}]; %wmoid
    pn = [pn;dat{3}]; %prof number
    parm = [parm;dat{7}]; %temp/psal/press
    sd = [sd;dat{8}]; % start depth
    ed = [ed;dat{9}]; %end depth
    fl1 = [fl1;dat{10}]; %flag current
    fl2 = [fl2;dat{11}]; %flag recommended by OA
    
end
% get the unique wmo/pn pairs
[~,ia] = unique([wmo,pn],'rows','stable');

%% cycle through each profile and make decisions
col = {'g','b','m','r'};
for a = 1:length(ia)
    disp([num2str(wmo(ia(a))) ', ' num2str(pn(ia(a)))])
    itemp = find(wmo == wmo(ia(a)) & pn == pn(ia(a)) & cellfun(@isempty,strfind(parm,'TEMP')) == 0);
    [fpp,dbdat] = getargo(wmo(ia(a)));  %float
    j = pn(ia(a)); %profile number
    
    figure(1);clf
    for i=max(j-win,1):min(j+win,length(fpp))
        plot(fpp(i).t_raw,fpp(i).p_calibrate,'color',[.9 .9 .9])
        hold on
        axis ij
    end
    i=j;
    plot(fpp(i).t_raw,fpp(i).p_calibrate,'k-', 'linewidth',2)
    vo=qc_apply(fpp(j).t_raw,fpp(j).t_qc);
    vp=qc_apply(fpp(j).p_calibrate,fpp(j).p_qc);
    plot(vo,vp,'g','linewidth',2)
    if ~isempty(itemp)
        for b = 1:length(itemp)
            ic = find(fpp(j).p_calibrate >= sd(itemp(b))-1 & fpp(j).p_calibrate <= ed(itemp(b))+1);
            plot(fpp(j).t_raw(ic),fpp(j).p_calibrate(ic),'marker','o',...
                'markerfacecolor',col{fl2(itemp(b))},'markeredgecolor',col{fl2(itemp(b))})
        end
    end
    title('Temperature')
    grid
    
    isal = find(wmo == wmo(ia(a)) & pn == pn(ia(a)) & cellfun(@isempty,strfind(parm,'PSAL')) == 0);
    % for j=1:3:length(fpp)
    figure(2);clf
    for i=max(j-win,1):min(j+win,length(fpp))
        plot(fpp(i).s_raw,fpp(i).p_calibrate,'color',[.9 .9 .9])
        vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
        vp=qc_apply(fpp(i).p_calibrate,fpp(i).p_qc);
        plot(vo,vp,'color',[.7 .7 .7])
        hold on
        axis ij
    end
    i=j;
    plot(fpp(i).s_raw,fpp(i).p_calibrate,'k-','linewidth',2)
    vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
    vp=qc_apply(fpp(i).p_calibrate,fpp(i).p_qc);
    plot(vo,vp,'g','linewidth',2)
    if ~isempty(isal)
        for b = 1:length(isal)
            ic = find(fpp(j).p_calibrate >= sd(isal(b))-1 & fpp(j).p_calibrate <= ed(isal(b))+1);
            plot(fpp(j).s_raw(ic),fpp(j).p_calibrate(ic),...
                'markerfacecolor',col{fl2(isal(b))},'markeredgecolor',col{fl2(isal(b))},'marker','o')
        end
    end
    grid on
    title('PSAL')
    
    %TS plots
    tsi = [itemp;isal];
    ts = [sd([itemp;isal]),ed([itemp;isal])];
    [ua,its] = unique(ts,'rows');
    % for j=1:3:length(fpp)
    figure(3);clf
    for i=max(j-10,1):min(j+10,length(fpp))
        plot(fpp(i).s_raw,fpp(i).t_raw,'color',[.9 .9 .9])
        vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
        vp=qc_apply(fpp(i).t_raw,fpp(i).t_qc);
        plot(vo,vp,'color',[.7 .7 .7])
        hold on
    end
    i=j;
    plot(fpp(i).s_raw,fpp(i).t_raw,'k-','linewidth',2)
    vo=qc_apply(fpp(i).s_calibrate,fpp(i).s_qc);
    vp=qc_apply(fpp(i).t_raw,fpp(i).t_qc);
    plot(vo,vp,'g','linewidth',2)
    if ~isempty(ua)
        
        for b = 1:size(ua,1)
            ic = find(fpp(j).p_calibrate >= ua(b,1)-1 & fpp(j).p_calibrate <= ua(b,2)+1);
            plot(fpp(j).s_raw(ic),fpp(j).t_raw(ic),...
                'markerfacecolor',col{fl2(tsi(its(b)))},'markeredgecolor',col{fl2(tsi(its(b)))},'marker','o')
        end
    end
    grid on
    title('T/S')
    
    figure(2)
    %need to make decisions now
%     yn = input('reject these points?','s');
pause
    % rejectpoints(5903955,273,{'s'},280,473)
end
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
 
