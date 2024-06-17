function Intensity_data = center_ROI_intensity(data)
    % pre-assign all values we will need for the rest of the calculations
    Img.GFP = data.SplitChannels.RawGFP;
    Img.RFP = data.SplitChannels.RawRFP;
    num_mid_pts = data.PreProcessedData.ROI_Input.Num_midpoints;
    n_ROI = data.ROI_Input.n_merge;
    start_pt = 1+n_ROI;
    end_pt = num_mid_pts-n_ROI;
    NumFrames = length(Img.GFP);
    
    % we use the ROI mask (i.e. are inside ROI is 1s and the rest is 0s)
    % because it makes it easier to detect the ROIs and extract data
    % Also, because GFP and RFP are aligned during splitting, the
    % coordinates for a single mask should apply for both GFP & RFP.
    ROI = data.ROI_Data.ROI_center_mask;

    Intensity_data.GFP = zeros(NumFrames,num_mid_pts,'double');
    Intensity_data.RFP = zeros(NumFrames,num_mid_pts,'double');
    Intensity_data.Ratio = zeros(NumFrames,num_mid_pts,'double');
    
    % iterate through every frame in stack for each ROI point. 
    for pt = start_pt:end_pt
        for  i = 1:NumFrames
            % collects data withing ROI in the form of a single vector
            current_roi_GFP = Img.GFP{i}(ROI{i}{pt});
            current_roi_RFP = Img.RFP{i}(ROI{i}{pt});
            
            %%% calculate mean intensity for each ROI %%%
            %create a data frame for each where ach row is a frame and each
            %column is one of the body points
            Intensity_data.GFP_center(i,pt) = sum(current_roi_GFP) / numel(current_roi_GFP); 
            Intensity_data.RFP_center(i,pt) = sum(current_roi_RFP) / numel(current_roi_RFP); 
            Intensity_data.Ratio_center(i,pt) = Intensity_data.GFP(i,pt) / Intensity_data.RFP(i,pt);
        end
    end
end