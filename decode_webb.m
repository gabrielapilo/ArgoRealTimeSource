% DECODE_WEBB  reads block data from Webb R1/Apex palace Argos transmissions 
% and converts to real units.
%
% INPUT  prof - decimal profile (in blocks and lines) from STRIP_ARGOS_MSG
%        dbdat- details for this float from the float master database
%
% OUTPUT fp   - structure containing profile and tech data (empty if a fatal
%               error has occurred.)
%
% Also in THIS FILE: functions  H2B  CALC_TEMP  CALC_SAL  CALC_VOLT
%
% USAGE: fp = decode_webb(prof,dbdat);

function fp = decode_webb(prof,dbdat,lat,processor)

% Create a generic blank profile struct
pro = new_profile_struct(dbdat);

fp = [];

% From dbdat we obtain:
% np0 - correction to float number due to "profiles" counted after
%       deployment but while still in the cardboard box
% subtype - Webb format number
% oxy     - does it have oxygen?
% ice     - does it have ice detection?
% tmiss   - does it have transmissiometer?

% subtypes are presently: 
%  pre-Apex   = 0
%  Apex1      = 1
%  Apex early Korea = 2
%  Apex Indian = 4
%  Apex Korea = 10
%  Apex2      = 11
%  Apex2ice Korea = 20
%  Apex2 SBE DO Korea = 22
%  Apex2ice   = 28   
%  Apex2oxyice= 31   
%  Apex2oxy   = 32   
%  Apex2oxyTmiss = 35
%  Apex2SBEoxy Indian = 38
%  ApexOptode Korea = 40
%  Apex2var Park T,P = 43
%  Apex2var Park T,P + ice detection = 44
%  ApexAPF9a   = 1001
%  ApexAPF9aOptode = 1002
%  ApexAPF9aIce = 1003
%  ApexIridium = 1004 - with and without ice (decode_iridium)
%  ApexSurfaceT Indian = 1005
%  ApexIridiumO2 = 1006  (decode_iridium) with and without flbb sensor
%  ApexIridiumSBEOxy = 1007  (decode_iridium)
%  ApexIridiumSBEOxy = 1008 - with flbb
%  ApexAPF9Indian = 1010
%  ApexAPF9 with an extra point = 1011
%  ApexAPF9 format (oxygen, 1002) with extra point = 1012
%  ApexAPF9 with engineering data at end of data = 1014
%  Solo Polynya floats = 1015
%  Seabird Navis Vanilla float = 1016
%  Seabird Navis Optical Oxygen = 1017
%  MRV Solo II Vanilla = 1018
%  Webb APF11 = 1019
%  Webb APF9 oxy FLBB = 1020
%  Webb APF9G Indian float = 1021 
%

typ = dbdat.subtype;

% Message length - check that it is right for this format (but maybe not
% much value in doing this. Also, could store this info in database)
% NOTE: use typ+1 because there is a typ=0, and cannot use 0 as an index.
% Indian floats use format '4' which is 32 bits long : added AT 07/2008

types =           [0  1  2  4  10 11 20 22 28 31 32 35 38 40 43 44 1001 1002 1003 1005 1010 1011 1012 1014 1021];
msglen(types+1) = [32 32 32 32 31 31 31 32 31 31 31 31 31 32 31 31   31   31   31   31   31   31   31   31  31];

if ~any(types==typ) || isnan(msglen(typ+1))
   disp(['DECODE_WEBB: New Message length info: ' num2str(size(prof,2)) ...
	 ', type ' num2str(typ)]);
   msglen(typ+1) = size(prof,2);
elseif size(prof,2) ~= msglen(typ+1)
   str = sprintf('Message length %d (expected %d) for float type %d\n', ...
		 size(prof,2),msglen(typ+1),typ);
   logerr(1,str);  
   return
end   

% All the info is in elements 3 to last of each message line, which we load 
% into 'dat'.
%   'd0' is used to track how far through 'dat' we have read. Initially set
% it to the end of first message, so next byte is 1st of the second message
% line.
%   We get the header stuff from variable 'p1' (which includes bytes 1&2) 
% because the numbers used to locate each variable then match the format 
% documents. 

dat = prof(:,3:end)';
dat = dat(:)';
d0 = msglen(typ+1) - 2;
p1 = prof(1,:);

if(length(dat)==58 & dbdat.boardtype==9)  %this is probably a test message with bad crcs that passed tests
                       % - only 2 blocks are not enough for a profile
                       % anyway so return...
   logerr(1,'Looks like test block - not enough data for profile');
   return
end
if(length(dat)<=87 & dbdat.boardtype==9 & dbdat.oxy)  %this is probably a test message with bad crcs that passed tests
                       % - only 2 blocks are not enough for a profile
                       % anyway so return...
   logerr(1,'Looks like test block - not enough data for profile');
   return
end
if(length(dat)<35)  %not enough data to do anything...
    logerr(1,'Very short message - abort decode');
    return
end

if p1(2)~=1
   logerr(1,'First block num not 1');
   return
end


pro.wmo_id = dbdat.wmo_id;

pro.SN = h2b(p1(4:5),1);
pro.profile_number = p1(6)-dbdat.np0;    %DEV Formerly np

% if this is the first profile for a float, add it to the web-tables

if(pro.profile_number==1);
    web_select_float;
    if ~isempty(strmatch('CSIRO',processor))
        web_select_float_tech;
        make_tech_webpage(pro.wmo_id); %makes first instance of the technical pages
    end
end

pro.npoints = p1(7);       %DEV Formerly lp
                      %DEV In Ann's 'loadfloat', lp is corrected by +1 
                      %    in Webb type 0 and 1 floats. If needed, I'd
    	              %    prefer to do this here!
                  
if(typ>1000)  % note - format 1014 is different and some values will be overwritten later
    pro.sfc_termination = [dec2hex(p1(8)) dec2hex(p1(9))];
else
    pro.sfc_termination = dec2hex(p1(8));
end
if typ>0 && typ<1000
    % These apply to all except the early R1-SBE floats
    pro.pistonpos = p1(9);
    pro.formatnumber = p1(10);
    pro.depthtable = p1(11);
    pro.pumpmotortime = h2b(p1(12:13),2);
    pro.voltage =  calc_volt(p1(14));
    pro.batterycurrent = p1(15) * 13;
elseif typ>1000
    pro.pistonpos = p1(14);
    %   pro.formatnumber = p1(10);
    if typ==1005
        pro.depthtable = 69;
    elseif typ==1021
        pro.depthtable = 67;
    else
        pro.depthtable = 26;
    end
    pro.pumpmotortime = h2b(p1(19:20),1);
    if typ>1001  % | typ==1011
        pro.voltage =  calc_volt9a(p1(25));
    else
        pro.voltage = calc_volt9(p1(25));
    end
    pro.batterycurrent = (p1(26) * 4.052) - 3.606;
end

