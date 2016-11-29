% INSITU2POT  Convert depth, salinity and insitu temperature to potential 
%       temperature. Assume reference pressure of 0 (which also helps 
%       reduce memory requirements.)
%
% Basic calculations cut straight from the SEAWATER library, compiled by Phil
% Morgan & Lindsay Pender.             - JRD 9/2/06
%
% INPUT:  t    [ncast ndep]
%         s    [ncast ndep]
%         lat  [ncast 1]
%         dep  [ncast ndep] or [1 ndep] if appropriate
%         lon  [ncast 1] IF PROVIDED, fill missing S using T/S climatology,
%              but forcing to fit (blend onto) any available S values. 
%
% *** DO NOT READ INPUT DETAILS ABOVE     (...and get what you deserve) ***
%
% USAGE: pt = insitu2pot(t,s,lat,dep,lon);

function pt = insitu2pot(T,S,lat,dep,lon)

global insitu2pot_nff insitu2pot_npf

% longitude will be provided if want gaps in S filled where possible
fills = (nargin>4 & ~isempty(lon));

[ncst,ndep] = size(T);
depsame = (min(dims(dep))==1 & ncst>1);

[ncS,ndS] = size(S);
if ncst~=ncS
   error('INSITU2POT: mismatch size of T and S');
elseif ndep~=ndS
   if fills & ndep>ndS
      S = [S repmat(nan,[ncst ndep-ndS])];
   else
      ndep = min([ndep ndS]);
      S = S(:,1:ndep);
      T = T(:,1:ndep);
      dep = dep(:,1:ndep);
   end
end
if ndep==0 | ncst==0
   pt = [];
   return
end
   
if fills
   % Casts with some T but no S
   jj = 1:ncst;
   ii = find(any(~isnan(T')) & all(isnan(S')));
   if ~isempty(ii)
      jj(ii) = [];
      [S2,oor] = s_from_direct_ts05(lon(ii),lat(ii),[],T(ii,:));
      if ~isempty(oor); ii(oor) = []; end
      if ~isempty(ii)
	 insitu2pot_nff = insitu2pot_npf + length(ii);
	 S(ii,:) = S2';
      end
   end
   
   ii = jj(find(any(~isnan(T(jj,:))' & isnan(S(jj,:))')));
   if ~isempty(ii)
      if depsame
	 dep = dep(ones(ncst,1),:);
	 depsame = 0;
      end
      [S2,oor] = s_from_direct_ts05(lon(ii),lat(ii),[],T(ii,:));
      if ~isempty(oor); ii(oor) = []; end
      S2 = S2';
      for kk = 1:length(ii)
	 ki = ii(kk);
	 gg = find(~isnan(S(ki,:)) & ~isnan(S2(kk,:)) & ~isnan(dep(ki,:)));
	 ll = find(isnan(S(ki,:)) & ~isnan(S2(kk,:)) & ~isnan(dep(ki,:)));
	 if any(diff(dep(ki,:))<=0) | isempty(gg)
	    % Can't use this approach if depths are not monotonic
	    ll = [];
	 end
	 if ~isempty(ll) & gg(end)<ll(end)	  
	    gg = [gg ll(end)];
	    S(ki,ll(end)) = S2(kk,ll(end)); 
	    ll(end) = [];
	 end
	 if ~isempty(ll) & length(gg)>1	    
	    dl = interp1(dep(ki,gg),S(ki,gg)-S2(kk,gg),dep(ki,ll)); 
	    S(ki,ll) = S2(kk,ll)+dl;
	 end
      end
      insitu2pot_npf = insitu2pot_npf + length(ii);
   end
end
      
X = latcor(lat);
C1 = 5.92E-3 + (X(:,ones(1,ndep)).^2 * 5.25E-3);

if depsame
   P = ((1-C1)-sqrt(((1-C1).^2)-(8.84E-6*dep(ones(ncst,1),:))))/4.42E-6;
else
   P = ((1-C1)-sqrt(((1-C1).^2)-(8.84E-6*dep)))/4.42E-6;
end
clear C1 X dep

% theta1
del_th = -P.*adtg_sw(S,T*1.00024,P);
th     = T * 1.00024 + 0.5*del_th;
q      = del_th;

% theta2
del_th = -P.*adtg_sw(S,th,0.5*P);
th     = th + (1 - 1/sqrt(2))*(del_th - q);
q      = (2-sqrt(2))*del_th + (-2+3/sqrt(2))*q;

% theta3
del_th = -P.*adtg_sw(S,th,0.5*P);
th     = th + (1 + 1/sqrt(2))*(del_th - q);
q      = (2 + sqrt(2))*del_th + (-2-3/sqrt(2))*q;

% theta4
del_th = -P.*adtg_sw(S,th,0);
pt     = (th + (del_th - 2*q)/6)/1.00024;

return
%-----------------------------------------------------------------------
% Just the SEAWATER sw_adtg reformulated to handle bigger arrays without 
% swamping memory

function ADTG = adtg_sw(S,T,P)

a0 =  3.5803E-5;
a1 = +8.5258E-6;
a2 = -6.836E-8;
a3 =  6.6228E-10;

b0 = +1.8932E-6;
b1 = -4.2393E-8;

c0 = +1.8741E-8;

c1 = -6.7795E-10;
c2 = +8.733E-12;
c3 = -5.4481E-14;

d0 = -1.1351E-10;
d1 =  2.7759E-12;

e0 = -4.6206E-13;
e1 = +1.8676E-14;
e2 = -2.1687E-16;

[m,n] = size(T);
if m*n > 10E6

   ADTG = zeros(m,n);
   for jj = 1:100:size(T,1)
      kk = jj:(min([jj+99 m])); 
      ADTG(kk,:) = (a2 + a3.*T(kk,:)).*T(kk,:);
      ADTG(kk,:) = a0 + (a1 + ADTG(kk,:)).*T(kk,:);
      tmp = (b0 + b1.*T(kk,:)).*(S(kk,:)-35);
      ADTG(kk,:) = ADTG(kk,:) + tmp;
      if P ~= 0
	 tmp = (c2 + c3.*T(kk,:)).*T(kk,:);
	 tmp = c0 + (c1 + tmp).*T(kk,:);
	 tmp = tmp + (d0 + d1.*T(kk,:)).*(S(kk,:)-35);
	 ADTG(kk,:) = ADTG(kk,:) + tmp.*P(kk,:);
	 tmp = e0 + (e1 + e2.*T(kk,:)).*T(kk,:);
	 ADTG(kk,:) = ADTG(kk,:) + tmp.*P(kk,:).*P(kk,:);
      end
   end
else   
   ADTG = a0 + (a1 + (a2 + a3.*T).*T).*T ...
	  + (b0 + b1.*T).*(S-35);
   if P ~= 0 
      ADTG = ADTG + ( (c0 + (c1 + (c2 + c3.*T).*T).*T) ...
		      + (d0 + d1.*T).*(S-35) ).*P ...
	     + (  e0 + (e1 + e2.*T).*T ).*P.*P;
   end
end

%-------------------------------------------------------------------------
