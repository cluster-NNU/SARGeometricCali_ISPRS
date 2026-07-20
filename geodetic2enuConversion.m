function enuCaliGCPInfoList = geodetic2enuConversion(caliGCPInfoList, ellipsoid)
% Convert geodetic coordinates in caliGCPInfoList to ENU coordinate system using the first satellite record as ENU origin
% Input:
%   caliGCPInfoList: Nx12 matrix, columns 1-3 are satellite [lon, lat, alt], columns 8-10 are GCP [lon, lat, alt]
%   ellipsoid: Earth ellipsoid object, e.g. wgs84Ellipsoid('meter');
% Output:
%   enuCaliGCPInfoList: Same structure as caliGCPInfoList, satellite and GCP positions converted to ENU coordinates

    % Use first satellite record as ENU origin
    refLon = caliGCPInfoList(1, 1);
    refLat = caliGCPInfoList(1, 2);
    refAlt = caliGCPInfoList(1, 3);
    
    enuCaliGCPInfoList = caliGCPInfoList;  % Initialize output

    for i = 1:size(caliGCPInfoList,1)
        % Satellite coordinate conversion
        sat_lon = caliGCPInfoList(i, 1);
        sat_lat = caliGCPInfoList(i, 2);
        sat_alt = caliGCPInfoList(i, 3);
        [e_sat, n_sat, u_sat] = geodetic2enu(sat_lat, sat_lon, sat_alt, refLat, refLon, refAlt, ellipsoid);
        
        % GCP coordinate conversion
        cp_lon = caliGCPInfoList(i, 8);
        cp_lat = caliGCPInfoList(i, 9);
        cp_alt = caliGCPInfoList(i, 10);
        [e_cp, n_cp, u_cp] = geodetic2enu(cp_lat, cp_lon, cp_alt, refLat, refLon, refAlt, ellipsoid);

        % Update output: replace satellite and GCP positions with ENU coordinates
        enuCaliGCPInfoList(i, 1:3) = [e_sat, n_sat, u_sat];
        enuCaliGCPInfoList(i, 8:10) = [e_cp, n_cp, u_cp];
    end
end