switch typ
  
  case 0
    % R1-SBE
    pro.bottom_t =     calc_temp(p1(9:10));
    pro.bottom_s =     calc_sal(p1(11:12),typ);
    pro.bottom_p =     h2b(p1(13:14),0.1);
    pro.voltage =      p1(15)*.1 + .6;     % Not the normal voltage offset
    pro.surfpres =     h2b(p1(16:17),0.1) - 5;    
    pro.p_internal =   (-.376 * p1(18)) + 29.15;
    d0 = 18-2;
    
  case 1
    % Apex
    pro.airpumpcurrent =   p1(16) * 13;
    pro.surfacepistonpos = p1(18);
    pro.airbladderpres =   p1(19);
    pro.park_t =        calc_temp(p1(20:21));
    pro.park_s =        calc_sal(p1(22:23),typ);
    pro.park_p =        h2b(p1(24:25),0.1);
    pro.bottombatteryvolt = calc_volt(p1(26));
    pro.surfacebatteryvolt = calc_volt(p1(27));
    pro.surfpres =      h2b(p1(28:29),0.1) - 5;    
    pro.p_internal =   (-.209 * p1(30)) + 26.23;
    pro.bottompistonpos =    p1(31);
    pro.SBEpumpcurrent = p1(32) * 13;
    
  case 2
    %  Apex early Korea
    pro.airpumpcurrent =   p1(16) * 13;
    pro.surfacepistonpos = p1(18);
    pro.airbladderpres =   p1(19); 
    pro.t_8hr =  calc_temp(p1(20:21));
    pro.s_8hr = calc_sal(p1(22:23),typ);
    pro.p_8hr = h2b(p1(24:25),0.1);
    pro.t_48hr =  calc_temp(p1(26:27));
    pro.s_48hr = calc_sal(p1(28:29),typ);
    pro.p_48hr = h2b(p1(30:31),0.1)
    % here it becomes relative:
    d0=31-2;
    
    pro.t_88hr = calc_temp(dat(d0+[1 2]));
    pro.s_88hr = calc_sal(dat(d0+[3 4]),typ);
    pro.p_88hr = h2b(dat(d0+[5 6]),0.1);
    pro.t_128hr = calc_temp(dat(d0+[7 8]));
    pro.s_128hr = calc_sal(dat(d0+[9 10]),typ);
    pro.p_128hr = h2b(dat(d0+[11 12]),0.1);
    pro.t_168hr = calc_temp(dat(d0+[13 14]));
    pro.s_168hr = calc_sal(dat(d0+[15 16]),typ);
    pro.p_168hr = h2b(dat(d0+[17 18]),0.1);
    pro.t_208hr = calc_temp(dat(d0+[19 20]));
    pro.s_208hr = calc_sal(dat(d0+[21 22]),typ);
    pro.p_208hr = h2b(dat(d0+[23 24]),0.1);
    pro.park_t  = calc_temp(dat(d0+[25 26]));
    pro.park_s  = calc_sal(dat(d0+[27 28]),typ);
    pro.park_p  = h2b(dat(d0+[29 30]),0.1);
    
    d0=d0+30;
	pro.bottombatteryvolt =  calc_volt(dat(d0+1));
	pro.surfacebatteryvolt = calc_volt(dat(d0+2)); 
    pro.surfpres =      h2b(dat(d0+[3 4]),0.1) - 5;    
    pro.p_internal =   (-.209 * dat(d0+5)) + 26.23;
	pro.bottompistonpos = dat(d0+6);
    pro.SBEpumpcurrent = dat(d0+7) * 13;
    d0=d0+7;
    
  case 4
    % Apex India
    pro.airpumpcurrent =    p1(16) * 13;
    pro.profilepistonpos = p1(17);
    pro.surfacepistonpos = p1(18);
    pro.airbladderpres =   p1(19);
    pro.park_t =        calc_temp(p1(20:21));
    pro.park_s =        calc_sal(p1(22:23),typ);
    pro.park_p =        h2b(p1(24:25),0.1);
    pro.parkbatteryvoltage = calc_volt(p1(26));
    pro.surfacebatteryvolt = calc_volt(p1(27));
    pro.surfpres =      h2b(p1(28:29),0.1) - 5;    
    pro.p_internal =   (-.209 * p1(30)) + 26.23;
    pro.parkpistonpos =    p1(31);
    pro.SBEpumpcurrent = p1(32) * 13;
    
  case 10 
    % Apex Korea
    pro.surfacepistonpos = p1(16);
    pro.airbladderpres =   p1(17);
    
    d0 = 17-2;
        % first, the 8 hour samples after descent:
       pro.t_8hr = calc_temp(dat(d0+[1 2]));
       pro.s_8hr = calc_sal(dat(d0+[3 4]),typ);
       pro.p_8hr = h2b(dat(d0+[5 6]),0.1);
       d0 = d0+6;    
       jj=0;
       tmp = dat(d0+[1 2]);
       while tmp(2)~=221;
           jj = jj+1;
           pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
           pro.s_park_av(jj) = calc_sal(dat(d0+[3 4]),typ);
           pro.p_park_av(jj) = h2b(dat(d0+[5 6]),0.1);
           d0 = d0+6;
           tmp = dat(d0+[1 2]);
       end
%         if tmp(2)~=221
%            logerr(2,'DECODE_WEBB: Did not get expected DD(221) after T,P avs');
%        end
       pro.park_t =        calc_temp(dat(d0+[3 4]));
       pro.park_s =        calc_sal(dat(d0+[5 6]),typ);
       pro.park_p =        h2b(dat(d0+[7 8]),0.1);
%        pro.parkO2 =        h2b(dat(d0+[9 10]),0.01);
       pro.bottombatteryvolt =   calc_volt(dat(d0+9));
       pro.bottombatterycurrent =   dat(d0+10) * 13;
       pro.surfpres =      h2b(dat(d0+[11 12]),0.1) - 5;
       pro.p_internal =    (-.209 * dat(d0+13)) + 26.23;
       pro.bottompistonpos =   dat(d0+14);
       pro.SBEpumpvoltage = calc_volt(dat(d0+15));
       pro.SBEpumpcurrent = dat(d0+16) * 13;
       d0 = d0+16;

      
  case 11
    % Apex2
    pro.profilepistonpos = p1(16);
    pro.airbladderpres =   p1(17);
    pro.park_t =        calc_temp(p1(18:19));
    pro.park_s =        calc_sal(p1(20:21),typ);
    pro.park_p =        h2b(p1(22:23),0.1);
    pro.parkbatteryvoltage =   calc_volt(p1(24));
    pro.parkbatterycurrent =   p1(25) * 13;
    pro.surfpres =      h2b(p1(26:27),0.1) - 5;    
    pro.p_internal =   (-.209 * p1(28)) + 26.23;
    pro.parkpistonpos =   p1(29);
    pro.SBEpumpvoltage = calc_volt(p1(30));
    pro.SBEpumpcurrent = p1(31) * 13;
    
  case 20
    % Apex2ice Korea
    pro.profilepistonpos = p1(16);
    pro.icedetection =  p1(17);
    pro.airbladderpres =   p1(18);
    %as per format 43 and 44 from here:    
    pro.n_parksamps =  p1(19)-1;
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
    d0 = 19-2;
        % first, the 8 hour samples after descent:
       pro.t_8hr = calc_temp(dat(d0+[1 2]));
       pro.s_8hr = calc_sal(dat(d0+[3 4]),typ);
       pro.p_8hr = h2b(dat(d0+[5 6]),0.1);
       d0 = d0+6;    
    
       for jj = 1:pro.n_parksamps
           pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
           pro.s_park_av(jj) = calc_sal(dat(d0+[3 4]),typ);
           pro.p_park_av(jj) = h2b(dat(d0+[5 6]),0.1);
           d0 = d0+6;
       end
       tmp = dat(d0+[1 2]);
       if tmp(2)~=221
           logerr(2,'DECODE_WEBB: Did not get expected DD(221) after T,P avs');
       end
       pro.park_t =        calc_temp(dat(d0+[3 4]));
       pro.park_s =        calc_sal(dat(d0+[5 6]),typ);
       pro.park_p =        h2b(dat(d0+[7 8]),0.1);
%        pro.parkO2 =        h2b(dat(d0+[9 10]),0.01);
       pro.bottombatteryvolt =   calc_volt(dat(d0+9));
       pro.surfpres =      h2b(dat(d0+[10 11]),0.1) - 5;
       pro.p_internal =    (-.209 * dat(d0+12)) + 26.23;
       pro.bottompistonpos =   dat(d0+13);
