
%=======================================================================================
%  INSERTS THE ENTRIES INTO THE MAIN INDEX TABLE OF THE HTML FILE
%=======================================================================================
function strout = ReplaceIndexTable(strin,Data)
    global ARGO_SYS_PARAM

%begin
    Index = strvcmp(strin, '[TABLE1]');
    if (isempty(Index)) return; end;
    
%     %CELL BACKGROUND COLORS:
    Red   = [0.9 0.5 0.5];
    Gray  = [0.95 0.95 0.95];
    Highl = [0.85 0.85 0.85];
    
    %COLUMN COLORS: set highlight color for each sorted column to dark gray
%     c1=Red;   c2=Gray;  c3=Gray;  c4=Gray;  c5=Gray;  c6=Gray;  c7=Gray;  c8=Gray;  c9=Gray; 
%     c10=Gray; c11=Gray; c12=Gray; c13=Gray; c14=Gray; c15=Gray; c16=Gray; %  c17=Gray; c18=Gray;
    c1=Red;   c2=Highl;  c3=Highl;  c4=Highl;  c5=Highl;  c6=Highl;  c7=Highl;  c8=Highl;  c9=Highl; 
    c10=Highl; c11=Highl; c12=Highl; c13=Highl; c14=Highl; c15=Highl; c16=Highl; %  c17=Gray; c18=Gray;
    

    %16 COLS TABLE HEADER:
    header = {'Depl Order',                ...    %1 row count
              'Hull ID',            ...    %2 hyperlink='Index_HullID.html'
              'Comms ID',           ...    %3 hyperlink='Index_ArgosID.html'
              'WMO ID',             ...    %4 hyperlink='Index_WmoID.html'
              'Status',             ...    %5 hyperlink='Index_Status.html'
              'Argo-RT',            ...    %6 profile link page
              'Launch Date',        ...    %7 hyperlink='Index_LaunchDate.html'
              'Deploy Ship',        ...    %8 hyperlink='Index_Ship.html'
              'CPU/Model',          ...    %9 APF8/APF9A,APF9I
              'Ice',                ...    %10 ice detection yes/no
              'Oxygen Sensor',      ...    %11 oxygen optode id
              'Volts',              ...    %12 hyperlink='Index_Voltage.html'
              'Cycles',             ...    %13 hyperlink='Index_Cycles.html'
              'Trans System',             ...    %14 hyperlink='Index_System.html'
              'Last Tx',            ...    %15 hyperlink='Index_LastTx.html'
              'Days Operational',   ...    %17 hyperlink='Index_DaysOperational.html'
            };
