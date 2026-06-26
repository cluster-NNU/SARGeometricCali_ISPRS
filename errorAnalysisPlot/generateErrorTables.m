function generateErrorTables()
% 生成三个区域的MAE、RMSE和定位误差表格并导出为CSV文件
% 清空环境变量
clc;
clear;
close all;

% ================== 配置参数 ==================
% 定义区域信息
regions = struct(...
    'FS43', struct('name', 'FS43', 'code', 'A', 'path', 'Result_FS43_our'), ...
    'FS75', struct('name', 'FS75', 'code', 'B', 'path', 'Result_FS75_our'), ...
    'ZQ90', struct('name', 'ZQ90', 'code', 'C', 'path', 'Result_ZQ90_our') ...
);

% 方法名称映射
methodNames = containers.Map();
methodNames('104') = 'Original-NT';
methodNames('669') = 'Original';
methodNames('1104') = 'RD-NT';
methodNames('1669') = 'RD';
methodNames('2104') = 'IFP-VC-NT';
methodNames('2669') = 'IFP-VC';
methodNames('3104') = 'Our-NT';
methodNames('3669') = 'Our';

% 基础路径
basePath = 'd:/a_workStation_Space/3_LW_GeometricCalibration/SARGeometricCali/';

% ================== 读取数据 ==================
fprintf('开始读取数据...\n');

allData = struct();
for regionKey = fieldnames(regions)'
    region = regions.(regionKey{1});
    fprintf('正在处理区域: %s (%s)\n', region.name, region.code);
    
    % 读取Amzi和Range定位结果
    amziFile = fullfile(basePath, region.path, 'AmziLocationResult.csv');
    rangeFile = fullfile(basePath, region.path, 'RangeLocationResult.csv');
    
    % 读取CSV文件
    amziData = readCSVWithStructure(amziFile);
    rangeData = readCSVWithStructure(rangeFile);
    
    % 存储数据
    allData.(regionKey{1}).amzi  = amziData;      % 方位向
    allData.(regionKey{1}).range = rangeData;     % 距离向
    allData.(regionKey{1}).info  = region;

    % --------- 计算平面(总)误差 ---------
    planarData = struct();
    planarData.methodIds = amziData.methodIds;
    planarData.locationErrors = sqrt(amziData.locationErrors.^2 + rangeData.locationErrors.^2);
    planarData.mae  = mean(abs(planarData.locationErrors), 1);
    planarData.rmse = sqrt(mean(planarData.locationErrors.^2, 1));
    allData.(regionKey{1}).planar = planarData;   % 平面(总)误差
end

% ================== 生成表格 ==================
fprintf('\n生成表格...\n');

% 1. MAE 表格（分别导出距离向/方位向/平面）
maeAz  = generateErrorTable(allData, methodNames, 'amzi',  'mae');
writetable(maeAz,  fullfile(pwd, 'MAE_Azimuth_Table.csv'));
maeRg  = generateErrorTable(allData, methodNames, 'range', 'mae');
writetable(maeRg,  fullfile(pwd, 'MAE_Range_Table.csv'));
maePl  = generateErrorTable(allData, methodNames, 'planar','mae');
writetable(maePl,  fullfile(pwd, 'MAE_Total_Table.csv'));
fprintf('MAE 表格已导出 (Azimuth/Range/Total)\n');

% 2. RMSE 表格（分别导出距离向/方位向/平面）
rmseAz = generateErrorTable(allData, methodNames, 'amzi',  'rmse');
writetable(rmseAz, fullfile(pwd, 'RMSE_Azimuth_Table.csv'));
rmseRg = generateErrorTable(allData, methodNames, 'range', 'rmse');
writetable(rmseRg, fullfile(pwd, 'RMSE_Range_Table.csv'));
rmsePl = generateErrorTable(allData, methodNames, 'planar','rmse');
writetable(rmsePl, fullfile(pwd, 'RMSE_Total_Table.csv'));
fprintf('RMSE 表格已导出 (Azimuth/Range/Total)\n');

% 3. 定位误差表格（包含所有数据点）
locationTable = generateLocationErrorTable(allData, methodNames);
locationFileName = fullfile(pwd, 'Location_Error_Details.csv');
writetable(locationTable, locationFileName);
fprintf('定位误差详细表格已导出: %s\n', locationFileName);