%        pro.SBEpumpvoltage = calc_volt(dat(d0+14));
       pro.SBEpumpcurrent = dat(d0+14) * 13;
       d0 = d0+14;
       
   case 22
       pro.airpumpcurrent =    p1(16) * 13;
       pro.surfacepistonpos = p1(17);
       pro.airbladderpres =   p1(18);
       pro.n_parksamps =  p1(19)-1;
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
    d0 = 19-2;
    
    % first, the 8 hour samples after descent:
       pro.t_8hr = calc_temp(dat(d0+[1 2]));
       pro.s_8hr = calc_sal(dat(d0+[3 4]),typ);
       pro.p_8hr = h2b(dat(d0+[5 6]),0.1);
       pro.SBEoxyfreq_8hr = h2b(dat(d0+[7 8]),1);
       pro.oxy_8hr = convertFREQoxygen(pro.t_8hr,pro.s_8hr,...
            pro.p_8hr,pro.SBEoxyfreq_8hr,dbdat.wmo_id);
       d0 = d0+8;    
    
    for jj = 1:pro.n_parksamps
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.s_park_av(jj) = calc_sal(dat(d0+[3 4]),typ);
       pro.p_park_av(jj) = h2b(dat(d0+[5 6]),0.1);
       pro.SBEoxyfreq_park_av(jj) = h2b(dat(d0+[7 8]),1);
       pro.oxy_park_av(jj) = convertFREQoxygen(pro.t_park_av(jj),pro.s_park_av(jj),...
           pro.p_park_av(jj),pro.SBEoxyfreq_park_av(jj),dbdat.wmo_id);
       d0 = d0+8;
    end
    tmp = dat(d0+[1 2]);
    if tmp(2)~=221
       logerr(2,'DECODE_WEBB: Did not get expected DD(221) after T,P avs');
    end
    pro.park_t =        calc_temp(dat(d0+[3 4]));
    pro.park_s =        calc_sal(dat(d0+[5 6]),typ);
    pro.park_p =        h2b(dat(d0+[7 8]),0.1);
    pro.park_SBEOxyfreq =        h2b(dat(d0+[9 10]),1); 
    pro.parkO2 = convertFREQoxygen(pro.park_t,pro.park_s,...
        pro.park_p,pro.park_SBEOxyfreq,dbdat.wmo_id);
    pro.parkbatteryvoltage =   calc_volt(dat(d0+11));
    pro.surfpres =      h2b(dat(d0+[12 13]),0.1) - 5;
    pro.p_internal =    (-.209 * dat(d0+14)) + 26.23;
    pro.parkpistonpos =   dat(d0+15);
    pro.SBEpumpvoltage = calc_volt(dat(d0+16));
    pro.SBEpumpcurrent = dat(d0+17) * 13;
    pro.parkbatterycurrent = dat(d0+18) * 13;
    d0 = d0+18;

  case 28
    % Apex2 ice
    pro.profilepistonpos = p1(16);
    pro.icedetection =  p1(17);
    pro.airbladderpres =   p1(18);
    pro.park_t =        calc_temp(p1(19:20));
    pro.park_s =        calc_sal(p1(21:22),typ);
    pro.park_p =        h2b(p1(23:24),0.1);
    pro.parkbatteryvoltage =  calc_volt(p1(25));
    pro.surfpres =      h2b(p1(26:27),0.1) - 5;
    pro.p_internal =   (-.209 * p1(28)) + 26.23;
    pro.parkpistonpos =   p1(29);
    pro.SBEpumpvoltage = calc_volt(p1(30));
    pro.SBEpumpcurrent = p1(31) * 13;

  case 31
    % Apex2 oxy ice
    pro.profilepistonpos = p1(16);
    pro.icedetection =  p1(17);
    pro.airbladderpres =   p1(18);
    pro.park_t =        calc_temp(p1(19:20));
    pro.park_s =        calc_sal(p1(21:22),typ);
    pro.park_p =        h2b(p1(23:24),0.1);
    pro.parkO2_umolar =        h2b(p1(25:26),.01);    
    pro.parkO2 =        convert_uMolar(pro.parkO2_umolar,pro.park_p,pro.park_s,pro.park_t,lat);    
    pro.parkToptode =   h2b(p1(27:28),.01);    
    pro.parkbatteryvoltage =   calc_volt(p1(29));
    pro.parkbatterycurrent =   p1(30) * 13;
    pro.surfpres =      h2b([p1(31) dat(d0+1)],0.1) - 5;    
    pro.p_internal =   (-.209 * dat(d0+1)) + 26.23;
    pro.parkpistonpos =   dat(d0+3);
    pro.SBEpumpvoltage =  calc_volt(dat(d0+4));
    pro.SBEpumpcurrent = dat(d0+5) * 13;
    d0 = d0+5;
  
  case 32
    % Apex2 oxy
    pro.profilepistonpos = p1(16);
    pro.airbladderpres =   p1(17);
    pro.park_t =        calc_temp(p1(18:19));
    pro.park_s =        calc_sal(p1(20:21),typ);
    pro.park_p =        h2b(p1(22:23),0.1);
    pro.parkO2_umolar =        h2b(p1(24:25),.01);    
    pro.parkO2 =        convert_uMolar(pro.parkO2_umolar,pro.park_p,pro.park_s,pro.park_t,lat);    
    pro.parkToptode =     h2b(p1(26:27),.01);    
    pro.parkbatteryvoltage =   calc_volt(p1(28));
    pro.parkbatterycurrent =   p1(29) * 13;
    pro.surfpres =      h2b(p1(30:31),0.1) - 5;    
    pro.p_internal =   (-.209 * dat(d0+1)) + 26.23;
    pro.parkpistonpos =  dat(d0+2);
    pro.SBEpumpvoltage = calc_volt(dat(d0+3));
    pro.SBEpumpcurrent = dat(d0+4) * 13;
    d0 = d0+4;
    
  case 35
    % Apex2 oxy tmiss
    pro.airpumpcurrent = p1(16) * 13;
    pro.profilepistonpos = p1(17);
    pro.currentpistonpos = p1(18);
    pro.airbladderpres =   p1(19);
    pro.park_t =        calc_temp(p1(20:21));
    pro.park_s =        calc_sal(p1(22:23),typ);
    pro.park_p =        h2b(p1(24:25),0.1);
    pro.parkO2_umolar =        h2b(p1(26:27),.01);    
    pro.parkO2 =        convert_uMolar(pro.parkO2_umolar,pro.park_p,pro.park_s,pro.park_t,lat);    
    pro.parkToptode =   h2b(p1(28:29),.01);    
    pro.parkTmcounts =     p1(30)*20.;
    pro.parkbatteryvoltage =  calc_volt(p1(31));
    
    pro.parkbatterycurrent =   dat(d0+1) * 13;
    pro.surfpres =      h2b(dat(d0+(2:3)),0.1) - 5;
    pro.p_internal =   (-.209 * dat(d0+4)) + 26.23;
    pro.parkpistonpos =  dat(d0+5);
    pro.SBEpumpvoltage = calc_volt(dat(d0+6));
    pro.SBEpumpcurrent = dat(d0+7) * 13;
    d0 = d0+7;
    tm0 = 11;   % Position of tmiss byte in the repeated profile sample blocks
    
  case 38
    % Apex2 Seabird oxy sensor
    pro.profilepistonpos = p1(16);
    pro.airbladderpres =   p1(17);
    pro.park_t =        calc_temp(p1(18:19));
    pro.park_s =        calc_sal(p1(20:21),typ);
    pro.park_p =        h2b(p1(22:23),0.1);
    pro.parkO2 =        h2b(p1(24:25),.01);   
    pro.parkToptode = [];
