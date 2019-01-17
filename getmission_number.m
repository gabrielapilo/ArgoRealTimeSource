% function [mn, config]=getmission_number(wmo_id,pn,all,dbdat)
%
% function to retrieve the current mission number from the aux.mat files
% for iridium floats:
% 
% usage:  [mn,config]=getmission_number(wmo_id,pn,dbdat) where
%     wmo_id is the wmo id of the float
%     pn is the profile number for which you need a mission number
%     dbdat is the dabatase structure for the float (could combine this
%      with wmo_id but added later and simpler to keep it separate - maybe
%      later...)
%   output - mn = mission number
%            config = mission structure for the float
%            all = get all missions or just the mission number for the
%            current profile?
%        
%
%  AT - Feb 2014

function [mn,config]=getmission_number(wmo_id,pn,all,dbdat)

global  ARGO_SYS_PARAM

floatTech=[];
config=[];

if dbdat.maker==5
    
    fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) 'auxS.mat'];
    mn=1;
    return
elseif dbdat.subtype==1015
    mn=1;
    return
else    
    fn= [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo_id) 'aux.mat'];
end

if exist(fn)
    
    load(fn);
    if ~isempty(floatTech)
        try
            mn=floatTech.Mission(pn).mission_number;
        catch
            mn=1;
        end
    else
        mn=1;
    end
else
    mn=1;
end


% now I need to go get the correct configuration names for each parameter
% and report back in a structure for the metadata files:

names=fieldnames(floatTech.Mission);
[m,n]=size(names);
mm=floatTech.Mission;
[m1,n1]=size(mm);
j=0;
values=[];

if all  %need all mission information for the metadata file:
    n0=1;
    
else    
    n1=pn;
    n0=pn;
end

