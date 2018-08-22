% check that the file has matching times in the N_MEASUREMENT series and
% the N_CYCLE series. The juld_adjusted time for each measurement code
% should be the same as the corresponding JULD_* fields.
%
% Bec Cowley, June, 2016.
% clear
fns = dir('/home/argo/ArgoRT/netcdf/');
%%
for bb =1:length(fns)
    if strfind(fns(bb).name,'.')
        continue
    end
    if isempty(strfind(fns(bb).name,'5905032'))
        continue
    end
    fln = fns(bb).name;
    fn = ['/home/argo/ArgoRT/netcdf/' fln '/' fln '_Rtraj.nc'];
    load(['/home/argo/ArgoRT/trajfiles/T' fln ])
    load(['/home/argo/ArgoRT/matfiles/float' fln '.mat'])
    j1950 = julian([1950 1 1 0 0 0]);
    
    %these are the N_MEASUREMENT items
    mc = ncread(fn,'MEASUREMENT_CODE');
    cyc = ncread(fn,'CYCLE_NUMBER');
    press = ncread(fn,'PRES');
    pressqc = ncread(fn,'PRES_QC');
    jd = ncread(fn,'JULD');
    jd_adj = ncread(fn,'JULD_ADJUSTED');
    stat = ncread(fn,'JULD_STATUS');
    jd_qc = ncread(fn,'JULD_QC');
    jda_stat = ncread(fn,'JULD_ADJUSTED_STATUS');
    jda_qc = ncread(fn,'JULD_ADJUSTED_QC');
    pqc = ncread(fn,'POSITION_QC');
    if isempty(jd)
        disp(['EMPTY NC FILE! ' fln])
        continue
    end
    
    %% quick test here, all juld times should be chronological
    ig = ~isnan(jd);
    dd = diff(jd(ig));
    c = cyc(ig);
    c = c(2:end);
    if any(dd < 0)
        disp('JULD times out of order')
        disp(c(dd<0))
    end
    igad = ~isnan(jd_adj);
    ddad = diff(jd_adj(igad));
    ca = cyc(igad);
    ca = ca(2:end);
    if any(ddad < 0)
        disp('JULD_ADJ times out of order')
        disp('Cycle    MC')
        mm = mc(igad);
        mma = mm(2:end);
        disp([ca(ddad<0) mma(ddad<0)])
    end
    % Now plot diff of times:
    figure(2);clf
    plot(c,dd,'b')
    hold on
    plot(ca,ddad,'r')
    title(['Difference in times for float ' fln])
    xlabel('Cycle')
    
    %% check the mandatory codes are filled.
    %HERE, CHECK THAT ALL CODES EXIST
    mmc = [0,100,150,190,200,250,290,300,301,400,450,500,501,550,600,700,701,702,703,704,800,903];
    umc = unique(mc);
    ia = ismember(umc,mmc);
    if any(ia == 0)
        disp('Missing MC for:')
        disp(num2str(umc(~ia)))
    end
    for a = 1:length(umc);
        if rem(umc(a)/100,1) ~= 0 | umc(a) == 0
            continue
        end
        ii = find(mc == umc(a));
        inan = find(isnan(jd(ii)) & isnan(jd_adj(ii)));% & str2num(stat(ii)) ~=9);
        if any(inan)
            disp(['Code: ' num2str(umc(a)) ])
            disp('Cycle')
            disp(num2str(unique(cyc(ii(inan)))))
        end
    end
    %% Check for equality in the date values between N_CYCLE and N_MEASUREMENT
    % params.
    
    % these are the N_CYCLE JULD items:
    cyc_ind = ncread(fn,'CYCLE_NUMBER_INDEX');
    tvnm = {'JULD_DESCENT_START','JULD_FIRST_STABILIZATION',...
        'JULD_DESCENT_END','JULD_PARK_START',...
        'JULD_PARK_END','JULD_DEEP_DESCENT_END','JULD_DEEP_PARK_START',...
        'JULD_DEEP_ASCENT_START','JULD_ASCENT_START','JULD_ASCENT_END',...
        'JULD_TRANSMISSION_START','JULD_FIRST_MESSAGE',...
        'JULD_LAST_MESSAGE',...
        'JULD_TRANSMISSION_END'};
    
    
    mcN = [100 150 200 250 300 400 450 550 500 600 700 702 704 800];
    
    
    jfl = ncread(fn,'JULD_FIRST_LOCATION');
    jll = ncread(fn,'JULD_LAST_LOCATION');
    
    %this does not look at cycle 0
    for a = 1:max(cyc_ind)
        %first check that first and last location dates match the max/min of ST
        %(code 703)
        ij = find(cyc_ind == a);
        ii = find(cyc == a & mc == 703);
        flt = min(jd(ii));
        llt = max(jd(ii));
         if any(~isnan(flt) | ~isnan(jfl(ij)))
            if flt ~= jfl(ij) 
                disp(['first mesage times dont match JULD_First_loc, Profile: ' num2str(a) ' mc = 703'])
            end
         end
        if any(~isnan(llt) | ~isnan(jll(ij)))
            if llt ~= jll(ij)
                disp(['last mesage times dont match JULD_last_loc, Profile: ' num2str(a) ' mc = 703'])
            end
        end
        for b = 1:length(mcN)
            ii = find(cyc == a & mc == mcN(b));
            
            jds = ncread(fn,tvnm{b});
            
            %check both juld and juld_adj values (TST is not adjusted)
            if ~isnan(jds(ij).*jd_adj(ii))
                if jds(ij) ~= jd_adj(ii) & jds(ij) ~= jd(ii)
                    disp(['Juld start/end dont match juld, Profile: ' num2str(a) ' mc = ' num2str(mcN(b))])
                    keyboard
                end
            end
        end
        
    end
    %% check that AST and DDET are the same
    jddde = ncread(fn,'JULD_DEEP_DESCENT_END');
    jdast = ncread(fn,'JULD_ASCENT_START');
    if ~isnan(nansum(jddde - jdast))
        if nansum(jddde - jdast) ~= 0
        disp('JULD_DEEP_DESCENT_END and JULD_ASCENT_START DIFFERENT!!')
        keyboard
        end
    end
    % check statuses are correct for failed file checker:
    stat_jdde = ncread(fn,'JULD_DEEP_DESCENT_END_STATUS');
    stat_jast = ncread(fn,'JULD_ASCENT_START_STATUS');
    stat_jaet = ncread(fn,'JULD_ASCENT_END_STATUS');
    ii = find(mc == 400);
    [cyc(ii) str2num(stat(ii))];
 
    %% location times
    jdll = ncread(fn,'JULD_LAST_LOCATION');
    jdfl = ncread(fn,'JULD_FIRST_LOCATION');

    %% pressure
    pr = ncread(fn,'PRES');
    prqc = ncread(fn,'PRES_QC');
    ibad = [];ibad2 = [];
    for a = 1:length(pr)
        if ~isnan(pr(a)) & prqc(a) == ' '
            ibad = [ibad;a];
        elseif isnan(pr(a)) & prqc(a) ~= ' '
            ibad2 = [ibad2;a];
        end
    end
    disp('PRESSURE')
    mc(ibad)
    mc(ibad2)
    %% pressure adj
    pra = ncread(fn,'PRES_ADJUSTED');
    praqc = ncread(fn,'PRES_ADJUSTED_QC');
    ibad = [];ibad2 = [];
    for a = 1:length(pra)
        if ~isnan(pra(a)) & praqc(a) == ' '
            ibad = [ibad;a];
        elseif isnan(pra(a)) & praqc(a) ~= ' '
            ibad2 = [ibad2;a];
        end
    end
    disp('PRESSURE_ADJUSTED')
    mc(ibad)
    mc(ibad2)
    
    %% look for missing JULD_QC and JULD_STATUS flags
    ibad = [];ibad2 = [];ibad3=[];ibad4=[];
    for a = 1:length(jd)
        if ~isnan(jd(a)) & jd_qc(a) == ' '
            ibad = [ibad;a];
        elseif isnan(jd(a)) & (isempty(str2num(jd_qc(a))) | str2num(jd_qc(a)) ~= 9)
            ibad2 = [ibad2;a];
        elseif ~isnan(jd(a)) & stat(a) == ' '
            ibad3 = [ibad3;a];
        elseif isnan(jd(a)) & (isempty(str2num(stat(a))) | str2num(stat(a)) ~= 9)
            ibad4 = [ibad4;a];
        end
    end
    disp('JULD')
    unique(mc(ibad))
    unique(mc(ibad2))
    unique(mc(ibad3))
    unique(mc(ibad4))
    %% look for missing JULD_adj_QC and JULD_adj_STATUS flags
    ibad = [];ibad2 = [];ibad3=[];ibad4=[];
    for a = 1:length(jd_adj)
        if ~isnan(jd_adj(a)) & jda_qc(a) == ' '
            ibad = [ibad;a];
        elseif isnan(jd_adj(a)) & (isempty(str2num(jda_qc(a))) | str2num(jda_qc(a)) ~= 9)
            ibad2 = [ibad2;a];
        elseif ~isnan(jd_adj(a)) & jda_stat(a) == ' '
            ibad3 = [ibad3;a];
        elseif isnan(jd_adj(a)) & (isempty(str2num(jda_stat(a))) | str2num(jda_stat(a)) ~= 9)
            ibad4 = [ibad4;a];
        end
    end
    disp('JULD_ADJUSTED')
    unique(mc(ibad))
    unique(mc(ibad2))
    unique(mc(ibad3))
    unique(mc(ibad4))

    %% Check that CONFIG_MISSION_NUMBER starts at 1
    cmn = ncread(fn,'CONFIG_MISSION_NUMBER');
    if min(cmn) ~=1
        figure(4);clf
        plot(cyc_ind, cmn,'x')
        title([fln ' CONFIG MISSION NUMBER'])
    end
    %% Plot something to visually check it all makes sense:
    
    %start with lat/lon:
    lat = ncread(fn,'LATITUDE');
    lon = ncread(fn,'LONGITUDE');
    %change lon to 360 degrees.
    if any(lon < 0)
        ii = lon<0;
        lon(ii) = 180+lon(ii)+180;
    end
    
    ig = ~isnan(lat.*lon);
    figure(1);clf
    plot(lon(ig),lat(ig),'-')
    text(lon(ig),lat(ig),num2str(cyc(ig)))
    hold on
    coast
    
    %the measurement codes for each cycle, where we have values
    ifil = ~isnan(jd) | ~isnan(jd_adj);
    figure(3);clf
    plot(mc,cyc,'ko');hold on
    plot(mc(ifil),cyc(ifil),'r.')
    grid
    title(fln)
    xlabel('MC')
    ylabel('Cycle')
    legend('Fill value','Juld/adj value')
    
    % the times between the surface locations:
    figure(5);clf
    tst = ncread(fn,'JULD_TRANSMISSION_START');
    plot(cyc_ind(2:end),diff(tst),'x')
    title([fln ' Surface time differences'])
    xlabel('Cycle')
    ylabel('Days')
    
    %missing cycles:
    figure(2)
    hold on
    uc=unique(cyc);
    C = 1:length(traj);
    [ia,ib]= ismember(C,uc);
    plot(C(~ia),zeros(length(C(~ia)),1),'ko')
    
    if any(ddad<0)
        pause
    else
        pause(0.2)
    end
    
    %park pressures
    figure(6);clf
    hold on
    ipr = mc == 290;
    plot(cyc(ipr),press(ipr),'-x')
    title('Park pressures')
    
end