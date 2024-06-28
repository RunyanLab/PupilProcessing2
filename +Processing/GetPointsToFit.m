function [pointsToFit, algorithm]=getPointsToFit(the_image,selectedThreshold,eyeMask,eyeEllipse,cornMask,selectedRightPercentile,SelectedTopPercentile)
    if size(the_image,3)==3
        the_image = rgb2gray(the_image);
    end
    
    selectedRightPercentile = 100 - selectedRightPercentile;

    piel = the_image;
    piel = imcrop(piel, eyeMask); %crop to eye ROI; important for dynamic contrast
    piel = regionfill(piel,~eyeEllipse);
    piel = regionfill(piel,cornMask);%mask out problem areas (may not be reflections on eye)
    piel = histeq(piel); %equalize histogram
    piel = imsharpen(piel, "Amount",3); %increase contrast near edges; helps to see edge of pupil
    piel = imdiffusefilt(piel, 'ConductionMethod', 'quadratic'); %smooth noise from sharpening
    piel = imbinarize(piel, selectedThreshold); %binarize image based on threshold
    CC = bwconncomp(piel);
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [~, idx] = max(numPixels);
    piel = false(size(piel));
    piel(CC.PixelIdxList{idx}) = true; %keep only pupil
    SE = strel('disk', 10);
    piel = imdilate(piel, SE);
    piel = imerode(piel, SE);
    piel = imfill(piel, "holes"); %clean pupil
    piel = edge(piel,'Canny'); %find edges
    [row,column] = find(piel); %get coords of outline points
    pointsToFit = vertcat(row', column');
    rightInd = find(pointsToFit(2,:) >= prctile(pointsToFit(2,:),selectedRightPercentile)); %pick rightmost points based on selected percentile
    topInd = find(pointsToFit(1,:) <= prctile(pointsToFit(1,:),SelectedTopPercentile)); %pick uppermost points based on selected percentile
    ind = intersect(rightInd,topInd); %top right points
    pointsToFit = pointsToFit(:,ind);
    pointsToFit = [pointsToFit(1,:) + eyeMask(2); pointsToFit(2,:) + eyeMask(1)];%add back values left and top values from cropping

    algorithm = readlines(strcat(mfilename("fullpath"), '.m'));  
