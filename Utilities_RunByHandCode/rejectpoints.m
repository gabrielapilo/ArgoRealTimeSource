% rejectpoints - this routine allows you to input a wmo id, profile number
% parameter list and depth range to reject those data points and re-create the profile
% netcdf file.
%
% usage:  rejectpoints(wmoid,pn,pl,startdepth,enddepth)%
% optional input is whether to reject or accept points - allows you to
% retrieve bad points that are actually good
%
%  where wmoid = wmo id
%                pn = profile number
%                pl = parameter list (cells) s,t,p
%                startdepth = first bad point
%                enddepth = last bad point or 999999 indicating the rest of
%                   the profile.
%                rr = reject(-1) or retrieve(1)? - optional
%                flg = flag level - optional. Default is 4
% Example:   rejectpoints(wmo,pn,{'s' 't'},0,2000)

function rejectpoints(wmoid,pn2,pl,startdepth,enddepth,rr,flg)

global ARGO_SYS_PARAM

if nargin < 7
    flg = 4;
end
if nargin<6
    rr=-1;
end

[fpp,dbdat]=getargo(wmoid);
if isempty(fpp(pn2).lat)
    return
end

pn = pn2;
for j=1:length(fpp)
    if fpp(j).profile_number == pn2
        pn=j;
    end
end

for i=1:length(pl)
    
    e = ['qc = fpp(pn).' pl{i} '_qc;'];
    eval(e);

    kj=find(isnan(fpp(pn).p_calibrate));
    if ~isempty(kj)
        if isempty(fpp(pn).surfpres_used)
            sp=fpp(pn).surfpres;
        else
            sp=fpp(pn).surfpres_used;
        end
    fpp(pn).p_calibrate(kj)=fpp(pn).p_raw(kj)-sp;
    end
    p = fpp(pn).p_calibrate;
    if(enddepth>=999999);enddepth=max(p);end
     
    kl = find(p >= startdepth-1 & p <= enddepth+1);
    if ~isempty(kl)
        kk=kl(1):kl(end);
    else
        kk = [];
    end
if rr<0
    qc(kk) = max(qc(kk),flg);
else
     qc(kk) = 1;
end
    e = ['fpp(pn).' pl{i} '_qc = qc;'];
    eval(e)
  
end

    float = fpp;
  
    fnm = [ARGO_SYS_PARAM.root_dir 'matfiles/float' num2str(dbdat.wmo_id)];


    save(fnm,'float','-v6');
    close all
    argoprofile_nc(dbdat,fpp(pn))
    web_profile_plot(fpp(pn),dbdat)
    tsplots(fpp)
    waterfallplots(fpp)
    time_section_plot(fpp)
    

