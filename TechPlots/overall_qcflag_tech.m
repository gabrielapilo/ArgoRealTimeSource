% OVERALL_QCFLAG  Compute the Argo QC status flag given the QC flags for
%       a single profile. We assume that profile has been QC-ed.
%
% INPUT:  qcp     - vector of profile QC values 
% OUTPUT: status  - single character ('A' to 'F')
%
% Jeff Dunn CSIRO/BoM  Aug 2006
%
% MODS:  2/10/08  Allow for possible all-0 profiles ("no QC performed")
%                 Also allows character input vector. This version 
%                 is optimal for ArgoRT system.
%
% CALLED BY:  argoprofile_nc
%
% USAGE: status = overall_qcflag(qcp)

function status = overall_qcflag(qcp)

if isstr(qcp)
   qcp = str2num(qcp(:))';
end

bd = sum(qcp==3 | qcp==4 | qcp==6 | qcp==7);
nn = sum(qcp~=9);

if any(qcp==0)
   % No QC performed!
   status = nan;
elseif nn==0   
   % An empty profile, either no values or all missing values 
   status= nan;      
else
   badd = bd/nn;
   if badd == 0
      status = 1;
   elseif badd <= .25
      status = 2;
   elseif badd <= .5
      status = 3;
   elseif badd <= .75
      status = 4;
   elseif badd < 1
      status = 5;
   else
      status = 6;
   end
end

return
%----------------------------------------------------------------------------
