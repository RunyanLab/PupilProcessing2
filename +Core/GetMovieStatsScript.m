%% Select file locations
addpath(genpath("W:\James\PupilProcessing2"));
disp('Select dataset location');
datasetLocation = uigetdir;
disp('Select block stats location');
blockStatsLocation = uigetdir;
disp('Select training frames location')
trainingFramesLocation = uigetdir;
locations{1} = datasetLocation;
locations{2} = blockStatsLocation;
locations{3} = trainingFramesLocation;

save("W:\James\PupilProcessing2\Temp\locations", 'locations');
cd(datasetLocation);
movies=dir('*.avi');
numBlocks = size(movies,1);
save("pupil_setup.mat")

%% Load previous file locations
addpath(genpath("W:\James\PupilProcessing2"));
load("W:\James\PupilProcessing2\Temp\locations.mat");
datasetLocation = locations{1};
blockStatsLocation = locations{2};
trainingFramesLocation = locations{3};
cd(datasetLocation);
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
cd(datasetLocation);
framesIndices = [151 175 145 1331 140 143 156 139 1744 154 234 184 117 122 125 115 105 109;
                3152 3175 3144 4331 3141 3143 3156 3140 4745 5156 5235 917 849 855 858 849 838 842];
chunkSize = 500;
save('pupil_setup')
parfor blck = 1:numBlocks
    CutAndReshapeFunc(movies,blck,framesIndices,chunkSize,eyeMask,blockStatsLocation)
end

%% concatenate cut and reshaped blocks

cd(blockStatsLocation);
for blck = 1:numBlocks
    outputName = strcat(blockStatsLocation,'\block',num2str(blck),'2D');
    load(outputName)

    if blck ~= 1
        thisDataset2D = [thisDataset2D thisBlock2D];
    else
        thisDataset2D = thisBlock2D;
    end
    thisBlock2D = [];
end

cd(blockStatsLocation)
outputName = strcat(blockStatsLocation,'\dataset2D'); % save the block struct
save(outputName,"thisDataset2D")
thisDataset2D = [];

%% normalize dataset and do PCA
tic
inputName = strcat(blockStatsLocation,'\dataset2D');
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
%% scatter plot PC scores for all frames

% 1:size(thisDatasetNormInPC,2)
figure(2)
scatter3(thisDatasetNormInPC(1,:) , thisDatasetNormInPC(2,:) ,thisDatasetNormInPC(3,:) ,"Marker",".","MarkerEdgeColor","k")
xticks([])
yticks([])
zticks([])
xlabel("1")
ylabel("2")
zlabel("3")

%% k-means visualization
colorVector = ['r' 'g' 'b' 'c' 'm' 'y'];
[clusterIndices, C] = kmeans(thisDatasetNormInPC',6);
for i = 1:size(C,1)
    scatter3(thisDatasetNormInPC(1,clusterIndices==i),thisDatasetNormInPC(2,clusterIndices==i),thisDatasetNormInPC(3,clusterIndices==i),"MarkerEdgeColor",colorVector(i),"Marker",".")
    hold on
    xlabel('1')
    ylabel('2')
    zlabel('3')
end
hold off

%% show example frames from each cluster

figure(2)
tiledlayout("flow")
for c = 1:size(C,1)
    nexttile
    thisCluster = thisDataset2D(:,clusterIndices==c);
    imshow(reshape(thisCluster(:,randi(size(thisCluster,2))),271,[]));
end

%% extract frames
addpath(genpath("W:\James\PupilProcessing2"));
load("W:\James\PupilProcessing2\Temp\locations.mat");
datasetLocation = locations{1};
blockStatsLocation = locations{2};
trainingFramesLocation = locations{3};
cd(datasetLocation);
movies=dir('*.avi');
sampling_rate = VideoReader(movies(1).name).FrameRate;
load("pupil_setup.mat");
numBlocks = size(movies,1);

cd(blockStatsLocation)
load("dataset2D.mat")
load("thisDatasetNormInPC.mat")
[clusterIndices, C] = kmeans(thisDatasetNormInPC',6);

for c = 1:size(C,1)
    fieldname = strcat("cluster",num2str(c));
    thisCluster = thisDataset2D(:,clusterIndices==c);
    
    for tstfrm = 1:20
        trainingIm = reshape(thisCluster(:,randi(size(thisCluster,2))),271,[]);
        trainingIm = imresize(gather(trainingIm),[224, 224]);
        cd(trainingFramesLocation)
        imwrite(trainingIm,strcat("im",num2str(tstfrm),"cluster",num2str(c),".png"))
    end
end

%% build training dataset
addpath(genpath("W:\James\PupilProcessing2"));
load("W:\James\PupilProcessing2\Temp\locations.mat");
datasetLocation = locations{1};
blockStatsLocation = locations{2};
trainingFramesLocation = locations{3};
cd(strcat(datasetLocation,'\Labeling'))
load("labelled1.mat")

for img = 1:size(gTruth.LabelData,1)
    coords = gTruth.LabelData(img,1:8);
    coords = table2array(coords);
    clear coordsReady
    for pnt = 1:8
        if isempty(coords{1,pnt})
            coordsReady(pnt,1) = 1;
            coordsReady(pnt,2) = 1;
        else
            coordsReady(pnt,1) = coords{1,pnt}(1);
            coordsReady(pnt,2) = coords{1,pnt}(2);
        end
    end
    keypoints{img,1} = coordsReady;
end
keypointsTable = table;
keypointsTable.keypoints = keypoints;

%% make training materials

pupilImds = imageDatastore(trainingFramesLocation,"FileExtensions",".png");
keypointsDS = arrayDatastore(keypointsTable);
bboxDS = boxLabelDatastore(gTruth.LabelData(:,"boundingBox"));
trainingData = combine(pupilImds,keypointsDS,bboxDS);
keypointClasses = ["point1","point2","point3","point4","point5","point6","point7","point8"]';

%% establish a net
pupilKeypointDetector = hrnetObjectKeypointDetector("human-full-body-w32",keypointClasses,"InputSize",[224 224 1]);
pupilKeypointDetector.Network

%% train the net
options = trainingOptions("adam", ...
    MaxEpochs=840, ...
    InitialLearnRate=0.001, ...
    MiniBatchSize=16, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.1, ...
    LearnRateDropPeriod=12, ...
    VerboseFrequency=25, ...
    BatchNormalizationStatistics="moving", ...
    ResetInputNormalization=false, ...
    CheckpointPath=trainingFramesLocation, ...
    CheckpointFrequency=20);

[trainedPupilKeypointDetector,info] = trainHRNetObjectKeypointDetector(trainingData,pupilKeypointDetector,options);

%% test the net
cd(trainingFramesLocation)
I = imread("im18cluster1.png");
bbox = [35,34,152,163];
predictedKeypoints = detect(trainedPupilKeypointDetector,I,bbox);
outputImg = insertObjectKeypoints(I,predictedKeypoints, ...
    KeypointColor="yellow",KeypointSize=3,LineWidth=3);
outputImg = insertShape(outputImg,rectangle=bbox);
figure
imshow(outputImg)

%% functions

function CutAndReshapeFunc(movies,block,framesIndices,chunkSize,eyeMask,blockStatsLocation)
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
    
    outputName = strcat(blockStatsLocation,'\block',num2str(block),'2D'); % save the block struct
    save(outputName,"thisBlock2D")
    thisBlock2D = []; % clear the block so it isn't taking up memory before being overwritten
    toc
    disp(strcat("Block ",num2str(block), " complete."))
end % end CutAndReshapeFunc