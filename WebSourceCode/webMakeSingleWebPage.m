%=========================================================================================
% CONSTRUCTS A SINGLE WEB PAGE GIVEN THE WMO ID OF THE FLOAT: NOTE THAT
% THE MAIN INDEX TABLES ARE NOT UPDATED.  USES THE ArgoRT DIRECTORY
%
% Created:      24/03/2010; V.Dirita / Appx Run time: 65.sec (first time)
%                                                     25.sec (thereafter)
% Inputs:       wmoID: -numeric value of the wmo ID of profiler to update
%               ex: wmoID=1901119
% rebuild - 1=rebuild whole file, 0 = only add new profiles (def=0)
%
% Description:  Loads the matfile for the given float and generates
%               all html files including gif files.  
%
% Requirements: dbaseConfigs.mat    -The database binary mat file.
%               xls      -Argo master excel file.
%
% Returns:      IndexPageInfo:      -This structure has information used by the main index
%                                    page table row for the float.
%==========================================================================================
function IndexPageInfo = webMakeSingleWebPage(wmoID,rebuild)
%begin
    %DEFINE GLOBAL DIRECTORIES:
    global FOLDER_HTML  FOLDER_DBASE  
    global ARGO_SYS_PARAM

tic
    if nargin<2 || isempty(rebuild)
        rebuild = 0;
    end
%VERIFY INPUT: / START TIMER:
    IndexPageInfo = [];
    if (isempty(wmoID)) return; end;
    tic;
%     fprintf('\n');
%     fprintf('CONSTRUCTING WEB PAGE FOR: %d \n', wmoID);
%     fprintf('----------------------------------\n');
%     
    %LOAD THE FLOAT PROFILE INFO FROM ArgoRT:
%     fprintf('[1] Loading dbase From ArgoRT Network Directory...: ');
    [fpp,dbase] = getargo(wmoID);
    if ~isempty(fpp)
        try
            HullID = dbase.maker_id;
            %         fprintf('Found Hull ID: %d \n', HullID);
        catch
            fprintf('DATABASE NOT FOUND,ABORT \n');
            fprintf('Error: dbase Not Found For WMO: %d \n', wmoID);
            return;
        end;
        
        %LOAD OUR DATABASE AND MAPS:
        Sensor=getadditionalinfo(wmoID);
        
        %LOAD THE WORLD MAP, SKIP IF ALREADY IN MEMORY:  WorldmapWide is -270 to +270 deg for overlap 116 MBytes
        %     fprintf('[3] Loading world map image into memory...........: ');
        %     if (isempty(WorldmapWide)) WorldmapWide=imread([ARGO_SYS_PARAM.worldmap 'WorldMapWide.jpg']); end;
        %     fprintf('Map Size %d x %d (layers %d) \n', size(WorldmapWide));
        
        %CREATE A HTML WEB FOLDER, IF ALREADY EXISTS THEN KEEP IT+CONTENTS: ex: '\\strait-hf\argoweb\tech\AU\1064'
        %     fprintf('[4] Creating/Replacing Output Folder..............: ');
        folder_dest = FOLDER_HTML;   %'\\strait-hf\argoweb\tech\AU\';
        destfolder  = [folder_dest, 'AU/', num2str(HullID)];
        
        if (exist(destfolder, 'dir')==7)
            bool=true;
        else
            try
                mkdir(destfolder);
                bool=true;
            catch
                fprintf('  ERROR: Unable to create new folder: %s \n', destfolder);
                bool = false;
                return;
            end
        end
        
        if (bool==false) fprintf(' ERROR Failed to create %s \n', destfolder); return; end;
        if (bool==true)  fprintf(' %s \n', destfolder); end;
        
        %CREATE AN HTML WEB PAGE:
        %     fprintf('[5] Constructing the HTML Web Page Components.....: \n');
        ConstructWebPage(dbase, Sensor, destfolder,fpp);
        
        %CREATE A STRUCTURE FOR INDEX PAGE:
        %     fprintf('[6] Constructing Index Page Structure Entry.......: \n');
        IndexPageInfo = ConstructIndexPageInfo(dbase, fpp, Sensor);
        
        %COPY BACKGROUND IMAGES:
        %     fprintf('[7] Copying Images and Bitmaps To Destination.....: \n');
        fcopy([ARGO_SYS_PARAM.Folder_html 'banner1.JPG'], [destfolder, '/banner1.JPG']);
        
        %DISPLAY ELAPSED TIMER:
        %     fprintf('[8] Completed Run Time %3d seconds.\n', fix(toc));
        %end
        
        
        system(['chmod o+r ' destfolder '/*']);
        system(['chmod 777 ' destfolder ]);

    end
toc




%=========================================================================================================
%                         CONSTRUCTS A SINGLE HTML WEB PAGE FOR A GIVEN FLOAT.
%      srcFolder:  source folder with tech, meta, traj, prof netcdf files.
%                  ex: "..\FilesNetcdf\NetcdfAU\1901119" 
%                  contains the files: {1901119_meta.nc; 1901119_tech.nc; 1901119_prof.nc; 1901119_traj.nc}
%
%      destFolder: destination folder containing the new html file + plots + trajectory etc..
%                  ex: "..\FullBrowser\FloatsAU\23\Hull_23.html"         -web page
%                      "..\FullBrowser\FloatsAU\23\Hull_23.txt"          -printable text file
%                      "..\FullBrowser\FloatsAU\23\Trajectory.png"       -trajectory map
%                      "..\FullBrowser\FloatsAU\23\Bathymetry.png"       -bathymetry map
%                      "..\FullBrowser\FloatsAU\23\Battery_Voltage.png"  -tech param plots
%===========================================================================================================
function ConstructWebPage(dbase, Sensor, destfolder,fpp)
%begin
    %GLOBALS FOR TESTING ONLY:    
%     global WorldmapWide

    %CHECK INPUTS:
    if (isempty(dbase))  ;    return; end;
    if (isempty(Sensor))  ;   return; end;
    if (isempty(destfolder)); return; end;
    if(isempty(fpp)); return;end

    %CONSTRUCT A FILENAME: Ex: Hull_2950.html 
    HullID   = dbase.maker_id;
    destfile = [destfolder, '/Hull_', num2str(HullID), '.html'];
