%run_allArgoRTplots and re-generate web files:

global THE_ARGO_FLOAT_DB
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

getdbase(0);
for ii =1:length(THE_ARGO_FLOAT_DB)
    ii=ii
    dbdat = getdbase(THE_ARGO_FLOAT_DB(ii).wmo_id);
    fpp = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
    if ~isempty(fpp) % & (~isempty(strmatch('live',dbdat.status)) | ~isempty(strmatch('suspect',dbdat.status)))  
 
        
%        waterfallplots(fpp);
%        time_section_plot(fpp)
%        locationplots(fpp);
%         tsplots(fpp);
        
%         for j=1:length(fpp)
%             fp=fpp(j);
%             try
%                web_plot_generation(fp,dbdat);
% if(~isempty(fpp))
%                web_profile_plot(fp,dbdat);
                  web_float_summary(fpp,dbdat,1);

%         webUpdatePages(dbdat.wmo_id,1);
%         make_tech_webpage(num2str(dbdat.wmo_id));
%         plot_tech(num2str(dbdat.wmo_id));

% end
%             end
%         end
    end
end
