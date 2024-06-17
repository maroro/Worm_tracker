function EnhancedFrame = CLAHE(workingframe, data)
    CLAHE_limit = data.CLAHE_limit;
    % Apply CLAHE with specific parameters
    CLAHE_frame = adapthisteq(workingframe,'ClipLimit',CLAHE_limit,'Distribution','rayleigh');
    EnhancedFrame = CLAHE_frame;
end