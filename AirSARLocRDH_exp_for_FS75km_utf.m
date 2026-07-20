%% Airborne SAR direct geolocation based on calibrated geometric parameters
% For Zhanjiang 90km region, verify slant range systematic error
% July 21, for 80km region, verify slant range systematic error
% May 25, new RHD geolocation model
% Compute correction parameters from GCPs, then perform RD and RH geolocation;
% Modifications mainly for RH geolocation model;
% 

%% Read data
clc
clear
close all

fprintf('============================================================\n');
fprintf('  WARNING: Required inputs for this program (FS 75km)\n');
fprintf('============================================================\n');
fprintf('  1. DEM file: Copernicus DEM GeoTIFF (实验区域CopDEM.tif)\n');
fprintf('  2. Check point folder: FSB/CP/\n');
fprintf('  3. Function libraries: ./function_pcode/ and ./function_pcode/compare_method/\n');
fprintf('  4. flightModel / flightAngle / RadarDirection\n');
fprintf('  5. PicNumList: Image index list (default: [1])\n');
fprintf('  6. GCPList: Number of check points per image (default: [10])\n');
fprintf('  7. CaliParam (range & azimuth bias) from calibration step\n');
fprintf('  Please verify all paths, parameters and data before proceeding.\n');
fprintf('============================================================\n\n');

dbstop if error
delete *.csv

