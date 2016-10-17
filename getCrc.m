function crc = getCRC(message)
% ----------------- Description -----------------------
% Function used to find the CRC value for a given
% message using the 16 bit CRC-CCITT standard polynomial.
% The Modulo-2 Binary Division is implemented and the
% remainder of the division will be the CRC. This 
% implementation is rather slow and can be speeded up
% using the well known technique of generating first a
% look-table. (Will do when I get the time!).
%
% Generator polynomial used:  CRC-CCITT 16 bit
%
% X^16 + X^12 + X^5 + 1
%
% Polynomial is truncated. The MSB 1 is removed
% as we have the information in the uppermost bit
% and we don't need it for the XOR, thus polynomial
% can be stored in a 16 bit register.
%
%
% INPUT : hexadecimal message (64 character array)
%
% OUTPUT: CRC hexadecimal value 
 
% Author : Quyen To Luong, QTL@wpo.nerc.ac.uk
% Date   : 15/09/2002
% Version: 1.0
%
% Copyright (C) BODC, Quyen Luong 2002.
% ------------------------------------------------------

%
% The generator polynomial (hexadecimal value)
%
genPoly = '1021'; 
%
% The mask hexadecimal value to test whether
% the uppermost bit is a 1
%
topbit = '8000';
%
% Width of register 16 bit
%
WIDTH = 16;
%
% There is a standard message to test whether the
% implementation is working. The message is ascii
% "123456789" and remainder(register) should have
% hex value 0x29B1. The initial remainder is 0xFFFF
%
isTest = length(message);

if ~isTest
    message = '123456789';
    nBytes = 9;
    register = 'FFFF';
else
    % Number expected bytes in martec float message
    nBytes = 32;
    %
    % The initial value of the register. Note the standard
    % intial register(remainder) is actually 0xFFFF. But
    % martec CRC encoding sets initial register to 0?
    %
    register = '0000';
end
%
%  Perform  modulo-2 division, a byte at a time
%
posn_start = 1;
for n = 1:nBytes
   %
   % Bring the next message byte into the register   
   %   
   if ~isTest
      % Convert the ascii code 
      byte = dec2hex(num2str(message(n)));      
   else
      % Two characters make a byte! 
      posn_end = posn_start+1;
      byte = num2str(message(posn_start:posn_end));   
      posn_start = posn_end + 1; 
   end
    
   register = dec2hex(...
        bitxor(...
        hex2dec(register),...
        bitshift(...
        hex2dec(byte),(WIDTH - 8))));                
   %
   % For each bit position in message....Perform modulo-2
   % division
   %
   for bit = 8:-1:1   
   %
   % If the uppermost bit is a 1...Then try to divide
   % the current bit.
   %                
   if bitand(hex2dec(register),hex2dec(topbit));              
      %
      % XOR the previous register with the divisor
      %          
     if isTest
        reg_shift_L1 = dec2hex(bitshift(hex2dec(register),1));
        
        % Remove the unwanted top 4 bits
        if length(reg_shift_L1) > 4
            reg_shift_L1 = reg_shift_L1(2:end);
        end
                   
        register = ...
            dec2hex(...
            bitxor(...
            hex2dec(reg_shift_L1),...
            hex2dec(genPoly)));
     else
        register = ...
            dec2hex(...
            bitxor(...
            bitshift(...
            hex2dec(register),1),...
            hex2dec(genPoly)));     
     end     
      
   else % Shift the register left 1 bit
      register = ...
         dec2hex(...
         bitshift(...
         hex2dec(register),1));                                      
   end   
   %
   % Remove the top byte. Matlab seems to make the 
   % register grow!!!! 
   %
   if length(register) > 4
      register = register(2:end);
   end         
end

end
%
% If the length of register is 3 hex characters then
% add hex value 0 to make up the 16 bits
%
if length(register) == 3
    register = strcat('0',register);
end
%
% The final register is the CRC result
%
crc = register;