for i=1:m
    
    if strmatch('AscentTimeOut',names{i})
        j=j+1;
        namesC{j}='CONFIG_AscentToSurfaceTimeOut_minutes';
        for k=n0:n1
            k=k;
            values(j,k)=mm(k).AscentTimeOut;
        end
    elseif strmatch('AscentTimeout',names{i})
            j=j+1;
            namesC{j}='CONFIG_AscentToSurfaceTimeOut_minutes';
            for k=n0:n1
                k=k;
                values(j,k)=mm(k).AscentTimeout;
            end
    elseif strmatch('BuoyancyNudgeInitial',names{i})
        j=j+1;
        namesC{j}='CONFIG_FirstBuoyancyNudge_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).BuoyancyNudgeInitial;
        end
    elseif strmatch('InitialBuoyancyNudge',names{i})
        j=j+1;
        namesC{j}='CONFIG_FirstBuoyancyNudge_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).InitialBuoyancyNudge;
        end
    elseif strmatch('BuoyancyNudge',names{i})
        j=j+1;
        namesC{j}='CONFIG_SlowAscentPistonAdjustment_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).BuoyancyNudge;
        end
    elseif strmatch('ConnectTimeOut',names{i})
        j=j+1;
        namesC{j}='CONFIG_ConnectionTimeOut_seconds';
        for k=n0:n1
            values(j,k)=mm(k).ConnectTimeOut;
        end
    elseif strmatch('CpActivationP',names{i})
        j=j+1;
        namesC{j}='CONFIG_CPActivationPressure_dbar';
        for k=n0:n1
            values(j,k)=mm(k).CpActivationP;
        end
    elseif strmatch('DeepProfileDescentTime' ,names{i})
        j=j+1;
        namesC{j}='CONFIG_DescentToProfTimeOut_minutes';
        for k=n0:n1
            values(j,k)=mm(k).DeepProfileDescentTime;
        end
    elseif strmatch('DeepDescentTimeout' ,names{i})
        j=j+1;
        namesC{j}='CONFIG_DescentToProfTimeOut_minutes';
        for k=n0:n1
            values(j,k)=mm(k).DeepDescentTimeout;
        end
    elseif strmatch('DeepProfilePistonPos',names{i})
        j=j+1;
        namesC{j}='CONFIG_PistonProfile_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).DeepProfilePistonPos;
        end
    elseif strmatch('DeepProfileBuoyancyPos',names{i})
        j=j+1;
        namesC{j}='CONFIG_PistonProfile_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).DeepProfileBuoyancyPos;
        end
    elseif strmatch('DeepProfilePressure',names{i})
        j=j+1;
        namesC{j}='CONFIG_ProfilePressure_dbar';
        for k=n0:n1
            values(j,k)=mm(k).DeepProfilePressure;
        end
    elseif strmatch('DeepDescentPressure',names{i})
        j=j+1;
        namesC{j}='CONFIG_ProfilePressure_dbar';
        for k=n0:n1
            values(j,k)=mm(k).DeepDescentPressure;
        end
    elseif strmatch('DownTime',names{i})
        j=j+1;
        namesC{j}='CONFIG_DownTime_minutes';
        for k=n0:n1
            values(j,k)=mm(k).DownTime;
        end
    elseif strmatch('IceDetectionP',names{i})
        j=j+1;
        namesC{j}='CONFIG_IceDetectionMixedLayerPMax_dbar';
        for k=n0:n1
            values(j,k)=mm(k).IceDetectionP;
        end
    elseif strmatch('IceEvasionP',names{i})
        j=j+1;
        namesC{j}='CONFIG_IceDetectionMixedLayerPMin_dbar';
        for k=n0:n1
            values(j,k)=mm(k).IceEvasionP;
        end
    elseif strmatch( 'IceMLTCritical',names{i})
        j=j+1;
        namesC{j}='CONFIG_IceDetection_degC';
        for k=n0:n1
            values(j,k)=mm(k).IceMLTCritical;
        end
    elseif strmatch( 'Direction',names{i})
        j=j+1;
        namesC{j}='CONFIG_Direction_NUMBER';
        for k=n0:n1
            values(j,k)=mm(k).Direction;
        end
    elseif strmatch( 'IceCriticalT',names{i})
        j=j+1;
        namesC{j}='CONFIG_IceDetection_degC';
        for k=n0:n1
            values(j,k)=mm(k).IceCriticalT;
        end
    elseif strmatch('IceMonths',names{i})
        j=j+1;
        namesC{j}='CONFIG_BitMaskMonthsIceDetectionActive_NUMBER';
        for k=n0:n1
            im=mm(k).IceMonths;
            ll=strfind(im,'x');
            im(ll)=[];
            mmd=hex2dec(im);
            values(j,k)=str2num(dec2bin(mmd));
        end
    elseif strmatch('ParkDescentTime',names{i})
        j=j+1;
        namesC{j}='CONFIG_DescentToParkTimeOut_minutes';
        for k=n0:n1
            if dbdat.subtype==1023
                values(j,k)=mm(k).ParkDescentTimeout;
            else
                values(j,k)=mm(k).ParkDescentTime;
            end
        end
    elseif strmatch('ParkPistonPos',names{i})
        j=j+1;
        namesC{j}='CONFIG_PistonPark_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).ParkPistonPos;
        end
    elseif strmatch('ParkBuoyancyPos',names{i})
        j=j+1;
        namesC{j}='CONFIG_PistonPark_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).ParkBuoyancyPos;
        end
    elseif strmatch('ParkPressure',names{i})
        j=j+1;
        namesC{j}='CONFIG_ParkPressure_dbar';
        for k=n0:n1
            values(j,k)=mm(k).ParkPressure;
        end
    elseif strmatch('PnPCycleLen',names{i})
        j=j+1;
        namesC{j}='CONFIG_ParkAndProfileCycleCounter_COUNT';
        for k=n0:n1
            values(j,k)=mm(k).PnPCycleLen;
        end
    elseif strmatch('DeepDescentCount',names{i})
        %             j=j+1;
        %             namesC{j}='CONFIG_ParkAndProfileCycleCounter_COUNT';
        %             for k=n0:n1
        %                 values(j,k)=mm(k).PnPCycleLen;
        %             end
    elseif strmatch('RafosWindowN',names{i})
        %         j=j+1;
        %         namesC{j}='CONFIG_';
    elseif strmatch('TelemetryRetry',names{i})
        j=j+1;
        namesC{j}='CONFIG_TelemetryRetryInterval_seconds';
        for k=n0:n1
            if dbdat.subtype==1023
                values(j,k)=mm(k).TelemetryRetryInterval;
            else
                values(j,k)=mm(k).TelemetryRetry;
            end
        end
    elseif strmatch('TimeOfDay',names{i})
        %         j=j+1;
        %         namesC{j}='CONFIG_DownTimeExpiryTimeOfDay';
    elseif strmatch('UpTime',names{i})
        j=j+1;
        namesC{j}='CONFIG_UpTime_minutes';
        for k=n0:n1
            values(j,k)=mm(k).UpTime/60;
        end
    elseif strmatch('DebugBits',names{i})
        %             j=j+1;
        %             namesC{j}='CONFIG_DebugBits_NUMBER';
        %             for k=n0:n1
        %                 values(j,k)=mm(k).DebugBits;
        %             end
    elseif strmatch('TargetAscentSpeed',names{i})
        j=j+1;
        namesC{j}='CONFIG_TargetAscentSpeed_cm/s';
        for k=n0:n1
            values(j,k)=mm(k).TargetAscentSpeed;
        end
    elseif strmatch('AscentRate',names{i})
        j=j+1;
        namesC{j}='CONFIG_TargetAscentSpeed_cm/s';
        for k=n0:n1
            values(j,k)=mm(k).AscentRate;
        end
    elseif strmatch('mission_number',names{i})
        %             j=j+1;
        for k=n0:n1
            mission_no(k)=floatTech.Mission(k).mission_number;
        end
    elseif strmatch('new_mission',names{i})
        %             j=j+1;
        for k=n0:n1
            newmiss(k)=floatTech.Mission(k).new_mission;
        end
    elseif strmatch('CompensatorHyperRetraction',names{i})
        
    elseif strmatch('FlbbMode',names{i})
        %             j=j+1;
        %             namesC{j}='????';
        %             for k=1:n1
        %                 values(j,k)=mm(k).FlbbMode;
        %             end
    elseif strmatch('HpvEmfK',names{i})
        %             j=j+1;
        %             namesC{j}='????';
        %             for k=1:n1
        %                 values(j,k)=mm(k).HpvEmfK;
        %             end
    elseif strmatch('HpvRes',names{i})
        %             j=j+1;
        %             namesC{j}='????';
        %             for k=1:n1
        %                 values(j,k)=mm(k).HpvRes;
        %             end
    elseif strmatch('CdomMode',names{i})
        %             j=j+1;
        %             namesC{j}='????';
        %             for k=1:n1
        %                 values(j,k)=mm(k).FlbbMode;
        %             end
    elseif strmatch('ActivateRecoveryMode',names{i})
               
    elseif strmatch('AscentTimerInterval',names{i})
        
    elseif strmatch('DeepDescentTimerInterval',names{i})
        
    elseif strmatch('DeepProfileFirst',names{i})
        
    elseif strmatch('EmergencyTimerInterval',names{i})
        
    elseif strmatch('IceBreakupDays',names{i})
        
    elseif strmatch('IdleTimerInterval',names{i})
        
    elseif strmatch('LogVerbosity',names{i})
        
    elseif strmatch('MActivationCount',names{i})
        
    elseif strmatch('MActivationPressure',names{i})
        
    elseif strmatch('MinBuoyancyCount',names{i})
        
    elseif strmatch('LeakDetect',names{i})
        
    elseif strmatch('MinVacuum',names{i})
        
    elseif strmatch('ParkBuoyancyNudge',names{i})
        
    elseif strmatch('ParkDeadBand',names{i})
        
    elseif strmatch('ParkDescentCount',names{i})
               
    elseif strmatch('ParkTimerInterval',names{i})
               
    elseif strmatch('PreludeSelfTest',names{i})
               
    elseif strmatch('SurfacePressure',names{i})
               
    elseif strmatch('CheckSum',names{i})
               
    elseif strmatch('PreludeTime',names{i})
%                
%     elseif strmatch('',names{i})
               
    elseif strmatch('IsusInit',names{i})
    else
        disp(['Dont panic. Found a new mission config parameter: ' names{i}])
        %             return
    end
end


if all
    dd=find(newmiss==0);
    values(:,dd)=[];
    mission_no(dd)=[];
else
    values(:,1:pn-1)=[];
    mission_no(1:pn-1)=[];
end

config.names=namesC;
config.missionno=mission_no;
config.values=values;



