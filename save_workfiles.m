%  SAVE_WORKFILES  Save intermediate work files.
%
% INPUT: variables as named in PROCESS_PROFILE workspace
%
% CALLED BY: process_profile
%
% Author:  Jeff Dunn  CSIR/BoM  Nov 2006, Sep 2013
%
% USAGE: save_workfiles(rawdat,heads,b1tim,pmeta,savewk)

function save_workfiles(rawdat,heads,b1tim,pmeta,savewk)

% MODS: 17/9/2013 Rearrange so always test for presence of 'qc' field, and
%       now also test for 'juld' and 'crc', since these often previously
%       missing.
%       16/5/2014 Now where a pre-existing file, instead of testing for
%       matching contents in selected fields, always just replace the file
%       (unless it has been manually edited.  JRD

global ARGO_SYS_PARAM

if savewk==1
   % One file per float, overwritten with each new profile (ie temporary
   % work files.)
   if ispc
       wfnm = [ARGO_SYS_PARAM.root_dir 'workfiles\R' num2str(pmeta.wmo_id)];
   else
       wfnm = [ARGO_SYS_PARAM.root_dir 'workfiles/R' num2str(pmeta.wmo_id)];
   end
   save(wfnm,'rawdat','heads','b1tim','pmeta','-v6');

elseif savewk==2
   % A new file per profile, viewed as permanent work files.
   if ispc
   wdir = [ARGO_SYS_PARAM.root_dir 'workfiles\' num2str(pmeta.wmo_id) '\'];
   else
   wdir = [ARGO_SYS_PARAM.root_dir 'workfiles/' num2str(pmeta.wmo_id) '/'];
   end
   if ~exist(wdir,'dir')
      system(['mkdir ' wdir]);
   end	 
   wfnm = ['N' num2str(pmeta.np) '_P' num2str(pmeta.pnum)]; 
   if exist([wdir wfnm '.mat'],'file')
      % We have an old workfile of this name, so either this is stage 2, 
      % OR we are reprocessing,  OR there is somehow a repeat of both 
      % profile numbers??  No harm in clobbering the old file if it has 
      % not been edited.
       
      old = load([wdir wfnm]);

      if isfield(old.rawdat,'qc')
	 % This file has had editing, so we don't want to clobber it!
	 logerr(3,[wfnm ' exists, has been edited, and contains ' ...
		   'different data, so saving instead to ' wfnm '_A']);
	 wfnm = [wfnm '_A'];
      else
	 % Now always just replace
	 %
	 % PREVIOUSLY:
	 % A quick but fallible test for different data in new and old versions
	 %  different = length(old.rawdat.blkno)~=length(rawdat.blkno) || ...
	 %      any(old.rawdat.blkno~=rawdat.blkno) || ~isfield(rawdat,'juld') ...
	 %     || ~isfield(rawdat,'crc') 
	 %  if different
	 %     logerr(4,['Data in ' wfnm ' has changed (since stage 1?)']);
	 %  else
	 %     % No new data, so no reason to save file!
	 %     wfnm = [];
	 %  end
      end
   end
   
   if ~isempty(wfnm)
      save([wdir wfnm],'rawdat','heads','b1tim','pmeta');
   end
end


%----------------------------------------------------------------------
