function ctd_sel_util(action)

% CTD_SEL_UTIL: Utility function supporting "ctd_select"
%
%  Copyright     Jeff Dunn, CSIRO Division of Marine Research, 29/1/1998

% $Id: ctd_sel_util.m,v 1.2 2000/10/20 03:57:13 dunn Exp dun216 $
% 
% Need to have globals only so they retain their values for subsequent calls.
% Could use the figure UserData, but would be messy.
% Globals are given stupid names to reduce chance of them clobbering a 
% likenamed global in some other code.

global limsFR limsSS limsAA limsG9 limsAS limsEACHYR limsYEARMN limsMONMN
global limsDAYMN limsYEARMX limsMONMX limsDAYMX limsNORTH
global limsSOUTH limsEAST limsWEST limsCRMN limsCRMX limsSTMN limsSTMX
global limsBDMN limsBDMX limsDDMN limsDDMX limsSAMPMN limsNDIG

global DATAves DATAcru DATAstn DATAlat DATAlon DATAtim DATAbdep DATAddep
global DATAndig DATAnts DATAfnames DATAtot_idx DISPii

global wrote_to_file

switch(action)

  case 'reset_lims'

    set(gcbf,'Pointer','watch');
    
    if isempty(DATAves)
      ncmex('setopts',0);
      
      fnm = platform_path('fips','eez_data/csiro/dpg_sta_list.nc');
      fid = ncmex('ncopen',fnm,'nowrite');

      if fid < 0
	 disp('ERROR - cannot open station list file.     Exiting');
	 clear global limsFR limsSS limsAA limsG9 limsAS limsEACHYR limsYEARMN...
	       limsMONMN limsDAYMN limsYEARMX limsMONMX limsDAYMX limsNORTH...
	       limsSOUTH limsEAST limsWEST limsCRMN limsCRMX limsSTMN limsSTMX...
	       limsBDMN limsBDMX limsDDMN limsDDMX limsSAMPMN limsNDIG...
	       DATAves DATAcru DATAstn DATAlat DATAlon DATAtim DATAbdep DATAddep...
	       DATAndig DATAnts DATAfnames DATAtot_idx DISPii wrote_to_file
	 close(gcbf);
      end
	 
      [tmp,nsta] = ncmex('ncdiminq',fid,'station_dim');
      [tmp,nfdim] = ncmex('ncdiminq',fid,'filename_dim');
      
      update = ncmex('ncattget',fid,'global','creation_date');
      set(findobj('Tag','update'),'String',['Updated ' update]);

      DATAves = ncmex('varget',fid,'vessel',0,nsta);
      DATAcru = ncmex('varget',fid,'cruise',0,nsta);
      ii = find(DATAcru<1000);
      if ~isempty(ii)
	 DATAcru(ii) = DATAcru(ii)+10000;  % Correct Y2K bug
      end
      DATAstn = ncmex('varget',fid,'station',0,nsta);
      DATAlat = ncmex('varget',fid,'lat',0,nsta);
      DATAlon = ncmex('varget',fid,'lon',0,nsta);
      DATAtim = ncmex('varget',fid,'time',0,nsta);
      DATAbdep = ncmex('varget',fid,'depth',0,nsta);
      DATAddep = ncmex('varget',fid,'deepest_data',0,nsta);
      DATAndig = ncmex('varget',fid,'num_dig',0,nsta);
      DATAnts = ncmex('varget',fid,'num_ts',0,nsta);
      DATAfnames = ncmex('varget',fid,'filename',[0 0],[nsta nfdim]);
      % Guard against changes in behaviour of ncmex
      ncol = size(DATAfnames,2);
      if ncol~=nfdim
	DATAfnames = DATAfnames';
      end
      
      DATAtot_idx = zeros(size(DATAlat));
      
      ncmex('ncclose',fid);
    end

    limsFR = 1;
    limsSS = 1;
    limsAA = 1;
    limsG9 = 1;
    limsAS = 1;
    
    limsEACHYR = 0;
    tmptim = time2greg(nanmin(DATAtim));
    limsYEARMN = tmptim(1);
    limsMONMN = tmptim(2);
    limsDAYMN = tmptim(3);
    tmptim = time2greg(nanmax(DATAtim));
    limsYEARMX = tmptim(1);
    limsMONMX = tmptim(2);
    limsDAYMX = tmptim(3);

    limsNORTH = nanmax(DATAlat);
    limsSOUTH = nanmin(DATAlat);
    limsEAST = nanmax(DATAlon);
    limsWEST = nanmin(DATAlon);
    limsCRMN = nanmin(DATAcru);
    limsCRMX = nanmax(DATAcru);
    limsSTMN = 1;
    limsSTMX = 999;
    limsBDMN = 0;
    limsBDMX = 10000;
    limsDDMN = 0;
    limsDDMX = 10000;
    limsSAMPMN = 1;
    limsNDIG = 0;

    set(findobj('Tag','franklin'),'Value',limsFR);
    set(findobj('Tag','surveyor'),'Value',limsSS);
    set(findobj('Tag','aurora'),'Value',limsAA);
    set(findobj('Tag','sprightly'),'Value',limsG9);
    set(findobj('Tag','soela'),'Value',limsAS);

    set(findobj('Tag','n_region'),'String',num2str(limsNORTH));
    set(findobj('Tag','s_region'),'String',num2str(limsSOUTH));
    set(findobj('Tag','e_region'),'String',num2str(limsEAST));
    set(findobj('Tag','w_region'),'String',num2str(limsWEST));
    set(findobj('Tag','eachyr'),'Value',limsEACHYR);
    set(findobj('Tag','yearmax'),'String',num2str(limsYEARMX));
    set(findobj('Tag','yearmin'),'String',num2str(limsYEARMN));
    set(findobj('Tag','monmax'),'String',num2str(limsMONMX));
    set(findobj('Tag','monmin'),'String',num2str(limsMONMN));
    set(findobj('Tag','daymax'),'String',num2str(limsDAYMX));
    set(findobj('Tag','daymin'),'String',num2str(limsDAYMN));
    set(findobj('Tag','crmax'),'String',num2str(limsCRMX));
    set(findobj('Tag','crmin'),'String',num2str(limsCRMN));
    set(findobj('Tag','ddepmax'),'String',num2str(limsDDMX));
    set(findobj('Tag','ddepmin'),'String',num2str(limsDDMN));
    set(findobj('Tag','bdepmax'),'String',num2str(limsBDMX));
    set(findobj('Tag','bdepmin'),'String',num2str(limsBDMN));
    set(findobj('Tag','stmax'),'String',num2str(limsSTMX));
    set(findobj('Tag','stmin'),'String',num2str(limsSTMN));
    set(findobj('Tag','sampmin'),'String',num2str(limsSAMPMN));
    set(findobj('Tag','needdig'),'Value',limsNDIG);

    set(gcbf,'Pointer','arrow');

  case 'franklin'
    limsFR = get(gcbo,'Value');
    
  case 'surveyor'
   limsSS = get(gcbo,'Value');
    
  case 'aurora'
    limsAA = get(gcbo,'Value');

  case 'sprightly'
    limsG9 = get(gcbo,'Value');

  case 'soela'
    limsAS = get(gcbo,'Value');

  case 'n_region'
    limsNORTH = eval(get(gcbo,'String'));
    
  case 's_region'
    limsSOUTH = eval(get(gcbo,'String'));
    
  case 'e_region'
    limsEAST = eval(get(gcbo,'String'));
    
  case 'w_region'
    limsWEST = eval(get(gcbo,'String'));
    
  case 'yearmax'
    limsYEARMX = eval(get(gcbo,'String'));
    
  case 'yearmin'
    limsYEARMN = eval(get(gcbo,'String'));
    
  case 'eachyr'
    limsEACHYR = get(gcbo,'Value');
    
  case 'monmax'
    limsMONMX = eval(get(gcbo,'String'));
    
  case 'monmin'
    limsMONMN = eval(get(gcbo,'String'));

  case 'daymax'
    limsDAYMX = eval(get(gcbo,'String'));
    
  case 'daymin'
    limsDAYMN = eval(get(gcbo,'String'));
    
  case 'crmax'
    limsCRMX = eval(get(gcbo,'String'));
    
  case 'crmin'
    limsCRMN = eval(get(gcbo,'String'));
    
  case 'ddepmax'
    limsDDMX = eval(get(gcbo,'String'));
    
  case 'ddepmin'
    limsDDMN = eval(get(gcbo,'String'));
    
  case 'bdepmax'
    limsBDMX = eval(get(gcbo,'String'));
    
  case 'bdepmin'
    limsBDMN = eval(get(gcbo,'String'));
    
  case 'stmax'
    limsSTMX = eval(get(gcbo,'String'));
    
  case 'stmin'
    limsSTMN = eval(get(gcbo,'String'));
    
  case 'sampmin'
    limsSAMPMN = eval(get(gcbo,'String'));
    
  case 'needdig'
    limsNDIG = get(gcbo,'Value');
    

    
    
