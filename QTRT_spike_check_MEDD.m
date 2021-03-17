function [is_spike,PROF_med,medm,medp,BO] = ...
             QTRT_spike_check_MEDD(PARAM, PROF, PRES, Z_levels, Med_SlideW,Z_dpdz,dpdz_thr,ddpdz_thr,d)

%   Author: D.Dobler (IFREMER) 
% 	Date: 2019/11/06
%   Version: 1.1
%   Modification:   1.1 (2019/11/06): layout improvements
%					1.0 (2019/09/01): creation
%
% 	Input arguments:
%   - PARAM = 'DENS' or 'TEMP' or 'PSAL' (are coded for the moment). This is used for specific limits and 
%			for the nondimensionalization of the axes in the step that computes the distance d to median curve
%	- PROF if the profiles to test (could be PSAL, TEMP, or their ADJUSTED counterpart)
%   - PRES is the corresponding pressures in dbar for vertical location.
%   - Z_levels defines 4 vertical zones [Z1; Z2; Z3 ; Z4]. e.g: Z_levels=[150;500;1000;1500] to customize sliding windows to global ocean variability
%   - Med_SlideW is the sliding window in [dbar] to compute median, depending on vertical zones. 
% 		For example Med_SlideW=[110;180;400 ;500] => +/- 110 dbar above Z1; +/- 110 dbar at Z1; +/- 180 dbar at Z2; +/- 400 dbar at Z3; +/- 500 dbar at Z4; +/- 500 dbar below Z4
%       then the sliding windows are linearly interpolated on segment [Z1, Z2], [Z2, Z3] and  [Z3, Z4].
%   - Z_dpdz are the Z levels used for vertical derivative thresholds definition (dpdz_thr and ddpdz_thr)
%   - dpdz_thr are the maximum allowed vertical derivative values for the parameter PARAM
%   - ddpdz_thr are the maximum allowed vertical derivative values when the sign changes for the parameter PARAM
% 	- d is a distance to median curve as a percentage of the windows
%
%   Output arguments:
%   - is_spike is size(PRES) and equal to one when PROF is out [medm medp] window
%   - PROF_med is the sliding median of the profile with many customizations
%   - medm and medp are computed as a 2D relative distance d from median
%   - BO is a break out flag used for performance computation
%

% STEP 0 - Initialization of outputs
% ------------------------------------------------

% outputs initializations
is_spike=zeros(size(PRES));
PROF_med=nan(size(PRES));
medm=nan(size(PRES));
medp=nan(size(PRES));
BO=0;

% internal initializations
dpdz_1950=zeros(size(PRES));
i_1950=nan(size(PRES));
isMed_set_to_Prof=zeros(size(PRES));
isout_global=zeros(size(PRES));


% STEP 1 - if not enough points: break out function
% ------------------------------------------------
i_ok=find(isfinite(PROF.*PRES));
i_ok=i_ok';
if length(i_ok)<=5
	BO=1;
	%disp ('break out: no enough points')
	return
end

% STEP 2 - Compute vertical derivative of profile values (used later for median adjustments)
% ------------------------------------------------
dpdz=nan * ones(size(PROF));
dpar=nan * ones(size(PROF));
dz=nan * ones(size(PROF));

dpar(i_ok(2:end))   = diff(PROF(i_ok));
dz(i_ok(2:end))    = diff(PRES(i_ok));
% compute vertical gradient
dpdz(i_ok(2:end)) = dpar(i_ok(2:end))./dz(i_ok(2:end));

% if points are too close, force it to be set at zero to prevent from erroneous big values
dpdz(find(abs(dpar)<0.01 & abs(dz)<5))=0;

% duplicate the gradient of the second point into the first point
dpdz(i_ok(1))=dpdz(i_ok(2));


% STEP 3: Compute sliding window 
% ------------------------------
SW =  Med_SlideW(1) .* (PRES < Z_levels(1)) + ...
	 (Med_SlideW(1) + (Med_SlideW(2) - Med_SlideW(1)) * ((PRES-Z_levels(1))/(Z_levels(2)-Z_levels(1))) ) .* (PRES >= Z_levels(1) & PRES < Z_levels(2)) + ...
	 (Med_SlideW(2) + (Med_SlideW(3) - Med_SlideW(2)) * ((PRES-Z_levels(2))/(Z_levels(3)-Z_levels(2))) ) .* (PRES >= Z_levels(2) & PRES < Z_levels(3) ) + ...
	 (Med_SlideW(3) + (Med_SlideW(4) - Med_SlideW(3)) * ((PRES-Z_levels(3))/(Z_levels(4)-Z_levels(3))) ) .* (PRES >= Z_levels(3) & PRES < Z_levels(4) ) + ...
	  Med_SlideW(4) .* (PRES >= Z_levels(4)) ;



