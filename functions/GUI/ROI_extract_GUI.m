function ROI_extract_GUI(WormTrackerData)
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
    setappdata(0, 'ROIGUIFinished', 0);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Create the figure itself. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fig = figure('units','pixels',...                                          
        'position',[figwidth/4 50 figwidth figheight],...
        'menubar','figure',...
        'name','Image Enhancement',...
        'numbertitle','off',...
        'resize','off');
    fig.UserData = WormTrackerData;
    fig.UserData.I = WormTrackerData.PreProcessedData.ProcessedStacks.GFP_stack;
    smallstep=1/(length(fig.UserData.I)-1);                                                
    largestep=smallstep*10;  
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Create the axes for image display. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S.axL = axes('units','pixels',...                                            
        'position',[4*pad 6*pad figwidth-80*pad figheight-8*pad],...
        'fontsize',10,...
        'nextplot','replacechildren');
    S.axR = axes('units','pixels',...                                            
        'position',[46*pad 6*pad figwidth-80*pad figheight-8*pad],...
        'fontsize',10,...
        'nextplot','replacechildren');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Create a slider and an editbox for picking frames. %%%%%%%%%%%%%%%%%%
    S.sl = uicontrol('style','slide',...                                        
        'unit','pix', ...                          
        'position',[2*pad pad figwidth-40*pad 2*pad],...
        'min',1, ...
        'max',length(fig.UserData.I), ...
        'Value',1,...
        'SliderStep', [smallstep largestep]);
    S.ed = uicontrol('style','edit',...                                         
        'unit','pix', ...
        'position',[figwidth-37*pad pad 4*pad 2*pad],...
        'fontsize',12,...
        'string','1');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% create button group for background subtraction %%%%%%%%%%%%%%%%%%%%%
    S.ROIoptionsbttngroup = uipanel('unit','pix',...                            %The button group itself
        'Parent',fig,...
        'position',[figwidth-28*pad figheight-32*pad 25*pad 30*pad]);

    S.ROIoptionstext=uicontrol('style','text',...
        'parent',S.ROIoptionsbttngroup,...
        'unit','pix',...
        'position',[6.5*pad 27*pad 12*pad 2*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','ROI options');

    S.ROImergebox = uicontrol('style','checkbox',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ROIoptionsbttngroup,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[1.5*pad 24*pad 18*pad 2*pad],...                               %(see the callback function "smoothing")
        'fontsize',11,...
        'string','Merge adjacent ROIs = ', ...
        'Value',0);
    S.ROImerge = uicontrol('style','edit',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ROIoptionsbttngroup,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[19*pad 24*pad 2*pad 2*pad],...                               %(see the callback function "smoothing")
        'fontsize',10,...
        'string','2');

    S.ROIcenterbutton=uicontrol('style','radiobutton',...                          %Radio button for gaussian smoothing
        'parent',S.ROIoptionsbttngroup,...
        'position',[1.5*pad 20*pad 13*pad 2*pad],...
        'fontsize',11, ...
        'string','Center ROI',...
        'Value',0);
     S.centerROIwidthtext = uicontrol('style','text',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ROIoptionsbttngroup,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[2.5*pad 17*pad 12*pad 2*pad],...                              
        'fontsize',10.5,...
        'string','Width (0.1 - 0.9) =');
    S.centerROIwidth = uicontrol('style','edit',...                          
        'unit','pix',...                                                     
        'parent',S.ROIoptionsbttngroup,...                                            
        'position',[15*pad 17*pad 2*pad 2*pad],...                              
        'fontsize',10,...
        'string','1');

    S.ROIedgebutton = uicontrol('style','radiobutton',...                  
        'unit','pix',...
        'Parent', S.ROIoptionsbttngroup, ...
        'position',[1.5*pad 13*pad 13*pad 3*pad],...
        'fontsize',11,...
        'string','Edge ROI', ...
        'Value',1);
    S.ROIoffsettext = uicontrol('style','text',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ROIoptionsbttngroup,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[2.5*pad 10.5*pad 12*pad 2*pad],...                              
        'fontsize',10.5,...
        'string','Offset (0 - 2) =');
    S.offset = uicontrol('style','edit',...                          
        'unit','pix',...                                                     
        'parent',S.ROIoptionsbttngroup,...                                            
        'position',[15*pad 10.5*pad 2*pad 2*pad],...                              
        'fontsize',10,...
        'string','0.9');
    S.ROIwidthtext = uicontrol('style','text',...                             %Editbox for size of gaussian kernel. Note that this number will be used
        'unit','pix',...                                                       %as the radius of the filter, NOT the default "matrix size". This is to
        'parent',S.ROIoptionsbttngroup,...                                                %make the "size" argument behave the same as for the disk filter.
        'position',[2.5*pad 8*pad 12*pad 2*pad],...                              
        'fontsize',10.5,...
        'string','Width (0.1 - 0.9) =');
    S.ROIwidth = uicontrol('style','edit',...                          
        'unit','pix',...                                                     
        'parent',S.ROIoptionsbttngroup,...                                            
        'position',[15*pad 8*pad 2*pad 2*pad],...                              
        'fontsize',10,...
        'string','1');

    S.extractROIdatabutton = uicontrol('style','pushbutton',...                  
        'unit','pix',...
        'Parent', S.ROIoptionsbttngroup, ...
        'position',[3*pad 2*pad 17*pad 3*pad],...
        'fontsize',12,...
        'string','Update ROI data');  

    %%% create text to let user know what frame is being worked on %%%
    S.ROIstatustext=uicontrol('style','text',...                                      %Ttextbox describing the button group
        'unit','pix',...,
        'parent',fig,...
        'position',[figwidth-23*pad figheight-67*pad 20*pad 4*pad],...
        'fontsize',14,...
        'FontWeight', 'bold', ...
        'string','Starting up wait...', ...
        'Foregroundcolor','red',...
        'Visible','on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S.bodyptbuttongroup = uipanel('unit','pix',...                           
        'Parent',fig,...
        'position',[figwidth-28*pad figheight-40*pad 25*pad 5*pad]);

    S.bodyptoptionstext = uicontrol('style','text',...
        'parent',S.bodyptbuttongroup,...
        'unit','pix',...
        'position',[2*pad 1.5*pad 18*pad 2*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','Body point selection = ');
    
    default_pt = round(fig.UserData.PreProcessedData.ROI_Input.Num_midpoints/2);
    default_pt = num2str(default_pt);
    S.bodyptselection = uicontrol('style','edit',...                          
        'unit','pix',...                                                     
        'parent',S.bodyptbuttongroup,...                                            
        'position',[20*pad 1.5*pad 2.5*pad 2.5*pad],...                              
        'fontsize',11,...
        'string',default_pt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S.FinishButton = uicontrol('style','pushbutton',...                  
        'unit','pix',...
        'Parent', fig, ...
        'position',[figwidth-25.5*pad figheight-48*pad 20*pad 5*pad],...
        'fontsize',12,...
        'string','Finish');  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Set callback functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set([S.ROIcenterbutton,S.ROIedgebutton], 'Callback',{@extract_ROI,S});
    set([S.ROImerge, S.ROIwidth, S.offset,S.extractROIdatabutton], ...
        'Callback',{@ROIoptionchekc,S});
    set([S.ed,S.sl],'Callback',{@switchframe,S});
    set(S.FinishButton,'Callback',{@Finish_function,S});
    %set(S.bodyptselection, 'Callback',{@ptselectioncheck,S})

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% start first frame ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% before drawing the first ROI we need ROI data %%%
    extract_ROI(fig,[],S);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Move slider or write in frame editbox callback function                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = switchframe(varargin)                                         
        S=varargin{3};
        h=varargin{1};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        GFP_stack = data.PreProcessedData.ProcessedStacks.GFP_stack;
        RFP_stack = data.PreProcessedData.ProcessedStacks.RFP_stack;

        if get(S.ROIedgebutton,'Value') ==1
            set(S.ROIcenterbutton,'Value',0);
            ROI_mask.dorsal = data.ROI_Data.edge_ROI.ROI_d_mask;
            ROI_mask.ventral = data.ROI_Data.edge_ROI.ROI_v_mask; 
        elseif get(S.ROIcenterbutton,'Value')==1
            set(S.ROIedgebutton,'Value',0);
            ROI_mask.center = data.ROI_Data.ROI_center_mask;
        end
                                                  
        switch h                                                                    %Who called?
            case S.ed                                                               %The editbox called...
                sliderstate =  get(S.sl,{'min','max','value'});                     % Get the slider's info
                enteredvalue = str2double(get(h,'string'));                         % The new frame number
                
                if enteredvalue >= sliderstate{1} && enteredvalue <= sliderstate{2} %Check if the new frame number actually exists
                    slidervalue=round(enteredvalue);
                    set(S.sl,'Value',slidervalue)                                   %If it does, move the slider there
                else
                    set(h,'string',sliderstate{3})                                  %User tried to set slider out of range, keep value
                end
            case S.sl                                                               %The slider called...
                slidervalue=round(get(h,'Value'));                                  % Get the new slider value
                set(S.ed,'string',num2str(slidervalue));                                      % Set editbox to current slider value
        end
        
        % generate boundary trace
        pt_selection = round(str2double(get(S.bodyptselection,'string')));
        ROI_boundary = bwboundaries(ROI_mask.dorsal{slidervalue}{pt_selection}, 'noholes');
        
        % Display the selected frame
        axes(S.axL); % Ensure we plot on the correct axes
        imshow(GFP_stack{slidervalue},[]);
        hold(S.axL, 'on');
        plot(ROI_boundary{1}(:,2), ROI_boundary{1}(:,1), 'r', 'LineWidth', 1);
        hold(S.axL, 'off');

        % Display the selected frame
        axes(S.axR); % Ensure we plot on the correct axes
        imshow(RFP_stack{slidervalue},[]);
        hold(S.axR, 'on');
        plot(ROI_boundary{1}(:,2), ROI_boundary{1}(:,1), 'r', 'LineWidth', 2);
        hold(S.axR, 'off');
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% callaback fxn to check ROI option  %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = ROIoptionchekc(varargin)
        h = varargin{1};
        S = varargin{3};
    
        if (h==S.ROImerge) && (str2double(get(h,'string'))<2) 
            set(h,'string','2');
            return
        end

        if (h==S.ROIwidth) && (str2double(get(h,'string'))<0.1)
            set(h,'string','0.1');                              
        elseif (h==S.ROIwidth) && (str2double(get(h,'string'))>0.9)
            set(h,'string','0.9');                                
            return
        end

        if (h==S.offset) && (str2double(get(h,'string'))<0) 
            set(h,'string','0');                               
        elseif (h==S.offset) && (str2double(get(h,'string'))>2)
            set(h,'string','2');
            return
        end

        set(S.ROIstatustext,'string','Curating data...',...
            'ForegroundColor','r')
        extract_ROI(h,[],S)
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% callaback fxn to check ROI option  %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = extract_ROI(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;

        
        %%% collect all user input partameters %%%
        data.ROI_Input.edge_offset=str2double(get(S.offset,'String'));
        data.ROI_Input.edge_width=str2double(get(S.ROIwidth,'String'));
        data.ROI_Input.center_width = str2double(get(S.centerROIwidth,'string'));
        if get(S.ROImergebox,'value')==1
            data.ROI_Input.n_merge=str2double(get(S.ROImerge,'String'));
        else
            data.ROI_Input.n_merge = 1;
        end
        
        %%% determine ROI based on mask %%%
        if get(S.ROIedgebutton,'Value')==1  
            set(S.ROIcenterbutton,'Value',0);
            data.ROI_Data.edge_ROI = create_edge_ROIs(data);
            % calculate Fluorescensce intensity within the ROI 
            % coordinates define above.
            data.ROI_Data.edge_intensity_data = edge_ROI_intensity(data);
            fig.UserData = data;                                                                
        elseif get(S.ROIcenterbutton,'Value')==1
            set(S.ROIedgebutton,'Value',0);
            data.ROI_Data = create_center_ROIs(data);
            % calculate Fluorescensce intensity within the ROI 
            % coordinates define above.
            data.ROI_Data.center_intensity_data = center_ROI_intensity(data);
            fig.UserData = data;
        end

        set(S.ROIstatustext,'string','Ready',...
            'ForegroundColor','g')

        %%% call slider to draw first frame %%%
        switchframe(S.ed,[],S) 
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% callaback fxn to check ROI option  %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function []=Finish_function(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        
        % export data as csv
        export_intensity_data(data,S)
        export_curvature_data(data)

        %collect data from this secton in a variable
        ROI_Info.ROI_Data = data.ROI_Data;
        ROI_Info.ROI_Input = data.ROI_Input;

        % Set a flag indicating GUI is done
        setappdata(0, 'ROIGUIFinished', 1);
        setappdata(0,'ROI_Info', ROI_Info);

        %close app
        pause(1);
        close(gcf);
    end
end