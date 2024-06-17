function FrameMaskdata = create_mask_stack(data,S,WorkingFrame)

    %%% specify a random diameter if one is not found %%%%%%%%%%%%5
    if ~isfield(data.SplitChannels.Body_Coords,'worm_diam')||...
            isempty(data.SplitChannels.Body_Coords.worm_diam)
        worm_diam = 150;
    else
        worm_diam = data.SplitChannels.Body_Coords.worm_diam;
    end
    
    %%% establish the identity of the working frame %%%%%%%%%%%%%%%%%%%%%%
    WorkingFrame=WorkingFrame.EnhancedFrame{1}; %use GFP frame as reference for mask

    data.MaskParameters.MaskDilation = str2double(get(S.Maskdilation,'string'));
    MaskDilation = data.MaskParameters.MaskDilation;
    
    %%% perform erosion before binarizing image if box checked %%%
    if S.erosionbox.Value == 1
        data.MaskParameters.erosion = str2double(get(S.erosion,'string'));
        % Initial Erosion to remove small noise and separate objects
        erodedframe = imerode(WorkingFrame, ...
            strel('disk', data.MaskParameters.erosion));
        % Apply adaptive thresholding
        T = adaptthresh(erodedframe, 0.5, 'ForegroundPolarity', 'bright');
        binaryFrame = imbinarize(erodedframe, T);
        % Perform edge detection on image
        edgeDetected = edge(binaryFrame, 'canny', [0.005, 0.3], 3);
    else
        data.MaskParameters.erosion = [];
        % Apply adaptive thresholding
        T = adaptthresh(WorkingFrame, 0.5, 'ForegroundPolarity', 'bright');
        binaryFrame = imbinarize(WorkingFrame, T);
        % Perform edge detection on image
        edgeDetected = edge(binaryFrame, 'canny', [0.005, 0.3], 3);
    end

    data.MaskParameters.dilation = [];
    % Apply closing to fill gaps, using the specified erosion coefficient
    FrameMaskdata.BW_Mask_Frame = imclose(edgeDetected, strel('disk', MaskDilation));
    % Remove small objects that have less than worm_diam pixels
    FrameMaskdata.BW_Mask_Frame = bwareaopen(FrameMaskdata.BW_Mask_Frame,round(worm_diam));
   
    % trace the boundary of objects found in our bw mask
    FrameMaskdata.FrameBoundary = bwboundaries(FrameMaskdata.BW_Mask_Frame,'noholes');
end