% STEP 4: Compute arrays of parameters dpdz_max and ddpdz_max depending on Z_dpdz levels
% -----------------------------------------------------------------------------------------
dpdz_max     = 	dpdz_thr(1) *(PRES < Z_dpdz(1)) + ...
				dpdz_thr(2) *(PRES >= Z_dpdz(1) & PRES < Z_dpdz(2)) + ...
				dpdz_thr(3) *(PRES >= Z_dpdz(2) & PRES < Z_dpdz(3)) + ...
				dpdz_thr(4) *(PRES >= Z_dpdz(3) & PRES < Z_dpdz(4)) + ...
				dpdz_thr(5) *(PRES >= Z_dpdz(4) & PRES < Z_dpdz(5)) + ...
				dpdz_thr(6) *(PRES >= Z_dpdz(5)); 
ddpdz_max =  ddpdz_thr(1) *(PRES < Z_dpdz(1)) + ...
				ddpdz_thr(2) *(PRES >= Z_dpdz(1) & PRES < Z_dpdz(2)) + ...
				ddpdz_thr(3) *(PRES >= Z_dpdz(2) & PRES < Z_dpdz(3)) + ...
				ddpdz_thr(4) *(PRES >= Z_dpdz(3) & PRES < Z_dpdz(4)) + ...
				ddpdz_thr(5) *(PRES >= Z_dpdz(4) & PRES < Z_dpdz(5)) + ...
				ddpdz_thr(6) *(PRES >= Z_dpdz(5)); 


% STEP 5 - Record doubtful points to discard them in the median computation
% -------------------------------------------------------------------------

% STEP 5.i Discard large vertical derivative with a change of sign (ddpdz_max thresholds)
% ---------------------------------------------------------------------------------------				
dpdz_ok=dpdz(i_ok);
dpdz_okn  =dpdz_ok(2:end-1);
dpdz_oknp1=dpdz_ok(3:end);
ddpdz_maxok=ddpdz_max(i_ok);
ddpdz_maxokn  =ddpdz_maxok(2:end-1);
ddpdz_maxoknp1=ddpdz_maxok(3:end);

i_out = find(  abs(dpdz_okn) > ddpdz_maxokn &  ...
			  abs(dpdz_oknp1) > ddpdz_maxoknp1 &  ...
			  sign(dpdz_okn) == -1 * sign(dpdz_oknp1) );
% i_out is expressed in dpdz_okn dimension: put it back in terms of PROF level dimension
i_okbis=i_ok(2:end-1);
i_out=i_okbis(i_out);
isout_global(i_out)=1;

% duplicate for first value as dpdz(1) is set to dpdz(2)
isout_global(i_ok(1))=isout_global(i_ok(2));
	
% STEP 5.ii Discard fast increase in temperature or decrease in density
% ---------------------------------------------------------------------
% Supplementary test because density generally increases
if strcmp(PARAM,'DENS')
	i_dens_neg=find(dpdz_ok < -0.001 );
	isout_global(i_ok(i_dens_neg))=1;
end

% Supplementary test because temperature generally decreases (except at high latitudes)
if strcmp(PARAM,'TEMP')
	i_temp_pos=find(dpdz_ok > 0.5 );
	isout_global(i_ok(i_temp_pos))=1;
end

% STEP 5.i Discard large vertical derivative (dpdz_max thresholds)
% ----------------------------------------------------------------
i_bigGradient=find(abs(dpdz) > dpdz_max);
isout_global(i_bigGradient)=1;


% STEP 6 - Compute sliding median
% ------------------------------------------------

% STEP 6.i - Initialization of a last correct index array
% -------------------------------------------------------
% This begins with a trick to record the correct index just above for isout_global points.
% This will be used later to assign a median value for isout_global points
i_notout=find(isout_global~=1 & ~isnan(PRES) & ~isnan(PROF));
if length(i_notout) > 0
	last_correct_isnotout_level=i_notout(1)*ones(size(PRES));
else 
	last_correct_isnotout_level=ones(size(PRES));
end

