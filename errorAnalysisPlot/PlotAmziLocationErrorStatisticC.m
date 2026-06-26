clc
clear
close all

% Read the CSV file
data1 = readtable('./Result_FS43_our/AmziLocationResult.csv');
data2 = readtable('./Result_FS75_our/AmziLocationResult.csv');
data3 = readtable('./Result_ZQ90_our/AmziLocationResult.csv');

outputPath = './PlotStatisticFigure/AmziLocationErrorDistributionComparison_Curves';
% 如果输出目录不存在则创建
if ~exist(outputPath, 'dir')
    mkdir(outputPath);
end
% Extract method numbers and error values
methods = data1{1, :};         % First row contains method numbers

errors1 = data1{2:end-2, :};    % Second row to the third last row contain error values
errors2 = data2{2:end-2, :};    % Second row to the third last row contain error values
errors3 = data3{2:end-2, :};    % Second row to the third last row contain error values

% Stack errors1, errors2, and errors3 vertically
errors = [errors1; errors2; errors3];

% Define a brighter color map with distinct colors for each method
colorMap = [
    0.9290, 0.6940, 0.1250;  % 黄色
    0.1216, 0.4667, 0.7059;  % 蓝色
    0.8500, 0.3250, 0.0980;  % 橙色
    0.9290, 0.6940, 0.1250;  % 黄色
    0.1216, 0.4667, 0.7059;  % 蓝色
    0.8500, 0.3250, 0.0980;  % 橙色
];  % 可以根据需要添加更多颜色

colorMap1 = [0.1216, 0.4667, 0.7059]; % 蓝色
% % Determine the overall minimum and maximum error values to define the x-axis range
% allErrors = errors(:);  % Convert all error values to a single vector

% minError = min(allErrors) - 3; % Extend the range for better visibility
% maxError = max(allErrors) + 3;

% % Create a range of x values for plotting the normal distribution curves
% xValues = linspace(minError, maxError, 1000);  % 1000 points for a smooth curve

% % Define the number of bins for the histogram
% numBins = 30;

% Create a figure for each method
for i = 1:length(methods)
    % Create a new figure for the current method
    figure('Color', 'w', 'Units', 'inches', 'Position', [0, 0, 4.8, 3.6]); % 调整尺寸以适应更亮的颜色
    hold on;

    ylim([0,7])
    
    % 计算当前方法的最小值和最大值
    minError = min(errors(:, i));
    maxError = max(errors(:, i));
    
    % 判断当前方法编号（假设 methods 数组保存的就是方法编号）
    if any(methods(i) == [121, 124])
        % 针对 method121 和 124，动态计算 x 轴范围（加一定边缘 padding）
        padding = 5;
        currentXlim = [minError - padding, maxError + padding];
    else
        % 其它方法采用固定范围
        currentXlim = [-45, 45];
    end
    xlim(currentXlim);

    width = maxError - minError;
    % Create a range of x values for plotting the normal distribution curves
    xValues = linspace(minError-5, maxError+5, 1000);  % 1000 points for a smooth curve

    % Define the number of bins for the histogram
    numBins = 30;

    % Calculate mean and standard deviation for the current method
    mu = mean(errors(:, i));
    sigma = std(errors(:, i));
    
    % Compute the normal distribution PDF
    pdfValues = normpdf(xValues, mu, sigma);
    
    % Plot the histogram of errors with 'count' normalization
    hCount = histogram(errors(:, i), numBins, 'Normalization', 'count', ...
        'FaceColor', 'b', 'FaceAlpha', 0.8, 'EdgeColor', 'none'); % colorMap1
    
    % Plot the normal distribution curve (scaled to match histogram counts)
    scalingFactor = length(errors(:, i)) * (maxError - minError) / numBins;
    hCurve = plot(xValues, pdfValues * scalingFactor, 'r', 'LineWidth', 2); % 'Color', colorMap(i, :),
    
    % Plot the mean as a vertical dashed line
    plot([mu mu], [0 scalingFactor * max(pdfValues)], 'r--', 'LineWidth', 1.5);
    plot([0 0], ylim, 'g--', 'LineWidth', 1.5);
    
    % Set graph properties to meet academic paper requirements
    xlabel('Azimuth Location Error (m)', 'FontSize', 14); % 'FontName', 'Times New Roman',
    ylabel('Count', 'FontSize', 14); % 'FontName', 'Times New Roman',
    % title(sprintf('Error Distribution for Method %d', methods(i)), 'FontSize', 16, 'FontWeight', 'bold'); % 'FontName', 'Times New Roman',
    set(gca, 'FontSize', 12, 'LineWidth', 1.5); % 'FontName', 'Times New Roman',
    
    % Add grid
    grid on;
    set(gca, 'GridLineStyle', '--', 'GridColor', [0.5 0.5 0.5]);
    
    % Enhance graph aesthetics
    box on;
    set(gca, 'LineWidth', 1.5);
    
    % Add legend for [Count, Fitted Curve]
    legend([hCount, hCurve], {'Count', 'Fitted Curve'}, 'Location', 'northwest', 'FontSize', 12, 'LineWidth', 1);

    % 添加统计信息到图像上
    statsText = sprintf('Mean: %.2f m\nMin: %.2f m\nMax: %.2f m\nStd Dev: %.2f m', ...
                        mu, min(errors(:, i)), max(errors(:, i)), sigma);
                    
    % 使用归一化坐标，在所有图中都将文本框固定在同样的位置（例如：右上角）
    text(0.68, 0.94, statsText, 'Units', 'normalized', ...
         'FontSize', 12, 'Color', 'k', 'BackgroundColor', 'w', 'EdgeColor', 'k', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'Margin', 5, 'LineWidth', 1);

    % Save the figure as a high-resolution image with minimal white margins
    outputFileName = sprintf('%s_Method%d', outputPath, methods(i));
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    print(outputFileName, '-dpng', '-r300');
    
    hold off;

        
    % 输出每种method的error值的max, min, mean和std值
    fprintf('Method %d:\n', methods(i));
    fprintf('  Min Error: %.4f m\n', min(errors(:, i)));
    fprintf('  Max Error: %.4f m\n', max(errors(:, i)));
    fprintf('  Mean Error: %.4f m\n', mu);
    fprintf('  Std Dev: %.4f m\n\n', sigma);
end

% methodNames = {'Original', 'TDC-RD', 'Our'};
