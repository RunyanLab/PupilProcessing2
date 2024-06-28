function [selectedThreshold,selectedBlink,selectedScope,selectedOrient,selectedRightPercentile,selectedTopPercentile,selectedUnit,...
    selectedConversion,selectedAlign,selectedFace,selectedKmeans,selectedDilCon]...
    = createSettingsGUI(exp_obj,frame_id,cornMask,eyeMask,eyeEllipse)
%% 
the_example_image = read(exp_obj,frame_id);

%% default parameters
selectedThreshold = .7;
selectedBlink = .1;
selectedScope = 'Inv';
selectedOrient = 90;
selectedRightPercentile = 60;
selectedTopPercentile = 100;
selectedUnit = 'mm^2';
selectedConversion = .0136;
selectedAlign = 'rough';
selectedFace = 0;
selectedKmeans = 0;
selectedDilCon =0;



% create the gui figure
uiFigure = figure('Name','Processing Settings','Position',[250 293 776 447]);
%% processing parameters 
procLabel = uicontrol('Style','text','Position',[140,370,190,50],'String','Processing Parameters','FontSize',11);
analysisLabel = uicontrol('Style','text','Position',[450,370,150,50],'String','Elective Analyses','FontSize',11);

%blink threshold input 
blinkLabel = uicontrol('Style','text','String','Blink Threshold:','Position',[30,340,150,20],'FontSize',9.5);
blinkEdit = uicontrol('Style','edit','Position',[170,340,80,20],'Callback',@blinkCallbackFxn);
 
% % scope - select one 
% scopeLabel = uicontrol('Style','text','String','Scope/Rig:','Position',[30,310,150,20],'FontSize',9.5,'Callback',@scopesCallbackFxn);
% scopes = {'2P+','Investigator','Training rig'};
% scopeDrop = uicontrol('Style','popupmenu','Position',[170,280,100,50],'String',scopes,'Callback',@scopesCallbackFxn);

% orientation
orientLabel = uicontrol('Style','text','String','Orientation:','Position',[30,310,150,20],'FontSize',9.5);
orients = {'90', '0'};
orientDrop = uicontrol('Style','popupmenu','Position',[170,310,50,20],'String',orients,'Callback',@orientCallbackFxn);

%unit 
unitLabel = uicontrol('Style','text','String','Unit:','Position',[30,280,50,20],'FontSize',9.5);
units = {'mm^2', 'pix^2'};
unitDrop = uicontrol('Style','popupmenu','Position',[170,280,50,20],'String',units,'Callback',@unitCallbackFxn);

%conversion
conversionLabel = uicontrol('Style','text','String','Conversion Factor:','Position',[30,250,150,20],'FontSize',9.5);
conversionEdit = uicontrol('Style','edit','Position',[170,250,50,20],'Callback',@conversionCallbackFxn);

%alignment
alignLabel = uicontrol('Style','text','String','Alignment type:','Position',[30,220,150,20],'FontSize',9.5);
align = {'rough','tight'};
alignDrop = uicontrol('Style','popupmenu','Position',[170,220,100,20],'String',align,'Callback',@alignCallbackFxn);

%threshold
thresholdLabel = uicontrol('Style','text','Position',[30,190,200,20],'String','Threshold:', 'FontSize', 9.5);
thresholdEdit = uicontrol('Style','edit','Position',[170,190,80,20], 'Value', .5, 'Callback',@thresholdCallback);
threshButtonDown = uicontrol('Style', 'pushbutton', 'Position', [260, 190, 20, 20], 'String', '<', 'Callback',@(src, event) threshButtonDownCallbackFxn(thresholdEdit));
threshButtonUp = uicontrol('Style', 'pushbutton', 'Position', [280, 190, 20, 20],  'String', '>', 'Callback',@(src, event) threshButtonUpCallbackFxn(thresholdEdit));

%example frame input 
frameLabel = uicontrol('Style','text','String','Example frame:','Position',[30,160,150,20],'FontSize',9.5);
frameEdit = uicontrol('Style','edit','Position',[170,160,80,20], 'Callback',@frameCallbackFxn);
frameButtonPrevious = uicontrol('Style', 'pushbutton', 'Position', [260, 160, 20, 20], 'String', '<', 'Callback',@(src, event) prevFrameCallbackFxn(frameEdit));
frameButtonNext = uicontrol('Style', 'pushbutton', 'Position', [280, 160, 20, 20],  'String', '>', 'Callback',@(src, event) nextFrameCallbackFxn(frameEdit));

%select pupil edge pixels
rightPercentileLabel = uicontrol('Style','text','String','Right Percentile:','Position',[30,130,150,20],'FontSize',9.5);
rightPercentileEdit = uicontrol('Style','edit','Position',[170,130,80,20], 'Callback',@rightPercentileCallbackFxn);

topPercentileLabel = uicontrol('Style','text','String','Top Percentile:','Position',[30,100,150,20],'FontSize',9.5);
topPercentileEdit = uicontrol('Style','edit','Position',[170,100,80,20], 'Callback',@topPercentileCallbackFxn);

