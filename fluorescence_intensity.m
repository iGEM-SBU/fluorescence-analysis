% function [raw, summary] = fluorescence_intensity(filepath, parameter, value)
%
% Purpose: To calculate data of the fluorescent intensity in a picture
% 
% Define variables:
%   Input variables:
%       filepath: the combined file name and path name of the image file to
%       be analyzed. This can be generated from the "fullfile" function
%       
%       Additional settings can be entered as parameter, value pairs:
%           Filter: the color filter that will be applied. This is used to
%           convert a color photo to a greyscale photo, and for the color
%           of the heatmap. Can be 'green', 'g', 'red', 'r',
%           'yellow', 'y', 'blue', or 'b'. Default is 'green'
%           MaskState: how the user wants to input a mask photo. Default is
%           'off' (no mask photo is selected). Entering a file name and
%           path name of an image will use that image as the mask photo.
%           Entering 'trace' will allow the user to trace a mask from the
%           original photo
%           StandardState: whether the user wants to trace out standards
%           for analysis or not ('on' or 'off'). Default is 'off'
%           HistState: whether the user wants to output a histogram or not
%           ('on' or 'off'). Default is 'off'
%           HeatmapState: whether the user wants to output a heatmap or not
%           ('on' or 'off'). Default is 'off'
%           MinValue: the min value for the heatmap, specified from 0 to
%           255. Default is 0.
%           MaxValue: the max value for the heatmap, specified from 0 to
%           255. Default is 255.
%   Output variables:
%       raw: raw data of the intensity of every region in the image
%       summary: summary data describing the intensities. In order, this is
%       the number of regions, the average intensity of the regions, the
%       standard deviation, and the percent infected if a mask photo was
%       specified

function [raw, summary] = fluorescence_intensity(filepath, varargin)

% INITIALIZATION

% Check to make sure the user inputted the correct number of paramters
narginchk(1,15);

% Check to make sure the filepath variable is inputted correctly
if ~ischar(filepath)
    % If not, output an error message and stop the callback function
    fprintf('Error: A valid file path name was not inputted \n');
    return
end

% Check to make sure the parameter / value pairs were entered in pairs
if rem(length(varargin), 2) == 1
    % If not, output an error message and stop the callback function
    fprintf('Error: Parameter and Value arguments were not entered in pairs \n');
    return
end

% Check to make sure all of the parameters are characters
if ~all(cellfun(@ischar, varargin(1:2:end)))
    % If not, output an error message and stop the callback function
    fprintf('Error: Parameters were not entered correctly \n');
end

% Create a structure array for the parameters, and set them to the defaults
parameters.Filter = 'Green';
parameters.MaskState = 'off';
parameters.StandardState = 'off';
parameters.HistState = 'off';
parameters.HeatmapState = 'off';
parameters.MinValue = 0;
parameters.MaxValue = 255;

% Loop through the parameter / value pairs
for ii = 1:2:length(varargin)
    % Check if it is a valid parameter / value pair. If it is, update the
    % structure accordingly. If not, display an error message and stop the
    % callback function
    switch lower(varargin{ii})
        case 'filter'
            if ~ischar(varargin{ii+1})
                fprintf('Error: The Filter value was not entered correctly \n');
                return
            elseif all(~strcmpi(varargin{ii+1}, {'Green', 'g', 'Red', 'r',...
                    'Yellow', 'y', 'Blue', 'b'}))
                fprintf('Error: The Filter value must be either "Green", "Red", "Yellow", or "Blue" \n');
                return
            else
                parameters.Filter = varargin{ii+1};
            end
        case 'maskstate'
            if ischar(varargin{ii+1})
                parameters.MaskState = varargin{ii+1};
            else
                fprintf('Error: The MaskState value was not entered correctly \n');
                return
            end
        case 'standardstate'
            if ~ischar(varargin{ii+1})
                fprintf('Error: The StandardState value was not entered correctly \n');
                return
            elseif strcmpi(varargin{ii+1}, 'on') || strcmpi(varargin{ii+1}, 'off')
                parameters.StandardState = varargin{ii+1};
            else
                fprintf('Error: The value of StandardState must be either "on" or "off" \n');
                return
            end
        case 'histstate'
            if ~ischar(varargin{ii+1})
                fprintf('Error: The HistState value was not entered correctly \n');
                return
            elseif strcmpi(varargin{ii+1}, 'on') || strcmpi(varargin{ii+1}, 'off')
                parameters.HistState = varargin{ii+1};
            else
                fprintf('Error: The value of HistState must be either "on" or "off" \n');
                return
            end
        case 'heatmapstate'
            if ~ischar(varargin{ii+1})
                fprintf('Error: The HeatmapState value was not entered correctly \n');
                return
            elseif strcmpi(varargin{ii+1}, 'on') || strcmpi(varargin{ii+1}, 'off')
                parameters.HeatmapState = varargin{ii+1};
            else
                fprintf('Error: The value of HeatmapState mist be either "on" or "off" \n');
                return
            end
        case 'minvalue'
            if ~isnumeric(varargin{ii+1})
                fprintf('Error: The value of MinValue must be numeric \n');
                return
            elseif varargin{ii+1} < 0 || varargin{ii+1} > 255
                fprintf('Error: The value of MinValue must be between 0 and 255 \n');
                return
            else
                parameters.MinValue = round(varargin{ii+1});
            end
        case 'maxvalue'
            if ~isnumeric(varargin{ii+1})
                fprintf('Error: The value of MaxValue must be numeric \n');
                return
            elseif varargin{ii+1} < 0 || varargin{ii+1} > 255
                fprintf('Error: The value of MaxValue must be between 0 and 255 \n');
                return
            else
                parameters.MaxValue = round(varargin{ii+1});
            end
        otherwise
            fprintf('Error: %s is not a valid parameter \n', varargin{ii});
            return
    end
