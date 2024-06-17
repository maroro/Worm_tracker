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
