function [xbmoins, xbplus] = relative_2D_distance(xa,ya,d)
%
%   Author: D.Dobler (IFREMER) 
% 	Date: 2019/11/05
%   Version: 1.1
%   Modification: 1.1 (2019/11/05) some layout improvements
%				  1.0 (2019/09/01) creation
% 	Description: This function computes two lines (xbmoins and xbplus) that are at distance d from {xa,ya} points and that have the same size as ya.
%


infinite=9e15;
eps=1e-10;

if size(xa,2)==1
	xa=xa';
	ya=ya';
	transpose_res=true;
end

% STEP 1: Curviline interpolation
% -------------------------------
% Interpolate so that there is always less than distance d between 2 consecutive points of the med curve

% Save original arrays before interpolation
xa_ori=xa;
ya_ori=ya;

x_to_add=[];
y_to_add=[];

% First compute the slope a and intercept b of the line supporting the segments
% also indicate when the line is vertical
dxa=xa(2:end)-xa(1:end-1);
dya=ya(2:end)-ya(1:end-1);
% Initialize vertical boolean and slope a
isvertical=ones(size(dxa));
a=infinite*ones(size(dxa));
% Test verticality and record the result in the boolean isvertical
inotnull=find(dxa ~= 0);
isvertical(inotnull)=0;
% compute slope a
a(inotnull)=dya(inotnull)./dxa(inotnull);
% compute intercept b
b=ya(1:end-1)-a.*xa(1:end-1);

% compute each segment length
l_segments=sqrt(dxa.^2+dya.^2);
% compute the number of points to add to ensure a maximal distance d between two points
n_to_add=floor(l_segments/d-0.2);
% if it is more than 0, compute the corresponding coordinates of the points to add on the segment
i_to_interpolate=find(n_to_add>0);
for i = i_to_interpolate
	if ~isvertical(i)
		xi=[xa(i):(xa(i+1)-xa(i))/(n_to_add(i)+1):xa(i+1)];
		yi=a(i)*xi+b(i);
	else
		%case this is a vertical segment
		yi=[ya(i):(ya(i+1)-ya(i))/(n_to_add(i)+1):ya(i+1)];
		xi=xa(i)*ones(size(yi));
	end
	x_to_add=[x_to_add xi];
	y_to_add=[y_to_add yi];
end

% add interpolated points to the xa,ya vectors
[ya,isort]=sort([ya y_to_add]);
xa=[xa x_to_add];
xa=xa(isort);


% STEP 2: compute points at d distance from med (xa,ya) points
% ------------------------------------------------------------
xbplus=nan(size(ya_ori));
xbmoins=nan(size(ya_ori));

for n=1:length(ya_ori)
	
	% first, compute all dy2 from current point to all the other profiles points
	dy2=(ya_ori(n)-ya).^2;
	
	% Then keep only those that can be at distance d from one point on the horizontal line going through current point
	i_close=find(dy2<=d^2);
	
	% compute all the abscissa that would be at distance d on this horizontal line
	xbp=xa(i_close)+sqrt(d^2-dy2(i_close));
	xbm=xa(i_close)-sqrt(d^2-dy2(i_close));
	
	% the points that are at at least a distance d from all the other points of the profiles
	% are min of xbm and max of xbp
	xbplus(n)=max(xbp);
	xbmoins(n)=min(xbm);

end


% the same size as the input if needed
if transpose_res
	xbim=xbmoins';
	xbip=xbplus';
end
