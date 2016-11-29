% GETSECTION: Extract a vertical section from the "atlas" maps.
%
%   * * *  U S E    G E T _ C L I M _ C A S T S   I N S T E A D * * *
%
% INPUT:
%  property - name; eg: 'temperature' or just 't'
%  xx       - longitudes onto which to interpolate maps
%  yy       - latitudes   "         "           "
% Optional:
%  deps     - vector of standard levels to extract. Default 1:33
%  cpath    - path to file if not default one
%  cfile    - name of file if not default one
%
% JRD April 97
%
% USAGE: [mn,an,sa] = getsection(property,xx,yy,deps,cpath,cfile)

function [mn,ann,san] = getsection(property,xx,yy,deps,cpath,cfile)

if nargin<4
  deps = 1:33;
end

eezgrid;

npos = prod(size(xx));
xx = xx(:)';
yy = yy(:)';

out = find(xx<100 | xx>180 | yy<-50 | yy>0);
if ~isempty(out)
  disp([num2str(length(out),6) '/' num2str(npos,7) ...
	  ' positions outside map range']);
  if length(out)==npos
    return
  end
end

mn = NaN*ones(length(deps),npos);
ann = mn + i*mn;
san = ann;

jj= find(deps<=19);
if ~isempty(jj)
  for kk = jj(:)'
    ii = deps(kk);
    an = []; sa = [];
    if nargin<=4
      [zi,an,sa] = getmap(property,ii);
    elseif nargin==5
      [zi,an,sa] = getmap(property,ii,cpath);
    else
      [zi,an,sa] = getmap(property,ii,cpath,cfile);
    end

    mn(kk,:) = interp2(Xg,Yg,zi,xx,yy,'*linear');
    if ~isempty(an)
      ann(kk,:) = interp2(Xg,Yg,an,xx,yy,'*linear');
    end
    if ~isempty(sa)
      san(kk,:) = interp2(Xg,Yg,sa,xx,yy,'*linear');
    end
  end
end

jj= find(deps>19);
if ~isempty(jj)
  for kk = jj(:)'
    ii = deps(kk);
    if nargin<=4
      zi = getmap(property,ii);
    elseif nargin==5
      zi = getmap(property,ii,cpath);
    else
      zi = getmap(property,ii,cpath,cfile);
    end
  
    mn(kk,:) = interp2(Xg,Yg,zi,xx,yy,'*linear');
  end
end

