% remake argos trajectory files.
% But remake the work files for selected floats/profiles that are failing
% the file checker from the GDAC.
clear all

%list the XML files
fcd = '/home/argo/ArgoRT/trajchecker/out/';
fid = fopen('trajArgosForRerun.txt','r');
flts = textscan(fid,'%s','delimiter','\n');
fclose(fid);
%% filename collection cell
% clear
% fid = fopen('trajArgosForRerun.txt','a');
% fcd = '/home/argo/ArgoRT/trajchecker/out/';
% fnms = dir([fcd '*.filecheck']);
% jj = 0;
% for a = 1:length(fnms)
%     % read in the XML file
%     s = parseXML([fcd fnms(a).name]);
%     
%     % identify which trajectory files need re-making
%     for b = 1:length(s.Children)
%         ii = strfind('errors',s.Children(b).Name);
%         if ~isempty(ii)
%             break
%         end
%     end
%     no_errs = str2num(s.Children(b).Attributes.Value);
%     if no_errs == 0
%         continue
%     end
%     fprintf(fid,'%s\n',fnms(a).name(1:7));
%     jj = jj+1;
% end
% fclose(fid);
%%
notfixed = [];
% jj = 0;
for a =18%11:length(flts{:})
    fnms = dir([fcd flts{:}{a} '*.filecheck']);
    % read in the XML file
    s = parseXML([fcd fnms.name]);
    
    % identify which trajectory files need re-making
    for b = 1:length(s.Children)
        ii = strfind('errors',s.Children(b).Name);
        if ~isempty(ii)
            break
        end
    end
        
    no_errs = str2num(s.Children(b).Attributes.Value);
    if no_errs == 0
        %nothing to fix
        continue
    end
    
    mc703 = 0;presfill = 0;
    %let's display
    sprintf('%s\n',fnms.name(1:7))
    for c = 1:length(s.Children(b).Children)
        if ~isempty(s.Children(b).Children(c).Children)
            disp(s.Children(b).Children(c).Children.Data)
            if ~isempty(strmatch('JULD (MC 703)',s.Children(b).Children(c).Children.Data))
                mc703 = 1;
            end
            if ~isempty(strmatch('R-mode: PRES_ADJUSTED:',s.Children(b).Children(c).Children.Data))
                presfill = 1;
            end
            
        end
    end

    %let's auto-fix the 703 mismatches.
    if mc703
        fn = ['/home/argo/ArgoRT/netcdf/' flts{:}{a} '/' flts{:}{a} '_Rtraj.nc'];
        wmo = flts{:}{a};
        try
            jfl = ncread(fn,'JULD_FIRST_LOCATION');
        catch
            fn = ['/home/argo/ArgoRT/netcdf/' flts{:}{a}(1:5) '/' flts{:}{a}(1:5) '_Rtraj.nc'];
            wmo = flts{:}{a}(1:5);
            jfl = ncread(fn,'JULD_FIRST_LOCATION');
        end
        cyc_ind = ncread(fn,'CYCLE_NUMBER_INDEX');
        mc = ncread(fn,'MEASUREMENT_CODE');
        cyc = ncread(fn,'CYCLE_NUMBER');
        jd = ncread(fn,'JULD');
        
        %this does not look at cycle 0
        remake = 0;
        for d = 1:max(cyc_ind)
            %first check that first and last location dates match the max/min of ST
            %(code 703)
            ij = find(cyc_ind == d);
            ii = find(cyc == d & mc == 703);
            flt = min(jd(ii));
            if any(~isnan(flt) | ~isnan(jfl(ij)))
                if flt ~= jfl(ij)
                    remake_workfile(str2num(wmo),d)
                    remake = 1;
                end
            end
        end
        
        if remake
            load_float_to_traj(str2num(wmo),1)
        end
        
        %reload and check:
        jfl = ncread(fn,'JULD_FIRST_LOCATION');
        cyc_ind = ncread(fn,'CYCLE_NUMBER_INDEX');
        mc = ncread(fn,'MEASUREMENT_CODE');
        cyc = ncread(fn,'CYCLE_NUMBER');
        jd = ncread(fn,'JULD');
        
        for d = 1:max(cyc_ind)
            %first check that first and last location dates match the max/min of ST
            %(code 703)
            ij = find(cyc_ind == d);
            ii = find(cyc == d & mc == 703);
            flt = min(jd(ii));
            if any(~isnan(flt) | ~isnan(jfl(ij)))
                if flt ~= jfl(ij)
                    disp('STILL NOT FIXED')
                    notfixed = [notfixed;str2num(wmo)];
                end
            end
        end
    elseif presfill
        fn = ['/home/argo/ArgoRT/netcdf/' flts{:}{a} '/' flts{:}{a} '_Rtraj.nc'];
        wmo = flts{:}{a};
        try
            %fix not fill values here
            load_float_to_traj(str2num(wmo),0)
        catch
            fn = ['/home/argo/ArgoRT/netcdf/' flts{:}{a}(1:5) '/' flts{:}{a}(1:5) '_Rtraj.nc'];
            wmo = flts{:}{a}(1:5);
            load_float_to_traj(str2num(wmo),0)
        end
        %reload and check:
        pra = ncread(fn,'PRES_ADJUSTED');
        if any(~isnan(pra))
            disp('STILL NOT FIXED')
            notfixed = [notfixed;str2num(wmo)];
        end
    else
        wmo = flts{:}{a};
        load_float_to_traj(str2num(wmo),1)

    end

end
disp(unique(notfixed))
return
%% copy to netcdf folder for transfer to Lisa.
clear all

fcd = '/home/argo/ArgoRT/trajchecker/out/';
% fnms = dir([fcd '*.filecheck']);
fid = fopen('trajArgosForRerun1.txt','r');
flts = textscan(fid,'%s','delimiter','\n');
fclose(fid);

for a = 1:length(flts{:})
    disp(a)
    fn = [flts{:}{a}  '_Rtraj.nc'];
    [status,~]=system(['cp -p /home/argo/ArgoRT/netcdf/' flts{:}{a} '/' fn ' /home/argo/ArgoRT/trajchecker/netcdf/' fn]);
    if status ~=0
        disp('failed')
        fn = [flts{:}{a}(1:5) '_Rtraj.nc'];
        [status,~]=system(['cp -p /home/argo/ArgoRT/netcdf/' flts{:}{a}(1:5) '/' fn ' /home/argo/ArgoRT/trajchecker/netcdf/' fn])
    end        
end

%and get the mat files too
for a = 1:length(flts{:})
    disp(a)
    fn = ['T' flts{:}{a}  '.mat'];
    [status,~]=system(['cp -p /home/argo/ArgoRT/trajfiles/' fn ' /home/argo/ArgoRT/trajchecker/netcdf/' fn]);
    if status ~=0
        disp('failed')
        fn = ['T' flts{:}{a}(1:5) '.mat'];
        [status,~]=system(['cp -p /home/argo/ArgoRT/trajfiles/' fn ' /home/argo/ArgoRT/trajchecker/netcdf/' fn])
    end        
end

