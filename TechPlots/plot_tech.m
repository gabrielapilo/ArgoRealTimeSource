%% Determine the different data from different floats
function plot_tech(float,dbdat)
%taken from Ben's run_all.m and adjusted to automate into RT system.
% RC August 2017, 
% RC More coding changes August 2018

global ARGO_SYS_PARAM;

%% load up the spreadsheets
if nargin == 0
    disp('No float or dbdat arguments passed in to plot_tech.m');
    return
end

close all
fnm = strcat(ARGO_SYS_PARAM.web_dir, '/tech/img/',num2str(dbdat.wmo_id));

if ~isdir(fnm)
    mkdir(fnm)
end
%get all the battery, float type etc information and save in a figure
eng = getadditionalinfo(dbdat.wmo_id);
    switch dbdat.wmo_inst_type
        case '831'
            aa = 'PALACE ';
            mak = 'WRC';
        case '846'
            aa = 'APEX ';
            mak = 'TWR';
        case '841'
            aa = 'PROVOR_MT';
            mak = 'METOCEAN'
        case '839'
            aa = 'PROVOR_II';
            mak = 'NKE';
        case '844'
            aa = 'ARVOR ';
            mak = 'NKE';
        case '851'
            aa = 'SOLO_W ';
            mak = 'WHOI';
        case '863'
            aa = 'NAVIS_A ';
            mak = 'SBE';
        case '869'
            aa = ['NAVIS_EBR '];
            mak = 'SBE';
        case '854'
            aa = ['S2A '];
            mak = 'MRV';
    end
fig1 = figure(1);clf;hold on;axis off
fig1.OuterPosition=[230 250 600 400];
dd = 1/9;
st = 0.95;
str = [];
if dbdat.subtype == 1019 | dbdat.subtype == 1023
    str = [str,'APF11 '];
end
if dbdat.ice
    str = [str,'Ice '];
end
if dbdat.oxy
    str = [str,'Oxy '];
end
if dbdat.tmiss
    str = [str,'Transmiss '];
end
if dbdat.flbb
    str = [str,'FLBB '];
end
if dbdat.em
    str = [str,'EM '];
end
if dbdat.suna
    str = [str,'SUNA '];
end
if dbdat.eco
    str = [str,'ECO '];
end
if dbdat.irr | dbdat.irr2
    str = [str,'IRR '];
end
if dbdat.pH
    str = [str,'pH'];
end
    
text([.01,.5],[st,st],{'Controller,sensors: ', str},'fontsize',12);st = st-dd;
text([.01,.5],[st,st],{'WMO, Hull, Trans ID: ', [num2str(eng.wmo_id) ', ' num2str(eng.mfg_id) ', ' dbdat.argos_hex_id]},'fontsize',12);st = st-dd;
text([.01,.5],[st,st],{'Maker: ', [mak ' ' aa ]},'fontsize',12);st = st-dd;
text([.01,.5],[st,st],{'Status: ', dbdat.status},'fontsize',12);st = st-dd;
text([.01,.5],[st,st],{'No Profiles: ', num2str(float(end).profile_number)},'fontsize',12);st = st-dd;
jj=length(float);
if isempty(float(end).jday)
    %find last not empty one
    for jj = length(float):-1:1
        if ~isempty(float(jj).jday)
            break
        end
    end
end
   
text([.01,.5],[st,st],{'Last date: ', [datestr(gregorian(float(jj).jday(1)),'dd/mm/yyyy') ' UTC, profile ' num2str(float(jj).profile_number)]},'fontsize',12);st = st-dd;
text([.01,.5],[st,st],{'Satellite type: ', eng.UplinkSystem },'fontsize',12);st = st-dd;
text([.01,.5],[st,st],{'Pressure sensor: ', [dbdat.pressure_sensor ', ' eng.Pressure.SerialNo]},'fontsize',12);st = st-dd;
text([.01,.5],[st,st],{'Battery : ', eng.Battery_Configuration},'fontsize',12);
my_save_fig([fnm '/summary'],'clobber')

%this is where we plot
plot_battery(float,fnm) ;
ground = plot_bathymetry(float ,fnm);
plot_weight(float, ground,fnm ) ;
plot_leak(float ,fnm) ;
plot_others(float,fnm);
plot_qc(float ,fnm) ;



