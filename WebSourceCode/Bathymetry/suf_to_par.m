% SUF_TO_PAR  Convert between EEZ_DATA file suffices and parameter
%    combination names. See also PAR_TO_SUF, LODRIVE, GET_ALL_CSL, SUF_CODES
%
% ** Now REDUNDANT -  see instead PAR_TO_IPAR, PAR_TO_CSRC, PAR_TO_DECL, LODRIVE
%
% Jeff Dunn  12/4/02

function [par,infodir] = suf_to_par(suf,ipar)

if any(suf==5 | suf==6 | suf==8)
   infodir = platform_path('cascade','dunn/eez/qc_data_xbt/');   
else
   infodir = platform_path('cascade','dunn/eez/qc_data/');   
end

if ipar==1
   if any(suf==6)
      if all(suf>=5 & suf<=6)
	 % suf = [5 6]
	 par = 'xx';
      elseif length(suf)==9
	 % suf = [1 2 3 4 5 6 7 8 9]
	 par = 'tx2';
      else
	 % suf = [1 2 3 4 5 6 7 9]
	 par = 'x2';
      end
   elseif any(suf==8)
      if length(suf)==1	 
	 % suf = 8
	 par = 'ta';
      else	 
	 % suf = [1 2 3 4 5 7 8 9]
	 par = 'tc';
      end
   elseif any(suf==5)
      if any(suf~=5)
	 % suf = [1 2 3 4 5 7 9];
	 par = 'tx';
      else
	 % suf = 5
	 par = 'x';
      end
   else
      % suf = [1 2 3 4 7 9]
      par = 't';
   end    
elseif ipar==2
   par = 's';
elseif ipar==3
   par = 'o2';
elseif ipar==4
   par = 'si';
elseif ipar==5
   par = 'po4';
elseif ipar==6
   par = 'no3';
else
   disp([7 'Do not understand ipar = ' num2str(ipar)]);
end

return

%---------------------------------------------------------------------------