end

% CONVERTING TO GREYSCALE

% Read the image data 
original_photo_data = imread(filepath);

% Find the size of the image
[ysize, xsize, channels] = size(original_photo_data);

if channels == 3
    % If the image has three channels, it is a color photo that needs to be
    % converted to a black and white photo
    % Convert it by using the filter specified
    switch lower(parameters.Filter(1))
        % If it is green, take the green channel of the image
        case 'g'
            bw_photo_data = original_photo_data(:,:,2);
        % If it is red, take the red channel of the image
        case 'r'
            bw_photo_data = original_photo_data(:,:,1);
        % If it is yellow, take the min of the green and red channels of
        % the image
        case 'y'
            bw_photo_data = min(original_photo_data(:,:,2), original_photo_data(:,:,1));
        % If it is blue, take the blue channel of the image
        case 'b'
            bw_photo_data = original_photo_data(:,:,3);
    end
elseif channels == 1
    % If it has one channel, then the image supplied is already black and
    % white
    bw_photo_data = original_photo_data;
else
    % Otherwise, there is an error. Alert the user, and stop the callback
    % function
    fprintf('Error: The image supplied cannot be converted \n');
    return
end

% ANALYZING INTENSITY

% Create a binary mask from the black and white image
bin_mask = imbinarize(bw_photo_data);

% Check if the user wants to analyze standards in their image
if strcmpi(parameters.StandardState, 'on')
    
    % If so, close any figures that may be open
    close all;
    
    % Display the image on an axes
    image(original_photo_data);
    
    % Tell the user to trace the two standards. Make it so the user has the
    % close the message box to continue
    waitfor(msgbox('Please trace the lower standard first, and then the higher standard'));
    
    % Use "imfreehand" function to trace the regions
    region_handle_low = imfreehand;
    region_handle_high = imfreehand;
    
    % Create the masks based on the freehand regions
    low_mask = createMask(region_handle_low);
    high_mask = createMask(region_handle_high);
    
    % Close the figure
    close all;
    
    % Apply the mask to the black and white image
    low_image = uint8(double(bw_photo_data) .* double(low_mask));
    high_image = uint8(double(bw_photo_data) .* double(high_mask));
    
    % Calculate the mean intensity of the two standards
    low_stats = regionprops(low_mask, low_image, 'MeanIntensity');
    low_intensity = round(mean([low_stats.MeanIntensity]));
    high_stats = regionprops(high_mask, high_image, 'MeanIntensity');
    high_intensity = round(mean([high_stats.MeanIntensity]));
    
    % Adjust the intensities in the black and white image accordingly by
    % taking the fraction.
    % Note that uint8 automatically converts negative values to 0, and
    % values greater than 255 to 255
    bw_photo_data = uint8(255*(double(bw_photo_data - low_intensity)) ./ (high_intensity - low_intensity));
end

% Use "regionprops" to get the average intensity of the pixels in a region,
% and the area of the region. Save into an array for easier processing
stats = regionprops(bin_mask, bw_photo_data, 'MeanIntensity');
mean_intensity = [stats.MeanIntensity];

% Calculate the mean intensity of each region, and the standard deviation
mean_region = mean(mean_intensity);
std_region = std(mean_intensity);

% ANALYZING THE MASK PHOTO

