 %%  MUSCLE ANALYSIS SCRIPT
% GCamp3/RFP image processing

%%%%%%%%%%%%%%%%% SELECT FILES AND INPUT PARAMETERS %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GUI: select img file path
% Load .tif image sequence, or re-load saved .mat file
choice_data = questdlg('Choose data to load','Data loading',...
    'Load new .TIF file','Cancel', ...
    'Load new .TIF file');

switch choice_data
    case 'Cancel'
        % User canceled the operation, display a warning message
        warndlg('You need to load data to run the program', 'Warning');
        return;  % Return to the main GUI and wait for further user action

    case 'Load new .TIF file'
        % Check if pathname exists and is a folder
        if exist('dirpath', 'var') && isfolder(dirpath)
            % Set the initial directory of uigetfile to pathname
            initialDir = dirpath;
        else
            % Set a default directory if pathname is not available
            initialDir = pwd;  % Current working directory
        end

        % Open the file selection dialog
        [stackname, dirpath] = uigetfile({'*.tif'}, 'Choose data to load', initialDir);
        stackpath = fullfile(dirpath,stackname);
        WormTrackerData.Paths = {dirpath, stackpath}; 

        % Check if the user canceled the file dialog
        if isequal(stackname, 0) || isequal(dirpath, 0)
            msgbox('File selection canceled.', 'Info');
            return;  % Return to the main GUI without changing the state
        end
end
      
%%%%%%%%% METADATA: create file name and numbering convention %%%%%%%%%%%%%
    %%% use Micro-Manager metadata .json file for stack metadata %%%
     jsonFilePath = findFirstJsonFile(dirpath);
     WormTrackerData.Paths{end+1} =jsonFilePath;
     % Load metadata (assuming JSON format for this example)
     WormTrackerData.metadata = jsondecode(fileread(WormTrackerData.Paths{3}));
    
      [StackPath,StackFrames,numdigits, numdigits_suffix] = ...
          File_Info(dirpath, stackname);
    
      
%% GUI: choose parameters for analysis
      choice_input_param = inputdlg({'Frames per second','Start frame', ...
          'End frame'},'Input parameters',1,...
          {'15','1',num2str(StackFrames)});
        
      fps = str2double(choice_input_param{1});
      FrameStart = str2double(choice_input_param{2});
      FrameEnd = str2double(choice_input_param{3});
      NumWorkingFrames = FrameEnd - FrameStart + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN CALCULATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% INITIALISATION ON FIRST FRAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

WormTrackerData.RawImg = cell(1, NumWorkingFrames);
% populate the cell array Img with frames from TIF stack
for k = FrameStart:FrameEnd
   WormTrackerData.RawImg{k-FrameStart+1} = imread(StackPath,k);
end

%%%%%%%%%%%%%%%%% PREPARATION: trim the GFP and RFP %%%%%%%%%%%%%%%%%%%%%%%
Channel_split_GUI(WormTrackerData)
% Wait for GUI to close by checking the flag
while getappdata(0, 'SplitGUIFinished')==0
    pause(1); % Adjust the pause as necessary
end
% retrieve updated WormTrackerData and save it as a checkpoint
WormTrackerData.SplitChannels = getappdata(0, 'SplitChannelData');
save(fullfile(dirpath,'WormTrackerData.mat'),'-struct','WormTrackerData','-v7.3');
setappdata(0, 'SplitGUIFinished', 0);

%%%%%%%%%%%%%%%%%%%%%% PROCESS:enhance, mask, midline %%%%%%%%%%%%%%%%%%%%%
Enhance_img_GUI(WormTrackerData)
% Wait for GUI to close by checking the flag
while ~getappdata(0, 'enhnaceGUIFinished')
    pause(1); % Adjust the pause as necessary
