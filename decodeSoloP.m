%  [pres]=decodeSoloP(sbdm)
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
% function [pres]=decodeSoloP(sbdm,pres)
% turn this into a script for greater efficiency : AT : Nov 2013

    %
%     d1                  = Indices(k);             %start index of profile
    d1=1;  %change to the way this is done - works for preliminary messages but need to test for the rest of the data...
    id                  = sbl(d1);                  %id for sequencing
    if any(id==presID);return;end
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
            pr(kk,1:length(sub))=sub;
            S  = sub(1);                       %scaling factor
            Po = sub(2)*256 + sub(3);          %first absolute pressure
            b  = sub(4:end);                   %pressure byte differences only
            dP = [Po, Po+cumsum(b)*S];         %pressure difference
            Pn = 0.04*dP - 10.0;               %to dbar units
    In=[];
            In(1:length(Pn)) = id;
            pres = [pres, Pn];                 %combine into single column pressure profile vector
            presID = [presID, In]; 
        end
