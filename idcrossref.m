% IDCROSSREF  Return all IDs for the given id(s) of one type. 
%
% INPUTS 
%   idin  - ID number(s) of one type (eg ARGOS id)
%   idtyp - idin's type:  1=WMO  2=ARGOS  3=deployment number  
%   itout - [optional] type for the list of output IDs, if only want one type.
%
% OUTPUT 
%   ids   - [N x 3]  The 3 IDs such that ids(:,idtyp) == idin
%        OR [N x 1]  if itout specified above
%
% SEE ALSO  getdbase.m
% 
% Jeff Dunn CSIRO/BoM Aug 2006
%
% EXAMPLE:  >> ids = idcrossref([21 117],3)
%           ids =
%               5900037       6390         21
%               5901160      57589        117
%           >> ids = idcrossref(6390,2,1)
%           ids =
%               5900037
%
% USAGE: ids = idcrossref(idin,idtyp,itout);

function ids = idcrossref(idin,idtyp,itout)

global ARGO_ID_CROSSREF

ids = [];

if nargin<2 | isempty(idtyp) | idtyp<1 | idtyp>3
   disp('IDCROSSREF: Supply 2nd arg "idtyp" (1=WMO  2=ARGOS  3=deploy num)')
   return
end
if nargin<3 | isempty(itout)
   itout = 1:3;
end
   
if isempty(ARGO_ID_CROSSREF)
   disp('IDCROSSREF:  Loading float database');
   tmp = getdbase(0);
end

typnm = {'WMO','ARGOS','Deployment num'};
	 
ii = [];
miss = [];
for nn = idin(:)'
   jj = find(ARGO_ID_CROSSREF(:,idtyp)==nn);
   if isempty(jj)
      miss = [miss nn];
%    elseif length(jj)>1   %no - this is fine!!! trapped elsewhere and maybe you want the first one!
      % Duplicate IDs - presumably Argos IDs, and presumably one "live" and
      %  NO!!!!
      % one "dead", so select the "live" one  NO!!!!
%       if all(ARGO_ID_CROSSREF(:,4)==0) || all(ARGO_ID_CROSSREF(:,4)==1)
% 	 % Strange, but just return the last duplicate (lower in the database
% 	 % means more recent)
%       else
	 % Find the live one
%      jjold=jj;
%          jj = find(ARGO_ID_CROSSREF(:,idtyp)==nn & ARGO_ID_CROSSREF(:,4)==1);
%       end
%       if(isempty(jj))
%          jj=jjold;
%       end
%       ii = [ii jj(end)];
   else
      ii = [ii jj];
   end
end

if ~isempty(miss)
   disp(['IDCROSSREF: Cannnot find ' typnm{idtyp} ' ID for these IDs:']);
   disp(num2str(miss));
end

if ~isempty(ii)
   ids = ARGO_ID_CROSSREF(ii,itout);
end

%--------------------------------------------------------------------------
