function traj = qc_tests_traj(traj)
%Apply the trajectory QC tests
% Input: traj structure from Argos floats
% Output: traj structure with qc flags applied
%
%RC December, 2017

%first put all the data in together.
% We don't need to worry about the order except for the position tests, and
% they are done on the traj file anyway.
for b = 1:length(traj)
    flds = fieldnames(traj(b));
    for a = 1:length(flds)
        if ~isempty(traj(b).(flds{a}))
            if isfield(traj(b).(flds{a}),'juld') & isempty(strfind('heads',flds{a})) ...
                    & isempty(strfind('raw',flds{a}))
                fp = traj(b).(flds{a});
                
                %set the qc to pass to start with
                fp.qc = repmat('1',1,length(fp.juld));
                if isfield(fp,'lat')
                    fp.qc_pos = repmat('1',1,length(fp.lat));
                end
                % Test1:  Platform Identification
                % How to check? Leave out.
                
                % Test2: Impossible Date Test:
                % we have done this test earlier
                j1 = julian([1997 1 1 0 0 0]);
                d =datestr(now,'yyyy mm dd HH MM SS');
                j2 = julian(str2num(d));
                
                % Actual test in the manual:
                %check the corresponding qc flag
                
                ii = fp.juld< j1 | fp.juld > j2;
                if sum(ii)>0
                    %this date is outside the date range, fails test
                    %record the failure
                    fp.qc(ii) = '4';
                end
                                
                % Test3: Impossible Location Test:
                % We have done this test earlier
                if isfield(fp,'lat')
                    ii = fp.lat<-90 | fp.lat > 90 | fp.lon<-180 | fp.lon > 180;
                    %check the corresponding qc flag
                    %record the failure
                    if sum(ii)>0
                        fp.qc_pos(ii) = '4';
                    end
%UP TO HERE!!!!!!!!!                                        
                    % Test4: Position on Land Test:
                    % Done in profile QC tests, but redo just in case?
                    inan = isnan(fp.lat);
                    try
                        deps = get_ocean_depth(fp.lat(~inan),fp.lon(~inan));
                        ii = deps < 0;
                        jj = deps >= 0;
                        %record the failure
                        if sum(ii)>0
                            if any(str2num(fp.pos_qc(ii))) ~= 4
                                t4 = 2;
                            else
                                t4 = 1;
                            end
                        end
                        if sum(jj)>0
                            if any(str2num(fp.pos_qc(jj))) ~= 1
                                t4 = 2;
                            elseif t4 ~=2 %not already failed
                                t4 = 1;
                            end
                        end
                    catch
                        %deps probably out of range of topo file, don't perform test.
                    end
                end
                
                % Test6: Global Range Test:
                
                %what about pressure, should be greater than -5db
                %not sure we are wrting the param_adjusted values correctly
                if isfield(fp,'p_raw')
                    ii = fp.p_raw < -5;
                    jj = fp.p_raw >= -5;
                    if any(ii)
                        if any(str2num(fp.p_rawqc(ii)) ~=4)
                            %record the failure
                            t6 = 2;
                        else
                            t6 = 1;
                        end
                    end
                    
                    if any(jj)
                        if any(str2num(fp.p_rawqc(jj)) ~=1)
                            %record the failure
                            t6 = 2;
                        elseif t6~=2 %not already failed
                            t6 = 1;
                        end
                    end
                    
                end
                
                if isfield(fp,'t_raw')
                    ii = (fp.t_raw<-2.5 | fp.t_raw>40.); %manual says <-2.5, we had -3.5!!
                    jj = (fp.t_raw>=-2.5 | fp.t_raw<=40.); %manual says <-2.5, we had -3.5!!
                    if any(ii)
                        if any(str2num(fp.t_rawqc(ii)) ~=4)
                            %record the failure
                            t6 = 2;
                        elseif t6 ~=2 %not already failed
                            t6 = 1;
                        end
                    end
                    if any(jj)
                        if any(str2num(fp.t_rawqc(jj)) ~=1)
                            %record the failure
                            t6 = 2;
                        elseif t6 ~=2 %not already failed
                            t6 = 1;
                        end
                    end
                    
                end
                if isfield(fp,'s_raw')
                    ii = (fp.s_raw<2.0 | fp.s_raw>41.);
                    jj = (fp.s_raw>=2.0 | fp.s_raw<=41.);
                    if any(ii)
                        if any(str2num(fp.s_rawqc(ii)) ~=4)
                            %record the failure
                            t6 = 2;
                        elseif t6 ~=2 %not already failed
                            t6 = 1;
                        end
                    end
                    if any(jj)
                        if any(str2num(fp.s_rawqc(jj)) ~=1)
                            %record the failure
                            t6 = 2;
                        elseif t6 ~=2 %not already failed
                            t6 = 1;
                        end
                    end
                end
                
                
                % Test7: Regional Parameter Test
                % we won't do this one?
                % This test applies to certain regions of the world where conditions can be further qualified. In this case, specific ranges for observations from the Mediterranean Sea and the Red Sea further restrict what are considered sensible values. The Red Sea is defined by the region 10N, 40E; 20N, 50E; 30N, 30E; 10N, 40E. The Mediterranean Sea is defined by the region 30N, 6W; 30N, 40E; 40N, 35E; 42N, 20E; 50N, 15E; 40N, 5W; 30N, 6W.
                % Red Sea
                % ?	Temperature in range 21.7 to 40.0°C
                % ?	Salinity in range 2 to 41.0 PSU
                % Mediterranean Sea
                % ?	Temperature in range 10.0 to 40.0°C
                % ?	Salinity in range 2 to 40.0 PSU
                % Action: If a value fails this test, it should be flagged as bad data (?4?), and only that value should be removed from TESAC distribution on the GTS. If temperature and salinity values at the same pressure both fail this test, both values should be flagged as bad data (?4?), and values for pressure, temperature and salinity should be removed from TESAC distribution on the GTS.
            end
        end
    end
