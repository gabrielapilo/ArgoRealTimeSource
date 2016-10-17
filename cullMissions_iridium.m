% cullMissions_iridium
%
% designed to gather mission information from iridium floats
% this is then stored in float#####aux.mat so the mission number can be
% calculated.
%
% It can be used either to cull all missions from existing floats or add
% missions from new profiles to an existing file.
%
%  AT: Feb 2014
%
%  Usage:  cullMissions_iridium(dbdat,fname)
% where fname contains the path to the iridium msg file for one profile
% fname=-1 regenerates all missions from the iridium_processed directory
% for a given float

function cullMissions_iridium(dbdat,fname)

global ARGO_SYS_PARAM

wmo_id=dbdat.wmo_id;

if ispc
fn= [ARGO_SYS_PARAM.root_dir 'matfiles\float' num2str(wmo_id) 'aux.mat']
else
fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) 'aux.mat']
end

if exist(fn,'file')
    try
        load(fn);
    catch
        floatTech=[];
    end
else
    floatTech=[];
end
fnm=[];
ms=[];
new=0;

if fname==-1
    [fpp,dbdat]=getargo(wmo_id);
    j=0;
    for i=1:length(fpp)
        if ~isempty(fpp(i).jday)
            ii=sprintf('%3.3i',i)
            if ispc
            fn2=[ARGO_SYS_PARAM.root_dir 'iridium_data\iridium_processed\' num2str(wmo_id) '\' dbdat.argos_hex_id '.' ii '.msg'];
            else
            fn2=[ARGO_SYS_PARAM.root_dir 'iridium_data/iridium_processed/' num2str(wmo_id) '/' dbdat.argos_hex_id '.' ii '.msg'];
            end  
            if exist(fn2,'file')
                j=j+1;
                fnm{j}=fn2;
            end
        end
    end
else
    fnm{1}=fname;
end

if isempty(fnm)
    return;
end


for k=1:length(fnm)  % go and get the mission data from individual iridium data files
    fid=fopen(fnm{k});
    pn=str2num(fnm{k}(end-6:end-4));
    if ~isempty(floatTech) & pn>1
        try
            ms=floatTech.Mission(pn-1);
        catch  %looks like empty missions exist - fill:
            % found a good mission:
            for jl=length(floatTech.Mission)+1:pn
                floatTech.Mission(jl)=floatTech.Mission(end);
            end
            ms=floatTech.Mission(pn-1);
           
        end        
    elseif isempty(floatTech)
        cullInitialMission;

    else
        ms=floatTech.Mission(1);
    end
    l=fgetl(fid);
    if strmatch('$',l)
        while strmatch('$',l)
            par=strfind(l,'(');
            par2=strfind(l,')');
            if ~isempty(par)
                if strfind(l,'TimeOf') 
                    
                    if strmatch(l(par+1:par2-1),'DISABLED')
                        mn=['ms.' l(3:par-1) '= NaN;'];
                    else
                        mn=['ms.' l(3:par-1) '= ' l(par+1:par2-1) ';'];
                    end
                    eval(mn);
                                        
                elseif strfind(l,'Debug')
                    
                    mn=['ms.' l(3:par-1) '= ''' l(par+1:par2-1) ''';'];
                    eval(mn);
                                        
                elseif strfind(l,'IceMonths')
                    
                    mn=['ms.' l(3:par-1) '= ''' l(par+1:par2-1) ''';'];
                    eval(mn);
                    
                elseif isempty(strfind(l,'AtD')) & isempty(strfind(l,'AltD')) & isempty(strfind(l,'FloatId')) & ...
                        isempty(strfind(l,'Verbo')) & isempty(strfind(l,'Full')) & isempty(strfind(l,'PActiv')) & ...
                        isempty(strfind(l,'Max')) & isempty(strfind(l,'Mission')) & isempty(strfind(l,'OkV')) & ...
                        isempty(strfind(l,'User')) & isempty(strfind(l,'Pwd')) & ...
                        isempty(strfind(l,'Flbb')) & isempty(strfind(l,'Compens')) 
                    
                    mn=['ms.' l(3:par-1) '=' l(par+1:par2-1) ';'];
                    eval(mn);
                    
                end
            end
            l=fgetl(fid);
        end
    else
        % this might be a float with the mission hidden in the logfile:
        fnm{k}(end-2:end)='log';
%         fclose(fid);
        if ~exist(fnm{k})  % this log file is missing...
            
            ms=floatTech.Mission(max(pn-1,1));
            
        else
            
            fid2=fopen(fnm{k});
            if ~isempty(floatTech) & pn>1
                try
                ms=floatTech.Mission(pn-1);
                catch  %looks like empty missions exist - fill:
                     % found a good mission:
                    for jl=length(floatTech.Mission)+1:pn
                        floatTech.Mission(jl)=floatTech.Mission(end);
                    end
                end
           
                        
            elseif isempty(floatTech)
                cullInitialMission;
                
            else
                ms=floatTech.Mission(1);
            end
            l=fgetl(fid2);
            while(l~=-1)
                config=strfind(l,'LogConfiguration');
                if ~isempty(config)
                    l=strtrim(l(config+20:end));
                    par=strfind(l,'(');
                    par2=strfind(l,')');
                    if ~isempty(par)
                        if strfind(l,'TimeOf')
                            if strmatch(l(par+1:par2-1),'DISABLED')
                                mn=['ms.' l(1:par-1) '= NaN;'];
                            else
                                mn=['ms.' l(1:par-1) '= ''' l(par+1:par2-1) ''';'];
                            end
                                eval(mn);
                            
                        elseif strfind(l,'Debug')
                            
                            mn=['ms.' l(1:par-1) '= ''' l(par+1:par2-1) ''';'];
                            eval(mn);
                            
                        elseif strfind(l,'IceMonths')
                            
                            mn=['ms.' l(1:par-1) '= ''' l(par+1:par2-1) ''';'];
                            eval(mn);
                            
                        elseif isempty(strfind(l,'AtD')) & isempty(strfind(l,'AltD')) & isempty(strfind(l,'FloatId')) & ...
                                isempty(strfind(l,'Verbo')) & isempty(strfind(l,'Full')) & isempty(strfind(l,'PActiv')) & ...
                                isempty(strfind(l,'Max')) & isempty(strfind(l,'Mission')) & isempty(strfind(l,'OkV')) & ...
                                isempty(strfind(l,'User')) & isempty(strfind(l,'Pwd'))
                            
                            mn=['ms.' l(1:par-1) '=' l(par+1:par2-1) ';'];
                            eval(mn);
                            
                        end
                    end
                end
                
                l=fgetl(fid2);
                
            end
            %         return  %????
        end
%         try
%         fclose(fid);
%         end
    end
    % now calculate mission number and identify whether it's a new or old
    % mission:

    if ~isempty(ms)
        names = fieldnames(ms);
        if pn>1
            
            for g=pn-1:-1:1
                differs=0;
                try
                    missNO(g)=floatTech.Mission(g).mission_number;
                catch
                    missNO(g)=0;
                end
                if missNO(g)~=0
                    if dbdat.maker==4
                        dff=40;
                    else
                        dff=20;
                    end
                    for gg=1:length(names)
                if isempty(strmatch('mission_number',names{gg})) & isempty(strmatch('new_mission',names{gg}))
                        v1=getfield(ms,names{gg});
                        v2=getfield(floatTech.Mission(g),names{gg});
                        if isnan(v1);v1=-99;end
                        if isnan(v2);v2=-99;end
                       if strmatch(names{gg},'DeepProfilePistonPos') % & 
                           if (pn-g==1);
                               if abs(v1-v2)>dff
                                   differs=1;
                               end
                           end
                       elseif strmatch(names{gg},'ParkPistonPos') % &
                           if (pn-g==1)
                               if abs(v1-v2)>dff
                                   differs=1;
                               end
                           end
                       elseif strmatch(names{gg},'DeepProfileBuoyancyPos') % &
                           if(pn-g==1)
                               if abs(v1-v2)>dff
                                   differs=1;
                               end
                           end
                       elseif strmatch(names{gg},'ParkBuoyancyPos') % &
                           if (pn-g==1)
                               if abs(v1-v2)>dff
                                   differs=1;
                               end
                           end
                       else
                           if v1~=v2
                               differs=1;
                           end
                       end
                end
                    end
                    if ~differs
                        ms.mission_number = floatTech.Mission(g).mission_number;
                        ms.new_mission = 0;
                        break
                    end
                end
                
                if differs
                    new=1
                    ms.mission_number = max(missNO)+1;
                    ms.new_mission = 1;
                end
            end
            
            
        else
            ms.mission_number = 1;
            ms.new_mission = 1;
        end
    end
    if ~isempty(ms)    
        try
            floatTech.Mission(pn)=ms;
        catch
            floatTech=[];
            floatTech.Mission=ms;
        end
    end
end
try
    fclose(fid);
    fclose(fid2);
end
save (fn,'floatTech','-v6');
if new
    [fpp,dbdat]=getargo(dbdat.wmo_id);
    metadata_nc(dbdat,fpp);
end
    



    


