%% 基于校正几何参数的机载SAR直接定位
% 用于湛江90km区域，验证斜距系统误差
% 7月21日，用于80km区域，验证斜距系统误差
% 5月25日，新建立RHD定位模型
% 通过控制点计算校正参数，并利用改正参数进行RD定位，RH定位；
% 修改主要用于RH定位模型；
% 

%% 读取数据
clc
clear
close all

dbstop if error
delete *.csv

addpath(".\function\")
addpath(".\function\compare_method\")
% delete locationResult.csv

% 定义matlab输出形式
format long

% 定义地球椭球
wgs84 = wgs84Ellipsoid('meter');  % 定义参考椭球 WGS84
flightModel = 2;                  % 机动目标群=1、山地=3， 多目标点=2
flightAngle = 243.22;             % 飞机航向角(度):84.9407959
RadarDirection = 0;               % 左侧视=0，右侧视=1

[DEM,DEMR] = geotiffread("D:/a_workStation_Space//0_a_Data_Center_RD/几何定标/实验区域CopDEM.tif");  % 读取DEM

PicNumList = [1];    % 图片名称
GCPList = [10];           % 单图检查点数

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

% 输出定位结果表
% delete RangeLocationResult.csv AmziLocationResult.csv TotalLocationResult.csv
LocResultProcess()

disp('处理完毕！')


function SARlocationAuto_s_our(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
% 读取第一视数据
    % pathView = ['F:\a_机载SAR图像目标定位技术\马兰SAR图像及参数文件\新疆70km条带\条带',num2str(picNum),'/'];
    % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
    % 读取数据
    [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
    % 数据预处理
    [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
        ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);

    %% 参数校正
    sv = 0; %-17000
    % 目标真实高程
    GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
    Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);

    %% 直接估计目标初始位置
    % (大幅提高速度20'->3'(6000p)，略微降低定位精度)
    [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % 确定目标初始位置   
    GCPResultLocinit = [latInit,lonInit,hp];
    GCPResultLoc = GCPResultLocinit;
    disp('载机参数较正前快速定位');
    % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
    
    %% RDE 迭代定位
    HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % 读取高程值
    [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
    disp('RDE方法')

    GCPResultLoc = [latT,lonT,hpT];
    delta_H = 100;             % 设定高程差初始值
    flag = 1;
    while abs(delta_H) >= 1|flag<4
        HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
        GCPResultLoc = [latT,lonT,hpT];
        HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
        delta_H = HEnd - HInit;
        flag = flag + 1;
        if flag>20 % 避免死循环
            break
        end
    end
    disp('RDE迭代方法 DEM')
    ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,3104,flightAngle,RadarDirection);
    RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,3104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % 估计测距误差

    clear latT lonT hpT 
    %% RDE定位应用ERA5数据和射线追踪的对流层延迟
    % hp_ = hp;
    hp_ = hp;              % 假定对流层延迟计算高程 1300
    % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % 计算对流层延迟
    % R_temp = R-TroDelay_R;                                                  % 进行斜距对流层延迟改正   

    csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
    MeteorData = readtable(csvFilePath);
    RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
    TroDelay_R = RayTracing.r3_total;
    R_temp = R-TroDelay_R;  

    HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % 根据快速的初始定位结果读取高程值
    [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
    GCPResultLoc = [latT,lonT,hpT];
    
    delta_H = 100;             % 设定高程差初始值
    flag = 1;
    while abs(delta_H) >= 1|flag<10
        HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % 根据位置读取高程值，循环更新
        % 根据更新的高程值计算对流层延迟
        RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % 使用新的高程值计算对流层延迟
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;                                          % 更新对流层延迟补偿后的斜距
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % 根据更新后的位置，读取高程值
        % 计算原始高程与更新后的高程之差
        delta_H = HEnd - HInit;
        flag = flag + 1;
        if flag>20 % 避免死循环
            break
        end
    end
    disp('ERA5射线追踪对流层延迟补偿方法 DEM')
    ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,3669,flightAngle,RadarDirection);
    RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,3669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % 估计测距误差
    clear latT lonT hpT
end


function SARlocationAuto_s_RD(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
    % 读取第一视数据
        % pathView = ['F:\a_机载SAR图像目标定位技术\马兰SAR图像及参数文件\新疆70km条带\条带',num2str(picNum),'/'];
        % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
        % 读取数据
        [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
        % 数据预处理
        [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
            ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);
    
        %% 参数校正
        sv = 0; %-17000
        % 目标真实高程
        GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
        Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
        %% 直接估计目标初始位置
        % (大幅提高速度20'->3'(6000p)，略微降低定位精度)
        [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % 确定目标初始位置   
        GCPResultLocinit = [latInit,lonInit,hp];
        GCPResultLoc = GCPResultLocinit;
        disp('载机参数较正前快速定位');
        % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
        
        %% RDE 迭代定位
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % 读取高程值
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
        disp('RDE方法')
    
        GCPResultLoc = [latT,lonT,hpT];
        delta_H = 100;             % 设定高程差初始值
        flag = 1;
        while abs(delta_H) >= 1|flag<4
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % 避免死循环
                break
            end
        end
        disp('RDE迭代方法 DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,1104,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,1104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % 估计测距误差
    
        clear latT lonT hpT 
        %% RDE定位应用ERA5数据和射线追踪的对流层延迟
        % hp_ = hp;
        hp_ = hp;              % 假定对流层延迟计算高程 1300
        % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % 计算对流层延迟
        % R_temp = R-TroDelay_R;                                                  % 进行斜距对流层延迟改正   
    
        csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
        MeteorData = readtable(csvFilePath);
        RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;  
    
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % 根据快速的初始定位结果读取高程值
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        
        delta_H = 100;             % 设定高程差初始值
        flag = 1;
        while abs(delta_H) >= 1|flag<10
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % 根据位置读取高程值，循环更新
            % 根据更新的高程值计算对流层延迟
            RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % 使用新的高程值计算对流层延迟
            TroDelay_R = RayTracing.r3_total;
            R_temp = R-TroDelay_R;                                          % 更新对流层延迟补偿后的斜距
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % 根据更新后的位置，读取高程值
            % 计算原始高程与更新后的高程之差
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % 避免死循环
                break
            end
        end
        disp('ERA5射线追踪对流层延迟补偿方法 DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,1669,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,1669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % 估计测距误差
        clear latT lonT hpT
    end

function SARlocationAuto_s_VC(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
    % 读取第一视数据
        % pathView = ['F:\a_机载SAR图像目标定位技术\马兰SAR图像及参数文件\新疆70km条带\条带',num2str(picNum),'/'];
        % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
        % 读取数据
        [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
        % 数据预处理
        [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
            ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);
    
        %% 参数校正
        sv = 0; %-17000
        % 目标真实高程
        GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
        Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
        %% 直接估计目标初始位置
        % (大幅提高速度20'->3'(6000p)，略微降低定位精度)
        [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % 确定目标初始位置   
        GCPResultLocinit = [latInit,lonInit,hp];
        GCPResultLoc = GCPResultLocinit;
        disp('载机参数较正前快速定位');
        % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
        
        %% RDE 迭代定位
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % 读取高程值
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
        disp('RDE方法')
    
        GCPResultLoc = [latT,lonT,hpT];
        delta_H = 100;             % 设定高程差初始值
        flag = 1;
        while abs(delta_H) >= 1|flag<4
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % 避免死循环
                break
            end
        end
        disp('RDE迭代方法 DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,2104,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,2104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % 估计测距误差
    
        clear latT lonT hpT 
        %% RDE定位应用ERA5数据和射线追踪的对流层延迟
        % hp_ = hp;
        hp_ = hp;              % 假定对流层延迟计算高程 1300
        % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % 计算对流层延迟
        % R_temp = R-TroDelay_R;                                                  % 进行斜距对流层延迟改正   
    
        csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
        MeteorData = readtable(csvFilePath);
        RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;  
    
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % 根据快速的初始定位结果读取高程值
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        
        delta_H = 100;             % 设定高程差初始值
        flag = 1;
        while abs(delta_H) >= 1|flag<10
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % 根据位置读取高程值，循环更新
            % 根据更新的高程值计算对流层延迟
            RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % 使用新的高程值计算对流层延迟
            TroDelay_R = RayTracing.r3_total;
            R_temp = R-TroDelay_R;                                          % 更新对流层延迟补偿后的斜距
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % 根据更新后的位置，读取高程值
            % 计算原始高程与更新后的高程之差
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % 避免死循环
                break
            end
        end
        disp('ERA5射线追踪对流层延迟补偿方法 DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,2669,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,2669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % 估计测距误差
        clear latT lonT hpT
    end

    function SARlocationAuto_s_original(picNum,gcp,flightModel,DEM,DEMR,flightAngle,RadarDirection,CaliParam,pathView)
    % 读取第一视数据
        % pathView = ['F:\a_机载SAR图像目标定位技术\马兰SAR图像及参数文件\新疆70km条带\条带',num2str(picNum),'/'];
        % pathView = 'D:/0_a_Data_Center_RD/佛山75km定位/';
        % 读取数据
        [SarInfo1,GDn1,ObjectLoctionInfoList1] = readSARTxt(pathView);
        % 数据预处理
        [AirplanePositionLonLat,h0,hp,VENU,R,delta_z,sv,pointLocationInfo,etaC,lonF,latF,gama0,PixelSizeRange,UAV] = dataPreProcess(gcp, ...
            ObjectLoctionInfoList1, GDn1, SarInfo1, flightModel, CaliParam);
    
        %% 参数校正
        sv = 0; %-17000
        % 目标真实高程
        GCPTruthLoc = [pointLocationInfo(5),pointLocationInfo(4),0];
        Hp_t = readHeightFromDEM(GCPTruthLoc, DEM, DEMR);
    
        %% 直接估计目标初始位置
        % (大幅提高速度20'->3'(6000p)，略微降低定位精度)
        [latInit,lonInit] = objectInitLocation(UAV, AirplanePositionLonLat, R); % 确定目标初始位置   
        GCPResultLocinit = [latInit,lonInit,hp];
        GCPResultLoc = GCPResultLocinit;
        disp('载机参数较正前快速定位');
        % ErrorEvalPlot_decompose(gcp,pointLocationInfo,GCPResultLoc(1),GCPResultLoc(2),hp,101,flightAngle,RadarDirection);
        
        %% RDE 迭代定位
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR); % 读取高程值
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R,sv);
        disp('RDE方法')
    
        GCPResultLoc = [latT,lonT,hpT];
        delta_H = 100;             % 设定高程差初始值
        flag = 1;
        while abs(delta_H) >= 1|flag<4
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR); % 读取高程值
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % 避免死循环
                break
            end
        end
        disp('RDE迭代方法 DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,104,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,104,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R); % 估计测距误差
    
        clear latT lonT hpT 
        %% RDE定位应用ERA5数据和射线追踪的对流层延迟
        % hp_ = hp;
        hp_ = hp;              % 假定对流层延迟计算高程 1300
        % TroDelay_R1 = TroDelayCalculate(floor(hp_/10)*10,floor(h0/10)*10,R,7);  % 计算对流层延迟
        % R_temp = R-TroDelay_R;                                                  % 进行斜距对流层延迟改正   
    
        csvFilePath = '../ZhaoqingERA5/refractivity_data.csv';
        MeteorData = readtable(csvFilePath);
        RayTracing = AirSARRayTracingPlus(hp_, h0, R, 7, MeteorData);
        TroDelay_R = RayTracing.r3_total;
        R_temp = R-TroDelay_R;  
    
        HInit = readHeightFromDEM(GCPResultLocinit,DEM,DEMR);                   % 根据快速的初始定位结果读取高程值
        [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLocinit,h0,R_temp,sv);
        GCPResultLoc = [latT,lonT,hpT];
        
        delta_H = 100;             % 设定高程差初始值
        flag = 1;
        while abs(delta_H) >= 1|flag<10
            HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR);               % 根据位置读取高程值，循环更新
            % 根据更新的高程值计算对流层延迟
            RayTracing = AirSARRayTracingPlus(HInit+180, h0, R, 7, MeteorData); % 使用新的高程值计算对流层延迟
            TroDelay_R = RayTracing.r3_total;
            R_temp = R-TroDelay_R;                                          % 更新对流层延迟补偿后的斜距
            [latT,lonT,hpT] = RDEwithL_Mori(HInit, VENU,AirplanePositionLonLat,GCPResultLoc,h0,R_temp,sv);
            GCPResultLoc = [latT,lonT,hpT];
            HEnd = readHeightFromDEM(GCPResultLoc,DEM,DEMR);                % 根据更新后的位置，读取高程值
            % 计算原始高程与更新后的高程之差
            delta_H = HEnd - HInit;
            flag = flag + 1;
            if flag>20 % 避免死循环
                break
            end
        end
        disp('ERA5射线追踪对流层延迟补偿方法 DEM')
        ErrorEvalPlot_decompose(gcp,pointLocationInfo,latT,lonT,hp,669,flightAngle,RadarDirection);
        RangeErrorAnalysis(gcp,pointLocationInfo,latT,lonT,Hp_t,669,flightAngle,RadarDirection,AirplanePositionLonLat,h0,R_temp); % 估计测距误差
        clear latT lonT hpT
    end