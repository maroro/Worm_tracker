function []= Channel_split_GUI(WormTrackerData)
    % Verify the inputs
    if nargin < 1 || isempty(WormTrackerData) 
        error('StackSlider requires two non-empty inputs: an image stack and trace data.');
    end

   setappdata(0, 'SplitGUIFinished', 0);% this signals the code to pause unti user clicks next                            

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Build the figure for the GUI.                                          
% All handles and the image stack are stored in the struct SS             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    SCRSZ=get(0,'ScreenSize');                                                  %Get user's screen size
    figheight=SCRSZ(4)-300;                                                     %A reasonable height for the GUI
    figwidth=SCRSZ(4)*1.1;                                                      %A reasonable width for the GUI (the height of the screen*1.1)
    pad=10;                                                                     %Inside padding in the GUI                                                  %Step the slider will take when moved by clicking in the slider: 10 frames
    
%%%%%%Create the figure itself. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fig = figure('units','pixels',...                                          
        'position',[figwidth/2, 50, figwidth, figheight,],...
        'menubar','figure',...
        'name','Channel Split',...
        'numbertitle','off',...
        'resize','on');
    %extract raw img from Img       
    fig.UserData = WormTrackerData;
    S.I = fig.UserData.RawImg;
    NumFrames = length(S.I);
    fig.UserData.SplitImgCoords = {};

%%%%%%%Create the axes for image display. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S.ax = axes('units','pixels',...                                            
        'position',[4*pad 6*pad figwidth-30*pad figheight-8*pad],...
        'fontsize',10,...
        'nextplot','replacechildren');

%%%Create a "split image" button to start collecting coordinates for GFP/RFP%%%%%
    S.splitImg = uicontrol('style','pushbutton',...                          
        'unit','pix',...
        'parent',fig,...
        'position',[figwidth-23*pad figheight-10*pad 20*pad 4*pad],...
        'fontsize',12,...
        'string','Split channels');

