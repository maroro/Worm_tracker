function export_curvature_data(data)

    curvatureData=data.PreProcessedData.ProcessedStacks.midline_data.curvature;
    % Number of frames
    numFrames = length(curvatureData);
    % Assuming each cell contains a row vector of the same length
    numElements = length(curvatureData{1});

    % Initialize a table to hold all curvature data along with frame numbers
    curvatureTable = table('Size', [numFrames, numElements + 1], ... % +1 for the frame number column
                           'VariableTypes', [repmat({'double'}, 1, numElements + 1)], ... % All columns are double
                           'VariableNames', ['Frame', arrayfun(@(x) sprintf('pt_%d', x), 1:numElements, 'UniformOutput', false)]);
    
    % Loop through each cell and assign it to a row in the table
    for k = 1:numFrames
        curvatureTable{k, 'Frame'} = k; % Assign the frame number
        curvatureTable{k, 2:end} = curvatureData{k}; % Assign curvature data
    end

    % Write the table to a CSV file
    writetable(curvatureTable, fullfile(data.Paths{1},'curvature_data.csv'));

end