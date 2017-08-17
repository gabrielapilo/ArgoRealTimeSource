% UpdateTechIndexPage
%
%=======================================================================================
% # CONSTRUCTS THE INDEX WEB PAGE GIVEN THE IndexPageInfo ARRAY OF ALL FLOATS
%=======================================================================================
% NOTE  - the only options for sorting are currently HULLID, WMOID, DEPORDER (deployment order) and
% ARGOSID, all caps.

function UpdateTechIndexPage(SortBy)
    global ARGO_SYS_PARAM
    global THE_ARGO_FLOAT_DB
% Note - removed from webUpdatePages to be run separately whenever a new float is deployed.
%
% %begin   
    %CELL BACKGROUND COLORS:
   Red   = [0.9 0.5 0.5];
   Gray  = [0.95 0.95 0.95];
   Highl = [0.85 0.85 0.85];
% COLUMN COLORS: set highlight color for each sorted column to dark gray
    c1=Red;   c2=Gray;  c3=Gray;  c4=Gray;  c5=Gray;  c6=Gray;  c7=Gray;  c8=Gray;  c9=Gray; 
    c10=Gray; c11=Gray; c12=Gray; c13=Gray; c14=Gray; c15=Gray; c16=Gray; c17=Gray; c18=Gray;
%     
   
% destfile=[ARGO_SYS_PARAM.folder_dest, '/index.html'];
% SortBy = 'HULLID';  
        
%     %CONSTRUCT THE HTML FILE: ADD DATE/TIME UNDER TITLE:
    htmlsrc  = [ARGO_SYS_PARAM.root_dir 'src/WebSourceCode/Template_Index.html'];
    htmlCode = LoadTextFile(htmlsrc); 
    htmlCode = Replace(htmlCode, '[DATE1]', datestr(now));
    htmlCode = Replace(htmlCode, '[SORTING]', SortBy);
    getdbase(-1);
    db = THE_ARGO_FLOAT_DB;
    destfile2 = [];

    
%     %SORT TABLE BY:
    switch upper(SortBy)
        case {'DEPORDER'};        %   fprintf(' [01] Constructing Index Table.....:  Sort By Hull ID \n');
            Data = sortstruc(db, 'deploy_num');
             destfile = [ARGO_SYS_PARAM.web_dir, '/tech/IndexAU_DepOrder.html'];
        case {'HULLID'};        %   fprintf(' [01] Constructing Index Table.....:  Sort By Hull ID \n');
            Data = sortstruc(db, 'maker_id');
             destfile = [ARGO_SYS_PARAM.webdir, '/tech/index.html'];
             destfile2 = [ARGO_SYS_PARAM.webdir, '/tech/IndexAU_HullID.html'];
             
        case {'ARGOSID'};       %   fprintf(' [02] Constructing Index Table.....:  Sort By Argos ID \n');
            Data = sortstruc(db, 'argos_id');
            destfile = [ARGO_SYS_PARAM.webdir, '/tech/IndexAU_ArgosID.html'];
            
        case {'WMOID'};          %  fprintf(' [03] Constructing Index Table.....:  Sort By WMO ID \n');
            Data = sortstruc(db, 'wmo_id');
            destfile = [ARGO_SYS_PARAM.webdir, '/tech/IndexAU_WmoID.html'];
            
%         case {'LAUNCHDATE'};     %  fprintf(' [04] Constructing Index Table.....:  Sort By Deployment Date \n');
%                                    Data = sortstruc(IndexPageInfo, 'LaunchDate');
%             
%         case {'CYCLES'};         %  fprintf(' [05] Constructing Index Table.....:  Sort By Number of Profiles \n');
%                                    Data = sortstruc(IndexPageInfo, 'Cycles');
% 
%         case {'VOLTAGE'};        %  fprintf(' [06] Constructing Index Table.....:  Sort By Voltage \n');
%                                    Data = sortstruc(IndexPageInfo, 'ParkVoltage');
%                              
%         case {'STATUS'};         %  fprintf(' [07] Constructing Index Table.....:  Sort By Status \n');
%                                    Data = sortstruc(IndexPageInfo, 'Status');
%                              
%         case {'SHIP'};           %  fprintf(' [08] Constructing Index Table.....:  Sort By Vessel \n');
%                                    Data = sortstruc(IndexPageInfo, 'DeployPlatform');
%                              
%         case {'SYSTEM'};         %  fprintf(' [09] Constructing Index Table.....:  Sort By Positioning System \n');
%                                    Data = sortstruc(IndexPageInfo, 'PositioningSystem');
%                              
%         case {'LASTTX'};         %  fprintf(' [10] Constructing Index Table.....:  Sort By Last Tx Date \n');
%                                    Data = sortstruc(IndexPageInfo, 'LastTransmission');
%                              
%         case {'TXDAYSAGO'};      %  fprintf(' [11] Constructing Index Table.....:  Sort By Last Tx Days Ago \n');
%                                    Data = sortstruc(IndexPageInfo, 'LastTxDaysAgo');
% 
%         case {'DAYSOPERATIONAL'};%  fprintf(' [12] Constructing Index Table.....:  Sort By Active Days Operational \n');
%                                    Data = sortstruc(IndexPageInfo, 'DaysInOperation');                             
%                              
    end
    
