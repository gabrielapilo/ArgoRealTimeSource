% QC_TESTS Apply the prescribed QC tests for realtime Argo profiles.
%
%  Reference: Argo quality control manual Version 2.1 (30/11/2006)
%
%  NOTE: Do not transmit profile if fails tests 2 3 4 or 13. For all other
%        failures, can transmit profiles, but with bad parts flagged.
%
% INPUT 
%  dbdat - master database record for this float
%  fpin  - float struct array
%  ipf   - [optional] index to profiles to QC (default: QC all profiles)
%
% OUTPUT 
%  fpp   - QC fields
%
% Author:  Jeff Dunn CSIRO/BoM  Aug 2006
%
%  Devolved from QCtestV2.m (Ann Thresher ?)
%
% USAGE: fpp = qc_tests(dbdat,fpin,ipf)
%
% added oxygen QC for secondary profile (optional): AT Dec 2015
%

function QCdat = qc_tests_Profile2(dbdat,p2,s2,t2,pq,sq,tq,o2,oq)


% Note: Flags are set according to Ref Table 2 and sec 2.1 of the manual.
% The flag value is not allowed to be reduced - eg if already set to 4, must
% not override to 3. This is implemented in the algorithms below.

% Work through each required profile
QC=[];
for ii = 1
     
    % Initialise QC variables where needed:
    %  0 = no QC done
    %  1 = good value
    %  9 = missing value
    % first, get trap for missing profiles:
    
    
    if isempty(p2) & isempty(s2) & isempty(t2)
        logerr(3,['FLOAT WITH NO DATA...:' num2str(dbdat.wmo_id)]);
        QCdat=[];
        return
    end

    QC.p=pq;
    QC.s=sq;
    QC.t=tq;
    
    % now done in qc_tests
%         QC.p=ones(size(p2),'uint16');
%         jj = find(isnan(p2));
%         QC.p(jj) = 9;
%         
%         
%         QC.t  = ones(size(t2),'uint16');
%         jj = find(isnan(t2));
%         QC.t(jj) = 9;
%         
%         QC.s = ones(size(s2),'uint16');
%         jj = find(isnan(s2));
%         QC.s(jj) = 9;
                
        nlev = length(p2);
        
        
        jj=find(p2>dbdat.profpres+(dbdat.profpres*.1));
        
        if ~isempty(jj)
            newv = repmat(4,1,length(jj));
            if(~isempty(newv))
                QC.p(jj) = max([QC.p(jj); newv]);
                QC.t(jj) = max([QC.t(jj); newv]);
                QC.s(jj) = max([QC.s(jj); newv]);
            end
        end
        
        % Test8: Pressure Increasing Test
        
        % not valid for NST floats:
        if dbdat.subtype~=1005
        
        gg = find(~isnan(p2));
        if any(diff(p2(gg))==0)
            jj=(diff(p2(gg))==0);
            newv = repmat(4,1,length(find(jj)));
            if(~isempty(newv))
                QC.p(jj) = max([QC.p(jj); newv]);
                QC.t(jj) = max([QC.t(jj); newv]);
                QC.s(jj) = max([QC.s(jj); newv]);
