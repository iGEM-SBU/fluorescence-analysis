% Script file: fluorescence_intensity_bulk
%
% Purpose: To analyze a set of images in a folder using the function
% "fluorescence_intensity"

% Clear the workspace
%clear;

% Prompt the user to choose a folder with the images to be analyzed
directory = uigetdir('', 'Please choose a folder of photos to be analzyed');

% Check to make sure user chose a directory
if directory == 0
    % If not, display an error message, and stop the callback function
    fprintf('Error: A folder was not selected \n');
    return
end

% Filter out the pictures using the function "fullfile" such that only
% images from the file are selected
filters = fullfile(directory, {'*.jpg', '*.tiff', '*.png', '*.bmp'});

% Initialize the file empty array
file_empty = zeros(1,4);

% Loop through the four filters
for v = 1:4
    % Create the filenames based on the different filters
    varnames{v} = dir(filters{v});
    % Check to see if the file is empty based on the filters, and add it to
    % the array
    file_empty(v) = isempty(varnames{v});
end

% Check to make sure there is at least one file that is an image
if all(file_empty)
    % If there are no images, display an error message, and stop the
    % callback function
    fprintf('Error: No files in the folder were images \n');
    return
else
    % If there are images, find the first filter that has an image in it,
    % and save it for the folder to properly be identified
    for v = 1:4
        if ~file_empty(v)
            folder_index = v;
            break
        end
    end
end

% Add all these names to one cell array
filenames = {varnames{1}.name, varnames{2}.name, varnames{3}.name,...
    varnames{4}.name};

% Find the folder name
foldername = {varnames{folder_index}.folder};
foldername = foldername{1};

% Create the proper file path names
files = fullfile(foldername, filenames);

% Create valid names from file names
validnames = matlab.lang.makeValidName(filenames);

% Prompt the user to input the filter used in the pictures
% Note: this assumes that the same standard is applied to every picture
filter = input('Please input the filter to be applied (green, red, yellow, or blue): ', 's');

% Check that the filter was inputted correctly
if ~ischar(filter)
    fprintf('Error: The filter was not inputted correctly \n');
    return
elseif isempty(filter)
    filter = 'Green';
elseif all(~strcmpi(filter, {'Green', 'g', 'Red', 'r', 'Yellow', 'y', 'Blue', 'b'}))
    fprintf('Error: The filter must be specified accordingly \n');
    help fluorescence_intensity;
    return
end

% Prompt the user to choose how they would like to input the mask
maskstate = input('Please input how you would like the mask to be applied (off, trace, or photo): \n', 's');

% Check that the maskstate was inputted correctly
if ~ischar(maskstate)
    fprintf('Error: The MaskState was not inputted correctly \n');
    return
elseif isempty(maskstate)
    maskstate = 'off';
elseif strcmpi(maskstate, 'photo')
    % Prompt the user to choose the folder of mask photos
    directory = uigetdir('', 'Please choose a folder of mask photos');
    
    % Check to make sure the user chose a directory
    if directory == 0
        % If not, display an error message, and stop the callback function
        fprintf('Error: A folder was not selected \n');
        return
    end
    
    % Filter out the pictures using the function "fullfile" such that only
    % images from the file are selected
    filters = fullfile(directory, {'*.jpg', '*.tiff', '*.png', '*.bmp'});
    
    % Initialize the file empty array
    file_empty = zeros(1,4);

    % Loop through the four filters
    for v = 1:4
        % Create the filenames based on the different filters
        varnames{v} = dir(filters{v});
        % Check to see if the file is empty based on the filters, and add it to
        % the array
        file_empty(v) = isempty(varnames{v});
    end

    % Check to make sure there is at least one file that is an image
    if all(file_empty)
        % If there are no images, display an error message, and stop the
        % callback function
        fprintf('Error: No files in the folder were images \n');
        return
    else
        % If there are images, find the first filter that has an image in it,
        % and save it for the folder to properly be identified
        for v = 1:4
            if ~file_empty(v)
                folder_index = v;
                break
            end
        end
    end

    % Add all these names to one cell array
    masknames = {varnames{1}.name, varnames{2}.name, varnames{3}.name,...
        varnames{4}.name};

    % Find the folder name
    maskfoldername = {varnames{folder_index}.folder};
    maskfoldername = maskfoldername{1};

    % Create the proper file path names
    mask_photos = fullfile(maskfoldername, masknames);
    
    % Check to make sure the two folders have the same number of images
    if length(mask_photos) ~= length(files)
        % If not, display an error message, and stop the callback function
        fprintf('Error: The number of mask images is not equal to the number of original images \n');
        return
    end
    
elseif strcmpi(maskstate, 'off') || strcmpi(maskstate, 'trace')
else
    fprintf('Error: The MaskState must be specified accordingly \n');
    help fluorescence_intensity;
    return
end

% Prompt the user to choose if they would like to analyze standards
standardstate = input('Please input if you would like to analyze standards (on or off): \n', 's');

% Check that the standardstate is inputted correctly
if ~ischar(standardstate)
    fprintf('Error: The StandardState was not inputted correctly \n');
    return
elseif isempty(standardstate)
    standardstate = 'off';
elseif strcmpi(standardstate, 'off') || strcmpi(standardstate, 'on')
else
    fprintf('Error: The StandardState must be specified accordingly \n');
    help fluorescence_intensity;
    return
end

% Initialize the cell array for the raw data, and the matrix for the
% summary data
raw_data = cell(1, length(files));
summary_data = zeros(length(files), 4);

