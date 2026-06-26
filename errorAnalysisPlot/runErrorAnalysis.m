% 主脚本：运行误差表格生成并创建可视化
clc;
clear;
close all;

fprintf('=== SAR几何定标误差分析表格生成工具 ===\n');
fprintf('版本：1.0\n');
fprintf('功能：生成MAE、RMSE和定位误差表格\n\n');

% 运行主函数
fprintf('开始生成表格...\n');
generateErrorTables();

fprintf('\n正在创建可视化图表...\n');
createErrorVisualization();

fprintf('\n所有任务完成！\n');
fprintf('生成的文件保存在：%s\n', 'd:/a_workStation_Space/3_LW_GeometricCalibration/SARGeometricCali/');

function createErrorVisualization()
% 创建误差可视化图表
    basePath = 'd:/a_workStation_Space/3_LW_GeometricCalibration/SARGeometricCali/';
    
    % 读取CSV文件
    maeTable = readtable(fullfile(basePath, 'MAE_Comparison_Table.csv'));
    rmseTable = readtable(fullfile(basePath, 'RMSE_Comparison_Table.csv'));
    
    % 创建图形
    figure('Position', [100, 100, 1200, 800], 'Name', 'SAR定位误差分析');
    
    % MAE对比图
    subplot(2, 2, 1);
    methodNames = maeTable.Properties.VariableNames(2:end); % 跳过行名
    maeData = maeTable{:, 2:end}; % 跳过行名
    
    bar(maeData);
    title('MAE对比 (Mean Absolute Error)');
    xlabel('区域');
    ylabel('MAE (m)');
    legend(methodNames, 'Location', 'bestoutside');
    set(gca, 'XTickLabel', maeTable.Properties.RowNames);
    grid on;
    
    % RMSE对比图
    subplot(2, 2, 2);
    rmseData = rmseTable{:, 2:end}; % 跳过行名
    
    bar(rmseData);
    title('RMSE对比 (Root Mean Square Error)');
    xlabel('区域');
    ylabel('RMSE (m)');
    legend(methodNames, 'Location', 'bestoutside');
    set(gca, 'XTickLabel', rmseTable.Properties.RowNames);
    grid on;
    
    % MAE热力图
    subplot(2, 2, 3);
    imagesc(maeData);
    colorbar;
    title('MAE热力图');
    xlabel('方法');
    ylabel('区域');
    set(gca, 'XTick', 1:length(methodNames), 'XTickLabel', methodNames);
    set(gca, 'YTick', 1:length(maeTable.Properties.RowNames), 'YTickLabel', maeTable.Properties.RowNames);
    
    % RMSE热力图
    subplot(2, 2, 4);
    imagesc(rmseData);
    colorbar;
    title('RMSE热力图');
    xlabel('方法');
    ylabel('区域');
    set(gca, 'XTick', 1:length(methodNames), 'XTickLabel', methodNames);
    set(gca, 'YTick', 1:length(rmseTable.Properties.RowNames), 'YTickLabel', rmseTable.Properties.RowNames);
    
    % 保存图形
    saveas(gcf, fullfile(basePath, 'Error_Analysis_Comparison.png'));
    fprintf('可视化图表已保存：%s\n', fullfile(basePath, 'Error_Analysis_Comparison.png'));
    
    % 创建详细误差分布图
    createDetailedErrorPlots(basePath);
end

function createDetailedErrorPlots(basePath)
% 创建详细的误差分布图
    % 读取详细数据
    locationTable = readtable(fullfile(basePath, 'Location_Error_Details.csv'));
    
    % 获取唯一区域和方法
    uniqueRegions = unique(locationTable.Region);
    uniqueMethods = locationTable.Properties.VariableNames(5:12); % 方法列
    
    % 为每个区域创建子图
    numRegions = length(uniqueRegions);
    figure('Position', [100, 100, 1400, 300*numRegions], 'Name', '详细误差分布');
    
    for i = 1:numRegions
        regionName = uniqueRegions{i};
        regionData = locationTable(strcmp(locationTable.Region, regionName), :);
        
        % Amzi数据
        amziData = regionData(strcmp(regionData.Data_Type, 'Amzi'), :);
        
        % 创建子图
        subplot(numRegions, 2, 2*i-1);
        
        % 绘制箱线图
        boxData = [];
        for j = 1:length(uniqueMethods)
            methodData = amziData{:, 4+j}; % 获取方法数据
            boxData = [boxData, methodData];
        end
        
        boxplot(boxData, 'Labels', uniqueMethods);
        title(sprintf('%s - Amzi定位误差分布', regionName));
        xlabel('方法');
        ylabel('误差 (m)');
        grid on;
        
        % Range数据
        rangeData = regionData(strcmp(regionData.Data_Type, 'Range'), :);
        
        subplot(numRegions, 2, 2*i);
        
        % 绘制箱线图
        boxData = [];
        for j = 1:length(uniqueMethods)
            methodData = rangeData{:, 4+j}; % 获取方法数据
            boxData = [boxData, methodData];
        end
        
        boxplot(boxData, 'Labels', uniqueMethods);
        title(sprintf('%s - Range定位误差分布', regionName));
        xlabel('方法');
        ylabel('误差 (m)');
        grid on;
    end
    
    % 保存详细图
    saveas(gcf, fullfile(basePath, 'Detailed_Error_Distribution.png'));
    fprintf('详细误差分布图已保存：%s\n', fullfile(basePath, 'Detailed_Error_Distribution.png'));
end