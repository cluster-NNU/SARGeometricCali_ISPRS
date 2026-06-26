% 批量处理所有区域的SAR定位误差分析
% 生成综合分析报告和对比图表

clear; clc; close all;

%% ================== 参数配置 ==================
% 定义所有区域
regions = {'FS43', 'FS75', 'ZQ90'};
regionNames = {'佛山43km', '佛山75km', '肇庆90km'};

% 基础路径
basePath = 'd:/a_workStation_Space/3_LW_GeometricCalibration/SARGeometricCali';

% 存储所有区域的数据
allAmziData = cell(1, length(regions));
allRangeData = cell(1, length(regions));
allMAE = zeros(length(regions), 8);  % 8种方法
allRMSE = zeros(length(regions), 8);  % 8种方法

%% ================== 数据读取和处理 ==================
for idx = 1:length(regions)
    region = regions{idx};
    
    % 构建文件路径
    amziFile = fullfile(basePath, ['Result_' region '_our'], 'AmziLocationResult.csv');
    rangeFile = fullfile(basePath, ['Result_' region '_our'], 'RangeLocationResult.csv');
    
    % 读取CSV数据
    amziData = readtable(amziFile, 'Delimiter', ',');
    rangeData = readtable(rangeFile, 'Delimiter', ',');
    
    % 存储数据
    allAmziData{idx} = amziData;
    allRangeData{idx} = rangeData;
    
    % 提取MAE和RMSE（最后两行）
    allMAE(idx, :) = amziData{end-1, :};
    allRMSE(idx, :) = amziData{end, :};
end

% 提取方法名
methodNames = allAmziData{1}.Properties.VariableNames;

%% ================== 图形绘制 ==================

% 1. 创建综合对比图
figure('Position', [50, 50, 1400, 1000], 'Color', 'w');

% 设置颜色映射
colors = lines(8);

