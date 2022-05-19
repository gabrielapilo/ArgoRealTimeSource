% CALSAL_DMOFFSET  Calibrates salinity in raw (near-realtime) Argo float,
%           and loads variable 's_calibrate'
%           calibration value (i.e., PSAL offset) is provided by DMQC team
%           Adapted from calsal in end-2021/mid-2022
%
% INPUT
%  float - struct array of profiles for one float. It is assumed that
%          profiles have already been QCed.
%  ical  - index to those to be calibrated (optional)
%
% OUTPUT
%   nfloat - copy of 'float', but with 's_calibrate' and all conductivity
%            profile variables loaded; these variables are set to 0 when
%            there is no PSAL offset value to be included in the adjustment
%   cal_report - LEGACY, not used anymore; 6 diagnostic values for the last profile calibrated
%         1 - "theta" (min theta of near-bottom values)
%         2 - num profile potential T values in cal range
%         3 - num reference CTDs used
%         4 - range of c_ratio estimates [large value (>.0005?) may indicate
%             problems in profile data]
%            5,6 supplied if can calculate a calibration
%         5 - correction as applied to S value at top of cal range
%         6 - threshold: median STD(S) [plus measure of local spatial
%             variability in clim S estimates at theta?]
%
% AUTHOR: original calsal written by Jeff Dunn  CMAR    Oct 2007
%         calsal_DMoffset adapted by Gabi Pilo  CSIRO   Oct 2021
%
% USAGE: [nfloat,cal_report] = calsal_DMoffset(float,ical,calibrate);

function [nfloat,cal_report] = calsal_DMoffset(float,ical)

% The CTD reference set variables are loaded once and retained thereafter
persistent CalFilNam CalFilNamDMoffset CalX CalY CalY0 Calinc CalPotTLev CalPLmin  CalPLmax;

global ARGO_SYS_PARAM ARGO_ID_CROSSREF;

cal_report = zeros(1,6);
dbdat = getdbase(float(end).wmo_id);

if nargin<=1
    ical = [];
end

% Loads mat file with PSAL offset values provided by DMQC team
if ~exist([ARGO_SYS_PARAM.CalFilNamDMoffset],'file')
    logerr(2,['calsal_DMoffset: cannot see PSAL offset file ' ARGO_SYS_PARAM.CalFilNamDMoffset ]);
    nfloat = float;
    return
else
    load(ARGO_SYS_PARAM.CalFilNamDMoffset)
end

cal_report = zeros(1,6);
npro = length(float);

% Check if this float has a PSAL offset
f = find(float(1).wmo_id == DMoffset(:,1));

if ~isempty(f) & length(f) == 1; % If the float is in the list
    
    % Initial cycle to apply PSAL offset from
    cycle_init = DMoffset(f,2);
    % PSAL Offset to be applied
    psal_offset = DMoffset(f,3);
    
    
    if abs(psal_offset) > 0.005; % no need to adjust if PSAL offset is <0.005
        
        display(['Applying PSAL offset of ' num2str(psal_offset) ' to WMO ID ' num2str(float(1).wmo_id)])
        
        %         % I don't think we need this
        %         if ~isfield(float,'c_ratio') % creates c_ratio field, if absent
        %             float(1).c_ratio = [];
        %             float(1).c_ratio_calc = [];
        %         end
        
        % Profiles to calibrate:
        ical = cycle_init:npro;
        
        if any(ical>npro); % to catch for erroneous nprof values in the DM file (may not be needed)
            ii = find(ical<=npro);
            ical = ical(ii); % will only calibrate profiles that exist
            logerr(3,['CALSAL: WMO ' num2str(float(1).wmo_id) ...
                ' - some specifed profiles not found in "float"']);
        end
        
        % Do not work on any empty profiles, partly because they crash sw_ routines.
        bad = zeros(size(ical));
        for kk = 1:length(ical)         %ical(:)'
            fp = float(ical(kk));
            bad(kk) = isempty(fp.s_raw) || isempty(fp.t_raw) || isempty(fp.p_raw);
        end
        ical(find(bad)) = [];
        
    else % if PSAL offset < 0.005
        nfloat=float;
        return
    end
    
else % if the float is not in the list for PSAL adjustment
    float(ical).s_calibrate = float(ical).s_raw;
    nfloat=float;
    return
end

%%%%%%%%%% Continues if there is PSAL to adjust %%%%%%%%%%

for kk = ical(1):ical(end); % loops in cycles to adjust
    
    % Loads this cycle
    fp = float(kk);
    
    % Skips if this cycle has been adjusted already
    %     if fp.deltaS ~= psal_offset
    
    fp.deltaS = psal_offset;
    fp.c_ratio = 1; % legacy from calsal code
    
    % Applies calibration to PSAL with QC flags 1, 2, and 3
    sgood = ismember(fp.s_qc,[1 2 3]);
    
    % applied PSAL offset to PSAL and save it as s_calibrate (which is saved as PSAL_ADJUSTED in nc file)
    fp.s_calibrate = fp.s_raw;
    fp.s_calibrate(sgood) = fp.s_calibrate(sgood) + psal_offset; % offset is negative, PSAL drift looks like freshening
    
    % We have made a new s_calibrate, which is not Thermal Lag corrected, so
    % clear the TL flag (it would be 0 anyway, unless we are repeating steps)
    fp.TL_cal_done = 0;
    
    % trap for missing T or P that still has S yet results in nan S in
    % calibrated variable
    gg=find(isnan(fp.s_calibrate) & fp.s_qc~=9);
    if ~isempty(gg)
        fp.s_qc(gg)=4;
    end
    
    %%%%%% Saves the calibrated profile %%%%%
    % Load this profile back into float array
    float(kk) = fp;
    
end

% end

nfloat = float;

end