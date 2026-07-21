function LocResultProcess()
    % Read CSV file
    data = readtable('locationResult.csv', 'Delimiter', ',');
    
    % Extract the first column and column I (set I as column 9)
    I = 9; % column 8 is total error, column 9 is range error, column 10 is azimuth error
    extractedData = data(:, [1, I]);
    
    % Remove rows where column I is empty
    extractedData = extractedData(~isnan(extractedData{:, 2}), :);
    
    % Get unique IDs
    uniqueIDs = unique(extractedData{:, 1});
    
    % Create a new table with IDs as column names
    newTable = array2table(NaN(height(extractedData), length(uniqueIDs)), 'VariableNames', cellstr(num2str(uniqueIDs)));
    
    % Fill the new table
    for idx = 1:length(uniqueIDs)
        id = uniqueIDs(idx);
        rows = extractedData{extractedData{:, 1} == id, 2};
        newTable{1:length(rows), idx} = rows;
    end
    
    % Remove rows containing NaN
    newTable = newTable(~all(ismissing(newTable), 2), :);
    
    % Calculate mean and standard deviation for each column
    meanValues = mean(abs(newTable{:,:}), 'omitnan'); 
    % stdValues = std(newTable{:,:}, 'omitnan');
    % Calculate RMSE (root mean square of each column)
    rmsValues = sqrt(mean(newTable{:,:}.^2, 'omitnan')); % 

    
    % Append mean and std to the last two rows of the table
    newTable{end+1, :} = meanValues;
    newTable{end+1, :} = rmsValues;
    
    % Save the new table
    writetable(newTable, 'RangeLocationResult.csv');


    % Extract the first column and column I (set I as column 8)
    I = 8; % column 8 is total error, column 9 is range error, column 10 is azimuth error
    extractedData = data(:, [1, I]);
    
    % Remove rows where column I is empty
    extractedData = extractedData(~isnan(extractedData{:, 2}), :);
    
    % Get unique IDs
    uniqueIDs = unique(extractedData{:, 1});
    
    % Create a new table with IDs as column names
    newTable = array2table(NaN(height(extractedData), length(uniqueIDs)), 'VariableNames', cellstr(num2str(uniqueIDs)));
    
    % Fill the new table
    for idx = 1:length(uniqueIDs)
        id = uniqueIDs(idx);
        rows = extractedData{extractedData{:, 1} == id, 2};
        newTable{1:length(rows), idx} = rows;
    end
    
    % Remove rows containing NaN
    newTable = newTable(~all(ismissing(newTable), 2), :);
    
    % Calculate mean and standard deviation for each column
    meanValues = mean(abs(newTable{:,:}), 'omitnan');
    % stdValues = std(newTable{:,:}, 'omitnan');
    % Calculate RMSE (root mean square of each column)
    rmsValues = sqrt(mean(newTable{:,:}.^2, 'omitnan'));
    
    % Append mean and std to the last two rows of the table
    newTable{end+1, :} = meanValues;
    newTable{end+1, :} = rmsValues;
    
    % Save the new table
    writetable(newTable, 'TotalLocationResult.csv');

    % Extract the first column and column I (set I as column 10)
    I = 10; % column 8 is total error, column 9 is range error, column 10 is azimuth error
    extractedData = data(:, [1, I]);
    
    % Remove rows where column I is empty
    extractedData = extractedData(~isnan(extractedData{:, 2}), :);
    
    % Get unique IDs
    uniqueIDs = unique(extractedData{:, 1});
    
    % Create a new table with IDs as column names
    newTable = array2table(NaN(height(extractedData), length(uniqueIDs)), 'VariableNames', cellstr(num2str(uniqueIDs)));
    
    % Fill the new table
    for idx = 1:length(uniqueIDs)
        id = uniqueIDs(idx);
        rows = extractedData{extractedData{:, 1} == id, 2};
        newTable{1:length(rows), idx} = rows;
    end
    
    % Remove rows containing NaN
    newTable = newTable(~all(ismissing(newTable), 2), :);
    
    % Calculate mean and standard deviation for each column
    meanValues = mean(abs(newTable{:,:}), 'omitnan');
    % stdValues = std(newTable{:,:}, 'omitnan');
    % Calculate RMSE (root mean square of each column)
    rmsValues = sqrt(mean(newTable{:,:}.^2, 'omitnan'));
    
    % Append mean and std to the last two rows of the table
    newTable{end+1, :} = meanValues;
    newTable{end+1, :} = rmsValues;
    
    % Save the new table
    writetable(newTable, 'AmziLocationResult.csv');

%% Process slant range measurement error

    % Read CSV file
    data = readtable('RangeErrorAnalysisResult.csv', 'Delimiter', ',');
    
    % Extract the first column and column I (set I as column 14)
    I = 14; % column 8 is total error, column 9 is range error, column 10 is azimuth error
    extractedData = data(:, [1, I]);
    
    % Remove rows where column I is empty
    extractedData = extractedData(~isnan(extractedData{:, 2}), :);
    
    % Get unique IDs
    uniqueIDs = unique(extractedData{:, 1});
    
    % Create a new table with IDs as column names
    newTable = array2table(NaN(height(extractedData), length(uniqueIDs)), 'VariableNames', cellstr(num2str(uniqueIDs)));
    
    % Fill the new table
    for idx = 1:length(uniqueIDs)
        id = uniqueIDs(idx);
        rows = extractedData{extractedData{:, 1} == id, 2};
        newTable{1:length(rows), idx} = rows;
    end
    
    % Remove rows containing NaN
    newTable = newTable(~all(ismissing(newTable), 2), :);
    
    % Calculate absolute mean and standard deviation for each column
    meanValues = mean(abs(newTable{:,:}), 'omitnan'); 
    % stdValues = std(newTable{:,:}, 'omitnan');
    % Calculate RMSE (root mean square of each column)
    rmsValues = sqrt(mean(newTable{:,:}.^2, 'omitnan')); % 

    
    % Append mean and std to the last two rows of the table
    newTable{end+1, :} = meanValues;
    newTable{end+1, :} = rmsValues;
    
    % Save the new table
    writetable(newTable, 'RangeErrorResult.csv');
end