% MAE对比条形图
subplot(2, 2, 1);
barData = allMAE;  % 3×8矩阵
bar(barData', 'FaceColor', 'flat');
colormap(colors);
xticklabels(regionNames);
ylabel('MAE (m)', 'FontSize', 12, 'FontWeight', 'bold');
title('不同区域MAE对比', 'FontSize', 14, 'FontWeight', 'bold');
legend(methodNames, 'Location', 'bestoutside', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 10);

% RMSE对比条形图
subplot(2, 2, 2);
barData = allRMSE;  % 3×8矩阵
bar(barData', 'FaceColor', 'flat');
colormap(colors);
xticklabels(regionNames);
ylabel('RMSE (m)', 'FontSize', 12, 'FontWeight', 'bold');
title('不同区域RMSE对比', 'FontSize', 14, 'FontWeight', 'bold');
legend(methodNames, 'Location', 'bestoutside', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 10);

% MAE热力图
subplot(2, 2, 3);
imagesc(allMAE);
colorbar;
ylabel('区域', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('方法', 'FontSize', 12, 'FontWeight', 'bold');
title('MAE热力图', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YTick', 1:length(regions), 'YTickLabel', regionNames);
set(gca, 'XTick', 1:length(methodNames), 'XTickLabel', methodNames);
set(gca, 'FontSize', 10);
rotateXLabels(gca, 45);

% RMSE热力图
subplot(2, 2, 4);
imagesc(allRMSE);
colorbar;
ylabel('区域', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('方法', 'FontSize', 12, 'FontWeight', 'bold');
title('RMSE热力图', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YTick', 1:length(regions), 'YTickLabel', regionNames);
set(gca, 'XTick', 1:length(methodNames), 'XTickLabel', methodNames);
set(gca, 'FontSize', 10);
rotateXLabels(gca, 45);

% 总标题
sgtitle('SAR定位误差综合分析', 'FontSize', 16, 'FontWeight', 'bold');

% 保存综合对比图
saveas(gcf, 'allRegions_comprehensive_analysis.png');
fprintf('综合对比图已保存为: allRegions_comprehensive_analysis.png\n');

%% 2. 为每个区域生成详细分析图
for idx = 1:length(regions)
    region = regions{idx};
    regionName = regionNames{idx};
    
    % 获取当前区域的数据
    amziData = allAmziData{idx};
    rangeData = allRangeData{idx};
    
    % 提取误差数据
    amziErrors = amziData{2:end-2, :};
    rangeErrors = rangeData{2:end-2, :};
    
    % 获取数据维度
    [numPoints, ~] = size(amziErrors);
    
    % 创建详细分析图
    figure('Position', [100+idx*50, 100+idx*50, 1200, 800], 'Color', 'w');
    
    % 方位向误差散点图
    subplot(2, 2, 1);
    hold on;
    for i = 1:length(methodNames)
        scatter(1:numPoints, amziErrors(:, i), 50, colors(i,:), 'filled', ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 0.8);
    end
    xlabel('控制点编号', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('方位向误差 (m)', 'FontSize', 12, 'FontWeight', 'bold');
    title([regionName, ' - 方位向定位误差散点图'], 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend(methodNames, 'Location', 'bestoutside', 'FontSize', 10);
    set(gca, 'FontSize', 10);
    
    % 距离向误差散点图
    subplot(2, 2, 2);
    hold on;
    for i = 1:length(methodNames)
        scatter(1:numPoints, rangeErrors(:, i), 50, colors(i,:), 'filled', ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 0.8);
    end
    xlabel('控制点编号', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('距离向误差 (m)', 'FontSize', 12, 'FontWeight', 'bold');
    title([regionName, ' - 距离向定位误差散点图'], 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend(methodNames, 'Location', 'bestoutside', 'FontSize', 10);
    set(gca, 'FontSize', 10);
    
    % 误差分布直方图（叠加显示）
    subplot(2, 2, 3);
    hold on;
    for i = 1:length(methodNames)
        histogram(amziErrors(:, i), 'BinWidth', 2, 'FaceColor', colors(i,:), ...
            'FaceAlpha', 0.5, 'EdgeColor', colors(i,:));
    end
    xlabel('方位向误差 (m)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('频数', 'FontSize', 12, 'FontWeight', 'bold');
    title([regionName, ' - 方位向误差分布'], 'FontSize', 14, 'FontWeight', 'bold');
    legend(methodNames, 'Location', 'bestoutside', 'FontSize', 10);
    grid on;
    set(gca, 'FontSize', 10);
    
    % 误差分布直方图（距离向）
    subplot(2, 2, 4);
    hold on;
    for i = 1:length(methodNames)
        histogram(rangeErrors(:, i), 'BinWidth', 2, 'FaceColor', colors(i,:), ...
            'FaceAlpha', 0.5, 'EdgeColor', colors(i,:));
    end
    xlabel('距离向误差 (m)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('频数', 'FontSize', 12, 'FontWeight', 'bold');
    title([regionName, ' - 距离向误差分布'], 'FontSize', 14, 'FontWeight', 'bold');
    legend(methodNames, 'Location', 'bestoutside', 'FontSize', 10);
    grid on;
    set(gca, 'FontSize', 10);
    
    % 总标题
    sgtitle([regionName, '区域 - 详细误差分析'], 'FontSize', 16, 'FontWeight', 'bold');
    
    % 保存详细分析图
    saveas(gcf, [region '_detailed_analysis.png']);
    fprintf('%s区域详细分析图已保存为: %s_detailed_analysis.png\n', regionName, region);
end

%% ================== 生成统计报告 ==================
fprintf('\n=== SAR定位误差统计报告 ===\n');
fprintf('%-12s', '区域');
for i = 1:length(methodNames)
    fprintf('%12s', methodNames{i});
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 12 + 12*length(methodNames)));

% MAE统计
fprintf('\nMAE统计 (单位: m):\n');
for idx = 1:length(regions)
    fprintf('%-12s', regionNames{idx});
    for i = 1:length(methodNames)
        fprintf('%12.4f', allMAE(idx, i));
    end
    fprintf('\n');
end

% RMSE统计
fprintf('\nRMSE统计 (单位: m):\n');
for idx = 1:length(regions)
    fprintf('%-12s', regionNames{idx});
    for i = 1:length(methodNames)
        fprintf('%12.4f', allRMSE(idx, i));
    end
    fprintf('\n');
end

% 最佳方法分析
fprintf('\n=== 最佳方法分析 ===\n');
for idx = 1:length(regions)
    [~, bestMAEIdx] = min(allMAE(idx, :));
    [~, bestRMSEIdx] = min(allRMSE(idx, :));
    fprintf('%s区域: 最佳MAE方法 - %s (%.4f m), 最佳RMSE方法 - %s (%.4f m)\n', ...
        regionNames{idx}, methodNames{bestMAEIdx}, allMAE(idx, bestMAEIdx), ...
        methodNames{bestRMSEIdx}, allRMSE(idx, bestRMSEIdx));
end

fprintf('\n分析完成！所有图形已保存。\n');

%% 辅助函数：旋转X轴标签
function rotateXLabels(ax, angle)
    % 获取当前X轴标签
    labels = get(ax, 'XTickLabel');
    if isempty(labels)
        return;
    end
    % 旋转标签
    set(ax, 'XTickLabel', labels, 'XTickLabelRotation', angle);
end