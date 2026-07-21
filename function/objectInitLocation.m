function [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R)   
% Determine target initial geographic position
% [latInit,lonInit] = objectInitLocation(UAV) 
% Assume radar is broadside-looking

    lonG = AirplanePositionLonLat(1);
    latG = AirplanePositionLonLat(2);

    flightAngle = UAV.flightAngle;  % Aircraft heading angle
    RadarDirection = UAV.CeshiFangshi; % Side-looking direction
    
    if RadarDirection == 1
        az = flightAngle+90;
    else
        az = flightAngle+270;
    end
    az = mod(az,360);
    wgs84 = wgs84Ellipsoid("meter");
    [latInit,lonInit] = reckon(latG,lonG,R,az,wgs84); % Target initial position
end