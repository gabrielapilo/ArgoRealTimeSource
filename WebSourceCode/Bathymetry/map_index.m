% MAP_INDEX    List details of CARS maps
%
% INPUT: par - [optional] unique property string, eg: 't' for 'temperature'
%              If no argument, a menu is given.
% OUTPUT: nil
%
% USAGE: map_index

function map_index(par)

disp('                                  ***')
disp([7 'OUT-OF-DATE. Now see www.marine.csiro.au/eez_data/doc/map_index.html']);
disp('                                  ***')
disp('')

fsuf = {'temp','salt','oxy','no3','po4','si','mld','hgt'};

if nargin>0 & ~isempty(par)
   if length(par)==1
      par = [par ' '];
   end
   if strncmpi(par,'t',1)
      npar = 1;
   elseif strncmpi(par,'si',2)
      npar = 6;
   elseif strncmpi(par,'s',1)
      npar = 2;
   elseif strncmpi(par,'o',1)
      npar = 3;
   elseif strncmpi(par,'n',1)
      npar = 4;
   elseif strncmpi(par,'p',1)
      npar = 5;
   elseif strncmpi(par,'m',1)
      npar = 7;
   elseif strncmpi(par,'d',1) | strncmpi(par,'h',1)
      npar = 8;
   else
      disp('I do not understand the given argument - choose from menu:');
      par = [];
   end
end

if nargin==0 | isempty(par)
   disp('Please select the mapped property from the menu.');
   disp('  You can call this mfile with an argument. eg for details of');
   disp('  silicate maps:   map_index(''si'')');
   npar = menu({'Details are available for',...
		'the following mapped properties:'},...
	       'temperature','salinity','oxygen','nitrate','phosphate',...
	       'silicate','mixed-layer-depth','dynamic-height');
end
  
more on
cmd = ['type /home/eez_data/atlas/map_index_' fsuf{npar}];
eval(cmd,' ');
eval('type /home/eez_data/atlas/map_index_notes',' ');
more off;

%--------------------------------------------------------------------------