% STEP 6.ii - Loop on all levels with finite PROF and PRES
% --------------------------------------------------------
for i_level = i_ok

	% 6.ii.a - Select coherent indices to compute median depending on vertical levels
	DZ_max = ceil(SW(i_level)/2)+1;
	i_coh=find(abs(PRES-PRES(i_level)) < DZ_max & ~isout_global & ~isnan(PRES) & ~isnan(PROF));
	i_coh=sort(i_coh);
	
	% 6.ii.b - Keep the same depth extension below and above actual level if enough points
	dPRES=PRES(i_level)-PRES(i_coh);

	n_above=length(find(dPRES>0));
	i_above=i_coh(find(dPRES>0));
	n_below=length(find(dPRES<0));
	i_below=i_coh(find(dPRES<0));
	n_equal=min(n_below,n_above);
	if n_equal ~= 0
		% N.B.: special warning, “below” and “above” refer to vertical sense: 
		% below is closest to bottom and above is closest to the surface. 
		% The corresponding indices are reversed as profile is read for surface to bottom: 
		% thus  i_above are the smallest indices and i_below are the largest indices.
		i_above=i_above(end-n_equal+1:end);
		i_below=i_below(1:n_equal);
		i_val=find(i_coh==i_level);
		if length(i_val) ~=0
			i_coh=[i_level i_above' i_below' ];
		else 
			i_coh=[i_above' i_below'];
		end
		i_coh=sort(i_coh);
		i_coh=i_coh';
	end

			
	% 6.ii.c - case some issue with pressure and no more coherent value.
	if length(i_coh)==0
		i_coh=i_level;
	end
	

	% 6.ii.d - Keep the number of values even for the median computation
	% with an even number of observations, the computed median is the mean of the two central values
	% this is not what is wanted. Here an easy routine to force it uneven.
	if mod(length(i_coh),2)==0
		i_coh=[i_coh(1); i_coh];
	end

	% 6.ii.e - Compute sliding median
	PROF_med(i_level)=median(PROF(i_coh),'omitnan');
	
	% 6.ii.f - Adjust median when there is no enough coherent points (i_coh) below

	ii=find(i_ok==i_level);
	j=(ii>1)*(ii-1)+(ii==1)*ii; % trick to handle first point
	i_levelm1=i_ok(j);
	
	if i_level>i_ok(1) & isout_global(i_level)==0 & isout_global(i_levelm1)==0
		if i_level == i_coh(end) % for the last point of a series
			isMed_set_to_Prof(i_level)=1;
		elseif length(i_coh)>1
			if i_level == i_coh(end-1) % and for the second last point of a series
				isMed_set_to_Prof(i_level)=1;
			end
		end
	end
	
	% 6.ii.g - Adjust median when there is no enough coherent points (i_coh) above
	ii=find(i_ok==i_level);
	j=(ii<length(i_ok))*(ii+1)+(ii==length(i_ok))*ii;% trick to handle last point
	i_levelp1=i_ok(j);
	
	if i_level<i_ok(end) & isout_global(i_level)==0 & isout_global(i_levelp1)==0
		if i_level == i_coh(1)  ... % only for the first point of a series
			if ~(strcmp(PARAM,'TEMP') & dpdz(i_level)> 0.1)
				isMed_set_to_Prof(i_level)=1;
			end
		elseif length(i_coh)>1
			if i_level == i_coh(2) &  ~(strcmp(PARAM,'TEMP') & dpdz(i_level)> 0.1) % and for the second point of a series
				isMed_set_to_Prof(i_level)=1;
			end
		end
	end
	
	
	% 6.ii.h - Adjust median for deep pressure values.
	
	% The purpose of this step is to trap spiky points for hedgehog profiles. 
	% This should be trapped by Pressure increasing test normally. 
	% It has been checked that it did not degrade for deep Argo but 
	% definitely, there is a need to better define dpdz_max  for pressure values deeper than 2000 dbar.
	
	% First record the level of last acceptable computed median above 1950 dbar 
	% and compute the gradient between current i_level and levels above 1950 dbar.

	
	% first find last acceptable median above 1950 dbar
	iPRES_med_ok=find(isout_global(i_level) ~= 1 & PRES < 1950);
	iPRES_med_ok=sort(iPRES_med_ok);
	if length(iPRES_med_ok)>0
		i_1950(i_level)=iPRES_med_ok(end);
		dpdz_1950(i_level)=(PROF(i_level)-PROF(i_1950(i_level)))/(PRES(i_level)-PRES(i_1950(i_level)));
	end
	% then , if below 1950 dbar, this is too steep: replace by the last acceptable median computed above 1950dbar.
	if PRES(i_level) >=1950 & abs(dpdz_1950(i_level)) > dpdz_max(i_level)
		PROF_med(i_level)=PROF_med(i_1950(i_level));
		isMed_set_to_Prof(i_level)=0;
	elseif PRES(i_level) >=1950 & isout_global(i_level)==0
		isMed_set_to_Prof(i_level)=1;
	end
	
	
	% 6.ii.i - Record last correct i_level value to adjust median for isout_global levels
	if i_level>i_ok(1)
		if isout_global(i_level)==1
			last_correct_isnotout_level(i_level)=last_correct_isnotout_level(i_ok(ii-1));
		else
			last_correct_isnotout_level(i_level)=i_level;
		end
	end
	