%               'Tx Days Ago'         ...    %16 hyperlink='Index_TxDaysAgo.html'
%               'Failure Mode',       ...    %18 failure mode from our database
  
    %INSERT TABLE HEADER INTO HTML FILE: 
    lc     = 1;  %line counter for the table of cells
    nc     = length(header);
    nr = length(Data);
    Table1 = cell((nc+2)*(nr+2),1);   %using cell arrays is faster
    
    
    %CONSTRUCT TABLE HEADER - NEW ROW:
    Table1(lc) = {'        <tr>'};   
    lc=lc+1;
    for j=1:nc  
        href='';
        if (j==1)  href=[ARGO_SYS_PARAM.web_pages(1:length(ARGO_SYS_PARAM.web_pages)-3) 'IndexAU_DepOrder.html'];          end;
        if (j==2)  href=[ARGO_SYS_PARAM.web_pages(1:length(ARGO_SYS_PARAM.web_pages)-3) 'IndexAU_HullID.html'];          end;
        if (j==3)  href=[ARGO_SYS_PARAM.web_pages(1:length(ARGO_SYS_PARAM.web_pages)-3) 'IndexAU_ArgosID.html'];         end;
        if (j==4)  href=[ARGO_SYS_PARAM.web_pages(1:length(ARGO_SYS_PARAM.web_pages)-3) 'IndexAU_WmoID.html'];           end;
        Table1(lc) = {AddCell(cell2mat(header(j)), 4, Red, href)};
        lc         = lc+1;
    end
    Table1(lc) = {'        </tr>'};
    lc=lc+1;
        
    %PARAMETER VALUES: ADD THE DATA ROWS TO THE TABLE:
    for j=1:nr   %40
        %new column:
        Table1(lc) = {'<tr>'};
        lc         = lc+1;
        
        %hyperlink for HullID technical page:
        s1     = num2str(Data(j).maker_id);
        s2     = num2str(Data(j).wmo_id);
        href1  = [ARGO_SYS_PARAM.web_pages s1, '/Hull_', s1, '.html'];
        href2  = [ARGO_SYS_PARAM.www_root 'floats/', s2, '/floatsummary.html'];
        
        %insert individual row cells
        Table1(lc) = {AddCell(num2str(Data(j).deploy_num),                                  5, c1,    '')};  lc=lc+1; %Depl No.
        Table1(lc) = {AddCell(sprintf('%04d', Data(j).maker_id),             5, c2, href1)};  lc=lc+1; %Hull-ID + hyperlink page
        Table1(lc) = {AddCell(num2str(Data(j).argos_id),                    5, c2,    '')};  lc=lc+1; %Argos-ID
        Table1(lc) = {AddCell(num2str(Data(j).wmo_id),                      5, c2,  href1)};  lc=lc+1; %WMO-ID
        Table1(lc) = {AddCell(num2str(Data(j).status),                     5, c2,    '')};  lc=lc+1; %Status
        Table1(lc) = {AddCell('Profile',                                   5, c2,    href2)};  lc=lc+1; %Ann's profile page hyperlink
        ld=[Data(j).launchdate(7:8) '/' Data(j).launchdate(5:6) '/' Data(j).launchdate(1:4) ' ' Data(j).launchdate(9:10) ':' Data(j).launchdate(11:12)];
        Table1(lc) = {AddCell(ld,                                          5, c2,    '')};  lc=lc+1; %Launch Date
        Table1(lc) = {AddCell(upper(strtrim(Data(j).launch_platform)),             5, c2,    '')};  lc=lc+1; %Launch Platform
        Table1(lc) = {AddCell(num2str(Data(j).controlboardnum),                               5, c2,    '')};  lc=lc+1; %CPU
        switch Data(j).ice
            case 1
                iceD='Y';
            case 0
                iceD = 'N';
        end
        Table1(lc) = {AddCell(iceD,               5, c2,   '')};  lc=lc+1; %Ice detection Y/N
        Table1(lc) = {AddCell(num2str(Data(j).oxysens_snum),             5, c2,   '')};  lc=lc+1; %OXYGEN/optode ID
        fpp=getargo(Data(j).wmo_id);
        
        if ~isempty(fpp)
            if(isempty(fpp(end).voltage))
                try
                    volts=fpp(end).parkbatteryvoltage;
                catch
                    if isfield(fpp,'SBEpumpvoltage')
                        volts=fpp(end).SBEpumpvoltage;
                    else
                        volts=NaN;
                    end
                end
           else
                volts=fpp(end).voltage;
            end
        else
            volts=NaN;
        end
        Table1(lc) = {AddCell(num2str(volts),                5, c2,   '')};  lc=lc+1; %Last Park voltage
        if ~isempty(fpp)
            Table1(lc) = {AddCell(num2str(fpp(end).profile_number),                     5, c2,   '')};  lc=lc+1; %Cycles
        else
            Table1(lc) = {AddCell(num2str(0),                     5, c2,   '')};  lc=lc+1; %Cycles
        end
        if Data(j).iridium
            possyst='GPS';
        else
            possyst='Argos';
        end
        Table1(lc) = {AddCell(possyst,                   5, c2,   '')};  lc=lc+1; %System
        if ~isempty(fpp)
            try
                dtv=fpp(end).datetime_vec(1,:);
                lastTX=[num2str(dtv(3)) '/' num2str(dtv(2)) '/' num2str(dtv(1)) ];
            catch
                lastTX=' ';
            end
        else
            lastTX=' ';
            
        end
        Table1(lc) = {AddCell(lastTX,                    5, c2,   '')};  lc=lc+1; %Last Tx
        %         Table1(lc) = {AddCell(sprintf('%0.0f', Data(j).LastTxDaysAgo),     5, c2,   '')};  lc=lc+1; %Days Ago since last Tx
        if ~isempty(fpp)
            try
                Table1(lc) = {AddCell(sprintf('%0.0f', (fpp(end).jday(1)-fpp(1).jday(1))),   5, c2,   '')};  lc=lc+1; %Days in operation=Txlast - deploy
            catch
                try
                Table1(lc) = {AddCell(sprintf('%0.0f', (fpp(end).jday(1)-fpp(2).jday(1))),   5, c2,   '')};  lc=lc+1; %Days in operation=Txlast - deploy
                catch
                    dbdat=getdbase(fpp(end).wmo_id);
                end
            end
                
        else
            o=0;
            Table1(lc) = {AddCell(sprintf('%0.0f', o),   5, c2,   '')};  lc=lc+1; %Days in operation=Txlast - deploy
        end
        %         Table1(lc) = {AddCell(Data(j).EndMissionStatus,                    5, c2,   '')};  lc=lc+1; %
    end
    %close new column:
    Table1(lc) = {'</tr>'};
    lc         = lc+1;
    
    %CONVERT TABLE FROM CELL ARRAY TO STRING:
    Table1 = strvcat(cellstr(Table1(1:lc-1)));
    
    %COMBINE THE TABLE INTO THE ORIGINAL HTML FILE:
    [nrows,ncols] = size(strin);             %size of original html file
    s1            = strin(1:Index-2,    :);  %everything before the table
    s2            = strin(Index+7:nrows,:);  %everything after the table
    strout        = strvcat(s1, Table1, s2);  %add table to before and after
    
    