% not sent    pro.parkToptode =     h2b(p1(26:27),.01);    
    pro.parkbatteryvoltage =   calc_volt(p1(26));
    pro.parkbatterycurrent =   p1(27) * 13;
    pro.surfpres =      h2b(p1(28:29),0.1) - 5;    
    pro.p_internal =   (-.209 * p1(30)) + 26.23;
    pro.parkpistonpos =  p1(31);
    pro.SBEpumpvoltage = calc_volt(dat(d0+1));
    pro.SBEpumpcurrent = dat(d0+2) * 13;
    d0 = d0+2;
    
  case 40  
    % Apex Korean optode oxy
    pro.airpumpcurrent =   p1(16) * 13;
    pro.surfacepistonpos = p1(17);
    pro.airbladderpres =   p1(18);
    pro.n_parksamps =  p1(19)-1;
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
    d0 = 19-2;
    
    % first, the 8 hour samples after descent:
       pro.t_8hr = calc_temp(dat(d0+[1 2]));
       pro.s_8hr = calc_sal(dat(d0+[3 4]),typ);
       pro.p_8hr = h2b(dat(d0+[5 6]),0.1);
       pro.oxy_8hr = h2b(dat(d0+[7 8]),.01);
       d0 = d0+8;    
    
    for jj = 1:pro.n_parksamps
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.s_park_av(jj) = calc_sal(dat(d0+[3 4]),typ);
       pro.p_park_av(jj) = h2b(dat(d0+[5 6]),0.1);
       pro.oxy_park_av(jj) = h2b(dat(d0+[7 8]),.01);
       d0 = d0+8;
    end
    tmp = dat(d0+[1 2]);
    if tmp(2)~=221
       logerr(2,'DECODE_WEBB: Did not get expected DD(221) after T,P avs');
    end
    pro.park_t =        calc_temp(dat(d0+[3 4]));
    pro.park_s =        calc_sal(dat(d0+[5 6]),typ);
    pro.park_p =        h2b(dat(d0+[7 8]),0.1);
    pro.parkO2_umolar =        h2b(dat(d0+[9 10]),0.01); 
    pro.parkO2 =        convert_uMolar(pro.parkO2_umolar,pro.park_p,pro.park_s,pro.park_t,lat);    
   pro.parkbatteryvoltage =   calc_volt(dat(d0+11));
    pro.surfpres =      h2b(dat(d0+[12 13]),0.1) - 5;
    pro.p_internal =    (-.209 * dat(d0+14)) + 26.23;
    pro.parkpistonpos =   dat(d0+15);
    pro.SBEpumpvoltage = calc_volt(dat(d0+16));
    pro.SBEpumpcurrent = dat(d0+17) * 13;
    pro.parkbatterycurrent = dat(d0+18) * 13;
    d0 = d0+18;
    
  case 43
    % Apex2 - optional Pressure Activation, DPF and Average T,P at Park Depth
    % (new in Nov 2006)
    pro.profilepistonpos = p1(16);
    pro.airbladderpres =   p1(17);
    pro.n_parkaverages =  p1(18);
    pro.n_parksamps =  p1(19);
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
    d0 = 19-2;
    for jj = 1:pro.n_parkaverages
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
    end
    tmp = dat(d0+[1 2]);
    if tmp(2)~=221
       logerr(2,'DECODE_WEBB: Did not get expected DD(221) after T,P avs');
    end
    pro.park_t =        calc_temp(dat(d0+[3 4]));
    pro.park_s =        calc_sal(dat(d0+[5 6]),typ);
    pro.park_p =        h2b(dat(d0+[7 8]),0.1);
    pro.parkbatteryvoltage =   calc_volt(dat(d0+9));
    pro.parkbatterycurrent =   dat(d0+10) * 13;
    pro.surfpres =      h2b(dat(d0+[11 12]),0.1) - 5;    
    pro.p_internal =    (-.209 * dat(d0+13)) + 26.23;
    pro.parkpistonpos =   dat(d0+14);
    pro.SBEpumpvoltage = calc_volt(dat(d0+15));
    pro.SBEpumpcurrent = dat(d0+16) * 13;
    d0 = d0+16;

  case 44
    % Apex2 - optional Pressure Activation, DPF and Average T,P at Park Depth
    % WITH Ice detection (new in Nov 2006)
    pro.profilepistonpos = p1(16);
    pro.airbladderpres =   p1(17);
    pro.n_parkaverages =  p1(18);
    pro.n_parksamps =     p1(19);
    pro.icedetection =    p1(20);
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 dat(d0+13)to where to start from..
    d0 = 20-2;
    for jj = 1:pro.n_parkaverages
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
    end
    tmp = dat(d0+[1 2]);
    if tmp(2)~=221
       logerr(2,'DECODE_WEBB: Did not get expected DD(221) after T,P avs');
    end
    pro.park_t =        calc_temp(dat(d0+[3 4]));
    pro.park_s =        calc_sal(dat(d0+[5 6]),typ);
    pro.park_p =        h2b(dat(d0+[7 8]),0.1);
    pro.parkbatteryvoltage =   calc_volt(dat(d0+9));
    pro.parkbatterycurrent =   dat(d0+10) * 13;
    pro.surfpres =      h2b(dat(d0+[11 12]),0.1) - 5;    
    pro.p_internal =    (-.209 * dat(d0+13)) + 26.23;
    pro.parkpistonpos =   dat(d0+14);
    pro.SBEpumpvoltage = calc_volt(dat(d0+15));
    pro.SBEpumpcurrent = dat(d0+16) * 13;
    d0 = d0+16;
    
  case 1001
   
    %Apex APF9 vanilla float
    pro.profilepistonpos = p1(16);
    pro.parkpistonpos =  p1(15);
    pro.SBE41status =  [dec2hex(p1(17)) dec2hex(p1(18))];
    pro.p_internal =    (-.209 * p1(12)) + 26.23;
    pro.surfpres =      h2b(p1(10:11),0.1); 
    %if this is true, the pressure is negative!!!
    if(pro.surfpres > 3276);pro.surfpres=pro.surfpres-6553.6;end
    pro.parkbatteryvoltage =   calc_volt9(p1(21));
    pro.parkbatterycurrent =   p1(22) * 13;
    pro.SBEpumpvoltage = calc_volt9(p1(23));
    pro.SBEpumpcurrent = p1(24) * 13;
    pro.airpumpvoltage = calc_volt9(p1(27));
    pro.airpumpcurrent = p1(28) * 13;
    pro.n_parkbuoyancy_adj = p1(29);
    pro.airbladderpres =  p1(13);
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
        pro.n_parkaverages = 1;
        pro.nparksamps = h2b(dat(d0+[1 2]),1); %???
    d0=d0+2;
