function [StackPath,numFrames,numdigits, numdigits_suffix] = ...
    File_Info(pathname, filename)

        TifStackPath = fullfile(pathname, filename);
        tifStackInfo = imfinfo(TifStackPath);
        numFrames = numel(tifStackInfo);

        % logical_digits is an logical array with 1 for numbers and 0 for
        % other characters
        logical_digits=zeros(1,length(filename)-4);
        for k=1:length(filename)-4
        logical_digits(k) = length(str2num(filename(k))); %#ok<ST2NM>
        end
        
        first_digit_position = 1+find(~logical_digits, 1, 'last');
        
        %fname is the common pathname to all .tif files
        StackPath = fullfile(pathname, filename);
        numdigits = length(filename) - 3 - first_digit_position;
        numdigits_suffix = ['%0' num2str(numdigits) 'd'];
end