%     fprintf('    [5.1] Creating HTML Destination Directory.....: %s \n', destfile);

    %GET THE HULL-ID, ARGOS-ID AND WMO-ID
    WMOID   = dbase.wmo_id;
    HullID  = dbase.maker_id;
    ArgosID = dbase.argos_id;
    Status  = dbase.status;  
    
%     [fpp]=getargo(dbase.wmo_id);
% prepare for map of positions:
    for i=1:length(fpp)
        
        if(~isempty(fpp(i).lat))
            lat(i)=fpp(i).lat(1);
            lon(i)=fpp(i).lon(1);
        else
            lat(i)=NaN;
            lon(i)=NaN;
        end
        
    end
    

%     fprintf('    [5.2] Current Float Status....................: %s \n', Status);
    
    %CONSTRUCT TRAJECTORY FIGURES "Trajectory.png":
%     t='trajfigure'
    trajfig = ConstructTrajectoryFigure(dbase, lat, lon, destfolder);
%     playtone(3000,8000,0.1,0.05);
%     fprintf('    [5.3] Constructing Trajectory Figure/saving...: %s ', trajfig);
    if (isempty(trajfig)) fprintf(' FAILED \n'); 
%     else fprintf(' OK \n'); 
    end;
    
    %CONSTRUCT BATHYMETRY FIGURES "Bathymetry.png":
%     t='bathyfigure'
    bathyfig = ConstructBathymetryFigure(dbase,lat, lon, destfolder);
%     playtone(3000,8000,0.1,0.05);
%     fprintf('    [5.4] Constructing Bathymetry Figure/saving...: %s ', bathyfig);
    if (isempty(trajfig)) fprintf(' FAILED \n');
%     else fprintf(' OK \n'); 
    end;

    %LOAD HTML FILE TEMPLATE:
%     fprintf('    [5.5] Loading HTML Template File..............: Template1_Hull.html ');
    htmlCode = LoadTextFile('Template2_Hull.html');
%     playtone(3000,8000,0.1,0.05);
    if (isempty(htmlCode)) fprintf(' FAILED \n'); 
%     else fprintf(' OK \n'); 
    end;
    
    %INSERT PREV-NEXT HULL ID HYPERLINKS FOR FASTER NAVIGATION:
%     fprintf('    [5.6] Inserting Prev-Next Hull Hyperlinks.....: OK \n');
    htmlCode = HTMLreplacePrevNextLinks(htmlCode, HullID);
%     playtone(3000,8000,0.1,0.05); 
    
    %REPLACE THE FIRST TABLE IN THE FILE, CONTAINS META INFORMATION
%     fprintf('    [5.7] Inserting Metadata Table into HTML......: OK \n');
    htmlCode = HTMLreplaceMetaTable(htmlCode, dbase, Sensor);
%     playtone(3000,8000,0.1,0.05);    
    
    %TECHNICAL ENGINEERING DATA:
%     fprintf('    [5.8] Inserting Engineering Table into HTML...: OK \n');
    htmlCode = HTMLreplaceEngineeringTable(htmlCode, fpp);
%     playtone(3000,8000,0.1,0.05);    
    
    %GENERATE FIGURES/PLOTS:
%     fprintf('    [5.9] Inserting Figures/Plots Table into HTML.: OK \n');
    figNames = CreateFigures(dbase, destfolder, fpp);
    htmlCode = HTMLreplaceTechPlots(htmlCode, figNames);
%     playtone(3000,8000,0.1,0.05);    
    
    %BATHYMETRY TABLE:
%     fprintf('    [5.10] Inserting Bathymetric Table into HTML..: OK \n');
    htmlCode = HTMLreplaceBathymetryTable(htmlCode, lat, lon, dbase);
%     playtone(3000,8000,0.1,0.05);

    %SAVE HTML CODE TO DESTINATION FILE:
    %  fprintf('    [5.12] Saving New HTML Filename...............: %s \n', destfile);
    SaveTextFile(destfile, htmlCode, 'wt');
    %playtone(3000,8000,0.1,0.05);
    %fprintf(' \n');
    pause(0.5);


%end


%############################################ TRAJECTORY PLOTTING FUNCTIONS ############################################


%===============================================================================
% CONSTRUCTS A TRAJECTORY MAP OF THE FLOAT FROM THE LAT-LON POSITIONS.
% This function requires the use of the bitmap image: WorldMap.jpg (3600x7200)
% THE FIGURE IS SAVED IN THE APPROPRIATE DESTINATION FOLDER:
% The output filename: "TrajectoryMap.png" has 2 plots: small and large region
%===============================================================================
function trajfig = ConstructTrajectoryFigure(dbase, lat, lon, destfolder )
%begin
    %RETURN IF NO TRAJECTORY POINTS AVAILABLE:
%     trajfig = '';
    if (isempty(dbase))        return; end;
    if (isempty(destfolder))   return; end;
    
    %REQUIRE LAT,LON DATA FOR BATHYMETRIC PLOTS:
    if ((isempty(lat)) || (isempty(lon))) return; end;

    %DETERMINE THE REGION WHERE THE FLOAT IS AND RETURN PATCH 2X2 DEGREES:
    figure(2);
    clf;
%     t='plotmap'

    plotmap_argo(lat,lon) ;

    %PLOT THE MAP TRAJECTORY:
    set(gcf, 'Menubar', 'none');
    Title1 = sprintf('Trajectory HULL: %d:', dbase.maker_id);
    Title2 = sprintf('Last Updated: %s', datestr(now));
    title({Title1; Title2}, 'Fontsize',  14, 'Fontname', 'Arial');
    xlabel('Longitude');
    ylabel('Latitude');
    set(gcf, 'PaperPosition', [0 0 20 10]        );  %in cm
    set(gcf, 'Position',      [300 400 1200 600] );
    set(gca, 'Position',      [0.1 0.1 0.80 0.75]);
    set(gca, 'fontweight',    'bold'             );
    set(gcf, 'Color',         [0.9 0.9 1]        );
    set(gca, 'fontsize',  12);
    set(gcf, 'Renderer', 'painters');
