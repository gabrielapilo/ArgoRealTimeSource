% CRCcheck - Carry out Cyclic Redundancy Check on a single message
%
% INPUT  In   - a vector of number, the first being the CRC value 
%               computed (according to make-dependant algorithms) for all
%               the rest.
%        dbdat  float database struct including maker and subtype
%
% OUTPUT ok     0=failed CRC check    1=CRC is correct  
%
% Author: Jeff Dunn  CMAR/BoM  July 2006  Compiled from various sources.
%
% USAGE: ok = CRCcheck(In,dbdat);

function ok = CRCcheck(In,dbdat)

if dbdat.maker==1
   % Webb - APEX floats
   
   nin = length(In);
   if nin~=31 & nin~=32
      logerr(2,['CRCcheck: Expect 31 or 32 values, got ' num2str(nin)]);
      ok = 0;
      return;
   end;
             
   ByteN = In(2);   
   for ii=3:nin
      ByteN = Hasard(ByteN);
      ByteN = bitxor(ByteN,In(ii));
   end
       
   ok = Hasard(ByteN)==In(1);

elseif dbdat.maker==2 & dbdat.subtype~=4
   % Martec-PROVOR floats
   % This doesn't seem exactly as documented, but works as below. Use Quyen's
   % "getCRC", which requires a 64 char string, with '0' in first 4 chars. 
   % It is impressively slow!
   
   cc = dec2hex(In,2)';
   cc = cc(:)';
   if length(cc)==62
      cc = [cc '00'];
   end
   crc = getCrc(['0000' cc(5:64)]);
   if length(crc) > 2
      crc = crc(3:4);    % Can it be other than 2 or 4 ??
   end
   
   ok = strcmp(cc(1:2),crc); 
elseif dbdat.maker==2 & dbdat.subtype==4
   % NKE Indian PROVOR floats - provor CTS-3
   % This doesn't seem exactly as documented, but works as below. Use Quyen's
   % "getCRC", which requires a 64 char string, with '0' in first 4 chars. 
   % It is impressively slow!
   
   In(isnan(In))=[];
   nin = length(In);
 
   cc = dec2hex(In(1:nin),2)';
   cc = cc(:)';
   if length(cc)==62
      cc = [cc '00'];
   end
   crc = getCrc([cc(1) '0000' cc(6:64)]);
%    if length(crc) > 2
%       crc = crc(3:4);    % Can it be other than 2 or 4 ??
%    end
   
   ok = strcmp(cc(2:5),crc); 
end

%-------------------------------------------------------------------------
function b2 = Hasard(b1)

x  = 0;
b2 = b1;
    
if (b1==0)
   b2=127;      
   return
end
if (bitand(b1,1) == 1);  x = x+1; end
if (bitand(b1,4) == 4);  x = x+1; end
if (bitand(b1,8) == 8);  x = x+1; end
if (bitand(b1,16)==16);  x = x+1; end

if (bitand(x,1)==1) 
   b2 = floor(b1/2) + 128;
else
   b2 = floor(b1/2);
end

% might be faster coded as...
%if (b1==0)
%   b2=127;
%else 
%   x = sum(bitget(b1,[1 3 4 5]);  
%   if (bitand(x,1)==1) 
%      b2 = floor(b1/2) + 128;
%   else
%      b2 = floor(b1/2);
%   end;   
%end


%-------------------------------------------------------------------------















