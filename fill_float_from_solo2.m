% function fp=fill_float_from_solo2(fp,flstruct)
%
%  this function takes the structure decoded from the binary SBD messages
%  and combines it with the metadata and profile data for that profile and
%  fills in the float.mat structure required by the plotting and netcdf
%  scripts of the Argo RT processing.
%
% inputs :
%   fp:  profile data and float structure for one profile
%   flstruct:   metadata, technical and location data for one profile
%   argosid: the hull number of the float
%
% outputs :
%   fp: the fully filled profile
%
% usage: fp=fill_float_from_solo2(fp,flstruct,argosid);
%
% AT November 2013
%
function fp = fill_float_from_solo2(fp,flstruct,argosid)
global ARGO_SYS_PARAM

 fl=flstruct;

 if ~isempty(fl.GPSEndProfile)
     Dive = fl.GPSEndProfile;
 else
     Dive = fl.GPSEndFirstDive;
 end
 
 if ~isempty(Dive) & Dive.ValidFix
     fp.lat=Dive.Latitude;
     fp.lon=Dive.Longitude;
     fp.position_accuracy = 'G';
     ddmmyy=[Dive.Date ' ' Dive.Time];
     
     dn = datenum(ddmmyy, 'dd/mm/yyyy HH:MM:SS');
     
     ds = str2num(datestr(dn,'yyyy mm dd HH MM SS'));
     fp.jday_ascent_end = julian(ds);
     
     fp.jday=julian(ds);
     fp.datetime_vec=ds;
 else
     gg=find(fl.IridiumPosn.CEP==min(fl.IridiumPosn.CEP));
     fp.lat=fl.IridiumPosn.Lat(gg(1));
     fp.lon=fl.IridiumPosn.Lon(gg(1));
     fp.jday_ascent_end = fl.IridiumPosn.jday_iridium(gg(1));
     
     fp.jday=fl.IridiumPosn.jday_iridium(gg(1));
     fp.position_accuracy = 'I';
     fp.datetime_vec=gregorian(fp.jday);
 end     
 %      change to 360 degree global coordinates:
if fp.lon<0; fp.lon=360+fp.lon; end


 fp.SN =  argosid;
 fp.PI =  ARGO_SYS_PARAM.PI_Name;
 fp.inst_type = '853';
 
 fp.GPScounter = Dive.NumberOfSatellites;
 fp.previous_position = [];
 fp.n_parkaverages = length(fp.t_park_av);
 
 fp.npoints = length(fp.p_raw);
 %  fp.driftpump_adj = [];;
 %  fp.previous_position = [];

 if ~isempty(fl.TechE2)
 
     fp.voltage = fl.TechE2.VoltageLastPUMP;
     fp.p_internal = fl.TechE2.VacuumHgBIT;
     
     fp.surfpres = fl.TechE2.PressureSurfaceBeforeReset;
     
     fp.t_park_av = fl.TechE2.TemperatureParkMean;
     fp.s_park_av = fl.TechE2.SalinityParkMean;
     fp.p_park_av = fl.TechE2.PressureParkMean;
     
     fp.syst_flags_surface = fl.TechE2.CompactedSBStatus;
     
     fp.p_internal_surface = fl.TechE2.VacuumHgAfterInflate;
     fp.CPUpumpvoltage = fl.TechE2.VoltageCPU;
     fp.CPUpumpSURFACEvoltage = fl.TechE2.VoltageSurfacePUMP;
     fp.SBEpumpvoltage = fl.TechE2.VoltageLastPUMP ;
     fp.SBEpumpSURFACEvoltage = fl.TechE2.VoltageSurfacePUMP;
     fp.pumpin_outatdepth = fl.TechE2.TimePumpedToDepthSeconds;
     fp.pumpin_outatsurface = fl.TechE2.TimePUMPAtSurfaceSeconds;

 end
 
 if ~isempty(fl.TechE3)
     fp.syst_flags_depth = fl.TechE3.ATSBDstatusLast;
 end
 