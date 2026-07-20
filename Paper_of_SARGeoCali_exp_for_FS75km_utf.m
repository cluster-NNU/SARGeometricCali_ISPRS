%% Airborne SAR direct geolocation based on calibrated geometric parameters
% Using Foshan 75km area to verify slant range systematic error
% July 21, used for 80km area to verify slant range systematic error
% May 25, newly established RHD geolocation model
% 
% Compute calibration parameters using GCPs, and perform RD/RH geolocation with correction parameters;
% 
% Modifications mainly for RH geolocation model;
% 
% Original RD geolocation method;
%% Read data
clc
clear
close all

fprintf('============================================================\n');
fprintf('  WARNING: Required inputs for this program (FS 75km)\n');
fprintf('============================================================\n');
fprintf('  1. DEM file: Copernicus DEM GeoTIFF (实验区域CopDEM.tif)\n');
fprintf('  2. GCP data folder: FSB/GCP/\n');
fprintf('  3. Function libraries: ./function_pcode/ and ./function_pcode/compare_method/\n');
fprintf('  4. PicNumList: Image index list (default: [1])\n');
fprintf('  5. GCPList: Number of GCPs per image (default: [5])\n');
fprintf('  Please verify all paths and data before proceeding.\n');
fprintf('============================================================\n\n');

dbstop if error
delete *.csv