% 4. 综合统计表格
summaryTable = generateSummaryTable(allData, methodNames);
summaryFileName = fullfile(pwd, 'Error_Statistics_Summary.csv');
writetable(summaryTable, summaryFileName);
fprintf('综合统计表格已导出: %s\n', summaryFileName);

fprintf('\n所有表格生成完成！\n');

end

function data = readCSVWithStructure(filename)
% 读取CSV文件并返回结构化数据
    try
        % 读取整个文件
        rawData = readmatrix(filename);
        
        % 提取方法编号（第一行）
        methodIds = rawData(1, :);
        
        % 提取定位误差数据（第2-11行）
        locationErrors = rawData(2:11, :);
        
        % 提取MAE（第12行）
        mae = rawData(12, :);
        
        % 提取RMSE（第13行）
        rmse = rawData(13, :);
        
        % 创建结构体
        data = struct();
        data.methodIds = methodIds;
        data.locationErrors = locationErrors;
        data.mae = mae;
        data.rmse = rmse;
        
    catch ME
        error('读取文件失败 %s: %s', filename, ME.message);
    end
end

function table = generateMAETable(allData, methodNames)
% 生成MAE比较表格
    % 获取所有方法名
    methodIds = {'104', '669', '1104', '1669', '2104', '2669', '3104', '3669'};
    methodNamesList = cell(1, length(methodIds));
    for i = 1:length(methodIds)
        methodNamesList{i} = methodNames(methodIds{i});
    end
    
    % 创建表格数据
    regions = fieldnames(allData);
    maeData = zeros(length(regions), length(methodIds));
    rowNames = cell(1, length(regions));
    
    for i = 1:length(regions)
        region = allData.(regions{i});
        maeData(i, :) = region.amzi.mae;
        rowNames{i} = sprintf('%s (%s)', region.info.name, region.info.code);
    end
    
    % 创建表格
    table = array2table(maeData, 'VariableNames', methodNamesList, 'RowNames', rowNames);
    
    % 添加描述
    table.Properties.Description = 'Mean Absolute Error (MAE) Comparison Across Regions and Methods';
end

function table = generateRMSETable(allData, methodNames)
% 生成RMSE比较表格
    % 获取所有方法名
    methodIds = {'104', '669', '1104', '1669', '2104', '2669', '3104', '3669'};
    methodNamesList = cell(1, length(methodIds));
    for i = 1:length(methodIds)
        methodNamesList{i} = methodNames(methodIds{i});
    end
    
    % 创建表格数据
    regions = fieldnames(allData);
    rmseData = zeros(length(regions), length(methodIds));
    rowNames = cell(1, length(regions));
    
    for i = 1:length(regions)
        region = allData.(regions{i});
        rmseData(i, :) = region.amzi.rmse;
        rowNames{i} = sprintf('%s (%s)', region.info.name, region.info.code);
    end
    
    % 创建表格
    table = array2table(rmseData, 'VariableNames', methodNamesList, 'RowNames', rowNames);
    
    % 添加描述
    table.Properties.Description = 'Root Mean Square Error (RMSE) Comparison Across Regions and Methods';
end

function table = generateErrorTable(allData, methodNames, component, statistic)
% 通用函数：根据 component(amzi/range/planar) 与 statistic(mae/rmse) 生成表格
    % 方法名称
    methodIds = {'104', '669', '1104', '1669', '2104', '2669', '3104', '3669'};
    methodNamesList = cellfun(@(id) methodNames(id), methodIds, 'UniformOutput', false);

    regions = fieldnames(allData);
    dataMat = zeros(length(regions), length(methodIds));
    rowNames = cell(1, length(regions));

    for i = 1:length(regions)
        region = allData.(regions{i});
        dataStruct = region.(component);
        dataMat(i, :) = dataStruct.(statistic);
        rowNames{i} = sprintf('%s (%s)', region.info.name, region.info.code);
    end

    table = array2table(dataMat, 'VariableNames', methodNamesList, 'RowNames', rowNames);
    table.Properties.Description = sprintf('%s Comparison (%s)', upper(statistic), component);
end

