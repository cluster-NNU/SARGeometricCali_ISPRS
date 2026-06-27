%% 基于校正几何参数的机载SAR直接定位
% 用佛山 75km 区域，验证斜距系统误差
% 7月21日，用于80km区域，验证斜距系统误差
% 5月25日，新建立RHD定位模型
% 
% 通过控制点计算校正参数，并利用改正参数进行RD定位，RH定位；
% 
% 修改主要用于RH定位模型；
% 
% 原始RD定位方式；
%% 读取数据
clc
clear
close all

dbstop if error
delete *.csv

addpath(".\function_pcode\")
addpath(".\function_pcode\compare_method\")
% delete locationResult.csv

% 定义matlab输出形式
format long
flightModel = 0; %无意义
% 定义地球椭球
wgs84 = wgs84Ellipsoid('meter');  % 定义参考椭球 WGS84
% 读取DEM
[DEM, DEMR] = readgeoraster("D:/a_workStation_Space//0_a_Data_Center_RD/几何定标/实验区域CopDEM.tif");  % 读取DEM
pathView = 'D:/a_workStation_Space//0_a_Data_Center_RD/几何定标/佛山75km定位/GCP/';

PicNumList = [1];    % 图片名称
GCPList = [5];            % 单图检查点数

for i = 1:length(PicNumList)
    picNum = PicNumList(i);
    gcpR = GCPList(i);
    % SARlocationAuto(picNum,gcp,flightModel);
    for gcp = 1:gcpR
        CaliGCPInfoList(gcp,:) = SARGeoCaliAuto(picNum,gcp,flightModel,DEM,DEMR,pathView);
    end
    % 检查是否存在同名csv文件，若存在则删除
    csvFileName = 'CaliGCPInfoList.csv';
    if exist(csvFileName, 'file')
        delete(csvFileName);
    end
    % 将CaliGCPInfoList保存为csv文件
    writematrix(CaliGCPInfoList, csvFileName);

    enuCaliGCPInfoList = geodetic2enuConversion(CaliGCPInfoList, wgs84); % 将大地坐标转换为ENU坐标系
        % 检查是否存在同名csv文件，若存在则删除
    csvFileName = 'enuCaliGCPInfoList.csv';
    if exist(csvFileName, 'file')
        delete(csvFileName);
    end
    % 将CaliGCPInfoList保存为csv文件
    writematrix(enuCaliGCPInfoList, csvFileName);

end

%% 新增：计算机载平台相对于目标的径向速度
sat_positions = enuCaliGCPInfoList(:,1:3);
sat_velocities = enuCaliGCPInfoList(:,4:6);
target_positions = enuCaliGCPInfoList(:,8:10);
% 计算指向目标的向量，并归一化
relative_dir = target_positions - sat_positions;
unit_relative_dir = relative_dir ./ vecnorm(relative_dir, 2, 2);
% 计算径向速度（单位：与机载平台速度相同的单位）
radial_velocity = sum(sat_velocities .* unit_relative_dir, 2);
fprintf('各控制点径向速度：\n'); disp(radial_velocity);

%% 使用我们的方法进行定位
[v_fit_x, v_fit_y, v_fit_z, V_base] = velocitiesFit_our(pathView);
velocitiesModel_our.modelFit = [v_fit_x, v_fit_y, v_fit_z];
velocitiesModel_our.V_base = V_base;

%% 新增：计算修正后机载平台相对于目标的径向速度
m = size(enuCaliGCPInfoList,1);  % 先定义m
sat_positions = enuCaliGCPInfoList(:,1:3)-[11.45 6.96 0];
sat_velocities = repmat(velocitiesModel_our.V_base, m, 1);
target_positions = enuCaliGCPInfoList(:,8:10);
% 计算指向目标的向量，并归一化
relative_dir = target_positions - sat_positions;
unit_relative_dir = relative_dir ./ vecnorm(relative_dir, 2, 2);
% 计算径向速度（单位：与机载平台速度相同的单位）
radial_velocity = sum(sat_velocities .* unit_relative_dir, 2);
fprintf('修正后各控制点径向速度：\n'); disp(radial_velocity);

%% 新增：使用真值计算修正后机载平台相对于目标的径向速度
m = size(enuCaliGCPInfoList,1);  % 先定义m
sat_positions = enuCaliGCPInfoList(:,1:3)-[18.45 11.22 0];
sat_velocities = repmat(velocitiesModel_our.V_base, m, 1);
target_positions = enuCaliGCPInfoList(:,8:10);
% 计算指向目标的向量，并归一化
relative_dir = target_positions - sat_positions;
unit_relative_dir = relative_dir ./ vecnorm(relative_dir, 2, 2);
% 计算径向速度（单位：与机载平台速度相同的单位）
radial_velocity = sum(sat_velocities .* unit_relative_dir, 2);
fprintf('修正后各控制点径向速度：\n'); disp(radial_velocity);

%% 计算几何定标参数（使用SARGeoCali_RD_normal）
m = size(enuCaliGCPInfoList,1);
sat_positions_ob = enuCaliGCPInfoList(:,1:3);
sat_velocities_ob = enuCaliGCPInfoList(:,4:6);
control_points_ob = enuCaliGCPInfoList(:,8:10);
measured_ranges = enuCaliGCPInfoList(:,7);
wavelength = enuCaliGCPInfoList(1,11);
doppler_shifts_ob = enuCaliGCPInfoList(:,12);
azimuthPix = enuCaliGCPInfoList(:,14);

tic;
[range_bias, pos_bias] = SARGeoCali_RD(m, sat_positions_ob, control_points_ob, measured_ranges, sat_velocities_ob, wavelength, doppler_shifts_ob);
t_RD = toc;
fprintf('RD: range_bias = %f, pos_bias = %f, time = %f s\n', range_bias, pos_bias, t_RD);


%% 速度拟合
[v_fit_x, v_fit_y, v_fit_z] = velocitiesFit(pathView);

velocitiesModel = [v_fit_x, v_fit_y, v_fit_z];
% 计算拟合后的速度
time_idx = 3000;
sat_velocities_fit(1,1) = polyval(v_fit_x, time_idx);
sat_velocities_fit(1,2) = polyval(v_fit_y, time_idx);
sat_velocities_fit(1,3) = polyval(v_fit_z, time_idx);

tic;
[range_bias, pos_bias] = SARGeoCali_RD_VC(m, sat_positions_ob, control_points_ob, measured_ranges, sat_velocities_ob, wavelength, doppler_shifts_ob, velocitiesModel, azimuthPix);
t_RD_VC = toc;
fprintf('IFP-VC: range_bias= %f, pos_bias = %f, time = %f s\n', range_bias, pos_bias, t_RD_VC);


% [range_bias, pos_bias] = SARGeoCali_RD_normal(m, sat_positions_ob, control_points_ob, measured_ranges, sat_velocities_ob, wavelength, doppler_shifts_ob, velocitiesModel_our);
% fprintf('RD-normal: range_bias = %f, pos_bias = %f\n', range_bias, pos_bias);

tic;
[range_bias, pos_bias] = SARGeoCali_RD_our(m, sat_positions_ob, control_points_ob, measured_ranges, sat_velocities_ob, wavelength, doppler_shifts_ob, velocitiesModel_our, azimuthPix);
t_Our = toc;
fprintf('Our: range_bias= %f, pos_bias = %f, time = %f s\n', range_bias, pos_bias, t_Our);

tic;
[range_bias, pos_bias] = SARGeoCali_RD_our_iter(m, sat_positions_ob, control_points_ob, measured_ranges, sat_velocities_ob, wavelength, doppler_shifts_ob, velocitiesModel_our, azimuthPix);
t_Our_iter = toc;
fprintf('Our_iter: range_bias= %f, pos_bias = %f, time = %f s\n', range_bias, pos_bias, t_Our_iter);

tic;
[range_bias, pos_bias, solved_velocitiesModel] = SARGeoCali_RD_our_Unif(m, sat_positions_ob, control_points_ob, measured_ranges, sat_velocities_ob, wavelength, doppler_shifts_ob, velocitiesModel_our, azimuthPix);
t_Our_Unif = toc;
fprintf('Our_Unif: range_bias= %f, pos_bias = %f, time = %f s\n', range_bias, pos_bias, t_Our_Unif);

fprintf('\n--------------------------------------------------\n');
fprintf('Method Running Time Comparison:\n');
fprintf('RD:         %.3f ms\n', t_RD*1000);
fprintf('IFP-VC:     %.3f ms\n', t_RD_VC*1000);
fprintf('Our:        %.3f ms\n', t_Our*1000);
fprintf('Our_iter:   %.3f ms\n', t_Our_iter*1000);
fprintf('Our_Unif:   %.3f ms\n', t_Our_Unif*1000);
fprintf('--------------------------------------------------\n');

disp('处理完毕！')


function caliGCPInfo = SARGeoCaliAuto(picNum,gcp,flightModel,DEM,DEMR, pathView)
    % 读取第一视数据
    % pathView = ['F:\a_机载SAR图像目标定位技术\马兰SAR图像及参数文件\新疆70km条带\条带',num2str(picNum),'/'];
    PRF = 0;
    [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
    % 数据预处理
    [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = CaliDataPreProcess(gcp, ...
        ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, PRF);

    % 目标真实高程
    GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
    Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
    % 目标像素坐标
    rangePixel = ObjectLoctionInfoList1(gcp,2);
    azimuthPixel = ObjectLoctionInfoList1(gcp,3);

    % 机载平台观测位置(m×3矩阵)机载平台观测速度(m×3矩阵)控制点观测位置(m×3矩阵) 测量距离向量(m×1) 雷达波长(米) 多普勒频移观测值(m×1)
    caliGCPInfo = [AirplanePositionLonLat(1) AirplanePositionLonLat(2) h0 VENU(1) VENU(2) VENU(3) R pointLocationInfo(4) ...
     pointLocationInfo(5) Hp_t 0.03 0 rangePixel azimuthPixel];
end

function [coeff_x, coeff_y, coeff_z] = velocitiesFit(pathView)
    % 获取三维速度数据（假设存在sat_velocities变量）
    % 原始速度数据格式应为N×3矩阵：X/Y/Z速度分量    
    % pathView = 'D:/0_a_Data_Center_RD/肇庆定位/';
    [SarInfo1, GDn1, ~] = readSARTxt(pathView);
    GDn = GDn1(2:end,:);
    sat_velocities = GDn(:,2:4);
    Imgi = SarInfo1(5);      % 图像总行 (方位)
    subImgi = Imgi/8;        % 子图行数
    t = 1:subImgi:Imgi;      % 子图采样点方位时间索引 
    
    % 对每个分量进行一阶多项式拟合
    coeff_x = polyfit(t, sat_velocities(:,1), 1);
    coeff_y = polyfit(t, sat_velocities(:,2), 1);
    coeff_z = polyfit(t, sat_velocities(:,3), 1);
    
    % 计算拟合速度
    % fit_x = polyval(coeff_x, t);
    % fit_y = polyval(coeff_y, t);
    % fit_z = polyval(coeff_z, t);
    
    % % 输出拟合参数
    % fprintf('X方向速度拟合方程：v = %.4f*t + %.4f\n', coeff_x(1), coeff_x(2));
    % fprintf('Y方向速度拟合方程：v = %.4f*t + %.4f\n', coeff_y(1), coeff_y(2));
    % fprintf('Z方向速度拟合方程：v = %.4f*t + %.4f\n', coeff_z(1), coeff_z(2));
    % 
    % % 绘制拟合效果图
    % figure;
    % subplot(3,1,1)
    % plot(t, sat_velocities(:,1), 'bo', t, fit_x, 'r-');
    % title('X方向速度拟合');
    % legend('原始数据', '拟合曲线');
    % 
    % subplot(3,1,2)
    % plot(t, sat_velocities(:,2), 'go', t, fit_y, 'r-');
    % title('Y方向速度拟合');
    % 
    % subplot(3,1,3)
    % plot(t, sat_velocities(:,3), 'ko', t, fit_z, 'r-');
    % title('Z方向速度拟合');
end

function [coeff_x, coeff_y, coeff_z, V_base] = velocitiesFit_our(pathView)
    % 获取三维速度数据（假设存在sat_velocities变量）
    % 原始速度数据格式应为N×3矩阵：X/Y/Z速度分量    
    % pathView = 'D:/0_a_Data_Center_RD/肇庆定位/';
    [SarInfo1, GDn1, ~] = readSARTxt(pathView);
    GDn = GDn1(2:end,:);
    sat_velocities = GDn(:,2:4);
    Imgi = SarInfo1(5);      % 图像总行 (方位)
    subImgi = Imgi/8;        % 子图行数
    t = 1:subImgi:Imgi;      % 子图采样点方位时间索引 

    v_begin = GDn(1,2:4);
    v_end = GDn(end,2:4);
    V_base = (v_begin + v_end) / 2; % 计算两个向量的平均值
    sat_velocities_res = sat_velocities - V_base;

    % 对每个分量进行一阶多项式拟合
    coeff_x = polyfit(t, sat_velocities_res(:,1), 1);
    coeff_y = polyfit(t, sat_velocities_res(:,2), 1);
    coeff_z = polyfit(t, sat_velocities_res(:,3), 1);
    
end