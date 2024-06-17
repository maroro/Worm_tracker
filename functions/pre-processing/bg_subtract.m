function EnhancedFrame = bg_subtract(workingframe, data)

    bg_area1 = workingframe(data.bg_coords.BGYmin : data.bg_coords.BGYmax, ...
    data.bg_coords.BGXmin : data.bg_coords.BGXmax);
    mean_bg1 = mean2(bg_area1);
    %subtract once
    bgenhanced1 = double(workingframe) - mean_bg1;
    %remove negative values
    bgenhanced1(bgenhanced1 < 0) = 0;

    bg_area2 = bgenhanced1(data.bg_coords.BGYmin : data.bg_coords.BGYmax, ...
    data.bg_coords.BGXmin : data.bg_coords.BGXmax);
    %do it a second time
    mean_bg2 = mean2(bg_area2);
    %subtract once
    bgenhanced2 = double(bgenhanced1) - mean_bg2;
    %remove negative values
    bgenhanced2(bgenhanced2 < 0) = 0;

    bg_area3 = bgenhanced2(data.bg_coords.BGYmin : data.bg_coords.BGYmax, ...
    data.bg_coords.BGXmin : data.bg_coords.BGXmax);
    %do it a second time
    mean_bg3 = mean2(bg_area3);
    %subtract once
    bgenhanced3 = double(bgenhanced2) - mean_bg3;
    %remove negative values
    bgenhanced3(bgenhanced3 < 0) = 0;
    EnhancedFrame = bgenhanced3;
end