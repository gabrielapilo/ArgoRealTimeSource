% blankfloat creates a blank entry in the float mat files for empty
% profiles.
function float=blankfloat(float,jj);

fieldn=fieldnames(float);
for kk=1:length(fieldn)
    blankn=['float(' num2str(jj) ').' fieldn{kk} ' = [];'];
    eval(blankn);
end    