% faceCheckBox = uicontrol('Style','checkbox','String','Compute face SVD?','Position',[30,100,150,20],'FontSize',9.5,'Callback',@faceCallbackFxn);

%follow up analysis
kMeansCheckBox = uicontrol('Style','checkbox','String','Kmeans Clustering','Position',[450,340,200,20],'FontSize',9.5,'Callback',@kmeansCallbackFxn);
dilconCheckBox = uicontrol('Style','checkbox','String','Dilation/Constriction Event Detection','Position',[450,310,250,20],'FontSize',9.5,'Callback',@dilconCallbackFxn);

% start button 
start = uicontrol('Style','pushbutton','String','Confirm','Position',[600,50,150,50],'Callback',@runButtonPushed);

%callback fxn for blink
    function blinkCallbackFxn(src,~)
        selectedBlink = str2num(src.String);
    end

%callback fxn for orient 
    function  orientCallbackFxn(src,~)
        selectedOrient = src.String{src.Value};
    end

%callback fxn for scope
    function scopesCallbackFxn(src,~)
        selectedScope = src.String{src.Value};
    end

%callback fxn for unit 
    function unitCallbackFxn(src,~)
        selectedUnit = src.String{src.Value};        
    end

%callback fxn for align 
    function alignCallbackFxn(src,~)
        selectedAlign = src.String{src.Value};
    end

%callback fxn for conversion factor 
    function conversionCallbackFxn(src,~)
        selectedConversion=str2num(src.String);
    end
    
%callback fxn for face 
    function faceCallbackFxn(src,~)
        selectedFace=src.Value;
    end


%callback fxn for kmeans 
    function kmeansCallbackFxn(src,~)
        selectedKmeans = src.Value;
    end

%callback fxn for dilcon
    function  dilconCallbackFxn(src,~)
        selectedDilCon = src.Value;
    end

%callback fxn for frame
    function frameCallbackFxn(src,~)
        frame_id = str2num(src.String);
        the_example_image = read(exp_obj,frame_id);
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile,cornMask,eyeMask,selectedOrient);
    end

%callback fxn for previous frame button
    function prevFrameCallbackFxn(frameEdit)
        frame_id = frame_id - 1;

        frameEdit.String = num2str(frame_id);
        the_example_image = read(exp_obj,frame_id);
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile,cornMask,eyeMask,selectedOrient);
    end

%callback fxn for next frame button
    function nextFrameCallbackFxn(frameEdit)
        frame_id = frame_id + 1;

        frameEdit.String = num2str(frame_id);
        the_example_image = read(exp_obj,frame_id);
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile,cornMask,eyeMask,selectedOrient);
    end

%callback fxn for right percentile
    function rightPercentileCallbackFxn(src,~)
        selectedRightPercentile = str2num(src.String);
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile, cornMask,eyeMask,selectedOrient);
    end

%callback fxn for top percentile
    function topPercentileCallbackFxn(src,~)
        selectedTopPercentile = str2num(src.String);
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile, cornMask,eyeMask,selectedOrient);
    end

%callback fxn for threshold
    function thresholdCallback(source,~)
        selectedThreshold = str2num(get(source,'String')); %get current value in field
    
        %update the plot with the current value
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile,cornMask,eyeMask,selectedOrient);
    end

%callback fxn for threshold down
    function threshButtonDownCallbackFxn(thresholdEdit)
        selectedThreshold = selectedThreshold - .025;

        thresholdEdit.String = num2str(selectedThreshold);

        the_example_image = read(exp_obj,frame_id);
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile,cornMask,eyeMask,selectedOrient);
    end

%callback fxn for threshold up
    function threshButtonUpCallbackFxn(thresholdEdit)
        selectedThreshold = selectedThreshold + .025;

        thresholdEdit.String = num2str(selectedThreshold);

        the_example_image = read(exp_obj,frame_id);
        plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile,cornMask,eyeMask,selectedOrient);
    end



function plotExampleThreshold(the_example_image,selectedThreshold,selectedRightPercentile,selectedTopPercentile,cornMask,eyeMask,selectedOrient)
    pointsToFit=processing.getPointsToFitTest(the_example_image,selectedThreshold,eyeMask,eyeEllipse,cornMask,selectedRightPercentile,selectedTopPercentile); 
    try
        [z, r, ~] = processing.fitcircle_mcc(pointsToFit);
    catch
        z = [];
        r = [];
    end

    %how to handle problem frames
    if isempty(r) || r > 175 || r < 25
        radius = 0;
        center = zeros(1,2);
    else
        radius = r;
        center = [z(2) z(1)];
    end

    figure(999);nexttile;
    imshow(the_example_image);
    viscircles(center,radius,'LineWidth',1);
    hold on; plot(pointsToFit(2,:), pointsToFit(1,:), 'Marker','.', 'LineStyle','none')
    end

%callback fxn for run button 
function  runButtonPushed(~,~)
    close(uiFigure);
    close(figure(999));
    disp('Processing parameters saved.');
end

waitfor(uiFigure);
end