%    for jj = 1:pro.n_parkaverages
jj=1;
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
%    end
    pro.t_park_std =    calc_temp(dat(d0+[1 2]));
    pro.p_park_std =    h2b(dat(d0+[3 4]),0.1);
    pro.t_min =         calc_temp(dat(d0+[5 6]));
    pro.p_at_min_t =    h2b(dat(d0+[7 8]),0.1);
    pro.t_max =         calc_temp(dat(d0+[9 10]));
    pro.p_at_max_t =    h2b(dat(d0+[11 12]),0.1);
    pro.p_min =         h2b(dat(d0+[13 14]),0.1);
    pro.p_max =         h2b(dat(d0+[15 16]),0.1);
    
    pro.park_t =        calc_temp(dat(d0+[17 18]));
    pro.park_s =        calc_sal(dat(d0+[19 20]),typ);
    pro.park_p =        h2b(dat(d0+[21 22]),0.1);
    d0=d0+22; 
    
  case {1002, 1012}
      
      if typ == 1012
          pro.npoints=pro.npoints+1;
      end

    %Apex APF9a with Anderaa Optode oxygen float
    pro.profilepistonpos = p1(16);
    pro.parkpistonpos =  p1(15);
    pro.SBE41status =  [dec2hex(p1(17)) dec2hex(p1(18))];
    pro.p_internal =    (0.293 * p1(12)) - 29.767;
    pro.surfpres =      h2b(p1(10:11),0.1); 
    %if this is true, the pressure is negative!!!
    if(pro.surfpres > 3276);pro.surfpres=pro.surfpres-6553.6;end
    pro.parkbatteryvoltage =   calc_volt9a(p1(21));
    pro.parkbatterycurrent =   (p1(22) * 4.052) - 3.606;
    pro.SBEpumpvoltage = calc_volt9a(p1(23));
    pro.SBEpumpcurrent = (p1(24) * 4.052) - 3.606;
    pro.airpumpvoltage = calc_volt9a(p1(27));
    pro.airpumpcurrent = (p1(28) * 4.052) - 3.606;
    pro.n_6secAirpumpbuoyancy_adj = p1(29);
    pro.airbladderpres =  p1(13);
    pro.airvolume = h2b(p1(30:31),1);
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
        pro.n_parkaverages = 1;
        pro.downtimeExpired_epoch =  hex2dec([dec2hex(dat(d0+1)) dec2hex(dat(d0+2)) dec2hex(dat(d0+3)) dec2hex(dat(d0+4))]);
    d0=d0+4;
        pro.timestarttelemetry = h2b(dat(d0+[1 2]),1);
        pro.n_parkbuoyancy_adj = dat(d0+3);
        
        pro.nparksamps = h2b(dat(d0+[4 5]),1); %???
    d0=d0+5;
%    for jj = 1:pro.n_parkaverages
jj=1;
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
%    end
    pro.t_park_std =    calc_temp(dat(d0+[1 2]));
    pro.p_park_std =    h2b(dat(d0+[3 4]),0.1);
    pro.t_min =         calc_temp(dat(d0+[5 6]));
    pro.p_at_min_t =    h2b(dat(d0+[7 8]),0.1);
    pro.t_max =         calc_temp(dat(d0+[9 10]));
    pro.p_at_max_t =    h2b(dat(d0+[11 12]),0.1);
    pro.p_min =         h2b(dat(d0+[13 14]),0.1);
    pro.p_max =         h2b(dat(d0+[15 16]),0.1);
      
    pro.surf_Oxy_pressure = h2b(dat(d0+[17 18]),.1);
    if(pro.surf_Oxy_pressure > 3276);pro.surf_Oxy_pressure=pro.surf_Oxy_pressure-6553.6;end
    [bp,ot]=conv3bytes(dat(d0+[19:21]));
    pro.surf_optode_Bphase =  bp;
    pro.surf_optode_T = ot;
    
    pro.park_t =        calc_temp(dat(d0+[22 23]));
    pro.park_s =        calc_sal(dat(d0+[24 25]),typ);
    pro.park_p =        h2b(dat(d0+[26 27]),0.1);
    [bp,ot]=conv3bytes(dat(d0+[28:30]));

    pro.park_Bphase =   bp;
    pro.parkToptode   =   ot;
    
    d0=d0+30;                        %byte 31 not used...
    
  case 1003
   
    %Apex APF9 vanilla float with ice detection
    pro.profilepistonpos = p1(16);
    pro.parkpistonpos =  p1(15);
    pro.SBE41status =  [dec2hex(p1(17)) dec2hex(p1(18))];
    pro.p_internal =    (0.293 * p1(12)) - 29.767;
    pro.surfpres =      h2b(p1(10:11),0.1); 
    %if this is true, the pressure is negative!!!
    if(pro.surfpres > 3276);pro.surfpres=pro.surfpres-6553.6;end
    pro.parkbatteryvoltage =   calc_volt9a(p1(21));
    pro.parkbatterycurrent =   (p1(22) * 4.052) - 3.606;
    pro.SBEpumpvoltage = calc_volt9a(p1(23));
    pro.SBEpumpcurrent = (p1(24) * 4.052) - 3.606;
    pro.airpumpvoltage = calc_volt9a(p1(27));
    pro.airpumpcurrent = (p1(28) * 4.052) - 3.606;
    
    pro.nAirPumps = p1(29);
    pro.VoltSecAirPump = h2b(p1(30:31),1.);

    pro.airbladderpres =  p1(13);
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
    d0=d0-1;
     pro.n_parkbuoyancy_adj = dat(d0+1);
     pro.iceEvasionBits = dec2bin(h2b(dat(d0+[2 3]),1.));
    d0=d0+3;
     
     pro.nMixedLayerSamples = dat(d0+1);  
     pro.medianMixedLayerT = calc_temp(dat(d0+[2 3]));
     pro.infimumMLTmedian = calc_temp(dat(d0+[4 5]));
    d0=d0+5;
     
     pro.n_parkaverages = 1;
        pro.nparksamps = h2b(dat(d0+[1 2]),1); %???
    d0=d0+2;
%    for jj = 1:pro.n_parkaverages
jj=1;
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
%    end
    pro.t_park_std =    calc_temp(dat(d0+[1 2]));
    pro.p_park_std =    h2b(dat(d0+[3 4]),0.1);
    pro.t_min =         calc_temp(dat(d0+[5 6]));
    pro.p_at_min_t =    h2b(dat(d0+[7 8]),0.1);
    pro.t_max =         calc_temp(dat(d0+[9 10]));
    pro.p_at_max_t =    h2b(dat(d0+[11 12]),0.1);
    pro.p_min =         h2b(dat(d0+[13 14]),0.1);
    pro.p_max =         h2b(dat(d0+[15 16]),0.1);
    
   d0=d0+16; 
   
    pro.park_t =        calc_temp(dat(d0+[1 2]));
    pro.park_s =        calc_sal(dat(d0+[3 4]),typ);
    pro.park_p =        h2b(dat(d0+[5 6]),0.1);
   d0=d0+6;
   
    case 1005   
        
    %possible correction needed?  recheck after next profile...
        
    pro.npoints=pro.npoints+1;
        
    %APF9a Indian floats - with surface T sensor 
    pro.profilepistonpos = p1(16);
    pro.parkpistonpos =  p1(15);
    pro.SBE41status =  [dec2hex(p1(17)) dec2hex(p1(18))];
    pro.p_internal =    (0.293 * p1(12)) - 29.767;
    pro.airbladderpres = p1(13);
    pro.surfpres =      h2b(p1(10:11),0.1); 
    %if this is true, the pressure is negative!!!
    if(pro.surfpres > 3276);pro.surfpres=pro.surfpres-6553.6;end
    pro.parkbatteryvoltage =   calc_volt9a(p1(21));
    pro.parkbatterycurrent =   (p1(22) * 4.052) - 3.606;
    pro.SBEpumpvoltage = calc_volt9a(p1(23));
    pro.SBEpumpcurrent = (p1(24) * 4.052) - 3.606;
    pro.airpumpvoltage = calc_volt9a(p1(27));
    pro.airpumpcurrent = (p1(28) * 4.052) - 3.606;
    
    %this is where format 1005 diverges from format 1001 
    %and is actually equivalent to format 1002:
    
    pro.airvolume = h2b(p1(30:31),1);
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
        pro.n_parkaverages = 1;
        pro.downtimeExpired_epoch =  hex2dec([dec2hex(dat(d0+1)) dec2hex(dat(d0+2)) dec2hex(dat(d0+3)) dec2hex(dat(d0+4))]);
    d0=d0+4;
        %and here is where 1005 diverges from format 1010:
        pro.nsurfpts = dat(d0+1);
        pro.nsurfpt = dat(d0+2);
        
        %and now it's the same as 1010 again:
        pro.n_parkbuoyancy_adj = dat(d0+3);        
        pro.nparksamps = h2b(dat(d0+[4 5]),1); %???
    d0=d0+5;
