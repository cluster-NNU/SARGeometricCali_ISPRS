function ResultLoc = fastInitSARLoc(AirplanePosition, VENU, h0, hp, R, sv)
%  FASTINITSARLOC Airborne SAR fast positioning initial values
% 
% Detailed description of this function.
% hp Scene average elevation
% Note: convert H from BLH to ECEF!!!
% Fast positioning completes main calculations in ECEF coordinate system
% [w1,w2,w3]=enu2ecefv(0,0,delta_z,latG,lonG)
lonG = AirplanePosition(1);
latG = AirplanePosition(2);
% Convert velocity from ENU to ECEF coordinates;
ve = VENU(1);
vn = VENU(2);
vu = VENU(3);
[vx,vy,vz]=enu2ecefv(ve,vn,vu,latG,lonG);
% Define Earth ellipsoid
wgs84 = wgs84Ellipsoid('meter');  % Define WGS84 reference ellipsoid
[gx,gy,gz] = geodetic2ecef(wgs84,latG,lonG,h0); % Aircraft ECEF position
[tx,ty,tz] = geodetic2ecef(wgs84,latG,lonG,hp); % Nadir point ECEF position
dz0 = tz - gz;  % ECEF z-direction difference
% Solve fast positioning equations
syms dx dy
f1 = dx^2+dy^2+dz0^2-R^2;
f2 = vx*dx+vy*dy+vz*dz0+sv;
[dx,dy] = solve([f1 f2]);
dx = vpa(dx);
dy = vpa(dy);
% This part is for verification
% [r1,r2,r3] = ecef2enuv(dx,dy,dz0,latG,lonG);
Tecef = sqrt(dx(1)^2+dy(1)^2);                      % Squared projected difference length
[x,y,z] = geodetic2ecef(wgs84,latG,lonG,h0);    % Aircraft ECEF position
xp1 = x + dx;
yp1 = y + dy;
zp1 = z + dz0; 
% Convert from ECEF to geodetic coordinates
[latp,lonp,hp1] = ecef2geodetic(wgs84,xp1,yp1,zp1);
ResultLoc = double(vpa([latp,lonp,hp1]));            % Force convert to Double type
end