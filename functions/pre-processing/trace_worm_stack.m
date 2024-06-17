function  frame_trace_data = trace_worm_stack(data,WorkingFrame,k)

    % Check if the user has not provided the value of k
    if nargin < 3
        k = 1;  % Set default value of k to 1
    end
 
    %This method effectively measures how the orientation of the boundary 
    % changes from one point to its neighbors ksep steps away. Such analysis
    % can reveal the curvature and bending points along the boundary, which are 
    % crucial for understanding the shape and posture dynamics of objects,
    % especially in biological studies.
    
    %By examining the changes in Bd_angle, you can infer where the object bends
    % and how its orientation changes along its contour. This information is 
    % valuable for tasks like shape analysis, motion tracking, and behavioral 
    % quantification in scientific research.

    % midline and boundaries detecting code 
    headx = data.SplitChannels.Body_Coords.head_coords(1);
    heady = data.SplitChannels.Body_Coords.head_coords(2);
    vulvax = data.SplitChannels.Body_Coords.vulva_coords(1);
    vulvay = data.SplitChannels.Body_Coords.vulva_coords(2);
    
%% Trace worm outline and find angles%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% assuming that worm is largest object in mask, the following looks
    %%% for the largest object and selects it as main boundary
    BoundaryList = WorkingFrame.frame_mask_data.FrameBoundary;
    boundary_lengths = [];
    for bd = 1:size(BoundaryList,1)
        if isempty(boundary_lengths)
            boundary_lengths = [size(BoundaryList{bd},1)];
        else
            boundary_lengths = [boundary_lengths,size(BoundaryList{bd},1)];
        end
        [~,max_boundary_index] = max(boundary_lengths);
    end
    MainBoundary = BoundaryList{max_boundary_index};

    %circshift Function: This MATLAB function circularly shifts the
    % elements of an array. Basically moves along the the boundary by a
    % determined amount. In this case it is called ksep: the total length
    % of the boundary divided by 20

    % Bd_plus and Bd_minus Calculation: By shifting CurrentBoundary by 
    % ksep positions forward and backward, respectively, you create two 
    % new arrays. These arrays represent points on the boundary that
    % are ksep positions ahead of and behind each original point,
    % considering the boundary as a continuous loop.
    Bd_size = size(MainBoundary,1);
    ksep = ceil(Bd_size/20); 
    Bd_plus = circshift(MainBoundary,[ksep 0]);
    Bd_minus = circshift(MainBoundary,[-ksep 0]);
    
    % Vectors AA and BB: The difference between CurrentBoundary and its
    % shifted versions (Bd_plus and Bd_minus) calculates vectors 
    % pointing from one boundary point to another, ksep steps away. 
    % These vectors span segments of the boundary curve.
    AA = MainBoundary - Bd_plus; 
    BB = MainBoundary - Bd_minus;

    %Complex Representation: By combining the x and y components of
    % these vectors into complex numbers (cAA and cBB), the code 
    % prepares to analyze the boundary in terms of angles. This 
    % representation facilitates the use of complex arithmetic to 
    % explore the geometry of the boundary.
    cAA = AA(:,1) + 1i*AA(:,2); 
    cBB = BB(:,1) + 1i*BB(:,2);

    % between each pair of vectors (AA and BB) around each boundary 
    % point. Because these vectors are represented as complex numbers,
    % dividing cBB by cAA gives a complex number whose argument (angle
    % in the complex plane) represents the angle between the two vectors

    %unwrap Function: The unwrap function is applied to the array of
    % angles to adjust the values to prevent discontinuities greater 
    % than π radians. This is important for correctly interpreting 
    % the angles along the boundary, especially over a continuous 
    % sequence where the angle might logically transition through a
    % point that would naively appear as a discontinuous jump.
    Bd_angle = unwrap(angle(cBB ./ cAA));% This operation computes the angle (in radians)
    
    %min_angle_pt_index1: This finds the index of the boundary point 
    % where the angle between vectors AA and BB is minimal. This angle
    % represents the point of highest curvature, which could correspond
    % to either the head or tailthe worm.
    min_angle_pt_index1 = find(Bd_angle == min(Bd_angle),1);
    
