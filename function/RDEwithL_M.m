function [latT,lonT,hpT] = RDEwithL_M(HInit, VENU,AirplanePosition,initLoc,h0,R,sv)
%  RDEWITHL_M Solve RDE equations using LM algorithm
% 
% Detailed description of this function.
    lonG = AirplanePosition(1);
    latG = AirplanePosition(2);
    % Convert velocity from ENU to ECEF coordinates;
    ve = VENU(1);
    vn = VENU(2);
    vu = VENU(3);
    [vx,vy,vz]=enu2ecefv(ve,vn,vu,latG,lonG);
    % Define Earth ellipsoid
    wgs84 = wgs84Ellipsoid('meter');  % Define WGS84 reference ellipsoid
    latInit =  initLoc(1);
    lonInit =  initLoc(2);
    ht = HInit;
    % Ellipsoid parameters
    Ra = 6378137.0;
    Rb = 6356752.3142;
    vN = sqrt(vx^2+vy^2+vz^2);% Velocity normalization
    
    %     vN = 1;
    [xt0,yt0,zt0] = geodetic2ecef(wgs84,latInit,lonInit,HInit);  % Target initial values from geodetic to ECEF coordinates
    [gx,gy,gz] = geodetic2ecef(wgs84,latG,lonG,h0);              % Aircraft ECEF position
    rN = sqrt((xt0-gx)^2+(yt0-gy)^2+(zt0-gz)^2); % Range normalization
    % Iteratively solve equations numerically using LM algorithm, 3D scene, in ECEF coordinate system;
    f = @(x)[(x(1)^2+x(2)^2+x(3)^2-R^2),
        (vx*x(1)+vy*x(2)+vz*x(3)+sv),
        ((gx+x(1))^2+(gy+x(2))^2)/(Ra+ht)^2+(gz+x(3))^2/(Rb)^2-1];
    % x3d = fsolve(f,[xt0-gx,yt0-gy,zt0-gz],optimset('Display','iter','Algorithm','levenberg-marquardt')); % Solved result
    x3d = fsolve(f,[xt0-gx,yt0-gy,zt0-gz],optimset('Algorithm','levenberg-marquardt')); % Solved result
%     J = jacobian(f,x)
% RD condition number
%     syms x1 y1 z1 vx1 vy1 vz1 rN1 vN1 gx1 gy1 gz1 Ra1 Rb1 ht1 R1 sv1
%     f = [(x1^2+y1^2+z1^2-R1^2)/rN1,
%          (vx1*x1+vy1*y1+vz1*z1+sv1)/vN1,
%          ((gx1+x1)^2+(gy1+y1)^2)/(Ra1+ht1)^2+(gz1+z1)^2/(Rb1)^2-1];
%     
%     J = jacobian(f,[x1 y1 z1]);
%     F = matlabFunction(J);
%     
%     res = F(Ra,Rb,gx,gy,gz,ht,rN,vN,vx,vy,vz,x3d(1),x3d(2),x3d(3));
%     C = cond(res);
%     f = matlabFunction(J);
%     J = jacobian(f);
%     C = cond(J)
% Luo condition number
%     syms x1 y1 z1 vx1 vy1 vz1 rN1 vN1 gx1 gy1 gz1 Ra1 Rb1 ht1 R1 sv1
%     f = [(x1^2+y1^2+z1^2-R1^2)/rN1,
%          (vx1*x1+vy1*y1+vz1*z1+sv1)/vN1];
%     
%     J = jacobian(f,[x1 y1]);
%     F = matlabFunction(J);
%     
%     res = F(rN,vN,vx,vy,x3d(1),x3d(2));
%     C = cond(res);
%     f = matlabFunction(J);
%     J = jacobian(f);
%     C = cond(J)
    
    xt = gx + x3d(1);
    yt = gy + x3d(2);
    zt = gz + x3d(3);
    [latT,lonT,hpT] = ecef2geodetic(wgs84,xt,yt,zt);
    f(x3d); % Verify numerical solution error
end