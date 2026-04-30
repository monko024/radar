classdef controller < handle
    properties
        hView
        hModel
        device
        currentAngle = 0
        stepSizeDeg = 20
        stepsPerDeg = 5.5
        serialTimeoutSec = 5  % Reduced timeout for better responsiveness
    end

    methods
        function obj = controller()
            if count(py.sys.path, pwd) == 0
                insert(py.sys.path, int32(0), pwd);
            end

            try
                obj.device = serialport("COM6", 9600);
                configureTerminator(obj.device, "LF");
                obj.device.Timeout = obj.serialTimeoutSec;
                pause(2); 
                fprintf('Connected to Arduino.\n');
            catch
                warning('Arduino connection failed.');
            end
        end

        function runScan(obj, nTimes)
            if isempty(obj.device) || ~isvalid(obj.device)
                error('Serial device not connected.');
            end

            stepsToMove = round(obj.stepSizeDeg * obj.stepsPerDeg);
            fprintf('Initializing radar...\n');
            py.radar_kod_pokus.radar_init(0.2, 1);

            try
                for i = 1:nTimes
                    fprintf('\n--- Cycle %d ---\n', i);

                    % 1. Command Arduino
                    fprintf('Motor: Moving %d steps...\n', stepsToMove);
                    writeline(obj.device, num2str(stepsToMove));

                    % 2. Wait for Arduino
                    response = obj.waitForDone();
                    if isempty(response)
                        fprintf('Warning: Arduino response timed out. Skipping.\n');
                        continue;
                    end

                    % 3. Radar Capture (Python)
                    fprintf('Radar: Capturing...\n');
                    try
                        py.radar_kod_pokus.capture_sweeps(int32(10));
                        pause(0.1); % Small buffer for file writing
                        obj.hModel.loadData();
                    catch ME
                        fprintf('Radar Error: %s\n', ME.message);
                        continue;
                    end

                    % 4. Render
                    obj.hView.render(obj.hModel.M, obj.currentAngle);
                    
                    obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                    drawnow;
                end
            catch ME
                fprintf('Global Error: %s\n', ME.message);
            end

            py.radar_kod_pokus.radar_cleanup();
            fprintf('Scan Finished.\n');
        end

        function setModel(obj, m), obj.hModel = m; end
        function setView(obj, v), obj.hView = v; end
    end

    methods (Access = private)
        function response = waitForDone(obj)
            response = '';
            deadline = tic;
            while toc(deadline) < obj.serialTimeoutSec
                if obj.device.NumBytesAvailable > 0
                    response = readline(obj.device);
                    fprintf('Arduino: %s\n', response);
                    return;
                end
                pause(0.05);
            end
            flush(obj.device); 
        end
    end
end