% Check how the user wants to analyze the mask photo
switch parameters.MaskState
    % 'off'
    case 'off'
        % If the user doesn't want to, continue the function
    % 'trace'
    case 'trace'
        % Close other figures that may be open
        close all
        
        % Display the image onto an axes 
        image(original_photo_data)
        
        % Tell the user to trace the border. Make it so the user has the
        % close the message box to continue
        waitfor(msgbox('Please trace the boundary of the leaf'));
        
        % Use "imfreehand" function to trace the region
        region_handle = imfreehand;
        
        % Create the mask based on the freehand region
        leaf_mask = createMask(region_handle);
        
        % Close the window
        close;
        
        % Create the leaf mask by applying it to the original photo
        leaf_mask = double(bw_photo_data) .* double(leaf_mask);
        leaf_mask = uint8(leaf_mask);
        
        % Use a threshold level of 115 (45%) to "crop" the image and find
        % the spots
        cropped_image = leaf_mask;
        cropped_image(cropped_image < 115) = 0;
        cropped_image = imbinarize(cropped_image);
        
        % Use "regionprops" to get the areas and intensities of the leaf
        % and the fluorescence
        bin_leaf_mask = imbinarize(leaf_mask);
        stats = regionprops(bin_leaf_mask, 'Area');
        leaf_area = [stats.Area];
        leaf_area = sum(leaf_area);
        stats = regionprops(cropped_image, leaf_mask, 'MeanIntensity', 'Area');
        mean_intensity = [stats.MeanIntensity];
        region_areas = [stats.Area];
        
        % Calculate the mean intensity of each region, the standard
        % deviation, and the percent infected
        mean_region = mean(mean_intensity);
        std_region = std(mean_intensity);
        percent_infected = (sum(region_areas) / leaf_area) * 100;
        
        % Use the mask photo and the new black and white photo
        bw_photo_data = leaf_mask;
        
    % 'filepath'
    otherwise
        % Read the image data provided
        mask_photo_data = imread(parameters.MaskState);
        
        % Binarize and invert the image so the leaf is white, and the
        % background is black
        leaf_mask = imbinarize(mask_photo_data);
        leaf_mask = imcomplement(leaf_mask);
        leaf_mask = imfill(leaf_mask, 'holes');
        
         % Apply the mask to the photo to get only the fluorescence in the
        % region
        fluorescence_mask = bin_mask & leaf_mask;
        bw_photo_data = fluorescence_mask .* double(bw_photo_data);
        
        % Use "regionprops" to get the areas and intensities of the leaf
        % and the fluorescence
        stats = regionprops(leaf_mask, 'Area');
        leaf_area = [stats.Area];
        leaf_area = sum(leaf_area);
        stats = regionprops(fluorescence_mask, bw_photo_data, 'MeanIntensity', 'Area');
        mean_intensity = [stats.MeanIntensity];
        region_areas = [stats.Area];
        
        % Calculate the mean intensity of each region, the standard
        % deviation, and the percent infected
        mean_region = mean(mean_intensity);
        std_region = std(mean_intensity);
        percent_infected = (sum(region_areas) / leaf_area) * 100;
end

% DISPLAYING HISTOGRAM

% Check if the user wants a histogram
if strcmpi(parameters.HistState, 'on')
    % If yes, make a new axes, and display the histogram
    hist_axes = axes;
    histogram(hist_axes, mean_intensity);
end

% DISPLAYING HEATMAP

% Check if the user wants a heatmap
if strcmpi(parameters.HeatmapState, 'on')
    % If yes, make a new figure
    heatmap_fig = figure;
    
    % Create the colormap based on the filter. The colormap goes from black
    % at zero intensity, to the max color at max intensity
    switch lower(parameters.Filter(1))
        case 'g'
            cmap = [zeros(64,1), linspace(0,1,64)', linspace(0,0.5, 64)'];
        case 'r'
            cmap = [linspace(0,1,64)', linspace(0,0.25,64)', linspace(0,0.25,64)'];
        case 'y'
            cmap = [linspace(0,1,64)', linspace(0,1,64)', linspace(0,0.5,64)'];
        case 'b'
            cmap = [zeros(64,1), linspace(0,0.5,64)', linspace(0,1,64)'];
    end
    
    % Create empty arrays for the labels of the heatmap
    xlabels = strings(1, xsize);
    ylabels = strings(1, ysize);
    
    % Create a mask by finding the values inbetween the min and max limit
    heatmap_mask = bw_photo_data >= parameters.MinValue * bw_photo_data <= parameters.MaxValue;
    
    % Apply this mask to the image. Pixels within this limit will have
    % their intensity stay the same, while pixels outside this limit will
    % have their intensity drop to zero
    heatmap_data = heatmap_mask .* double(bw_photo_data);
    
    % Display a heatmap based on the greyscale image and the mask
    heatmap(heatmap_fig, heatmap_data, 'XDisplayLabels', xlabels,...
        'YDisplayLabels', ylabels, 'Colormap', cmap, 'GridVisible', 'off');
    caxis([0 255]);
end

% OUTPUTTING DATA

% Save the raw and summary data to arrays
raw = mean_intensity;
summary = [length(mean_intensity), mean_region, std_region];
if exist('percent_infected', 'var')
    summary(4) = percent_infected;
else
    summary(4) = NaN;
end


end