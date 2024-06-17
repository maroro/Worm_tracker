function ROI_data = create_edge_ROIs(data)

    midline_data = data.PreProcessedData.ProcessedStacks.midline_data;
    Img.GFP = data.SplitChannels.RawGFP;
    Img.RFP = data.SplitChannels.RawRFP;
    num_mid_pts = data.PreProcessedData.ROI_Input.Num_midpoints;
    f=data.ROI_Input.edge_offset;
    a=data.ROI_Input.edge_width;
    n_ROI=data.ROI_Input.n_merge;
    
    NumFrames = length(Img.GFP);

    X_out_d_2 = zeros(num_mid_pts,NumFrames,'double');
    Y_out_d_2 = zeros(num_mid_pts,NumFrames,'double');
    X_in_d_2 = zeros(num_mid_pts,NumFrames,'double');
    Y_in_d_2 = zeros(num_mid_pts,NumFrames,'double');
    X_out_v_2 = zeros(num_mid_pts,NumFrames,'double');
    Y_out_v_2 = zeros(num_mid_pts,NumFrames,'double');
    X_in_v_2 = zeros(num_mid_pts,NumFrames,'double');
    Y_in_v_2 = zeros(num_mid_pts,NumFrames,'double');

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define X and Y coords of ROIs for each midpoint %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for k =1:NumFrames
        %These calculations find points that are "outward" along the line 
        % from the starting to ending points. The formula (2-f) and (f-1)
        % adjust the weight given to the start and end points as f varies.
        % The outward points move beyond the end points when f is between
        % 1 and 2.

        %Also, These calculate points that are "inward" along the same line but 
        % closer to the starting points. The factors (1-f) and f weigh the
        % end points less and the start points more as f increases from
        % 0 to 1.

        %Interpretation of f: When f = 0, the inward points coincide with
        % the start points (midline_data.midpoints{k}(:,1), midline_data.midpoints{k}(:,2)).

        %When f = 1, the inward points move to the end points (*midline_data.dorsal_points{k}(:,1), *midline_data.dorsal_points{k}(:,2), 
        % *midline_data.ventral_points{k}(:,1), *midline_data.ventral_points{k}(:,2)), and the outward points extend the line beyond these 
        % end points.

        %Values of f between 0 and 1 interpolate points along the line
        % between the start and end points.

        %Values of f between 1 and 2 for outward points extend the line
        % past the original end points.
        X_out_d=(2-f).*midline_data.dorsal_points{k}(:,1) + (f-1).*midline_data.midpoints{k}(:,1);
        X_in_d=(1-f).*midline_data.dorsal_points{k}(:,1) + f.*midline_data.midpoints{k}(:,1);
        Y_out_d=(2-f).*midline_data.dorsal_points{k}(:,2) + (f-1).*midline_data.midpoints{k}(:,2); 
        Y_in_d=(1-f).*midline_data.dorsal_points{k}(:,2) + f.*midline_data.midpoints{k}(:,2);
        
        X_out_v=(2-f).*midline_data.ventral_points{k}(:,1) + (f-1).*midline_data.midpoints{k}(:,1);
        X_in_v=(1-f).*midline_data.ventral_points{k}(:,1) + f.*midline_data.midpoints{k}(:,1);
        Y_out_v=(2-f).*midline_data.ventral_points{k}(:,2) + (f-1).*midline_data.midpoints{k}(:,2);
        Y_in_v=(1-f).*midline_data.ventral_points{k}(:,2) + f.*midline_data.midpoints{k}(:,2);