%     %INSERT THE FLOAT INFO INTO THE INDEX TABLE:
    htmlCode = ReplaceIndexTable(htmlCode, Data);
    SaveTextFile(destfile, htmlCode, 'wt');
    system(['chmod 777 ' destfile])
    if ~isempty(destfile2)
        SaveTextFile(destfile2, htmlCode, 'wt');
    system(['chmod 777 ' destfile2])
    end
% %     playtone(3000,8000,0.1,0.05);
%     pause(0.1);
%end





%=======================================================================================
% #  INSERTS THE ENTRIES INTO THE MAIN INDEX TABLE OF THE HTML FILE
% # The table is manually created by inserting rows and columns to reflect
% # the data. Look for the keyword [ENGINEERINGTABLE] to locate the first
% # row and column cell of the table.
% #
% # Inputs:
% #       strin:     the input html file to modify
% #           allFloatInfo:  -information about each float, array of structures
% #                           1xN struct array with fields:
% #                                HullID
% #                                ArgosID
% #                                WmoID
% #                                Status
% #                                ParkVoltage
% #                                Cycles
% #                                LastTransmission
% #                                DeepestPressure
% #
% # Outputs:
% #       strout:    the modified html file output with table added:
% #
% # HTML TABLE LOOKS LIKE:
% #			<tr>
% #				<td>[ENGINEERINGTABLE]</td>
% #				<td>&nbsp;</td>
% #			</tr>
% #			<tr>
% #				<td>&nbsp;</td>
% #				<td>&nbsp;</td>
% #			</tr>
%=======================================================================================
% function strout = ReplaceIndexTable(strin, Data, SortBy)
%     global ARGO_SYS_PARAM
% %begin
%     %CHECK FOR INPUT ERRORS:
%     strout = strin;
%     if (isempty(strin)) return; end;
%     if (isempty(Data))  return; end;
%     
%     %LOOK FOR THE KEYWORD [TABLE1] FIRST ROW AND COL:
%     Index = strvcmp(strin, '[TABLE1]');
%     if (isempty(Index)) return; end;
%  
%     %CELL BACKGROUND COLORS:
%     Red   = [0.9 0.5 0.5];
%     Gray  = [0.95 0.95 0.95];
%     Highl = [0.85 0.85 0.85];
%     
%     %COLUMN COLORS: set highlight color for each sorted column to dark gray
%     c1=Red;   c2=Gray;  c3=Gray;  c4=Gray;  c5=Gray;  c6=Gray;  c7=Gray;  c8=Gray;  c9=Gray; 
%     c10=Gray; c11=Gray; c12=Gray; c13=Gray; c14=Gray; c15=Gray; c16=Gray; c17=Gray; c18=Gray;
%     
%     %SORT TABLE BY:
%  %     switch upper(SortBy)
%         case {'HULLID'};     c2=Highl;  strin = Replace(strin, '[SORTING]', 'Hull-ID');
%         case {'ARGOSID'};    c3=Highl;  strin = Replace(strin, '[SORTING]', 'Argos-ID');
%         case {'WMOID'};      c4=Highl;  strin = Replace(strin, '[SORTING]', 'WMO-ID');
%         case {'STATUS'};     c5=Highl;  strin = Replace(strin, '[SORTING]', 'Status: Active/Overdue/Dead');
%         case {'LAUNCHDATE'}; c7=Highl;  strin = Replace(strin, '[SORTING]', 'Deployment Date');
%         case {'SHIP'};       c8=Highl;  strin = Replace(strin, '[SORTING]', 'Deployment Ship');
%         case {'VOLTAGE'};   c12=Highl;  strin = Replace(strin, '[SORTING]', 'Increasing (Latest) Battery Voltage');  
%         case {'CYCLES'};    c13=Highl;  strin = Replace(strin, '[SORTING]', 'Increasing Number of Profiles');
%         case {'SYSTEM'};    c14=Highl;  strin = Replace(strin, '[SORTING]', 'Transmission System Argos/Iridium');
%         case {'LASTTX'};    c15=Highl;  strin = Replace(strin, '[SORTING]', 'Latest Transmission Date');    
%     end
% 
%     %16 COLS TABLE HEADER:
%     header = {'No.',                ...    %1 row count
%               'Hull ID',            ...    %2 hyperlink='IndexAU_HullID.html'
%               'Argos ID',           ...    %3 hyperlink='IndexAU_ArgosID.html'
%               'WMO ID',             ...    %4 hyperlink='IndexAU_WmoID.html'
%               'Status',             ...    %5 hyperlink='IndexAU_Status.html'
%               'Argo-RT',            ...    %6 profile link page
%               'Launch Date',        ...    %7 hyperlink='IndexAU_LaunchDate.html'
%               'Deploy Ship',        ...    %8 hyperlink='IndexAU_Ship.html'
%               'CPU/Model',          ...    %9 APF8/APF9A,APF9I
%               'Ice',                ...    %10 ice detection yes/no
%               'Oxygen Sensor',      ...    %11 oxygen optode id
%               'Volts',              ...    %12 hyperlink='IndexAU_Voltage.html'
%               'Cycles',             ...    %13 hyperlink='IndexAU_Cycles.html'
%               'System',             ...    %14 hyperlink='IndexAU_System.html'
%               'Last Tx',            ...    %15 hyperlink='IndexAU_LastTx.html'
%               'Tx Days Ago'         ...    %16 hyperlink='IndexAU_TxDaysAgo.html'
%               'Days Operational',   ...    %17 hyperlink='IndexAU_DaysOperational.html'
%               'Failure Mode',       ...    %18 failure mode from our database 
%             };
%           
%     %INSERT TABLE HEADER INTO HTML FILE: 
%    lc     = 1;  %line counter for the table of cells
%     nc     = length(header);
%     nr     = length(Data);
%     Table1 = cell((nc+2)*(nr+2),1);   %using cell arrays is faster
%     
%     %CONSTRUCT TABLE HEADER - NEW ROW:
%     Table1(lc) = {'        <tr>'}; 
%     lc         = lc+1;
%     
%     for j=1:nc
%         %make each table row header a hyperlink to another sorted table in same web page
%         href  = '';
%         if (j==2)  href=['IndexAU_HullID.html'];          end;
%         if (j==3)  href=['IndexAU_ArgosID.html'];         end;
%         if (j==4)  href=['IndexAU_WmoID.html'];           end;
%         if (j==5)  href=['IndexAU_Status.html'];          end;
%         if (j==7)  href=['IndexAU_LaunchDate.html'];      end;
%         if (j==8)  href=['IndexAU_Ship.html'];            end;
%         if (j==12) href=['IndexAU_Voltage.html'];         end;
%         if (j==13) href=['IndexAU_Cycles.html'];          end;
%         if (j==14) href=['IndexAU_System.html'];          end;
%         if (j==15) href=['IndexAU_LastTx.html'];          end;
%         if (j==16) href=['IndexAU_TxDaysAgo.html'];       end;
%         if (j==17) href=['IndexAU_DaysOperational.html']; end;
%         
%         Table1(lc) = {AddCell(cell2mat(header(j)), 4, Red, href)}; 
%         lc         = lc+1;
%     end
%     Table1(lc) = {'        </tr>'}; 
%     lc=lc+1;
    
    %PARAMETER VALUES: ADD THE DATA ROWS TO THE TABLE:
