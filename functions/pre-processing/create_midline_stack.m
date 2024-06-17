function midline_data = create_midline_stack(data,WorkingFrame)
    
    dorsal_path=WorkingFrame.frame_trace_data.dorsal_trace;
    ventral_path=WorkingFrame.frame_trace_data.ventral_trace;
%% use outline paths to create midline divided in X number of midpoints%%%%
    % The paths (path1 and path2) are rescaled to have a uniform number
    % of points (data.ROI_Input.Num_midpoints), facilitating subsequent analysis. This
    % uniformity is essential for comparing paths and calculating midlines.
    D_path_rescaled = zeros(data.ROI_Input.Num_midpoints,2);
    V_path2_rescaled = zeros(data.ROI_Input.Num_midpoints,2);
    D_path1_rescaled2 = zeros(data.ROI_Input.Num_midpoints,2);
    V_path2_rescaled2 = zeros(data.ROI_Input.Num_midpoints,2);
    
    %Interpolation (interp1): Linear interpolation is used to rescale 
    % the paths, ensuring that the rescaled paths (path1_rescaled and 
    % path2_rescaled) have evenly spaced points along the length of the
    % original paths. This step is critical for accurately representing
    % the organism's structure at a consistent resolution.
    D_path_rescaled(:,1) = interp1(0:size(dorsal_path,1)-1, dorsal_path(:,1), ...
        (size(dorsal_path,1)-1)*(0:data.ROI_Input.Num_midpoints-1)/(data.ROI_Input.Num_midpoints-1), 'linear');
    D_path_rescaled(:,2) = interp1(0:size(dorsal_path,1)-1, dorsal_path(:,2), ...
        (size(dorsal_path,1)-1)*(0:data.ROI_Input.Num_midpoints-1)/(data.ROI_Input.Num_midpoints-1), 'linear');
    V_path2_rescaled(:,1) = interp1(0:size(ventral_path,1)-1, ventral_path(:,1),...
        (size(ventral_path,1)-1)*(0:data.ROI_Input.Num_midpoints-1)/(data.ROI_Input.Num_midpoints-1), 'linear');
    V_path2_rescaled(:,2) = interp1(0:size(ventral_path,1)-1, ventral_path(:,2), ...
        (size(ventral_path,1)-1)*(0:data.ROI_Input.Num_midpoints-1)/(data.ROI_Input.Num_midpoints-1), 'linear');
    
    %For each point on path1_rescaled and path2_rescaled, the code
    % finds the closest point on the opposite path. This is done by 
    % calculating the Euclidean distance between points and selecting
    % the point with the minimum distance. The result (path2_rescaled2
    % and path1_rescaled2) represents a refined approximation of the
    % corresponding points across the two paths.
    for kk=1:data.ROI_Input.Num_midpoints
        tmp1 = repmat(D_path_rescaled(kk,:), [data.ROI_Input.Num_midpoints,1]) - V_path2_rescaled;
        tmp2 = sqrt(tmp1(:,1).^2 + tmp1(:,2).^2);
        V_path2_rescaled2(kk,:) = V_path2_rescaled(find(tmp2==min(tmp2),1),:);
    end
    
    for kk=1:data.ROI_Input.Num_midpoints
        tmp1 = repmat(V_path2_rescaled(kk,:), [data.ROI_Input.Num_midpoints,1]) - D_path_rescaled;
        tmp2 = sqrt(tmp1(:,1).^2 + tmp1(:,2).^2);
        D_path1_rescaled2(kk,:) = D_path_rescaled(find(tmp2==min(tmp2),1),:);
    end
    
    % Deal with motion artifacts A weight function is introduced to gradually blend the midline 
    % calculations toward the ends of the organism. This approach
    % mitigates abrupt changes or inaccuracies at the extremities,
    % where the boundary might be less defined or more susceptible to 
    % imaging artifacts.
    weight_fn = ones(data.ROI_Input.Num_midpoints,1);
    tmp=round(data.ROI_Input.Num_midpoints*0.2);
    weight_fn(1:tmp)=(0:tmp-1)/tmp;
    weight_fn(end-tmp+1:end)=(tmp-1:-1:0)/tmp;
    weight_fn_new = [weight_fn weight_fn];
    
    
    %% NOTE: we calculate the midline in multiple ways
    %later on we only use midline_mixed but I recomend playing around with it.
    midline = 0.5*(D_path_rescaled+V_path2_rescaled);
    midline2a = 0.5*(D_path_rescaled+V_path2_rescaled2);
    %midline2b = 0.5*(D_path1_rescaled2+V_path2_rescaled);
    midline_mixed = midline2a .* weight_fn_new + midline .* (1-weight_fn_new); 
    
    %% Skeleton processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %extract midline coordinates using one of the calculations above
    X_mid = midline_mixed(:,2);
    Y_mid = midline_mixed(:,1);
    
    %calculate eucledian distance between ponints 
    %then use cumsum computes the cumulative sum of these distances, 
    % resulting in s, a vector where each element represents the total arc 
    % length from the start of the midline to that point. This
    % reparameterizes the curve by its length, making the spacing of points
    % along s proportional to the distance along the curve rather than 
    % their ordinal position in the dataset.
    s = cumsum(sqrt([0;diff(X_mid)].^2 + [0;diff(Y_mid)].^2));
    
    %use vector of arc lengths to create smoothed spline
    X_mid_sp = spline(s,X_mid);
    Y_mid_sp = spline(s,Y_mid);
    
    %This code snippet is for processing a midline (such as the central 
    % path of an object) to calculate its curvature at equally spaced 
    % points in terms of relative arc length
    
    %Determine equally spaced points (in terms of relative acrlength) for
    %calculating curvature
    s_reg = (1:data.ROI_Input.Num_midpoints)'.*s(end)/data.ROI_Input.Num_midpoints - s(end)/data.ROI_Input.Num_midpoints;
    
    % evaluate the spline representationat each of the evenly spaced points
    X_mid_tmp=ppval(X_mid_sp,s_reg); X_mid_tmp_mean=X_mid_tmp;
    Y_mid_tmp=ppval(Y_mid_sp,s_reg); Y_mid_tmp_mean=Y_mid_tmp;  
    
    % This smoothing step is intended to reduce noise in the calculation of
    % curvature by averaging out small variations in the midline
    % coordinates.
    for midPts=2:data.ROI_Input.Num_midpoints-1
        X_mid_tmp_mean(midPts)=(1/3)*(X_mid_tmp(midPts+1)+X_mid_tmp(midPts)+X_mid_tmp(midPts-1));
        Y_mid_tmp_mean(midPts)=(1/3)*(Y_mid_tmp(midPts+1)+Y_mid_tmp(midPts)+Y_mid_tmp(midPts-1));
    end    
        
    % create new smoothed spline from the evenli spaced midpoints
    X_mid_sp = spline(s_reg,X_mid_tmp_mean);
    Y_mid_sp = spline(s_reg,Y_mid_tmp_mean);  
    
    % Calculate analytically curvature on equally spaced points along the midline
    %these next few steps just rearrange the coefficients of the spline
    %to calculate the derivative.This works because they're just polynomials
    XPrime = X_mid_sp;
    XPrime.coefs = XPrime.coefs*diag([3 2 1],1);
    YPrime = Y_mid_sp;
    YPrime.coefs = YPrime.coefs*diag([3 2 1],1);
    
    XDoubPrime = XPrime;
    XDoubPrime.coefs = XDoubPrime.coefs*diag([3 2 1],1);
    YDoubPrime = YPrime;
    YDoubPrime.coefs = YDoubPrime.coefs*diag([3 2 1],1);
    
    %Calculate curvature of midline in arclength regularly spaced points
    %from derivatives of parametrized parts calculated above
    midline_data.curvature(1,:) = 1000*(ppval(XPrime,s_reg).*ppval(YDoubPrime,s_reg) ...
    - ppval(YPrime,s_reg).*ppval(XDoubPrime,s_reg))./((ppval(XPrime,s_reg).^2 ...
    + ppval(YPrime,s_reg).^2).^(3/2));
    
    %% find ventral/dorsal points perpendicular to midline spline %%%%%%%%%%%%
    
    % Seek the ventral and dorsal points starting from the midline point
    midline_data.midpoints(:,1)=ppval(X_mid_sp,s_reg);
    midline_data.midpoints(:,2)=ppval(Y_mid_sp,s_reg);
    
    %calculates the slope of the tangent to the midline at each point using
    % the derivative values (YPrime/XPrime), which gives the slope c.
    c = ppval(YPrime,s_reg)./ppval(XPrime,s_reg);
    
    X1=midline_data.midpoints(:,1); Y1=midline_data.midpoints(:,2);
    X2=midline_data.midpoints(:,1); Y2=midline_data.midpoints(:,2);
    midline_data.X_d=midline_data.midpoints(:,1); midline_data.Y_d=midline_data.midpoints(:,2);
    midline_data.X_v=midline_data.midpoints(:,1); midline_data.Y_v=midline_data.midpoints(:,2);  
    
    Xplus=midline_data.midpoints(:,1); Yplus=midline_data.midpoints(:,2);
    Xminus=midline_data.midpoints(:,1); Yminus=midline_data.midpoints(:,2);

    for p=1:2*round(data.SplitChannels.Body_Coords.worm_diam)
        % It starts by incrementally moving away from each point on the midline
        % (midline_data.midpoints, midline_data.midpoints(:,2)) in both positive (Xplus, Yplus) and negative 
        % (Xminus, Yminus) directions perpendicular to the midline, based on 
        % the slope c.
        Yplus=Yplus+0.5./sqrt(1+c.^2);
        Xplus=Xplus-0.5*(c./sqrt(1+c.^2));
        Yminus=Yminus-0.5./sqrt(1+c.^2);
        Xminus=Xminus+0.5*(c./sqrt(1+c.^2));
        
        % Set for first frame path 1 as positive angle and path 2 as negative
        % angle
        if floor(Xplus(2))>1 && floor(Yplus(2))>1 && ...
          ceil(Xplus(2))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,2) && ceil(Yplus(2))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,1)...
          && norm([Xplus(2)-midline_data.midpoints(2,1) Yplus(2)-midline_data.midpoints(2,2)])>=...
              norm([X1(2)-midline_data.midpoints(2,1) Y1(2)-midline_data.midpoints(2,2)])...
          && WorkingFrame.frame_mask_data.BW_Mask_Frame(floor(Yplus(2)),floor(Xplus(2)))==1 ...
          
          if (midline_data.midpoints(2,1)-midline_data.midpoints(1,1))*(Yplus(2)-midline_data.midpoints(1,2))>=(midline_data.midpoints(2,2)-midline_data.midpoints(1,2))*(Xplus(2)-midline_data.midpoints(1,1))      
              X1(2) = Xplus(2);
              Y1(2) = Yplus(2);
        
          elseif (midline_data.midpoints(2,1)-midline_data.midpoints(1,1))*(Yplus(2)-midline_data.midpoints(1,2))<(midline_data.midpoints(2,2)-midline_data.midpoints(1,2))*(Xplus(2)-midline_data.midpoints(1,1))     
              X2(2) = Xplus(2);
              Y2(2) = Yplus(2);      
          end 
        end
        
        if floor(Xminus(2))>1 && floor(Yminus(2))>1 && ...
          ceil(Xminus(2))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,2) && ceil(Yminus(2))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,1)...
          && norm([Xminus(2)-midline_data.midpoints(2,1) Yminus(2)-midline_data.midpoints(2,2)])>=...
              norm([X1(2)-Xminus(2) Y1(2)-Yminus(2)])...
          && WorkingFrame.frame_mask_data.BW_Mask_Frame(floor(Yminus(2)),floor(Xminus(2)))==1 ...
          
          if (midline_data.midpoints(2,1)-midline_data.midpoints(1,1))*(Yminus(2)-midline_data.midpoints(1,2))>=(midline_data.midpoints(2,2)-midline_data.midpoints(1,2))*(Xminus(2)-midline_data.midpoints(1,1))   
              X1(2) = Xminus(2);
              Y1(2) = Yminus(2);
        
          elseif (midline_data.midpoints(2,1)-midline_data.midpoints(1,1))*(Yminus(2)-midline_data.midpoints(1,2))<(midline_data.midpoints(2,2)-midline_data.midpoints(1,2))*(Xminus(2)-midline_data.midpoints(1,1))    
              X2(2) = Xminus(2);
              Y2(2) = Yminus(2);      
          end 
        end
    end 
      



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%extend lines from points along the midline outwards in both directions to
% find the organism's boundaries. This process is crucial for analyzing the
% organism's shape, posture, and movements over time.
    Xplus=midline_data.midpoints(:,1); Yplus=midline_data.midpoints(:,2);
    Xminus=midline_data.midpoints(:,1); Yminus=midline_data.midpoints(:,2);   
    
    for p=1:2*round(data.SplitChannels.Body_Coords.worm_diam)
    Yplus=Yplus+0.5./sqrt(1+c.^2);
    Xplus=Xplus-0.5*(c./sqrt(1+c.^2));
    Yminus=Yminus-0.5./sqrt(1+c.^2);
    Xminus=Xminus+0.5*(c./sqrt(1+c.^2));
    
        for point=3:data.ROI_Input.Num_midpoints
            %checks if the extended points (Xplus(k3), Yplus(k3)) fall within
            % the valid area of the organism by ensuring they are within the
            % image boundaries and that the corresponding location in
            % data.frame_mask_data.BW_Mask_Frame is 1 (indicating the presence of the organism).
            if floor(Xplus(point))>1 && floor(Yplus(point))>1 && ceil(Xplus(point))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,2) && ceil(Yplus(point))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,1)
                if norm([Xplus(point)-midline_data.midpoints(point,1) Yplus(point)-midline_data.midpoints(point,2)])>norm([X1(point)-...
                    midline_data.midpoints(point,1) , Y1(point)-midline_data.midpoints(point,2)]) ...
                    && WorkingFrame.frame_mask_data.BW_Mask_Frame(floor(Yplus(point)),floor(Xplus(point)))==1 ...
                    && norm([Xplus(point)-X1(point-1) Yplus(point)-Y1(point-1)])<=norm([Xplus(point)-...
                    X2(point-1) Yplus(point)-Y2(point-1)])
                    
                    X1(point) = Xplus(point);
                    Y1(point) = Yplus(point);     
                end  
              
                if norm([Xplus(point)-midline_data.midpoints(point,1) , Yplus(point)-midline_data.midpoints(point,2)])>norm([X2(point)-...
                    midline_data.midpoints(point,1) , Y2(point)-midline_data.midpoints(point,2)]) ...
                    && WorkingFrame.frame_mask_data.BW_Mask_Frame(floor(Yplus(point)),floor(Xplus(point)))==1 ...
                    && norm([Xplus(point)-X2(point-1) Yplus(point)-Y2(point-1)])<norm([Xplus(point)-...
                    X1(point-1) Yplus(point)-Y1(point-1)])
                    
                    X2(point) = Xplus(point);
                    Y2(point) = Yplus(point);
                end 
            end  
                
            if floor(Xminus(point))>1 && floor(Yminus(point))>1 && ceil(Xminus(point))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,2) && ceil(Yminus(point))<size(WorkingFrame.frame_mask_data.BW_Mask_Frame,1)       
                if norm([Xminus(point)-midline_data.midpoints(point,1) , Yminus(point)-midline_data.midpoints(point,2)])>norm([X1(point)-...
                    midline_data.midpoints(point,1) Y1(point)-midline_data.midpoints(point,2)]) ...
                    && WorkingFrame.frame_mask_data.BW_Mask_Frame(floor(Yminus(point)),floor(Xminus(point)))==1 ...
                    && norm([Xminus(point)-X1(point-1) Yminus(point)-Y1(point-1)])<=norm([Xminus(point)-...
                    X2(point-1) Yminus(point)-Y2(point-1)])
                    
                    X1(point) = Xminus(point);
                    Y1(point) = Yminus(point);     
                end   
                
                if norm([Xminus(point)-midline_data.midpoints(point,1) , Yminus(point)-midline_data.midpoints(point,2)])>norm([X2(point)-...
                    midline_data.midpoints(point,1) Y2(point)-midline_data.midpoints(point,2)]) ...
                    && WorkingFrame.frame_mask_data.BW_Mask_Frame(floor(Yminus(point)),floor(Xminus(point)))==1 ...midlinemidline_data.midpoints(:,2)
                    && norm([Xminus(point)-X2(point-1) Yminus(point)-Y2(point-1)])<norm([Xminus(point)-...
                    X1(point-1) Yminus(point)-Y1(point-1)])
                    
                    X2(point) = Xminus(point);
                    Y2(point) = Yminus(point);
                end 
            end
        end 
    end
        