%                 fp.oxy_qc(jj) = max([fp.oxy_qc(jj); newv]);
%                 fp.oxyT_qc(jj) = max([fp.oxyT_qc(jj); newv]);
            end
        end
        
        bb=[];
        kk=find(diff(p2)>0);
        
        if length(kk)>0
            for jj=1:length(kk)
                for l=kk(jj):kk(jj)+1    %max(2,kk(jj)):min(length(fp.p_calibrate)-2,kk(jj)+1)
                    if l>=length(p2)-1
                        bb=[bb min(length(p2),l+1)];
                    elseif l==1
                        if p2(l)< p2(l+2)
                            bb=[bb l];
                        else
                            bb=[bb l+1];
                        end
                    elseif(p2(l)>=p2(l-1) | p2(l)<= p2(l+2))
                        bb=[bb l];
                    end
                end
            end
            newv = repmat(4,1,length(bb));
            if ~isempty(newv)
                QC.p(bb) = max([QC.p(bb); newv]);
                QC.t(bb) = max([QC.t(bb); newv]);
                QC.s(bb) = max([QC.s(bb); newv]);
            end
        end
        end
        
        % Test9: Spike Test
        % testv is distance of v(n) outside the range of values v(n+1) and v(n-1).
        % If -ve, v(n) is inside the range of those adjacent points.
        
        bdt = findspike(t2,p2,'t');
        if ~isempty(bdt)
            newv = repmat(4,1,length(bdt));
            QC.t(bdt) = max([QC.t(bdt); newv]);
        end
        
        bds = findspike(s2,p2,'s');
        if ~isempty(bds)
            newv = repmat(4,1,length(bds));
            QC.s(bds) = max([QC.s(bds); newv]);
        end
        
        % Test11: Gradient Test
        if nlev>=3
            
            jj = 2:(nlev-1);
            
            testv = abs(t2(jj) - (t2(jj+1)+t2(jj-1))/2);
            kk = find(testv>9 | (p2(jj)>500 & testv>3));
            if ~isempty(kk)
                newv = repmat(4,1,length(kk));
                QC.t(kk+1) = max([QC.t(kk+1); newv]);
                
            end
            
            testv = abs(s2(jj) - (s2(jj+1)+s2(jj-1))/2);
            kk = find(testv>1.5 | (p2(jj)>500 & testv>0.5));
            if ~isempty(kk)
                newv = repmat(4,1,length(kk));
                QC.s(kk+1) = max([QC.s(kk+1); newv]);
            end
        end
        
        
        % Test14: Density Inversion Test
        
        % new test from ADMT12: density calculated relative to neighboring points,
        % not surface reference level...:
        
        difdd=0;
        for iij=1:length(p2)-1
            difdd(iij)=0;
            
            density = sw_pden(s2(iij:iij+1),t2(iij:iij+1),p2(iij:iij+1), ...
                (p2(iij)+p2(iij+1))/2);
            difdd(iij)=diff(density);
            
        end
        
        jj = find(difdd>0.03);
        jf=[];
        for i=1:length(jj)
            jk=[max(jj(i)-1,1);jj(i);min(length(difdd),jj(i)+1)];
            jk=unique(jk);
            jl=find(difdd(jk)==min(difdd(jk)));
            jf=[jf jj(i) jk(jl)];
        end
        
        
        if (~isempty(jf))
            % Have to reject value at both levels involved
            newv = repmat(4,1,length(jf));
            QC.t(jf) = max([QC.t(jf); newv]);
            QC.s(jf) = max([QC.s(jf); newv]);
            
        end
        
        % Test15: Grey List Test
        fp.testsperformed(15) = 0;
        
        if(strcmp(dbdat.status,'suspect') | strcmp(dbdat.status,'evil'))
            fp.testsperformed(15) = 1;
            fp.testsfailed(15) = 1;
            vv=1:length(p2);
            newv = repmat(3,1,length(vv));
            if(dbdat.wmo_id==5901162 | dbdat.wmo_id==1901121 | dbdat.wmo_id==5903264 | ...
                    dbdat.wmo_id==5900043 | dbdat.wmo_id==5900026 | dbdat.wmo_id==5900029 | ...
                    dbdat.wmo_id==5901150 | dbdat.wmo_id==5903707 | dbdat.wmo_id==7900325 |...
                    dbdat.wmo_id==5903660 | dbdat.wmo_id==5903700 | dbdat.wmo_id==5901702 |...
                    dbdat.wmo_id==1901320)
                QC.s(vv) = max([QC.s(vv); newv]);
                %            fp.s_qc(vv) = 3;
            else
                if strcmp(dbdat.status,'evil')
                    QC.p(vv) = 4;
                    QC.s(vv) = 4;
                    QC.t(vv) = 4;
                else
                    QC.s(vv) = max([QC.s(vv); newv]);
                    QC.p(vv) = max([QC.p(vv); newv]);
                    QC.t(vv) = max([QC.t(vv); newv]);
                    %                fp.p_qc(vv) = 3;
                    %                fp.s_qc(vv) = 3;
                    %                fp.t_qc(vv) = 3;
                end
            end
        end
    end
    QCdat=QC;
end

%-------------------------------------------------------------------------