%     axis image;
    drawnow
    pause(0.1);
    
    %SAVE TO DESTINATION .PNG FILE:- GRAB AS FRAME FOR BETTER IMAGE QUALITY:
    trajfig  = 'Trajectory.png';
    filename = [destfolder, '/', trajfig];
    drawnow
        
    if(ispc)
        print('-dtiff',filename);
    else
        try
            my_save_fig([filename],'clobber')
        end
    end
    
    system(['chmod o+r ' filename '*']);
%    F        = getframe(gcf);
%     imwrite(F.cdata, filename, 'png');
%     pause(0.1);
%end


%############################################ BATHYMETRY PLOTTING FUNCTIONS ############################################


%===============================================================================
% CONSTRUCTS A BATHYMETRY PLOT FOR THE GIVEN TRAJECTORY DATA
%===============================================================================
function bathyfig = ConstructBathymetryFigure(dbase, lat, lon, destfolder)
global Depths
%begin
colormap(jet)
    %GET LAT LON, REQUIRE LAT,LON DATA FOR BATHYMETRIC PLOTS:
    bathyfig  = '';
    
    if ((isempty(lat)) || (isempty(lon))); return; end;
    
    %LONGITUDES SHOULD BE 0-360 DEGREES, ANY NEGATIVE VALUES SIMPLY ADD 360:
    Index      = find(lon<0);
    lon(Index) = lon(Index)+360;
    %     Depths     = Depth(lat,lon);
    try
        [mindep]=get_ocean_depth_minonly(lat,lon);
        Depths=mindep;
    catch
        fprintf('Error: Topographic/Bathymetric software not found \n');
        Depths = [];
    end
    if (isempty(Depths)) return; end;
    
    %PLOT THE BATHYMETRY USING A PATCH:
    figure(2);
    clf;
    set(gcf, 'Units', 'pixels', 'Position', [300 300 600 500], 'Color', [0.9 0.9 1]);
    
    %BATHYMETRY DATA:
    bathyfig = 'Bathymetry.png';
    maxDepth = -(500*round(max(Depths)/500)+500);
    n        = length(Depths);
    x        = linspace(1,n,n);
    y        = -Depths;
    x        = [x,        n,        1,    1];   %close the bottom of the patch surface
    y        = [y, maxDepth, maxDepth, y(1)];   %close the bottom of the patch surface
    plot(x,y, 'linewidth', 2);
    hold on;
    patch(x,y,[0.5 0.5 0.8]);
    
    %CHANGE DEFAULT GRAPHICS PARAMETERS:
    set(gca, 'fontsize',          12        );
    set(gca, 'fontName',          'Arial'   );
    set(gca, 'linewidth',         1         );
    set(gcf, 'PaperPositionMode', 'auto'    );
    set(gcf, 'Renderer',          'painters');
    
    %LABEL THE AXES AND TITLE:
    xlabel('Sample No.',    'Fontsize', 13, 'Fontweight', 'bold');
    ylabel('Depth (dBars)', 'Fontsize', 13, 'Fontweight', 'bold');
    HullID = dbase.maker_id;
    Title1 = sprintf('Bathymetry Plot: HULL: %d', HullID);
    Title2 = sprintf('Last Updated: %s', datestr(now));
    title({Title1; Title2}, 'Fontsize', 14);
    grid on;
    
    %SAVE IT: - GRAB AS FRAME FOR BETTER IMAGE QUALITY:
    filename = [destfolder, '/', bathyfig]; 
    drawnow

if(ispc)
    print('-dtiff',filename);
else
    try
    my_save_fig([filename],'clobber')
    end
end

system(['chmod o+r ' filename '*']);
% F        = getframe(gcf);
%     imwrite(F.cdata, filename, 'png');
%     pause(0.1);
%end






%======================================================================================================================
%  INSERTS THE ENGINEERING PLOTS INTO THE HTML FILE
% The Figures/plots are linked to the table
%
% Inputs:
%       strin:       the input html file to modify
%       trajRecord:  trajectory record with positioning data
%       profRecord:  profile record with park/profile depth data
%
% Outputs:
%       strout:    the modified html file output with table added:
%
% HTML TABLE LOOKS LIKE:
%	<textarea rows="27" name="S1" cols="61" style="font-family: Arial monospaced for SAP; font-size: 12pt; font-weight: bold">
%     [BATHYMETRYTEXT1]
%     [BATHYMETRYTEXT2]
%   </textarea></p>
%
%======================================================================================================================
function strout = HTMLreplaceBathymetryTable(strin, lat, lon, dbase)

global Depths
%begin
    %CHECK FOR INPUT ERRORS:
    strout = strin;
    if (isempty(strin)) return; end;
    depth=Depths;
    %LOOK FOR THE KEYWORD [BATHYMETRYTEXT1] FIRST ROW AND COL:
    [nrows,ncols] = size(strin);
    Index         = strvcmp(strin, '[BATHYMETRYTEXT1]'); 
    if (isempty(Index)) return; end;
    [fpp]=getargo(dbase.wmo_id);
    for i=1:length(fpp)
        try;park_p(i)=fpp(i).park_p(1);catch;park_p(i)=NaN;end
        try;grounded(i)=fpp(i).grounded;catch;grounded=NaN;end
        try;parkpistonpos(i)=fpp(i).parkpistonpos;catch;parkpistonpos(i)=NaN;end
        try;profile_number(i)=fpp(i).profile_number;catch;profile_number(i)=NaN;end
        try;date_time(i,:)=fpp(i).datetime_vec(1,:);catch;date_time(i,:)=NaN;end
%         try;depth(i)=Depth(lat(i),lon(i));catch;depth(i)=NaN;end
    end
                
    %CONSTRUCT BATHYMETRIC TABLE: 
