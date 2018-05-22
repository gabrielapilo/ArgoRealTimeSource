% LOAD_FLOAT_TO_TRAJ   This is not part of normal processing, but a
%  utility/test program to build the whole traj workfile and traj netcdf file
%  for a float, when required by the operator. 
%
% INPUT
%    wm      - WMOid 
%    rebuild - 1 = delete existing traj file and startfrom scratch
% 
% Find workfiles for a float, rebuild them if they don't have .crc or .juld
% or .satnam, then extend or rebuild the full traj workfile, then create traj netcdf file. 
%
% JRD Dec 2013

function load_float_to_traj(wm,rebuild)

if nargin<2 || isempty(rebuild)
   rebuild = 0;
end

load(['/home/argo/ArgoRT/matfiles/float' num2str(wm)]);

if isempty(float)
   return
end


if rebuild
   fnm = ['/home/argo/ArgoRT/trajfiles/T' num2str(wm) '.mat'];
   if exist(fnm,'file') 
      system(['rm ' fnm]);
   end
end

dbdat = getdbase(wm);

if ~dbdat.iridium  % argos floats:
    
pth = ['/home/argo/ArgoRT/workfiles/' num2str(wm) '/'];

for ii = 1:length(float)
    if ~isempty(float(ii).jday)
        wnm = [pth 'N' num2str(ii) '_P' num2str(ii)];
        
        if exist([wnm '.mat'],'file')
            A = load(wnm);
            if isempty(A.rawdat.blkno) || ~isfield(A.heads,'satnam') ...
                    || ~isfield(A.rawdat,'crc') || ~isfield(A.rawdat,'juld')
                disp([wnm ' is an incomplete file - rebuilding']);
                npro = 0;
                if isfield(A.pmeta,'ftp_fname') && ~isempty(A.pmeta.ftp_fname)
                    fnm2 = A.pmeta.ftp_fname;
                    fnm2 = ['/home/argo/ArgoRT/argos_downloads/' fnm2 '.log'];
                    if exist(fnm2,'file')
                        npro = strip_for_workfile(fnm2,wm,ii);
                    end
                end
            else
                npro = 1;
            end
        else
            npro = 0;
            disp([wnm ' is missing - rebuilding']);
        end
        
        if ~npro
            % Either no file, or no ftp_fname in pmeta, or could not
            % successfully get a profile out of that download file
            remake_workfile(wm,ii);
        end
        
        if exist([wnm '.mat'],'file')
            A = load(wnm);
            traj = load_traj_apex_argos(A.rawdat,A.heads,A.b1tim,A.pmeta,dbdat,float,1);
        end
    end
end

[traj,traj_mc_order] = load_traj_apex_argos(A.rawdat,A.heads,A.b1tim,A.pmeta,dbdat,float,0);

else    %iridium floats:
    
    %    pth = ['/home/argo/ArgoRT/dium_data/iridium_processed/' num2str(wm) '/'];
    %
    %    for ii = 1:length(float)
    %        if ~isempty(float(ii).jday)
    %            pno=sprintf('%3.3i',ii);
    %            filen=[pth num2str(dbdat.argos_id) '_' pno '.log'];
    %            if exist(filen,'file')
    %                strip_traj_iridium(filen);
    %            end
    %        end
    %    end
    %
    %
    %
    
    
    
    
    
end

if ~isempty(traj) && ~isempty(traj_mc_order)
    trajectory_nc(dbdat,float,traj,traj_mc_order);
end
