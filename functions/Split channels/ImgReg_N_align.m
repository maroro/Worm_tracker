function RegRFP = ImgReg_N_align(ImgGFP, ImgRFP)
%MATLAB's `imregister` function can be used to perform the registration.
%You'll need to set up an optimizer and a metric for the registration 
% process:
    %Decide on the type of transformation appropriate for your images. 
    %Common types include:
    %'translation': allows the image to move in x and y directions.
    %'rigid': allows translation and rotation.
    %'affine': includes translation, rotation, scaling, and shearing.
    %'nonrigid' or 'custom': for more complex transformations.
    [optimizer, metric] = imregconfig('multimodal');
    optimizer.MaximumIterations = 15;
    tform = imregtform(ImgRFP, ImgGFP,'translation', optimizer, metric);
 
    xOffset = tform.T(3,1);
    yOffset = tform.T(3,2);

    RegRFP = imtranslate(ImgRFP, [xOffset, yOffset]);

end