%     park_p         = dbasequery_GetParam(dbase, 'park_p');
%     grounded       = dbasequery_GetParam(dbase, 'grounded');
%     parkpistonpos  = dbasequery_GetParam(dbase, 'parkpistonpos');
%     profile_number = dbasequery_GetParam(dbase, 'profile_number');
%     datetime       = dbasequery_GetParam(dbase, 'datetime_vec');
%     depth          = Depth(lat,lon);
    Table          =                'No.  Date-Time:  Latitude  Longitude  Bathy  Park  Gnd  PPP';
    Table          = strvcat(Table, '---  ----------  --------  ---------  -----  ----  ---  ---');
    try n = length(depth); catch; return; end;
    
    %TABLE:
    for j=1:n
        try s1 = sprintf('%3d',       profile_number(j));  catch; s1 = '...';        end;
        try s2 = sprintf('%2.2s%1s%2.2s%1s%4.4s',  num2str(date_time(j,3)),'/',num2str(date_time(j,2)),'/',num2str(date_time(j,1)));  catch; s2 = '..........'; end;
        try s3 = sprintf('%8.3f',                lat(j));  catch; s3 = '........';   end;
        try s4 = sprintf('%9.3f',                lon(j));  catch; s4 = '........';   end;
        try s5 = sprintf('%5.0f',              depth(j));  catch; s5 = '....';       end;
        try s6 = sprintf('%4.0f',             park_p(j));  catch; s6 = '....';       end;
        try s7 = sprintf('%1s',            grounded(j));  catch; s7 = '.';          end;  
        try s8 = sprintf('%3d',        parkpistonpos(j));  catch; s8 = '...';        end;
        str    = [s1, '  ', s2, '  ', s3, '  ', s4, '  ', s5, '  ', s6, '  ', s7, '  ', s8];
        Table  = strvcat(Table, str);
    end
        
    %COMBINE THE TABLE INTO THE ORIGINAL HTML FILE:
    s1     = strin(1:Index-1,    :);  %everything before the table
    s2     = strin(Index+1:nrows,:);  %everything after the table
    strout = strvcat(s1, Table, s2);  %add table to before and after
    pause(0.1);
%end




%====================================================
% GET BATHYMETRIC VALUES AT GIVE LAT LON VECTORS
% Ensure that matlab path to /Bathymetry is specified
%====================================================
function h = Depth(lat,lon)
global ARGO_SYS_PARAM
%begin  
    %use local file with topography:
    try
%         h = -topongdc(lat,lon, [ARGO_SYS_PARAM.ocean_depth '.nc']);                     
[mindep,maxdep]=get_ocean_depth_maxmin(lat,lon);
h=mindep;
    catch
        fprintf('Error: Topographic/Bathymetric software not found \n');
        h = [];
    end
%end






%############################################ HTML TABLE RELATED FUNCTIONS ############################################



%=================================================================================
% SIMPLY ADDS A HORIZONTAL LIST OF 20 FLOATS BELOW THE TITLE OF THE TECH
% WEB PAGE, IT ALLOWS THE PREVIOUS OR NEXT FLOAT IN THE LIST TO BE VIEWED RATHER
% THAN RETURNING TO THE INDEX PAGE AND THEN SELECTING THE PREV/NEXT FLOAT IN THE
% LIST
%
% Inputs:
%   strin:       html code of the tech page to modify
%   HullID:      currently viewed hull ID for this tech page
%
% Outputs
%   strout:      modified html code with hyperlinked float list
%
% Looks for the keyword/line:
%   <a href="Index_ArgosID.html">[PREVNEXTHULL]</a>
%
% and replaces with appropriate list of 20 hull IDs and hlinked pages
%=================================================================================
function strout = HTMLreplacePrevNextLinks(strin, HullID)
%begin
    %CHECK FOR INPUT ERRORS:
    strout = strin;
    if (isempty(strin))  return; end;
    if (isempty(HullID)) return; end;
    
    %LOOK FOR THE KEYWORD [PREVNEXTHULL] = <a href="Index_ArgosID.html">[PREVNEXTHULL]</a>
    [nrows,ncols] = size(strin);
    Index         = strvcmp(strin, '[PREVNEXTHULL]');

    %LOAD DATABASE SUMMARY INTO MEMORY TO GET ALL HULL IDs: (DEPLOYED ONLY)
    AllHullIDs = dbaseGetAllHullIDs();
    if (isempty(AllHullIDs)) return; end;
    
    %LOOK FOR CURRENT HULL ID IN LIST AND GET 10 NEAREST HULL IDS:
    d = find(HullID==AllHullIDs);
    try
        d = d(1);
    catch
        strout = strvcat(strin(1:Index-1,:), strin(Index+1:nrows,:));
        return;
    end
    
    %GET 10 prev and 10 next NEAREST HULL IDS + THIS HULL ID IN THE MIDDLE:
    n = length(AllHullIDs);
    if (d<11)   d=11;   end;
    if (d>n-11) d=n-11; end;
    U    = AllHullIDs(d-10:d+10);
    line = [];
    
    for j=1:length(U)
        s1   = num2str(U(j));
        s2   = ['<a href="../', s1, '/Hull_', s1, '.html"><font color="#FFFF00">', s1, '</font></a>'];
        if (HullID==U(j)) s2 = ['<a href="../', s1, '/Hull_', s1, '.html"><font color="#00FFFF">[', s1, ']</font></a>']; end;
        line = [line, ' - ', s2]; 
    end
    
    %COMBINE THE TABLE INTO THE ORIGINAL HTML FILE:
    s1     = strin(1:Index-1,    :);  %everything before the table
    s2     = strin(Index+1:nrows,:);  %everything after the table
    strout = strvcat(s1, line, s2);  %add table to before and after
    pause(0.1);
        
%end


%======================================================================================================================
%  REPLACES THE METATABLE (FIRST TABLE) OF THE HTML FILE
% The Figures/plots are linked to the table
%
% Inputs:
%       strin:       the input html file to modify
%       dbase:       database with meta data
%
% Outputs:
%       strout:    the modified html file output with table added:
%
% HTML TABLE LOOKS LIKE:
%	<textarea rows="27" name="S1" cols="61" style="font-family: Arial monospaced for SAP; font-size: 12pt; font-weight: bold">
%     [BATHYMETRYTEXT1]
%     [BATHYMETRYTEXT2]
%   </textarea></p>
%
%======================================================================================================================
function strout = HTMLreplaceMetaTable(strin, dbase, Sensor)
%begin
    %CHECK FOR INPUT ERRORS:
    strout = strin;
    if (isempty(strin)) return; end;
    [fpp]=getargo(dbase.wmo_id);
    %LOOK FOR THE KEYWORD [BATHYMETRYTEXT1] FIRST ROW AND COL:
    try n=length(fpp);  catch; return; end;
    try HullID = dbase.maker_id; catch; return; end;

    if (n==0) return; end;
    
