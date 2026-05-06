classdef App < handle
    properties
        UIFigure, GridLayout, LeftPanel, RightPanel
        RangeStartEdit, RangeEndEdit, NumRotationsEdit, AngleStepEdit
        RunButton, ClearButton, UIAxes
        hModel, hView, hController
    end
    
    methods
        function obj = App()
            obj.UIFigure = uifigure('Name', 'Radar Scanner Control', 'Color', [0.15 0.15 0.15]);
            obj.UIFigure.Position = [100 100 950 550];
            obj.GridLayout = uigridlayout(obj.UIFigure, [1, 2]);
            obj.GridLayout.ColumnWidth = {280, '1x'};
            
            obj.LeftPanel = uipanel(obj.GridLayout, 'Title', 'Setup', ...
                'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w');
            
            uilabel(obj.LeftPanel, 'Text', 'Range Start (m):', 'Position', [20 380 120 22], 'FontColor', 'w');
            obj.RangeStartEdit = uieditfield(obj.LeftPanel, 'numeric', 'Value', 0.2, 'Position', [140 380 80 22]);
            
            uilabel(obj.LeftPanel, 'Text', 'Range End (m):', 'Position', [20 340 120 22], 'FontColor', 'w');
            obj.RangeEndEdit = uieditfield(obj.LeftPanel, 'numeric', 'Value', 1.0, 'Position', [140 340 80 22]);
            
            uilabel(obj.LeftPanel, 'Text', 'Rotations:', 'Position', [20 300 120 22], 'FontColor', 'w');
            obj.NumRotationsEdit = uieditfield(obj.LeftPanel, 'numeric', 'Value', 5, 'Position', [140 300 80 22]);
            
            uilabel(obj.LeftPanel, 'Text', 'Step Angle (°):', 'Position', [20 260 120 22], 'FontColor', 'w');
            obj.AngleStepEdit = uieditfield(obj.LeftPanel, 'numeric', 'Value', 20, 'Position', [140 260 80 22]);
            
            obj.RunButton = uibutton(obj.LeftPanel, 'Text', 'RUN SCAN', 'Position', [20 180 220 40], ...
                'BackgroundColor', [0.2 0.6 0.2], 'FontColor', 'w', 'ButtonPushedFcn', @(~,~) obj.startScan());
            
            obj.ClearButton = uibutton(obj.LeftPanel, 'Text', 'CLEAR DISPLAY', 'Position', [20 120 220 40], ...
                'BackgroundColor', [0.6 0.2 0.2], 'FontColor', 'w', 'ButtonPushedFcn', @(~,~) obj.clearDisplay());
            
            obj.RightPanel = uipanel(obj.GridLayout, 'BackgroundColor', [0.1 0.1 0.1], 'BorderType', 'none');
            obj.UIAxes = uiaxes(obj.RightPanel, 'Position', [10 10 600 500], 'Color', 'none');
            
            obj.hModel = model();
            obj.hView = view(); 
            obj.hController = controller();
            obj.hController.setModel(obj.hModel);
            obj.hController.setView(obj.hView);
            
            obj.hView.render([], 0, obj.UIAxes);
        end
        
        function startScan(obj)
            obj.RunButton.Enable = 'off';
            obj.RunButton.Text = 'Scanning...';
            drawnow;
            try
                obj.hView.setRange(obj.RangeStartEdit.Value, obj.RangeEndEdit.Value);
                obj.hController.stepSizeDeg = obj.AngleStepEdit.Value;
                obj.hController.currentAngle = 0; 
                
                py.radar_kod_pokus.radar_init(obj.RangeStartEdit.Value, obj.RangeEndEdit.Value);
                obj.hController.runScan(obj.NumRotationsEdit.Value);
                py.radar_kod_pokus.radar_cleanup();
            catch ME
                uialert(obj.UIFigure, ME.message, 'Error');
                py.radar_kod_pokus.radar_cleanup();
            end
            obj.RunButton.Enable = 'on';
            obj.RunButton.Text = 'RUN SCAN';
        end
        
        function clearDisplay(obj)
            obj.hView.render([], 0, obj.UIAxes);
            obj.hController.currentAngle = 0;
        end
    end
end