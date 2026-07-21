function RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,hp,LocMethod,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R)
% Slant range accuracy evaluation, error analysis and plotting
% This function performs range error analysis and plotting for a given set of geodetic coordinates and parameters.
%
% Inputs:
%   gcp - Ground control point identifier
%   pointLocationInfo - Array containing geodetic coordinates and other information of the point location
%   latT - Latitude of the target point (in degrees)
%   lonT - Longitude of the target point (in degrees)
%   hp - Ellipsoidal height of the target point (in meters)
%   LocMethod - Localization method identifier
%   flightAngle - Flight angle of the airplane (in degrees)
%   RadarDirection - Direction of the radar (in degrees)
%   AirplanePositionLonLat - Array containing the longitude and latitude of the airplane position (in degrees)
%   h0 - Ellipsoidal height of the airplane (in meters)
%   R - Measured slant range (in meters)
%
% Outputs:
%   This function does not return any outputs. It performs calculations and displays results.
%
% Functionality:
%   1. Defines the reference ellipsoid (WGS84).
%   2. Converts geodetic coordinates to ECEF (Earth-Centered, Earth-Fixed) coordinates for the target point, ground control point, and reference point.
%   3. Calculates the true slant range between the airplane and the target point.
%   4. Computes the slant range residual.
%   5. Calculates the location errors in geodetic coordinates.
%   6. Displays the total location error, latitude error, and longitude error.
%   7. Decomposes the position error into azimuth and range components.
%   8. Plots the results for visualization and analysis.
%   9. Enhances the graph aesthetics and saves the figure as a high-resolution image.
%   10. Displays the results in the command window.


    wgs84 = wgs84Ellipsoid('meter');  % Define WGS84 reference ellipsoid
    % ecefLocResult = double([xpenu,ypenu,zpenu]);
    disp(['gcp',num2str(gcp)]);
    
    [x,y,z] = geodetic2ecef(wgs84,latT,lonT,hp);
    % disp('location Result:')
    geodeticLocResult = [latT,lonT];
    ecefLocResult = double([x,y,z]);  % RD positioning result
    
    [x,y,z] = geodetic2ecef(wgs84,pointLocationInfo(5),pointLocationInfo(4),hp);%ecefGcpResult
    % disp('Ture Result:')
    geodeticGCP = [pointLocationInfo(5),pointLocationInfo(4)]; % Latitude, longitude
    ecefGcpResult = [x,y,z];          % GCP true coordinates
    
    [x,y,z] = geodetic2ecef(wgs84,pointLocationInfo(7),pointLocationInfo(6),hp);%ecefRefResult
    % disp('image self refrence result:')
    geodeticRef = [pointLocationInfo(7),pointLocationInfo(6)];
    ecefRefResult = [x,y,z];          % Built-in geographic coordinates
    
    
    % Calculate slant range difference
    [x_a,y_a,z_a] = geodetic2ecef(wgs84,AirplanePositionLonLat(2),AirplanePositionLonLat(1),h0); % Aircraft ECEF position
    [x,y,z] = geodetic2ecef(wgs84,pointLocationInfo(5),pointLocationInfo(4),hp);                 % ecefGcpResult
    % Calculate true slant range between aircraft and target
    R_t = sqrt((x - x_a)^2 + (y - y_a)^2 + (z - z_a)^2);

    % Calculate slant range residual
    R_re = (R-R_t);

    % disp('Ture Result:')
    % geodeticGCP = [pointLocationInfo(5),pointLocationInfo(4)]; % Latitude, longitude
    % ecefGcpResult = [x,y,z];          % GCP true coordinates
    
    
    
    % Calculate coordinate differences in geodetic coordinate system
    [arclenLocTal, azLocTal] = distance(geodeticGCP,geodeticLocResult,wgs84); % total location error
    [arclenLocLon, azLocLon] = distance(geodeticGCP(1),geodeticGCP(2),geodeticLocResult(1),geodeticGCP(2),wgs84); % location error on lat 
    arclenLocLon = -sign(geodeticGCP(1)-geodeticLocResult(1))*arclenLocLon;
    [arclenLocLat, azLocLat] = distance(geodeticGCP(1),geodeticGCP(2),geodeticGCP(1),geodeticLocResult(2),wgs84); % location error on lon
    arclenLocLat = -sign(geodeticGCP(2)-geodeticLocResult(2))*arclenLocLat;
    disp(['Positioning coordinate error: total error ',num2str(arclenLocTal),'m',' x latitude error ',num2str(arclenLocLat),'m', ...
        ' y longitude error ',num2str(arclenLocLon),'m']);
    
    % Azimuth-range frame error decomposition
    % Tibet experiment, aircraft heading angle 314.4451
    positionError = [arclenLocLat arclenLocLon];
    % flightAngle = 314.4451;
    % RadarDirection = 0;
    [RangeError,AmzithError] = positionErrorDecomposition(flightAngle, positionError, RadarDirection);
    disp(['Positioning coordinate error: total error ',num2str(arclenLocTal),'m',' range error ',num2str(RangeError),'m', ...
        ' azimuth error ',num2str(AmzithError),'m']);
    
    [arclenRefTal, azRefTal] = distance(geodeticGCP,geodeticRef,wgs84); % total location error (1),geodeticGCP(2),geodeticRef(1)
    [arclenRefLon, azRefLon] = distance(geodeticGCP(1),geodeticGCP(2),geodeticRef(1),geodeticGCP(2),wgs84); % location error on lat
    arclenRefLon = -sign(geodeticGCP(1)-geodeticRef(1))*arclenRefLon;
    [arclenRefLat, azRefLat] = distance(geodeticGCP(1),geodeticGCP(2),geodeticGCP(1),geodeticRef(2),wgs84); % location error on lon
    arclenRefLat = -sign(geodeticGCP(2)-geodeticRef(2))*arclenRefLat;
    disp(['Original coordinate error: total error ',num2str(arclenRefTal),'m',' x latitude error ',num2str(arclenRefLat),'m', ...
        ' y longitude error ',num2str(arclenRefLon),'m']);
    
    
    % filename.txt is the file name to save, data is the variable in workspace
    % Create file
    data = [LocMethod,latT,lonT,pointLocationInfo(5),pointLocationInfo(4),pointLocationInfo(7),pointLocationInfo(6),arclenLocTal,RangeError,AmzithError, ...,
        arclenRefTal,arclenRefLat,arclenRefLon, R_re];
    fid=fopen('RangeErrorAnalysisResult.csv','a+');% Create file
    % Loop to write data
    for i=1:length(data)
        fprintf(fid,'%.8f,',data(i));% Save 8 decimal places
    end
    fprintf(fid,'\n');
    fclose(fid);
