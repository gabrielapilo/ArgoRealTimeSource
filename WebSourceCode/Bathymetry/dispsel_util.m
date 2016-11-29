function dispsel_util(action)

global DATAves DATAcru DATAlat DATAlon DATAtim DISPii 
global tot_cru cru_hand

vstr = ['Fr';'SS';'AA';'G9';'AS';'??';'??';'??';'??'];

switch action

  case 'init'
    tmpHndl = findobj(gcf,'Tag','disp_title');
    set(tmpHndl,'String',[num2str(length(DISPii)) ' casts selected']);
    
    cru_list = {};
    tot_cru = sort_nd((DATAves(DISPii)*100000)+DATAcru(DISPii));
    for ii=1:length(tot_cru)
      vvv = floor(tot_cru(ii)/100000);
      ccc = tot_cru(ii)-(vvv*100000);
      nnn = length(find(DATAves(DISPii)==vvv & DATAcru(DISPii)==ccc));
      cru_list(ii) = ...
	  {[' ' vstr(vvv,:) '  ' num2str(ccc) '         ' num2str(nnn)]};
    end

    tmpHndl = findobj(gcf,'Tag','cru_list_box');
    set(tmpHndl,'String',cru_list);    
    cru_hand = [];
    
  case 'map'
    hold off;
    plot(DATAlon(DISPii),DATAlat(DISPii),'+');
    ax = axis;
    xr = ax(2)-ax(1);
    yr = ax(4)-ax(3);
    if xr>(2*yr)
      cor = (xr-(2*yr))/2;
      axis([ax(1) ax(2) ax(3)-cor ax(4)+cor]);
    elseif xr<(1.5*yr)
      cor = ((1.5*yr)-xr)/2;
      axis([ax(1)-cor ax(2)+cor ax(3) ax(4)]);
    end
    xlabel(' ');
    hold on;
    gebco
    cru_hand = [];
    
  case 'one_cru'
    if ~isempty(cru_hand)
      delete(cru_hand);
    end
    this_cru = get(gcbo,'Value');
    if ~isempty(tot_cru) & this_cru <= length(tot_cru)
      vvv = floor(tot_cru(this_cru)/100000);
      ccc = tot_cru(this_cru)-(vvv*100000);
      iii = find(DATAves(DISPii)==vvv & DATAcru(DISPii)==ccc);
      cru_hand=plot(DATAlon(DISPii(iii)),DATAlat(DISPii(iii)),'r*');
    end
    
  case 'histo'
    hold off;
    tmp = nanmax(DATAtim(DISPii)) - nanmin(DATAtim(DISPii));
    nbin = max(12,tmp/30.5);
    hist(1900+DATAtim(DISPii)/365.25,nbin);
    xlabel('Years');
    cru_hand = [];
    
  case 'continue'
    close(gcbf);
    
end

% -------------------- End of dispsel_util.m ------------------------