% X_out_d_2, Y_out_d_2, X_in_d_2, Y_in_d_2, X_out_v_2, Y_out_v_2, X_in_v_2,
% and Y_in_v_2 are arrays to store new coordinates adjusted from the
% original outward and inward points
 
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

            % use "a" to adjust the distance between the midpoint and the outer border 
            X_out_diff_d= a*(X_out_d(current_pt) - cpt_X_start);
            X_in_diff_d = a*(X_in_d(current_pt) - cpt_X_start);
            Y_out_diff_d= a*(Y_out_d(current_pt) - cpt_Y_start);
            Y_in_diff_d = a*(Y_in_d(current_pt) - cpt_Y_start);
            
            %use "a"-scaled values to define new inward/outward (x,y) coords.
            X_out_d_2(current_pt,k) =  cpt_X_start + X_out_diff_d + ...
                (1-a)*(X_out_diff_d); %second scaling reduces the original 
            % adjustment to prevent the user from overshooting passed the mmidoint
            X_in_d_2(current_pt,k) =  cpt_X_start + X_in_diff_d + ...
                (1-a)*(X_in_diff_d);
            Y_out_d_2(current_pt,k) =  cpt_Y_start + Y_out_diff_d + ...
                (1-a)*(Y_out_diff_d);
            Y_in_d_2(current_pt,k) =  cpt_Y_start + Y_in_diff_d + ...
                (1-a)*(Y_in_d(current_pt)- cpt_Y_start);
            
            %repeat for ventral side 
            % use "a" to adjust the distance between the midpoint and the outer border 
            X_out_diff_v= a*(X_out_v(current_pt) - cpt_X_start);
            X_in_diff_v = a*(X_in_v(current_pt) - cpt_X_start);
            Y_out_diff_v= a*(Y_out_v(current_pt) - cpt_Y_start);
            Y_in_diff_v = a*(Y_in_v(current_pt) - cpt_Y_start);
            %use "a"-scaled values to define new inward/outward (x,y) coords.
            X_out_v_2(current_pt,k) =  cpt_X_start + X_out_diff_v + ...
                (1-a)*(X_out_diff_v); %second scaling reduces the original 
            % adjustment to prevent the user from overshooting passed the mmidoint
            X_in_v_2(current_pt,k) =  cpt_X_start + X_in_diff_v + ...
                (1-a)*(X_in_diff_v);
            Y_out_v_2(current_pt,k) =  cpt_Y_start + Y_out_diff_v + ...
                (1-a)*(Y_out_diff_v);
            Y_in_v_2(current_pt,k) =  cpt_Y_start + Y_in_diff_v + ...
                (1-a)*(Y_in_v(current_pt)- cpt_Y_start);
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
            ROI_data.ROI_d_X{k}{current_pt} = [X_out_d_2(current_pt-n_ROI:current_pt+n_ROI,k); ...
                X_in_d_2(current_pt+n_ROI:-1:current_pt-n_ROI,k)];
            ROI_data.ROI_d_Y{k}{current_pt} = [Y_out_d_2(current_pt-n_ROI:current_pt+n_ROI,k);...
                Y_in_d_2(current_pt+n_ROI:-1:current_pt-n_ROI,k)];

            ROI_data.ROI_v_X{k}{current_pt} = [X_out_v_2(current_pt-n_ROI:current_pt+n_ROI,k); ...
                X_in_v_2(current_pt+n_ROI:-1:current_pt-n_ROI,k)];
            ROI_data.ROI_v_Y{k}{current_pt} = [Y_out_v_2(current_pt-n_ROI:current_pt+n_ROI,k);...
                Y_in_v_2(current_pt+n_ROI:-1:current_pt-n_ROI,k)];
           
            % roipoly is used to create binary masks for dorsal (ROI_d) and ventral 
            % (ROI_v) regions based on the adjusted points. 
            ROI_data.ROI_d_mask{k}{current_pt} = roipoly(Img.GFP{k}, ROI_data.ROI_d_X{k}{current_pt}, ...
                ROI_data.ROI_d_Y{k}{current_pt});
            ROI_data.ROI_v_mask{k}{current_pt} = roipoly(Img.GFP{k}, ROI_data.ROI_v_X{k}{current_pt}, ...
                ROI_data.ROI_v_Y{k}{current_pt});   
        end
    end
end