%    for jj = 1:pro.n_parkaverages
jj=1;
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
%    end

    pro.t_park_std =    calc_temp(dat(d0+[1 2]));
    pro.p_park_std =    h2b(dat(d0+[3 4]),0.1);
    pro.t_min =         calc_temp(dat(d0+[5 6]));
    pro.p_at_min_t =    h2b(dat(d0+[7 8]),0.1);
    pro.t_max =         calc_temp(dat(d0+[9 10]));
    pro.p_at_max_t =    h2b(dat(d0+[11 12]),0.1);
    pro.p_min =         h2b(dat(d0+[13 14]),0.1);
    pro.p_max =         h2b(dat(d0+[15 16]),0.1);
        
%back to format 1001 here:
    pro.park_t =        calc_temp(dat(d0+[17 18]));
    pro.park_s =        calc_sal(dat(d0+[19 20]),typ);
    pro.park_p =        h2b(dat(d0+[21 22]),0.1);
    d0=d0+22; 
       
    case {1010, 1011}
        
        if typ == 1011
           pro.npoints=pro.npoints+1;
        end
                
    %APF9a Indian floats - slightly different from format 1001 
    pro.profilepistonpos = p1(16);
    pro.parkpistonpos =  p1(15);
    pro.SBE41status =  [dec2hex(p1(17)) dec2hex(p1(18))];
    pro.p_internal =    (0.293 * p1(12)) - 29.767;
    pro.airbladderpres = p1(13);
    pro.surfpres =      h2b(p1(10:11),0.1); 
    %if this is true, the pressure is negative!!!
    if(pro.surfpres > 3276);pro.surfpres=pro.surfpres-6553.6;end
    pro.parkbatteryvoltage =   calc_volt9a(p1(21));
    pro.parkbatterycurrent =   (p1(22) * 4.052) - 3.606;
    pro.SBEpumpvoltage = calc_volt9a(p1(23));
    pro.SBEpumpcurrent = (p1(24) * 4.052) - 3.606;
    pro.airpumpvoltage = calc_volt9a(p1(27));
    pro.airpumpcurrent = (p1(28) * 4.052) - 3.606;
    
    %this is where format 1010 diverges from format 1001 
    %and is actually equivalent to format 1002:
    
    pro.airvolume = h2b(p1(30:31),1);
    
    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
        pro.n_parkaverages = 1;
        pro.downtimeExpired_epoch =  hex2dec([dec2hex(dat(d0+1)) dec2hex(dat(d0+2)) dec2hex(dat(d0+3)) dec2hex(dat(d0+4))]);
    d0=d0+4;
        pro.timestarttelemetry = h2b(dat(d0+[1 2]),1);
        pro.n_parkbuoyancy_adj = dat(d0+3);
        
        pro.nparksamps = h2b(dat(d0+[4 5]),1); %???
    d0=d0+5;
%    for jj = 1:pro.n_parkaverages
jj=1;
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
%    end

    pro.t_park_std =    calc_temp(dat(d0+[1 2]));
    pro.p_park_std =    h2b(dat(d0+[3 4]),0.1);
    pro.t_min =         calc_temp(dat(d0+[5 6]));
    pro.p_at_min_t =    h2b(dat(d0+[7 8]),0.1);
    pro.t_max =         calc_temp(dat(d0+[9 10]));
    pro.p_at_max_t =    h2b(dat(d0+[11 12]),0.1);
    pro.p_min =         h2b(dat(d0+[13 14]),0.1);
    pro.p_max =         h2b(dat(d0+[15 16]),0.1);
        
%back to format 1001 here:
    pro.park_t =        calc_temp(dat(d0+[17 18]));
    pro.park_s =        calc_sal(dat(d0+[19 20]),typ);
    pro.park_p =        h2b(dat(d0+[21 22]),0.1);
    d0=d0+22; 
    
    case 1014
        pro.npoints = pro.npoints;
        pro.psurf_now = p1(12)/10.;
        pro.pistonpos = p1(13);
        pro.voltage =  calc_volt9a(p1(24));
        pro.pumpmotortime = h2b(p1(18:19),1);
        pro.batterycurrent = (p1(25) * 4.052) - 3.606;

    pro.profilepistonpos = p1(15);
    pro.parkpistonpos =  p1(14);
    pro.SBE41status =  [dec2hex(p1(16)) dec2hex(p1(17))];
    
%     pro.p_internal =    (0.293 * p1(12)) - 29.767;  Moved to later
    pro.airbladderpres = p1(28);
    pro.surfpres =      h2b(p1(10:11),0.1); 
    %if this is true, the pressure is negative!!!
    if(pro.surfpres > 3276);pro.surfpres=pro.surfpres-6553.6;end
    pro.parkbatteryvoltage =   calc_volt9a(p1(20));
    pro.parkbatterycurrent =   (p1(21) * 4.052) - 3.606;
    pro.SBEpumpvoltage = calc_volt9a(p1(22));
    pro.SBEpumpcurrent = (p1(23) * 4.052) - 3.606;
    
    pro.airpumpvoltage = calc_volt9a(p1(26));
    pro.airpumpcurrent = (p1(27) * 4.052) - 3.606;
    
    %this is where format 1010 diverges from format 1001 
    %and is actually equivalent to format 1002:
    
    pro.airvolume = h2b(p1(30:31),1);
    pro.nAirPumps = p1(29);

    % Format is variable from here, so start using 'dat' instead of 'p1',
    % and set d0 to where to start from..
        pro.n_parkaverages = 1;
        pro.downtimeExpired_epoch =  hex2dec([dec2hex(dat(d0+1)) dec2hex(dat(d0+2)) dec2hex(dat(d0+3)) dec2hex(dat(d0+4))]);
    d0=d0+4;
        pro.timestarttelemetry = h2b(dat(d0+[1 2]),1);
        pro.n_parkbuoyancy_adj = dat(d0+3);
        
        pro.nparksamps = h2b(dat(d0+[4 5]),1); %???
    d0=d0+5;
%    for jj = 1:pro.n_parkaverages
jj=1;
       pro.t_park_av(jj) = calc_temp(dat(d0+[1 2]));
       pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1);
       d0 = d0+4;
%    end

    pro.t_park_std =    calc_temp(dat(d0+[1 2]));
    pro.p_park_std =    h2b(dat(d0+[3 4]),0.1);
    pro.t_min =         calc_temp(dat(d0+[5 6]));
    pro.p_at_min_t =    h2b(dat(d0+[7 8]),0.1);
    pro.t_max =         calc_temp(dat(d0+[9 10]));
    pro.p_at_max_t =    h2b(dat(d0+[11 12]),0.1);
    pro.p_min =         h2b(dat(d0+[13 14]),0.1);
    pro.p_max =         h2b(dat(d0+[15 16]),0.1);
        
