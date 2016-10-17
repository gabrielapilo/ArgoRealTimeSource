function [range, A12, A21] = distance_lpo(lat, long)
%
% Computes distance and bearing between points on the earth using WGS 1984
% ellipsoid
%
% [range, A12, A21] = distance_lpo(lat, long) computes the ranges RANGE between
% points specified in the LAT and LONG vectors (decimal degrees with positive
% indicating north/east). Forward and reverse bearings (degrees) are returned
% in AF, AR.
%
% Ellipsoid formulas are recommended for distance d<2000 km,
% but can be used for longer distances.
%
% GIVEN THE LATITUDES AND LONGITUDES (IN DEG.) IT ASSUMES THE IAU SPHERO
% DEFINED IN THE NOTES ON PAGE 523 OF THE EXPLANATORY SUPPLEMENT TO THE
% AMERICAN EPHEMERIS.
%
% THIS PROGRAM COMPUTES THE DISTANCE ALONG THE NORMAL
% SECTION (IN M.) OF A SPECIFIED REFERENCE SPHEROID GIVEN
% THE GEODETIC LATITUDES AND LONGITUDES OF THE END POINTS
% *** IN DECIMAL DEGREES ***
%
% IT USES ROBBIN'S FORMULA, AS GIVEN BY BOMFORD, GEODESY,
% FOURTH EDITION, P. 122. CORRECT TO ONE PART IN 10**8
% AT 1600 KM. ERRORS OF 20 M AT 5000 KM.
%
% CHECK: SMITHSONIAN METEOROLOGICAL TABLES, PP. 483 AND 484,
% GIVES LENGTHS OF ONE DEGREE OF LATITUDE AND LONGITUDE
% AS A FUNCTION OF LATITUDE. (SO DOES THE EPHEMERIS ABOVE)
%
% PETER WORCESTER, AS TOLD TO BRUCE CORNUELLE...1983 MAY 27
%
% Copied from Argo Data Management Cookbook, Section 12 (Annex I).
% Test data can be found there.
% 
% On 09/11/1988, Peter Worcester gave me the constants for the
% WGS84 spheroid, and he gave A (semi-major axis), F = (A-B)/A
% (flattening) (where B is the semi-minor axis), and E is the
% eccentricity, E = ( (A**2 - B**2)**.5 )/ A
% the numbers from peter are: A=6378137.; 1/F = 298.257223563
% E = 0.081819191

A = 6378137.;
E = 0.081819191;
B = sqrt(A.^2 - (A*E).^2);
EPS = E*E/(1.-E*E);

NN = max(size(lat));
if (NN ~= max(size(long)))
   error('dist: Lat, Long vectors of different sizes!');
end
if (NN == size(lat))
   rowvec = 0; % it is easier if things are column vectors,
else
   rowvec = 1; % but we have to fix things before returning!
end;

% convert to radians
lat = lat(:)*pi/180;
long = long(:)*pi/180;

% fixes some nasty 0/0 cases in the geodesics stuff
lat(lat == 0) = eps*ones(sum(lat == 0), 1);

% endpoints of each segment
PHI1 = lat(1:NN-1);
XLAM1 = long(1:NN-1);
PHI2 = lat(2:NN);
XLAM2 = long(2:NN);

% wiggle lines of constant lat to prevent numerical probs.
if any(PHI1 == PHI2)
   for ii = 1:NN-1
      if (PHI1(ii) == PHI2(ii))
	 PHI2(ii) = PHI2(ii) + 1e-14;
      end
   end
end
% wiggle lines of constant long to prevent numerical probs.
if any(XLAM1 == XLAM2)
   for ii = 1:NN-1
      if XLAM1(ii) == XLAM2(ii)
	 XLAM2(ii) = XLAM2(ii) + 1e-14;
      end
   end
end

% COMPUTE THE RADIUS OF CURVATURE IN THE PRIME VERTICAL FOR EACH POINT
xnu = A./sqrt(1.0-(E*sin(lat)).^2);
xnu1 = xnu(1:NN-1);
xnu2 = xnu(2:NN);

% COMPUTE THE AZIMUTHS.
% A12 (A21) IS THE AZIMUTH AT POINT 1 (2) OF THE NORMAL SECTION CONTAININING
% THE POINT 2 (1)
TPSI2 = (1.-E*E)*tan(PHI2) + E*E*xnu1.*sin(PHI1)./(xnu2.*cos(PHI2));
PSI2 = atan(TPSI2);

% SOME FORM OF ANGLE DIFFERENCE COMPUTED HERE??
DPHI2 = PHI2-PSI2;
DLAM = XLAM2-XLAM1;
CTA12 = (cos(PHI1).*TPSI2 - sin(PHI1).*cos(DLAM))./sin(DLAM);
A12 = atan((1.)./CTA12);
CTA21P = (sin(PSI2).*cos(DLAM) - cos(PSI2).*tan(PHI1))./sin(DLAM);
A21P = atan((1.)./CTA21P);

% GET THE QUADRANT RIGHT
DLAM2 = (abs(DLAM)<pi).*DLAM + (DLAM>=pi).*(-2*pi+DLAM) + (DLAM<=-pi).*(2*pi+DLAM);
A12 = A12 + (A12<-pi)*2*pi-(A12>=pi)*2*pi;
A12 = A12 + pi*sign(-A12).*(sign(A12) ~= sign(DLAM2));
A21P = A21P + (A21P<-pi)*2*pi - (A21P>=pi)*2*pi;
A21P = A21P + pi*sign(-A21P).*(sign(A21P) ~= sign(-DLAM2));
% A12*180/pi
% A21P*180/pi
SSIG = sin(DLAM).*cos(PSI2)./sin(A12);

% At this point we are OK if the angle < 90 but otherwise
% we get the wrong branch of asin!
% This fudge will correct every case on a sphere, and *almost*
% every case on an ellipsoid (wrong hnadling will be when
% angle is almost exactly 90 degrees)
dd2 = [cos(long).*cos(lat) sin(long).*cos(lat) sin(lat)];
dd2 = sum((diff(dd2).*diff(dd2))')';
if any(abs(dd2-2) < 2*((B-A)/A)^2)           % Corrected: JRD 8/7/2014
   disp('dist: Warning...point(s) too close to 90 degrees apart');
end
bigbrnch = dd2>2;
SIG = asin(SSIG).*(bigbrnch==0) + (pi-asin(SSIG)).*bigbrnch;
A21 = A21P - DPHI2.*sin(A21P).*tan(SIG/2.0);

% COMPUTE RANGE
G2 = EPS*(sin(PHI1)).^2;
G = sqrt(G2);
H2 = EPS*(cos(PHI1).*cos(A12)).^2;
H = sqrt(H2);
TERM1 = -SIG.*SIG.*H2.*(1.0-H2)/6.0;
TERM2 = (SIG.^3).*G.*H.*(1.0-2.0*H2)/8.0;
TERM3 = (SIG.^4).*(H2.*(4.0-7.0*H2)-3.0*G2.*(1.0-7.0*H2))/120.0;
TERM4 = -(SIG.^5).*G.*H/48.0;
range = xnu1.*SIG.*(1.0 + TERM1 + TERM2 + TERM3 + TERM4);

% CONVERT TO DECIMAL DEGREES
A12 = A12*180/pi;
A21 = A21*180/pi;
if (rowvec)
   range = range';
   A12 = A12';
   A21 = A21';
end
