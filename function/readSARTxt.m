function [SarInfo,GDn,ObjectLoctionInfoList] = readSARTxt(path)
%  READSARTXT Read airborne SAR parameter file
% 
% path is way of the fold of SAR text content.
    SarInfo = readmatrix(strcat(path,"SARinfo.txt")); % Read radar parameter information
    GDn = readmatrix(strcat(path,"GDinfo.txt"));      % Read inertial navigation information
    ObjectLoctionInfoList = readmatrix(strcat(path,"objectLocationInfo.csv")); % Reference point position information
end