%     First, replace the title of the pages:
    strout = Replace(strout, 'New Page 1',  [num2str(dbase.wmo_id) '/'   num2str(dbase.maker_id) '/'       num2str(dbase.argos_id)]   );
    
    %Latest Profiler Status:
    strout = Replace(strout, '[HULL]',                num2str(dbase.maker_id)                   );
    strout = Replace(strout, '[CURRENTDATE]',         datestr(now)                                         );
    strout = Replace(strout, '[CURRENTSTATUS]',       dbase.status                              );
    strout = Replace(strout, '[STATUS]',              dbase.status                              );
    strout = Replace(strout, '[LASTTRANSMISSION]',    datestr(fpp(n).datetime_vec(1,:))                );
    strout = Replace(strout, '[ANOMALY]',             ''                                                   );
    try
        strout = Replace(strout, '[PARKVOLTAGE]',         num2str(fpp(n).parkbatteryvoltage)             );
        
    catch
        try
            strout = Replace(strout, '[PARKVOLTAGE]',     num2str(fpp(n).SBEpumpvoltage)             );
        catch
            strout = Replace(strout, '[PARKVOLTAGE]',     'NaN'                 );
        end
    end
    strout = Replace(strout, '[NUMBEROFPROFILES]',    num2str(fpp(n).profile_number  )             );
    strout = Replace(strout, '[OPERATIONALISSUES]',   '-'                                                  );
    strout = Replace(strout, '[ENDMISSIONDATE]',      ['Last Tx: ', datestr(fpp(n).datetime_vec(1,:))] );
    strout = Replace(strout, '[ENDMISSIONSTATUS]',     dbase.status                                         );
    
    %Profiler Identification IDs
    strout = Replace(strout, '[HULLID]',              num2str(dbase.maker_id)        );
    strout = Replace(strout, '[WMOID]',               num2str(dbase.wmo_id)          );
    strout = Replace(strout, '[ARGOSID]',             num2str(dbase.argos_id)        );
    strout = Replace(strout, '[MANUFACTURER]',        num2str(dbase.maker)           );
    strout = Replace(strout, '[INSTRUMENTREFERENCE]', num2str(dbase.wmo_inst_type)   );
    strout = Replace(strout, '[CPU]',                 num2str(dbase.controlboardnumstring) );
  
    %Sensor Configuration:
    S      = Sensor;
    strout = Replace(strout, '[SBESERIALNUMBER]',       [S.CTDtype, '; ', S.CTDSerialNo '; ', S.Firmware_Revision]);
    strout = Replace(strout, '[SENSORTEMPERATURE]',     [S.Temperature.Name ':   Units: ' S.Temperature.Units '  Symbol: [' S.Temperature.Symbol ']' ...
         '  Maker:  [ '   S.Temperature.Maker, ' ]  S/N:    [ '   S.Temperature.SerialNo, ' ]    Model:  [ ' S.Temperature.ModelNo ' ]']);
    strout = Replace(strout, '[SENSORCONDUCTIVITY]',    [S.Salinity.Name ':   Units: ' S.Salinity.Units '  Symbol: [' S.Salinity.Symbol ']' ...
         '  Maker:  [ '   S.Salinity.Maker, ' ]  S/N:    [ '   S.Salinity.SerialNo, ' ]    Model:  [ ' S.Salinity.ModelNo ' ]']);  
    strout = Replace(strout, '[SENSORPRESSURE]',        [S.Pressure.Name ':   Units: ' S.Pressure.Units '  Symbol: [' S.Pressure.Symbol ']' ...
         '  Maker:  [ '   S.Pressure.mfg, ' ]  S/N:    [ '   S.Pressure.SerialNo, ' ] ']);
     if dbase.oxy
    strout = Replace(strout, '[SENSOROXYGEN]',          [S.Oxygen.Name ':   Units: ' S.Oxygen.Units '  Symbol: [' S.Oxygen.Symbol ']' ...
         '  Maker:  [ '   S.Oxygen.mfg, ' ]  S/N:    [ '   S.Oxygen.SerialNo, ' ]    Model:  [ ' S.Oxygen.ModelNo ' ]']);
     else
         strout = Replace(strout, '[SENSOROXYGEN]',          [' No oxygen sensor present ']);
     end
     if dbase.tmiss
    strout = Replace(strout, '[SENSORTURBIDITY]',       [S.Transmissometer.Name ':   Units: ' S.Transmissometer.Units '  Symbol: [' S.Transmissometer.Symbol ']' ...
         '  Maker:  [ '   S.Transmissometer.mfg, ' ]  S/N:    [ '   S.Transmissometer.SerialNo, ' ]    Model:  [ ' S.Transmissometer.ModelNo ' ]']);
     else
         strout = Replace(strout, '[SENSORTURBIDITY]',          [' No transmissometer sensor present ']);
     end
     if dbase.flbb
         strout = Replace(strout, '[FLBB]',                  [S.FLBB.Name ':   Units: ' S.FLBB.Units '  Symbol: [' S.FLBB.Symbol ']' ...
             '  Maker:  [ '   S.FLBB.mfg, ' ]  S/N:    [ '   S.FLBB.SerialNo, ' ]    Model:  [ ' S.FLBB.ModelNo ' ]']);
     else
         strout = Replace(strout, '[FLBB]',          [' No FLBB sensor present ']);
     end

    strout = Replace(strout, '[TURBIDITYOTHER]',        ' '                                      );
 
    %Mission Programming:
    strout = Replace(strout, '[POSITIONINGSYSTEM]',      Sensor.UplinkSystem                  );
    strout = Replace(strout, '[BATTERYCONFIGURATION]',   Sensor.Battery_Configuration );
    strout = Replace(strout, '[ARGOSFREQUENCY]',         ''                                   ); % Sensor.PTTFrequencyMHz                       %Config.Argos.PTTFrequencyMHz     
    strout = Replace(strout, '[ARGOSREPETITIONPERIOD]',  num2str(dbase.reprate)    );
    strout = Replace(strout, '[TRANSMISSIONSYSTEMID]',   Sensor.UplinkSystemID                 );
    strout = Replace(strout, '[WMOINSTRUMENTTYPE]',      num2str(dbase.wmo_inst_type)); 
    strout = Replace(strout, '[CYCLETIMEHOURS]',         '240 (default but can change for Iridium floats)'                                   );
    strout = Replace(strout, '[UPTIMEHOURS]',            num2str(dbase.uptime)     );
    strout = Replace(strout, '[DOWNTIMEHOURS]',          num2str(dbase.parktime)   );
    strout = Replace(strout, '[PARKDEPTHDBARS]',         num2str(dbase.parkpres)   );
    strout = Replace(strout, '[PROFILEDEPTHDBARS]',      num2str(dbase.profpres)   );
    strout = Replace(strout, '[FIRMWARE]',               Sensor.Firmware_Revision );
    
    %Deployment Information:
    strout = Replace(strout, '[DEPLOYPOSITION]',      ['Lat: ', num2str(dbase.launch_lat), ' Lon: ', num2str(dbase.launch_lon)]);
    strout = Replace(strout, '[DEPLOYMISSION]',       '');
    strout = Replace(strout, '[DEPLOYSHIP]',          dbase.launch_platform);
    strout = Replace(strout, '[DEPLOYDATE]',          LongDateToDateTime(dbase.launchdate));
    strout = Replace(strout, '[DEPLOYPROBLEMS]',      ''        );         %dbasequery_History(Config.History, 'CODE#07', 'Field4') );
    pause(0.2);
