function Intensity_data = edge_ROI_intensity(data)
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
    ROI_v = data.ROI_Data.edge_ROI.ROI_v_mask;
    ROI_d = data.ROI_Data.edge_ROI.ROI_d_mask;

    Intensity_data.GFP_d = zeros(NumFrames,num_mid_pts,'double');
    Intensity_data.GFP_v = zeros(NumFrames,num_mid_pts,'double');
    Intensity_data.RFP_d = zeros(NumFrames,num_mid_pts,'double');
    Intensity_data.RFP_v = zeros(NumFrames,num_mid_pts,'double');
    Intensity_data.Ratio_d = zeros(NumFrames,num_mid_pts,'double');
    Intensity_data.Ratio_v = zeros(NumFrames,num_mid_pts,'double');
    
    % iterate through every frame in stack for each ROI point. 
    for pt = start_pt:end_pt
        for  i = 1:NumFrames
            % collects data withing ROI in the form of a single vector
            current_d_roi_GFP = Img.GFP{i}(ROI_d{i}{pt});
            current_d_roi_RFP = Img.RFP{i}(ROI_d{i}{pt});
            current_v_roi_GFP = Img.GFP{i}(ROI_v{i}{pt});
            current_v_roi_RFP = Img.RFP{i}(ROI_v{i}{pt});
            
            %%% calculate mean intensity for each ROI %%%
            %create a data frame for each where ach row is a frame and each
            %column is one of the body points
            Intensity_data.GFP_d(i,pt) = sum(current_d_roi_GFP) / numel(current_d_roi_GFP); 
            Intensity_data.GFP_v(i,pt) = sum(current_v_roi_GFP) / numel(current_v_roi_GFP);
            Intensity_data.RFP_d(i,pt) = sum(current_d_roi_RFP) / numel(current_d_roi_RFP); 
            Intensity_data.RFP_v(i,pt) = sum(current_v_roi_RFP) / numel(current_v_roi_RFP);
            Intensity_data.Ratio_d(i,pt) = Intensity_data.GFP_d(i,pt) / Intensity_data.RFP_d(i,pt);
            Intensity_data.Ratio_v(i,pt) =  Intensity_data.GFP_v(i,pt) / Intensity_data.RFP_v(i,pt); 
        end
    end
end