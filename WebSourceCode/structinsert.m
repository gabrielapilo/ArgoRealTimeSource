%======================================================================
%INSERT THE STRUCTURE 'a' INTO THE ARRAY OF STRUCTURES 'A' AT THE GIVEN
%INDEX POSITION 'index', THE FIRST IS 1, if A IS EMPTY THEN B=a
%if length(A)<index then the structure is simply appended to the end
%the output B is n+1 where n=length(A)
%
%all structures below index are moved down.
%
%ex:      index=2 
%         A    ={S(1)='first', S(2)='second', S(3)'third'} 
%         a    ='hello'
%
%returns: B(1)='first'  B(2)='hello'  B(3)='second'   B(4)='third'
%======================================================================
function B = structinsert(A, a, index)
%begin
    %return the input by default:
    B = A;
    if (isempty(a))      return; end;   %empty input 
    if (isempty(A)) B=a; return; end;   %empty input set
    if (index==0)        return; end;   %invalid index range
    if (isnan(index))    return; end;   %invalid index range
    
    %append by default if index > size of input array:
    n = length(A)
 disp(A)
 disp(B)
 disp(a)
 
    if (index>n)  B = [B,a]; return; end;  %append into end, outside 
    if (index==1) B = [a,B]; return; end;  %insert into beginning
    
    %insert into appropriate index point
    B = [A(1:index-1), a, A(index:n)];
    
    
    

%end