% Circshift and Second Minimum: The boundary angles array
% (Bd_angle) is circularly shifted so that the point with the
% minimum angle found above is moved to the start of the array.
% This manipulation facilitates finding another significant point 
% on the boundary:
    
    %Bd_angle1: A version of Bd_angle shifted based on the first
    % minimum angle 
    Bd_angle_first = circshift(Bd_angle, - min_angle_pt_index1);
    
    %min_angle_pt_index2bis: Finds a second point of interest by 
    % searching for the minimum angle in a subset of Bd_angle1. This
    % subset excludes the quarter of points nearest to the first
    % minimum point to ensure the second point is on the opposite side 
    % of the object. 
    min_angle_pt_index2bis = round(.25*Bd_size) - 1 + ...
    find(Bd_angle_first(round(.25*Bd_size):round(.75*Bd_size))== ...
    min(Bd_angle_first(round(.25*Bd_size):round(.75*Bd_size))),1);
    
    % min_angle_pt_index2: Adjusts the index of the second point found
    % to account for the circular shift and aligns it with the original
    % boundary indexing
    min_angle_pt_index2 = 1+mod(min_angle_pt_index2bis + ...
                                min_angle_pt_index1 - 1, Bd_size);
    
    % Bd_shifted: The boundary array is shifted so the first minimum 
    % angle point is at the start. This reordering simplifies the 
    % extraction of paths from the head to tail (or vice versa).
    Bd_shifted = circshift(MainBoundary, [1-min_angle_pt_index1 0]);

%% use worm outline to find head and tail%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %end1: Calculates the end index for one of the paths based on the 
    % distance between the two points of interest.
    end1 = 1+mod(min_angle_pt_index2 - min_angle_pt_index1 - 1, Bd_size);
    % path1 and path2: Two paths are defined from the point with the 
    % minimum angle (possibly the head or tail). path1 goes from this 
    % point to the second point of interest, and path2 takes the 
    % reverse route. These paths could represent the organism's body
    % from head to tail and tail to head, respectively.
    path1 = Bd_shifted(1:end1,:);
    path2 = Bd_shifted(end:-1:end1,:);

    % here we use head coordinates to define if our end1 actually
    % defines the head. if it end1 is not close to head, the reverse
    % paths
    if norm(path1(1,:) - [heady headx]) > norm(path1(end,:) - [heady headx]) 
      tmp = path1;
      path1 = path2(end:-1:1,:);
      path2 = tmp(end:-1:1,:);
    end


    %Here head and tail coordinates are reasinged based on the paths
    %created from the mask of the worm.
    head_coords(1,1) = path1(1,1); head_coords(1,2) = path1(1,2);

%% Reorient paths based on vulva coordinates to corectly label dorsal & ventral sides
    % This approach allows for the consistent analysis of structural 
    % or movement changes in elongated organisms across a sequence of 
    % images. By ensuring that the paths representing the organism's 
    % structure are oriented consistently relative to a specific 
    % anatomical feature or the previous frame's orientation, the 
    % algorithm facilitates accurate tracking of changes in posture, 
    % movement, or other morphological characteristics over time.
    
    % Allocate dorsal and ventral sides to paths 1 and 2 : by default 1 is
    % dorsal and 2 is ventral, invert if vulva is on path1
    
    if k == 1
        if min((vulvax-path1(:,2)).^2+(vulvay-path1(:,1)).^2)<...
             min((vulvax-path2(:,2)).^2+(vulvay-path2(:,1)).^2) 
       
            ventral_trace=path1;
            dorsal_trace=path2;
            
        else
            ventral_trace=path2;
            dorsal_trace=path1;
        end
        % store position of one point of path 1 in order to compare it with next
        % frame paths, because paths do not have constant lengths
        midpath=floor(length(dorsal_trace)/2);
        midDorsal(1,1) = dorsal_trace(midpath,1); 
        midDorsal(1,2) = dorsal_trace(midpath,2);

    elseif k>1
        DorsalmidX = data.ProcessedStacks.trace_data.dorsal_midpoint{k-1}(1,1);
        DorsalmidY = data.ProcessedStacks.trace_data.dorsal_midpoint{k-1}(1,2);
        if min((DorsalmidX - path1(:,2)).^2 + (DorsalmidY-path1(:,1)).^2) > ...   
             min((DorsalmidX - path2(:,2)).^2 + (DorsalmidY-path2(:,1)).^2) 

            ventral_trace=path1;
            dorsal_trace=path2;
        else
            ventral_trace=path2;
            dorsal_trace=path1;
        end

        % store position of one point of path 1 in order to compare it with next
        % frame paths, because paths do not have constant lengths
        midpath=floor(length(dorsal_trace)/2);
        midDorsal(1,1) = dorsal_trace(midpath,1); 
        midDorsal(1,2) = dorsal_trace(midpath,2);
    end

    %store the morphological data onto a cell array so that we can
    %use the data later for visualization
    % {DorsalPath, VentralPath, MidbodyX, MidbodyY}
    frame_trace_data.dorsal_trace = dorsal_trace;
    frame_trace_data.ventral_trace = ventral_trace;
    frame_trace_data.midDorsal = midDorsal;
    frame_trace_data.head_coords = head_coords;
    frame_trace_data.boundary_angles = Bd_angle;
end