end
% retrieve updated WormTrackerData and save it as a checkpoint
WormTrackerData.PreProcessedData = getappdata(0, 'PreProcessedData');
save(fullfile(dirpath,'WormTrackerData.mat'),'-struct','WormTrackerData','-v7.3');
setappdata(0, 'enhnaceGUIFinished', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%% ROI DATA COLLECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROI_extract_GUI(WormTrackerData);
% Wait for GUI to close by checking the flag
while ~getappdata(0, 'ROIGUIFinished')
    pause(1); % Adjust the pause as necessary
end
% retrieve updated WormTrackerData and save it as a checkpoint
WormTrackerData.ROI_Info = getappdata(0, 'ROI_Info');
save(fullfile(dirpath,'WormTrackerData.mat'),'-struct','WormTrackerData','-v7.3');
setappdata(0, 'ROIGUIFinished', 0);











%% GUI: collect user input for angle analysis. %%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialisation
choice_mid_pts = inputdlg({'Number of points on the midline ?'}, ...
    'Input for number of midline points', 1, {num2str(uint16(100))});
num_mid_pts = str2double(choice_mid_pts{1});

choice_ROI = inputdlg({'Number of boxes on each side of central point',...
     'ROI position parameter 0<f<1','Distortion parameter 0<a<1'},...
     'Number of ROIs used to compute fluorescence', 1, ...
     {num2str(uint16(2)),'0.9','0.9'});
 
n_ROI = str2double(choice_ROI{1});
f = str2double(choice_ROI{2});
a = str2double(choice_ROI{3});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%use background subtraction to enhance displayed frames
[EnhancedRFP, EnhancedGFP] = EnhanceStackDisplay(RegRFP,ImgGFP);

%we will use this class later on to call these for fluoresence analysis
Img.GFP=ImgGFP;  
Img.RFP = RegRFP;

% use the enhanced GFP image to collect coordinates from worm body
[worm_diam, head_coords, tail_coords,vulva_coords] = ...
    Body_Coordinates(EnhancedGFP);

%use first frame of GFP image to determine dilation and erosion coeficients
%we'll later use them to detect worms
[c1,c2] = dilation_erosion_select(EnhancedGFP);

% use the dilation and erosion values from first frame to apply to rest of
% stack and create masks of the worm silhouette and trace it.
[Boundaries,ref_mask_stack] = Create_mask(EnhancedGFP, c1, c2, worm_diam);
trace_data = trace_worm(Boundaries, head_coords,vulva_coords,EnhancedGFP);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% generate midline and ROIs around each midpoint%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%use the outline of the mask trace to generate a midline and collect data
%from it
midline_data = midline_creation(num_mid_pts, trace_data,...
    worm_diam, ref_mask_stack, EnhancedGFP);

% use the midpoint coordinates to generate ROI coordinates alonmg ventral
% and dorsal edge of worm
ROI_data = create_ROIs(f,a,n_ROI,num_mid_pts,midline_data, Img);

%calculate Fluorescensce intensity within the ROI coordinates define above.
Intensity_data = ROI_intensity(Img,n_ROI,num_mid_pts, ROI_data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%- collect user input for smoothing of data %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Choice_smooth = inputdlg({'time window (# rames):',...
     'space window:','Sigma (STDev for Gaussian Filter)'},...
     'Parameters Used to smooth (average) data over time and space', 1, ...
     {'3','1','1'});
 
timewindow = str2double(Choice_smooth{1});
spacewindow = str2double(Choice_smooth{2});
sigma = str2double(Choice_smooth{3});

% use user input to collect smoothed data
smoothed_data = smooth_curvature(timewindow, spacewindow, ...
    sigma, fps, midline_data, Intensity_data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Visualize ROIs in app %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

StackSlider(EnhancedGFP, trace_data, ROI_data, midline_data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% store data in .csv files in given output folder %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

choice_save=questdlg('Save this data?','Save data','Yes','No','Yes');

switch choice_save
    case 'Yes'
        [savefilename savepathname]=uiputfile('*.mat',...
            'Choose file to save',strcat(StackPath,'_',...
            num2str(FrameStart),'-',num2str(FrameEnd),'.mat'));
        save(strcat(savepathname,savefilename));
    case 'No'
        display('You did not save your data');
end




%% PLOT TRACES FOR MANY POINTS ALONG THE WORM'S BODY

switch questdlg('Show results?','Show results?','Yes','No','Yes')
    case 'Yes'
        showstuff = true;
    case 'No'
        showstuff = false;
end

if (showstuff)

    for k = 1:NumWorkingFrames
        rat{k} = Img.GFP{k}./max(1,Img.RFP{k});
    end

    for v = 50:25:75
        mean_ratio = mean(smoothed_data.FluoRatio_v_filtered(:,v));

        figure; clf; hold on;
        plot((1:1:NumWorkingFrames-1)'/fps,...
            (Intensity_data.FluoRatio_d(1:NumWorkingFrames-1,v)),'-r',...
            (1:1:NumWorkingFrames-1)'/fps,...
            (Intensity_data.FluoRatio_v(1:NumWorkingFrames-1,v)),'-g',...
            (1:1:NumWorkingFrames-1)'/fps, smoothed_data.curvaturePrime_filtered(:,v),'-b');
        title({strcat('GCaMP and RFP Fluorescence Over Time for Point ',num2str(v));...
            strcat('Corr ref = ',num2str(corr(Intensity_data.FluoRatio_d(1:NumWorkingFrames-1,v),smoothed_data.curvaturePrime_filtered(:,v))),...
            '// Corr  = ',num2str(corr(Intensity_data.FluoRatio_d(1:NumWorkingFrames-1,v),smoothed_data.curvaturePrime_filtered(:,v))))},'FontSize',12)
        legend('Normalized Dorsal Fluorescence ratio',...
            'Normalized Ventral Fluorescence ratio',...
            'Curvature/100'); 
        xlabel('Time (seconds)','FontSize',12);
        ylabel('Fluorescence ratios and curvature','FontSize',12);

    end
end

%% Phase plots
cols=50;

% find the value of k if curvature = sin(kx)-->derviative = k*cos(kx)
% the period in frames is equal to 2*pi/k

if (showstuff)
    figure; clf; hold on;
    plot((1:1:NumWorkingFrames)', curvature_filtered(:,cols),'-k');
    title({strcat('Curvature Over Time for Point ',num2str(cols));...
        'Select 2 points separated by a whole number of periods'})
    legend('Curvature'); 
    xlabel('Frames');
    ylabel('Curvature');

    coef1 = ginput(1);
    plot(coef1(1),coef1(2),'+r')
    coef2 = ginput(1);
    plot(coef2(1),coef2(2),'+g')

    choice_numperiods = inputdlg({'Number of periods ?'}, ...
        'Number of periods', 1, {num2str(uint16(3))});
    numperiods = str2double(choice_numperiods{1});

    gcoef = numperiods*2*pi/abs(coef1(1)-coef2(1));

    r_d = FluoRatio_d_filtered(:,cols);
    r_v = FluoRatio_v_filtered(:,cols);
    g = curvature_filtered(:,cols);
    gPrime = gcoef*curvaturePrime_filtered(:,cols);
    phi=NaN(NumWorkingFrames,1);

    for k = 1:NumWorkingFrames
      if gPrime(k) >= 0
        phi(k) = atan(g(k)./gPrime(k));
      else
        phi(k) = pi + atan(g(k)./gPrime(k));
      end
    end

    figure(20); clf; hold on;
    polar(phi,r_d,'+r')
    title({'Polar plot with angle given by curvature seen as a sine';...
        ['and raduis given by dorsal fluorescence ratio for point ',num2str(cols)]},'FontSize',12)
  
    polar(phi,r_v,'+r')
    title({'Polar plot with angle given by curvature seen as a sine';...
        ['and raduis given by ventral fluorescence ratio for point ',num2str(cols)]},'FontSize',12)

    figure(22); clf; hold on;
    plot(g,r_d,'+-b')
    title(['Fluorescence ratio against curvature for point ',num2str(cols)],'FontSize',12)
    xlabel('Curvature','FontSize',12)
    ylabel('Dorsal fluorescence ratio','FontSize',12)

    figure(23); clf; hold on;
    plot(gPrime,r_d,'+-b')
    title(['Fluorescence ratio against curvature derivative for point ',num2str(cols)],'FontSize',12)
    xlabel('Curvature derivative','FontSize',12)
    ylabel('Dorsal fluorescence ratio','FontSize',12)
end

