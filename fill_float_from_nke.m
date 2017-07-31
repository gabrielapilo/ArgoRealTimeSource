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
% By uday on June 2017
%
function fp = fill_float_from_nke(fp,flstruct,argosid)
global ARGO_SYS_PARAM

 fl=flstruct;

 if ~isempty(fl.TechPkt1Info)
     Dive = fl.TechPkt1Info;
 else
     Dive = [];
 end
 
 if ~isempty(Dive) %& Dive.ValidFix
     fp.lat=Dive.gps_lat_deg + (Dive.gps_lat_min/60.0);
     if(Dive.gps_lat_orientation == 1)
       fp.lat = -1*fp.lat;
     end
     fp.lon=Dive.gps_lon_deg + (Dive.gps_lon_min/60.0);
     if(Dive.gps_lon_orientation == 1)
       fp.lon = -1*fp.lon;
     end
     fp.position_accuracy = 'G';

     dn = datenum((Dive.float_date_year+2000),Dive.float_date_mon,Dive.float_date_day,Dive.float_time_hour,Dive.float_time_min,Dive.float_time_sec);
     
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
 fp.inst_type = '844';
 
 fp.GPScounter = [];   %Dive.NumberOfSatellites;
 fp.previous_position = [];
 fp.n_parkaverages = []; %length(fp.t_park_av);
 
 fp.npoints = length(fp.p_raw);
 %  fp.driftpump_adj = [];;
 %  fp.previous_position = [];

     fp.voltage = Dive.batvolt_drop_atPmax_pumpon;
     fp.n_valve_acts_surf = Dive.n_valve_acts_surf;
     fp.desc_sttime = Dive.desc_sttime;
     fp.first_stab_time = Dive.first_stab_time;
     fp.desc_endtime = Dive.desc_endtime;
     fp.n_valve_acts_desc = Dive.n_valve_acts_desc;
     fp.n_pump_acts_desc = Dive.n_pump_acts_desc;
     fp.n_repositions = Dive.n_repositions;
     fp.resurf_endtime = Dive.resurf_endtime;
     fp.n_pump_acts_asc = Dive.n_pump_acts_asc;
     fp.float_time_hour = Dive.float_time_hour;
     fp.float_time_min = Dive.float_time_min;
     fp.float_time_sec = Dive.float_time_sec;
     fp.pres_offset = Dive.pres_offset;
     fp.surfpres = Dive.pres_offset;
     fp.p_internal = Dive.internal_vacuum;

  if ~isempty(fl.TechPkt2Info)
     fp.n_asc_blks = fl.TechPkt2Info.n_asc_blks;
     fp.n_drift_blks = fl.TechPkt2Info.n_drift_blks;
     fp.n_drift_samps = fl.TechPkt2Info.n_drift_samps;
     fp.park_p = fl.TechPkt2Info.sub_surf_pres;
     fp.park_t = fl.TechPkt2Info.sub_surf_temp;
     fp.park_s = fl.TechPkt2Info.sub_surf_psal;
  end
end
