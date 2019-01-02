function [pro,fpp] = replicate_profile_struct(dbdat,fpp,np)
% function fpp = replicate_profile_struct(fpp)
% replicates and adds a profile structure to the end of an existing float
% structure. 
% Bec Cowley, October, 2018

% replicate
pro = fpp(end);

% Clear all the fields for the end profile
fldnms = fieldnames(pro);

for a = 1:length(fldnms)
    pro.(fldnms{a}) = [];
end

% Processing system fields
pro.proc_stage = 0;
pro.TL_cal_done = 0;
pro.proc_status = [0 0];
pro.fbm_report = zeros(1,8,'uint8');       % See find_best_msg.m
pro.stage_ecnt = zeros(2,5,'uint8');      % See process_profile.m
pro.stage_jday = [0; 0];              % Local dates of 1st & 2nd stage processing
pro.ftp_download_jday = [0; 0];       % UTC julian time of ftp download (stage 1&2)
pro.stg1_desc = '';                   % stage 1 description
pro.stg2_desc = '';                   % stage 2 description
pro.cal_report = zeros(1,6);          % See calsal.m
pro.rework = 0;                       % Can be set if want already processed

% Generic float data fields
pro.wmo_id = dbdat.wmo_id;
pro.maker = dbdat.maker;
pro.subtype = dbdat.subtype;   
pro.grounded = 'U';

pro.testsperformed = zeros(1,19,'uint8');     % QC info
pro.testsfailed = zeros(1,19,'uint8');        % QC info

fpp(np) = pro;
