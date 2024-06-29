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
save("pupil_setup.mat")

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
exampleFrame = 225;

theMovie = VideoReader(movies(block).name);
[eyeMask,eyeEllipse,problemsMask] = Processing.Masking(movies,block,exampleFrame);
save('pupil_setup');

%% get stats for all movies at once using parallel computing

addpath(genpath("W:\James\PupilProcessing2"));
cd(inputFolder)

chunkSize = 250; % how many frames to load and send to GPU at once?

parfor blck = 1:numBlocks
    GetBlockStatsFunc(movies,blck,eyeMask,outputFolder,chunkSize)
    pause(1.5) % pause so that loading movies is offset; use full bandwidth from the beginning
end

%% concatenate structures
for blck = 1:numBlocks
    outputName = strcat(outputFolder,'\block',num2str(blck),'Stats');
    load(outputName)

    if blck ~= 1
            datasetStatsStruct.MeanInt = [datasetStatsStruct.MeanInt blockStatsStruct.MeanInt];
            datasetStatsStruct.MaxInt = [datasetStatsStruct.MaxInt blockStatsStruct.MaxInt];
            datasetStatsStruct.MinInt = [datasetStatsStruct.MinInt blockStatsStruct.MinInt];
            datasetStatsStruct.STDev = [datasetStatsStruct.STDev blockStatsStruct.STDev];
        else 
            datasetStatsStruct = blockStatsStruct;
    end

end
save('datasetStatsStruct', "datasetStatsStruct")
%% functions 

function GetBlockStatsFunc(movies, block, eyeMask,outputFolder,chunkSize)
    blockStatsStruct = struct;
    chunkStatsStruct = struct;
    theMovie = VideoReader(movies(block).name);
    numFrames = theMovie.NumFrames;
    tic
    disp(strcat('starting block', ' ' ,num2str(block)))
    
    for chnk = 1:round(numFrames/chunkSize,TieBreaker="plusinf") % cannot send whole block to GPU at once so must break it up;
        chunkStartFrame = 1 + ((chnk-1)*chunkSize);              
        if chnk*chunkSize > numFrames
            chunkEndFrame = numFrames;
        else
            chunkEndFrame = chnk * chunkSize;
        end
    
        thisChunk = read(theMovie, [chunkStartFrame, chunkEndFrame]); % read select frames of AVI into matrix on CPU
        thisChunk = gpuArray(thisChunk);                              % pass the matrix to GPU
        thisChunk = thisChunk(eyeMask(2):eyeMask(2)+eyeMask(4), eyeMask(1):eyeMask(1)+eyeMask(3),1,:); % crop the matrix as a block 
        
        for frm = 1:chunkEndFrame-chunkStartFrame+1 % collect stats on each frame
            chunkStatsStruct.MeanInt(frm) = mean(thisChunk(:,:,1,frm),"all"); 
    
            chunkStatsStruct.MaxInt(frm) = max(thisChunk(:,:,1,frm),[],"all");
    
            chunkStatsStruct.MinInt(frm) = min(thisChunk(:,:,1,frm),[],"all");
            
            thisFrame = im2single(thisChunk(:,:,1,frm));
            chunkStatsStruct.STDev(frm) = std(thisFrame,1,"all")*256;
        end
    
        if chnk ~= 1 % add chunk struct to block struct
            blockStatsStruct.MeanInt = [blockStatsStruct.MeanInt chunkStatsStruct.MeanInt];
            blockStatsStruct.MaxInt = [blockStatsStruct.MaxInt chunkStatsStruct.MaxInt];
            blockStatsStruct.MinInt = [blockStatsStruct.MinInt chunkStatsStruct.MinInt];
            blockStatsStruct.STDev = [blockStatsStruct.STDev chunkStatsStruct.STDev];
        else 
            blockStatsStruct = chunkStatsStruct;
        end
        chunkStatsStruct = [];
    end
    
    outputName = strcat(outputFolder,'\block',num2str(block),'Stats'); % save the block struct
    save(outputName,"blockStatsStruct")
    blockStatsStruct = [];
    disp(strcat('Block ',num2str(block), 'complete.'))
    toc
end % end GetBlockStatsFunc