end

% Plotting
% figure()
% gcpPosition.Geometry = 'Point';
% locPosition.Geometry = 'Point';
% refPosition.Geometry = 'Point';
% Tcircle.Geometry = 'circle'; 
% ax = worldmap([pointLocationInfo(5)-0.002,pointLocationInfo(5)+0.002],[pointLocationInfo(4)-0.002,pointLocationInfo(4)+0.002 ...
%     ]);
% gcpPosition.Lon = pointLocationInfo(4);
% gcpPosition.Lat = pointLocationInfo(5);
% gcpPosition.Name = 'ture1';
% 
% refPosition.Lon = pointLocationInfo(6);
% refPosition.Lat = pointLocationInfo(7);
% refPosition.Name = 'ref1';
% 
% locPosition.Lon = double(lonT);%lonp;
% locPosition.Lat = double(latT);
% locPosition.Name = 'gcp1';
% 
% geoshow(locPosition,'MarkerEdgeColor','b','Marker','+','MarkerSize',10) % RD positioning coordinates
% geoshow(gcpPosition,'MarkerEdgeColor','r','Marker','*','MarkerSize',10) % True coordinates
% geoshow(refPosition,'MarkerEdgeColor','g','Marker','.','MarkerSize',10) % Image built-in geographic coordinates