%back to format 1001 here:
    pro.park_t =        calc_temp(dat(d0+[17 18]));
    pro.park_s =        calc_sal(dat(d0+[19 20]),typ);
    pro.park_p =        h2b(dat(d0+[21 22]),0.1);
    d0=d0+22; 
    
   case 1021

   %APF9G Indian floats - slightly different from format 1010  
   
     pro.TelonicsStatus = p1(10);
     pro.profilepistonpos = p1(16); % Field PPP 
     pro.parkpistonpos =  p1(15); % Field PPP2 
     pro.SBE41status =  [dec2hex(p1(17)) dec2hex(p1(18)) dec2hex(p1(19)) dec2hex(p1(20))]; % SBE41 status word 
     pro.surfpres =      h2b(p1(12:13),0.1); % Field SP 
     %if this is true, the pressure is negative!!! 
     if(pro.surfpres > 3276);pro.surfpres=pro.surfpres-6553.6;end 
     pro.parkbatteryvoltage =   calc_volt9a(p1(21)); % Field VQ 
     pro.parkbatterycurrent =   (p1(22) * 4.052) - 3.606; %Field IQ 
     pro.SBEpumpvoltage = calc_volt9a(p1(23)); % Field VSBE 
     pro.SBEpumpcurrent = (p1(24) * 4.052) - 3.606; % Field ISBE 
     pro.airpumpvoltage = calc_volt9a(p1(27)); % Field VAP 
     pro.airpumpcurrent = (p1(28) * 4.052) - 3.606; %Field IAP 
     pro.n_6secAirpumpbuoyancy_adj = p1(29);
 
     %this is where format 1011 diverges from format 1010  
     %and is actually equivalent to format 1002: 
     pro.airvolume = h2b(p1(30:31),1); %Field VSAP 
 
     % Format is variable from here, so start using 'dat' instead of 'p1', 
     % and set d0 to where to start from.. 
         pro.n_parkaverages = 1; 
         pro.downtimeExpired_epoch =  hex2dec([dec2hex(dat(d0+1)) dec2hex(dat(d0+2)) dec2hex(dat(d0+3)) dec2hex(dat(d0+4))]); % Field EPOCH down time expired 
     d0=d0+4; 
         pro.timestarttelemetry = h2b(dat(d0+[1 2]),1);% Fields TINIT 
         pro.n_parkbuoyancy_adj = dat(d0+3); % Fields NADJ 
 
         pro.nparksamps = h2b(dat(d0+[4 5]),1); % Field PRKN 
     d0=d0+5; 
 %    for jj = 1:pro.n_parkaverages 
     jj=1; 
        pro.t_park_av(jj) = calc_temp(dat(d0+[1 2])); % Field TMEAN 
        pro.p_park_av(jj) = h2b(dat(d0+[3 4]),0.1); % Field PMEAN 
        d0 = d0+4; 
 %    end 
 
     pro.t_park_std =    calc_temp(dat(d0+[1 2])); 
     pro.p_park_std =    h2b(dat(d0+[3 4]),0.1); 
     pro.t_min =         calc_temp(dat(d0+[5 6])); 
     pro.p_at_min_t =    h2b(dat(d0+[7 8]),0.1); 
     pro.t_max =         calc_temp(dat(d0+[9 10])); 
     pro.p_at_max_t =    h2b(dat(d0+[11 12]),0.1); 
     pro.p_min =         h2b(dat(d0+[13 14]),0.1); 
     pro.p_max =         h2b(dat(d0+[15 16]),0.1); 
     d0=d0+16; 
 % To obtain these values from Data message packet 3 
     pro.p_internal =    (0.293 * dat(d0+1) - 29.767); % Field VAC 
     pro.airbladderpres = dat(d0+2); % Field ABP 
     d0=d0+4; 
 %back to format 1001 here: 
     pro.park_t =        calc_temp(dat(d0+[1 2])); 
     pro.park_s =        calc_sal(dat(d0+[3 4]),typ); 
     pro.park_p =        h2b(dat(d0+[5 6]),0.1); 
     d0=d0+6; 
   
       
  otherwise
    % Have not coded this type yet
    logerr(1,['No code yet for float type ' num2str(typ)]);
    return
end


nbyt = 6;
if dbdat.oxy
    if dbdat.subtype == 1002 | dbdat.subtype == 1012
        nbyt = nbyt+3;
    elseif dbdat.subtype == 38 | dbdat.subtype == 40 | dbdat.subtype == 22
        nbyt = nbyt+2;
    else
       nbyt = nbyt+4;
    end
end
if dbdat.tmiss
   nbyt = nbyt+1;
end


% Check that the data vector is big enough, if not adjust 'lp'

if (length(dat)-d0)/nbyt < pro.npoints
   tmp = sprintf('Too few bytes: (%d) when expect %d X %d',...
		 (length(dat)-d0),pro.npoints,nbyt);
   logerr(2,tmp);
   pro.npoints = floor((length(dat)-d0)/nbyt);   
end

% Get common data

    iistart=1;

for ii = 1:pro.npoints
   jj = d0+(ii-1)*nbyt;
   
   pro.t_raw(ii) = calc_temp(dat(jj+[1 2]));
   pro.s_raw(ii) = calc_sal(dat(jj+[3 4]),typ);
   pro.p_raw(ii) = h2b(dat(jj+[5 6]),.1);
end

if dbdat.oxy
   % Oxygen float
   if dbdat.subtype == 1002 | dbdat.subtype == 1012   %APF9a oxygen
       for ii = 1:pro.npoints
          jj = d0+(ii-1)*nbyt;  % bytes 7 : 8 1/2 for Bphase, bytes 8 1/2 : 9 for t
          [bp,ot]=conv3bytes(dat(jj+(7:9)));
          pro.oxyT_raw(ii) = ot;

          pro.Bphase_raw(ii) = bp;
          pro.oxy_raw(ii) = convertBphase(bp,pro.oxyT_raw(ii),pro.s_raw(ii),pro.wmo_id, ...
              pro.p_raw(ii),lat);
       end         
          pro.surf_O2 = convertBphase(pro.surf_optode_Bphase,pro.surf_optode_T,pro.s_raw(end),...
              pro.wmo_id,pro.surf_Oxy_pressure,lat) ;
          pro.parkO2 = convertBphase(pro.park_Bphase,pro.parkToptode,pro.park_s,pro.wmo_id,...
              pro.park_p,lat) ;
   elseif dbdat.subtype == 38
       for ii = 1:pro.npoints
          jj = d0+(ii-1)*nbyt;
          pro.oxy_freq(ii) = h2b(dat(jj+(7:8)),1);
          if ~isnan(pro.oxy_freq(ii)) & ~isnan(pro.t_raw(ii)) & ~isnan(pro.s_raw(ii)) ...
                  & ~isnan(pro.p_raw(ii))
          pro.oxy_raw(ii) = convertFREQoxygen(pro.t_raw(ii),pro.s_raw(ii),...
              pro.p_raw(ii),pro.oxy_freq(ii),dbdat.wmo_id);
          else
                pro.oxy_raw(ii)=NaN;
          end
       end
   elseif dbdat.subtype == 40
       for ii = 1:pro.npoints
          jj = d0+(ii-1)*nbyt;
          pro.oxy_umolar(ii) = h2b(dat(jj+(7:8)),.01);
       end
   elseif dbdat.subtype == 22
       for ii = 1:pro.npoints
          jj = d0+(ii-1)*nbyt;
          pro.SBEOxyfreq_raw(ii) = h2b(dat(jj+(7:8)),1);
          if ~isnan(pro.SBEOxyfreq_raw(ii)) & ~isnan(pro.t_raw(ii)) & ~isnan(pro.s_raw(ii)) ...
                  & ~isnan(pro.p_raw(ii))
          pro.oxy_raw(ii) = convertFREQoxygen(pro.t_raw(ii),pro.s_raw(ii),...
                  pro.p_raw(ii),pro.SBEOxyfreq_raw(ii),dbdat.wmo_id);
          else
                pro.oxy_raw(ii)=NaN;
          end
      end
   else
       for ii = 1:pro.npoints
          jj = d0+(ii-1)*nbyt;
          pro.oxy_umolar(ii) = h2b(dat(jj+(7:8)),.01);
          pro.oxyT_raw(ii) = h2b(dat(jj+(9:10)),.01);
       end  
   end
end

if dbdat.subtype==31 || dbdat.subtype==32 || dbdat.subtype==35 || dbdat.subtype == 40
    pro.oxy_raw = convert_uMolar(pro.oxy_umolar,pro.p_raw,pro.s_raw,pro.t_raw,lat);    
end

