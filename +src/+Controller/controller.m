classdef controller < handle
    properties
        hView
        hModel
        device
        range1 = 0
        range2 = 0.6
    end

    methods
        function obj = controller()
<<<<<<< Updated upstream
            % Python Setup
            %if count(py.sys.path, pwd) == 0
            %    insert(py.sys.path, int32(0), pwd);
            %end
            
            % Serial Initialization
            %try
            %    obj.device = serialport("COM6", 9600);
            %    configureTerminator(obj.device, "LF");
            %    pause(2); % Wait for Arduino reboot
            %    fprintf('Connected to Radar Motor.\n');
            %catch
            %    warning('Arduino connection failed. Check COM6.');
            %end
        end
        
        function runScan(obj, nTimes)
            %if isempty(obj.device) || ~isvalid(obj.device)
             %   error('Serial device not connected.');
            %end
=======
            % Setup Python
            %if count(py.sys.path, pwd) == 0
            %    insert(py.sys.path, int32(0), pwd);
            %end
            %mod = py.importlib.import_module('radar_kod_pokus');
            %py.importlib.reload(mod);

            % Initialize Serial Port
            %try
            %    obj.device = serialport("COM8", 9600);
             %   configureTerminator(obj.device, "LF");
              %  pause(3);
               % fprintf('Serial connection established on COM8\n');
            %catch e
            %    warning('Could not connect to Arduino on COM8: %s');
            %    obj.device = [];
            %end
        end
>>>>>>> Stashed changes

        function runScan(obj, totalSteps, numPositions)
            %if isempty(obj.device) || ~isvalid(obj.device)
            %    error('Serial device not connected.');
            %end

<<<<<<< Updated upstream
            for i = 1:nTimes
                fprintf('Cycle %d: Moving %d steps to Angle %d...\n', i, stepsToMove, obj.currentAngle);
                
                % 1. Send the number as a string (Arduino parseInt needs this)
                %writeline(obj.device, num2str(stepsToMove));
                
                % 2. Wait for Arduino "DONE"
                %readline(obj.device); 
                
                % 3. Python Capture & Model Update
                %py.radar_kod_pokus.collect_radar_data(int32(10), 0, 0.6);
                obj.hModel.loadData();
                
                % 4. View Render
                obj.hView.render(obj.hModel.M, obj.currentAngle);
                
                % 5. State Update
                obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                drawnow; 
                pause(0.5);
=======
            stepsPerMove = floor(totalSteps / numPositions);
            allData = [];
            figHandle = figure('Color', 'w'); % open figure once

            for i = 1:numPositions
                fprintf('Position %d of %d...\n', i, numPositions);

                % Move motor one increment
                %writeline(obj.device, num2str(stepsPerMove));
                %readline(obj.device); % wait for DONE

                % Capture radar data at this position
                cycles = 10;
                %py.radar_kod_pokus.collect_radar_data(int32(cycles), obj.range1, obj.range2);

                % Load and accumulate data
                obj.hModel.loadData();
                allData = [allData; obj.hModel.M]; %#ok<AGROW>

                % Update plot with data collected so far
                obj.hModel.M = allData;
                obj.hView.render(obj.hModel.M, figHandle);
            end

            fprintf('Scan complete.\n');
        end

        function setModel(obj, hModel), obj.hModel = hModel; end
        function setView(obj, hView), obj.hView = hView; end

        function delete(obj)
            if ~isempty(obj.device) && isvalid(obj.device)
                delete(obj.device);
                obj.device = [];
                fprintf('Serial port closed.\n');
>>>>>>> Stashed changes
            end
        end
    end
end