addpath(".\function_pcode\")
addpath(".\function_pcode\compare_method\")
% delete locationResult.csv

% Set MATLAB output format
format long

% Define Earth ellipsoid
wgs84 = wgs84Ellipsoid('meter');  % Define WGS84 reference ellipsoid
flightModel = 2;                  % Maneuvering target group=1, mountain=3, multi-target=2
flightAngle = 243.22;             % Aircraft heading angle (degrees):84.9407959
RadarDirection = 0;               % Left-looking=0, right-looking=1

[DEM,DEMR] = geotiffread("D:/a_workStation_Space//0_a_Data_Center_RD/几何定标/实验区域CopDEM.tif");  % Read DEM

PicNumList = [1];    % Image index
GCPList = [10];           % Number of check points per image

% original
CaliParam_ori.range = 0;
CaliParam_ori.azimuth = 0;

% RD 
CaliParam_SQRD.range = 89.48;
CaliParam_SQRD.azimuth = -26.15; 

% VC
CaliParam_VC.range = 89.30;
CaliParam_VC.azimuth = 1.22; 

% our method
CaliParam_our.range = 89.48;
CaliParam_our.azimuth = -32.46; 

for i = 1:length(PicNumList)
    picNum = PicNumList(i);
    gcpR = GCPList(i);
    pathView = 'D:/a_workStation_Space//0_a_Data_Center_RD/几何定标/佛山75km定位/CP/';
    % SARlocationAuto(picNum,gcp,flightModel);
    for gcp = 1:gcpR
        SARlocationAuto_s_original(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam_ori,pathView);
        SARlocationAuto_s_our(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam_our,pathView);
        SARlocationAuto_s_RD(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam_SQRD,pathView);
        SARlocationAuto_s_VC(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam_VC,pathView);
    end
    % close all
end

% Output geolocation result table
% delete RangeLocationResult.csv AmziLocationResult.csv TotalLocationResult.csv
LocResultProcess()

disp('Processing complete!')


function SARlocationAuto_s_our(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
% Read first-look data
    % pathView = ['**',num2str(picNum),'/'];
    % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
    % Read data
    [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
    % Data preprocessing
    [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
        ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);

    %% Parameter correction
    sv = 0; %-17000
    % True elevation of target
    GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
    Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);

    %% Directly estimate initial target position
    % (Significantly improves speed 20'->3' (6000p), slightly reduces geolocation accuracy)
    [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % Determine initial target position   
    GCPResultLocinit = [latInit,lonInit,hp];
    GCPResultLoc = GCPResultLocinit;
    disp('Fast geolocation before platform parameter correction');
    % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
    
    %% RDE iterative geolocation
    HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % Read elevation value
    [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
    disp('RDE method')

    GCPResultLoc = [latT,lonT,hpT];
    delta_H = 100;             % Set initial elevation difference
    flag = 1;
    while abs(delta_H) >= 1|flag<4
        HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
        GCPResultLoc = [latT,lonT,hpT];
        HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
        delta_H = HEnd - HInit;
        flag = flag + 1;
        if flag>20 % Prevent infinite loop
            break
        end
    end
    disp('RDE iterative method with DEM')
    ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,3104,flightAngle,RadarDirection);
    RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,3104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % Estimate ranging error

    clear latT lonT hpT 
    %% RDE geolocation with ERA5 data and ray-tracing tropospheric delay
    % hp_ = hp;
    hp_ = hp;              % Assumed elevation for tropospheric delay computation 1300
    % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % Compute tropospheric delay
    % R_temp = R-TroDelay_R;                                                  % Apply slant range tropospheric delay correction   

    csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
    MeteorData = readtable(csvFilePath);
    RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
    TroDelay_R = RayTracing.r3_total;
    R_temp = R-TroDelay_R;  

    HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % Read elevation based on fast initial geolocation result
    [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
    GCPResultLoc = [latT,lonT,hpT];
    
    delta_H = 100;             % Set initial elevation difference
    flag = 1;
    while abs(delta_H) >= 1|flag<10
        HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % Read elevation based on position, iterative update
        % Compute tropospheric delay with updated elevation
        RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % Compute tropospheric delay with new elevation
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;                                          % Update slant range after tropospheric delay compensation
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % Read elevation based on updated position
        % Compute difference between original and updated elevation
        delta_H = HEnd - HInit;
        flag = flag + 1;
        if flag>20 % Prevent infinite loop
            break
        end
    end
    disp('ERA5 ray-tracing tropospheric delay compensation with DEM')
    ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,3669,flightAngle,RadarDirection);
    RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,3669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % Estimate ranging error
    clear latT lonT hpT
end


function SARlocationAuto_s_RD(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
    % Read first-look data
        % pathView = ['**',num2str(picNum),'/'];
        % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
        % Read data
        [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
        % Data preprocessing
        [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
            ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);
    
        %% Parameter correction
        sv = 0; %-17000
        % True elevation of target
        GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
        Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
        %% Directly estimate initial target position
        % (Significantly improves speed 20'->3' (6000p), slightly reduces geolocation accuracy)
        [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % Determine initial target position   
        GCPResultLocinit = [latInit,lonInit,hp];
        GCPResultLoc = GCPResultLocinit;
        disp('Fast geolocation before platform parameter correction');
        % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
        
        %% RDE iterative geolocation
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % Read elevation value
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
        disp('RDE method')
    
        GCPResultLoc = [latT,lonT,hpT];
        delta_H = 100;             % Set initial elevation difference
        flag = 1;
        while abs(delta_H) >= 1|flag<4
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % Prevent infinite loop
                break
            end
        end
        disp('RDE iterative method with DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,1104,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,1104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % Estimate ranging error
    
        clear latT lonT hpT 
        %% RDE geolocation with ERA5 data and ray-tracing tropospheric delay
        % hp_ = hp;
        hp_ = hp;              % Assumed elevation for tropospheric delay computation 1300
        % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % Compute tropospheric delay
        % R_temp = R-TroDelay_R;                                                  % Apply slant range tropospheric delay correction   
    
        csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
        MeteorData = readtable(csvFilePath);
        RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;  
    
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % Read elevation based on fast initial geolocation result
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        
        delta_H = 100;             % Set initial elevation difference
        flag = 1;
        while abs(delta_H) >= 1|flag<10
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % Read elevation based on position, iterative update
            % Compute tropospheric delay with updated elevation
            RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % Compute tropospheric delay with new elevation
            TroDelay_R = RayTracing.r3_total;
            R_temp = R-TroDelay_R;                                          % Update slant range after tropospheric delay compensation
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % Read elevation based on updated position
            % Compute difference between original and updated elevation
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % Prevent infinite loop
                break
            end
        end
        disp('ERA5 ray-tracing tropospheric delay compensation with DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,1669,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,1669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % Estimate ranging error
        clear latT lonT hpT
    end

function SARlocationAuto_s_VC(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
    % Read first-look data
        % pathView = ['**',num2str(picNum),'/'];
        % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
        % Read data
        [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
        % Data preprocessing
        [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
            ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);
    
        %% Parameter correction
        sv = 0; %-17000
        % True elevation of target
        GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
        Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
        %% Directly estimate initial target position
        % (Significantly improves speed 20'->3' (6000p), slightly reduces geolocation accuracy)
        [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % Determine initial target position   
        GCPResultLocinit = [latInit,lonInit,hp];
        GCPResultLoc = GCPResultLocinit;
        disp('Fast geolocation before platform parameter correction');
        % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
        
        %% RDE iterative geolocation
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % Read elevation value
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
        disp('RDE method')
    
        GCPResultLoc = [latT,lonT,hpT];
        delta_H = 100;             % Set initial elevation difference
        flag = 1;
        while abs(delta_H) >= 1|flag<4
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % Prevent infinite loop
                break
            end
        end
        disp('RDE iterative method with DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,2104,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,2104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % Estimate ranging error
    
        clear latT lonT hpT 
        %% RDE geolocation with ERA5 data and ray-tracing tropospheric delay
        % hp_ = hp;
        hp_ = hp;              % Assumed elevation for tropospheric delay computation 1300
        % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % Compute tropospheric delay
        % R_temp = R-TroDelay_R;                                                  % Apply slant range tropospheric delay correction   
    
        csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
        MeteorData = readtable(csvFilePath);
        RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;  
    
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % Read elevation based on fast initial geolocation result
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        
        delta_H = 100;             % Set initial elevation difference
        flag = 1;
        while abs(delta_H) >= 1|flag<10
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % Read elevation based on position, iterative update
            % Compute tropospheric delay with updated elevation
            RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % Compute tropospheric delay with new elevation
            TroDelay_R = RayTracing.r3_total;
            R_temp = R-TroDelay_R;                                          % Update slant range after tropospheric delay compensation
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % Read elevation based on updated position
            % Compute difference between original and updated elevation
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % Prevent infinite loop
                break
            end
        end
        disp('ERA5 ray-tracing tropospheric delay compensation with DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,2669,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,2669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % Estimate ranging error
        clear latT lonT hpT
    end

    function SARlocationAuto_s_original(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
    % Read first-look data
        % pathView = ['**',num2str(picNum),'/'];
        % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
        % Read data
        [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
        % Data preprocessing
        [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
            ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);
    
        %% Parameter correction
        sv = 0; %-17000
        % True elevation of target
        GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
        Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
        %% Directly estimate initial target position
        % (Significantly improves speed 20'->3' (6000p), slightly reduces geolocation accuracy)
        [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % Determine initial target position   
        GCPResultLocinit = [latInit,lonInit,hp];
        GCPResultLoc = GCPResultLocinit;
        disp('Fast geolocation before platform parameter correction');
        % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
        
        %% RDE iterative geolocation
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % Read elevation value
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
        disp('RDE method')
    
        GCPResultLoc = [latT,lonT,hpT];
        delta_H = 100;             % Set initial elevation difference
        flag = 1;
        while abs(delta_H) >= 1|flag<4
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % Read elevation value
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % Prevent infinite loop
                break
            end
        end
        disp('RDE iterative method with DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,104,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % Estimate ranging error
    
        clear latT lonT hpT 
        %% RDE geolocation with ERA5 data and ray-tracing tropospheric delay
        % hp_ = hp;
        hp_ = hp;              % Assumed elevation for tropospheric delay computation 1300
        % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % Compute tropospheric delay
        % R_temp = R-TroDelay_R;                                                  % Apply slant range tropospheric delay correction   
    
        csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
        MeteorData = readtable(csvFilePath);
        RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;  
    
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % Read elevation based on fast initial geolocation result
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        
        delta_H = 100;             % Set initial elevation difference
        flag = 1;
        while abs(delta_H) >= 1|flag<10
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % Read elevation based on position, iterative update
            % Compute tropospheric delay with updated elevation
            RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % Compute tropospheric delay with new elevation
            TroDelay_R = RayTracing.r3_total;
            R_temp = R-TroDelay_R;                                          % Update slant range after tropospheric delay compensation
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % Read elevation based on updated position
            % Compute difference between original and updated elevation
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % Prevent infinite loop
                break
            end
        end
        disp('ERA5 ray-tracing tropospheric delay compensation with DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,669,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % Estimate ranging error
        clear latT lonT hpT
    end