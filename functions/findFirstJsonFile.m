function jsonFilePath = findFirstJsonFile(pathname)
    % Check if the directory exists
    if ~isfolder(pathname)
        error('Directory does not exist: %s', pathname);
    end

    % Get a list of all files and folders in the directory
    filesAndDirs = dir(pathname); 
    % Filter out directories from the list
    files = filesAndDirs(~[filesAndDirs.isdir]);
 
    % Initialize the output
    jsonFilePath = '';
    % Loop through the files to find the first .json file
    for i = 1:length(files)
        [~, ~, ext] = fileparts(files(i).name);
        if strcmpi(ext, '.json') % Case insensitive comparison
            jsonFilePath = fullfile(pathname, files(i).name);
            return; % Exit the function once the first .json file is found
        end
    end
    % If no .json file is found
    if isempty(jsonFilePath)
        warning('No .json file found in the directory: %s', pathname);
    end
end