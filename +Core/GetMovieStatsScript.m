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

%% select ROI
block = 5;
exampleFrame = 225;

theMovie = VideoReader(movies(block).name);
[eyeMask] = Processing.Masking(movies,block,exampleFrame);
save('pupil_setup');

%% PCA on full dataset
framesIndices = [151 175 145 1331;
                3152 3175 3144 4331];
chunkSize = 500;

parfor blck = 1:2%numBlocks
    CutAndReshapeFunc(movies,blck,framesIndices,chunkSize,eyeMask,outputFolder)
end

%% concatenate cut and reshaped blocks

for blck = 1:2%numBlocks
    outputName = strcat(outputFolder,'\block',num2str(blck),'2D');
    load(outputName)

    if blck ~= 1
        thisDataset2D = [thisDataset2D thisBlock2D];
    else
        thisDataset2D = thisBlock2D;
    end
end

%% normalize dataset and do PCA

[U,S,V] = svd(thisDataset2D,'econ','vector');
thisDatasetMeanFrame = mean(thisDataset2D,2);
thisDatasetNormalized = thisDataset2D - thisDatasetMeanFrame;
for pc = 1:3
    for frm = 1:size(thisDatasetNormalized,2)
        thisDatasetNormInPC(pc, frm) = thisDatasetNormalized(:,frm)'*U(:,pc);
    end
end

%% plotting 

% 1:size(thisDatasetNormInPC,2)
scatter3(thisDatasetNormInPC(1,:) , thisDatasetNormInPC(2,:) ,thisDatasetNormInPC(3,:) ,"Marker",".","MarkerEdgeColor","k")
xticks([])
yticks([])
zticks([])
xlabel("1")
ylabel("2")
zlabel("3")

%% functions

function CutAndReshapeFunc(movies,block,framesIndices,chunkSize,eyeMask,outputFolder)
    disp(strcat("starting block ", num2str(block)));
    tic
    theMovie = VideoReader(movies(block).name);
    thisBlockStartFrame = framesIndices(1,block);
    thisBlockEndFrame = framesIndices(2,block);
    thisBlockNumFrames = thisBlockEndFrame-thisBlockStartFrame;

    for chnk = 1:round(thisBlockNumFrames/chunkSize,TieBreaker="plusinf")
        chunkStartFrame = thisBlockStartFrame + ((chnk-1)*chunkSize);

        if thisBlockStartFrame + (chnk*chunkSize) > thisBlockEndFrame
            chunkEndFrame = thisBlockEndFrame;
        else
            chunkEndFrame = thisBlockStartFrame + (chnk * chunkSize);
        end
    
        thisChunk = read(theMovie, [chunkStartFrame chunkEndFrame]);
        thisChunk = im2single(thisChunk);
        thisChunk = thisChunk(eyeMask(2):eyeMask(2)+eyeMask(4), eyeMask(1):eyeMask(1)+eyeMask(3),1,:);
        [yPixels, xPixels, nFrames] = size(thisChunk);
        thisChunk2D = reshape(thisChunk,xPixels*yPixels,nFrames);

        if chnk ~= 1 % add chunk struct to block struct
            thisBlock2D = [thisBlock2D thisChunk2D];
        else 
            thisBlock2D = thisChunk2D;
        end
        thisChunk2D = []; % clear the chunk so it isn't taking up memory before being overwritten
    end
    
    outputName = strcat(outputFolder,'\block',num2str(block),'2D'); % save the block struct
    save(outputName,"thisBlock2D")
    thisBlock2D = [];
    toc
    disp(strcat("Block ",num2str(block), " complete."))
end % end CutAndReshapeFunc

% this is now defunct but it's well written so it's worth keeping to look back at
function GetBlockStatsFunc(movies, block, eyeMask,outputFolder,chunkSize)
    blockStatsStruct = struct;
    chunkStatsStruct = struct;
    theMovie = VideoReader(movies(block).name);
    numFrames = theMovie.NumFrames;
    tic
    disp(strcat("starting block ",num2str(block)))
    
    for chnk = 1:round(numFrames/chunkSize,TieBreaker="plusinf") % cannot send whole block to GPU at once so must break it up;
        chunkStartFrame = 1 + ((chnk-1)*chunkSize);              
        if chnk*chunkSize > numFrames
            chunkEndFrame = numFrames;
        else
            chunkEndFrame = chnk * chunkSize;
        end
    
        thisChunk = read(theMovie, [chunkStartFrame, chunkEndFrame]); % read select frames of AVI into matrix on CPU
        thisChunk = gpuArray(thisChunk);                              % pass the matrix to GPU
        thisChunk = im2single(thisChunk);
        thisChunk = thisChunk(eyeMask(2):eyeMask(2)+eyeMask(4), eyeMask(1):eyeMask(1)+eyeMask(3),1,:); % crop the matrix as a block 
        
        for frm = 1:chunkEndFrame-chunkStartFrame+1 % collect stats on each frame
            ;
        end
    
        if chnk ~= 1 % add chunk struct to block struct
            ;
        else 
            blockStatsStruct = chunkStatsStruct;
        end
        chunkStatsStruct = []; % clear the chunk struct so it isn't taking up memory before being overwritten
    end
    
    outputName = strcat(outputFolder,'\block',num2str(block),'Stats'); % save the block struct
    save(outputName,"blockStatsStruct")
    blockStatsStruct = [];
    disp(strcat("Block ",num2str(block), " complete."))
    toc
end % end GetBlockStatsFunc