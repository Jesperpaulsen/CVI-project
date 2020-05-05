classdef app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        LoadcustomimageButton          matlab.ui.control.Button
        PredefinedImagesDropDownLabel  matlab.ui.control.Label
        PredefinedImagesDropDown       matlab.ui.control.DropDown
        Label                          matlab.ui.control.Label
        TextArea_6Label                matlab.ui.control.Label
        ShowboundariesCheckBox         matlab.ui.control.CheckBox
        ShowareaCheckBox               matlab.ui.control.CheckBox
        ShowcenterCheckBox             matlab.ui.control.CheckBox
        UIAxes                         matlab.ui.control.UIAxes
        ShowdetectedcoinsCheckBox      matlab.ui.control.CheckBox
        DetailsTextArea                matlab.ui.control.TextArea
        ClickonanobjecttoseedetailsaboutitLabel  matlab.ui.control.Label
        TabGroup                       matlab.ui.container.TabGroup
        OrderTab                       matlab.ui.container.Tab
        UIAxes1                        matlab.ui.control.UIAxes
        OrderobjectsbyDropDownLabel    matlab.ui.control.Label
        OrderobjectsbyDropDown         matlab.ui.control.DropDown
        UIAxes2                        matlab.ui.control.UIAxes
        UIAxes3                        matlab.ui.control.UIAxes
        UIAxes4                        matlab.ui.control.UIAxes
        UIAxes5                        matlab.ui.control.UIAxes
        UIAxes6                        matlab.ui.control.UIAxes
        UIAxes7                        matlab.ui.control.UIAxes
        UIAxes8                        matlab.ui.control.UIAxes
        TransformationTab              matlab.ui.container.Tab
        UIAxes2_9                      matlab.ui.control.UIAxes
        UIAxes2_10                     matlab.ui.control.UIAxes
        UIAxes2_11                     matlab.ui.control.UIAxes
        UIAxes2_12                     matlab.ui.control.UIAxes
        UIAxes2_13                     matlab.ui.control.UIAxes
        UIAxes2_14                     matlab.ui.control.UIAxes
        UIAxes2_15                     matlab.ui.control.UIAxes
        UIAxes2_16                     matlab.ui.control.UIAxes
        Table                          matlab.ui.container.Tab
        UITable                        matlab.ui.control.Table
        ShowdistanceCheckBox           matlab.ui.control.CheckBox
    end

    properties (Access = public)
        IA % The ImageAnalyzerClass
        im % The current image
        imPlot % Holds the image plot
        boundaryPlot % Holds the boundary plot
        areaPlot % holds the area plot
        centerPlot % Holds the center plot
        coinPlot % Holds the coin plot
        distancePlot % Holds the distance plots
        distanceText % Holds the distance text
        selectedObjectID % Holds ID to the last selected object
        sortedImageAxis % Axis to display sorted images
        objectPlot % Holds the box plot around the selected object
    end    
    methods (Access = private)
        function initalizeImageAnalyzer(app, pathToImage)
            app.IA = ImageAnalyzer(pathToImage);
            app.IA = app.IA.loadAndPreProcessImage();
            app.IA = app.IA.watershedImage();
            app.IA = app.IA.detectObjects();
            axis(app.UIAxes, 'image');
            app.im = imread(pathToImage);
            app.imPlot = imagesc(app.UIAxes, app.im, 'Tag', 'objectsImage');
            app.drawObejctID();
            app.loadTableData();
        end
        
        function deleteImPlot(app)
            app.ShowareaCheckBox.Value = 0;
            % app.drawArea(0);
            app.ShowboundariesCheckBox.Value = 0;
            % app.drawBoundaries(0);
            app.ShowcenterCheckBox.Value = 0;
            % app.drawCenter(0);
            app.ShowdetectedcoinsCheckBox.Value = 0;
            delete(app.objectPlot);
            delete(app.imPlot);
        end
        
        function drawArea(app, value)
            if (value == 1)
                boundaries = app.IA.getBoundaries();
                hold(app.UIAxes, "on");
                for i = 1:size(boundaries, 1)
                	thisBoundary = boundaries{i};
                	app.areaPlot(i, 1) = fill(app.UIAxes, thisBoundary(:,2), thisBoundary(:,1), [0.7 0.8 1]);
                end
                app.drawObejctID();
                hold(app.UIAxes, "off");
                if (app.ShowboundariesCheckBox.Value == 1)
                    app.drawBoundaries(0);
                    app.drawBoundaries(1);
                end
                if (app.ShowcenterCheckBox.Value == 1)
                    app.drawCenter(0);
                    app.drawCenter(1);
                end
                if (app.ShowdetectedcoinsCheckBox.Value == 1)
                    app.drawCoins(0);
                    app.drawCoins(1);
                end
                if (app.ShowdistanceCheckBox.Value == 1 && app.ShowdistanceCheckBox.Visible)
                    app.drawDistanceIndicators(0);
                    app.drawDistanceIndicators(1);
                end
            else
                hold(app.UIAxes, "on");
                for i = 1:size(app.areaPlot, 1)
                    try
                        delete(app.areaPlot(i));
                    catch ME
                        disp('Unable to delete areaplot');
                    end
                end
                hold(app.UIAxes, "off");
            end
        end
        
        function drawBoundaries(app, value)
            if (value == 1)
                boundaries = app.IA.getBoundaries();
                hold(app.UIAxes, "on");
                for i = 1:size(boundaries, 1)
                	thisBoundary = boundaries{i};
                	app.boundaryPlot(i, 1) = plot(app.UIAxes, thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
                end
                hold(app.UIAxes, "off");
            else
                hold(app.UIAxes, "on");
                for i = 1:size(app.boundaryPlot, 1)
                    try
                      delete(app.boundaryPlot(i));
                    catch ME
                       disp('Unable to delete boundaryplot');
                    end
                end
                hold(app.UIAxes, "off");
            end
        end
        
        function drawCenter(app, value)
            if (value == 1)
                hold(app.UIAxes, "on");
                for i = 1:app.IA.noOfObjects
                    boxCenter = table2array(app.IA.stats(i, 'Centroid'));
                    app.centerPlot(i, 1) = plot(app.UIAxes, boxCenter(1), boxCenter(2), 'r+');
                end
                hold(app.UIAxes, "off");
            else
                hold(app.UIAxes, "on");
                for i = 1:app.IA.noOfObjects
                    try
                        delete(app.centerPlot(i));
                    catch ME
                        disp('Unable to delete centerplot');
                    end
                end
                hold(app.UIAxes, "off");
            end
        end
        
        function drawCoins(app, value)
            if (value == 1)
                hold(app.UIAxes, "on");
                for i = 1:app.IA.noOfObjects
                    coinValue = table2array(app.IA.stats(i, 'Value'));
                    if (coinValue > 0)
                        theta = linspace(0, 2*pi, 100);
                        x = app.IA.stats.Centroid(i, 1) + app.IA.stats.Radii(i, 1) * cos(theta);
                        y = app.IA.stats.Centroid(i, 2) + app.IA.stats.Radii(i, 1) * sin(theta);
                        app.coinPlot(i, 1) = plot(app.UIAxes, x, y, 'b', 'LineWidth', 2);
                    end
                end
                hold(app.UIAxes, "off");
            else
                hold(app.UIAxes, "on");
                for i = 1:app.IA.noOfObjects
                    try
                        delete(app.coinPlot(i));
                    catch ME
                        disp('Unable to delete coin plot');
                    end
                end
                hold(app.UIAxes, "off");
            end
        end
        function drawObejctID(app)
            for i=1:app.IA.noOfObjects
                text(app.UIAxes, app.IA.stats.BoundingBox(i, 1) + 20, app.IA.stats.BoundingBox(i, 2) + 40, "# " + app.IA.stats.ObjectID(i) + "");
            end
        end
        function drawDistanceIndicators(app, value)
            if (value == 1)
                rows = app.IA.stats.ObjectID == app.selectedObjectID;
                colors = ['c', 'm', 'r', 'g', 'b'];
                absoluteObject = app.IA.stats(rows, :);
                hold(app.UIAxes, "on");
                
                for i=1:app.IA.noOfObjects
                    if(app.IA.stats.Distance(i) > 0)
                        no = randi([1 5]);
                        color = colors(no);
                        app.distancePlot(i, 1) = plot(app.UIAxes, [app.IA.stats.Centroid(i, 1) absoluteObject.Centroid(1,1)], [app.IA.stats.Centroid(i, 2) absoluteObject.Centroid(1,2)], '-', 'Color', color);
                        textX = (app.IA.stats.Centroid(i, 1) + absoluteObject.Centroid(1,1)).'/2;
                        textY = (app.IA.stats.Centroid(i, 2) + absoluteObject.Centroid(1,2)).'/2;
                        app.distanceText(i, 1) = text(app.UIAxes, textX, textY, "O" + app.IA.stats.ObjectID(i) + ": " + num2str(round(app.IA.stats.Distance(i))), 'Color', color);
                    else
                        try
                            delete(app.distancePlot(i));
                            delete(app.distanceText(i));
                        catch ME
                            disp('Unable to delete distance text/plot');
                        end
                    end
                end
                hold(app.UIAxes, "off");
            else
                for i=1:app.IA.noOfObjects
                    try
                        delete(app.distancePlot(i));
                        delete(app.distanceText(i));
                    catch ME
                        disp('Unable to delete distance text/plot');
                    end
                end
            end
        end
        function handleFigureClick(app)
            [area, centroid, bbox, perimeter, value, circularity, radii, sharpness, objectID] = app.IA.getSelectedObject(app.UIAxes.CurrentPoint);
            app.selectedObjectID = objectID;
            if (area > 0)
                try
                    delete(app.objectPlot);
                catch ME
                    disp("Unable to delete objectplot");
                end
                app.IA = app.IA.updateDistanceToSelectedObject(objectID);
                app.ShowdistanceCheckBox.Visible = 1;
                if (app.ShowdistanceCheckBox.Value == 1)
                   app.drawDistanceIndicators(0);
                   app.drawDistanceIndicators(1); 
                end
                string =  "Area: " + num2str(area) +...
                    newline + "Perimeter: " + num2str(perimeter) +...
                    newline + "Center: (" + num2str(round(centroid(1))) + ", " + num2str(round(centroid(2))) + ")" + ...
                    newline + "Sharpness: " + num2str(sharpness) +...
                    newline + "Circularity: " + num2str(circularity) + "";
                if (radii > 0)
                   string = string + newline + "Radii: " + num2str(radii) + ""; 
                end
                if (value > 0)
                    switch value
                        case 0.01
                            strValue = "1 cent";
                        case 0.02
                            strValue = "2 cent";
                        case 0.05
                            strValue = "5 cent";
                        case 0.1
                            strValue = "10 cent";
                        case 0.2
                            strValue = "20 cent";
                        case 0.5
                            strValue = "50 cent";
                        case 1.0
                            strValue = "1 euro";
                        otherwise
                            strValue = "";
                            disp("Value was greather than 0, but not recognized");
                    end
                    string = string + newline + "Value: " + strValue + ".";
                end
            app.DetailsTextArea.Value = string;
            app.objectPlot = rectangle(app.UIAxes, "Position", bbox, "EdgeColor","y", "LineWidth", 2);
            else
                delete(app.objectPlot);
                app.selectedObjectID = -1;
                app.DetailsTextArea.Value = "Object not chosen";
                app.IA = app.IA.updateDistanceToSelectedObject(-1);
                app.ShowdistanceCheckBox.Visible = 0;
                app.drawDistanceIndicators(0);  
            end
        end
        function loadTableData(app)
            app.UITable.Data = table(app.IA.stats.ObjectID, app.IA.stats.Area,...
               app.IA.stats.Centroid, app.IA.stats.Perimeter,...
               app.IA.stats.Value, app.IA.stats.Circularity, app.IA.stats.Sharpness,...
               app.IA.stats.Radii);
        end
        function updateSortedImages(app, value)
            switch value
                case "Area"
                    app.IA = app.IA.sortStats("Area");
                case "Perimeter"
                    app.IA = app.IA.sortStats("Perimeter");
                case "Sharpness"
                    app.IA = app.IA.sortStats("Sharpness");
                case "Distance from selected object"
                    app.IA = app.IA.sortStats("Distance");
                otherwise
                    app.IA = app.IA.sortStats("ObjectID");
            end
            limit = max(app.IA.noOfObjects, 8);
            for i=1:limit
                imagesc(app.sortedImageAxis(i), app.IA.stats.Image(i));
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.initalizeImageAnalyzer(app.PredefinedImagesDropDown.Value);
            app.sortedImageAxis = [app.UIAxes1, app.UIAxes2, app.UIAxes3, app.UIAxes4, app.UIAxes5,...
                app.UIAxes6, app.UIAxes7, app.UIAxes8];
        end

        % Value changed function: ShowboundariesCheckBox
        function ShowboundariesCheckBoxValueChanged(app, event)
            value = app.ShowboundariesCheckBox.Value;
            app.drawBoundaries(value);
        end

        % Value changed function: ShowareaCheckBox
        function ShowareaCheckBoxValueChanged(app, event)
            value = app.ShowareaCheckBox.Value;
            app.drawArea(value);
        end

        % Value changed function: ShowcenterCheckBox
        function ShowcenterCheckBoxValueChanged(app, event)
            value = app.ShowcenterCheckBox.Value;
            app.drawCenter(value);
        end

        % Value changed function: PredefinedImagesDropDown
        function PredefinedImagesDropDownValueChanged(app, event)
            value = app.PredefinedImagesDropDown.Value;
            try
                app.deleteImPlot();
            catch ME
                disp(ME);
            end
            app.initalizeImageAnalyzer(value);
        end

        % Value changed function: ShowdetectedcoinsCheckBox
        function ShowdetectedcoinsCheckBoxValueChanged(app, event)
            value = app.ShowdetectedcoinsCheckBox.Value;
            app.drawCoins(value);
        end

        % Window button down function: UIFigure
        function UIFigureWindowButtonDown(app, event)
          if ~isempty(event.Source.CurrentObject) && isequal(event.Source.CurrentObject.Tag,'objectsImage')
              app.handleFigureClick();
          end
        end

        % Button pushed function: LoadcustomimageButton
        function LoadcustomimageButtonPushed(app, event)
            filterspec = {'*.jpg'};
            [f, p] = uigetfile(filterspec);
            if (ischar(p))
                try
                    app.deleteImPlot();
                catch ME
                    disp(ME);
                end
                fname = [p f];
                disp(fname);
                app.initalizeImageAnalyzer(fname);
            end
        end

        % Value changed function: ShowdistanceCheckBox
        function ShowdistanceCheckBoxValueChanged(app, event)
            value = app.ShowdistanceCheckBox.Value;
            app.drawDistanceIndicators(value);
        end

        % Value changed function: OrderobjectsbyDropDown
        function OrderobjectsbyDropDownValueChanged(app, event)
            value = app.OrderobjectsbyDropDown.Value;
            app.updateSortedImages(value);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 817 851];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.WindowButtonDownFcn = createCallbackFcn(app, @UIFigureWindowButtonDown, true);

            % Create LoadcustomimageButton
            app.LoadcustomimageButton = uibutton(app.UIFigure, 'push');
            app.LoadcustomimageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadcustomimageButtonPushed, true);
            app.LoadcustomimageButton.Position = [246 490 120 22];
            app.LoadcustomimageButton.Text = 'Load custom image';

            % Create PredefinedImagesDropDownLabel
            app.PredefinedImagesDropDownLabel = uilabel(app.UIFigure);
            app.PredefinedImagesDropDownLabel.HorizontalAlignment = 'right';
            app.PredefinedImagesDropDownLabel.Position = [16 490 106 22];
            app.PredefinedImagesDropDownLabel.Text = 'Predefined Images';

            % Create PredefinedImagesDropDown
            app.PredefinedImagesDropDown = uidropdown(app.UIFigure);
            app.PredefinedImagesDropDown.Items = {'Moedas 1', 'Moedas 2', 'Moedas 3', 'Moedas 4'};
            app.PredefinedImagesDropDown.ItemsData = {'MATERIAL\database\Moedas1.jpg ', 'MATERIAL\database\Moedas2.jpg ', 'MATERIAL\database\Moedas3.jpg ', 'MATERIAL\database\Moedas4.jpg'};
            app.PredefinedImagesDropDown.ValueChangedFcn = createCallbackFcn(app, @PredefinedImagesDropDownValueChanged, true);
            app.PredefinedImagesDropDown.Position = [137 490 100 22];
            app.PredefinedImagesDropDown.Value = 'MATERIAL\database\Moedas1.jpg ';

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [1 315 25 22];
            app.Label.Text = '';

            % Create TextArea_6Label
            app.TextArea_6Label = uilabel(app.UIFigure);
            app.TextArea_6Label.HorizontalAlignment = 'right';
            app.TextArea_6Label.Position = [147 72 25 22];
            app.TextArea_6Label.Text = '';

            % Create ShowboundariesCheckBox
            app.ShowboundariesCheckBox = uicheckbox(app.UIFigure);
            app.ShowboundariesCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowboundariesCheckBoxValueChanged, true);
            app.ShowboundariesCheckBox.Text = 'Show boundaries';
            app.ShowboundariesCheckBox.Position = [663 778 115 22];

            % Create ShowareaCheckBox
            app.ShowareaCheckBox = uicheckbox(app.UIFigure);
            app.ShowareaCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowareaCheckBoxValueChanged, true);
            app.ShowareaCheckBox.Text = 'Show area';
            app.ShowareaCheckBox.Position = [663 747 79 22];

            % Create ShowcenterCheckBox
            app.ShowcenterCheckBox = uicheckbox(app.UIFigure);
            app.ShowcenterCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowcenterCheckBoxValueChanged, true);
            app.ShowcenterCheckBox.Text = 'Show center';
            app.ShowcenterCheckBox.Position = [663 718 89 22];

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, '')
            xlabel(app.UIAxes, '')
            ylabel(app.UIAxes, '')
            app.UIAxes.Position = [200 537 456 303];

            % Create ShowdetectedcoinsCheckBox
            app.ShowdetectedcoinsCheckBox = uicheckbox(app.UIFigure);
            app.ShowdetectedcoinsCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowdetectedcoinsCheckBoxValueChanged, true);
            app.ShowdetectedcoinsCheckBox.Text = 'Show detected coins';
            app.ShowdetectedcoinsCheckBox.Position = [663 687 133 22];

            % Create DetailsTextArea
            app.DetailsTextArea = uitextarea(app.UIFigure);
            app.DetailsTextArea.Editable = 'off';
            app.DetailsTextArea.Position = [28 599 187 172];
            app.DetailsTextArea.Value = {'Object not chosen'};

            % Create ClickonanobjecttoseedetailsaboutitLabel
            app.ClickonanobjecttoseedetailsaboutitLabel = uilabel(app.UIFigure);
            app.ClickonanobjecttoseedetailsaboutitLabel.HorizontalAlignment = 'center';
            app.ClickonanobjecttoseedetailsaboutitLabel.Position = [35 778 174 28];
            app.ClickonanobjecttoseedetailsaboutitLabel.Text = {'Click on an object to see details'; 'about it'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [16 27 780 421];

            % Create OrderTab
            app.OrderTab = uitab(app.TabGroup);
            app.OrderTab.Title = 'Order';

            % Create UIAxes1
            app.UIAxes1 = uiaxes(app.OrderTab);
            title(app.UIAxes1, '')
            xlabel(app.UIAxes1, '')
            ylabel(app.UIAxes1, '')
            app.UIAxes1.Position = [15 222 189 130];

            % Create OrderobjectsbyDropDownLabel
            app.OrderobjectsbyDropDownLabel = uilabel(app.OrderTab);
            app.OrderobjectsbyDropDownLabel.HorizontalAlignment = 'right';
            app.OrderobjectsbyDropDownLabel.Position = [12 363 94 22];
            app.OrderobjectsbyDropDownLabel.Text = 'Order objects by';

            % Create OrderobjectsbyDropDown
            app.OrderobjectsbyDropDown = uidropdown(app.OrderTab);
            app.OrderobjectsbyDropDown.Items = {'Area', 'Perimeter', 'Sharpness', 'Similarity to selected object', 'Distance from selected object'};
            app.OrderobjectsbyDropDown.ValueChangedFcn = createCallbackFcn(app, @OrderobjectsbyDropDownValueChanged, true);
            app.OrderobjectsbyDropDown.Position = [117 363 255 22];
            app.OrderobjectsbyDropDown.Value = 'Area';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.OrderTab);
            title(app.UIAxes2, '')
            xlabel(app.UIAxes2, '')
            ylabel(app.UIAxes2, '')
            app.UIAxes2.Position = [203 222 189 130];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.OrderTab);
            title(app.UIAxes3, '')
            xlabel(app.UIAxes3, '')
            ylabel(app.UIAxes3, '')
            app.UIAxes3.Position = [391 222 189 130];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.OrderTab);
            title(app.UIAxes4, '')
            xlabel(app.UIAxes4, '')
            ylabel(app.UIAxes4, '')
            app.UIAxes4.Position = [579 222 189 130];

            % Create UIAxes5
            app.UIAxes5 = uiaxes(app.OrderTab);
            title(app.UIAxes5, '')
            xlabel(app.UIAxes5, '')
            ylabel(app.UIAxes5, '')
            app.UIAxes5.Position = [15 66 189 130];

            % Create UIAxes6
            app.UIAxes6 = uiaxes(app.OrderTab);
            title(app.UIAxes6, '')
            xlabel(app.UIAxes6, '')
            ylabel(app.UIAxes6, '')
            app.UIAxes6.Position = [203 66 189 130];

            % Create UIAxes7
            app.UIAxes7 = uiaxes(app.OrderTab);
            title(app.UIAxes7, '')
            xlabel(app.UIAxes7, '')
            ylabel(app.UIAxes7, '')
            app.UIAxes7.Position = [391 66 189 130];

            % Create UIAxes8
            app.UIAxes8 = uiaxes(app.OrderTab);
            title(app.UIAxes8, '')
            xlabel(app.UIAxes8, '')
            ylabel(app.UIAxes8, '')
            app.UIAxes8.Position = [579 66 189 130];

            % Create TransformationTab
            app.TransformationTab = uitab(app.TabGroup);
            app.TransformationTab.Title = 'Transformation';

            % Create UIAxes2_9
            app.UIAxes2_9 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_9, '')
            xlabel(app.UIAxes2_9, '')
            ylabel(app.UIAxes2_9, '')
            app.UIAxes2_9.Position = [15 222 189 130];

            % Create UIAxes2_10
            app.UIAxes2_10 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_10, '')
            xlabel(app.UIAxes2_10, '')
            ylabel(app.UIAxes2_10, '')
            app.UIAxes2_10.Position = [203 222 189 130];

            % Create UIAxes2_11
            app.UIAxes2_11 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_11, '')
            xlabel(app.UIAxes2_11, '')
            ylabel(app.UIAxes2_11, '')
            app.UIAxes2_11.Position = [391 222 189 130];

            % Create UIAxes2_12
            app.UIAxes2_12 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_12, '')
            xlabel(app.UIAxes2_12, '')
            ylabel(app.UIAxes2_12, '')
            app.UIAxes2_12.Position = [579 222 189 130];

            % Create UIAxes2_13
            app.UIAxes2_13 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_13, '')
            xlabel(app.UIAxes2_13, '')
            ylabel(app.UIAxes2_13, '')
            app.UIAxes2_13.Position = [15 66 189 130];

            % Create UIAxes2_14
            app.UIAxes2_14 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_14, '')
            xlabel(app.UIAxes2_14, '')
            ylabel(app.UIAxes2_14, '')
            app.UIAxes2_14.Position = [203 66 189 130];

            % Create UIAxes2_15
            app.UIAxes2_15 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_15, '')
            xlabel(app.UIAxes2_15, '')
            ylabel(app.UIAxes2_15, '')
            app.UIAxes2_15.Position = [391 66 189 130];

            % Create UIAxes2_16
            app.UIAxes2_16 = uiaxes(app.TransformationTab);
            title(app.UIAxes2_16, '')
            xlabel(app.UIAxes2_16, '')
            ylabel(app.UIAxes2_16, '')
            app.UIAxes2_16.Position = [579 66 189 130];

            % Create Table
            app.Table = uitab(app.TabGroup);
            app.Table.Title = 'Table';

            % Create UITable
            app.UITable = uitable(app.Table);
            app.UITable.ColumnName = {'ID'; 'Area'; 'Centroid'; 'Perimeter'; 'Value'; 'Circularity'; 'Sharpness'; 'Radii'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.Position = [0 19 779 345];

            % Create ShowdistanceCheckBox
            app.ShowdistanceCheckBox = uicheckbox(app.UIFigure);
            app.ShowdistanceCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowdistanceCheckBoxValueChanged, true);
            app.ShowdistanceCheckBox.Visible = 'off';
            app.ShowdistanceCheckBox.Text = 'Show distance';
            app.ShowdistanceCheckBox.Position = [664 654 100 22];
            app.ShowdistanceCheckBox.Value = true;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end