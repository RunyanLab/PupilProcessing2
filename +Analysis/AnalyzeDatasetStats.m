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
numBlocks = size(movies,1);

%% scatterplot top 3 PCs
scatter3(datasetStatsStruct.MeanInt, datasetStatsStruct.MaxInt, datasetStatsStruct.STDev,'.k')
xlabel('Mean')
ylabel('Max')
zlabel('STDev')

%% histogram
figure(777)
scatter3(datasetStatsStruct.HistogramMaxima1,datasetStatsStruct.HistogramMaxima2,datasetStatsStruct.HistogramMaxima3)
xlabel('1')
ylabel('2')
zlabel('3')

%% PC of hist maxima
% normalizedHM1 = normalize(datasetStatsStruct.HistogramMaxima1);
% normalizedHM2 = normalize(datasetStatsStruct.HistogramMaxima2);
% normalizedHM3 = normalize(datasetStatsStruct.HistogramMaxima3);

normalizedHM = vertcat(normalizedHM1,normalizedHM2,normalizedHM3)';
normHM = gather(normalizedHM);
[U,S,V] = svd(normHM,"econ","vector");
scatter3(U(:,1),U(:,2),U(:,3));