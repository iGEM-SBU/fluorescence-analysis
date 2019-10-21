## Stony Brook iGEM 2019

## Requirements
MATLAB R2018a or later\
MATLAB Image Processing Toolbox

## Downloaded Files
Fluorescent_Intensity_Analysis.fig: This is the figure file for the GUI\
Fluorescent_Intensity_Analysis.m: This is the code for the GUI (to be used with the figure file above). BOTH of these are neceesary to run.\
fluorescence_intensity.m: This is a function that performs the same algorithm as the GUI\
fluorescence_intensity_bulk.m: This is a script for performing this algorithm on a folder of images. This REQUIRES the function fluorescence_intensity.m to run.

## How to use
For individual photos, the files Fluorescent_Intensity_Analysis.fig and Fluorescent_Intensity_Analysis.m can be used. When you run the program, a figure box will be displayed. First, upload an image by pressing the "upload image" button. Then, select the filter (which fluorescent protein to use) and options about analyzing the image. Then, click "analyze images" to calculate the fluorescent intensities. There is also a help button included for more help on how to use the GUI.
For multiple photos, the files fluorescent_intensity.m and fluorescent_intensity_bulk.m can be used. When you run the bulk script, select a folder of images, and input the specifications of the analysis (the same ones that would be selected in the GUI). The program will then automatically run and output the calculations. Alternatively, the function fluorescent_intensity can be used in other programs. Parameters to input in the function are commented in the code.
