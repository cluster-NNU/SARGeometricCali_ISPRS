% 简化版本：快速生成误差分析表格
% 不包含可视化，运行速度更快
clc;
clear;

fprintf('=== SAR几何定标误差分析表格生成工具（简化版） ===\n');
fprintf('功能：快速生成MAE、RMSE表格（无可视化）\n\n');

% 运行主函数（仅生成表格）
fprintf('开始生成表格...\n');
generateErrorTables();

fprintf('\n简化版任务完成！\n');
fprintf('生成的文件保存在：%s\n', 'd:/a_workStation_Space/3_LW_GeometricCalibration/SARGeometricCali/');
fprintf('包含文件：\n');
fprintf('- MAE_Comparison_Table.csv\n');
fprintf('- RMSE_Comparison_Table.csv\n');
fprintf('- Location_Error_Details.csv\n');
fprintf('- Error_Statistics_Summary.csv\n');