%end





%=======================================================================
%  INSERTS THE ENTRIES INTO THE ENGINEERING DATA TABLE OF THE HTML FILE
% The table is manually created by inserting rows and columns to reflect
% the data. Look for the keyword [ENGINEERINGTABLE] to locate the first
% row and column cell of the table.
%
% Inputs:
%       strin:     the input html file to modify
%       dbase      tech data from netcdf file to add to html file
%
% Outputs:
%       strout:    the modified html file output with table added:
%
% HTML TABLE LOOKS LIKE:
%			<tr>
%				<td>[ENGINEERINGTABLE]</td>
%				<td>&nbsp;</td>
%			</tr>
%			<tr>
%				<td>&nbsp;</td>
%				<td>&nbsp;</td>
%			</tr>
%=======================================================================
function strout = HTMLreplaceEngineeringTable(strin, float)
%begin
    %CHECK FOR INPUT ERRORS:
    strout = strin;
    if (isempty(float)) return; end;

    %LOOK FOR THE KEYWORD [ENGINEERINGTABLE] FIRST ROW AND COL:
    [nrows,ncols] = size(strin);
    Index         = strvcmp(strin, '[ENGINEERINGTABLE]');
    if (isempty(Index)) return; end;
 
    %GET THE TECH PARAMETER NAMES+VALUES+DATE+LAT-LON FROM DBASE STRUCTURE:
    TechParam = dbasequeryGetEngineeringParam(float);
    try nc = length(TechParam);         catch; return; end;  %number of cols
    try nr = length(TechParam(1).pval); catch; return; end;  %number of rows
    
    %TABLE HEADER:
    Table = '        <tr>';
    for j=1:nc
        if (TechParam(j).showIt==false) continue; end;
        s1 = strrep(TechParam(j).pname, '_', ' '); 
        s1 = ['               <td align="center">', s1, '</td>'];
        Table = strvcat(Table, s1);
    end
    Table = strvcat(Table, '        </tr>');
    
    %PARAMETER VALUES: ADD THE DATA ROWS TO THE TABLE:
    warning off;
    for r=1:nr
        Table = strvcat(Table, '        <tr>');
        
        for c=1:nc
            if (TechParam(c).showIt==false) continue;    end;
            try x  = TechParam(c).pval(r);  catch; x=[]; end;
            format = TechParam(c).format;
            s1     = 'NaN';
            if (iscell(x)) x = cell2mat(x); end;
            try s1 = sprintf(format, x); catch s1='-'; end;
            s1     = ['               <td align="center">', s1, '</td>'];
            Table  = strvcat(Table, s1);    
        end
        Table = strvcat(Table, '        </tr>');
    end
    warning on;
    
    %COMBINE THE TABLE INTO THE ORIGINAL HTML FILE:
    s1     = strin(1:Index-2,    :);  %everything before the table
    s2     = strin(Index+7:nrows,:);  %everything after the table
    strout = strvcat(s1, Table, s2);  %add table to before and after
    pause(0.1); 
%end





%====================================================================
%RETURNS A SENSOR STRING INFORMATION FOR PRINTING/DISPLAY:
%Input: Sensor: 
%    ex:    Exists: 1
%             Name: 'Temperature'
%            Units: ''
%           Symbol: 'T1'
%     Manufacturer: 'Seabird'
%         SerialNo: ''
%          ModelNo: ''
%         Equation: 'Linear()'
%           Format: '%6.3f'
%        MultCoeff: 1
%         AddCoeff: 0
%    SentinelUpper: []
%    SentinelLower: []
%       ValidUpper: []
%       ValidLower: []
%      Calibration: []
%            Index: '3-4'
%
%====================================================================
function str = GetSensorInformation(Sensor)
%begin
    %check input:
    str = '';
    if (isempty(Sensor)) return; end;
   
    
    %format a single string:
    try 
        if (Sensor.Exists==0) return; end;
        str = [Sensor.Name, '   Units: ',   Sensor.Units, '  Symbol: (', Sensor.Symbol, ')'];
        str = [str, '  Maker:  [ ',     Sensor.mfg, ' ]'];
        str = [str, '  S/N:    [ ',     Sensor.SerialNo,     ' ]'];
        str = [str, '  Model:  [ ',     Sensor.ModelNo,      ' ]'];
    catch
    end;

%end






%############################################## CREATES PLOTS FOR EACH ENG TECH PARAMETER #######################################



%===============================================================================
% CONSTRUCTS ALL PLOTS FOR A PARTICULAR FLOAT AND SAVES THEM IN THE SPECIFIED
% WEB DIRECTORY.
% Returns a list of figure names, this list is hyperlinked into the web-page
%===============================================================================
function figNames = CreateFigures(dbase, destfolder, fpp)
%begin
    %CHECK INPUT DATA:
    figNames = cell(0,0);
    figCount = 0;
