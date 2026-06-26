% 清空环境变量并关闭图形窗口
clear; clc; close all;


% ================== 参数配置 ==================
% 区域a
amziFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS43_our\AmziLocationResult.csv'; 
rangeFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS43_our\RangeLocationResult.csv'; 
savePath = 'FS43_errorResult.png';


% 区域b
amziFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS75_our\AmziLocationResult.csv'; 
rangeFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS75_our\RangeLocationResult.csv'; 
savePath = 'FS75_errorResult.png';


% 区域c
amziFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_ZQ90_our\AmziLocationResult.csv'; 
rangeFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_ZQ90_our\RangeLocationResult.csv'; 
savePath = 'ZQ90_errorResult.png';


