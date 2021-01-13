function [fv,fp] = qc_traj(fv,fp)
%QC tests for traj files.
%Bec Cowley 1 March, 2019
%this needs to be done for the on_deployment field too for iridium files

%for the on_deployment field, if it exists and isn't empty (ie, cycle 1).
if isfield(fv,'on_deployment')
    if ~isempty(fv.on_deployment)
        fvod = fv.on_deployment;
        [fvod,fp] = traj_qc(fvod,fp);
        fv.on_deployment = fvod;
    end
end
%for the traj for this cycle
[fv,fp] = traj_qc(fv,fp);

end
function [fv,fp] = traj_qc(fv,fp)

fpparmn = {'park_p','park_t','park_s','p_park_av','t_park_av','s_park_av'};
fpparmnq = {'park_pq','park_tq','park_sq','p_park_avq','t_park_avq','s_park_avq'};
parmnm = {'pressure','temperature','salinity'};
parmnmq = {'pressure_qc','temperature_qc','salinity_qc'};


flds = fieldnames(fv);
for a = 1:length(flds)
    fld = fv.(flds{a});        
    if isfield(fld,'juld')
        fld.juld_qc = ones(size(fld.juld));
        
        % Test2: Impossible Date Test:
        %check date is between
        j1 = julian([1997 1 1 0 0 0]);
        d =datestr(now,'yyyy mm dd HH MM SS');
        j2 = julian(str2num(d));
        
        ibad = fld.juld< j1 | fld.juld > j2;
        if any(ibad)
            fld.juld_qc(ibad) = 3;
        end
    end
    
    
    % Tests 3 - 5
    %grab the QC from the fpp structure:
    if isfield(fld,'lat')
        fld.qcflags = ones(size(fld.lat));
        if length(fld.lat) ~= length(fp.lat)
            disp(['Profile: ' num2str(fp.profile_number) ': qc_traj.m: Different length of positions'])
            [~,ia,ib] = intersect(fld.lat,fp.lat,'stable');
            fld.qcflags(ia) = fp.pos_qc(ib);
        else
        fld.qcflags = fp.pos_qc;
        end
    end
        

    % Test6: Global Range Test on PTS:
    for b = 1:length(parmnm)
        if isfield(fld,parmnm{b})
            dat = fld.(parmnm{b});
            qc = ones(size(dat));
%             qc2 = ones(size(dat));
            
            if b==1 
                ip = find(dat < -5);
            end
%             if b == 1 % PRES QC test 2
%                 ip2 = find(dat >= -5 & dat <= -2.4);
%             end
            if b == 2
                ip = find(dat<=-2.5 | dat>40.);
            end
            if b == 3
                ip = find(dat<2.0 | dat>41.);
            end
            
            if ~isempty(ip)
                newv = repmat(4,size(ip));
                qc(ip) = max([qc(ip), newv],[],2);
            end
%             if ~isempty(ip2); % If PRES within ranges, QC3 to P,T,S
%                 newv2 = repmat(3,size(ip2));
%                 qc2(ip2) = max([qc2(ip2), newv2],[],2);
%                 fld.(parmnmq{1}) = qc2;
%                 fld.(parmnmq{2}) = qc2;
%                 fld.(parmnmq{3}) = qc2;
%             end
            
            fld.(parmnmq{b}) = qc;
            %and get rid of very large values eg 3.4095e+38 which have
            %occurred in dodgy CTDs and cause problems with ncwrite:
            ip = find(dat > 100000);
            if ~isempty(ip)
                fld.(parmnm{b})(ip) = NaN;
                fld.(parmnmq{b})(ip) = 9;
            end
        end
    end
    
    fv.(flds{a}) = fld;
end
%repeat test 6 here on fpp structure:
for b = 1:length(fpparmn)
    if isfield(fp,fpparmn{b})
        dat = fp.(fpparmn{b});
        qc = ones(size(dat));
%         qc2 = ones(size(dat));
        
        if b==1 || b == 4
            ip = find(dat < -5);
        end
%         if b==1 || b == 4
%             ip2 = find(dat >= -5 & dat <= -2.4);
%         end
        if b == 2 || b == 5
            ip = find(dat<=-2.5 | dat>40.);
        end
        if b == 3 || b==6
            ip = find(dat<2.0 | dat>41.);
        end
        
        if ~isempty(ip)
            newv = repmat(4,1,length(ip));
            qc(ip) = max([qc(ip); newv]);
        end
%         if ~isempty(ip2)
%             newv2 = repmat(3,1,length(ip2));
%             qc2(ip2) = max([qc2(ip2); newv2]);
%             fp.(fpparmnq{1}) = qc2;
%             fp.(fpparmnq{2}) = qc2;
%             fp.(fpparmnq{3}) = qc2;
%         end
        fp.(fpparmnq{b}) = qc;
    end
end
% Test7: Regional Parameter Test
% we won't do this one?
end


