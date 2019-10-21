function varargout = Fluorescent_Intensity_Analysis(varargin)
% FLUORESCENT_INTENSITY_ANALYSIS MATLAB code for Fluorescent_Intensity_Analysis.fig
%      FLUORESCENT_INTENSITY_ANALYSIS, by itself, creates a new FLUORESCENT_INTENSITY_ANALYSIS or raises the existing
%      singleton*.
%
%      H = FLUORESCENT_INTENSITY_ANALYSIS returns the handle to a new FLUORESCENT_INTENSITY_ANALYSIS or the handle to
%      the existing singleton*.
%
%      FLUORESCENT_INTENSITY_ANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FLUORESCENT_INTENSITY_ANALYSIS.M with the given input arguments.
%
%      FLUORESCENT_INTENSITY_ANALYSIS('Property','Value',...) creates a new FLUORESCENT_INTENSITY_ANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Fluorescent_Intensity_Analysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Fluorescent_Intensity_Analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Fluorescent_Intensity_Analysis

% Last Modified by GUIDE v2.5 29-Sep-2019 14:16:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Fluorescent_Intensity_Analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @Fluorescent_Intensity_Analysis_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Fluorescent_Intensity_Analysis is made visible.
function Fluorescent_Intensity_Analysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Fluorescent_Intensity_Analysis (see VARARGIN)

% Choose default command line output for Fluorescent_Intensity_Analysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Fluorescent_Intensity_Analysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Fluorescent_Intensity_Analysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in analyze_images_button.
function analyze_images_button_Callback(hObject, eventdata, handles)
% hObject    handle to analyze_images_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% INITIALIZATION

% Check to make sure the user loaded an image
if ~isfield(handles, 'original_photo_data')
    % If not, display an error message, and stop the callback function
    msgbox('Please upload an image first');
    return
end

% CONVERTING TO GREYSCALE

% Find the size of the image
[ysize, xsize, channels] = size(handles.original_photo_data);

if channels == 3
    % If the image has three channels, it is a color photo that
    % needs to be converted to a black and white photo
    % Convert it using the user function "rgb2bw"
    bw_photo_data = rgb2bw(handles);
elseif channels == 1
    % If it has one channel, then the image supplied is already a
    % black and white photo
    bw_photo_data = handles.original_photo_data;
else
    % Otherwise, there is an error. Alert the user, and stop the callback
    % function
    msgbox('Error: The function did not work properly');
    return
end

% Load the image onto the axes, and get rid of the tick marks
imshow(bw_photo_data, 'Parent', handles.BW_Photo);
set(handles.BW_Photo, 'XTick', []);
set(handles.BW_Photo, 'YTick', []);

% ANALYZING STANDARDS

% Check if the user wants to analyze standards in their image
if get(handles.analyze_standards_button, 'Value')
    
    % If so, display the binarized image on a bigger screen for easier
    % tracing
    trace_figure = figure;
    trace_axes = axes(trace_figure);
    image(handles.original_photo_data, 'Parent', trace_axes);
    
    % Tell the user to trace the two standards. Make it so the user has the
    % close the message box to continue
    waitfor(msgbox('Please trace the lower standard first, and then the higher standard'));
    
    % Use "imfreehand" function to trace the regions
    region_handle_low = imfreehand(trace_axes);
    region_handle_high = imfreehand(trace_axes);
    
    % Create the masks based on the freehand regions
    low_mask = createMask(region_handle_low);
    high_mask = createMask(region_handle_high);
    
    % Close the figure
    close(trace_figure);
    
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
    
    % Load the image onto the axes, and get rid of the tick marks
    imshow(bw_photo_data, 'Parent', handles.BW_Photo);
    set(handles.BW_Photo, 'XTick', []);
    set(handles.BW_Photo, 'YTick', []);
end

% ANALYZING INTENSITY

% Create a binary mask from the black and white image
bin_mask = imbinarize(bw_photo_data);

% Use "regionprops" to get the average intensity of the pixels in a region. 
% Save into an array for easier processing
stats = regionprops(bin_mask, bw_photo_data, 'MeanIntensity', 'Area');
mean_intensity = [stats.MeanIntensity];

% Calculate the mean intensity of each region, and the standard deviation
mean_region = mean(mean_intensity);
std_region = std(mean_intensity);

