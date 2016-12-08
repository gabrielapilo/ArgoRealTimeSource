% CHECK_P  Check for bad P or badly flagged P in pre-DM files
%
% INPUT:  wmoid   WMO id  (numeric)
%         dmdir   -1 to 5 corresponding to the data/dmode/ directories
%                0:4 = 0dmqc/ to 4gilson_final/ respectively
%                -1 = ArgoRT/netcdf/    
%                 5 = 1pres_cor/
%         pnums   List of profile numbers ([] = all profiles) 
%         doit    0=just test but do not make changes  [default = 1]
%
% OUTPUT: netcdf files may be modified
%
%  Jeff Dunn 24/11/09
%
% EXAMPLE: Just scan through all profiles, but do not make any changes to 
%  files:
%         check_P(5900842,0,[],0)
%
% EXAMPLE: Check and correct a group of profile files
%         check_P(5900842,0,59:63)
%
% OPERATION:  Each profile will be checked for potentially bad P.
%   It is then plotted with symbols showing the QC values that this 
%   program has just calculated (see legend). Original QC>2 is indicated
%   by additional cyan diamonds. Type h in plot to see menu of control
%   options. These are typed into figure window. They are:
%
%  click:   (button 1) select and display a point
%      u:  Up to next point
%      d:  Down to next point
%      h:  This help message
%   1..9:  Set QC value for selected point
%      z:   Zoom activate (CR at command line to end Zoom)
%     CR:   go to next profile
%
%   If changes are made to QC, these are written to PRES_QC and PRES_ADJUSTED_QC
%   in file. Whether or not changes are made, all PRES_ADJUSTED values are
%   set to Fillval if QC>3, and any Fillval are replaced with PRES value if
%   QC<=3.
%
% NOTE:  
%   If P QC flags have been set because of something other than P (eg density
%   inversions) then this program will unset them. For now, we accept this.
%
% SYNTAX: check_P(wmoid,dmdir,pnums,doit)

function check_P(wmoid,dmdir,pnums,doit)

if nargin<3
   pnums = [];
end

flist = get_dm_pfnames(dmdir,wmoid,pnums,0);

if nargin<4 || isempty(doit)
   doit = 1;
end
if ~doit
   disp('Just testing');
end
   
fillval = 99999.;

fh12 = figure(12);
symbl{1} = 'b+';  mrkr{1} = '+';  col{1} = [0 0 1];
symbl{2} = 'c+';  mrkr{2} = '+';  col{2} = [0 1 1];
symbl{3} = 'm*';  mrkr{3} = '*';  col{3} = [1 0 1];
symbl{4} = 'r*';  mrkr{4} = '*';  col{4} = [1 0 0];
symbl{9} = 'go';  mrkr{9} = 'o';  col{9} = [0 1 0];
lstr = {'QC 1','QC 2','QC 3','QC 4','QC 9','OrigQC >2'};

