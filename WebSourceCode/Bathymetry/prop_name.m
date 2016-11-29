% PROP_NAME  Return property name(s) corresponding to codes (if NO input
%     argument given, lists all codes, names and descriptions).
%
% INPUTS: 
%  par    CSIRO property code 
%  opt    0=short name  1=long name  2=assume WOD01 property codes [default 0]
%
% CSIRO JRD  24/6/05
%
% USAGE: 
%   to see all property codes, names and descriptions:
%            prop_name
%   or to get individual property names:
%            pnm = prop_name(par,opt);

function pnm = prop_name(par,opt);

if nargin<2 | isempty(opt)
   opt = 0;
end

pars = {'t','s','o2','si','po4','no3','gamma','','','','','','','no4','nh3'};
lpar = {'temperature','salinity','oxygen','silicate','phosphate','nitrate',...
	'nutdens','','','','','','','nitrite','ammonia'};
desc = {'in situ deg C','PSU','ml/l','micromolar','micromolar','micromolar', ...
	'kg/m^3','','','','','','','micromolar','?'};

wpar = {'t','s','o2','po4','','si','','no3','pH','','Chl'};
wpar{17} = 'Alkalinity';
wpar{20} = 'pCO2';
wpar{21} = 'TCO2';
wpar{23} = 'NO2+NO3';
wpar{25} = 'Pressure';
wpar{27} = 'CO2 warming';
wpar{28} = 'xCO2 atmosphere';
wpar{29} = 'Air pressure';

pnm = pars;

if nargin==0 | isempty(par)
   for ii = 1:length(pars)
      if ~isempty(pars{ii})
	 disp(sprintf('%7d %7s   %10s',ii,pars{ii},desc{ii}))
      end
   end
else
   if opt==2
      pnms = wpar;
   elseif opt==1
      pnms = lpar;
   else
      pnms = pars;
   end
   if any(par>length(pnms))
      jj = find(par>length(pnms));
      disp(['Max property code is ' num2str(length(pnms))]);
      par(jj) = [];
   end
   if ~isempty(par)
      if par==0
	 pnm = 'All';
      else
	 pnm = pnms{par};
      end
      if nargout==0
	 disp(sprintf('%7d',par))
	 disp(sprintf('%7s',pnm))
      end
   end
end

%-----------------------------------------------------------------------------