end

% STEP 6.iii - Finalize median computation
% ----------------------------------------
% First set to profile value the median for eligible levels (steps 6.ii.f , 6.ii.g and 6.ii.h):
i_MedProf=find(isMed_set_to_Prof==1);
PROF_med(i_MedProf)=PROF(i_MedProf);
% Second, set to last correct median for isout_global levels (step 5, step 6.i and step 6.ii.i)
i_isout=find(isout_global==1);
PROF_med(i_isout)=PROF_med(last_correct_isnotout_level(i_isout));


% STEP 7 - Compute thresholds using 2D relative distance to median
% ----------------------------------------------------------------

% STEP 7.i - Retrieve indices for vertical zones
% ---------------------------------------------

i_VZ1=find(PRES < Z_levels(2) );
i_VZ2=find((PRES < Z_levels(3)) & (PRES >=Z_levels(2) ));
i_VZ3=find((PRES < Z_levels(4)) & (PRES >=Z_levels(3) ));
i_VZ4=find(PRES >= Z_levels(4));


% STEP 7.ii - Initialize arrays
% -----------------------------
medm_1=nan(size(PROF_med));
medp_1=nan(size(PROF_med));
medm_2=nan(size(PROF_med));
medp_2=nan(size(PROF_med));
medm_3=nan(size(PROF_med));
medp_3=nan(size(PROF_med));
medm_4=nan(size(PROF_med));
medp_4=nan(size(PROF_med));

% STEP 7.iii - Nondimensionalization of axes
% ------------------------------------------

	% The z-axis was first nondimensionalized  by a fixed maximal extension of 2000 dbar 
	% but by experience, it was more adapted with a smaller value.
	Lz=700;
	
	% The x-axis is nondimensionalized  by the extension of the x-values 
	% but this extension is bounded to avoid too large or too small windows.
	Lx=max(PROF_med(i_ok))-min(PROF_med(i_ok));
	if strcmp(PARAM,'TEMP')
		Lx=max(min(Lx,10),4);
	end
	if strcmp(PARAM,'PSAL')
		Lx=max(min(Lx,5),1);
	end
	if strcmp(PARAM,'DENS')
		Lx=max(min(Lx,6),1);
	end
	
	% Here, I’ve made something not straight to get directly the output of 2D relative distance function in the dimension of PROF.
	% Instead of nondimensionalizing PROF and PRES, apply the function on them and put dimension back the output, 
	% I have chosen to nondimensionalize PRES and dimensionalize d
	
	PRES_b=PRES*Lx/Lz;
	d_b=d*Lx;

% STEP 7.iv - Call relative 2D distance function
% ----------------------------------------------	

[medm_1(i_ok), medp_1(i_ok)] = relative_2D_distance(PROF_med(i_ok),PRES_b(i_ok),d_b(1));
[medm_2(i_ok), medp_2(i_ok)] = relative_2D_distance(PROF_med(i_ok),PRES_b(i_ok),d_b(2));
[medm_3(i_ok), medp_3(i_ok)] = relative_2D_distance(PROF_med(i_ok),PRES_b(i_ok),d_b(3));
[medm_4(i_ok), medp_4(i_ok)] = relative_2D_distance(PROF_med(i_ok),PRES_b(i_ok),d_b(4));


medm(i_VZ1)=medm_1(i_VZ1);
medm(i_VZ2)=medm_2(i_VZ2);
medm(i_VZ3)=medm_3(i_VZ3);
medm(i_VZ4)=medm_4(i_VZ4);
medp(i_VZ1)=medp_1(i_VZ1);
medp(i_VZ2)=medp_2(i_VZ2);
medp(i_VZ3)=medp_3(i_VZ3);
medp(i_VZ4)=medp_4(i_VZ4);


% STEP 8 - Construct is_spike output
% ----------------------------------
i_biggap=(PROF > medp | PROF < medm);
is_spike(find(i_biggap>0))=1;
