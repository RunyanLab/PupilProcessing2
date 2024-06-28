function [eyeMask,eyeEllipse,problemsMask,exampleImage] = Masking(movies, block, exampleFrame)

    exampleMovie = VideoReader(movies(block).name);
    exampleImage = read(exampleMovie,exampleFrame);
    rows = size(exampleImage,1);
    columns = size(exampleImage,2);
    
    figure()
    imshow(exampleImage)
    title('Draw Eye ROI')
    hold on 
    eye = drawellipse;
    pause;
    eyeEllipse = poly2mask(eye.Vertices(:,1), eye.Vertices(:,2) , rows, columns);
    [row, column] = find(eyeEllipse);
    eyeMask = [min(column) min(row) max(column)-min(column) max(row)-min(row)];
    eyeEllipse = imcrop(eyeEllipse, eyeMask);

%     title('Mask over problems')
%     problemPoly = drawellipse('Color','r');
%     pause;
%     problemsMask = imcrop(poly2mask(problemPoly.Vertices(:,1), problemPoly.Vertices(:,2), rows, columns), eyeMask);
%     moreProb = input('Would you like to mask over another problem? \n');
%     num = 2;
%     while moreProb
%        problemPoly = drawellipse('Color','r');
%        pause
%        problemMask = imcrop(poly2mask(problemPoly.Vertices(:,1), problemPoly.Vertices(:,2), rows, columns), eyeMask);
%        problemsMask(problemMask) = 1;
%        num = num+1;
%        moreProb = input('Would you like to input another corneal reflection? 0/1 \n');
%     end
    problemsMask = [];
    close all
end