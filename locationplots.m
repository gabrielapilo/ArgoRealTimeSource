% LOCATIONPLOTS  Create location plot for one float.
%  
% INPUT: fpp - struct array for the float
%
% OUTPUT:
%   Files   loc_WMO.tif
%
% AUTHOR: Rebecca Cowley CMAR March 2007 
%
% CALLED BY:  Argo main program. Can be used standalone
% 
% USAGE: locationplots(fpp)

function locationplots(fpp)

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

H = figure(9);
clf
c=[];

set(H,'PaperPosition',[0 0 4.5 3])      % Controls final image size
hold on
for kk=1:nprof
    if nprof>256
        k=floor(kk/ceil(nprof/256))+1;
    else
        k=kk;
    end
    %find the first occurrence of a good position
    order = [1,2,0,5,8,9,7]; %what is 7 for?
    [~,ia,~] = intersect(fpp(kk).pos_qc,order);
    
    figure(9),hold on
    if(~isempty(fpp(kk).lon) && ~isnan(fpp(kk).lon(ia(1))) && ~isempty(fpp(kk).profile_number))
        c(kk)=plot(fpp(kk).lon(ia(1)),fpp(kk).lat(ia(1)),'o','markersize',4,'color',cc(k,:));
        set(c(kk),'Color',cc(k,:))
        lab(kk,:) =sprintf('%7i',fpp(kk).profile_number);
    end
end

title(['Float ' fwmo ' location'],'fontsize',10)
ylabel('Latitude')
xlabel('Longitude')

va = axis;
continents([.7 .7 .7])
 axis equal
axis([va(1)-5 va(2)+5 va(3)-5 va(4)+5])

% need to control for missing profiles:
if isempty(c)
   jj=[];
   return
end
jj=find(c==0);
if(~isempty(jj))
    c(jj)=[];
    lab(jj,:)=[];
end

if length(c) < 15,
kk=1:length(c);
else
   np = floor(length(c)/15);
   kk  = 1:np:length(c);
end

legend(c(kk),lab(kk,:),-1,'Location','NorthEastOutside');

fnm = [fpth 'loc_' fwmo];
if(ispc)
    print('-dtiff',fnm);
else
    my_save_fig(fnm,'clobber')
end

system(['chmod -f 664 ' fpth '*if']);