% Display this information to the GUI
set(handles.number_regions_text, 'String', ['Number of Regions = ', num2str(length(mean_intensity))]);
set(handles.average_intensity_text, 'String', ['Average Intensity of Regions = ', num2str(mean_region)]);
set(handles.std_intensity_text, 'String', ['Standard Deviation = ', num2str(std_region)]);

% DISPLAYING GRAPHS AND SAVING DATA

% Create empty arrays for the labels of the heatmap
xlabels = strings(1, xsize);
ylabels = strings(1, ysize);

% Display a histogram of the distribution of the intensities of the regions
histogram(handles.Histogram_Image, mean_intensity);

% Check the filter button that is selected by finding the radio button with
% the value of 1 "on"
selection = findobj('Value', 1);
selection = selection(end);

% Create the colormap based on the filter selected. The colormap goes from
% black at zero intensity, to the max color at the max intensity
switch selection.String
    case 'Green (GFP)'
        cmap = [zeros(64,1), linspace(0,1,64)', linspace(0,0.5,64)'];
    case 'Red (RFP)'
        cmap = [linspace(0,1,64)', linspace(0,0.25,64)', linspace(0,0.25,64)'];
    case 'Yellow (YFP)'
        cmap = [linspace(0,1,64)', linspace(0,1,64)', linspace(0,0.5,64)'];
    case 'Blue (BFP)'
        cmap = [zeros(64,1), linspace(0,0.5,64)', linspace(0,1,64)'];
    % Otherwise, display an error message, and stop the callback function
    otherwise
        msgbox('Error: The function did not work properly');
        return
end
    
% Save the raw data, the black and white photo data, the labels, and the
% colormap to the GUI
handles.mean_intensity = mean_intensity;
handles.bw_photo_data = bw_photo_data;
handles.xlabels = xlabels;
handles.ylabels = ylabels;
handles.cmap = cmap;
guidata(hObject, handles);

% Call the user function "displayheatmap" to display the heatmap
displayheatmap(handles, handles.heatmap_panel);

% ANALYZING THE MASK PHOTO

% Check to see if the user uploaded a mask photo

% First, check if a photo was uploaded
if isfield(handles, 'mask_photo_data')
    % If it is, take the mask directly from the photo
    
    % Binarize the image, and invert it so the leaf is white, and the
    % background is black
    % NOTE: This is assuming dark leaf, white background
    leaf_mask = imbinarize(handles.mask_photo_data);
    leaf_mask = imcomplement(leaf_mask);
    leaf_mask = imfill(leaf_mask, 'holes');
    
% Then, check if the user wants to trace the mask
elseif get(handles.trace_mask_button, 'Value')
    % If so, allow the user to trace the mask
    
    % Plot the original photo on a bigger figure for easier tracing
    trace_figure = figure;
    trace_axes = axes(trace_figure);
    image(handles.original_photo_data, 'Parent', trace_axes);
    
    % Communicate with the user on what they have to do. Make it so the
    % user has to close the message box to continue
    waitfor(msgbox('Please trace the border of the leaf to be used as a mask'));
    
    % Use "imfreehand" function to trace the region
    region_handle = imfreehand(trace_axes);
    
    % Create the mask based on the freehand region
    leaf_mask = createMask(region_handle);
    
    % Close the figure
    close(trace_figure);
    
    % Create the leaf mask by applying it to the original photo
    leaf_mask = double(handles.bw_photo_data) .* double(leaf_mask);
    leaf_mask = uint8(leaf_mask);
    
    % Display the mask photo on the axes
    imshow(leaf_mask, 'Parent', handles.Mask_Photo);
    
% Otherwise, stop the callback function
else
    return
end

% Find the area of the leaf
bin_leaf_mask = imbinarize(leaf_mask);
stats = regionprops(bin_leaf_mask, 'Area');
leaf_area = [stats.Area];
leaf_area = sum(leaf_area);

% Use a threshold level of 115 (45%) to "crop" the image and find the spots
cropped_image = leaf_mask;
cropped_image(cropped_image < 115)=0;
cropped_image = imbinarize(cropped_image);

% Use "regionprops" to get the average intensity of the pixels in the mask,
% and the areas of the regions in the mask
stats = regionprops(cropped_image, leaf_mask, 'MeanIntensity', 'Area');
handles.mean_intensity = [stats.MeanIntensity];
region_areas = [stats.Area];

% Calculate the mean intensity of each region, the standard deviation, and
% the percent infected
mean_region = mean(handles.mean_intensity);
std_region = std(handles.mean_intensity);
percent_infected = (sum(region_areas) / leaf_area) * 100;

% Display this information to the GUI
set(handles.number_regions_text, 'String', ['Number of Regions = ', num2str(length(handles.mean_intensity))]);
set(handles.average_intensity_text, 'String', ['Average Intensity of Regions = ', num2str(mean_region)]);
set(handles.std_intensity_text, 'String', ['Standard Deviation = ', num2str(std_region)]);
set(handles.percent_infected_text, 'String', ['Percent Infected = ', num2str(percent_infected)]);

% Redisplay the histogram and the heatmap, using the mask photo as the new
% black and white photo
handles.bw_photo_data = leaf_mask;
histogram(handles.Histogram_Image, handles.mean_intensity);
displayheatmap(handles, handles.heatmap_panel);

% Save this information to the GUI
handles.percent_infected = percent_infected;
guidata(hObject, handles);


% --- Executes on button press in clear_button.
function clear_button_Callback(hObject, eventdata, handles)
% hObject    handle to clear_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Initialize arrays for all handles created during processing (except for 
% selection handles for dialogue boxes), all axes, all static text boxes,
% and initial strings for text boxes
processed_handles = {'original_photo_data', 'mean_intensity', 'bw_photo_data',...
    'xlabels', 'ylabels', 'cmap', 'mask_photo_data', 'percent_infected'};
axes_handles = {handles.Original_Photo, handles.BW_Photo, handles.Mask_Photo,...
    handles.Histogram_Image};
static_text_handles = {handles.original_title_text, handles.number_regions_text,...
    handles.average_intensity_text, handles.std_intensity_text, handles.percent_infected_text};
static_text_initials = {'', 'Number of Regions = ', 'Average Intensity of Regions = ',...
    'Standard Deviation = ', 'Percent Infected = '};

% Loop through the processed handles array
for ii = 1:length(processed_handles)
    % If the field exists, delete it
    if isfield(handles, processed_handles{ii})
        handles = rmfield(handles, processed_handles{ii});
    end
end

% Save all handles to the GUI
guidata(hObject, handles);

% Loop through the axes handle array
for ii = 1:length(axes_handles)
    % Clear the axes
    cla(axes_handles{ii});
    % Reload the axes
    image([], 'Parent', axes_handles{ii});
    set(axes_handles{ii}, 'XTick', []);
    set(axes_handles{ii}, 'YTick', []);
end

% Loop through the static text arrays
for ii = 1:length(static_text_handles)
    % Reset static text
    set(static_text_handles{ii}, 'String', static_text_initials{ii});
end

% Delete the heatmap from the panel
x = findobj('ColorbarVisible', 'on');
delete(x);

% Reset the sliders and the text boxes
set(handles.min_slider, 'Value', 0);
set(handles.max_slider, 'Value', 255);
set(handles.min_text_box, 'String', 0);
set(handles.max_text_box, 'String', 255);


% --- Executes on button press in help_button.
function help_button_Callback(hObject, eventdata, handles)
% hObject    handle to help_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Display the main menu question box to direct users to the subfield
subfield = listdlg('Name', 'Main Menu', 'SelectionMode', 'Single',...
    'ListString', {'Workflow of the program', 'Loading Images',...
    'Analyzing Images', 'Data, Graphs, and Charts'}, 'PromptString',...
    'What topic do you need help with?', 'OkString', 'Select',...
    'ListSize', [200 55]);

% Check to see if the user chose an option
if isempty(subfield)
    % If so, stop the callback function
    return
end

% Pull up the corresponding subfield based on the selection
switch subfield
    % WORKFLOW OF THE PROGRAM
    case 1
        % Display the subdirectory for the workflow of the program
        qwork = listdlg('Name', 'Workflow of the program', 'SelectionMode',...
            'Single', 'ListString', {'How do I use the program?', 'What does the "Clear All" button do?'},...
            'OkString', 'Select', 'CancelString', 'Go Back', 'ListSize', [275 30]);
        
        % Check to see if the user wants to go back
        if isempty(qwork)
            % If so, go back to the main menu
            help_button_Callback(hObject, eventdata, handles);
            return
        end
        
        % Otherwise, display the help messages for the specific questions
        switch qwork
            % "How do I use the program?"
            case 1
                waitfor(helpdlg('To use this program, first upload an image by hitting the "Load Image" button. You can also specify whether you want to upload a mask photo as well by hitting the checkbox.',...
                    'How do I use the Program?'));
                waitfor(helpdlg('Then, specify a filter to use, and click the "Analyze Images" button. The data and charts will be filled in automatically.',...
                    'How do I use the Program?'));
                waitfor(helpdlg('You can save the data by hitting the corresponding buttons. To analyze a new image, you can either upload directly, or clear everything first by hitting the "Clear All" button.',...
                    'How do I use the Program?'));
            % "What does the 'Clear All' button do?"
            case 2
                waitfor(helpdlg('The "Clear All" button clears all the images, data, and charts from the program.',...
                    'What does the "Clear All" button do?'));
                waitfor(helpdlg('It is not necessary to hit the button after each image, but it helps if you have to analyze different photos differently.',...
                    'What does the "Clear All" button do?'));
        end
    % LOADING IMAGES
    case 2
        % Display the subdirectory for loading images
        qload = listdlg('Name', 'Loading Images', 'SelectionMode', 'Single',...
            'ListString', {'What images can I upload?', 'What is a mask photo?',...
            'What are the standards?'}, 'PromptString',...
            'What question do you have about loading images?', 'OkString',...
            'Select', 'CancelString', 'Go Back', 'ListSize', [240 40]);
        
        % Check to see if the user wants to go back
        if isempty(qload)
            % If so, go back to the main menu
            help_button_Callback(hObject, eventdata, handles);
            return
        end
        
        % Otherwise, display the help messages for the specific question
        switch qload
            % "What images can I upload?"
            case 1
                waitfor(helpdlg('You can upload either a color photo or a greyscale photo as the original photo. If it is a color photo, it will be converted to a greyscale photo.',...
                    'What Images can I Upload?'));
                waitfor(helpdlg('If you specify that you want to upload a mask photo, you can also upload that. It can be a color photo, a greyscale photo, or a binary photo.',...
                    'What Images can I Upload?'));
            % "What is a mask photo?"
            case 2
                waitfor(helpdlg('A mask photo is an optional image that can be used to find the border of the leaf in the image.',...
                    'What is a Mask Photo?'));
                waitfor(helpdlg('This is used to calculate the percent of the leaf that is infected',...
                    'What is a Mask Photo?'));
                waitfor(helpdlg('A mask photo is needed for this calculation because the program cannot determine the edge of the leaf just by the original photo, so a mask is needed.',...
                    'What is a Mask Photo?'));
            % "What are the standards?"
            case 3
                waitfor(helpdlg('Standards are objects that standarize the intensity of objects in a photo.',...
                    'What are the standards?'));
                waitfor(helpdlg('This program assumes two standards: one with 0 intensity, and one with 255 intensity.',...
                    'What are the Standards?'));
        end
    % ANALYZING IMAGES
    case 3
        % Display the subdirectory for analyzing images
        qanalyze = listdlg('Name', 'Analyzing Images', 'SelectionMode', 'Single',...
            'ListString', {'What do the filters do?', 'How are greyscale images created from color images?',...
            'How are the images analyzed?', 'How does tracing a mask photo work?',...
            'How is the mask photo analyzed?', 'How are the standards analyzed?'},...
            'OKString', 'Select', 'CancelString', 'Go Back', 'ListSize', [275 85]);
        
        % Check to see if the user wants to go back
        if isempty(qanalyze)
            % If so, go back to the main menu
            help_button_Callback(hObject, eventdata, handles);
            return
        end
        
        % Otherwise, display the help messages for the specific questions
        switch qanalyze
            % "What do the filters do?"
            case 1
                waitfor(helpdlg('The filters are used when converting the original photo to a greyscale photo if it is a color photo.',...
                    'What do the Filters do?'));
                waitfor(helpdlg('They are also used in determining the color of the heatmap after analysis.',...
                    'What do the Filters do?'));
            % "How are greycale images created from color images?"
            case 2
                waitfor(helpdlg('If a color image is provided, the program will look at the filter selected.',...
                    'How are Color Images Converted?'));
                waitfor(helpdlg('If the filter is red, green, or blue, the corresponding channel is taken from the original image.',...
                    'How are Color Images Converted?'));
                waitfor(helpdlg('If the filter is yellow, the minimum of the red and green channels is taken.',...
                    'How are Color Images Converted?'));
            % "How are the images analyzed?"
            case 3
                waitfor(helpdlg('Once the greyscale images are created or uploaded, the average pixel intensity of each distinct region will be measured.',...
                    'How are the Images Analyzed?'));
                waitfor(helpdlg('This information will then be processed to create the data and graphs.',...
                    'How are the Images Analyzed?'));
            % "How does tracing a mask photo work?"
            case 4
                waitfor(helpdlg('If the box is selected, while analyzing the images, a messgae box and the original photo will be displayed.',...
                    'How does Tracing a Mask Photo Work?'));
                waitfor(helpdlg('The user can then click and trace the leaf on the original photo. The mask will be displayed under "Mask Photo".',...
                    'How does Tracing a Mask Photo Work?'));
                waitfor(helpdlg('If an image is uploaded under "Mask Photo", this will take priority over tracing, even if the "Trace Mask Photo" box is checked',...
                    'How does Tracing a Mask Photo Work?'));
            % "How is the mask photo analyzed?"
            case 5
                waitfor(helpdlg('Once the mask photo is uploaded or traced, the border of the leaf will be determined.',...
                    'How is the Mask Photo Analyzed?'));
                waitfor(helpdlg('This information will then be used to calculate the total area of the leaf, and therefore the percent of the leaf that is fluorescent.',...
                    'How is the Mask Photo Analyzed?'));
            % "How are the standards analyzed?"
            case 6
                waitfor(helpdlg('Once the standards are traced, their intensities are calculated. Then, each region is shifted based on the intensities.',...
                    'How are the Standards Analyzed?'));
                waitfor(helpdlg('Intensities below the low standard will be set to zero. Intensities above the high standard will be set to 255. Intensities between these two values will be calculated based on a fraction.',...
                    'How are the Standards Analyzed?'));
                waitfor(helpdlg('After this transformation, the new image is then subsequently analyzed the same as if standards were not specified.',...
                    'How are the Standards Analyzed?'));
        end
    % DATA, GRAPHS, AND CHARTS
    case 4
        % Display the subdirectory for data, graphs, and charts
        qdata = listdlg('Name', 'Data, Graphs, and Charts', 'SelectionMode',...
            'Single', 'ListString', {'What numbers are calculated?', 'What is "intensity"?',...
            'What does the histogram show?', 'What does the heatmap show?',...
            'What do the sliders do on the heatmap?', 'What can be saved?'},...
            'OkString', 'Select', 'CancelString', 'Go Back', 'ListSize', [270 80]);
        
        % Check to see if the user wants to go back
        if isempty(qdata)
            % If so, go back to the main menu
            help_button_Callback(hObject, eventdata, handles);
            return
        end
        
        % Otherwise, display the help messages for the specific questions
        switch qdata
            % "What numbers are calculated?"
            case 1
                waitfor(helpdlg('Based on the intensity of each region, the mean and standard deviation are calculated.',...
                    'What Numbers are Calculated?'));
                waitfor(helpdlg('If a mask photo is supplied, the percent infected is also calculated.',...
                    'What Numbers are Calculated?'))
            % "What is 'intensity'?"
            case 2
                waitfor(helpdlg('Intensity is defined as the pixel intensity, from 0 to 255, of the region in the photo.',...
                    'What is "intensity"?'));
            % "What does the histogram show?"
            case 3
                waitfor(helpdlg('The histogram shows the distribution of the intensities of each region in the photo.',...
                    'What does the Histogram Show?'));
            % "What does the heatmap show?"
            case 4
                waitfor(helpdlg('The heatmap shows the intensities of each region in the photo.',...
                    'What does the Heatmap Show?'));
                waitfor(helpdlg('An intensity of 0 is shown as black, and an increasing intensity is shown as a brighter color, specified by the filter.',...
                    'What does the Heatmap Show?'));
            % "What do the sliders do on the heatmap?"
            case 5
                waitfor(helpdlg('The sliders and text boxes are used to filter out unwanted intensities in the heatmap.',...
                    'What do the Sliders do on the Heatmap?'));
                waitfor(helpdlg('Only intensities within the range will be shown. Intensities outside the range will be black.',...
                    'What do the Sliders do on the Heatmap?'));
            % "What can be saved?"
            case 6
                waitfor(helpdlg('For the intensity data, the raw data of the intensity of each region, and the summary data displayed can be saved as an Excel file.',...
                    'What can be Saved?'));
                waitfor(helpdlg('For the histogram, the graph can be saved as a picture file.',...
                    'What can be Saved?'));
                waitfor(helpdlg('For the heatmap, the graph and colorbar can be saved, along with text stating what filters are applied to the chart.',...
                    'What can be Saved?'));
        end
end


% --- Executes on button press in load_image_button.
function load_image_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_image_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Use "uigetfile" function to get the filename and filepath
[picture_filename, picture_pathname] = uigetfile('*.jpg;*.tiff;*.png;*.bmp', 'Select Original Picture');

% Check to make sure user chose a file
if picture_filename == 0
    % If not, stop the callback function
    return
end

% Use "fullfile" function to combine pathname and filename
picture_pathfile = fullfile(picture_pathname, picture_filename);

% Use "imread" function to read the image file
original_photo_data = imread(picture_pathfile);

% Load the image data onto the axes, and get rid of tick marks
image(original_photo_data, 'Parent', handles.Original_Photo);
set(handles.Original_Photo, 'XTick', []);
set(handles.Original_Photo, 'YTick', []);

% Load the name of the image on the static text
set(handles.original_title_text, 'String', picture_filename);
set(handles.original_title_text, 'FontSize', 12);

% Store the original picture data handle in the GUI
handles.original_photo_data = original_photo_data;
guidata(hObject, handles);

% Check to see if the user wants to also upload a mask photo
if ~get(handles.upload_mask_button, 'Value')
    % If not, stop the callback function
    return
end

% If so, prompt the user to choose the mask photo using the "uigetfile"
% funciton
[mask_filename, mask_pathname] = uigetfile('*.jpg;*.tiff;*.png;*.bmp', 'Select Mask Picture');

% Check to make sure the user chose a file
if mask_filename == 0
    % If not, stop the callback function
    return
end

% Use "fullfile" function to combine pathname and filename
mask_pathfile = fullfile(mask_pathname, mask_filename);

% Use "imread" function to read the image file
mask_photo_data = imread(mask_pathfile);

% Load the image data onto the axes, and get rid of tick marks
image(mask_photo_data, 'Parent', handles.Mask_Photo);
set(handles.Mask_Photo, 'XTick', []);
set(handles.Mask_Photo, 'YTick', []);

% Store the original picture data handle in the GUI
handles.mask_photo_data = mask_photo_data;
guidata(hObject, handles);


% --- Executes on button press in upload_mask_button.
function upload_mask_button_Callback(hObject, eventdata, handles)
% hObject    handle to upload_mask_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of upload_mask_button


% --- Executes on button press in download_data_button.
function download_data_button_Callback(hObject, eventdata, handles)
% hObject    handle to download_data_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check to make sure the user analyzed an image
if ~isfield(handles, 'bw_photo_data')
    % If not, display an error message, and stop the callback function
    msgbox('Please analyze an image first');
    return
end

% Create a structure array for the summary data
summary = struct('Number', length(handles.mean_intensity), 'Mean',...
    mean(handles.mean_intensity), 'Std', std(handles.mean_intensity));

% Check to see if a mask photo was analyzed
if isfield(handles, 'percent_infected')
    % If so, add it to the summary struct
    summary.Percent_Infected = handles.percent_infected;
end

% Tabulate the data
tabulated_data = array2table(handles.mean_intensity', 'VariableNames', {'Intensity'});
tabulated_data_summary = struct2table(summary);

% Use function "uiputfile" to get the path name and file name for where the
% user wants to save the table
[save_file_name, save_path_name] = uiputfile('*.xlsx', 'Save Data As');

% Check to make sure the user chose a file
if save_file_name == 0
    % If not, stop the callback function
    return
end

% Use "fullfile" function to combine path name and file name
save_pathfile = fullfile(save_path_name, save_file_name);

% Write the data to the selected file
writetable(tabulated_data(:,1), save_pathfile, 'Sheet', 1);
writetable(tabulated_data_summary, save_pathfile, 'Sheet', 2);


% --- Executes on button press in save_histogram_button.
function save_histogram_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_histogram_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check to see if the user analzyed an image
if ~isfield(handles, 'mean_intensity')
    % If not, display an error message, and stop the callback function
    msgbox('Please analyze an image first');
    return
end

% Ask the user where they would like to save the histogram
[save_file_name, save_path_name] = uiputfile('*.jpg;*.tiff;*.png;*.bmp', 'Save Histogram As');

% Check to see if the user chose a file
if save_file_name == 0
    % If not, stop the callback function
    return
end

% Use the "fullfile" function to combine the path name and file name
save_pathfile = fullfile(save_path_name, save_file_name);

% Recreate the histogram to save it
copy_fig = figure;
set(copy_fig, 'Visible', 'off');
histogram(handles.mean_intensity, 'Parent', copy_fig);
title(copy_fig.CurrentAxes, ['Intensity Histogram of ', get(handles.original_title_text,'String')])
saveas(copy_fig, save_pathfile);
close(copy_fig);


% --- Executes on button press in save_heatmap_button.
function save_heatmap_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_heatmap_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check to see if the user analzyed an image
if ~isfield(handles, 'bw_photo_data')
    % If not, display an error message, and stop the callback function
    msgbox('Please analyze an image first');
    return
end

% Ask the user where they would like to save the histogram
[save_file_name, save_path_name] = uiputfile('*.jpg;*.tiff;*.png;*.bmp', 'Save Heatmap As');

% Check to see if the user chose a file
if save_file_name == 0
    % If not, stop the callback function
    return
end

% Use the "fullfile" function to combine the path name and file name
save_pathfile = fullfile(save_path_name, save_file_name);

% Recreate the heatmap to save it
copy_fig = figure;
set(copy_fig, 'Visible', 'off');
displayheatmap(handles, copy_fig);
title(copy_fig.CurrentAxes, ['Heatmap of ', get(handles.original_title_text,'String')])
uicontrol('Style', 'Text', 'String', ['Min filter is ', num2str(get(handles.min_slider, 'Value')),...
    ', Max filter is ', num2str(get(handles.max_slider, 'Value'))], 'Position', [2 20 550 20],...
    'FontSize', 12);
saveas(copy_fig, save_pathfile);
close(copy_fig);


% --- Executes on slider movement.
function min_slider_Callback(hObject, eventdata, handles)
% hObject    handle to min_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% Get the current position of the min slider
min_pos = get(handles.min_slider, 'Value');

% Round the value to the nearest integer
min_pos = round(min_pos);

% Set the slider value and the editable text box accordingly
set(handles.min_slider, 'Value', min_pos);
set(handles.min_text_box, 'String', min_pos);

% Check to see if the user analyzed an image
if isfield(handles, 'bw_photo_data')
    % If so, call the user function to redisplay the heatmap
    displayheatmap(handles, handles.heatmap_panel);
end


% --- Executes during object creation, after setting all properties.
function min_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function max_slider_Callback(hObject, eventdata, handles)
% hObject    handle to max_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% Get the current position of the max slider
max_pos = get(handles.max_slider, 'Value');

% Round the value to the nearest integer
max_pos = round(max_pos);

% Set the slider value and the editable text box accordingly
set(handles.max_slider, 'Value', max_pos);
set(handles.max_text_box, 'String', max_pos);

% Check to see if the user analyzed an image
if isfield(handles, 'bw_photo_data')
    % If so, call the user function to redisplay the heatmap
    displayheatmap(handles, handles.heatmap_panel);
end


% --- Executes during object creation, after setting all properties.
function max_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function min_text_box_Callback(hObject, eventdata, handles)
% hObject    handle to min_text_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of min_text_box as text
%        str2double(get(hObject,'String')) returns contents of min_text_box as a double

% Get the current value in the min text box, and convert it to a numeric
% answer. Round it to the nearest integer
min_pos = get(handles.min_text_box, 'String');
min_pos = str2num(min_pos);
min_pos = round(min_pos);

% Check to make sure it is both an integer, and between the limits of 0 to
% 255. If it is not, alert the user, and stop the callback function. Set
% the textbox back to the previous position by getting the position of the
% slider
if isempty(min_pos)
    msgbox('Please input an integer');
    min_pos = get(handles.min_slider, 'Value');
    set(handles.min_text_box, 'String', min_pos);
    return
elseif min_pos > 255 || min_pos < 0
    msgbox('Please input an integer between 0 and 255');
    min_pos = get(handles.min_slider, 'Value');
    set(handles.min_text_box, 'String', min_pos);
    return
end

% Set the slider value and text box accordingly
set(handles.min_slider, 'Value', min_pos);
set(handles.min_text_box, 'String', min_pos);

% Check to see if the user analyzed an image
if isfield(handles, 'bw_photo_data')
    % If so, call the user function to redisplay the heatmap
    displayheatmap(handles, handles.heatmap_panel);
end


% --- Executes during object creation, after setting all properties.
function min_text_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min_text_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function max_text_box_Callback(hObject, eventdata, handles)
% hObject    handle to max_text_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of max_text_box as text
%        str2double(get(hObject,'String')) returns contents of max_text_box as a double

% Get the current value in the max text box, and convert it to a numeric
% answer. Round it to the nearest integer
max_pos = get(handles.max_text_box, 'String');
max_pos = str2num(max_pos);
max_pos = round(max_pos);

% Check to make sure it is both an integer, and between the limits of 0 to
% 255. If it is not, alert the user, and stop the callback function. Set
% the textbox back to the previous position by getting the position of the
% slider
if isempty(max_pos)
    msgbox('Please input an integer');
    max_pos = get(handles.max_slider, 'Value');
    set(handles.max_text_box, 'String', max_pos);
    return
elseif max_pos > 255 || max_pos < 0
    msgbox('Please input an integer between 0 and 255');
    max_pos = get(handles.max_slider, 'Value');
    set(handles.max_text_box, 'String', max_pos);
    return
end

% Set the slider value and text box accordingly
set(handles.max_slider, 'Value', max_pos);
set(handles.max_text_box, 'String', max_pos);

% Check to see if the user analyzed an image
if isfield(handles, 'bw_photo_data')
    % If so, call the user function to redisplay the heatmap
    displayheatmap(handles, handles.heatmap_panel);
end


% --- Executes during object creation, after setting all properties.
function max_text_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_text_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in trace_mask_button.
function trace_mask_button_Callback(hObject, eventdata, handles)
% hObject    handle to trace_mask_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of trace_mask_button


% --- Executes on button press in analyze_standards_button.
function analyze_standards_button_Callback(hObject, eventdata, handles)
% hObject    handle to analyze_standards_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of analyze_standards_button


% USER FUNCTIONS

% function bw = rgb2bw(handles)
% Purpose: to convert a color image to a black and white image based on the
% filter selection

function bw = rgb2bw(handles)

% Check the filter button that is selected

% Find the radio button with the value of 1 ("on")
selection = findobj('Value', 1);
selection = selection(end);
switch selection.String
    % If it is green, take the green channel of the original image
    case 'Green (GFP)'
        bw = handles.original_photo_data(:,:,2);
    % If it is red, take the red channel of the original image
    case 'Red (RFP)'
        bw = handles.original_photo_data(:,:,1);
    % If it is yellow, take the min of the green and red channels of the
    % original image
    case 'Yellow (YFP)'
        bw = min(handles.original_photo_data(:,:,1), handles.original_photo_data(:,:,2));
    % If it is blue, take the blue channel of the original image
    case 'Blue (BFP)'
        bw = handles.original_photo_data(:,:,3);
    % Otherwise, display an error message, and stop the callback function
    otherwise
        msgbox('Error: The function did not work properly');
        return
end

% function displayheatmap(handles, figure)
% Purpose: to display the heat map on the figure based on the filters
% applied by the sliders and text boxes

function displayheatmap(handles, figure)

% Get the limit for the intensities based on the value of the sliders
minlimit = get(handles.min_slider, 'Value');
maxlimit = get(handles.max_slider, 'Value');

% Create the mask by finding the values inbetween these two limits
heatmap_mask = handles.bw_photo_data >= minlimit & handles.bw_photo_data <= maxlimit;

% Apply this mask to the greyscale image. Pixels within the limit will have
% their intensity stay the same, while pixels outside the limit will have
% their intensity changed to zero
heatmap_data = heatmap_mask .* double(handles.bw_photo_data);

% Display a heatmap based on the greyscale image and the mask
heatmap(figure, heatmap_data, 'XDisplayLabels', handles.xlabels,...
    'YDisplayLabels', handles.ylabels, 'Colormap', handles.cmap, 'GridVisible', 'off');
caxis([0, 255]);

