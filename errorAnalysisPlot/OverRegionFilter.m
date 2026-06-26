% 区域重叠分析程序
clc; clear; close all;

% 1. 设置文件夹路径（修改为您的实际路径）
folderPath = './data/radarParams/';

% 2. 获取所有TXT文件
fileList = dir(fullfile(folderPath, '*.txt'));
numFiles = length(fileList);
if numFiles < 2
    error('至少需要2个区域文件才能比较重叠度');
end

% 3. 预分配存储空间
bboxes = zeros(numFiles, 4);  % [minLon, minLat, maxLon, maxLat]
regionNames = cell(numFiles, 1);

% 4. 处理每个区域文件
for k = 1:numFiles
    filePath = fullfile(fileList(k).folder, fileList(k).name);
    regionNames{k} = fileList(k).name(1:end-4);  % 移除.txt后缀
    
    % 初始化角点提取状态
    corners = zeros(4, 2); % [左上; 左下; 右上; 右下]
    corners_found = false(1, 4); % 标记每个角点是否已找到
    
    % 读取文件内容
    fid = fopen(filePath, 'r');
    if fid == -1
        error('无法打开文件: %s', filePath);
    end
    
    % 逐行解析文件
    while ~feof(fid)
        line = fgetl(fid);
        
        % 提取左上角坐标（只取第一次出现）
        if startsWith(line, '左上角经度(度):') && ~corners_found(1)
            corners(1,1) = sscanf(line, '左上角经度(度):%f');
            nextLine = fgetl(fid);
            corners(1,2) = sscanf(nextLine, '左上角纬度(度):%f');
            corners_found(1) = true;
        
        % 提取左下角坐标（只取第一次出现）
        elseif startsWith(line, '左下角经度(度):') && ~corners_found(2)
            corners(2,1) = sscanf(line, '左下角经度(度):%f');
            nextLine = fgetl(fid);
            corners(2,2) = sscanf(nextLine, '左下角纬度(度):%f');
            corners_found(2) = true;
        
        % 提取右上角坐标（只取第一次出现）
        elseif startsWith(line, '右上角经度(度):') && ~corners_found(3)
            corners(3,1) = sscanf(line, '右上角经度(度):%f');
            nextLine = fgetl(fid);
            corners(3,2) = sscanf(nextLine, '右上角纬度(度):%f');
            corners_found(3) = true;
        
        % 提取右下角坐标（只取第一次出现）
        elseif startsWith(line, '右下角经度(度):') && ~corners_found(4)
            corners(4,1) = sscanf(line, '右下角经度(度):%f');
            nextLine = fgetl(fid);
            corners(4,2) = sscanf(nextLine, '右下角纬度(度):%f');
            corners_found(4) = true;
        end
        
        % 如果所有角点都已找到，提前退出循环
        if all(corners_found)
            break;
        end
    end
    fclose(fid);
    
    % 验证提取的角点数量
    if ~all(corners_found)
        warning('文件 %s 中未找到所有角点：缺少 %d 个角点', ...
                fileList(k).name, sum(~corners_found));
    end
    
    % 计算最小外接矩形 (AABB)
    lons = corners(:,1);
    lats = corners(:,2);
    bboxes(k,:) = [min(lons), min(lats), max(lons), max(lats)];
end

% 5. 计算所有区域对的重叠度
numPairs = numFiles * (numFiles - 1) / 2;
pairResults = cell(numPairs, 1);
iouValues = zeros(numPairs, 1);
idx = 0;

for i = 1:numFiles-1
    for j = i+1:numFiles
        idx = idx + 1;
        
        % 计算当前区域对的IoU
        iou = bboxIoU(bboxes(i,:), bboxes(j,:));
        
        % 存储结果
        pairResults{idx} = {regionNames{i}, regionNames{j}};
        iouValues(idx) = iou;
    end
end

% 6. 按IoU降序排序
[iouSorted, sortIdx] = sort(iouValues, 'descend');
pairsSorted = pairResults(sortIdx);

% 7. 提取前20个结果
N = min(500, numPairs);
topPairs = pairsSorted(1:N);
topIou = iouSorted(1:N);

% 8. 显示结果
fprintf('\n重叠度最大的前%d个区域对：\n', N);
fprintf('%-15s %-15s %-10s\n', '区域1', '区域2', '重叠度(IoU)');
for k = 1:N
    pair = topPairs{k};
    fprintf('%-15s %-15s %.6f\n', pair{1}, pair{2}, topIou(k));
end

% 9. 保存结果为CSV文件
resultTable = table(...
    cellfun(@(x) x{1}, topPairs(1:N), 'UniformOutput', false), ...
    cellfun(@(x) x{2}, topPairs(1:N), 'UniformOutput', false), ...
    topIou(1:N), ...
    'VariableNames', {'Region1', 'Region2', 'IoU'});
writetable(resultTable, 'top_overlaps.csv');
disp('结果已保存到 top_overlaps.csv');

% --- IoU计算函数 (使用AABB近似) ---
function iou = bboxIoU(bbox1, bbox2)
    % 解析边界框: [minLon, minLat, maxLon, maxLat]
    [x1_min, y1_min, x1_max, y1_max] = deal(bbox1(1), bbox1(2), bbox1(3), bbox1(4));
    [x2_min, y2_min, x2_max, y2_max] = deal(bbox2(1), bbox2(2), bbox2(3), bbox2(4));
    
    % 计算交集区域
    inter_xmin = max(x1_min, x2_min);
    inter_ymin = max(y1_min, y2_min);
    inter_xmax = min(x1_max, x2_max);
    inter_ymax = min(y1_max, y2_max);
    
    % 检查是否有交集
    if inter_xmin >= inter_xmax || inter_ymin >= inter_ymax
        iou = 0;
        return;
    end
    
    % 计算面积
    area1 = (x1_max - x1_min) * (y1_max - y1_min);
    area2 = (x2_max - x2_min) * (y2_max - y2_min);
    inter_area = (inter_xmax - inter_xmin) * (inter_ymax - inter_ymin);
    union_area = area1 + area2 - inter_area;
    
    % 计算IoU
    iou = inter_area / union_area;
end