%% Allocate each point to dorsal or ventral side %%%%%%%%%%%%%%%%%%%%%%%%%%
    %find points along the line that are a certain proportion (f) away 
    % from the starting point towards the end point, both "outward" and
    % "inward." The distinction between "outward" and "inward" points
    % is controlled by the factor f and how it's applied in the 
    % equations. 
    for point=1:data.ROI_Input.Num_midpoints
      if min((X1(point)-dorsal_path(:,2)).^2+(Y1(point)-dorsal_path(:,1)).^2)<...
              min((X2(point)-dorsal_path(:,2)).^2+(Y2(point)-dorsal_path(:,1)).^2)
          midline_data.X_d(point)=X1(point); midline_data.Y_d(point)=Y1(point);
          midline_data.X_v(point)=X2(point); midline_data.Y_v(point)=Y2(point);
      else
          midline_data.X_d(point)=X2(point); midline_data.Y_d(point)=Y2(point);
          midline_data.X_v(point)=X1(point); midline_data.Y_v(point)=Y1(point);
      end
    end
    
    %direction_trim = 0.1*data.ROI_Input.Num_midpoints;

    %direction(k) = sign(dot([mean(midline_data.X_start{k}(current_pt)) - G(k,1), mean(midline_data.Y_start{k}(current_pt))-G(k,2)],...
    %[mean(midline_data.X_start{k}(1:direction_trim)) - mean(midline_data.X_start{k}(data.ROI_Input.Num_midpoints-direction_trim:data.ROI_Input.Num_midpoints)) ...
    %mean(midline_data.Y_start{k}(1:direction_trim)) - mean(midline_data.Y_start{k}(data.ROI_Input.Num_midpoints-direction_trim:data.ROI_Input.Num_midpoints))]));

    %G(k,1) = mean(midline_data.X_start{k});
    %G(k,2) = mean(midline_data.Y_start{k});
    
end