% Script to drive ArgoRT in various test modes
%
%   Expected that the user will modify this script


global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF
global ARGO_SYS_PARAM
if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

% Super severe restart: clear output files so that all profiles are rebuilt
%
%system(['rm ' ARGO_SYS_PARAM.root_dir 'matfiles/*']);
%system(['rm ' ARGO_SYS_PARAM.root_dir 'export/*']);
%system(['rm ' ARGO_SYS_PARAM.root_dir 'reports/*']);

spth = ARGO_SYS_PARAM.argos_downloads;

choose = 2;

if choose==1
   % Normal operation

   [st,lfile] = system(['ls -1tr ' spth '*.log | tail -1']);
   if st~=0
      error('Cannot find lastest download file');
   end
   lfile = deblank(lfile);

   strip_argos_msg(lfile,[]);

elseif choose==2
   % Reprocessing (after setting rework flag)

   rework_flag_set(1);
   
   %opts.rtmode = 0;
   opts.rtmode = 1;
   opts.tr_now = 0;
   opts.savewk = 2;
   opts.redo = [];
   opts.prec_fnm = [];
   %opts.prec_fnm = 'nov13_proc_records';
   
   fpth = ARGO_SYS_PARAM.argos_downloads;

   for ii = [347]
      disp(['File ' num2str(ii)]);
      fnm = [fpth 'argos' int2str(ii) '.log'];
      strip_argos_msg(fnm,[],opts);
      web_processing_report(opts.prec_fnm,1,0,1);
   end   

   getdbase(0);
   for ii = 1:length(THE_ARGO_FLOAT_DB)
      fpp = getargo(THE_ARGO_FLOAT_DB(ii).wmo_id);
      if ~isempty(fpp)
	 web_float_summary(fpp,THE_ARGO_FLOAT_DB(ii),1);
      end
   end

   % Finished reworking, so clear flag for those not reworked.
   %disp('*** Clearing rework flag temporarily disabled')
   rework_flag_set(0);

elseif choose==3
   % manual TESTING - single pass
   
   lfile = '';          % ??
   wmo = [];            % ??
   
   opts.rtmode = 1;
   opts.tr_now = 0;
   opts.savewk = 2;
   opts.redo = [1 2];

   strip_argos_msg(lfile,wmo,opts);
end



