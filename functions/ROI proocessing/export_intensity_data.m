function export_intensity_data(data,S)
    if get(S.ROIedgebutton,'Value')==1
        %makes it easier to reference the intensity data
        Intensity_data = data.ROI_Data.edge_intensity_data;
        % Extract data size info
        [NumFrames, num_mid_pts] = size(Intensity_data.GFP_d);
        % Initialize table to store data
        IntensityTable = table();
        % Populate the table
        for i = 1:NumFrames
            for pt = 1:num_mid_pts
                % Create a temporary row for each point in each frame
                newRow = table(i, pt, ...
                    Intensity_data.GFP_d(i, pt), ...
                    Intensity_data.GFP_v(i, pt), ...
                    Intensity_data.RFP_d(i, pt), ...
                    Intensity_data.RFP_v(i, pt), ...
                    Intensity_data.Ratio_d(i, pt), ...
                    Intensity_data.Ratio_v(i, pt), ...
                    'VariableNames', {'Frame', 'Point', 'GFP_d', 'GFP_v', 'RFP_d', 'RFP_v', 'Ratio_d', 'Ratio_v'});
                % Append the new row to the main table
                IntensityTable = [IntensityTable; newRow];
            end
        end

    elseif get(S.ROIcenterbutton,'Value')==1
        Intensity_data = data.ROI_Data.center_intensity_data;
    end
    
    % Write the table to a CSV file
    writetable(IntensityTable, fullfile(data.Paths{1},'ROI_Intensity_Data.csv'));
end