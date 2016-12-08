% script to convert all old-format matfiles 


ipth = '/home/gronell/argos/floatdata/';
opth = '/home/argo/ArgoRT/matfiles/';

ldir = dir([ipth 'flo*mat']);

for ii = 1:length(ldir)
   fnm = ldir(ii).name;
   i1 = strfind(fnm,'float');
   i2 = strfind(fnm,'.mat');
   argos = str2num(fnm((i1+5):(i2-1)));
   
   if argos<70
      argos = 21200+argos;
   elseif  argos<100
      argos = 21000+argos;
   end

   wmo = idcrossref(argos,2,1);
   if isempty(wmo)
      disp(['No WMO id found for ARGOS ' num2str(argos)])
   else
      convert_matfiles(wmo,ipth,opth);
   end
end
