% COLBARH  Place a *thin* colorbar at bottom of a frame
%
%         Jeff Dunn   CSIRO Marine Research  1997
%
% USAGE:  colbarh  OR  h = colbarh;

function hcb = colbarh()
   
hgca=gca;
gcapos = get(gca,'position');
hcb = colorbar('horiz');

cbpos = get(hcb,'position');
cbpos(4) = .01;
set(hcb,'position',cbpos);

gcapos(2) = gcapos(2)+.04;
gcapos(4) = gcapos(4)*.94;
set(hgca,'position',gcapos);

if nargout==0
   clear hcb
end

return