% ----- Activity Controls    
    
  case 'clear_all'
    DATAtot_idx = zeros(size(DATAlat));
    wrote_to_file = 1;
    

  case {'test_sel','save_sel'}

    set(gcbf,'Pointer','watch');

    if limsEACHYR
      % Testing in same period each year. 'doy' is 'Day_Of_Year'.
      tmp = time2greg(DATAtim);
      gyrs = tmp(:,1)';
      doy = time2doy(DATAtim);
      tmp = greg2time([1900 limsMONMN limsDAYMN 0 0 0]);
      mindoy = time2doy(tmp);
      tmp = greg2time([1900 limsMONMX limsDAYMX 0 0 0]);
      maxdoy = time2doy(tmp);

      ii = find(gyrs>=limsYEARMN & gyrs<=limsYEARMX & doy>=mindoy ...
	  & doy<=maxdoy);

      clear tmp doy
    else
      timmin = greg2time([limsYEARMN limsMONMN limsDAYMN 0 0 0]);
      timmax = greg2time([limsYEARMX limsMONMX limsDAYMX 0 0 0]);
      ii = find(DATAtim>=timmin & DATAtim<=timmax);
    end
    
    if ~isempty(ii) & limsNDIG 
      ii = ii(find(DATAndig(ii)>0));
    end
    
    if ~isempty(ii) & ~(limsFR & limsSS & limsAA & limsG9 & limsAS)
      tmp = [];
      if limsFR
	tmp = ii(find(DATAves(ii)==1));
      end
      if limsSS
	tmp = [tmp ii(find(DATAves(ii)==2))];
      end
      if limsAA
	tmp = [tmp ii(find(DATAves(ii)==3))];
      end
      if limsG9
	tmp = [tmp ii(find(DATAves(ii)==4))];
      end
      if limsAS
	tmp = [tmp ii(find(DATAves(ii)==5))];
      end
      ii = tmp;
    end
    
    if ~isempty(ii) 
      ii = ii(find(DATAlat(ii)>=limsSOUTH & DATAlat(ii)<=limsNORTH & ...
	  DATAlon(ii)>=limsWEST & DATAlon(ii)<=limsEAST));
    end
    
    if ~isempty(ii)
      ii = ii(find(DATAcru(ii)>=limsCRMN & DATAcru(ii)<=limsCRMX ...
	  & DATAstn(ii)>=limsSTMN & DATAstn(ii)<=limsSTMX ...
	  & DATAbdep(ii)>=limsBDMN & DATAbdep(ii)<=limsBDMX ...
	  & DATAddep(ii)>=limsDDMN & DATAddep(ii)<=limsDDMX));
    end      
    
    if ~isempty(ii) & limsSAMPMN>1 
      ii = ii(find(DATAnts(ii)>=limsSAMPMN));
    end

    if strcmp(action,'test_sel')
