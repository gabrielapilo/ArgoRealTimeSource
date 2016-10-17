% LOGERR  Update global activity report structure and write msg to report file
%
% INPUT: 
%  level   1-fatal  2-error  3-warning  4-adjustment/correction  5-activity report
%          0-clear the report (and set new report prefix)
%
%  newrpt  additions to report, which may be:
%          empty - in which case nothing is added
%          a string - used as text for a new report. 'level' must be a scalar
%                     OR if level = 0,  text to prefix subsequent reports
%
% Jeff Dunn  CMAR/BoM  Aug 2006
%
% USAGE: logerr(level,newrpt);

function logerr(level,newrpt)

global ARGO_REPORT ARGO_RPT_FID
persistent PRFX 

levstr = {' L1 **FATAL ',' L2 *Error ',' L3 warning ',' L4 action ',...
	  ' L5 report '};

if nargin<2; newrpt = []; end

if isempty(ARGO_RPT_FID)
    PRFX=[];
end
if isempty(ARGO_REPORT) | level==0
   % Initialise the report variable
   ARGO_REPORT.ecnt =  [0 0 0 0 0];
   ARGO_REPORT.irp = 0;
   ARGO_REPORT.level = {};
   ARGO_REPORT.description = {};
   PRFX = newrpt;
   newrpt = [];
end

if isempty(newrpt)
   % do nothing - sent an empty message
else
   % Add a report
   ARGO_REPORT.ecnt(level) =  ARGO_REPORT.ecnt(level)+1;
   ARGO_REPORT.irp = ARGO_REPORT.irp+1;
   irp = ARGO_REPORT.irp;
   ARGO_REPORT.level{irp} = level;
   ARGO_REPORT.description{irp} = [PRFX ' ' newrpt];

   rpt = [PRFX levstr{level} newrpt];
   if isempty(ARGO_RPT_FID) | ARGO_RPT_FID<2
      % If no report file opened, write to 1 (stdout). 
      fprintf(1,'%s\n',rpt);
   else
      fprintf(ARGO_RPT_FID,'%s\n',rpt);
   end      
end

%---------------------------------------------------------------------------
