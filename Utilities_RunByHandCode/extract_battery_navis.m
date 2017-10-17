clear all
set_argo_sys_params
global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
getdbase(0);
fndone = [5904219
5904220
5904222
5904223
3901465
3901466
5904225
5904227
];

for a = 788:length(THE_ARGO_FLOAT_DB)
    if THE_ARGO_FLOAT_DB(a).maker ~= 4
        continue
    end
    
    if any(fndone == THE_ARGO_FLOAT_DB(a).wmo_id)
        continue
    end
    fnm = THE_ARGO_FLOAT_DB(a).wmo_id;
    clear dat batt
    dirs  = ['/home/argo/ArgoRT/iridium_data/iridium_processed/' num2str(fnm) '/'];
    load(['./matfiles/float' num2str(fnm) '.mat'])
    %pre-make the structure
    sz = NaN*ones(size(float));
    dat = struct('wmoid',sz,'cycle',sz,'time',sz,'startprofilevolt',sz,...
        'startprofilecurrent',sz,'secondpumpvolt',sz,'secondpumpcurrent',sz,...
        'parkbatterycurrent',sz,'parkbatteryvolt',sz);
    %go through each cycle
    for b = 1:length(float)
        if isempty(float(b).profile_number)
            continue
        end
        dat.wmoid(b) = float(1).wmo_id;
        dat.cycle(b) = float(b).profile_number;
        %read the log file & msg file:
        fid = fopen([dirs sprintf('%04d',float(b).SN) '.' ...
            sprintf('%03d',float(b).profile_number) '.log'],'r');
        if fid > 0
            log = textscan(fid,'%s','Delimiter','|');
            fclose(fid);
            %get all the volts indications:
            ii = find(cellfun(@isempty,strfind(log{1},'Sbe41cpStartCP'))==0);
            if ~isempty(ii)
                
                ij = find(cellfun(@isempty,strfind(log{1},'BuoyancyAdjustAbsWTO'))==0);
                step = ij-ii;
                jj = min(find(step > 0));
                
                if ~isempty(jj)
                    %now extract and group them by the name. Record the date/time
                    str = log{1}{ii+step(jj)};
                    %             date/time
                    dt = textscan(str,'(%s','delimiter',',');
                    dat.time(b) = datenum(dt{1});
                    
                    %now get the first voltage & current at bottom of profile:
                    v = regexp(str,'....Volts','match');
                    %some files have the string interrupted and on the next
                    %line
                    if isempty(v)
                        %look at next 2 lines
                        for nl = 1:2
                            str = log{1}{ii+step(jj)+nl};
                            vv = regexp(str,'....Volts','match');
                            if ~isempty(vv)
                                v = vv;
                            end
                        end
                        if isempty(v)
                            keyboard
                        end
                    end
                    v = str2num(v{:}(1:end-5));
                    dat.startprofilevolt(b) = v;
                    
                    cur = regexp(str,'.....Amps','match');
                    cur = str2num(cur{:}(1:end-4));
                    dat.startprofilecurrent(b) = cur;
                    
                    %now get the second pump voltage and current:
                    if length(step) > jj
                        str = log{1}{ii+step(jj+1)};
                        v = regexp(str,'....V','match');
                        v = str2num(v{:}(1:end-1));
                        dat.secondpumpvolt(b) = v;
                        
                        cur = regexp(str,'.....Amps','match');
                        cur = str2num(cur{:}(1:end-4));
                        dat.secondpumpcurrent(b) = cur;
                    end
                end
            end
        end
        %back out the calculation
        cur = (float(b).parkbatterycurrent + 3.606)/4.052;
        if ~isempty(cur)
            %recalculate (mA)
            dat.parkbatterycurrent(b) = cur*1.1546 - 0.1454;
        end
        
        %back out the calculation
        v = (float(b).parkbatteryvoltage-0.486)/0.077;
        if ~isempty(v)
            %             calculate with correct coefficients (V)
            dat.parkbatteryvolt(b) = v*0.004825 + 0.00197;
        end
        %fix the other current and voltage values in the float mat file:
        %back out the calculation
        %reassign value to float mat file:
        float(b).parkbatterycurrent = dat.parkbatterycurrent(b)/1000;
        %reassign value to float mat file:
        float(b).parkbatteryvoltage = dat.parkbatteryvolt(b);
        
        v = (float(b).SBEpumpvoltage-0.486)/0.077;
        if ~isempty(v)
            float(b).SBEpumpvoltage = v*0.004825 + 0.00197;
        end
        v = (float(b).airpumpvoltage-0.486)/0.077;
        if ~isempty(v)
            float(b).airpumpvoltage = v*0.004825 + 0.00197;
        end
        v = (float(b).buoyancypumpvoltage-0.486)/0.077;
        if ~isempty(v)
            float(b).buoyancypumpvoltage = v*0.004825 + 0.00197;
        end
        
        %back out the calculation
        cur = (float(b).SBEpumpcurrent + 3.606)/4.052;
        if ~isempty(cur)
            %recalculate (A)
            float(b).SBEpumpcurrent = (cur*1.1546 - 0.1454)/1000;
        end
        cur = (float(b).buoyancypumpcurrent + 3.606)/4.052;
        if ~isempty(cur)
            float(b).buoyancypumpcurrent = (cur*1.1546 - 0.1454)/1000;
        end
        %recalculate (A)
        cur = (float(b).airpumpcurrent + 3.606)/4.052;
        if ~isempty(cur)
            float(b).airpumpcurrent = (cur*1.1546 - 0.1454)/1000;
        end
        %recalculate (A)
        
        %vacuum/pressure recalculations:
        v = (float(b).p_internal + 29.767)/0.293;
        if ~isempty(v)
            float(b).p_internal = v*0.2878 - 29.8571;
        end
        
        %air pump pressure not currently pulled out. Need to look at maybe
        %doing this - look for AirSystem and Hg in the log file.
        
    end
    %save the battery data:
    batt = dat;
    save(['/home/argo/ArgoRT/battery/float' num2str(fnm) '.mat'],'batt')
    clear dat batt
    
    %save the updated float mat file:
    save(['./matfiles/float' num2str(fnm) '.mat'],'float')
end

%% remake our battery plots
for a = 1:length(THE_ARGO_FLOAT_DB)

    if THE_ARGO_FLOAT_DB(a).maker ~= 4
        continue
    end
    
    if any(fndone == THE_ARGO_FLOAT_DB(a).wmo_id)
        continue
    end
    
    plot_tech(THE_ARGO_FLOAT_DB(a).wmo_id)
end