%     [fpp]=getargo(dbase.wmo_id);
    %GET THE HULL ID:
    try HullID = dbase.maker_id; catch; return; end;
    
    %GET THE TECH PARAMETER NAMES+VALUES+DATE+LAT-LON FROM DBASE STRUCTURE:
    TechParam = dbasequeryGetEngineeringParam(fpp);           %returns the tech parameters of interest
    try Nfigs = length(TechParam);         catch; return; end;  %max number of figures
    try n     = length(TechParam(1).pval); catch; return; end;  %number of profiles

    %NO DATA - EXIT:
    if (isempty(TechParam))    return; end;
    if ((Nfigs==0) || (n==0))  return; end;
    
    %CREATE EACH FIGURE AND ASSIGN NAME
    for j=1:Nfigs
        if (TechParam(j).plotIt==false); continue; end;
        figCount           = figCount+1;
        str                = PlotTechParam(TechParam(j), destfolder, HullID);
        if isempty(str)
            figCount=figCount-1;
        else
            figNames(figCount) = {str};
        end
        %  fprintf('                  [5.9.%02d] Figure Created..............: %s \n',figCount, str);        
    end;
    
    pause(0.1);
%end






%====================================================================================
%  CREATES A GRAPH AS AN IMAGE WHICH CAN BE VIEWED IN A PAGE OF A WEB-BROWSER 
%                                                                             
%  INPUTS:                                                                    
%                                                                             
%      - Filename:  name of the graph file:                                   
%                          ex: '..\DataFiles_WebPages\2321\Fig_Vnoload.png'   
%     - InfoStruct: this is a structure with the contents shown below, ex:
% 
%           wmoID: 53546
%          hullID: 57
%         argosID: 21073
%      paramNames: [4x15 char]    {'Voltage', 'Current', 'Piston_Position', 'Offset' }
%     paramValues: [86x4 double]  {array of 86x4 4=values, 86 profiles }
%                                                                             
%  Plots the Y data with three additional bands: (1) upper 0.2SD band, lower  
%  -0.2SD band and a mean band:                                               
%   
%  Returns:
%      - the full filename of the figure (no path) for linking to the main 
%        technical web page.
%====================================================================================
function figName = PlotTechParam(TechParam, destfolder, HullID)
%begin    
    %PLOT DATA:
    try
        %plotting parameters:
        Title         = TechParam.pname;
        Ydata         = TechParam.pval;
        figName       = [Title, '.png']; 
        [Xl,Xu,Yl,Yu] = BestPlotRange(TechParam);
        if isnan(Yl);figName = ''; return; end
    catch
        figName = '';
        return;
    end
    
    %plot the voltage etc:
    figure(2);
    clf;
    set(gcf, 'Units', 'pixels', 'Position', [300 300 400 350], 'Color', [0.9 0.9 1]);
    plot(Ydata, 'm.-', 'linewidth', 1);
    hold on;
    
    %change the physical size of the plot and fonts: 
    set(gcf, 'PaperPositionMode', 'auto'   );
    set(gca, 'Fontname',          'Arial'  );
    set(gca, 'fontsize',          11       );
    set(gca, 'linewidth',         2        );
    set(gcf, 'Renderer',         'painters');
     axis([Xl, Xu, Yl, Yu]);

    %title + also includes the last update time/date:
    grid on; 
    str    = strrep(Title, '_', ' ');
    Title1 = sprintf('%d:  %s', HullID, str);
    Title2 = sprintf('Updated: %s', datestr(now));
    title({Title1; Title2}, 'Fontsize', 13, 'Fontname', 'Arial Narrow', 'Fontweight', 'bold');
    
    %x axis and y axis labels
    xlabel('Profile', 'Fontsize', 12, 'Fontname', 'Arial',        'Fontweight', 'bold');
    ylabel(Title,     'Fontsize', 12, 'Fontname', 'Arial Narrow', 'Fontweight', 'bold');
       
    %create filename, remove the Fig_ prefix to shorten name and overall html index file size
    filename = [destfolder, '/', Title, '.png']; 
    if(ispc)
        print('-dtiff',filename);
    else
        try
            my_save_fig([filename],'clobber')
        end
    end
% Fig      = getframe(gcf);
%     imwrite(Fig.cdata, filename, 'png');
    pause(0.2);
%end




%====================================================================================
% DETERMINE THE BEST PLOT RANGE USING DEFAULTS AS STARTING POINT
%====================================================================================
function [Xl,Xu,Yl,Yu] = BestPlotRange(TechParam)
%begin
    %starting point:
    Ydata = TechParam.pval;
%     Yl    = min(min(Ydata-min(Ydata)/10),TechParam.Ylower);
Yl=floor(min(Ydata)-10);
%     Yu    = max(max(Ydata+max(Ydata)/10),TechParam.Yupper);
Yu=floor(max(Ydata)+10);
    Xl    = 1;
    Xu    = length(Ydata);

    %adjust the x-range: increments of 10:
    Xu = fix(length(Ydata)/10)*10+10;
    
    %adjust the y-range: binary scale
    
%end    
    
    



%==========================================================================================
% INSERTS THE ENGINEERING PLOTS INTO THE HTML FILE: FIGURES ARE PLACED INSIDE AN HTML TABLE
%
% Inputs:
%       strin:     the input html file to modify
%       figNames:  list of figure names to link into html code, names are cell objects
%                  Ex:    VOLTAGE_BatteryInitialAtProfileDepth_VOLTS.png           
%                         CURRENT_BatterySBEPump_mAMPS.png 
% Outputs:
%       strout:    the modified html file output with table added:
%
% HTML TABLE LOOKS LIKE:
%		   <tr>
%				<td align="center"> <img border="0" src="Figure1.bmp"></td>
%				<td align="center"> <img border="0" src="Figure2.bmp"></td>
%				<td align="center"> <img border="0" src="Figure3.bmp"></td>
%		   </tr>
%==========================================================================================
function strout = HTMLreplaceTechPlots(strin, figs)
%begin
    %CHECK FOR INPUT ERRORS:
    strout = strin;
    if (isempty(strin)) return; end;
    
    %LOOK FOR THE KEYWORD [ENGINEERINGPLOTS] FIRST ROW AND COL:
    nfigs = length(figs);
    Plots = '';
    Index = strvcmp(strin, '[ENGINEERINGPLOTS]');
    if (isempty(Index)) return; end;
    if (nfigs==0)       return; end;
    
    %CONSTRUCT ENGINEERING PLOTS 3 COLUMNS WIDE, ROWS DEPENDS ON THE NUMBER OF PLOTS:
    for j=1:3:nfigs
        %begin new table row
        Plots = strvcat(Plots,  '        <tr>');  
        
        %first column figure:
        s1 = '				<td>&nbsp;</td>';
        if (j+0<=nfigs) s1=['				<td align="center"> <img border="0" src="', cell2mat(figs(j+0)), '"></td>']; end;
        Plots = strvcat(Plots,s1);
        
        %second column figure:
        s1 = '				<td>&nbsp;</td>';
        if (j+1<=nfigs) s1=['				<td align="center"> <img border="0" src="', cell2mat(figs(j+1)), '"></td>']; end;
        Plots = strvcat(Plots,s1);
        
        %third column figure:
        s1 = '				<td>&nbsp;</td>';
        if (j+2<=nfigs) s1=['				<td align="center"> <img border="0" src="', cell2mat(figs(j+2)), '"></td>']; end;
        Plots = strvcat(Plots,s1);
    
        %end table row
        Plots = strvcat(Plots,  '        <tr>'); 
    end
    
    %COMBINE THE TABLE INTO THE ORIGINAL HTML FILE:
    [nrows,ncols] = size(strin);
    s1            = strin(1:Index-3,    :);  %everything before the table
    s2            = strin(Index+7:nrows,:);  %everything after the table
    strout        = strvcat(s1, Plots, s2);  %add table to before and after