%      display_sel(DATAves(ii),DATAcru(ii),DATAlat(ii),DATAlon(ii),DATAtim(ii));
      DISPii = ii;
      dispsel;
    else
      previous = length(find(DATAtot_idx>0));
      DATAtot_idx(ii) = ones(size(ii));
      if previous>0
	dis_tot = questdlg('Display accumulated selections');
	if strcmp(dis_tot,'Yes')
	  DISPii = find(DATAtot_idx>0);
	  dispsel;
	end     
      end
      wrote_to_file = 0;
    end
    
    set(gcbf,'Pointer','arrow');

    
  case 'save_to_file'
    write_to_file(DISPii);
    wrote_to_file = 1;
   
    
  case 'finish'
    if any(DATAtot_idx) & ~wrote_to_file
      ans = questdlg('Write accumulated selections to file');
      if strcmp(ans,'Yes')
	write_to_file(ii);
      end
    end

    disp('CTD_SELECT exited');
    
    clear global limsFR limsSS limsAA limsG9 limsAS limsEACHYR limsYEARMN...
	limsMONMN limsDAYMN limsYEARMX limsMONMX limsDAYMX limsNORTH...
        limsSOUTH limsEAST limsWEST limsCRMN limsCRMX limsSTMN limsSTMX...
        limsBDMN limsBDMX limsDDMN limsDDMX limsSAMPMN limsNDIG...
	DATAves DATAcru DATAstn DATAlat DATAlon DATAtim DATAbdep DATAddep...
	DATAndig DATAnts DATAfnames DATAtot_idx DISPii wrote_to_file

    close(gcbf);

  otherwise
    disp(['WARNING: unknown action: ' action]);
    
end
    

%-----------------------------------------------------------------------
function write_to_file(ii)

global DATAtot_idx DATAves DATAcru DATAfnames

vcode = ['fr';'ss';'aa';'g9';'as';'??';'??';'??';'??'];

kk = find(DATAtot_idx>0);
if isempty(kk)
  kk = ii;
end
if ~isempty(kk)
  defnam = {'ctdnames.lis'};
  outname = inputdlg('Name for ASCII output file','Output File',1,defnam);
  if isempty(outname)
    outname = defnam;
  end
  fid = fopen(outname{1},'w');
  ii = find(DATAcru>=10000);
  if ~isempty(ii)
     DATAcru(ii) = DATAcru(ii)-10000;  % Undo Y2K correction
  end
  for jj = 1:length(kk)
    count=fprintf(fid,'%s%04d/%s\n',vcode(DATAves(kk(jj)),:),...
	DATAcru(kk(jj)),DATAfnames(kk(jj),:));
  end
  fclose(fid);      
  msgbox(['Some recent cruises are in different locations and '...
	  'different formats. If this is a problem, contact Jeff'],'','warn');
else
  msgbox('There are no selected casts to write to file','','warn')
end

%----------------------------------------------------------------------
