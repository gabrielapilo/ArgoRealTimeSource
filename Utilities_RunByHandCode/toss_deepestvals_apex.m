 function toss_deepestvals_apex(profile_name)

% function = toss_deepestvals_apex('profile_name','tech_name')
%
% checks for existence of deepest sample - if below drift pressure, sets QC = 3 
%


% Display profile name
profile_name;
disp (profile_name);

% Derive name of technical file
if is_pc 
    dir_sep='\';
else
    dir_sep='/';
end
first_sep=strrevfind(profile_name, dir_sep);
wmo_id= profile_name(first_sep+2:length(profile_name)-7);
meta_name=profile_name(1:first_sep);
sep_2=strrevfind(meta_name, dir_sep);
meta_name=meta_name(1:sep_2-1);
sep_3=strrevfind(meta_name, dir_sep);
meta_name=[meta_name(1:sep_3), wmo_id, '_meta.nc'];
 

% now open the profile netcdf profile for writing
f=netcdf(profile_name,'write');

% get the data state indicator

DATA_STATE_INDICATOR=f{'DATA_STATE_INDICATOR'}(:)

% only if there is a "B" suggesting this is real-time data should we do
% anything


%if  DATA_STATE_INDICATOR(3)== '2'  & DATA_STATE_INDICATOR(4)== 'B'  % only edit files that have not done the first Gilson screening
if findstr('2B',DATA_STATE_INDICATOR)
    % read in salinity and QC flags

    PSAL = f{'PSAL'}(:);
    PSAL_QC = f{'PSAL_QC'}(:);
 
    % read in temperature and and QC Flags 

     TEMP_QC = f{'TEMP_QC'}(:);
 
     
    % read in pressure and QC flags

    PRES = f{'PRES'}(:);
    PRES_QC = f{'PRES_QC'}(:);

    
    % Exit if not enough data (<=2)
    if max(PRES) <= 500.   % wont be affected
        return;
    end
    
    
    % open up the metanical file to get at the surface pressure reported by the float

    g=netcdf(meta_name,'nowrite');
 
    PARK_DB=g{'PARKING_PRESSURE'}(:)
    PROF_DB=g{'DEEPEST_PRESSURE'}(:)
    
   % still get 'hook' on park and profile floats
   %  if PARK_DB < (PROF_DB -100),
   %     disp(' THIS FLOAT DOES NOT DRIFT NEAR ITS PROFILE DEPTH - DONT USE THIS ROUTINE!!!')
   %     return
   % end
 
 
    % close the meta data file

    close(g)
    
    l=length(profile_name);
    prof_num=str2num(profile_name(l-5:l-3));
    
     % is deepest pressure is below nominal value - drift value
    
    [pmax,imax]=max(PRES);
    disp([' max pressure ',num2str(pmax,6)])
    
    % check that value is below profile pressure and that there is a measurement nearby profile_pressure
if pmax > PROF_DB &  abs([PRES(imax-1) - PROF_DB]) < 2.,  
    % have extra deep measurement which is drift and not profile
    % put QC = 3
    TEMP_QC(imax) = '3'
    PSAL_QC(imax) = '3';
end
     
 
    % Overwrite variables in the netcdf file

    f{'TEMP_QC'}(:)=TEMP_QC;
    f{'PSAL_QC'}(:)=PSAL_QC;
    
     

end % if  DATA_STATE_INDICATOR 

% close the netcdf profile file

close(f)

return