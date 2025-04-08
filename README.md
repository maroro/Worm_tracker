Worm_Tracker is a MatLAb based GUI that is design for image processing and broken down into three parts.

HOW TO USE? 
- To use the worm_tracker open the 'Worm_signal_tracking_MR.m' file in matlab. 
- Ensure that the folder 'functions' and all subfolders are added to the path.
- RUN the code in the 'Worm_signal_tracking_MR.m'

WHAT TO EXPECT?
- When you run the script it will first ask you to choose the TIFF stack that you will work with. In addition it will alow you to determine which sequence of frames from the stack you want to use for your analysis.
  
- The first GUI window has two functions:
    1.  allow you to split GFP and RFP channels from a single image taken using a light splitter.
    2.  select key points in the body of the worm.
    3.  after selecting 'Next' thi GUI will split the images using the coordinates defined by user in the first step, then it will use a CNN algorithm to align the images.
    4.  after it is done processing images this GUI window will close and open the next one. NOTE: Please be patient, while this happens it is storing the newly created stacks so it may take few minutes before it opens the next GUI.
       
 - The second GUI allows the user to enhance the image for the purpose of creating a clear outline of the worm.
    1. Background subtraction allow you to select background area and use subtract it from the whole image.
    2. median filter allows you to select the size of the filter.
    3. there are two methods to enhance contrast. Notice these apporaches ten to binarize the image making it difficult to detect worm outline.
    4. after enhancing the image click on 'Create Mask' to be able to see the detected worm outline.
       - if there are many white specs around worm outline increase the 'erode' value.
       - if there are holes in the outline of the worm, increase the 'dilate' vaue.
    5. once you are happy with the parameters for the mask press 'Next". The GUI will take a moment to process all frames in the stack. it will generate a new enhanced stack, and stack with the mask. Once the GUI is done processing it will close the window, store the new stacks and open a new window for the last GUI.
       
- The last GUI is designed so the User can define where along the body of the worm they want to place an ROI. once the ROI is defined, the user can display this ROI throughout the video for quality coontrol. Lastly, the user can extract intensity data from that ROI in both the GFP and RFP Frame, which results in a '.csv' file.
