function enuCaliGCPInfoList = geodetic2enuConversion(caliGCPInfoList, ellipsoid)
% 使用卫星第一条记录作为ENU原点，将caliGCPInfoList中的大地坐标转换到ENU坐标系
% 输入:
%   caliGCPInfoList: Nx12矩阵, 前3列为卫星[lon, lat, alt]，第8-10列为控制点[lon, lat, alt]
%   ellipsoid: 地球椭球对象, 如wgs84Ellipsoid('meter');
% 输出:
%   enuCaliGCPInfoList: 与caliGCPInfoList相同结构, 卫星和控制点位置转换为ENU坐标

    % 以第一条卫星记录为ENU原点
    refLon = caliGCPInfoList(1, 1);
    refLat = caliGCPInfoList(1, 2);
    refAlt = caliGCPInfoList(1, 3);
    
    enuCaliGCPInfoList = caliGCPInfoList;  % 初始化输出

    for i = 1:size(caliGCPInfoList,1)
        % 卫星坐标转换
        sat_lon = caliGCPInfoList(i, 1);
        sat_lat = caliGCPInfoList(i, 2);
        sat_alt = caliGCPInfoList(i, 3);
        [e_sat, n_sat, u_sat] = geodetic2enu(sat_lat, sat_lon, sat_alt, refLat, refLon, refAlt, ellipsoid);
        
        % 控制点坐标转换
        cp_lon = caliGCPInfoList(i, 8);
        cp_lat = caliGCPInfoList(i, 9);
        cp_alt = caliGCPInfoList(i, 10);
        [e_cp, n_cp, u_cp] = geodetic2enu(cp_lat, cp_lon, cp_alt, refLat, refLon, refAlt, ellipsoid);

        % 更新输出：将卫星和控制点位置替换为ENU坐标
        enuCaliGCPInfoList(i, 1:3) = [e_sat, n_sat, u_sat];
        enuCaliGCPInfoList(i, 8:10) = [e_cp, n_cp, u_cp];
    end
end
