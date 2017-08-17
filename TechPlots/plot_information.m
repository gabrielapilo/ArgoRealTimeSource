function [ ] = plot_information( nbfloat , document , floatnum , floatbatt , typebatt, hull)
% This function permits to plot information about the float.
lft = [0.05:1/5:0.95];
bot = 0.8:-.1872:0.05 ;
wid = 0.13;
hgt = 0.3;

% Extract the information from another program:
[ status , typepres , bgc , typefloat , batterytype , last_date, hull ] = float_info( nbfloat , document , floatnum , floatbatt , typebatt );

% Determine the position of the information:
subplot('Position',[lft(1) bot(5) wid hgt]);
axis off
title(nbfloat);

% Status of the float (dead or alive).
t = text(0.1 , 0.97 , 'Status : ');
t.FontWeight = 'bold';
text(0.5 , 0.97 , status );

% Number of profile done by the float.
t = text(0.1 , 0.87 , 'Nb prof : ');
t.FontWeight = 'bold';
text(0.5 , 0.87 , int2str(length(document.float)));

% last report date of the float
t = text(0.1 , 0.77 , 'Last date : ');
t.FontWeight = 'bold';
text(0.5 , 0.77 , last_date);


[ res ] = argo_irid( nbfloat , document );
% System of satellite (ARGOs or Iridium).
t = text(0.1 , 0.62 , 'Satellite : ');
t.FontWeight = 'bold';
text(0.5 , 0.62 , res );

% Type of the float (APEX, Sea Bird...)
t = text(0.1 , 0.52 , 'Type : ');
t.FontWeight = 'bold';
text(0.5 , 0.52 , typefloat );

% Type of sensor used (oxygen, ice...)
t = text(0.1 , 0.42 , 'Sensors : ');
t.FontWeight = 'bold';
text(0.5 , 0.42 , bgc );

% Type of pressure sensor used (Druck, Ametek...)
t = text(0.1 , 0.32 , 'Pressure : ');
t.FontWeight = 'bold';
text(0.5 , 0.32 , typepres );

% Type of battery of the float (Lithium,alkaline...)
t = text(0.1 , 0.17 , 'Battery : ');
t.FontWeight = 'bold';
text(0.1 , 0.07 , batterytype );

% Manufacturer hull number
t = text(0.1 , 0.0 , 'Manufacturer ID : ');
t.FontWeight = 'bold';
text(0.1 , -0.1 , hull );

end