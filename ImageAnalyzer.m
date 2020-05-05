classdef ImageAnalyzer
    %IMAGEANALYZER Summary of this class goes here
    %   A class built from project1.m, to make it easier to create a MATLAB
    %   app
    
    properties
        coinValues = [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0];
        coinRadii = [58.36326667, 67.6397, 75.3049, 70.495, 79.40548, 86.05955, 82.97574];
        defaultImages;
        noOfObjects = 0;
        RGBImage;
        BWImage;
        BWImageUnFiltered;
        selectedImagePath;
        stats;
    end
    
    methods (Access = public)
        function this = ImageAnalyzer(selectedImage)
            %IMAGEANALYZER Construct an instance of this class
            %   Detailed explanation goes here
            this.defaultImages = ["MATERIAL\database\Moedas1.jpg", "MATERIAL\database\Moedas2.jpg", "MATERIAL\database\Moedas3.jpg", "MATERIAL\database\Moedas4.jpg"];
            this.selectedImagePath = selectedImage;
            this.loadAndPreProcessImage();
            this.watershedImage();
            this.detectObjects();
        end
        %% Image processing
        function this = loadAndPreProcessImage(this)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            % Applying the gaussian filter to make the object detection easier.
            this.RGBImage = imread(this.selectedImagePath);
            filteredImage = imgaussfilt(this.RGBImage, 2);
            % This doesn't work because red objects will overlap with our blue
            % background.
            % ***********************************
            % grayImage = rgb2gray(filteredImage);
            % BWImage = imbinarize(grayImage); 
            % ***********************************
            % Instead, we can use the red channel to get a binary image like this:
            RChannel = filteredImage(:, :, 1);
            this.BWImage = RChannel < 128;
            this.BWImage = imcomplement(this.BWImage);
            % Because we want to be able to calculate the sharpness of the
            % objects, we need a picture that hasn't been filtered
            this.BWImageUnFiltered = rgb2gray(this.RGBImage);
            % We are mainly interested in circular objects, thus we can use imopen to
            % perform a morphological opening on the image (Same as first calling
            % dilate and then erode) wit a circular structure element.
            se = strel('disk', 2);
            this.BWImage = imopen(this.BWImage, se);
        end
        %% Watershed algorithm
        function this = watershedImage(this)
            % Watershed alogrithm to separate objects
            % Because the objects we are looking for might overlap, we want to perform
            % a watershed segmentation of the picture.

            % The watershed algorithm creates one region for each local minima. As we
            % at the moment have a lot of noise in our picture, it will try to create
            % segments around these small pixels instead of the actually objects we
            % have in our picture. First we need to remove some of the noise. 
            this.BWImage = ~bwareaopen(~this.BWImage, 10);
            % Then we can calculate the distance transform (for binary image: The
            % distance from every pixel to the closest nonzero pixel.)
            distanceTransform = -bwdist(~this.BWImage);
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
            this.BWImage(segmentMatrix == 0) = 0;
        end
        %% Detecting objects
        function this = detectObjects(this)
            % By the use of bwlabel which returns [labelMatrix = label matrix for objects found] 
            % and [n = number of objects in the matrix], we can use regionprops to get
            % information about the objects found in the labelMatrix.
            [labelMatrix, n] = bwlabel(this.BWImage);
            this.noOfObjects = n;
            this.stats = regionprops('table', labelMatrix, 'Area', 'Centroid', 'Perimeter', 'BoundingBox', 'EulerNumber', 'Image');
            this.stats.Value = zeros(n, 1);
            this.stats.Circularity = ([this.stats.Perimeter] .^ 2) ./ (4 * pi .* [this.stats.Area]);
            
            hold on;
            for i=1:this.noOfObjects
                bbox = table2array(this.stats(i, 'BoundingBox'));
                rectangle('Position', bbox);
                croppedBWImage = imcrop(this.BWImage,  table2array(this.stats(i, 'BoundingBox')));
                croppedRGBImage = imcrop(this.RGBImage, table2array(this.stats(i, 'BoundingBox')));
                croppedBWImageUnFiltered = imcrop(this.BWImage,  table2array(this.stats(i, 'BoundingBox')));
                this.stats.Sharpness(i) = this.computeSharpness(croppedBWImageUnFiltered);
                croppedRGBImage(size(croppedRGBImage,1),:,:) = [];
                croppedRGBImage(:,size(croppedRGBImage,2), :) = [];
                % cell2mat(croppedRGBImage);
                % this.stats.Image(i) = bsxfun(@times, croppedRGBImage, cast(A, 'like', croppedRGBImage));
                this.stats.ObjectID(i) = i;
                this.stats.Distance(i) = -1;
                [centers, radii, metrics] = this.findCoins(croppedBWImage);
                if (isempty(centers) == 0)
                    % stats.Circularity(i) = metrics(1);
                    this.stats.Radii(i) = radii(1);
                    % As the euro currencty doesn't have any coins with holes, we only
                    % want to check objects without holes
                    if (this.stats.EulerNumber(i) == 1)
                        % TODO: It might be a bit overkill to check the objects for more than
                        % 1 coin here, so at the moment we havent implemented a way to
                        % find more than 1 coin inside an object. We will have to check
                        % if its necessary with more logic here
                        center = [bbox(1) + centers(1) bbox(2) + centers(2)];
                        this.stats.Centroid(i, :) = center(:);
                        for j=1:length(this.coinRadii)
                            if (radii < (this.coinRadii(j) + 2) & radii > (this.coinRadii(j) - 2))
                               this.stats.Value(i) = this.coinValues(j);
                               break
                            end    
                        end
                    end
                end
                boxCenter = table2array(this.stats(i, 'Centroid'));
                plot(boxCenter(1), boxCenter(2), 'r+');
            end
            % this.plotBoundaries(this.BWImage);
            disp(this.stats);
        end
        %% Finding coins
        function [centers, radii, metrics] = findCoins(this, croppedBWImage)
            % TODO: Determine if we can use circularity to detect coins or if we should
            % continue to use Circular Hough Transform.
            % As coins are the only objecttype we know, and the other objects can be of
            % any type, partially visible and becuase they can overlap, we use
            % the Circular Hough Transform to look for coins
            startRadius = 50;
            endRadius = 160;
            sensitivity = 0.93;
            [centers, radii, metrics] = imfindcircles(croppedBWImage, [startRadius, endRadius], 'Sensitivity', sensitivity);
        end
        %% Compute sharpness
        % Uses the gradient to compute the sharpness of the cropped image
        function [sharpness] = computeSharpness(this, croppedBWImageUnfiltered)
            [gradientX, gradientY] = gradient(croppedBWImageUnfiltered);
            S = sqrt(gradientX.*gradientX+gradientY.*gradientY);
            sharpness = sum(sum(S))./(numel(gradientX));
            disp(sharpness);
        end
        %% Finding boundaries
        function boundaries = getBoundaries(this)
            boundaries = bwboundaries(this.BWImage);
        end
        %% Finding object from position
        function [area, centroid, bbox, perimeter, value, circularity, radii, sharpness, objectID] = getSelectedObject(this, position)
            x = position(1, 1);
            y = position(1, 2);
            for i=1:this.noOfObjects
                if (x > this.stats.BoundingBox(i, 1) && x < (this.stats.BoundingBox(i, 1) + this.stats.BoundingBox(i, 3))...
                    && y > this.stats.BoundingBox(i, 2) && y < (this.stats.BoundingBox(i, 2) + this.stats.BoundingBox(i, 4)))  
                    area = this.stats.Area(i);
                    centroid = this.stats.Centroid(i, :);
                    bbox = this.stats.BoundingBox(i, :);
                    value = this.stats.Value(i);
                    circularity = this.stats.Circularity(i, :);
                    radii = this.stats.Radii(i);
                    perimeter = this.stats.Perimeter(i);
                    sharpness = this.stats.Sharpness(i);
                    objectID = this.stats.ObjectID(i);
                    return;
                end
            end
            area = 0;
            centroid = 0;
            bbox = 0;
            value = 0;
            circularity = 0;
            radii = 0;
            perimeter = 0;
            sharpness = 0;
            objectID = 0;
        end
        %% Update distances to selected object
        function this = updateDistanceToSelectedObject(this, selectedID)
            if (selectedID > 0)
            rows = this.stats.ObjectID == selectedID;
            absoluteObject = this.stats(rows, :);
            for i=1:this.noOfObjects
                if (this.stats.ObjectID(i) ~= absoluteObject.ObjectID(1))
                    this.stats.Distance(i) = pdist([this.stats.Centroid(i, 1), this.stats.Centroid(i, 2); absoluteObject.Centroid(1, 1), absoluteObject.Centroid(1, 2)], 'euclidean');
                else
                    this.stats.Distance(i) = -1;
                end
            end
            else
                for i=1:this.noOfObjects
                    this.stats.Distance(i) = -1;
                end
            end
        end
        %% Sort the stats based on row name
        function this = sortStats(this, value)
            sortRows(this.stats, value);
        end
    end
end

