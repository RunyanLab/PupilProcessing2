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

%% cut and reshape blocks
cd(inputFolder);
framesIndices = [151 175 145 1331 140 143 156 139 1744 154 234 184 117 122 125 115 105 109;
                3152 3175 3144 4331 3141 3143 3156 3140 4745 5156 5235 917 849 855 858 849 838 842];
chunkSize = 500;

parfor blck = 1:numBlocks
    CutAndReshapeFunc(movies,blck,framesIndices,chunkSize,eyeMask,outputFolder)
end

%% concatenate cut and reshaped blocks

cd(inputFolder);
for blck = 1:numBlocks
    outputName = strcat(outputFolder,'\block',num2str(blck),'2D');
    load(outputName)

    if blck ~= 1
        thisDataset2D = [thisDataset2D thisBlock2D];
    else
        thisDataset2D = thisBlock2D;
    end
    thisBlock2D = [];
end

outputName = strcat(outputFolder,'\dataset2D'); % save the block struct
save(outputName,"thisDataset2D")
thisDataset2D = [];

%% normalize dataset and do PCA
tic
inputName = strcat(outputFolder,'\dataset2D');
load(inputName)

thisDataset2D = single(thisDataset2D);
thisDatasetMeanFrame = mean(thisDataset2D,2);
thisDatasetNormalized = thisDataset2D - thisDatasetMeanFrame;
tDNOCPU = gather(thisDatasetNormalized);
clear thisDataset2D thisDatasetMeanFrame thisDatasetNormalized
[U,S,V] = svd(tDNOCPU,'econ','vector');
for pc = 1:3
    for frm = 1:size(tDNOCPU,2)
        thisDatasetNormInPC(pc, frm) = tDNOCPU(:,frm)'*U(:,pc);
    end
end
toc
%% plotting PC scores for all frames

% 1:size(thisDatasetNormInPC,2)
figure(2)
scatter3(thisDatasetNormInPC(1,:) , thisDatasetNormInPC(2,:) ,thisDatasetNormInPC(3,:) ,"Marker",".","MarkerEdgeColor","k")
xticks([])
yticks([])
zticks([])
xlabel("1")
ylabel("2")
zlabel("3")

%% k-means
colorVector = ['r' 'g' 'b' 'c' 'm' 'y'];
[clusterIndices, C] = kmeans(thisDatasetNormInPC',6);
for i = 1:size(C,1)
    scatter3(thisDatasetNormInPC(1,clusterIndices==i),thisDatasetNormInPC(2,clusterIndices==i),thisDatasetNormInPC(3,clusterIndices==i),"MarkerEdgeColor",colorVector(i),"Marker",".")
    hold on
end
hold off

%% separate clusters
cluster1 = thisDataset2D(:,clusterIndices==1);
cluster2 = thisDataset2D(:,clusterIndices==2);
cluster3 = thisDataset2D(:,clusterIndices==3);
cluster4 = thisDataset2D(:,clusterIndices==4);
cluster5 = thisDataset2D(:,clusterIndices==5);
cluster6 = thisDataset2D(:,clusterIndices==6);


%% show example frames from each cluster

figure(2)
tiledlayout("flow")
for c = 1:6
    nexttile
    thisCluster = thisDataset2D(:,clusterIndices==c);
    thisFrame = reshape(thisCluster(:,randi(size(thisCluster,2))),271,[]);
    imshow(thisFrame)
end

%% functions

function CutAndReshapeFunc(movies,block,framesIndices,chunkSize,eyeMask,outputFolder)
    disp(strcat("Starting block ", num2str(block), "."));
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
        thisChunk = gpuArray(thisChunk);
        thisChunk = thisChunk(eyeMask(2):eyeMask(2)+eyeMask(4), eyeMask(1):eyeMask(1)+eyeMask(3),1,:);
        [yPixels, xPixels, nFrames] = size(thisChunk);
        thisChunk2D = reshape(thisChunk,xPixels*yPixels,nFrames);
        thisChunk = [];

        if chnk ~= 1 % add chunk struct to block struct
            thisBlock2D = [thisBlock2D thisChunk2D];
        else 
            thisBlock2D = thisChunk2D;
        end
        thisChunk2D = []; % clear the chunk so it isn't taking up memory before being overwritten
    end
    
    outputName = strcat(outputFolder,'\block',num2str(block),'2D'); % save the block struct
    save(outputName,"thisBlock2D")
    thisBlock2D = []; % clear the block so it isn't taking up memory before being overwritten
    toc
    disp(strcat("Block ",num2str(block), " complete."))
end % end CutAndReshapeFunc