function table = generateLocationErrorTable(allData, methodNames)
% 生成定位误差详细表格
    % 获取所有方法名
    methodIds = {'104', '669', '1104', '1669', '2104', '2669', '3104', '3669'};
    methodNamesList = cell(1, length(methodIds));
    for i = 1:length(methodIds)
        methodNamesList{i} = methodNames(methodIds{i});
    end
    
    % 收集所有数据
    allRows = {};
    regions = fieldnames(allData);
    
    for i = 1:length(regions)
        region = allData.(regions{i});
        
        % Amzi定位误差
        for pointIdx = 1:size(region.amzi.locationErrors, 1)
            rowData = {region.info.name, region.info.code, 'Amzi', sprintf('Point_%d', pointIdx), ...
                      region.amzi.locationErrors(pointIdx, :)};
            allRows{end+1} = rowData;
        end
        
        % Range定位误差
        for pointIdx = 1:size(region.range.locationErrors, 1)
            rowData = {region.info.name, region.info.code, 'Range', sprintf('Point_%d', pointIdx), ...
                      region.range.locationErrors(pointIdx, :)};
            allRows{end+1} = rowData;
        end

        % Total(Planar) 定位误差
        for pointIdx = 1:size(region.planar.locationErrors, 1)
            rowData = {region.info.name, region.info.code, 'Total', sprintf('Point_%d', pointIdx), ...
                      region.planar.locationErrors(pointIdx, :)};
            allRows{end+1} = rowData;
        end
    end
    
    % 转换为表格
    varNames = [{'Region', 'Region_Code', 'Data_Type', 'Point_ID'}, methodNamesList];
    
    % 将cell数组转换为矩阵格式
    numRows = length(allRows);
    numCols = length(varNames);
    tableData = cell(numRows, numCols);
    
    for i = 1:numRows
        rowData = allRows{i};
        tableData(i, 1:4) = rowData(1:4);
        tableData(i, 5:end) = num2cell(rowData{5});
    end
    
    table = cell2table(tableData, 'VariableNames', varNames);
    
    % 添加描述
    table.Properties.Description = 'Detailed Location Errors for All Points Across Regions and Methods';
end

function table = generateSummaryTable(allData, methodNames)
% 生成综合统计表格
    % 获取所有方法名
    methodIds = {'104', '669', '1104', '1669', '2104', '2669', '3104', '3669'};
    methodNamesList = cell(1, length(methodIds));
    for i = 1:length(methodIds)
        methodNamesList{i} = methodNames(methodIds{i});
    end
    
    % 创建表格数据
    regions = fieldnames(allData);
    summaryRows = {};
    
    for i = 1:length(regions)
        region = allData.(regions{i});
        
        % Amzi MAE数据
        rowAmziMAE = [{region.info.name, region.info.code, 'Amzi', 'MAE'}, ...
                      num2cell(region.amzi.mae)];
        summaryRows{end+1} = rowAmziMAE;
        
        % Amzi RMSE数据
        rowAmziRMSE = [{region.info.name, region.info.code, 'Amzi', 'RMSE'}, ...
                       num2cell(region.amzi.rmse)];
        summaryRows{end+1} = rowAmziRMSE;
        
        % Range MAE数据
        rowRangeMAE = [{region.info.name, region.info.code, 'Range', 'MAE'}, ...
                       num2cell(region.range.mae)];
        summaryRows{end+1} = rowRangeMAE;
        
        % Range RMSE数据
        rowRangeRMSE = [{region.info.name, region.info.code, 'Range', 'RMSE'}, ...
                        num2cell(region.range.rmse)];
        summaryRows{end+1} = rowRangeRMSE;

        % Total MAE 数据
        rowPlanarMAE = [{region.info.name, region.info.code, 'Total', 'MAE'}, ...
                        num2cell(region.planar.mae)];
        summaryRows{end+1} = rowPlanarMAE;

        % Total RMSE 数据
        rowPlanarRMSE = [{region.info.name, region.info.code, 'Total', 'RMSE'}, ...
                         num2cell(region.planar.rmse)];
        summaryRows{end+1} = rowPlanarRMSE;
    end
    
    % 创建表格
    varNames = [{'Region', 'Region_Code', 'Data_Type', 'Statistic_Type'}, methodNamesList];
    
    % 将cell数组转换为矩阵格式
    numRows = length(summaryRows);
    numCols = length(varNames);
    tableData = cell(numRows, numCols);
    
    for i = 1:numRows
        rowData = summaryRows{i};
        for j = 1:numCols
            if j <= length(rowData)
                tableData(i, j) = rowData(j);
            end
        end
    end
    
    table = cell2table(tableData, 'VariableNames', varNames);
    
    % 添加描述
    table.Properties.Description = 'Comprehensive Error Statistics Summary (MAE and RMSE)';
end