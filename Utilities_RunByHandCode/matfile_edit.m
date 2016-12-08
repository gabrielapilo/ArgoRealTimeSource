% MATFILE_EDIT  Perform some limited actions on one Argo matfile.
%     Should never be needed - use with great reservation (but do use 
%     this rather than directly fiddling with matfiles in Matlab!
%
%            IMPORTANT NOTE 
%  Workfiles are named according to element number in matfile array,
%  so any changes to order of profiles will break correspondance of  
%  individual Workfiles with the matfile profiles. It is messy and
%  risky, but I think you should carefully rename workfiles to reflect
%  the changes in the matfile.
%
% INPUT:  wmo  - WMO ID of file to edit
%         cmd  - command:
%                's'   = sort profiles in matfile according to jday(1)
%                'rNN' = remove profile(s) NN
%                'iNN' = insert one blank profile at NN
%             where NN is index in 'float' array (NOT Argo profile_number)
%             NN can be multiple numbers for 'r' but only a single number 
%             for 'i' (just so we don't get muddled.) 
%
% OUTPUT  nil
%    Files:  modified Argo matfiles
%
% JRD Nov 06
%
% CALLED BY:  for interactive use only
%
% Example:  
%   If profile 7 is empty or a duplicate, and should remove it:
%       matfiles_edit(wmo,'r7')
%
%   If 35 profiles, the last few having pnums 34 35 37. Want to insert
%   a blank profile at float(35) so that then have pnums  34 35 0 37
%   for float(33:36), ready for reprocessing to retrieve pnum 36:
%       matfiles_edit(wmo,'i35')
%
% USAGE: matfile_edit(wmo,cmd)

function matfile_edit(wmo,cmd)

global ARGO_SYS_PARAM
global THE_ARGO_FLOAT_DB  ARGO_ID_CROSSREF

if isempty(ARGO_SYS_PARAM)
   set_argo_sys_params;
end

if isempty(THE_ARGO_FLOAT_DB)
   getdbase(0);
end
db = THE_ARGO_FLOAT_DB;    % Just give it a shorter name


fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(wmo)];


if exist([fnm '.mat'],'file')
   load(fnm,'float');
   np = length(float);
   disp(['This matfile has ' num2str(np) ' profiles');
   j1 = repmat(nan,[np 1]);
   for ii=1:np
      if ~isempty(float(ii).jday(1))
	 j1(ii) = float(ii).jday(1);
      end
   end
   dbdat = getdbase(wmo);
end


nn = eval(cmd(2:end));

if strcmp(cmd(1),'r') || strcmp(cmd(1),'R')

   % REMOVE some profiles
   
   if isempty(nn) 
      error(['This command does not scan: ' cmd]);
   elseif any(nn<1) || any(nn>np)
      error('Specified profiles exceed size of float array')
   end
   disp('You want to remove profiles with these profile_numbers:') 
   disp(num2str([float(nn).profile_number]));
   ss = input('Continue? [n] : ','s');
   if ~isempty(ss) && (strcmp(ss,'y') || strcmp(ss,'Y'))
      float(nn) = [];      
      save(fnm,'float','-v6');
      disp(['Done. Now ' num2str(length(float)) ' profiles in ' fnm]);
   end
   
elseif strcmp(cmd(1),'i') || strcmp(cmd(1),'I')

   % INSERT one profile
   
   if isempty(nn) 
      error(['This command does not scan: ' cmd]);
   elseif length(nn)>1
      % Could allow this, but won't because easy to get muddled.
      disp('Sorry - can only insert one profile at a time')
   elseif nn<1 || nn>np
      disp(['You want to insert at ' num2str(nn) ' in numbers 1-' ...
	    num2str(np) '? Report to my office!']);
   else
      if nn==1
	 jint = j1(1)-10;
	 disp(['Est time for new prof, and existing prof 1: ' ...
	       datestr(gregorian(jint)) ' - ' datestr(gregorian(j1(1)))]);
	 ss = input('Type B to accept this estimate, Q to abandon' ...
		    ' insertion, or N to prompt for new estimate : ','s');
      else	
	 disp(['Previous : ' datestr(gregorian(j1(nn-1)))]);
	 disp(['New, estA: ' datestr(gregorian(j1(nn-1)+10))]);
	 disp(['New, estB: ' datestr(gregorian(j1(nn)-10))]);
	 disp(['Next     : ' datestr(gregorian(j1(nn)))]);
	 ss = input('Type A or B to accept estimates, Q to abandon' ...
		    ' insertion, or N to prompt for new estimate : ','s');
      end
      if isempty(ss); ss = 'q'; end
      ss = lower(ss(1));
      if ss=='a'
	 jint = j1(nn-1)+10;
      elseif ss=='b'
	 jint = j1(nn)-10;
      elseif ss=='n'
	 disp('Give new date/time as vector including sq brackets,')
	 gg = input('eg [2006 11 29 23 55]  : ');
	 if length(gg)<5 || length(gg)>6
	    disp('You mucked that up! Aborting.')
	    return
	 else
	    if length(gg)==5
	       gg = [gg 0];
	    end
	    jint = julian(gg);
	    disp(['You have said: ' datestr(gregorian(jint))])
	 end
      else
	 disp('Ok - bailing out!')
	 return
      end
      nshft = (nn+1):np;
      float(nshft+1) = float(nshft);
      float(nn) = new_profile_struct(dbdat);
      float(nn).jday(1) = jint;
      float(nn).datetime_vec(1) = gregorian(jint);
      float(nn).lat(1) = nan;
      float(nn).lon(1) = nan;
      float(nn).position_accuracy(1) = '0';
            
      web_float_summary(float,dbdat,1);
      disp('   Refresh the now-modified float summary page')
      ss = input('Is that what you intended. Save that? [n] : ','s');
      if ~isempty(ss) && (ss=='y' || ss=='Y')
	 save(fnm,'float','-v6');
	 disp('Ok - done that');
      else
	 load(fnm,'float');
	 web_float_summary(float,dbdat,1);      
	 disp('Change discarded and summary page rebuilt.');
      end	 
   end   
   
else
   
   % SORT by jday(1)
   if any(isnan(j1))
      disp('At least one profile missing jday(1) - so cannot sort.')
      disp('Could remove that profile, or estimate and manually insert a value')
      disp('then try sorting again.')
      return
   else
      [sj,ij] = sort(j1);
      if all(diff(ij))==1
	 disp('The profiles were already in order!??');
      else
	 float = float(ij);
	 save(fnm,'float','-v6');
	 web_float_summary(float,dbdat,1);      
	 disp('Ok - done, and summary page rebuilt');
	 disp('Here is the changed N number, for altering Workfile names:')
	 for jj = 1:np
	    if ij(jj)~=jj
	       disp(['Old: ' num2str(jj) '   New: ' num2str(ij(jj))]);
	    end
	 end
      end	 
   end
else
   
   disp(['Do not understand command ' cmd]);
end

%-------------------------------------------------------------------
