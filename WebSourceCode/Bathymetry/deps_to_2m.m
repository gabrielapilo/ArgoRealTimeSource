% DEPS_TO_2M  Interpolate values on arbitrary depths to regular 2m cast.
%     (Devolved from DEPS_TO_STDDEP v1.4  on  24/11/97)
% INPUT: odep  - *vector* of depths of the data (in m)
%        obs   - corresponding data values, with NaNs indicating any gaps.
%        maxdep - maximum depth of output profile (max 7000m)
% Optional
%        maxdis - see doco in "help rr_int"
%                 -1 => do NOT use rr_int
%
% OUTPUT: sdat - interpolated values on 2m intervals (from 0 to maxdep).
%
% $Id: deps_to_2m.m,v 1.3 2003/03/18 00:12:43 dun216 Exp dun216 $
% Jeff Dunn  24/11/97  Copyright CSIRO Division of Marine Research
%
% USAGE:  sdat = deps_to_2m(odep,obs,400)
%    OR:  sdat = deps_to_2m(odep,obs,400,maxdis)
% after first call to get threshold matrix from rr_int:
%         [dum,maxdis] = rr_int([],[],0:2:400);

function sdat = deps_to_2m(odep,obs,maxdep,maxdis)


% global rr_int_cnt lin_int_cnt dir_sub_cnt;
% Make persistent so that doesn't need to be recomputed every call
persistent DT2Mextd_lim

sdep = (0:2:maxdep)';
nlvl = length(sdep);

% Set up the distance-from-data threshold:
% extd_lim:   0-30=4  30-300=5  300-700=7  700-1100=16  1100-7000=30 
% near_lim is twice extd_lim,
% far_lim is a contrived function that looks about right

if isempty(DT2Mextd_lim)
   DT2Mextd_lim = [repmat(4,16,1); repmat(5,1351,1); repmat(7,200,1); ...
	 repmat(16,200,1); repmat(30,2950,1)];
end
near_lim = DT2Mextd_lim*2;
far_lim = (15+sdep).^0.7;

sdat = repmat(NaN,size(sdep));


% Remove NaNs (and test depths range as DPG files are sometimes crap)

odep = odep(:);
obs = obs(:);
jj = find(isnan(obs) | isnan(odep) | odep<0 | odep>8000);
if ~isempty(jj)
  obs(jj) = [];
  odep(jj) = [];
end
ndeps = length(obs);

if ndeps == 0
  return;
end

% ---- RETURN here if no data


if nargin<4; maxdis = 1; end

if ndeps < 4 | maxdis == -1
  sidx = (1:nlvl)';
else  
  sdat = rr_int(obs,odep,sdep,1,maxdis);
  sidx = find(isnan(sdat));

%  rr_int_cnt = rr_int_cnt + nlvl - length(sidx);
end


% Find which depths left to fill by linear interpolation. First, get index
% to sdep's between the odep's, then find between which pairs of odep's each
% remaining sdep falls, then calc distance from the two odep's, and assess 
% whether either near enough to one odep or the gap between the two odep's is 
% small enough to interpolate a value at that sdep.

if ~isempty(sidx)  & ndeps >= 2
  idx = sidx(find(sdep(sidx)>odep(1) & sdep(sidx)<odep(ndeps)));

  if ~isempty(idx)
    oidx = interp1q(odep,(1:ndeps)',sdep(idx));
    dists = [sdep(idx)-odep(floor(oidx)) odep(ceil(oidx))-sdep(idx)];  
    near = min(dists')';
    far = max(dists')';

    interp = idx(find(near<near_lim(idx) | far<far_lim(idx)));

    if ~isempty(interp)
      sdat(interp) = interp1q(odep,obs,sdep(interp));
      sidx = find(isnan(sdat));
      
%      lin_int_cnt = lin_int_cnt + length(interp);
    end
  end
end


% If any depths still remain unfilled, see if any are near enough to obs to
% just take that nearby value (ie direct substitution). First, any sdep which
% are beyond the range of odep would crash interp1 and also we would not find
% the odep nearest them. Beat this by adding extreme values to odep (and to 
% obs so that indices match between the two arrays).

if ~isempty(sidx)  
  odep = [-99999; odep; 99999];
  obs = [NaN; obs; NaN];
  idx = round(interp1q(odep,(1:ndeps+2)',sdep(sidx)));
  
  kk = find(abs(odep(idx)-sdep(sidx)) < DT2Mextd_lim(sidx));
  if ~isempty(kk)
    sdat(sidx(kk)) = obs(idx(kk));

%    dir_sub_cnt = dir_sub_cnt + length(kk);
  end
end

% ------------ End of deps_to_2m -----------------
