%=================================================================================
%SBD - ARVOR-I FLOAT PARAMETER PACKET (Type=6)
% --------------------------------------------------------------------------------
% Packet type Code: 0x02
% This message contains float's Submerged TS information
%
% Reference:
%         pp. 27,28: "Arvor-i flaot user manual, NKE instrumentation"
% Author: Udaya Bhaskar, INCOIS 02, June 2017
%==================================================================================
pres = [];
temp = [];
psal = [];
In = [];
% To open a file and append the data corresponding to the CTD profile
cyc_num = num2str(IDs(2)*256 + IDs(3));
if(length(cyc_num) == 1) 
   cyc_num = ['00' cyc_num];
elseif(length(cyc_num) == 2)
   cyc_num = ['0' cyc_num];
%else cyc_num = cyc_num;
end
fnam = ['/home/argo/ARGO_RT/Nke_data/processed/' num2str(wmoid) '/ctd/Subctd' cyc_num '.txt'];
fid = fopen(fnam,'a');
ctd_hr = IDs(4)*256 + IDs(5);
ctd_min = IDs(6);
ctd_sec = IDs(7);
i = 1;
for j=8:6:97
% coded in two's complement and hence need to be checked for priority bit
   p = [dec2hex(IDs(j),2) dec2hex(IDs(j+1),2)];
   intp = dec2bin(hex2dec(p),16);
   if str2num(intp(1)) == 1 
     ptmp(i) = ((hex2dec(p) - 2^16) + 10000.0)/10.0;
   else
     ptmp(i) = (hex2dec(p) + 10000.0)/10.0; 
   end
   %pres
% coded in two's complement and hence need to be checked for priority bit
   t = [dec2hex(IDs(j+2),2) dec2hex(IDs(j+3),2)];
   intt = dec2bin(hex2dec(t),16);
   if str2num(intt(1)) == 1
     ttmp(i) = (hex2dec(t) - 2^16)/1000.0;
   else
     ttmp(i) = hex2dec(t)/1000.0; 
   end
   %temp
   s = [dec2hex(IDs(j+4),2) dec2hex(IDs(j+5),2)];
   psaltmp(i) = hex2dec(s)/1000.0;
   %psal
 i = i +1;
end
% Now to check for P=1000,T=0 and S=0 and eliminate them
jlp = 1;
for i=1:length(ptmp)
    if ptmp(i) == 1000.000 && ttmp(i) == 0.0 && psaltmp(i) == 0.0
    else
       pres(jlp) = ptmp(i);
       temp(jlp) = ttmp(i);
       psal(jlp) = psaltmp(i);
    end
    jlp = jlp + 1;
end
% for printing the decoded values in file
for i=1:1:length(pres)
   fmt ='%7.2f %9.3f %9.3f\n';
   fprintf(fid,fmt,pres(i),temp(i),psal(i));
end
fclose(fid); 
In(1:length(pres))=jjj;
drfpres = [pres;In];
drftemp = [temp;In];
drfpsal = [psal;In];