addpath(".\function_pcode\")
addpath(".\function_pcode\compare_method\")
% delete locationResult.csv

% Set MATLAB output format
format long
flightModel = 0; % placeholder (unused)
% Define Earth ellipsoid
wgs84 = wgs84Ellipsoid('meter');  % Define WGS84 reference ellipsoid
% Read DEM
[DEM, DEMR] = readgeoraster("D:/a_workStation_Space//0_a_Data_Center_RD/几何定标/实验区域CopDEM.tif");  % Read DEM
pathView = 'D:/a_workStation_Space//0_a_Data_Center_RD/几何定标/佛山75km定位/GCP/';

PicNumList = [1];    % Image index
GCPList = [5];            % Number of GCPs per image

for i = 1:length(PicNumList)
    picNum = PicNumList(i);
    gcpR = GCPList(i);
    % SARlocationAuto(picNum,gcp,flightModel);
    for gcp = 1:gcpR
        CaliGCPInfoList(gcp,:) = SARGeoCaliAuto(picNum,gcp,flightModel,DEM,DEMR,pathView);
    end
    % Check if CSV file exists, delete if so
    csvFileName = 'CaliGCPInfoList.csv';
    if exist(csvFileName, 'file')
        delete(csvFileName);
    end
    % Save CaliGCPInfoList as CSV file
    writematrix(CaliGCPInfoList, csvFileName);

    enuCaliGCPInfoList = geodetic2enuConversion(CaliGCPInfoList, wgs84); % Convert geodetic coordinates to ENU coordinate system
        % Check if CSV file exists, delete if so
    csvFileName = 'enuCaliGCPInfoList.csv';
    if exist(csvFileName, 'file')
        delete(csvFileName);
    end
    % Save CaliGCPInfoList as CSV file
    writematrix(enuCaliGCPInfoList, csvFileName);

end

%% Compute radial velocity of airborne platform relative to target
sat_positions = enuCaliGCPInfoList(:,1:3);
sat_velocities = enuCaliGCPInfoList(:,4:6);
target_positions = enuCaliGCPInfoList(:,8:10);
% Compute direction vector to target and normalize
relative_dir = target_positions - sat_positions;
unit_relative_dir = relative_dir ./ vecnorm(relative_dir, 2, 2);
% Compute radial velocity (same unit as platform velocity)
radial_velocity = sum(sat_velocities .* unit_relative_dir, 2);
fprintf('Radial velocity at each GCP:\n'); disp(radial_velocity);

%% Velocity modeling using our method
[v_fit_x, v_fit_y, v_fit_z, V_base] = velocitiesFit_our(pathView);
velocitiesModel_our.modelFit = [v_fit_x, v_fit_y, v_fit_z];
velocitiesModel_our.V_base = V_base;

%% Compute corrected radial velocity of platform relative to target
m = size(enuCaliGCPInfoList,1);  % Define m first
sat_positions = enuCaliGCPInfoList(:,1:3)-[11.45 6.96 0];
sat_velocities = repmat(velocitiesModel_our.V_base, m, 1);
target_positions = enuCaliGCPInfoList(:,8:10);
% Compute direction vector to target and normalize
relative_dir = target_positions - sat_positions;
unit_relative_dir = relative_dir ./ vecnorm(relative_dir, 2, 2);
% Compute radial velocity (same unit as platform velocity)
radial_velocity = sum(sat_velocities .* unit_relative_dir, 2);
fprintf('Corrected radial velocity at each GCP:\n'); disp(radial_velocity);

%% Compute corrected radial velocity using ground truth
m = size(enuCaliGCPInfoList,1);  % Define m first
sat_positions = enuCaliGCPInfoList(:,1:3)-[18.45 11.22 0];
sat_velocities = repmat(velocitiesModel_our.V_base, m, 1);
target_positions = enuCaliGCPInfoList(:,8:10);
% Compute direction vector to target and normalize
relative_dir = target_positions - sat_positions;
unit_relative_dir = relative_dir ./ vecnorm(relative_dir, 2, 2);
% Compute radial velocity (same unit as platform velocity)
radial_velocity = sum(sat_velocities .* unit_relative_dir, 2);
fprintf('Corrected radial velocity at each GCP:\n'); disp(radial_velocity);

%% Compute geometric calibration parameters
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


%% Velocity fitting
[v_fit_x, v_fit_y, v_fit_z] = velocitiesFit(pathView);

velocitiesModel = [v_fit_x, v_fit_y, v_fit_z];
% Compute fitted velocity
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

disp('Processing complete!')


function caliGCPInfo = SARGeoCaliAuto(picNum,gcp,flightModel,DEM,DEMR, pathView)
    % Read first-look data
    % pathView = ['**',num2str(picNum),'/'];
    PRF = 0;
    [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
    % Data preprocessing
    [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = CaliDataPreProcess(gcp, ...
        ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, PRF);

    % True elevation of target
    GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
    Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
    % Target pixel coordinates
    rangePixel = ObjectLoctionInfoList1(gcp,2);
    azimuthPixel = ObjectLoctionInfoList1(gcp,3);

    % Platform position (m×3), platform velocity (m×3), GCP position (m×3), measured slant range (m×1), radar wavelength (m), Doppler shift observation (m×1)
    caliGCPInfo = [AirplanePositionLonLat(1) AirplanePositionLonLat(2) h0 VENU(1) VENU(2) VENU(3) R pointLocationInfo(4) ...
     pointLocationInfo(5) Hp_t 0.03 0 rangePixel azimuthPixel];
end

function [coeff_x, coeff_y, coeff_z] = velocitiesFit(pathView)
    % Get 3D velocity data
    % Raw velocity data format: N×3 matrix with X/Y/Z velocity components    
    % pathView = 'D:/0_a_Data_Center_RD/肇庆定位/';
    [SarInfo1, GDn1, ~] = readSARTxt(pathView);
    GDn = GDn1(2:end,:);
    sat_velocities = GDn(:,2:4);
    Imgi = SarInfo1(5);      % Total image rows (azimuth)
    subImgi = Imgi/8;        % Sub-image rows
    t = 1:subImgi:Imgi;      % Azimuth time indices of sub-image sampling points 
    
    % First-order polynomial fitting for each component
    coeff_x = polyfit(t, sat_velocities(:,1), 1);
    coeff_y = polyfit(t, sat_velocities(:,2), 1);
    coeff_z = polyfit(t, sat_velocities(:,3), 1);
    
    % Compute fitted velocity
    % fit_x = polyval(coeff_x, t);
    % fit_y = polyval(coeff_y, t);
    % fit_z = polyval(coeff_z, t);
    
    % % Print fitting parameters
    % fprintf('X-direction velocity fit: v = %.4f*t + %.4f\n', coeff_x(1), coeff_x(2));
    % fprintf('Y-direction velocity fit: v = %.4f*t + %.4f\n', coeff_y(1), coeff_y(2));
    % fprintf('Z-direction velocity fit: v = %.4f*t + %.4f\n', coeff_z(1), coeff_z(2));
    % 
    % % Plot fitting results
    % figure;
    % subplot(3,1,1)
    % plot(t, sat_velocities(:,1), 'bo', t, fit_x, 'r-');
    % title('X-direction velocity fitting');
    % legend('Raw data', 'Fitted curve');
    % 
    % subplot(3,1,2)
    % plot(t, sat_velocities(:,2), 'go', t, fit_y, 'r-');
    % title('Y-direction velocity fitting');
    % 
    % subplot(3,1,3)
    % plot(t, sat_velocities(:,3), 'ko', t, fit_z, 'r-');
    % title('Z-direction velocity fitting');
end

function [coeff_x, coeff_y, coeff_z, V_base] = velocitiesFit_our(pathView)
    % Get 3D velocity data
    % Raw velocity data format: N×3 matrix with X/Y/Z velocity components    
    % pathView = 'D:/0_a_Data_Center_RD/肇庆定位/';
    [SarInfo1, GDn1, ~] = readSARTxt(pathView);
    GDn = GDn1(2:end,:);
    sat_velocities = GDn(:,2:4);
    Imgi = SarInfo1(5);      % Total image rows (azimuth)
    subImgi = Imgi/8;        % Sub-image rows
    t = 1:subImgi:Imgi;      % Azimuth time indices of sub-image sampling points 

    v_begin = GDn(1,2:4);
    v_end = GDn(end,2:4);
    V_base = (v_begin + v_end) / 2; % Compute the mean of two vectors
    sat_velocities_res = sat_velocities - V_base;

    % First-order polynomial fitting for each component
    coeff_x = polyfit(t, sat_velocities_res(:,1), 1);
    coeff_y = polyfit(t, sat_velocities_res(:,2), 1);
    coeff_z = polyfit(t, sat_velocities_res(:,3), 1);
    
end
