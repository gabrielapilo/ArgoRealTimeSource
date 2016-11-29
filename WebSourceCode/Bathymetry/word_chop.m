% WORD_CHOP  Chop up a string of space separated words into a cell array of words
%
% Jeff Dunn 29 March 1999   CSIRO Marine Research

function words = word_chop(str)

instr = deblank(str);
iw = 0;
while ~isempty(instr)
   [addw,instr] = strtok(instr);
   iw = iw+1;
   words{iw} = addw;
end
