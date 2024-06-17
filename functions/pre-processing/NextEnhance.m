function WorkingFrame = NextEnhance(data,k,S)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BG subtraction:
    workingframe{1} = data.SplitChannels.RawGFP{k};
    workingframe{2} = data.SplitChannels.RawRFP{k};
    EnhancedFrameGFP = [];
    EnhancedFrameRFP = [];
    if data.PreProcessInput.bgsubtractSelection == 1  
        EnhancedFrameGFP = bg_subtract(workingframe{1}, data);
        EnhancedFrameRFP = bg_subtract(workingframe{2}, data);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Smoothing:
    if data.PreProcessInput.medfilterSelection==1
        %if no enhancement was performed, S.EnhancedFrame should be
        %empty so we would start with the raw image
        if isempty(EnhancedFrameGFP) || isempty(EnhancedFrameRFP)
            workingframe{1} = data.SplitChannels.RawGFP{k};
            workingframe{2} = data.SplitChannels.RawRFP{k};
        else
            workingframe{1} = EnhancedFrameGFP;
            workingframe{2} = EnhancedFrameRFP;
        end
        % Create a Gaussian filter kernel
        %sigma = str2double(get(S.smgausssigma,'string'));
        data.filtSz = str2double(get(S.smfiltersize,'string')); % Can be determined based on sigma
        medfiltFrameGFP = medfilt2(workingframe{1}, [data.filtSz data.filtSz]);
        medfiltFrameRFP = medfilt2(workingframe{2}, [data.filtSz data.filtSz]);
        
        EnhancedFrameGFP = medfiltFrameGFP;
        EnhancedFrameRFP = medfiltFrameRFP;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Contrast enhancement:
    %%% CLAHE %%%
    if data.PreProcessInput.CLAHESelection == 1 
        %if no enhancement was performed, S.EnhancedFrame should be
        %empty so we would start with the raw image
        if isempty(EnhancedFrameGFP) || isempty(EnhancedFrameRFP)
            workingframe{1} = data.SplitChannels.RawGFP{k};
            workingframe{2} = data.SplitChannels.RawRFP{k};
        else
            workingframe{1} = EnhancedFrameGFP;
            workingframe{2} = EnhancedFrameRFP;
        end
        data.CLAHE_limit = data.PreProcessInput.CLAHELimit;
        EnhancedFrameGFP = CLAHE(workingframe{1}, data);
        EnhancedFrameRFP = CLAHE(workingframe{2}, data);
    end
    %%% Unsharp & mask %%%
    if data.PreProcessInput.UnsharpSelection == 1 
        if isempty(EnhancedFrameGFP) || isempty(EnhancedFrameRFP)
            workingframe{1} = data.SplitChannels.RawGFP{k};
            workingframe{2} = data.SplitChannels.RawRFP{k};
        else
            workingframe{1} = EnhancedFrameGFP;
            workingframe{2} = EnhancedFrameRFP;
        end
        % Apply unsharp masking
        rad = data.PreProcessInput.UnsharpRadius;
        amnt = data.PreProcessInput.UnsharpAmount;
        sharpenedframeGFP = imsharpen(workingframe{1},'Radius',rad,'Amount',amnt);
        sharpenedframeRFP = imsharpen(workingframe{2},'Radius',rad,'Amount',amnt);
        EnhancedFrameGFP = sharpenedframeGFP;
        EnhancedFrameRFP = sharpenedframeRFP;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(EnhancedFrameGFP) || isempty(EnhancedFrameRFP)
        EnhancedFrameGFP = data.SplitChannels.RawGFP{k};
        EnhancedFrameRFP = data.SplitChannels.RawRFP{k};
    end

    WorkingFrame.EnhancedFrame{1} = EnhancedFrameGFP;
    WorkingFrame.EnhancedFrame{2} = EnhancedFrameRFP;
    % these must run in the order as the output of one function becomes the
    % input of the next
    WorkingFrame.frame_mask_data = create_mask_stack(data,S,WorkingFrame);
    WorkingFrame.frame_trace_data = trace_worm_stack(data,WorkingFrame,k);
    WorkingFrame.frame_midline_data = create_midline_stack(data,WorkingFrame);
end