for jj = 1:length(flist)
   
   fnm = flist{jj};
   ncload(fnm,'PRES','PRES_QC','PRES_ADJUSTED','PRES_ADJUSTED_QC');

   if size(PRES_QC,1)==1
      PRES_QC = PRES_QC';
   end
   qc = str2num(PRES_QC)';
   nobs = length(qc);

   % Muck around because QC can sometimes contain null strings
   if nobs<length(PRES)
      qc = str2num(PRES_ADJUSTED_QC)';
      nobs = length(qc);
      if nobs<length(PRES)
	 nobs = length(PRES);
	 qc = ones(1,nobs);
	 for ii = 1:length(PRES_QC)
	    tmp = str2num(PRES_QC(ii));
	    if isnum(tmp)
	       qc(ii) = tmp;
	    end
	 end
      end
   end
   
   % Begin building our new QC flags 
   qcnew = ones(size(qc));

   qcnew(PRES<-10 | PRES>2200) = 4;
   qcnew(PRES==fillval | isnan(PRES)) = 9;
   
   % Extrapolate expected values, both upwards and downwards, delP changes in
   % large steps, so many points will fit the sequence nicely in one
   % direction but not at all in the other.
   ii = find(qcnew<=2);
   ll = length(ii);

   i1 = ii(1:(ll-2));
   i2 = ii(2:(ll-1));
   i3 = ii(3:ll);   

   del1 = repmat(nan,size(PRES));
   ex1 = del1;
   del2 = del1;
   ex2 = del1;
   
   del1(i3) = (PRES(i2)-PRES(i1))./(i2-i1);
   del1(del1<0) = 0;
   ex1(i3) = PRES(i2) + (i3-i2).*del1(i3);      

   del2(i1) = (PRES(i2)-PRES(i3))./(i2-i3);
   del2(del2<0) = 0;
   ex2(i1) = PRES(i2) + (i1-i2).*del2(i1);

   % Setting a good-enough-fit threshold is also difficult because of the
   % huge range in delP. It is of course P-dependant, but that is no help if
   % we have bad P! So, try to get a smoothed best-guess at delP to use as
   % our fit limit.
   thr = med_filt(del1,del2);
   
   % Build figure
   figure(fh12)
   clf

   sfnm = fnm;
   sfnm(strfind(fnm,'_')) = '-';
   title(['Pressure ' sfnm]);
   hold on;

   % A trick to set up legend. First plot all required symbols to left 
   % of origin, then later change left axis so we don't see these.
   for jk = [1:4 9]
      plot(-1,1,symbl{jk});
   end
   plot(-1,1,'cd','markersize',12);
      
   
   bad = (abs(PRES-ex1)>thr & abs(PRES-ex2)>thr);
   qcnew(bad & qcnew<4) = 4;

   % Set up handles so we can change the plot symbols if change QC
   hh = zeros(nobs,1);
      
   % Cap extreme values so that plot has a sensible range
   PR = -PRES;      
   PR(PR<-2300) = -2300;
   PR(PR>100) = 100;
   X = 1:nobs;
      
   for ii = 1:nobs	 
      hh(ii) = plot(ii,PR(ii),symbl{qcnew(ii)});
      if qc(ii)>1 & qc(ii)<9
	 plot(ii,PR(ii),'cd','markersize',12);
      end
   end

   % Get axis and change left limit to hide symbols plotted just for legend
   ax = axis;
   ax(1) = 0;
   axis(ax);
   legend(lstr,'location','best');
      
   % Set up to loop on inputs to this figure, ending when we get a CR
   go_next = 0;   
   isel = [];
   selh = [];
      
   while go_next==0
      keypress = waitforbuttonpress;
      ptr_fig = get(0,'CurrentFigure');
      if ptr_fig==fh12	 
	 % Are we in the right figure window?
	 
	 if keypress
	    % A key, as opposed to a mouse-click
	    
	    key = get(fh12, 'CurrentCharacter');
	    
	    if key==13
	       % CR key
	       go_next = 1;

	    elseif strcmp(key,'d')
	       if isempty(isel)
		  isel = 1;
	       elseif isel==nobs
		  disp('Already down to last point')
	       else
		  isel = isel+1;
	       end
	       
	    elseif strcmp(key,'u')
	       if isempty(isel)
		  isel = nobs;
	       elseif isel==1
		  disp('Already up to point #1')
	       else
		  isel = isel-1;
	       end
	       
	    elseif ~isempty(strfind('1234567890',key))
	       ikey = str2num(key);
	       if ikey>4 & ikey<9
		  disp('Ignored! QC codes 5 to 8 are not in use! ')
	       elseif isempty(isel)
		  disp('Need to select a point before changing QC value')
	       else
		  qcnew(isel) = ikey;
		  set(hh(isel),'marker',mrkr{ikey},'color',col{ikey});
	       end
	       
	    elseif strcmp(key,'h')
	       str = {'u:  Up to next point';
		      'd:  Down to next point';
		      'h:  This help message';
		      '1..9:  Set QC value for selected point';
		      'z:   Zoom activate (CR at command line to end Zoom)';
		      'click:   select and display a point';
		      'CR:   go to next profile'};
	       helpwin(str,'','Controls for check_P','FontSize',12);
	       
	    elseif strcmp(key,'z')
	       zoom on
	       pointer2 = get(gcf,'pointer');
	       input('Zoom with buttons 1 & 3.     <CR>  H E R E  to finish :')
	       zoom off
	       
	    else
	       disp('Do NOT understand that command. Hit "h" for help.')
	    end
	    
	 else     
	    % A mouse button clicked
	    
	    button = get(fh12, 'SelectionType');
	    if strcmp(button,'normal')          % ------- Button 1
	       pt = get(gca,'currentpoint');
	       if size(pt,1)>1
		  pt = pt(1,1:2);
	       end
	       scal = (max(PR)-min(PR))/nobs;
	       r = sqrt((scal.*(X-pt(1))).^2 + (PR-pt(2)).^2);
	       [tmp,isel] = min(r);
	       if length(isel)~=1
		  disp('Sorry - no point selected')
	       end
	    elseif strcmp(button,'extend')      % -------- Button 2
	       disp('No action defined for button 3')
	    elseif strcmp(button,'alt') 	% --------- Button 3	    
	       disp('No action defined for button 3')
	    end
	 end

	 if ~isempty(selh)
	    % Clear out any previous selected-point highlight line
	    delete(selh);
	    selh = [];
	 end
	 
	 if ~isempty(isel)
	    % Display this selected point
	    ss = sprintf('Point %d, P=%6.1f,   QC=%d,  OrigQC=%d',...
			 [isel PRES(isel) qcnew(isel) qc(isel)]);		  
	    xlabel(ss)	       
	    selh = plot([isel isel],ax([3 4]),'r:');
	 end	 
	 
      end       % Was the input in the right window  ?
   end      % While expecting more inputs for this profile

   
   
   pafil = ( isnan(PRES_ADJUSTED) | PRES_ADJUSTED==fillval );
   
   if doit & ( any(qc~=qcnew) | any(pafil~=(qcnew>2)) )
      % If need to make any changes to this file...
      
      nid = netcdf(fnm,'write');
      
      if any(qc~=qcnew)
	 disp(['Modifying ' num2str(sum(qc~=qcnew)) ' QC flags'])
	 sqc = num2str(qcnew(:)','%1d');
	 nid{'PRES_QC'}(:) = sqc;
	 nid{'PRES_ADJUSTED_QC'}(:) = sqc;
      end

      if any(pafil~=(qcnew>3))
	 % Apply fillval to bad-flagged obs
	 PRES_ADJUSTED(qcnew>3) = fillval;
	 
	 % If any good-flagged obs have fillval, replace with PRES. Even 
	 % though this is not a proper adjusted value, it will soon be
	 % replaced by one in the DM processing, so this is ok.
	 jk = find(pafil & qcnew<=3);
	 if ~isempty(jk)
	    PRES_ADJUSTED(jk) = PRES(jk);
	 end	 
	 nid{'PRES_ADJUSTED'}(:) = PRES_ADJUSTED;
      end

      nid = close(nid);
   end
      
end

close(fh12)


%-----------------------------------------------------------------------------
function thr = med_filt(del1,del2);

nn = length(del1);

thr = ones(1,nn);

for ii = 1:nn
   jj = [max([1 ii-3]):min([ii+3 nn])];
   
   k1 = del1(jj)>0;
   k2 = del2(jj)>0;
   
   if any(k1) | any(k2)
      thr(ii) = median([del1(jj(k1)) del2(jj(k2))]);
   end
end

return

%------------------------------------------------------------------------------
