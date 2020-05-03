clear variables, close all

%% Let user choose image
% Choose you want to use a training image from local repos or a test image
% imgFrom = questdlg('Choose if you want to use a local (training) image or a remote test image by path', ...
%     'Image origin', 'Local (training)', 'Remote (test)', 'Exit');
% name = inputdlg('Type image name');
% path = '';
% if strcmp(imgFrom, 'Local (training)') == 1
%     path = 'MATERIAL/database/';
% end
% 
% img = imread(strcat(path, name{1}));
img = imread('MATERIAL/database/Moedas4.jpg');

%% Process image 
img_gauss = imgaussfilt(img, 3);
binary = imbinarize(img_gauss(:,:,1), 0.5);
se = strel('disk', 2);
imgTemp = imdilate(binary, se);

imshow(imgTemp);

% Collisions
D = -bwdist(~imgTemp);
WS = watershed(D);
mask = imextendedmin(D,3);
D2 = imimposemin(D, mask);
WS2 = watershed(D2);
processedImg = imgTemp;
processedImg(WS2 == 0) = 0;

imshow(processedImg);
%% Detect image objects
[lb, num] = bwlabel(processedImg);

%% Get stats from image
stats = regionprops(lb, 'Centroid', 'Perimeter', 'Area', 'BoundingBox');

% Number of objects
objectCount = size(stats,1);
disp(objectCount);

%% Count coins
circularity = ([stats.Perimeter] .^ 2) ./ (4 * pi .* [stats.Area]);
C = num2cell(circularity .');
[stats.Circularity] = C{:};

count = 0;

for i = 1:length(objectCount)
    if (circularity(i) < 1.01)
        count = count + 1;
    end
end
disp(count);

%% Sharpness of the objects
boundaries = bwboundaries(processedImg, 'holes');
sharpness = [];

for i = 1:num
    deltaSq = diff(boundaries{i}).^2;
    perimeter = sum(sqrt(sum(deltaSq, 2)));
    area = stats(i).Area;
    objectSharpness = 1 - 4*pi*area/perimeter^2;
    sharpness = [sharpness objectSharpness];
end

C = num2cell(sharpness)
[stats.Sharpness] = C{:}

%% Table from stats
statsTable = struct2table(stats);
statsTable.ObjectNumber = zeros(objectCount, 1);
statsTable.ObjectNumber(:) = 1:objectCount;

% Table as figure
colnames= {'Area', 'Centroid x', 'Centroid y', 'BoundingBox x', ...
    'BoundingBox y', 'BoundingBox width', 'BoundingBox height', ...
    'Perimeter', 'Circularity', 'Sharpness', 'Object'};
t = uitable('Data', statsTable{:,:}, 'ColumnName', colnames, 'RowName', ...
    statsTable.Properties.RowNames, 'Units', 'Normalized', 'Position', ...
    [0, 0, 1, 1]);

%% Visualize centroid and draw object number on figure, also calculate distance
distance = NaN(objectCount, objectCount);

figure;
imshow(label2rgb(lb));

hold on;
for i = 1:num
    % Draw point and object number
    plot(stats(i).Centroid(1), stats(i).Centroid(2), 'k.', 'markersize', 20);
    text(stats(i).Centroid(1), stats(i).Centroid(2)-20, int2str(i));
    
    % Calculate relative distance
    distance(1, i) = i;
    distance(i, i) = 0;
    for j = i+1:num
        X = [stats(i).Centroid(1),stats(i).Centroid(2); stats(j).Centroid(1),stats(j).Centroid(2)];
        distance(j, i) = pdist(X, 'euclidean');
    end
    drawnow;
end
hold off;

%% Visualize perimeter of objects
figure; 
imshow(img);
title('Perimeters');

hold on;
boundaries = bwboundaries(processedImg);
for i = 1:size(boundaries, 1)
	thisBoundary = boundaries{i};
	plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
end
hold off;

%% Draw individual objects and order them
%orderBy = questdlg('Order individual objects by:', 'Ordering',...
%    'Perimeter', 'Area', 'Circularity', 'Exit');
choice = menu('Order individual objects by:',...
    'Perimeter', 'Area', 'Circularity', 'Sharpness');
choices = ["Perimeter", "Area", "Circularity", "Sharpness"];
orderBy = char(choices(choice));

drawIndividualObjectsByOrdering(img, statsTable, stats, orderBy,...
    objectCount);

%% Relative distance
figure; 
imshow(img);
title('Select an object to see distance to other objects');
hold on;
[x,y] = ginput(1);
for i = 1:objectCount
    if (x > stats(i).BoundingBox(1)) &&...
            (x < (stats(i).BoundingBox(1) + stats(i).BoundingBox(3)))
        if (y > stats(i).BoundingBox(2)) &&...
                (y < (stats(i).BoundingBox(2) + stats(i).BoundingBox(4)))
           for j = 1:objectCount
               if i < j
                    txt = ['d = ' num2str(distance(j, i))];
               else
                    txt = ['d = ' num2str(distance(i, j))];  
               end
               text(stats(j).Centroid(1)-40,stats(j).Centroid(2)-20,...
                   txt, 'Color', 'white', 'BackgroundColor', 'black');
               plot([stats(i).Centroid(1) stats(j).Centroid(1)],...
                   [stats(i).Centroid(2) stats(j).Centroid(2)], '-');
            end
        end
    end
end
hold off;


%-------------------------------------------------------------------------%


function drawIndividualObjectsByOrdering(img, table, stats,...
    orderBy, objectCount)
    orderedTable = sortrows(table, orderBy);
    figure;
    for k = 1:objectCount
        objIndex = orderedTable.ObjectNumber(k);
        property = getfield(stats, {objIndex}, orderBy);
        bbox = stats(objIndex).BoundingBox;
        subImage = imcrop(img, bbox);
        subplot(3,4,k);
        imshow(subImage);
        title([orderBy ' = ' num2str(property)]);
        text(bbox(3)/2-25, bbox(4)+15, ['Object #' num2str(objIndex)]);
    end
end

