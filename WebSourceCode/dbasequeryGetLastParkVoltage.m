%==========================================================
%GETS THE LAST TRANSMISSION DATE FROM THE PROFILE DATA:
%RETURNS STRING '06/01/2006'
%==========================================================
function Vlast = dbasequeryGetLastParkVoltage(dbase, format)
%begin
    %check for input data: (must have profile)
    Vlast = [];
    if (format=='s') Vlast=''; end;
    
    try
        n     = length(dbase.float);
        Vlast = dbase.float(n).parkbatteryvoltage;
        if (format=='s') Vlast=sprintf('%0.2f Volts', Vlast); end;
    catch
        Vlast = NaN;
        if (format=='s') Vlast='No Data'; end;
    end

end