% Communicate with the user that the function is analyzing 
fprintf('Analyzing %d images...\n', length(files));

% Loop through the files cell array
for ii=1:length(files)
    % Call the function "fluorescence_intensity" to output the raw and
    % summary stats
    if strcmpi(maskstate, 'off') || strcmpi(maskstate, 'trace')
        [raw, summary] = fluorescence_intensity(files{ii}, 'Filter', filter,...
            'MaskState', maskstate, 'StandardState', standardstate);
    else
        [raw, summary] = fluorescence_intensity(files{ii}, 'Filter', filter,...
            'MaskState', mask_photos{ii}, 'StandardState', standardstate);
    end
    
    % Save the raw data and the summary data
    raw_data{ii} = raw';
    summary_data(ii, 1:4) = summary;
    
    % Check if the raw data is empty
    if isempty(raw_data{ii})
        % If so, change it to "0"
        raw_data{ii} = 0;
    end
    
    % Check if the index is a multiple of ten
    if rem(ii,10) == 0
        % If so, display the current number of images analyzed for the user
        fprintf('%d images analyzed...\n', ii);
    end
end

% Clear the command window of any messages outputted during the loop
clc;

% Communicate with the user that all of the images have been analyzed
fprintf('All images have been analyzed \n');

% Check if the last column of the summary data is NaN
if all(isnan(summary_data(:,4)))
    % If so, delete it
    summary_data(:,4) = [];
end

% Ask the user if they would like to save the data as an excel file
answer = input('Would you like to save the data as an Excel file (y/n): ', 's');

% Check the answer
if strcmpi(answer, 'yes') || strcmpi(answer, 'y')
    % If so, use function "uiputfile" to get the path name and file name
    % for where the user wants to save the data
    [save_file_name, save_path_name] = uiputfile('*.xlsx', 'Save Data As');

    % Check to make sure the user chose a file
    if save_file_name == 0
        % If not, stop the callback function
        return
    end

    % Use "fullfile" function to combine path name and file name
    save_pathfile = fullfile(save_path_name, save_file_name);
    
    % Tabulate the summary data
    [~, ysize] = size(summary_data);
    if ysize == 4
        varnames = {'Number', 'Mean', 'Std', 'Percent_Infected'};
    else
        varnames = {'Number', 'Mean', 'Std'};
    end
    tabulated_summary = array2table(summary_data, 'VariableNames', varnames);
    
    % Initialize the percent for the user 
    userper = 0;
    
    % Alert the user that the data is being saved
    fprintf('Saving data...\n');
    
    % Write the summary data in the corresponding column in sheet 2
    writetable(tabulated_summary, save_pathfile, 'Sheet', 2);
    
    % Loop through the raw data
    for ii = 1:length(files)
        % Use user function "ExcelColumn" to get the column where the raw
        % data will be written
        column = ExcelColumn(ii);
        
        % Write the raw data in the corresponding column in sheet 1
        writetable(array2table(raw_data{ii}, 'VariableNames', validnames(ii)),...
            save_pathfile, 'Range', [column '1'], 'Sheet', 1);
        
        % Check if the new index is a new multiple of 10%
        if floor(ii*10/length(files)) > userper
            % If so, alert the user of the progress, and update the percent
            userper = userper + 1;
            fprintf('%d%% done...\n', userper*10);
        end
    end
    
    % Clear the command window of any messages outputted during the program
    clc;
    
    % Alert the user that saving has finished
    fprintf('All data has been saved successfully\n');
else
    % If not, alert the user where the information has been saved
    fprintf('The raw data has been saved in the variable "raw_data"\n');
    fprintf('The summary data has been saved in the variable "summary_data"\n');
end

% USER FUNCTIONS

% function column = ExcelColumn(ii)
% Purpose: to convert a number into its corresponding Excel Column

function column = ExcelColumn(ii)

% Initialize the alphabet, the column output, and the value for the
% algorithm
alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
column = '';
algval = ii;

% Get the number of digits the column will have by taking the ceiling of
% the log of the input
numdig = ceil(log(ii)/log(26));

% If the number of digits is exactly zero, then output 'A'
if numdig == 0
    column = 'A';
    return
end

% Perform the algorithm for each of the digits
while numdig > 0
    % Divide the algorithm value by the power of 26 correspoinding to that
    % digit
    tempval = algval / (26^(numdig-1));
    
    % Check if there is a remainder when dividing by 26
    checkrem = rem(algval, 26);
    if checkrem == 0
        % If so, the last value is a 'Z', so another algorithm is needed
        % Divide the algorithm value by 26, and subtract 1
        tempval = (algval/26) - 1;
        if tempval == 0
            % If it is 0, output 'Z'
            column = 'Z';
            return
        else
            % If it is not, repeat the algorithm with the new temporary
            % value to get the values in front of the 'Z'
            column = ExcelColumn(tempval);
            % Add a 'Z' to the end of the output
            column = [column, 'Z'];
            return
        end
    end
    
    % Take the floor of that value to get the value for the letter
    letval = floor(tempval);
    
    % Use that value to get the letter for that digit
    column = [column, alphabet(letval)];
    
    % Subtract the letter value from the temporary value to get the
    % remainder
    remainder = tempval - letval;
    
    % Multiply the remainder by the power of 26 to get the new algorithm
    % value. Round it to get rid of any error from multiplying
    algval = remainder * (26^(numdig-1));
    algval = round(algval);
    
    % Move to the next digit
    numdig = numdig - 1;
end
end