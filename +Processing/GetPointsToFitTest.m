function pointsToFit=getPointsToFitTest(the_image,selectedThreshold,eyeMask,eyeEllipse,cornMask,selectedRightPercentile,SelectedTopPercentile)
    if size(the_image,3)==3
        the_image = rgb2gray(the_image);
    end
    selectedRightPercentile = 100 - selectedRightPercentile;

    figure(999) 
    tiledlayout('flow', "TileSpacing","tight", "Padding","tight")

    piel = the_image;

    piel = imcrop(piel, eyeMask);
    nexttile
    imshow(piel)
    
    piel = regionfill(piel,~eyeEllipse); 
    piel = regionfill(piel,cornMask);
    nexttile
    imshow(piel)

    piel = histeq(piel);
    nexttile
    imshow(piel)

    piel = imsharpen(piel, "Amount",3);
    nexttile
    imshow(piel)

    piel = imdiffusefilt(piel, 'ConductionMethod', 'quadratic');
    nexttile
    imshow(piel)

    piel = imbinarize(piel, selectedThreshold);
    nexttile
    imshow(piel)

    CC = bwconncomp(piel);
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [~, idx] = max(numPixels);
    piel = false(size(piel));
    piel(CC.PixelIdxList{idx}) = true;
    nexttile
    imshow(piel)

    SE = strel('disk', 10);
    piel = imdilate(piel, SE);
    piel = imerode(piel, SE);
    piel = imfill(piel, "holes");
    nexttile
    imshow(piel)
    
    piel = edge(piel,'Canny');
    nexttile
    imshow(piel)

    [row,column] = find(piel);
    pointsToFit = vertcat(row', column');
    rightInd = find(pointsToFit(2,:) >= prctile(pointsToFit(2,:),selectedRightPercentile)); %pick rightmost points based on selected percentile
    topInd = find(pointsToFit(1,:) <= prctile(pointsToFit(1,:),SelectedTopPercentile)); %pick uppermost points based on selected percentile
    ind = intersect(rightInd,topInd); %top right points
    pointsToFit = pointsToFit(:,ind);
    pointsToFit = [pointsToFit(1,:) + eyeMask(2); pointsToFit(2,:) + eyeMask(1)];%add back values