%%%%%%%%%%%%%%%%%%%% create collect body coordinate button %%%%%%%%%%%%%%%%
    S.bodycoords = uicontrol('style','pushbutton',...                        
        'parent',fig,...
        'unit','pix',...
        'position',[figwidth-23*pad figheight-15*pad 20*pad 4*pad],...
        'fontsize',12,...
        'string','Body coordinates');
    S.bodycoordtext=uicontrol('style','text',...                                 
        'unit','pix',...,
        'parent',fig,...
        'position',[figwidth-35*pad figheight-45*pad 25*pad 10*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','');

%%%%%%Create a "Reset" button to reset everything to defaults%%%%%%%%%%%%%%
        S.resetbutton = uicontrol('style','pushbutton',...                          
        'parent',fig,...
        'unit','pix',...
        'position',[figwidth-23*pad figheight-20*pad 20*pad 4*pad],...
        'fontsize',12,...
        'string','Reset');
    
%%%%%%%%%%%%%%%%%Create a "Next" button move on to next step%%%%%%%%%%%%%%%
        S.nextbutton = uicontrol('style','pushbutton',...
        'parent',fig,...
        'unit','pix',...
        'position',[figwidth-23*pad figheight-25*pad 20*pad 4*pad],...
        'fontsize',12,...
        'string','Next');
        %%% create text to let user know what frame is being worked on %%%
        S.nexttext=uicontrol('style','text',...                                      %Ttextbox describing the button group
        'unit','pix',...,
        'parent',fig,...
        'position',[figwidth-23*pad figheight-30*pad 20*pad 4*pad],...
        'fontsize',12,...
        'FontWeight', 'bold', ...
        'string','');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Draw the first frame of the stack and set callback functions           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Draw the first frame of the stack%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    height_Img = size(S.I{1},1); width_Img = size(S.I{1},2);
    xlim([1,width_Img]);
    ylim([1, height_Img]);
    imshow(S.I{1},[]); colormap gray;                                     %Display the first frame
    hold off;
    
%%%%%%Set callback functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(S.splitImg,'Callback', {@SplitImgCoords,S});
    set(S.bodycoords,'Callback',{@BodyCoordCollect,S})
    set(S.resetbutton,'Callback', {@resetfunction,S});                          %Callback function for the reset button
    set(S.nextbutton,'Callback', {@nextfunction,S}); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%    CALL BACK fUNCTIONS     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% start collectin the coordinates of the %%%%%%%%%%%%%%%%
    function [] = SplitImgCoords(varargin)
        S = varargin{3};
        fig= ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;

        height_Img = size(S.I{1},1); width_Img = size(S.I{1},2);
        xlim([1,width_Img]);
        ylim([1, height_Img]);
        imshow(S.I{1},[]); colormap gray;  
        hold on;

        xlim([1,width_Img]);
        ylim([1, height_Img]);

        % USER INPUT FOR ROI1
        [crop_x_GFP_1, crop_y_GFP_1] = ginput_y(1);
        %round to nearest integer
        crop_x_GFP_1 = floor(crop_x_GFP_1); crop_y_GFP_1 = floor(crop_y_GFP_1);    
        % plot red cursors passing by the first selected point
        g_line_1 = plot([1 width_Img], [crop_y_GFP_1 crop_y_GFP_1], '-g');
        g_line_2 = plot([crop_x_GFP_1 crop_x_GFP_1], [1 height_Img], '-g');
        
        % repeat agaim to find second corner of GFP half
        [crop_x_GFP_2, crop_y_GFP_2] = ginput_y(1);
        crop_x_GFP_2 = floor(crop_x_GFP_2); crop_y_GFP_2 = floor(crop_y_GFP_2);     
        
        %plot GFP box
        delete(g_line_1);delete(g_line_2)
        plot([crop_x_GFP_1 crop_x_GFP_2], [crop_y_GFP_2 crop_y_GFP_2], '-g');
        plot([crop_x_GFP_2 crop_x_GFP_2], [crop_y_GFP_1 crop_y_GFP_2], '-g');
        plot([crop_x_GFP_1 crop_x_GFP_2], [crop_y_GFP_1 crop_y_GFP_1], '-g');
        plot([crop_x_GFP_1 crop_x_GFP_1], [crop_y_GFP_1 crop_y_GFP_2], '-g');
        
        %calculate GFP-half height and width
        sp_with = abs(crop_x_GFP_2-crop_x_GFP_1);
        sp_height = abs(crop_y_GFP_2-crop_y_GFP_1);
        
        %now select top-left corner of of the RFP image
        [crop_x_RFP_1, crop_y_RFP_1] = ginput_y(1);
        crop_x_RFP_1 = floor(crop_x_RFP_1); crop_y_RFP_1 = floor(crop_y_RFP_1); 
        %creat the second set of coordinates using the same dimensions of GFP side
        crop_x_RFP_2 = crop_x_RFP_1 + sp_with;
        crop_y_RFP_2 = crop_y_RFP_1 + sp_height;
        % plot green cursors passing by the second selected point
        plot([crop_x_RFP_1 crop_x_RFP_2], [crop_y_RFP_2 crop_y_RFP_2], '-r');
        plot([crop_x_RFP_2 crop_x_RFP_2], [crop_y_RFP_1 crop_y_RFP_2], '-r');
        plot([crop_x_RFP_1 crop_x_RFP_2], [crop_y_RFP_1 crop_y_RFP_1], '-r');
        plot([crop_x_RFP_1 crop_x_RFP_1], [crop_y_RFP_1 crop_y_RFP_2], '-r');
        
        hold(S.ax, 'off');
        axis equal tight                                                           
        
        % collect the x,y coordinates from the input and assign them to
        % variables that we will use for GFP and RFP triming
        S.sp_coords.GFPXmin = min([crop_x_GFP_1 crop_x_GFP_2]);
        S.sp_coords.GFPXmax = max([crop_x_GFP_1 crop_x_GFP_2]);
        S.sp_coords.GFPYmin = min([crop_y_GFP_1 crop_y_GFP_2]);
        S.sp_coords.GFPYmax = max([crop_y_GFP_1 crop_y_GFP_2]);
        
        S.sp_coords.RFPXmin = min([crop_x_RFP_1 crop_x_RFP_2]);
        S.sp_coords.RFPXmax = max([crop_x_RFP_1 crop_x_RFP_2]);
        S.sp_coords.RFPYmin = min([crop_y_RFP_1 crop_y_RFP_2]);
        S.sp_coords.RFPYmax = max([crop_y_RFP_1 crop_y_RFP_2]);

        %adjust sizing if max coords is out of bounds
        if S.sp_coords.RFPXmax > size(S.I{1},2)
            S.sp_coords.RFPXmax = size(S.I{1},2);
        end

        if S.sp_coords.RFPYmax > size(S.I{1},1)
            S.sp_coords.RFPYmax = size(S.I{1},1);
        end
        %store to figure UserData
        data.SplitImgCoords = S.sp_coords;
        
        frame = S.I{1};
        data.GFPFrame = frame(data.SplitImgCoords.GFPYmin : data.SplitImgCoords.GFPYmax, ...
                data.SplitImgCoords.GFPXmin:data.SplitImgCoords.GFPXmax);

        height_Img = size(data.GFPFrame,1); width_Img = size(data.GFPFrame,2);
        xlim([1,width_Img]);
        ylim([1, height_Img]);
        axes(S.ax);
        imshow(data.GFPFrame,[]); colormap (S.ax,'gray');                       
        axis equal tight; hold(S.ax,'on');        

        %Update the figure user data 
        fig.UserData = data;
    end

%%%%%%%%%%%%%%%%%%%%%%%% collect body coords %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = BodyCoordCollect(varargin)
        S = varargin{3};
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        if ~isfield(data ,'GFPFrame') || isempty(data.GFPFrame)
            uiwait(msgbox(['Need to split channels first. please select' ...
                ' "Split channels" button'], ...
                'Warning', 'warn'));
        else
            data.Body_Coords = Body_Coordinates(data, S);
            %Update the figure user data 
            fig.UserData = data;
        end
    end

%%%%%%%% reset function clears drawing and clears coordinates %%%%%%%%%%%
    function [] = resetfunction(varargin)
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        S = varargin{3};
        S.sp_coords = struct();
        data.GFPFrame=[];
        height_Img = size(S.I{1},1); width_Img = size(S.I{1},2);
        xlim([1,width_Img]);
        ylim([1, height_Img]);
        S.ih = imshow(S.I{1},[]); colormap gray;                                    
        hold off;                               %Display the first frame                                           
    end

%%%%%%%%%%%%%%%%%%%%% next function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = nextfunction(varargin)
        fig = ancestor(varargin{1},"figure","toplevel");
        data = fig.UserData;
        % retriev e GUI data
        S = varargin{3};

        if ~isfield(data ,'SplitImgCoords') || isempty(data.SplitImgCoords) ||...
           ~isfield(data ,'Body_Coords') || isempty(data.Body_Coords)
            uiwait(msgbox(['Need to split channels first. please select' ...
                ' "Split channels" button'], ...
                'Warning', 'warn'));
        else
            NumFrames = length(data.RawImg);
            for k =1:NumFrames
                frame = data.RawImg{k};
                %extract trimmed recentered image
                GFPFrame = frame(data.SplitImgCoords.GFPYmin:data.SplitImgCoords.GFPYmax, ...
                    data.SplitImgCoords.GFPXmin:data.SplitImgCoords.GFPXmax);
                RFPFrame = frame(data.SplitImgCoords.RFPYmin:data.SplitImgCoords.RFPYmax, ...
                    data.SplitImgCoords.RFPXmin:data.SplitImgCoords.RFPXmax);
                
                %Align GFP image with the RFP imaged basd on their
                %fluorescence
                RegRFP = ImgReg_N_align(GFPFrame, RFPFrame);
            
                %store trimmed stack
                data.RawGFP{k} = GFPFrame;
                data.RawRFP{k} = RegRFP;
    
                set(S.nexttext, 'string', ['Working on Frame: ', num2str(k),...
                    '/',num2str(NumFrames)]);
                drawnow;
            end
        end

        %store output stacks
        fig.UserData = data;
        % now we store all new data created from this step onto the overall
        % data class structure called WormTrackerData
        setappdata(0,'SplitChannelData', fig.UserData)
        % Set a flag indicating GUI is done
        setappdata(0, 'SplitGUIFinished', 1);

        %close app
        pause(1);
        close(gcf);
    end

end