if dbdat.tmiss
   % Transmissometer float   
   for ii = 1:pro.npoints
      jj = d0+(ii-1)*nbyt;
      pro.tm_counts(ii) = dat(jj+tm0)*20;
      pro.CP(ii)=convertTmiss(pro.tm_counts(ii),dbdat.wmo_id);
   end   
   
end

if dbdat.subtype==1005
    jj=(d0+pro.npoints*nbyt)+2;  % skip over the 'DDDDD' field in the next byte
       for ii = 1:pro.nsurfpts
          i2=length(pro.p_raw)+1;
          pro.nearsurfT(ii) = calc_temp(dat(jj+[1 2]));
          pro.nearsurfP(ii) = h2b(dat(jj+[3 4]),.1);
          pro.nearsurfTpumped(ii) =  calc_temp(dat(jj+[5 6]));
          pro.nearsurfSpumped(ii) = calc_sal(dat(jj+[7 8]),typ);
          pro.nearsurfPpumped(ii) = h2b(dat(jj+[9 10]),.1);
%           pro.p_raw(i2) = pro.nearsurfP(ii);
          pro.p_raw(i2) = pro.nearsurfPpumped(ii);
%           pro.t_raw(i2) = pro.nearsurfT(ii);
          pro.t_raw(i2) = pro.nearsurfTpumped(ii);
%           pro.s_raw(i2) = NaN;
          pro.s_raw(i2) = pro.nearsurfSpumped(ii);
          jj = jj+10;
       end  
       
       % set profile values to include the calibration values:
       pro.npoints = pro.npoints + pro.nsurfpts ;
       
          jj=jj+2;  %skip over 'EEEEE'
          
       for ii = ii+1:ii+pro.nsurfpt
%           i2=length(pro.p_raw)+1;
          pro.nearsurfT(ii) = calc_temp(dat(jj+[1 2]));
          pro.nearsurfP(ii) = h2b(dat(jj+[3 4]),.1);
%           pro.p_raw(i2) = pro.nearsurfP(ii);
%           pro.t_raw(i2) = pro.nearsurfT(ii);   
%           pro.s_raw(i2) = NaN;
          jj=jj+4;
       end   
end

if dbdat.subtype>1000 
    if dbdat.subtype==1005
%        jj=jj+1;
    else
        jj=d0+pro.npoints*nbyt;
    end
    ind=0;
    if(length(dat)>jj)
        if(dbdat.subtype==1014)
            ind1=9; 
        else
            ind1=7;
        end
        while(jj+1<length(dat) & ind <= ind1)
            ind=ind+1;
            ind2=ind;
            if (dbdat.subtype == 1014 | dbdat.subtype == 1021) 
                if (ind == 1)
                    pro.p_divergence = h2b(dat(jj+1:jj+2),10);  
                    jj=jj+1 ;                
                elseif (ind == 2)                    
                    pro.time_prof_init = h2b(dat(jj+1:jj+2),1); 
                    jj=jj+1;
                elseif (ind == 3)
                    pro.p_internal = (0.293 *  dat(jj+1) - 29.767);
                elseif (ind>3)
                    ind2=ind-3;
                end
            elseif((dbdat.subtype == 1002 | dbdat.subtype == 1005 | dbdat.subtype == 1012) & ind == 1)
                pro.time_prof_init = h2b(dat(jj+1:jj+2),1);
                jj=jj+1;
            elseif (dbdat.subtype == 1002 | dbdat.subtype == 1005 | dbdat.subtype == 1012)
                ind2=ind-1;
            end
            switch ind2
                case 1
                    pro.n_desc_p = dat(jj+1);                    
                case 2
                    pro.p_end_pistonretract = dat(jj+1);
                case 3
                    pro.p_1_hour = dat(jj+1);
                case 4
                    pro.p_2_hour = dat(jj+1);
                case 5
                    pro.p_3_hour = dat(jj+1);
                case 6
                    pro.p_4_hour = dat(jj+1);
                case 7
                    pro.p_5_hour = dat(jj+1);
            end
            jj=jj+1;
        end
    end
end
if dbdat.subtype==1005
    jj=d0+pro.npoints*nbyt;
end    


% Note: this was originally deleted - perhaps delete again?  If this is IN,
% it removes blank bitsof the parameter arrays, hiding wher teh gaps really
% are.  if it is out, we get missing bits of the profile but this means we
% can perhaps retrieve some dataa if we want to expend the effort by
% interpolating the missing values given that we know the position within
% the array...

% if dbdat.oxy
%     kk=find(isnan(pro.t_raw)& isnan(pro.s_raw) & isnan(pro.p_raw) & isnan(pro.oxy_raw));
%     if ~isempty(kk)
%         pro.t_raw(kk)=[];
%         pro.s_raw(kk)=[];
%         pro.p_raw(kk)=[];
%         pro.oxy_raw(kk)=[];
%         pro.npoints=pro.npoints-length(kk);
%     end
%     if isfield(pro,'oxy_umolar')
%         pro.oxy_umolar(kk)=[];
%     end
%     if isfield(pro,'pro.oxyT_raw')
%         pro.oxyT_raw(kk)=[];
%     end
%     if isfield(pro,'SBEOxyfreq_raw')
%         pro.SBEOxyfreq_raw(kk)=[];
%     end
%     if isfield(pro,'oxy_freq')
%         pro.oxy_freq(kk)=[];
%     end
%     if isfield(pro,'Bphase_raw')
%         pro.Bphase_raw(kk)=[];
%     end
%     
% else
%     kk=find(isnan(pro.t_raw)& isnan(pro.s_raw) & isnan(pro.p_raw));
%     if ~isempty(kk)
%         pro.t_raw(kk)=[];
%         pro.s_raw(kk)=[];
%         pro.p_raw(kk)=[];
%         pro.npoints=pro.npoints-length(kk);
%     end
%     
% end
fp = pro;

return

%--------------------------------------------------------------------
%  (256*h1 + h2) converts 2 hex (4-bit) numbers to an unsigned byte. 

function bb = h2b(dd,sc)

bb = (256*dd(1) + dd(2)).*sc;

%--------------------------------------------------------------------
function t = calc_temp(dd)

t = (256*dd(1) + dd(2)).*.001;
if t > 62.535
   t = t - 65.536;
end

%--------------------------------------------------------------------
function v = calc_volt(dd)

v = dd*.1 + .4;

%--------------------------------------------------------------------
function v = calc_volt9(dd)

v = dd*.078 + .5;
%--------------------------------------------------------------------
%--------------------------------------------------------------------
function v = calc_volt9a(dd)

v = dd*.077 + .486;
%--------------------------------------------------------------------

function s = calc_sal(dd,typ)

if typ==0
   % The Webb R1-SBE (block1.f) had ambiguous salinity coding, but since
   % all these floats are now dead<, I don't need to worry about it. Hence
   % this is a bit of "heritage" code - which would be inadequate if really
   % required.
   s = 30 + (256*dd(1) + dd(2))*.0001;   

else
   s = (256*dd(1) + dd(2))*.001;

   % Correction for sal for float 417 as coded in block1apex2ghost.f, but 417
   % is now dead anyway!
   %if sn==417 & s < 10.000
   %   s = s + 65.536;
   %end
end
%--------------------------------------------------------------------

function [bp,ot] = conv3bytes(dd)
    %convert the raw values to oxygen temp (ot) and bphase values (bp)
    
if(any(isnan(dd)))
    bp=nan;
    ot=nan;
    return
end
d1= dec2hex(dd(1));
d2= dec2hex(dd(2));
d3= dec2hex(dd(3));

if length(d2)<2
   d2(2)=d2(1);
   d2(1)='0';
end
if length(d3)<2
   d3(2)=d3(1);
   d3(1)='0';
end

bp = (hex2dec([d1 d2(1)])/100) + 23.;
ot = (hex2dec([d2(2) d3])/100) - 3.;

%--------------------------------------------------------------------