%      Table1(lc) = {'</table></body></html>'};
%     strout     = '';
%     disp(lc);
    
%     for j=1:lc
%         str = strtrim(cell2mat(Table1(j)));
%         strout = strcat(strout, str);
%     end

% end








%===================================================================
% CONSTRUCT A SINGLE LINE OF HTML CODE FOR SINGLE TABLE CELL ROW
% Inputs:
%      line:      - single line of text to display in cell
%      cellcolor  - background color ex white=[1 1 1]
%      fontsize   - 1, 2, 3
%      href:      - hyperlink reference to another html file=filename 
%                   thus: <a href="Index_HullID.html">Hull-ID</a>
% Output:
%      strout:    - single line of html code defining table row entry
%====================================================================
function strout = AddCell(line, fontsize, cellcolor, href)
%begin
    %cell background color make rgb = "%RRGGBB"
    rgb = round(cellcolor*255);
    rgb = sprintf('#%02x%02x%02x',rgb(1),rgb(2),rgb(3));
    
    %draw a cell outline even if no string is present:
    if (isempty(line)) line = '&nbsp;'; end;
    strout = '';
    
    %font size:
    fs = fontsize-2;
    if (isnumeric(fontsize)) fs=num2str(fs); end;
    
    if (isempty(href))
        %add cell row to table with no hyperlink:
%         strout = ['<td bgcolor="', bgcolor, '" font size="', fs, '" face="Arial" >', line, '</td>'];
        strout = ['               <td align="left" bgcolor="', rgb, '"><font size="', fs, '"  face="Arial Narrow">', line, '</td>'];
    else
        %this bit adds a hyperlink to the text with href as the linked html file
        line   = ['<a href="', href, '">', line, '</a>'];
%         strout = ['<td> <font size="', fs, '"  face="Courier New" ><input type="button" style="bgcolor: #FF0000; font-family: Tahoma" value="HullID: ', line, '" name="B3">', '</td>'];
        strout = ['<td> <align="left" bgcolor="', rgb, '"><font size="', fs, '"  face="Arial Narrow">', line, '</td>'];
    end
    
%end



% 
% %====================================================================
% %html code to display fancy buttons
% %====================================================================
% function str = jshead()
% %begin
%     str = '<head>';
%     str = strcat(str, '<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">');
%     str = strcat(str, '<title>New Page 1</title>');
%     str = strcat(str, '<script language="JavaScript">');
%     str = strcat(str, '<!--');
%     str = strcat(str, 'function FP_preloadImgs() {//v1.0');
%     str = strcat(str, ' var d=document,a=arguments; if(!d.FP_imgs) d.FP_imgs=new Array();');
%     str = strcat(str, ' for(var i=0; i<a.length; i++) { d.FP_imgs[i]=new Image; d.FP_imgs[i].src=a[i]; }');
%     str = strcat(str, '}');
% 
%     str = strcat(str, 'function FP_swapImg() {//v1.0');
%     str = strcat(str, ' var doc=document,args=arguments,elm,n; doc.$imgSwaps=new Array(); for(n=2; n<args.length;');
%     str = strcat(str, 'n+=2) { elm=FP_getObjectByID(args[n]); if(elm) { doc.$imgSwaps[doc.$imgSwaps.length]=elm;');
%     str = strcat(str, 'elm.$src=elm.src; elm.src=args[n+1]; } }');
%     str = strcat(str, '}');
% 
%     str = strcat(str, 'function FP_getObjectByID(id,o) {//v1.0');
%     str = strcat(str, ' var c,el,els,f,m,n; if(!o)o=document; if(o.getElementById) el=o.getElementById(id);');
%     str = strcat(str, ' else if(o.layers) c=o.layers; else if(o.all) el=o.all[id]; if(el) return el;');
%     str = strcat(str, ' if(o.id==id || o.name==id) return o; if(o.childNodes) c=o.childNodes; if(c)');
%     str = strcat(str, ' for(n=0; n<c.length; n++) { el=FP_getObjectByID(id,c[n]); if(el) return el; }');
%     str = strcat(str, ' f=o.forms; if(f) for(n=0; n<f.length; n++) { els=f[n].elements;');
%     str = strcat(str, ' for(m=0; m<els.length; m++){ el=FP_getObjectByID(id,els[n]); if(el) return el; } }');
%     str = strcat(str, ' return null;');
%     str = strcat(str, '}');
%     str = strcat(str, '// -->');
%     str = strcat(str, '</script>');
%     str = strcat(str, '</head>');
%     str = strcat(str, '<body onload="FP_preloadImgs(/*url*/''Images/button3.jpg'',/*url*/''Images/button4.jpg'',/*url*/''Images/button6.jpg'',/*url*/''Images/button7.jpg'')">');
% %end
% 
% 
% 
% %==========================================================
% %                   [CHANGE THE FONT TYPE IN THE GRID]
% %==========================================================
% function OnClickButton_uiMouse(src,evt)
% %begin
%   
%     disp('hello');
%     
% %end
% 