%     nr = length(Data);
%     for j=1:nr
%         %new column:
%         Table1(lc) = {'        <tr>'}; 
%         lc         = lc+1;
%         
%         %hyperlink for HullID technical page:
%         s1     = num2str(Data(j).HullID);
%         s2     = num2str(Data(j).WmoID);
%         href1  = ['AU/', s1, '/Hull_', s1, '.html'];
%         href2  = [ARGO_SYS_PARAM.web_dir '/floats/', s2, '/floatsummary.html'];
%         
%         %insert individual row cells
%         Table1(lc) = {AddCell(num2str(j),                                  3, c1,    '')};  lc=lc+1; %No.
%         Table1(lc) = {AddCell(num2str(Data(j).HullID),                     3, c2, href1)};  lc=lc+1; %Hull-ID + hyperlink page
%         Table1(lc) = {AddCell(num2str(Data(j).ArgosID),                    3, c3,    '')};  lc=lc+1; %Argos-ID
%         Table1(lc) = {AddCell(num2str(Data(j).WmoID),                      3, c4,    '')};  lc=lc+1; %WMO-ID
%         Table1(lc) = {AddCell(num2str(Data(j).Status),                     3, c5,    '')};  lc=lc+1; %Status
%         Table1(lc) = {AddCell('Profile',                                   3, c6, href2)};  lc=lc+1; %Ann's profile page hyperlink
%         Table1(lc) = {AddCell(Data(j).LaunchDate,                          3, c7,    '')};  lc=lc+1; %Launch Date
%         Table1(lc) = {AddCell(strtrim(Data(j).DeployPlatform),             3, c8,    '')};  lc=lc+1; %Launch Platform
%         Table1(lc) = {AddCell(Data(j).cpuID,                               3, c9,    '')};  lc=lc+1; %CPU
%         Table1(lc) = {AddCell(num2str(Data(j).IceDetection),               3, c10,   '')};  lc=lc+1; %Ice detection Y/N
%         Table1(lc) = {AddCell(num2str(Data(j).OxygenSensorSN),             3, c11,   '')};  lc=lc+1; %OXYGEN/optode ID
%         Table1(lc) = {AddCell(num2str(Data(j).ParkVoltage),                3, c12,   '')};  lc=lc+1; %Last Park voltage
%         Table1(lc) = {AddCell(num2str(Data(j).Cycles),                     3, c13,   '')};  lc=lc+1; %Cycles
%         Table1(lc) = {AddCell(Data(j).PositioningSystem,                   3, c14,   '')};  lc=lc+1; %System
%         Table1(lc) = {AddCell(Data(j).LastTransmission,                    3, c15,   '')};  lc=lc+1; %Last Tx
%         Table1(lc) = {AddCell(sprintf('%0.0f', Data(j).LastTxDaysAgo),     3, c16,   '')};  lc=lc+1; %Days Ago since last Tx
%         Table1(lc) = {AddCell(sprintf('%0.0f', Data(j).DaysInOperation),   3, c17,   '')};  lc=lc+1; %Days in operation=Txlast - deploy
%         Table1(lc) = {AddCell(Data(j).EndMissionStatus,                    3, c18,   '')};  lc=lc+1; %Battery Pack style
%         
%         %close new column:
%         Table1(lc) = {'        </tr>'}; 
%         lc         = lc+1;
%     end
% 
%     %CONVERT TABLE FROM CELL ARRAY TO STRING:
%     Table1 = strvcat(cellstr(Table1(1:lc-1)));
% 
%     %COMBINE THE TABLE INTO THE ORIGINAL HTML FILE:
%     [nrows,ncols] = size(strin);             %size of original html file
%     s1            = strin(1:Index-2,    :);  %everything before the table
%     s2            = strin(Index+7:nrows,:);  %everything after the table
%     strout        = strvcat(s1, Table1, s2);  %add table to before and after
% %end
% 
% 
% 
% 
% 
% 
% %===================================================================
% % CONSTRUCT A SINGLE LINE OF HTML CODE FOR SINGLE TABLE CELL ROW
% % Inputs:
% %      line:      - single line of text to display in cell
% %      cellcolor  - background color ex white=[1 1 1]
% %      fontsize   - 1, 2, 3
% %      href:      - hyperlink reference to another html file=filename 
% %                   thus: <a href="Index_HullID.html">Hull-ID</a>
% % Output:
% %      strout:    - single line of html code defining table row entry
% %====================================================================
% function strout = AddCell(line, fontsize, cellcolor, href)
% %begin
%     %cell background color make rgb = "%RRGGBB"
%     rgb = round(cellcolor*255);
%     rgb = sprintf('#%02x%02x%02x',rgb(1),rgb(2),rgb(3));
%     
%     %draw a cell outline even if no string is present:
%     if (isempty(line)) line = '&nbsp;'; end;
%     strout = '';
%     
%     %font size:
%     fs = fontsize;
%     if (isnumeric(fontsize)) fs=num2str(fontsize); end;
%     
%     if (isempty(href))
%         %add cell row to table with no hyperlink:
%         strout = ['               <td align="left" bgcolor="', rgb, '"><font size="', fs, '"  face="Arial Narrow">', line, '</td>'];
%     else
%         %this bit adds a hyperlink to the text with href as the linked html file
%         line   = ['<a href="', href, '">', line, '</a>'];
%         strout = ['               <td align="left" bgcolor="', rgb, '"><font size="', fs, '"  face="Arial Narrow">', line, '</td>'];
%     end
%     
% %end
% 
% 
% 









