% plot_all_profiles - this cycles through all the floats and regenerates
% the web plots for all profiles.  Edit this to plot only selected profiles
% or selected floats....

addpath src
global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB 
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end
jd=julian(clock)

dbb=getdbase(0);

dbA = THE_ARGO_FLOAT_DB;    % Just give it a shorter name

for fl=  1:length(dbA)
    [fl dbA(fl).wmo_id]
    
    [fpp,db] = getargo(dbA(fl).wmo_id);
    if ~isempty(fpp) & (abs(fpp(end).jday-jd)<=10) 
    
        fp=fpp(end);
        try
            web_profile_plot(fp,db);

        end
%           pause
    end 
end