%end




%======================================= TECHNICAL PROBLEMS AND ISSUES TABLE ============================================

%======================================================================================================================
%  REPLACES THE ISSUES TABLE (SECOND TABLE) OF THE HTML FILE / 3 ROW ENTRIES
% The Figures/plots are linked to the table
%
% Inputs:
%       strin:       the input html file to modify
%       allFloats:   our database stuff
%       HullID:      the hull id to match to database
%
% Outputs:
%       strout:    the modified html file output with table added:
%
% HTML TABLE LOOKS LIKE:
%	<textarea rows="27" name="S1" cols="61" style="font-family: Arial monospaced for SAP; font-size: 12pt; font-weight: bold">
%     [BATHYMETRYTEXT1]
%     [BATHYMETRYTEXT2]
%   </textarea></p>
%


%======================================================================================================================
%RETURNS A STRUCTURE HAVING COMPONENTS USED BY THE INDEX PAGE ROW ENTRY:
%======================================================================================================================
function IndexPageInfo = ConstructIndexPageInfo(dbase, fpp, sensor)
%begin
    %check input:
    IndexPageInfo = [];
    if (isempty(dbase))  return; end;
    if (isempty(fpp)) ; return;end
    if (isempty(sensor)) return; end;
        try n = length(fpp);                        catch; n = 1;     end;
     
    %GET FLOAT TECHNICAL PARAM:
    for i=length(fpp)
        
        try 
            Voltage=fpp(i).parkbatteryvoltage;  
        catch; 
            try; 
                Voltage=fpp(i).SBEpumpvoltage;
            catch;
                Voltage = 0;     
            end;
        end;
        try Cycles=fpp(i).profile_number;       catch; Cycles = 0;     end;
        try TxDate=fpp(i).datetime_vec;         catch; TxDate = ' '; end;
        try ParkP=fpp(i).park_p;                catch; ParkP  = 0;     end;
        try SurfP=fpp(i).surfpres;              catch; SurfP  = 0;     end;
        
    end

    %DATES IN NUMERIC FORM:
    try Tdeploy   = datenum(dbase.launchdate(1:8), 'yyyymmdd');   catch; Tdeploy   = 0;  end;
    try Tlast     = datenum(fpp(end).datetime_vec(1,:));   catch; Tlast     = 0;  end;
%     try EndStatus = dbasequery_History(Config.History, 'CODE#14: DEAD', 'Field2');   catch; 
        EndStatus = '';
    
    %CONSTRUCT AN OUTPUT STRUCTURE USED BY INDEX TABLE:
    try s.HullID            = dbase.maker_id;         catch;  s.HullID  = 0;   end;
    try s.ArgosID           = dbase.argos_id;         catch;  s.ArgosID  = 0;   end;
    try s.WmoID             = dbase.wmo_id;           catch;  s.WmoID  = 0;   end;
    try s.Status            = dbase.status;           catch;  s.Status   = '';  end;
    try s.EndMissionStatus  = EndStatus;              catch;  s.EndMissionStatus  = '';  end;
    try s.ParkVoltage       = Voltage(n);             catch;  s.ParkVoltage       = [];  end;
    try s.Cycles            = Cycles(n);              catch;  s.Cycles            = [];  end;
    try s.LastTransmission  = cell2mat(TxDate(n));    catch;  s.LastTransmission  = '';  end;
    try s.LastTxDaysAgo     = now - Tlast;            catch;  s.LastTxDaysAgo     = [];  end;
    try s.MaxParkPressure   = max(ParkP);             catch;  s.MaxParkPressure   = [];  end;
    try s.MinParkPressure   = min(ParkP);             catch;  s.MinParkPressure   = [];  end;
    try s.LaunchDate        = LongDateToDateTime(dbase.launchdate); catch;  s.LaunchDate  = '';  end;
    try s.DeployPlatform    = dbase.launch_platform;  catch;  s.DeployPlatform = '';  end;
    try s.PositioningSystem = sensor.UplinkSystem;    catch;  s.PositioningSystem = '';  end;
    try s.DaysInOperation   = round(Tlast - Tdeploy); catch;  s.DaysInOperation   = [];  end;
    try s.SurfacePressure   = max(SurfP);             catch;  s.SurfacePressure   = [];  end;
    try s.cpuID             = dbase.controlboardnumstring;  catch;  s.cpuID             = '';  end;
    try s.OxygenSensorSN    = dbase.oxysens_snum;     catch;  s.OxygenSensorSN    = [];  end;    
    try s.IceDetection      = dbase.ice;              catch;  s.IceDetection      = [];  end;
    
    %no data on last uplink date:
    if (Tlast==0) s.LastTransmission  = '';  end;
    if (Tlast==0) s.LastTxDaysAgo     = [];  end;
    if (Tlast==0) s.DaysInOperation   = [];  end;
    
    %save in return argument:
    IndexPageInfo = s;
%end

    



    