end

% Test5: Impossible Speed Test:
%Use only for non-Argos floats
% Test speed between profiles. If apparently wrong, try some variant
% tests and maybe remove our present 1st fix if it appears wrong. Could
% test more combinations of previous profiles and fix numbers, but
% probably best to just eyeball any cases where this test fails.
[t5] = deal(0);
if ~isfield(fp,'lat')
    return
end
if findstr('ARGOS',fp.ts)
    %set up a structure for the jamstec tests
    [uc,~,np] = unique(fp.cyc);
    ii = findstr(' ',fp.pos_qc');
    fp.pos_qc(ii) = '0';
    fp.pos_qc = str2num(fp.pos_qc);
    if isempty(fp.pos_qc)
        %probalby not filled
        fp.pos_qc = zeros(size(fp.lat));
    end
    
    % Extract Argos locations for present (ie last) cycle
    for a = 1:length(np)
        pos_qc = jamstec_position_test(traj(a));
        if ~isempty(pos_qc)
            %check against qc for the profile
            if fp.pos_qc(np==a) ~= pos_qc
                t5 = 2;
            elseif t5 ~=2;
                t5 = 1;
            end
        end
    end
    %Test 20
    %Questionable Argos postion test - jamstec test?
    % use in place of test 5 for Argos floats.end
    % I think this test needs updating - wrt flagging when criterion 1 is
    % passed and 2 is not (line 97 to 99 of jamstec_position_test)
else
    %non-argos positioning systems
    % tests within and between profile positions. In all cases, should be
    % liss than 3m/s
    
    try
        distance = [0;sw_dist(fp.lat,fp.lon,'km')]*1000;
        timediff =  abs(fp.juld)*86400;
        speed = distance./timediff;
        ii = speed > 3;
        jj = speed <= 3;
        if any(ii)
            if any(fp.pos_qc(ii) ~=4)
                t5 = 2;
            else
                t5 = 1;
            end
        end
        if any(jj)
            if any(fp.pos_qc(jj) ~=1)
                t5 = 2;
            elseif t5 ~= 2
                t5 = 1;
            end
        end
    catch
        %might fail if only one position in the file.
    end
end
end
% GET_OCEAN_DEPTH  Find deepest and shallowest point within +/- .25 deg of each position
%
%   ** WARNING:  Hardcoded bathymetry file name!
%
% INPUT:  lat,lon - lat and lon for npos positions
%
% OUTPUT: dep - deepest point in bathymetry set within +/- .25 degrees
%
% Jeff Dunn  CSIRO/BoM  Aug 2006
%
% CALLED BY:  process_profile
%
% USAGE: [dep] = get_ocean_depth(lat,lon);
% edited 2017 July to use matlab netcdf toolbox. RC.

function [dep] = get_ocean_depth(lat,lon, dist)

fname = '/home/netcdf-data/topo_ngdc_8.2.nc';

% First call, so load bathymetry grid coords
XB = ncread(fname,'lon');
YB = ncread(fname,'lat');

% If for any reason we can't get depths, then 5000 is a benign fillin.
dep = repmat(5000,size(lat));
if nargin<3;dist=0.25;end

% Want longitude in range 0-360
if any(lon<0)
    ii = find(lon<0);
    lon(ii) = lon(ii) + 360;
end
% If we are wrapping around 0E, this test is not worth the complication it
% entails, so just go back.
if any(lon<.3 | lon>359.7)
    return
end

% Use lx,ly to find out if the subsampled locations in the bathy dataset
% change from one position to the next. If not, we save time by not reloading
% the bathymetry.

lx = 9999999999999; ly = [];
hb = -1*ncread(fname,'height');


for ii = 1:size(lat)
    ix = find(XB >= lon(ii)-dist & XB <= lon(ii)+dist);
    iy = find(YB >= lat(ii)-dist & YB <= lat(ii)+dist);
    
    if length(union(ix,lx))~=length(ix) | length(union(iy,ly))~=length(iy)
        hbi = hb(min(ix):max(ix),min(iy):max(iy));
        lx = ix;
        ly = iy;
    end
    dep(ii) = max(hbi(:));
    %    mindep(ii) = min(hb(:));
end

return
%-------------------------------------------------------------------------
end