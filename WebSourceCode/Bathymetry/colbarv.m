% COLBARV  Place a *thin* colorbar at right of a frame
%
%         Jeff Dunn   CSIRO Marine Research  1997
%
% USAGE:  colbarv  OR  h = colbarv;

function hcb = colbarv()

hgca=gca;
gcapos = get(gca,'position');
hcb = colorbar;

cbpos = get(hcb,'position');
cbpos(1) = gcapos(1)+(gcapos(3)*.95);
cbpos(3) = .01;
set(hcb,'position',cbpos);

gcapos(3) = gcapos(3)*.94;
set(hgca,'position',gcapos);
clear hgca cbpos gcapos

if nargout==0
   clear hcb
end

return
