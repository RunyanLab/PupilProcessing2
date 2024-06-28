%% Select file locations
addpath(genpath("W:\James\PupilProcessing2"));
disp('Select movies location');
inputFolder = uigetdir;
disp('Select save folder');
outputFolder = uigetdir;
locations{1} = inputFolder;
locations{2} = outputFolder;
save("W:\James\PupilProcessing2\Temp\locations", 'locations');
cd(inputFolder);
movies=dir('*.avi');
sampling_rate = VideoReader(movies(1).name).FrameRate;
numBlocks = size(movies,1);

%% Load previous file locations
addpath(genpath("W:\James\PupilProcessing2"));
load("W:\James\PupilProcessing2\Temp\locations.mat");
inputFolder = locations{1};
outputFolder = locations{2};
cd(inputFolder);
movies=dir('*.avi');
sampling_rate = VideoReader(movies(1).name).FrameRate;
load("pupil_setup.mat");
numBlocks = size(movies,1);

%% Establish processing parameters
block = 5;
exampleFrame = 300;

theMovie = VideoReader(movies(block).name);
[eyeMask,eyeEllipse,problemsMask,exampleImage] = Processing.Masking(movies,block,exampleFrame);
save('pupil_setup');

%% testing
addpath(genpath("W:\James\PupilProcessing2"));
theMovie = VideoReader(movies(block).name);
testingImages = read(theMovie);

tic
disp('tic')
frm = 1;
while hasFrame(theMovie)
    frm
    the_image = readFrame(theMovie,"native");
    the_image = imcrop(the_image,eyeMask);

    blockStatsStruct.MeanInt(frm) = mean(the_image,"all"); 

    blockStatsStruct.MaxInt(frm) = max(the_image,[], "all");

    blockStatsStruct.MinInt(frm) = min(the_image,[],"all");

    the_image = im2double(the_image);
    blockStatsStruct.STDev(frm) = std(the_image,1,"all")*256;
    frm = frm+1;
end
toc
%time to run on CPU: 86 sec
%time to run on GPU: 120 sec
%% get stats for all movies at once using parallel computing

addpath(genpath("W:\James\PupilProcessing2"));

parfor blck = 1:numBlocks
    GetBlockStats(movies,blck,eyeMask,outputFolder)
end

%% concatenate structures
datasetStatsStruct = struct();
for blck = 1:numBlocks
    outputName = strcat(outputFolder,'\block',num2str(blck),'Stats');
    load(outputName)

    if blck ~= 1
        datasetStatsStruct = [datasetStatsStruct, blockStatsStruct];        
    else 
        datasetStatsStruct = blockStatsStruct;
    end
end

%% functions 

function GetBlockStats(movies, block, eyeMask,outputFolder)
    theMovie = VideoReader(movies(block).name);
    frm = 1;
    tic
    while hasFrame(theMovie)
        if mod(frm,100) == 0
            block 
            frm
        end

        the_image = readFrame(theMovie);
        the_image = gpuArray(the_image);
        the_image = imcrop(the_image,eyeMask);
    
        blockStatsStruct.MeanInt(frm) = mean(the_image,"all"); 
    
        blockStatsStruct.MaxInt(frm) = max(the_image,[], "all");
    
        blockStatsStruct.MinInt(frm) = min(the_image,[],"all");
    
        the_image = im2single(the_image);
        blockStatsStruct.STDev(frm) = std(the_image,1,"all")*256;
        frm = frm + 1;
    end
    outputName = strcat(outputFolder,'\block',num2str(block),'Stats');
    save(outputName,"blockStatsStruct")
    blockStatsStruct = [];
    toc
    disp(strcat('Block ',num2str(block), 'complete.'))
end
% time to run on CPU: ~115 sec for 2 blocks; ~210 for 6 blocks; ~400 for 12 blocks
% time to run on GPU: ~139 sec for 2 blocks; ~220 for 6 blocks; ~420 for 12 blocks; so, processing on GPU scales better 
