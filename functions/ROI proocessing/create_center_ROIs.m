function ROI_data = create_center_ROIs(data)

    midline_data = data.PreProcessedData.ProcessedStacks.midline_data;
    Img.GFP = data.SplitChannels.RawGFP;
    Img.RFP = data.SplitChannels.RawRFP;
    num_mid_pts = data.PreProcessedData.ROI_Input.Num_midpoints;
    a=data.ROI_Input.center_width;
    n_ROI=data.ROI_Input.n_merge;
    
    NumFrames = length(Img.GFP);

    X_out_d_2 = zeros(num_mid_pts,NumFrames,'double');
    Y_out_d_2 = zeros(num_mid_pts,NumFrames,'double');
    X_out_v_2 = zeros(num_mid_pts,NumFrames,'double');
    Y_out_v_2 = zeros(num_mid_pts,NumFrames,'double');

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define X and Y coords of ROIs for each midpoint %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for k =1:NumFrames
        %skip the first and last couple moints because those correspond to
        %the head and we are focusing on the body muscle
        for current_pt= 1+n_ROI : num_mid_pts-n_ROI                        % select only midpoints where whe can draw ROIs around them
            %The code calculates new positions for both the outward and 
            % inward points on the dorsal side. It uses a blend of the 
            % original position adjusted towards the midline starting 
            % point (midline_data.midpoints{k}(:,1), midline_data.midpoints{k}(:,2)) 
            % and the specific position of current_pt to create a smoother 
            % transition or focus around the region of interest.
            cpt_X_start = midline_data.midpoints{k}(current_pt,1);
            cpt_Y_start = midline_data.midpoints{k}(current_pt,2);

            X_out_d = midline_data.dorsal_points{k}(current_pt,1) + cpt_X_start;
            Y_out_d = midline_data.dorsal_points{k}(current_pt,2) + cpt_Y_start;   
            X_out_v = midline_data.ventral_points{k}(current_pt,1) +cpt_X_start;
            Y_out_v = midline_data.ventral_points{k}(current_pt,2) + cpt_Y_start;

            % use "a" to adjust the distance between the midpoint and the outer border 
            X_out_diff_d= a*(X_out_d - cpt_X_start);
            Y_out_diff_d= a*(Y_out_d - cpt_Y_start);
            X_out_diff_v= a*(X_out_v - cpt_X_start);
            Y_out_diff_v= a*(Y_out_v - cpt_Y_start);
            
            %use "a"-scaled values to define new outward (x,y) coords.
            X_out_d_2(current_pt,k) =  cpt_X_start + (1-a)*(X_out_diff_d); 
            Y_out_d_2(current_pt,k) =  cpt_Y_start + (1-a)*(Y_out_diff_d); 
            % do the same for ventral side
            X_out_v_2(current_pt,k) =  cpt_X_start + (1-a)*(X_out_diff_v);
            Y_out_v_2(current_pt,k) =  cpt_Y_start + (1-a)*(Y_out_diff_v);
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate ROIs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
    for k =1:NumFrames
        for current_pt= 1+n_ROI : num_mid_pts-n_ROI 
            %generate path of x coordinates. staring with outward points n_ROI before
            %the current_pt annd ending n_ROI after then followed by inward coords
            %staring n_ROI after the current_pt and moving toward n_ROI before the
            %current_pt.
            ROI_data.ROI_center_X{k}{current_pt} = [X_out_d_2(current_pt-n_ROI:current_pt+n_ROI,k); ...
                X_out_v_2(current_pt+n_ROI:-1:current_pt-n_ROI,k)];
            ROI_data.ROI_center_Y{k}{current_pt} = [Y_out_d_2(current_pt-n_ROI:current_pt+n_ROI,k);...
                Y_out_v_2(current_pt+n_ROI:-1:current_pt-n_ROI,k)];
           
            % roipoly is used to create binary masks for dorsal (ROI_d) and ventral 
            % (ROI_v) regions based on the adjusted points. 
            ROI_data.ROI_center_mask{k}{current_pt} = roipoly(Img.GFP{k}, ROI_data.ROI_center_X{k}{current_pt}, ...
                ROI_data.ROI_center_Y{k}{current_pt});
        end
    end
end