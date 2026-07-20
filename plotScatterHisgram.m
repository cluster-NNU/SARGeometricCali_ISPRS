% Clear environment variables and close figure windows
clear; clc; close all;


% ================== Parameter configuration ==================
% Region a
amziFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS43_our\AmziLocationResult.csv'; 
rangeFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS43_our\RangeLocationResult.csv'; 
savePath = 'FS43_errorResult.png';


% Region b
amziFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS75_our\AmziLocationResult.csv'; 
rangeFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_FS75_our\RangeLocationResult.csv'; 
savePath = 'FS75_errorResult.png';


% Region c
amziFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_ZQ90_our\AmziLocationResult.csv'; 
rangeFile = 'd:/a_workStation_Space/\3_LW_GeometricCalibration\SARGeometricCali\Result_ZQ90_our\RangeLocationResult.csv'; 
savePath = 'ZQ90_errorResult.png';


