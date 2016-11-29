% DSET_VARS  Look up which vars are present in a given dataset.
%
% INPUT   dset   Single dataset code. 
%         fset   Single fileset code (1=obs level, 2=CSL level, 3=header)
%                [default 2]
%         var    [optional] list of required vars,  
%         hvar   [optional] list of required header vars,  
%
% OUTPUT  vars   Vars in dset (OR IF 3rd ARG ABOVE, then index in "var" of
%                those actually in the dset)
%         hvars  Header vars in dset (OR IF 4th ARG ABOVE, then index in "hvar"
%                of those actually in the dset)
%
% If no output arguments, vars are listed to the screen.
%
% [vars,hvars] = dset_vars(dset,fset,var,hvar);

function [vars,hvars] = dset_vars(dset,fset,var,hvar)

if nargin<2 | isempty(fset)
   fset=2;
end

% Header variable names: 
%  1-stn  2-time  3-V_castflag  4-botdep  5-co  6-cru  
%   11-Vbot(:,1) [depth]  12=Vbot(:,2) [value]  
%  (where V is property name; eg t_castflag or o2bot ... )

dshvlst{7} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9],[]};
dshvlst{8} = {[],[1 2 4 9],[]};
dshvlst{9} = {[1 2 3 5 6 9],[1 2 4 5 6 9 11 12],[]};
dshvlst{10} = {[1 2 3 4 6 9],[1 2 4 6 9 11 12],[]};
dshvlst{11} = {[],[1 2 4 9],[]};
dshvlst{12} = {[1 2 3 4 6 9],[1 2 4 6 9],[]};
dshvlst{13} = {[1 2 3 4 5 6 9],[1 2 3 4 5 6 9],[]};
dshvlst{14} = {[1 2 4 9],[1 2 4 9],[]};
dshvlst{17} = {[],[1 2 4 9],[]};
dshvlst{18} = {[],[1 2 4 9],[]};
dshvlst{19} = {[1 2 3 4 6 9],[1 2 4 6 9 11 12],[1 2 6 9]};
dshvlst{20} = {[1 2 4 9],[1 2 4 9],[]};
dshvlst{21} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{22} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{23} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{24} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{25} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{26} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{27} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{28} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9 11 12],[1 2 4 5 6 9]};
dshvlst{29} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9],[1 2 4 5 6 9]};
dshvlst{31} = {[1 2 3 4 5 9],[1 2 4 5 9],[]};
dshvlst{35} = {[1 2 3 4 6 9],[1 2 4 6 9 11 12],[]};
dshvlst{70} = {[1 2 4 6 9],[],[]};
dshvlst{71} = {[1 2 3 4 6 9],[1 2 4 6 9],[]};
dshvlst{72} = {[1 2 3 4 5 6 9],[1 2 4 5 6 9],[]};
dshvlst{121} = {[],[1 2 4 6 9],[]};
dshvlst{200} = {[]};

vnm = {'t','s','o2','si','po4','no3','nutdens','','','','','','','no4','nh3'};

dsdvlst{7} = {[1 2 7],[1 2 3 4 5 6 7 14 15],[]};
dsdvlst{8} = {[],1,[]};
dsdvlst{9} = {[1 2 3 7],[1 2 3 7],[]};
dsdvlst{10} = {[1 2 7],[1 2 7],[]};
dsdvlst{11} = {[],[1 2 7],[]};
dsdvlst{12} = {[1 2],[1 2 7],[]};
dsdvlst{13} = {[1 2 3 4 5 6 7],[1 2 3 4 5 6 7],[]};
dsdvlst{14} = {1,1,[]};
dsdvlst{17} = {1,1,[]};
dsdvlst{18} = {1,1,[]};
%dsdvlst{19} = {[1 2 3 4 5 6 14],[1 2 3 4 5 6 7 14],[]};  
%  WOCE files do contain hydro data, but get_all_obs not yet coded to access it
dsdvlst{19} = {[1 2 3],[1 2 3 4 5 6 7 14],[]};
dsdvlst{20} = {1,1,[]};
dsdvlst{21} = {[1 2 3],[1 2 3 7],[]};
dsdvlst{22} = {[1 2 3 4 5 6],[1 2 3 4 5 6 7],[]};
dsdvlst{23} = {[1 2],[1 2 7],[]};
dsdvlst{24} = {[1 2],[1 2 7],[]};
dsdvlst{25} = {[1 2],[1 2 7],[]};
dsdvlst{26} = {[1 2],[1 2 7],[]};
dsdvlst{27} = {[1 2],[1 2 7],[]};
dsdvlst{28} = {1,1,[]};
dsdvlst{29} = {[1 2],[1 2],[]};
dsdvlst{31} = {[1 2 3 4 5 6],[1 2 3 4 5 6 7],[]};
dsdvlst{35} = {[1 2],[1 2 7],[]};
dsdvlst{70} = {[1 2 3 7],[],[]};
dsdvlst{71} = {[1 2 6],[1 2 6 7],[]};
dsdvlst{72} = {[1 2 3 4 5 6 7 14 15],[1 2 3 4 5 6 7 14 15],[]};
dsdvlst{121} = {[],[1 2 7],[]};
dsdvlst{200} = {[],[],[]};

vars = dsdvlst{dset}{fset};
hvars = dshvlst{dset}{fset};
   
if nargout==0
   disp(['Vars for dset ' num2str(dset) ': ' num2str(vars)]);
   disp(['Header vars : ' num2str(hvars)]);
end

if nargin>=3 & ~isempty(var)
   vars = find(ismember(var,vars));
end
if nargin>=4 & ~isempty(hvar)
   hvars = find(ismember(hvar,hvars));
end

%-------------------------------------------------------------------------
