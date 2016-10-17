% JAMSTEC_POSITION_TEST  Carry out quality test of trajectory position fixes
%
%   float.position_accuracy  contains the Argos position accuracy class, ie
%       G 1 2 3 0 A B Z
%
% Jeff Dunn CMAR  July 2014, from Argo Cookbook, Section 12.
%
% INPUTS:  
%  traj - structure containing trajectory info for all cycles
%
% CALLED BY: load_traj_apex_argos
% 
% USAGE: flags = jamstec_position_test(traj);

function flags = jamstec_position_test(traj)

np = length(traj);

% Extract Argos locations for present (ie last) cycle
juld = traj(np).heads.juld; 
lat = traj(np).heads.lat; 
lon = traj(np).heads.lon; 
aclass = traj(np).heads.aclass;
flags = traj(np).heads.qcflags;

if ~any(flags==1)
   return
end


if np>1 && ~isempty(traj(np-1).heads) && any(~isnan(traj(np-1).heads.juld))
   if ~isfield(traj(np-1).heads,'qcflags') || isempty(traj(np-1).heads.qcflags)
      % Original processing did not add qcflags, so initially we will just
      % assume that last position from last cycle is good.
      jl = find(~isnan(traj(np-1).heads.juld),1,'last');
   else
      % Find last good position in last cycle 
      jl = find(traj(np-1).heads.qcflags==1,1,'last');
   end

   checking = ~isempty(jl);
   if checking
      lal = traj(np-1).heads.lat(jl);
      lol = traj(np-1).heads.lon(jl);
      jdl = traj(np-1).heads.juld(jl);
   end
   
   % Step 1: section 12.2.1
   while checking && sum(flags<=2)>0 
      k1 = find(flags<=2,1,'first');
      rr = distance_lpo([lal; lat(k1)],[lol; lon(k1)]);
      spd = rr/((juld(k1)-jdl)*86400);
      if spd>3
	 flags(k1) = 4;
      else
	 checking = 0;
      end
   end
end

% Rank Argos position classes, and define corresponding error radii
ArgosClass = 'ZBA0123G';
errad = [1503 1502 1501 1500 1000 350 150 100];   

checking = sum(flags==1)>1;

while checking && sum(flags==1)>1
   ii = find(flags==1);
   dist = vec(distance_lpo(lat(ii),lon(ii)));
   tdel = 86400.*diff(juld(ii));
   spd = dist./tdel;
   [smx,imax] = max(spd);
   % spd(i) relates to positions ii(i) and ii(i+1), so max speed arises from
   % positions ii(imax) and ii(imax+1) {called A,B respectively in Cookbook sec 12.3}
   
   checking = smx>3;
   if checking
      % Step 2,3: sec 12.2.2,3  Speed Test   
      if ~exist('classrank','var')
	 % When first needed, get the error radii (squared) appropriate to
         % each fix's position class 
	 classrank = ones(size(aclass));
	 for jj = 2:length(ArgosClass)
	    classrank(aclass==ArgosClass(jj)) = jj;
	 end
	 ersq = errad(classrank).^2;
      end      
      
      nii = length(ii);
      if aclass(ii(imax))==aclass(ii(imax+1))
	 % Locations have same Argos Class
	 
	 % The "distance test" 12.4
	 if dist(imax)>sqrt(sum(ersq(ii([imax imax+1]))))
	    flg = 3;
	 else
	    % We are told to delete this position, but not to set the
            % flag='3', so I suppose we set it to '2'??
	    flg = 2;
	 end
	 
	 if nii==2
	    % Last 2 positions - label both as abnormal
	    flags(ii) = flg;
	 elseif imax>1 && imax<length(ii)-1
	    % Have positions before and after the questionable pair 

	    XBdist = distance_lpo([lat(ii(imax-1)) lat(ii(imax+1))],[lon(ii(imax-1)) lon(ii(imax+1))]);
	    AYdist = distance_lpo([lat(ii(imax)) lat(ii(imax+2))],[lon(ii(imax)) lon(ii(imax+2))]);
	    XBtdel = 86400*(juld(ii(imax+1))-juld(ii(imax-1)));
	    AYtdel = 86400*(juld(ii(imax+2))-juld(ii(imax)));

	    XAYspd = (dist(imax-1)+AYdist)./(tdel(imax-1) + AYtdel);
	    XBYspd = (XBdist+dist(imax+1))./(XBtdel + tdel(imax+1));
	 
	    if XAYspd>XBYspd
	       flags(ii(imax)) = flg;
	    else
	       flags(ii(imax+1)) = flg;
	    end

	 elseif imax==1
	    % Case 1: First positions but have some positions after this
	    AYdist = distance_lpo([lat(ii(imax)) lat(ii(imax+2))],[lon(ii(imax)) lon(ii(imax+2))]);
	    AYtdel = 86400*(juld(ii(imax+2))-juld(ii(imax)));

	    AYspd = AYdist./AYtdel;
	 
	    if AYspd>spd(imax+1)
	       flags(ii(imax)) = flg;
	    else
	       flags(ii(imax+1)) = flg;
	    end
	    
	 else
	    % Case 2: Last positions but have some positions before this
	    XBdist = distance_lpo([lat(ii(imax-1)) lat(ii(imax+1))],[lon(ii(imax-1)) lon(ii(imax+1))]);
	    XBtdel = 86400*(juld(ii(imax-1))-juld(ii(imax+1)));

	    XBspd = XBdist./XBtdel;
	 
	    if XBspd>spd(imax)
	       flags(ii(imax+1)) = flg;
	    else
	       flags(ii(imax)) = flg;
	    end
	 
	 end
	    
      else
	 % Case 3: Locations have different Argos Class
	 if classrank(ii(imax)) < classrank(ii(imax+1))
	    flags(ii(imax)) = 3;
	 else
	    flags(ii(imax+1)) = 3;
	 end
      end
   
   end
end
   

%---------------------------------------------------------------------------
