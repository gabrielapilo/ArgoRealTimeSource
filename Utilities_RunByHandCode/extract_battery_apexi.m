%extract the apex battery information
clear all

fnms = [5905030
    5903221
    5904245
    5903242
    5903245
    5903258
    5903226
    5901677
    5903232
    5903256
    5903659];

for a = 1%:length(fnms)
    [float,dbdat] = getargo(fnms(a));
    fnm = fnms(a);
    clear dat batt
    dirs  = ['/home/argo/ArgoRT/iridium_data/iridium_processed/' num2str(fnm) '/'];
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
        fid = fopen([dirs sprintf('%04d',dbdat.argos_id) '.' ...
            sprintf('%03d',float(b).profile_number) '.log'],'r');
        if fid > 0
            log = textscan(fid,'%s','Delimiter','|');
            fclose(fid);
            %get all the volts indications:
            ii = find(cellfun(@isempty,strfind(log{1},'Sbe41cpStartCP'))==0);
            if ~isempty(ii)
                
                ij = find(cellfun(@isempty,strfind(log{1},'PistonMoveAbsWTO'))==0);
                step = ij-ii;
                jj = min(find(step > 0));
                
                if ~isempty(jj)
                    %now extract and group them by the name. Record the date/time
                    str = log{1}{ii+step(jj)};
                    %             date/time
                    dt = textscan(str,'(%s','delimiter',',');
                    dat.time(b) = datenum(float(b).datetime_vec(1,:));
                    
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
                        v = regexp(str,'....Volts','match');
                        if isempty(v)
                            %look at next 2 lines
                            for nl = 1:2
                                str = log{1}{ii+step(jj+1)+nl};
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
                        dat.secondpumpvolt(b) = v;
                        
                        cur = regexp(str,'.....Amps','match');
                        cur = str2num(cur{:}(1:end-4));
                        dat.secondpumpcurrent(b) = cur;
                    end
                end
            end
        end
        if ~isnan(float(b).parkbatterycurrent)
            dat.parkbatterycurrent(b) = float(b).parkbatterycurrent;
        end
        if ~isnan(float(b).parkbatteryvoltage)
            dat.parkbatteryvolt(b) = float(b).parkbatteryvoltage;
        end
       
    end
    %save the battery data:
    batt = dat;
    save(['/home/argo/ArgoRT/battery/apex/float' num2str(fnm) '.mat'],'batt')
    clear dat batt
end

