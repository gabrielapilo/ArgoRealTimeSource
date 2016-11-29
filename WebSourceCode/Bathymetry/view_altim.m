% VIEW_ALTIM  Cursory inspection of data in file produced by program "altim"
%
% INPUT: fnm - name of altim netCDF file (can leave off '.nc')
%
% OUTPUT: to figures
%
% Jeff Dunn 26/10/01
%
% USAGE: view_altim(fnm)

function view_altim(fnm)

cc = input('Using figs 4,5,6 unless specify other (eg [1 2 11]) : ');
if ~isempty(cc)
   figs = cc;
else
   figs = [4 5 6];
end
lo=getnc(fnm,'lon');  
la=getnc(fnm,'lat');  
tim=getnc(fnm,'time');  
hdf=getnc(fnm,'height_diff');  
ii = find(isnan(hdf));

tim(ii)=repmat(nan,size(ii));
tim = (tim/86400)+31046;

[ntrk,ncyc,nlat] = size(tim);

disp(['Plotting data distrib for ' num2str(ntrk) ' tracks'])

[x,y] = meshgrid(la,1:ncyc);
aa1 = [0 ncyc+1 min(la)-1 max(la)+1];

disp('Plotting data availability in lat and time space')
ss = 1;
cc = input(['Track to plot (f=finish) [' num2str(ss) '] : '],'s');
if ~isempty(cc) & cc=='f'
   ss = ntrk+1;
end
while ss<=ntrk
   tm = sq(tim(ss,:,:));
   ll = find(~isnan(tm));   
   figure(figs(1))
   hold off
   plot(y(ll),x(ll),'k.','markersize',1);
   axis(aa1);
   hold on;
   plot(1:ncyc,aa1(3),'b^','markersize',5);
   title('Data present in cycle (time) vs lat domain')
   c1 = time2greg(min(tm(:)));
   c2 = time2greg(max(tm(:)));
   xlabel(['CYCLE number  (Time range ' num2str(c1([3 2 1])) '  -  ' ...
	   num2str(c2([3 2 1])) ')']);
   ylabel('latitude');
   figure(figs(2))
   clff
   hold on
   for ii=1:ntrk
      plot(lo(ii,:),la,'k.','markersize',1);
   end
   plot(lo(ss,:),la,'r+');
   gebco
   ss = ss+1;
   cc = input(['Track to plot (f=finish) [' num2str(ss) '] : '],'s');
   if ~isempty(cc)
      if cc=='f'
	 ss = ntrk+1;
      else 
	 ss = str2double(cc);
      end
   end
end 


clear x y

disp('Plotting individual cycles.');
la = repmat(la',[ntrk 1]);
figure(figs(3))

ss = 1;
cc = input([num2str(ncyc) ' cycles. First to plot (f=finish) [' num2str(ss) '] : '],'s');
if ~isempty(cc) & cc=='f'
   ss = ncyc+1;
end
while ss<=ncyc
   if any(any(sq(~isnan(hdf(:,ss,:)))))
      clff
      colourplot(lo,la,sq(hdf(:,ss,:)))
      tm = sq(tim(:,ss,:));
      c1 = time2greg(min(tm(:)));
      c2 = time2greg(max(tm(:)));
      cdat = sprintf('%2d/%0.2d/%4d - %2d/%0.2d/%4d',[c1([3 2 1]) c2([3 2 1])]);
      ss = ss+1;
      cc = input([num2str(ss-1) ' : ' cdat '. Next (f=finish) [' num2str(ss) '] : '],'s'); 
   else
      ss = ss+1;
      cc = input([num2str(ss-1) ' - no data. Next (f=finish) [' num2str(ss) '] : '],'s'); 
   end

   if ~isempty(cc)
      if cc=='f'
	 ss = ncyc+1;
      else 
	 ss = str2double(cc);
      end
   end
end

%---------------------------------------------------------------------------
