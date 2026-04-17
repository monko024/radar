classdef controller < handle
    properties
        hView
        hModel
        device
        currentAngle = 0
        stepSizeDeg = 20  % Degrees to rotate per iteration
        stepsPerDeg = 5.5 % Example: 200 steps / 360 degrees = ~0.55 (Adjust for your motor!)
    end
    
    methods
        function obj = controller()
            % Python Setup
            if count(py.sys.path, pwd) == 0
                insert(py.sys.path, int32(0), pwd);
            end
            
            % Serial Initialization
            try
                obj.device = serialport("COM6", 9600);
                configureTerminator(obj.device, "LF");
                pause(2); % Wait for Arduino reboot
                fprintf('Connected to Radar Motor.\n');
            catch
                warning('Arduino connection failed. Check COM6.');
            end
        end
        
        function runScan(obj, nTimes)
            if isempty(obj.device) || ~isvalid(obj.device)
                error('Serial device not connected.');
            end

            % Calculate how many steps to send for each movement
            stepsToMove = round(obj.stepSizeDeg * obj.stepsPerDeg);

            for i = 1:nTimes
                fprintf('Cycle %d: Moving %d steps to Angle %d...\n', i, stepsToMove, obj.currentAngle);
                
                % 1. Send the number as a string (Arduino parseInt needs this)
                writeline(obj.device, num2str(stepsToMove));
                
                % 2. Wait for Arduino "DONE"
                readline(obj.device); 
                
                % 3. Python Capture & Model Update
                py.radar_kod_pokus.collect_radar_data(int32(10), 0, 0.6);
                obj.hModel.loadData();
                
                % 4. View Render
                obj.hView.render(obj.hModel.M, obj.currentAngle);
                
                % 5. State Update
                obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                drawnow; 
            end
        end
        
        function setModel(obj, m), obj.hModel = m; end
        function setView(obj, v), obj.hView = v; end
    end
end