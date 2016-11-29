%==========================================================
%GETS THE LAST TRANSMISSION DATE FROM THE PROFILE DATA:
%RETURNS STRING '06/01/2006'
%==========================================================
function Tlast = dbasequeryGetLastTransmittDate(dbase)
%begin
    %check for input data: (must have profile)
    Tlast = '';
    
    try
        n = length(dbase.float);
        T = dbase.float(n).datetime_vec;
        Tlast = datestr(T(1,1:6));
    catch
        Tlast = 'File Data Error';
    end
end
    
    
    