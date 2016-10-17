%  [pssal]=decodeSoloS(sbdm)
%
% take a raw sbd messge and extract pressure, returning it in a vector to
% be sorted later
%
% usage: decodeSoloP
% where sbdm is a binary attachment from a single file
% and pres is a set of pressure values from that file
%
% based on code by Vito Dirita
%  
% function [psal]=decodeSoloS(sbdm,psal)
% turn this into a script for greater efficiency : AT : Nov 2013

    %
    d1=1;  %                  = Indices(k);             %start index of profile
    id                  = sbl(d1);                  %id for sequencing
    if any(id==psalID);return;end
    m                   = 256*sbl(d1+1) + sbl(d1+2);  %message length
    bytes               = sbl(d1+3:d1+m-2);
    In=[];

        d1    = 1;                            %sub-block start index:
        d2    = 27;                           %sub-block end index d1+26=27 bytes==25 samples
        n     = length(bytes);                %how many bytes message
        kk    = 0;                            %sub-block counter (25 sample blocks)
        if (n<d2) d2=n; end;                  %could be less than 25 samples 
        

        while (d1<length(bytes))
            %grab 27-byte sub-block:
            sub = bytes(d1:d2);                %get the sub-block 27 bytes
            d1  = d1+27;                       %increment to the beginning of the next sub-block
            d2  = d2+27;                       %increment to the end of the next sub-block
            kk  = kk+1;                        %sub-block counter
            if (d2>n) d2=n; end;               %last sub-block may be less than 27 bytes
            sr(kk,1:length(sub))=sub;
            S  = sub(1);                       %scaling factor
            So = sub(2)*256 + sub(3);          %first absolute pressure
            Sdiff       = sub(4:end);                   %temperature byte differences only
            kneg        = find(Sdiff>=128);             %negative values
            Sdiff(kneg) = Sdiff(kneg)-256;              %negative values
            dS = [So, So+cumsum(Sdiff)*S];         %pressure difference
            Sn          = 0.001*dS - 1.000;             %to degC units
    In=[];            
            In(1:length(Sn))=id;   %need index of the  block numbers to match properly...
            psal = [psal, Sn];                 %combine into single column Salinity profile vector
            psalID = [psalID, In];
        end
