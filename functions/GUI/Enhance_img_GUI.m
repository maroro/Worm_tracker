function Enhance_img_GUI(WormTrackerData)
    % Verify the inputs
   if nargin < 1 || isempty(WormTrackerData) 
        error('StackSlider requires two non-empty inputs: an image stack and trace data.');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Build the figure for the GUI.                                          
% All handles and the image stack are stored in the struct SS             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    SCRSZ=get(0,'ScreenSize');                                                 %Get user's screen size
    figheight=SCRSZ(4)-300;                                                    %A reasonable height for the GUI
    figwidth=SCRSZ(4)*1.1;                                                     %A reasonable width for the GUI (the height of the screen*1.1)
    pad=10;                                                                    %Inside padding in the GUI
    setappdata(0, 'enhnaceGUIFinished', 0);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Create the figure itself. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fig = figure('units','pixels',...                                          
        'position',[figwidth/4 50 figwidth figheight],...
        'menubar','figure',...
        'name','Image Enhancement',...
        'numbertitle','off',...
        'resize','off');
    fig.UserData = WormTrackerData;
    fig.UserData.I = WormTrackerData.SplitChannels.RawGFP;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Create the axes for image display. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S.axL = axes('units','pixels',...                                            
        'position',[4*pad 6*pad figwidth-76*pad figheight-8*pad],...
        'fontsize',10,...
        'nextplot','replacechildren');
    S.axR = axes('units','pixels',...                                            
        'position',[51*pad 6*pad figwidth-76*pad figheight-8*pad],...
        'fontsize',10,...
        'nextplot','replacechildren');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% create button group for background subtraction %%%%%%%%%%%%%%%%%%%%%
    S.bgbutgrp = uipanel('unit','pix',...                            %The button group itself
        'Parent',fig,...
        'position',[figwidth-23*pad figheight-10*pad 21*pad 8.5*pad]);
    S.bgsubtract=uicontrol('style','checkbox',...                          %Radio button for gaussian smoothing
        'parent',S.bgbutgrp,...
        'position',[1*pad 5*pad 25*pad 2*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','Subtract background',...
        'Value',0);
    S.bgdefinebutton = uicontrol('style','pushbutton',...                  
        'unit','pix',...
        'Parent', S.bgbutgrp, ...
        'position',[4*pad 1*pad 13*pad 3*pad],...
        'fontsize',10,...
        'string','Select Background');                                           
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Create a button group for smoothing. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S.smbutgrp = uipanel('unit','pix',...                                %The button group itself
        'position',[figwidth-23*pad figheight-19*pad 21*pad 8*pad]);
    S.medfilter=uicontrol('style','checkbox',...                                   
        'parent',S.smbutgrp,...
        'position',[1*pad 5*pad 20*pad 2*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...,
        'string','Median filter',...
        'Value',1);
    S.smgausssizetext=uicontrol('style','text',...                            
        'unit','pix',...        
        'parent',S.smbutgrp,...
        'position',[3.5*pad 1.5*pad 8*pad 2*pad],...
        'fontsize',10,...
        'string','Filter size:');
    S.smfiltersize = uicontrol('style','edit',...                              
        'unit','pix',...                                                       
        'parent',S.smbutgrp,...                                                
        'position',[12*pad 1.5*pad 4*pad 2*pad],...                             
        'fontsize',10,...
        'string','10');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% button group for contrast enhancement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S.ctbutgrp = uipanel(fig,'unit','pix',...                                %The button group itself
        'position',[figwidth-23*pad figheight-37*pad 21*pad 17*pad]);
    S.cttext=uicontrol('style','text',...
        'parent',S.ctbutgrp,...%Ttextbox describing the button group
        'unit','pix',...
        'position',[0.25*pad 14*pad 20*pad 2*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','Contrast enhancement');
    %%%%% adaptive histogram control %%%%%
    S.CLAHE = uicontrol('style','checkbox',...                           % Checkbox for CLAHE
        'parent',S.ctbutgrp,...
        'position',[0.5*pad 11.5*pad 18*pad 2*pad],...
        'fontsize',10,...    
        'string','Histogram Equalization', ...
        'Value',0);
    S.ctAHElimittext=uicontrol('style','text',...                              %Textbox "size" to set filter size. 
        'unit','pix',...        
        'parent',S.ctbutgrp,...
        'position',[5*pad 9*pad 4*pad 2*pad],...
        'fontsize',10,...
        'string','Limit:');
    S.ctAHElimit = uicontrol('style','edit',...                                %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ctbutgrp,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[9*pad 9*pad 6*pad 2*pad],...                            %(see the callback function "smoothing")
        'fontsize',10,...
        'string','0.02');
    %%%%% unmask and sharpen control %%%%%
    S.ctunsharpmask=uicontrol('style','checkbox',...                              %Radio button for gaussian smoothing
        'parent',S.ctbutgrp,...
        'position',[0.5*pad 5*pad 18*pad 4*pad],...
        'fontsize',10,...    
        'string','Unsharp and mask',...
        'Value',0);
    S.ctumaskradiustext=uicontrol('style','text',...                           %Textbox "size" to set filter size. 
        'unit','pix',...        
        'parent',S.ctbutgrp,...
        'position',[0.5*pad 3.5*pad 5.5*pad 2*pad],...
        'fontsize',10,...
        'string','Radius:');
    S.ctumaskradius = uicontrol('style','edit',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ctbutgrp,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[6*pad 3.5*pad 3*pad 2*pad],...                             %(see the callback function "smoothing")
        'fontsize',10,...
        'string','1');
    S.ctumaskamounttext=uicontrol('style','text',...                           %Textbox "size" to set filter size. 
        'unit','pix',...        
        'parent',S.ctbutgrp,...
        'position',[11*pad 3.5*pad 5.5*pad 2*pad],...
        'fontsize',10,...
        'string','Amount:');
    S.ctumaskamount = uicontrol('style','edit',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ctbutgrp,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[16.5*pad 3.5*pad 3*pad 2*pad],...                               %(see the callback function "smoothing")
        'fontsize',10,...
        'string','1');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% panel for selecting masking erosion and dilation parameters %%%%%%%
    S.MaskOptionpanel = uipanel(fig,'unit','pix',...                                
        'position',[figwidth-23*pad figheight-56*pad 21*pad 18*pad]);
    S.Maskoptiontext=uicontrol('style','text',...                           %Textbox "size" to set filter size. 
        'unit','pix',...        
        'parent',S.MaskOptionpanel,...
        'position',[1.2*pad 15*pad 18*pad 2*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','Masking options');
    S.createmaskbutton = uicontrol('style','pushbutton',...                  
        'unit','pix',...
        'Parent', S.MaskOptionpanel, ...
        'position',[2.6*pad 11*pad 15*pad 3*pad],...
        'fontsize',12,...
        'string','Create mask');  
    S.maskdilationtext = uicontrol('style','text',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.MaskOptionpanel,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[2.5*pad 5*pad 11*pad 2*pad],...                              
        'fontsize',11,...
        'string','Mask dilation =');
    S.Maskdilation = uicontrol('style','edit',...                          
        'unit','pix',...                                                     
        'parent',S.MaskOptionpanel,...                                            
        'position',[13.6*pad 5*pad 2*pad 2*pad],...                              
        'fontsize',10,...
        'string','30');
    S.erosionbox = uicontrol('style','checkbox',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.MaskOptionpanel,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[1.5*pad 8*pad 18*pad 2*pad],...                               %(see the callback function "smoothing")
        'fontsize',11,...
        'string','Erosion =', ...
        'Value',1);
    S.erosion = uicontrol('style','edit',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.MaskOptionpanel,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[10.1*pad 8*pad 2*pad 2*pad],...                               %(see the callback function "smoothing")
        'fontsize',10,...
        'string','2');
     S.midpointtext = uicontrol('style','text',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.MaskOptionpanel,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[2.5*pad 2*pad 12*pad 2*pad],...                              
        'fontsize',11,...
        'string','# of midpoints =');
    S.midpoint = uicontrol('style','edit',...                          
        'unit','pix',...                                                     
        'parent',S.MaskOptionpanel,...                                            
        'position',[14.5*pad 2*pad 2*pad 2*pad],...                              
        'fontsize',10,...
        'string','30');
    
%%%%%%Create a "reset" button to reset everything to defaults%%%%%%%%%%%%%%
    S.resetbutton = uicontrol('style','pushbutton',...                   %Pushbutton to reset everything to defaults
        'unit','pix',...
        'parent',fig,...
        'position',[figwidth-23*pad figheight-60*pad 10*pad 4*pad],...
        'fontsize',11,...
        'FontWeight', 'bold', ...
        'string','Reset');
    
%%%%%%Create a "Next" button to reset everything to defaults%%%%%%%%%%%%%%
    S.nexttbutton = uicontrol('style','pushbutton',...                   %Pushbutton to reset everything to defaults
        'unit','pix',...
        'position',[figwidth-12*pad figheight-60*pad 10*pad 4*pad],...
        'fontsize',11,...
        'FontWeight', 'bold', ...
        'string','Next');
    %%% create text to let user know what frame is being worked on %%%
    S.nexttext=uicontrol('style','text',...                                      %Ttextbox describing the button group
        'unit','pix',...,
        'parent',fig,...
        'position',[figwidth-23*pad figheight-64*pad 20*pad 4*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','', ...
        'Visible','off');
       
%%%%%%Set callback functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                                               
    set(S.bgdefinebutton,'Callback',{@select_bg,S});
    set(S.bgsubtract, 'Callback',{@bg_subtract_check,S});

    set(S.medfilter, 'Callback',{@EnhanceFrame,S});
    set(S.smfiltersize,'Callback',{@smoothinputcheck,S});

    set([S.CLAHE, S.ctunsharpmask],'Callback',{@EnhanceFrame,S});
    set([S.ctAHElimit, S.ctumaskamount, S.ctumaskradius], ...
        'Callback',{@ctinputcheck,S})

    set(S.createmaskbutton,'Callback', {@CreateMask,S});
    set([S.midpoint, S.erosion,S.Maskdilation],'Callback',{@MaskInputCheck,S})

    set(S.resetbutton,'Callback', {@resetfunction,S});                   %Callback function for the reset button
    set(S.nexttbutton,'Callback', {@nextfuncfion,S});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Draw first frame with presets %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    EnhanceFrame(fig,[],S)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%Select background area %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = select_bg(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        height_Img = size(data.I{1},1); width_Img = size(data.I{1},2);
    
        xlim([1,width_Img]);
        ylim([1, height_Img]);
    
        % USER INPUT FOR ROI1
        [crop_x_BG_1, crop_y_BG_1] = ginput_y(1);
        %round to nearest integer
        crop_x_BG_1 = floor(crop_x_BG_1); crop_y_BG_1 = floor(crop_y_BG_1);    
        % plot red cursors passing by the first selected point
        g_line_1 = plot([1 width_Img], [crop_y_BG_1 crop_y_BG_1], '-m');
        g_line_2 = plot([crop_x_BG_1 crop_x_BG_1], [1 height_Img], '-m');
        
        % repeat agaim to find second corner of GFP half
        [crop_x_BG_2, crop_y_BG_2] = ginput_y(1);
        crop_x_BG_2 = floor(crop_x_BG_2); crop_y_BG_2 = floor(crop_y_BG_2);     
        
        %plot bg box
        delete(g_line_1);delete(g_line_2)
        plot([crop_x_BG_1 crop_x_BG_2], [crop_y_BG_2 crop_y_BG_2], '-y');
        plot([crop_x_BG_2 crop_x_BG_2], [crop_y_BG_1 crop_y_BG_2], '-y');
        plot([crop_x_BG_1 crop_x_BG_2], [crop_y_BG_1 crop_y_BG_1], '-y');
        plot([crop_x_BG_1 crop_x_BG_1], [crop_y_BG_1 crop_y_BG_2], '-y');
    
        % Specify the position (x, y) for the text, the string itself, and any formatting options
        textPositionX = (crop_x_BG_1 + crop_x_BG_2) / 2; % For example, centered between the two x points
        textPositionY = crop_y_BG_1 - 10; % Position the text slightly above the top line of the ROI
    
        % Add the text to the image
        text(textPositionX, textPositionY, 'Background', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 10, ...
        'Color', 'yellow');
        axis equal tight 
    
        % collect the x,y coordinates from the input
        bg_coords.X_BG_1 = crop_x_BG_1;
        bg_coords.X_BG_2 = crop_x_BG_2;
        bg_coords.Y_BG_1 = crop_y_BG_1;
        bg_coords.Y_BG_2 = crop_y_BG_2;
        bg_coords.BGXmin = min([crop_x_BG_1 crop_x_BG_2]);
        bg_coords.BGXmax = max([crop_x_BG_1 crop_x_BG_2]);
        bg_coords.BGYmin = min([crop_y_BG_1 crop_y_BG_2]);
        bg_coords.BGYmax = max([crop_y_BG_1 crop_y_BG_2]);
    
        % Update the GUI data
        fig.UserData.bg_coords = bg_coords;
        %pass the info to Enhance frame so we can see it in bg subtract is
        %already pressed
        set(S.bgsubtract,'Value',1);
        EnhanceFrame(fig,[],S);
    end
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% chnage background subtraction selection %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = bg_subtract_check(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel"); 
        data = fig.UserData;
    
        if ~isfield(data ,'bg_coords') || isempty(data.bg_coords)
            uiwait(msgbox(['Background area has not been selected. Please' ...
                ' press on "Select Background" before selecting this option'], 'Warning', 'warn'));
            set(S.bgsubtract,'value',0);
            data.bg_coords = [];
        else
            EnhanceFrame(fig,[],S)
        end
        
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% callaback fxn to check smoothing size %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = smoothinputcheck(varargin)
        h = varargin{1};
        S = varargin{3};
    
        if (h==S.smfiltersize) && (str2double(get(h,'string'))<1) %Check if the filter size is set to less than one
            set(h,'string','1');                                 % If it is, set it to one and return without action
            return
        end
    
        EnhanceFrame(varargin{1},[],S)
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% callaback fxn to check smoothing size %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = ctinputcheck(varargin)
        h = varargin{1};
        S = varargin{3};
    
        if (h==S.ctAHElimit) && (str2double(get(h,'string'))<0) 
            set(h,'string','0.01');                                
            return
        end
    
        if (h==S.ctumaskamount) && (str2double(get(h,'string'))<0) 
            set(h,'string','0.1');                                 
            return
        end
        if (h==S.ctumaskradius) && (str2double(get(h,'string'))<0.1) 
            set(h,'string','0.1');                                
            return
        end
    
        EnhanceFrame(varargin{1},[],S)
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% create output image %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = EnhanceFrame(varargin)
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        S = varargin{3};
        data.WorkingFrame.enhanced_frame = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BG subtraction:
        if S.bgsubtract.Value == 1
            %if no enhancement was performed, EnhancedFrame should be
            %empty so we would start with the raw image
            if isempty(data.WorkingFrame.enhanced_frame)
                workingframe = data.I{1};
            else
                workingframe = data.WorkingFrame.enhanced_frame;
            end
            %bg subtraction
            data.WorkingFrame.enhanced_frame = bg_subtract(workingframe, data);
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Smoothing:
        if S.medfilter.Value==1
            %if no enhancement was performed, EnhancedFrame should be
            %empty so we would start with the raw image
            if isempty(data.WorkingFrame.enhanced_frame)
                workingframe = data.I{1};
            else
                workingframe = data.WorkingFrame.enhanced_frame;
            end
            % Create a Gaussian filter kernel
            %sigma = str2double(get(S.smgausssigma,'string'));
            data.filtSz = str2double(get(S.smfiltersize,'string')); % Can be determined based on sigma
            medfiltFrame = medfilt2(workingframe, [data.filtSz data.filtSz]);
            
            data.WorkingFrame.enhanced_frame = medfiltFrame;
        end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Contrast enhancement:
        %%% CLAHE %%%
        if S.CLAHE.Value == 1 
            %if no enhancement was performed, EnhancedFrame should be
            %empty so we would start with the raw image
            if isempty(data.WorkingFrame.enhanced_frame)
                workingframe = data.I{1};
            else
                workingframe = data.WorkingFrame.enhanced_frame;
            end
            data.CLAHE_limit = str2double(get(S.ctAHElimit,'string'));
            data.WorkingFrame.enhanced_frame = CLAHE(workingframe, data);
        end
        %%% Unsharp & mask %%%
        if S.ctunsharpmask.Value == 1 
            if isempty(data.WorkingFrame.enhanced_frame)
                workingframe = data.I{1};
            else
                workingframe = data.WorkingFrame.enhanced_frame;
            end
            % Apply unsharp masking
            data.rad = str2double(get(S.ctumaskradius,'string'));
            data.amnt = str2double(get(S.ctumaskamount,'string'));
            sharpenedframe = imsharpen(workingframe,'Radius',data.rad,'Amount',data.amnt);
            data.WorkingFrame.enhanced_frame = sharpenedframe;
        end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if isempty(data.WorkingFrame.enhanced_frame)
            data.WorkingFrame.enhanced_frame = data.I{1};
        end
        
        %store this new frame so we can call it in other functions
        data.EnhancedFrame = data.WorkingFrame.enhanced_frame;
        fig.UserData = data;

%%%%%%%%%%%%%%%%%%% plot visualized available input %%%%%%%%%%%%%%%%%%%%%%%
        height_Img = size(data.EnhancedFrame,1); width_Img = size(data.EnhancedFrame,2);
        xlim([1,width_Img]);
        ylim([1, height_Img]);

        %%%%% plot the image onto left side %%%%%%
        axes(S.axL);
        imshow(data.EnhancedFrame,[]); colormap (S.axL,'gray');                     
        axis equal tight; hold(S.axL,'on');
        
        %%%%%% plot right side if field is available %%%%%%%
        if  isfield(data.WorkingFrame,'frame_mask_data') & ...
            ~isempty(data.WorkingFrame.frame_mask_data.BW_Mask_Frame)

            height_mask = size(data.WorkingFrame.frame_mask_data.BW_Mask_Frame,1); 
            width_mask = size(data.WorkingFrame.frame_mask_data.BW_Mask_Frame,2);
            xlim([1,width_mask]);
            ylim([1, height_mask]);

            axes(S.axR);
            imshow(data.WorkingFrame.frame_mask_data.BW_Mask_Frame,[]); 
            colormap (S.axR,'gray');                       
            axis equal tight;
        elseif ~isfield(data.WorkingFrame,'frame_mask_data')
            axes(S.axR);
            imshow([],[])
            colormap (S.axR,'gray');
            axis equal tight;
        end
        
        %%%%% If background was selected, plot it %%%%%%
         if  isfield(data,'bg_coords') & ~isempty(data.bg_coords)
            %plot BG box
            plot(S.axL,[data.bg_coords.X_BG_1, data.bg_coords.X_BG_2], ...
                [data.bg_coords.Y_BG_2, data.bg_coords.Y_BG_2], '-y');
            plot(S.axL,[data.bg_coords.X_BG_2, data.bg_coords.X_BG_2], ...
                [data.bg_coords.Y_BG_1, data.bg_coords.Y_BG_2], '-y');
            plot(S.axL,[data.bg_coords.X_BG_1, data.bg_coords.X_BG_2], ...
                [data.bg_coords.Y_BG_1, data.bg_coords.Y_BG_1], '-y');
            plot(S.axL,[data.bg_coords.X_BG_1, data.bg_coords.X_BG_1], ...
                [data.bg_coords.Y_BG_1, data.bg_coords.Y_BG_2], '-y');
        
            % Specify the position (x, y) for the text, the string itself, and any formatting options
            textPositionX = (data.bg_coords.X_BG_1 + data.bg_coords.X_BG_2) / 2; % For example, centered between the two x points
            textPositionY = data.bg_coords.Y_BG_1 - 10; % Position the text slightly above the top line of the ROI
        
            % Add the text to the image
            text(S.axL,textPositionX, textPositionY, 'Background', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 11, ...
            'Color', 'yellow')
         end
         %%% If mask was created, plot it %%%%
         if isfield(data.WorkingFrame,'frame_trace_data') & ...
                 ~isempty(data.WorkingFrame.frame_trace_data)
             dorsal_path = data.WorkingFrame.frame_trace_data.dorsal_trace;                                              
             ventral_path = data.WorkingFrame.frame_trace_data.ventral_trace;
             midDorsal = data.WorkingFrame.frame_trace_data.midDorsal;
             midPoints = data.WorkingFrame.frame_midline_data.midpoints;
        
             plot(S.axL, dorsal_path(:,2), dorsal_path(:,1), ...
                 'Color', '#D95319', ...
                 'LineStyle', '-')
             plot(S.axL,ventral_path(:,2), ventral_path(:,1), ...
                 'Color','#4DBEEE', ...
                 'LineStyle','-')
             plot(S.axL,midDorsal(1,2), midDorsal(1,1), 'wo','MarkerSize',4)
             plot(S.axL,midPoints(:,1), midPoints(:,2), ...
                 'Marker', 'o','MarkerSize',3,'MarkerEdgeColor','#FFFFFF', ...
                 'LineStyle', '-','Color','w');
              
         end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Call back function for Apply button %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = CreateMask(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        
        data.WorkingFrame.frame_mask_data = create_mask(data,S);
        data.WorkingFrame.frame_trace_data = trace_worm(data);
        data.ROI_Input.Num_midpoints = str2double(S.midpoint.String);
        data.WorkingFrame.frame_midline_data = midline_creation(data);
        %ensure that data is assigned to the UI global var UserData
        fig.UserData = data;

        EnhanceFrame(varargin{1},[],S)
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% callaback fxn to check mask options %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = MaskInputCheck(varargin)
        h = varargin{1};
        S = varargin{3};
    
        if (h==S.erosion) && (str2double(get(h,'string'))<1) 
            set(h,'string','1');
            return
        elseif (h==S.erosion) 
            erosion_integer = round(str2double(get(h,'string')));
            set(h,'string',num2str(erosion_integer));
            return
        end
    
        if (h==S.midpoint) && (str2double(get(h,'string'))<1) 
            set(h,'string','1');                                 
            return
        elseif (h==S.midpoint) 
            midpoint_integer = round(str2double(get(h,'string')));
            set(h,'string',num2str(midpoint_integer));
            return
        end

        if (h==S.Maskdilation) && (str2double(get(h,'string'))<1) 
            set(h,'string','1');                                 
            return
        elseif (h==S.Maskdilation) 
            Mask_dilation_integer = round(str2double(get(h,'string')));
            set(h,'string',num2str(Mask_dilation_integer));
            return
        end
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Call back function for reset button %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = resetfunction(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
    
        set(S.bgsubtract,'Value',0)
        data.bg_coords = {};
    
        set(S.medfilter,'Value',1);
        set(S.smfiltersize,'string','10')
        
        set(S.CLAHE,'value',0);
        set(S.ctunsharpmask,'Value',0);
        set(S.ctAHElimit,'string','0.02');
        set(S.ctumaskamount,'string','1');
        set(S.ctumaskradius,'string','1');

        set(S.erosionbox,'Value',1)
        set(S.erosion,'String','2')

        fields ={'frame_mask_data','frame_midline_data','frame_trace_data'};
        data.WorkingFrame=rmfield(data.WorkingFrame,fields);
        
        %ensure that data is assigned to the UI global var UserData
        fig.UserData = data;
    
        EnhanceFrame(fig,[],S)
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% callaback fxn when user clicks next %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function []=nextfuncfion(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;

        data.PreProcessInput.bgsubtractSelection = S.bgsubtract.Value;
        data.PreProcessInput.medfilterSelection = S.medfilter.Value;
        data.PreProcessInput.medfilterSize = S.medfilter.String;
        data.PreProcessInput.CLAHESelection = S.CLAHE.Value;
        data.PreProcessInput.CLAHELimit = str2double(S.ctAHElimit.String);
        data.PreProcessInput.UnsharpSelection = S.ctunsharpmask.Value;
        data.PreProcessInput.UnsharpRadius = str2double(S.ctumaskradius.String);
        data.PreProcessInput.UnsharpAmount = str2double(S.ctumaskamount.String);

        data.MaskInput.ErosionSelection = S.erosionbox.Value;
        data.MaskInput.MaskErosion = str2double(S.erosion.String);
        data.MaskInput.MaskDilation = str2double(S.Maskdilation.String);

        data.ROI_Input.Num_midpoints = str2double(S.midpoint.String);

        fig.UserData=data;

        for k = 1:length(data.I)

            set(S.nexttext, ...
                'string',['Working on Frame: ',                     ...
                           num2str(k),'/',num2str(length(data.I))], ...
                'Visible', 'on');
                drawnow;

            data.WorkingFrame = NextEnhance(data,k,S);

            data.ProcessedStacks.GFP_stack{k} = data.WorkingFrame.EnhancedFrame{1};
            data.ProcessedStacks.RFP_stack{k} = data.WorkingFrame.EnhancedFrame{2};
            data.ProcessedStacks.mask_stack{k} = data.WorkingFrame.frame_mask_data.BW_Mask_Frame;

            data.ProcessedStacks.trace_data.dorsal_trace{k} = data.WorkingFrame.frame_trace_data.dorsal_trace;
            data.ProcessedStacks.trace_data.ventral_trace{k} = data.WorkingFrame.frame_trace_data.ventral_trace;
            data.ProcessedStacks.trace_data.head_coords{k} = data.WorkingFrame.frame_trace_data.head_coords;
            data.ProcessedStacks.trace_data.dorsal_midpoint{k} = data.WorkingFrame.frame_trace_data.midDorsal;

            data.ProcessedStacks.midline_data.curvature{k} = data.WorkingFrame.frame_midline_data.curvature;
            data.ProcessedStacks.midline_data.midpoints{k} = data.WorkingFrame.frame_midline_data.midpoints;
            data.ProcessedStacks.midline_data.dorsal_points{k}(:,1) = data.WorkingFrame.frame_midline_data.X_d;    
            data.ProcessedStacks.midline_data.dorsal_points{k}(:,2) = data.WorkingFrame.frame_midline_data.Y_d;
            data.ProcessedStacks.midline_data.ventral_points{k}(:,1) = data.WorkingFrame.frame_midline_data.X_v;    
            data.ProcessedStacks.midline_data.ventral_points{k}(:,2) = data.WorkingFrame.frame_midline_data.Y_v;
            
        end

        %store output stacks
        fig.UserData = data;
        % now we store all new data created from this step onto the overall
        % data class structure called WormTrackerData
        PreProcessedData.ProcessedStacks = data.ProcessedStacks;
        PreProcessedData.MaskInput = data.MaskInput;
        PreProcessedData.PreProcessInput = data.PreProcessInput;
        PreProcessedData.ROI_Input = data.ROI_Input;

        % Set a flag indicating GUI is done
        setappdata(0, 'enhnaceGUIFinished', 1);
        setappdata(0,'PreProcessedData', PreProcessedData);

        %close app
        pause(1);
        close(gcf);
    end
end










