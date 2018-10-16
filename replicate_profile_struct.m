function fpp = replicate_profile_struct(fpp)
% function fpp = replicate_profile_struct(fpp)
% replicates and adds a profile structure to the end of an existing float
% structure. 
% Bec Cowley, October, 2018

% replicate
fpp(end+1) = fpp(end);

% Clear all the fields for the end profile
fldnms = fieldnames(fpp(end));

for a = 1:length(fldnms)
    fpp(end).(fldnms{a}) = [];
end
