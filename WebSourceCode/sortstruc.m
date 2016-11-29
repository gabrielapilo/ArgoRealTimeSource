%=================================================================
% SORT A STRUCTURE ARRAY BY GIVEN FIELD NAME, FIELD NAME SPECIFIED
% MUST BE ALPHANUMERIC.
% ex:        Y = sortstruc(X, 'HullID')
%
%            where X:  1xN struct array with fields:
%                  HullID           - works
%                  ArgosID          - works
%                  WmoID            - works
%                  Status
%                  ParkVoltage
%                  Cycles
%                  LastTransmission
%                  LastTxDaysAgo
%                  DeepestPressure
%                  LaunchDate         - 
%                  DeployPlatform
%                  PositioningSystem
%                  Database
%
%Output Y: 
%       above  array of structures sorted according to HullID
% Note:
%       if the field name is a string, the first character of the
%       string is used to sort the array.
%
%       If the field name is a vector, it takes the last entry of
%       the vector.
%================================================================
function Y = sortstruc(X, fieldname)
%begin
    %check inputs:
    Y = [];
    if (isempty(X)) return; end;
    n = length(X);
    if (n<=1) Y=X; return; end;
    
    %check that field exists:
    if (~isfield(X(1), fieldname)) 
        fprintf('ERROR: Field name %s does not exist/ array not sorted \n', fieldname);
        Y = X; 
        return; 
    end;
     
    %determine if the field-type is numeric or characters, must be consistent:
    fieldtype = 'C';
    for j=1:n 
        z = getfield(X(j), fieldname);
        if (isnumeric(z)) fieldtype='N'; break; end;
    end
  
    %get field name value (numeric, datestrings, strings):
    for j=1:n 
        z = getfield(X(j), fieldname);
        
        %character string field, could also be date:
        if (fieldtype=='C')
            z = strtrim(z);
            if (length(strfind(z, '/'))==2) z=datenum(z, 'dd/mm/yyyy'); end;
            if (length(z)>1) z=lower(z(1)); end;
            if (isempty(z)) z=' '; end;
        end
        
        %deal with numeric values:
        if (fieldtype=='N')
            if (isempty(z))  z=NaN;        end;
            if (length(z)>1) z=lastval(z); end;
        end
   
        V(j) = z;
    end

    %sort list:
    [u,Index] = sort(V);
    Y         = X(Index);
%end





