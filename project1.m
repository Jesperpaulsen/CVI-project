%%
% Program that recocnizes objects in a picture. It also recognizes the
% value of euro coins.
close all; clear all;

%% The files to read
filePaths = ["MATERIAL\database\Moedas1.jpg", "MATERIAL\database\Moedas2.jpg", "MATERIAL\database\Moedas3.jpg", "MATERIAL\database\Moedas4.jpg"];
RBGImage = imread(filePaths(2));
%% Image processing to prepare the picture for object recognition

% Applying the gaussian filter to make the object detection easier.
filteredImage = imgaussfilt(RBGImage, 2);

% This doesn't work because red objects will overlap with our blue
% background.
% ***********************************
% grayImage = rgb2gray(filteredImage);
% BWImage = imbinarize(grayImage); 
% ***********************************
% Instead, we can use the red channel to get a binary image like this:
RChannel = filteredImage(:, :, 1);
BWImage = RChannel < 128;
BWImage = imcomplement(BWImage);

% We are mainly interested in circular objects, thus we can use imopen to
% perform a morphological opening on the image (Same as first calling
% dilate and then erode) wit a circular structure element.
se = strel('disk', 2);
BWImage = imopen(BWImage, se);

%% Watershed alogrithm to separate objects
% Because the objects we are looking for might overlap, we want to perform
% a watershed segmentation of the picture.

% The watershed algorithm creates one region for each local minima. As we
% at the moment have a lot of noise in our picture, it will try to create
% segments around these small pixels instead of the actually objects we
% have in our picture. First we need to remove some of the noise. 
BWImage = ~bwareaopen(~BWImage, 10);
% Then we can calculate the distance transform (for binary image: The
% distance from every pixel to the closest nonzero pixel.)
distanceTransform = -bwdist(~BWImage);
% imshow(distanceTransform,[])

% Now we can use the watershed algorithm to compute the ridge lines of the
% objects.
% The watershed algorithm is used to produce segments (catchment basin).
% It contains positive integers for pixels in a segment, and 0 for the
% lines between segments. Since we then know were the lines are, we can
% at the end draw them as the background: 
% *********************
% segmentMatrix = watershed(D);
% imshow(label2rgb(segmentMatrix))
% BWImage(segmentMatrix == 0) = 0;
% imshow(BWImage);
% *********************
% The problem with this, is that the algorithm produces too many segments,
% due to a lot of local minimas. To solve this we use imextendedmin which
% is an extended-minima transformation, combining local minimas. By
% applying imimposemin on the mask we created with imextendedmin we can
% replace these local minimas with regional minimas, which will fix the
% "over-segmentation" problem.
mask = imextendedmin(distanceTransform, 4);
distanceTransformRegionalMinimas = imimposemin(distanceTransform, mask);
% Then we can apply the watershed algorithm
segmentMatrix = watershed(distanceTransformRegionalMinimas);
BWImage(segmentMatrix == 0) = 0;
imshow(RBGImage);

%% Detecting objects
% By the use of bwlabel which returns [labelMatrix = label matrix for objects found] 
% and [noOfObjects = number of objects in the matrix], we can use regionprops to get
% information about the objects found in the labelMatrix.
[labelMatrix, noOfObjects] = bwlabel(BWImage);
stats = regionprops('table', labelMatrix, 'Area', 'Centroid', 'Perimeter', 'BoundingBox', 'EulerNumber');
stats.Value = zeros(noOfObjects, 1);

stats.Circularity = ([stats.Perimeter] .^ 2) ./ (4 * pi .* [stats.Area]);

% Info we have about the coins:

Values = [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0];
CoinRadii = [58.36326667, 67.6397, 75.3049, 70.495, 79.40548, 86.05955, 82.97574];

hold on;
for i=1:noOfObjects
    bbox = table2array(stats(i, 'BoundingBox'));
    rectangle('Position', bbox);
    croppedImage = imcrop(BWImage,  table2array(stats(i, 'BoundingBox')));
    [centers, radii, metrics] = findCoins(croppedImage);
    if (isempty(centers) == 0)
        % stats.Circularity(i) = metrics(1);
        stats.Radii(i) = radii(1);
        % As the euro currencty doesn't have any coins with holes, we only
        % want to check objects without holes
        if (stats.EulerNumber(i) == 1)
            % TODO: It might be a bit overkill to check the objects for more than
            % 1 coin here, so at the moment we havent implemented a way to
            % find more than 1 coin inside an object. We will have to check
            % if its necessary with more logic here
            center = [bbox(1) + centers(1) bbox(2) + centers(2)];
            stats.Centroid(i, :) = center(:);
            viscircles(center, radii, 'Color', 'b');
            for j=1:length(CoinRadii)
                if (radii < (CoinRadii(j) + 2) & radii > (CoinRadii(j) - 2))
                   stats.Value(i) = Values(j);
                   text(center(1), center(2), num2str(Values(j)));
                   break
                end    
            end
        end
    end
    boxCenter = table2array(stats(i, 'Centroid'));
    plot(boxCenter(1), boxCenter(2), 'r+');
end
plotBoundaries(BWImage);
disp(stats);
%% Finding coins
% TODO: Determine if we can use circularity to detect coins or if we should
% continue to use Circular Hough Transform.
% As coins are the only objecttype we know, and the other objects can be of
% any type, partially visible and becuase they can overlap, we use
% the Circular Hough Transform to look for coins
function [centers, radii, metrics] = findCoins(croppedImage)
    startRadius = 50;
    endRadius = 160;
    sensitivity = 0.93;
    imshow(croppedImage);
    [centers, radii, metrics] = imfindcircles(croppedImage, [startRadius, endRadius], 'Sensitivity', sensitivity);
end

%% Finding boundaries
% Detects and draws boundaries
function boundaries = plotBoundaries(BWImage)
    hold on;
    boundaries = bwboundaries(BWImage);
    for i = 1:size(boundaries, 1)
        thisBoundary = boundaries{i};
        plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
    end
    hold off;
end


