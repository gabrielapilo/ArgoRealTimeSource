% NEW_PROC_REC_STRUCT   Create a blank Argo post-processing control structure
%
%          THIS is also the DEFINITION of the structure 
%
%   An exact match should be maintained between the USE of the variables 
%   and any DESCRIPTIONS below.
%
% INPUT   dbdat - Argo database record for one float
%         np    - profile number
%
% OUTPUT  prec  - processing record struct (with ID fields set and all 
%                 others initialised)
%
% Called by:   process_profile
%
%  Jeff Dunn  CSIRO/BoM  Oct 2006
%
% USAGE: prec = new_proc_rec_struct(dbdat,np);

function prec = new_proc_rec_struct(dbdat,np)

% Id fields
prec.wmo_id = dbdat.wmo_id;
prec.argos_id = dbdat.argos_id;
prec.profile_number = np;
prec.jday_ascent_end = [];

% Post-Processing control fields
prec.new = 1;
prec.proc_stage = 0;
prec.prof_nc_count = 99;
prec.tech_nc_count = 99;   
prec.meta_nc_count = 99;
prec.traj_nc_count = 99;   
prec.gts_count = 99;

% Processing report fields
prec.proc_status = [0 0];
prec.stage_ecnt = zeros(2,5,'uint8');      % See process_profile.m
prec.ftptime = [];

return

%------------------------------------------------------------------------
