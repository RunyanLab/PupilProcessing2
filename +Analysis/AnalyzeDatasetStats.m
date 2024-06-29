%% Select file locations
addpath(genpath("W:\James\PupilProcessing2"));
disp('Select movies location');
inputFolder = uigetdir;
disp('Select save folder');
outputFolder = uigetdir;
locations{1} = inputFolder;
locations{2} = outputFolder;
cd(inputFolder);
movies=dir('*.avi');
sampling_rate = VideoReader(movies(1).name).FrameRate;
numBlocks = size(movies,1);

%% plot things
scatter3(datasetStatsStruct.MeanInt, datasetStatsStruct.MaxInt, datasetStatsStruct.STDev,'.k')
xlabel('Mean')
ylabel('Max')
zlabel('STDev')
